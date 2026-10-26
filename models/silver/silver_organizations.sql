{{
  config(
    cluster_by=['org_id', 'org_login'],
    tags=['silver', 'entities']
  )
}}

with organization_events as (

    select
        event_id,
        org_id,
        org_login,
        org_url,
        event_created_at,
        loaded_at
    from {{ ref('bronze_github_events') }}
    where org_id is not null

),

ranked as (

    select
        *,
        min(event_created_at) over (partition by org_id) as first_seen_at,
        max(event_created_at) over (partition by org_id) as last_seen_at,
        count(distinct event_id) over (partition by org_id) as observed_event_rows,
        row_number() over (
            partition by org_id
            order by event_created_at desc, loaded_at desc
        ) as organization_rank
    from organization_events

)

select
    org_id,
    org_login,
    org_url,
    first_seen_at,
    last_seen_at,
    observed_event_rows,
    current_timestamp() as transformed_at
from ranked
where organization_rank = 1
