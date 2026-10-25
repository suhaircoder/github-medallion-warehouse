{{
  config(
    partition_by={
      "field": "activity_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=['actor_key', 'actor_login'],
    tags=['mart', 'actor']
  )
}}

with actor_activity as (

    select
        fact_github_events.date_key,
        fact_github_events.actor_key,
        count(*) as total_events,
        count(distinct fact_github_events.repository_key) as repositories_touched,
        sum(fact_github_events.push_event_count) as push_events,
        sum(fact_github_events.pull_request_event_count) as pull_request_events,
        sum(fact_github_events.issue_event_count) as issue_events,
        sum(coalesce(fact_github_events.commit_count, 0)) as observed_commits
    from {{ ref('fact_github_events') }} as fact_github_events
    where fact_github_events.actor_key is not null
    group by 1, 2

),

actor_daily as (

    select
        dim_date.calendar_date as activity_date,
        dim_actor.actor_key,
        dim_actor.actor_id,
        dim_actor.actor_login,
        actor_activity.total_events,
        actor_activity.repositories_touched,
        actor_activity.push_events,
        actor_activity.pull_request_events,
        actor_activity.issue_events,
        actor_activity.observed_commits
    from actor_activity
    inner join {{ ref('dim_date') }} as dim_date
        on actor_activity.date_key = dim_date.date_key
    inner join {{ ref('dim_actor') }} as dim_actor
        on actor_activity.actor_key = dim_actor.actor_key

)

select
    *,
    sum(total_events) over (
        partition by actor_key
        order by activity_date
        rows between 6 preceding and current row
    ) as rolling_7_day_events,
    sum(repositories_touched) over (
        partition by actor_key
        order by activity_date
        rows between 6 preceding and current row
    ) as rolling_7_day_repositories_touched,
    dense_rank() over (
        partition by activity_date
        order by total_events desc
    ) as daily_actor_activity_rank,
    current_timestamp() as loaded_at
from actor_daily
