{{
  config(
    partition_by={
      "field": "event_created_at",
      "data_type": "timestamp",
      "granularity": "day"
    },
    cluster_by=['repository_key', 'actor_key', 'payload_action'],
    tags=['gold', 'fact']
  )
}}

with issues as (

    select *
    from {{ ref('silver_issues') }}

)

select
    issues.issue_event_key,
    issues.event_key,
    format_date('%Y%m%d', issues.event_date) as date_key,
    dim_repository.repository_key,
    dim_actor.actor_key,
    dim_organization.organization_key,
    issues.event_id,
    issues.event_created_at,
    issues.event_date,
    issues.payload_action,
    issues.previous_issue_action,
    issues.issue_id,
    issues.issue_number,
    issues.issue_state,
    issues.issue_event_sequence,
    issues.first_observed_at,
    issues.last_observed_at,
    issues.observed_lifecycle_hours,
    1 as issue_event_count,
    if(issues.payload_action = 'opened', 1, 0) as opened_issue_count,
    if(issues.payload_action = 'closed', 1, 0) as closed_issue_count,
    current_timestamp() as loaded_at
from issues
left join {{ ref('dim_repository') }} as dim_repository
    on issues.repo_id = dim_repository.repo_id
left join {{ ref('dim_actor') }} as dim_actor
    on issues.actor_id = dim_actor.actor_id
left join {{ ref('dim_organization') }} as dim_organization
    on issues.org_id = dim_organization.org_id
