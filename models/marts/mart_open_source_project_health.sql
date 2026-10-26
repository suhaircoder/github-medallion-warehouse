{{
  config(
    partition_by={
      "field": "activity_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=['repository_key', 'health_tier'],
    tags=['mart', 'repository', 'health']
  )
}}

with base_activity as (

    select
        activity_date,
        repository_key,
        repo_id,
        repo_name,
        repository_owner,
        repository_name,
        total_events,
        active_actors,
        push_events,
        pull_request_events,
        issue_events,
        observed_commits
    from {{ ref('mart_repository_activity_daily') }}

),

push_quality as (

    select
        date(event_created_at) as activity_date,
        repository_key,
        count(distinct commit_author_email_hash) as distinct_commit_authors,
        count(distinct commit_author_email_domain) as distinct_commit_email_domains
    from {{ ref('fact_pushes') }}
    where repository_key is not null
    group by activity_date, repository_key

),

workflow_activity as (

    select
        activity_date,
        repository_key,
        sum(opened_pull_requests) as opened_pull_requests,
        sum(closed_pull_requests) as closed_pull_requests,
        sum(opened_issues) as opened_issues,
        sum(closed_issues) as closed_issues
    from (
        select
            date(event_created_at) as activity_date,
            repository_key,
            sum(opened_pull_request_count) as opened_pull_requests,
            sum(closed_pull_request_count) as closed_pull_requests,
            0 as opened_issues,
            0 as closed_issues
        from {{ ref('fact_pull_requests') }}
        where repository_key is not null
        group by activity_date, repository_key

        union all

        select
            date(event_created_at) as activity_date,
            repository_key,
            0 as opened_pull_requests,
            0 as closed_pull_requests,
            sum(opened_issue_count) as opened_issues,
            sum(closed_issue_count) as closed_issues
        from {{ ref('fact_issues') }}
        where repository_key is not null
        group by activity_date, repository_key
    )
    group by activity_date, repository_key

),

scored as (

    select
        base_activity.activity_date,
        base_activity.repository_key,
        base_activity.repo_id,
        base_activity.repo_name,
        base_activity.repository_owner,
        base_activity.repository_name,
        base_activity.total_events,
        base_activity.active_actors,
        base_activity.push_events,
        base_activity.pull_request_events,
        base_activity.issue_events,
        base_activity.observed_commits,
        coalesce(push_quality.distinct_commit_authors, 0) as distinct_commit_authors,
        coalesce(push_quality.distinct_commit_email_domains, 0) as distinct_commit_email_domains,
        coalesce(workflow_activity.opened_pull_requests, 0) as opened_pull_requests,
        coalesce(workflow_activity.closed_pull_requests, 0) as closed_pull_requests,
        coalesce(workflow_activity.opened_issues, 0) as opened_issues,
        coalesce(workflow_activity.closed_issues, 0) as closed_issues,
        (
            least(base_activity.total_events, 100)
            + least(base_activity.active_actors * 5, 100)
            + least(base_activity.observed_commits * 2, 100)
            + least(coalesce(workflow_activity.opened_pull_requests, 0) * 10, 100)
            + least(coalesce(workflow_activity.closed_issues, 0) * 10, 100)
        ) as activity_health_score
    from base_activity
    left join push_quality
        on base_activity.activity_date = push_quality.activity_date
       and base_activity.repository_key = push_quality.repository_key
    left join workflow_activity
        on base_activity.activity_date = workflow_activity.activity_date
       and base_activity.repository_key = workflow_activity.repository_key

)

select
    *,
    case
        when activity_health_score >= 300 then 'high'
        when activity_health_score >= 150 then 'medium'
        else 'low'
    end as health_tier,
    percent_rank() over (
        partition by activity_date
        order by activity_health_score
    ) as daily_health_percentile,
    current_timestamp() as loaded_at
from scored
