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
        {{ generate_surrogate_key(['event_rollup.event_id']) }} as event_key,
        event_rollup.event_id,
        event_rollup.event_type,
        coalesce(event_type_mapping.event_family, 'other') as event_family,
        event_rollup.is_public,
        event_rollup.repo_id,
        event_rollup.repo_name,
        event_rollup.actor_id,
        event_rollup.actor_login,
        event_rollup.org_id,
        event_rollup.org_login,
        event_rollup.event_created_at,
        event_rollup.event_date,
        extract(hour from event_rollup.event_created_at) as event_hour,
        event_rollup.payload_action,
        event_rollup.payload_ref,
        event_rollup.payload_ref_type,
        event_rollup.pull_request_id,
        event_rollup.pull_request_number,
        event_rollup.pull_request_state,
        event_rollup.issue_id,
        event_rollup.issue_number,
        event_rollup.issue_state,
        event_rollup.release_id,
        event_rollup.push_size,
        event_rollup.push_distinct_size,
        event_rollup.commit_count,
        current_timestamp() as transformed_at
    from event_rollup
    left join {{ ref('event_type_mapping') }} as event_type_mapping
        on event_rollup.event_type = event_type_mapping.event_type
    where event_rollup.event_rank = 1

)

select *
from typed_events
