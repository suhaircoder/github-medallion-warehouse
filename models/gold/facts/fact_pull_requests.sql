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

with pull_requests as (

    select *
    from {{ ref('silver_pull_requests') }}

)

select
    pull_requests.pull_request_event_key,
    pull_requests.event_key,
    format_date('%Y%m%d', pull_requests.event_date) as date_key,
    dim_repository.repository_key,
    dim_actor.actor_key,
    dim_organization.organization_key,
    pull_requests.event_id,
    pull_requests.event_created_at,
    pull_requests.event_date,
    pull_requests.payload_action,
    pull_requests.previous_pull_request_action,
    pull_requests.pull_request_id,
    pull_requests.pull_request_number,
    pull_requests.pull_request_state,
    pull_requests.pull_request_event_sequence,
    pull_requests.first_observed_at,
    pull_requests.last_observed_at,
    pull_requests.observed_lifecycle_hours,
    1 as pull_request_event_count,
    if(pull_requests.payload_action = 'opened', 1, 0) as opened_pull_request_count,
    if(pull_requests.payload_action = 'closed', 1, 0) as closed_pull_request_count,
    current_timestamp() as loaded_at
from pull_requests
left join {{ ref('dim_repository') }} as dim_repository
    on pull_requests.repo_id = dim_repository.repo_id
left join {{ ref('dim_actor') }} as dim_actor
    on pull_requests.actor_id = dim_actor.actor_id
left join {{ ref('dim_organization') }} as dim_organization
    on pull_requests.org_id = dim_organization.org_id
