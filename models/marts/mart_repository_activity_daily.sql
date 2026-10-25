{{
  config(
    partition_by={
      "field": "activity_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=['repository_key', 'repository_owner'],
    tags=['mart', 'repository']
  )
}}

with event_activity as (

    select
        fact_github_events.date_key,
        fact_github_events.repository_key,
        count(*) as total_events,
        count(distinct fact_github_events.actor_key) as active_actors,
        sum(fact_github_events.push_event_count) as push_events,
        sum(fact_github_events.pull_request_event_count) as pull_request_events,
        sum(fact_github_events.issue_event_count) as issue_events,
        sum(coalesce(fact_github_events.commit_count, 0)) as observed_commits
    from {{ ref('fact_github_events') }} as fact_github_events
    where fact_github_events.repository_key is not null
    group by 1, 2

),

repository_activity as (

    select
        dim_date.calendar_date as activity_date,
        dim_repository.repository_key,
        dim_repository.repo_id,
        dim_repository.repo_name,
        dim_repository.repository_owner,
        dim_repository.repository_name,
        event_activity.total_events,
        event_activity.active_actors,
        event_activity.push_events,
        event_activity.pull_request_events,
        event_activity.issue_events,
        event_activity.observed_commits
    from event_activity
    inner join {{ ref('dim_date') }} as dim_date
        on event_activity.date_key = dim_date.date_key
    inner join {{ ref('dim_repository') }} as dim_repository
        on event_activity.repository_key = dim_repository.repository_key

)

select
    *,
    sum(total_events) over (
        partition by repository_key
        order by activity_date
        rows between 6 preceding and current row
    ) as rolling_7_day_events,
    sum(active_actors) over (
        partition by repository_key
        order by activity_date
        rows between 6 preceding and current row
    ) as rolling_7_day_active_actors,
    dense_rank() over (
        partition by activity_date
        order by total_events desc
    ) as daily_repository_activity_rank,
    current_timestamp() as loaded_at
from repository_activity
