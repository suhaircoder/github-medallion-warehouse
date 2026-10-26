{{
  config(
    cluster_by=['actor_id', 'actor_login'],
    tags=['silver', 'entities']
  )
}}

with actor_events as (

    select
        event_id,
        actor_id,
        actor_login,
        actor_url,
        actor_avatar_url,
        event_created_at,
        source_table_date,
        loaded_at
    from {{ ref('bronze_github_events') }}
    where actor_id is not null

),

ranked as (

    select
        *,
        min(event_created_at) over (partition by actor_id) as first_seen_at,
        max(event_created_at) over (partition by actor_id) as last_seen_at,
        count(distinct event_id) over (partition by actor_id) as observed_event_rows,
        row_number() over (
            partition by actor_id
            order by event_created_at desc, loaded_at desc
        ) as actor_rank
    from actor_events

)

select
    actor_id,
    actor_login,
    actor_url,
    actor_avatar_url,
    first_seen_at,
    last_seen_at,
    observed_event_rows,
    current_timestamp() as transformed_at
from ranked
where actor_rank = 1
