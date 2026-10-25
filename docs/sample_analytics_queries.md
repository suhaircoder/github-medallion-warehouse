# Sample Analytics Questions

Use these questions to demonstrate the value of the final marts.

## Top Repositories By Daily Activity

```sql
select
    activity_date,
    repo_name,
    total_events,
    active_actors,
    observed_commits,
    daily_repository_activity_rank
from {{ ref('mart_repository_activity_daily') }}
where daily_repository_activity_rank <= 10
order by activity_date, daily_repository_activity_rank
```

## Most Active Contributors

```sql
select
    activity_date,
    actor_login,
    total_events,
    repositories_touched,
    observed_commits,
    daily_actor_activity_rank
from {{ ref('mart_actor_contributions_daily') }}
where daily_actor_activity_rank <= 10
order by activity_date, daily_actor_activity_rank
```

## High Health Repositories

```sql
select
    activity_date,
    repo_name,
    activity_health_score,
    health_tier,
    active_actors,
    observed_commits,
    opened_pull_requests,
    closed_issues
from {{ ref('mart_open_source_project_health') }}
where health_tier = 'high'
order by activity_date, activity_health_score desc
```
