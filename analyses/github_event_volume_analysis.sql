with daily_event_volume as (

    select
        date(event_created_at) as event_date,
        event_type,
        count(*) as event_rows,
        count(distinct event_id) as distinct_events,
        count(distinct repo_id) as active_repositories,
        count(distinct actor_id) as active_actors
    from {{ ref('bronze_github_events') }}
    group by 1, 2

)

select
    event_date,
    event_type,
    event_rows,
    distinct_events,
    active_repositories,
    active_actors,
    round(
        event_rows / nullif(sum(event_rows) over (partition by event_date), 0),
        4
    ) as pct_of_daily_rows
from daily_event_volume
order by event_date, event_rows desc
