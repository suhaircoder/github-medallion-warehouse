{{
  config(
    partition_by={
      "field": "event_created_at",
      "data_type": "timestamp",
      "granularity": "day"
    },
    cluster_by=['event_type_key', 'repository_key', 'actor_key'],
    tags=['gold', 'fact']
  )
}}

with events as (

    select *
    from {{ ref('silver_github_events') }}

)

select
    events.event_key,
    format_date('%Y%m%d', events.event_date) as date_key,
    dim_event_type.event_type_key,
    dim_repository.repository_key,
    dim_actor.actor_key,
    dim_organization.organization_key,
    events.event_id,
    events.event_type,
    events.event_family,
    events.event_created_at,
    events.event_date,
    events.event_hour,
    events.payload_action,
    events.payload_ref,
    events.payload_ref_type,
    events.is_public,
    events.pull_request_id,
    events.pull_request_number,
    events.issue_id,
    events.issue_number,
    events.release_id,
    events.push_size,
    events.push_distinct_size,
    events.commit_count,
    1 as event_count,
    if(events.event_type = 'PushEvent', 1, 0) as push_event_count,
    if(events.event_type = 'PullRequestEvent', 1, 0) as pull_request_event_count,
    if(events.event_type = 'IssuesEvent', 1, 0) as issue_event_count,
    current_timestamp() as loaded_at
from events
left join {{ ref('dim_event_type') }} as dim_event_type
    on events.event_type = dim_event_type.event_type
left join {{ ref('dim_repository') }} as dim_repository
    on events.repo_id = dim_repository.repo_id
left join {{ ref('dim_actor') }} as dim_actor
    on events.actor_id = dim_actor.actor_id
left join {{ ref('dim_organization') }} as dim_organization
    on events.org_id = dim_organization.org_id
