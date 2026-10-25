{{
  config(
    partition_by={
      "field": "event_created_at",
      "data_type": "timestamp",
      "granularity": "day"
    },
    cluster_by=['event_type', 'repo_id', 'actor_id'],
    tags=['silver', 'events']
  )
}}

with bronze_events as (

    select *
    from {{ ref('bronze_github_events') }}

),

event_rollup as (

    select
        event_id,
        event_type,
        is_public,
        repo_id,
        repo_name,
        actor_id,
        actor_login,
        org_id,
        org_login,
        event_created_at,
        date(event_created_at) as event_date,
        payload_action,
        payload_ref,
        payload_ref_type,
        pull_request_id,
        pull_request_number,
        pull_request_state,
        issue_id,
        issue_number,
        issue_state,
        release_id,
        push_size,
        push_distinct_size,
        countif(commit_sha is not null) over (partition by event_id) as commit_count,
        row_number() over (
            partition by event_id
            order by event_created_at desc, loaded_at desc
        ) as event_rank
    from bronze_events

),

typed_events as (

    select
        {{ generate_surrogate_key(['event_id']) }} as event_key,
        event_id,
        event_type,
        case
            when event_type in ('PushEvent', 'CommitCommentEvent') then 'code'
            when event_type in ('PullRequestEvent', 'PullRequestReviewEvent', 'PullRequestReviewCommentEvent') then 'collaboration'
            when event_type in ('IssuesEvent', 'IssueCommentEvent') then 'planning'
            when event_type in ('CreateEvent', 'DeleteEvent', 'ForkEvent', 'WatchEvent', 'ReleaseEvent') then 'repository'
            else 'other'
        end as event_family,
        is_public,
        repo_id,
        repo_name,
        actor_id,
        actor_login,
        org_id,
        org_login,
        event_created_at,
        event_date,
        extract(hour from event_created_at) as event_hour,
        payload_action,
        payload_ref,
        payload_ref_type,
        pull_request_id,
        pull_request_number,
        pull_request_state,
        issue_id,
        issue_number,
        issue_state,
        release_id,
        push_size,
        push_distinct_size,
        commit_count,
        current_timestamp() as transformed_at
    from event_rollup
    where event_rank = 1

)

select *
from typed_events
