{{
  config(
    partition_by={
      "field": "event_created_at",
      "data_type": "timestamp",
      "granularity": "day"
    },
    cluster_by=['repo_id', 'actor_id', 'payload_action'],
    tags=['silver', 'pull_requests']
  )
}}

with pull_request_events as (

    select
        event_key,
        event_id,
        repo_id,
        actor_id,
        org_id,
        event_created_at,
        event_date,
        payload_action,
        pull_request_id,
        pull_request_number,
        pull_request_state
    from {{ ref('silver_github_events') }}
    where event_type = 'PullRequestEvent'
      and pull_request_id is not null

),

sequenced as (

    select
        *,
        row_number() over (
            partition by repo_id, pull_request_number
            order by event_created_at
        ) as pull_request_event_sequence,
        lag(payload_action) over (
            partition by repo_id, pull_request_number
            order by event_created_at
        ) as previous_pull_request_action,
        min(event_created_at) over (
            partition by repo_id, pull_request_number
        ) as first_observed_at,
        max(event_created_at) over (
            partition by repo_id, pull_request_number
        ) as last_observed_at
    from pull_request_events

)

select
    {{ generate_surrogate_key(['event_id', 'pull_request_id']) }} as pull_request_event_key,
    event_key,
    event_id,
    repo_id,
    actor_id,
    org_id,
    event_created_at,
    event_date,
    payload_action,
    previous_pull_request_action,
    pull_request_id,
    pull_request_number,
    pull_request_state,
    pull_request_event_sequence,
    first_observed_at,
    last_observed_at,
    timestamp_diff(last_observed_at, first_observed_at, hour) as observed_lifecycle_hours,
    current_timestamp() as transformed_at
from sequenced
