# Architecture

## Medallion Layers

### Bronze

The Bronze layer reads directly from GitHub Archive public wildcard tables. It
keeps raw event context while extracting frequently used JSON payload fields and
flattening PushEvent commits with `UNNEST()`.

### Silver

The Silver layer cleans and normalizes the event stream into stable analytical
entities such as actors, repositories, organizations, pull requests, issues, and
push commits. It also hashes commit author emails before they reach downstream
facts and marts.

### Gold

The Gold layer exposes a star schema optimized for analytics and BI:

- Facts capture event and workflow activity.
- Dimensions provide descriptive context.
- Marts aggregate common business questions such as repository activity and
  contributor behavior.

## Model Flow

```text
bronze_github_events
        |
        v
silver_github_events
silver_actors
silver_repositories
silver_organizations
silver_pull_requests
silver_issues
silver_push_commits
        |
        v
dim_date
dim_event_type
dim_actor
dim_repository
dim_organization
fact_github_events
fact_pushes
fact_pull_requests
fact_issues
        |
        v
mart_repository_activity_daily
mart_actor_contributions_daily
mart_open_source_project_health
```

## BigQuery Optimization

Large event tables are partitioned by event date and clustered by common filter
or join keys. Event models are partitioned by `event_created_at` and clustered
by keys such as event type, repository, actor, and commit SHA.
