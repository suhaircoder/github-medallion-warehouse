# Data Dictionary

## Bronze

### `bronze_github_events`

One row per GitHub event, with PushEvent commits expanded to one row per commit
when commit data is present.

Important columns:

- `event_id`: GitHub Archive event identifier.
- `event_type`: Source event type, such as `PushEvent` or `PullRequestEvent`.
- `repo_id`: Numeric repository identifier.
- `repo_name`: Repository full name.
- `actor_id`: Numeric actor identifier.
- `actor_login`: GitHub username.
- `event_created_at`: Source event timestamp.
- `raw_payload`: Original JSON payload.
- `commit_sha`: Commit SHA for flattened PushEvent commits.

## Silver

- `silver_github_events`: One row per event with typed fields, event family, event date, event hour, and commit counts.
- `silver_actors`: One row per actor with latest profile attributes and observed activity window.
- `silver_repositories`: One row per repository with owner/name parsing and observed activity window.
- `silver_organizations`: One row per organization with latest observed attributes.
- `silver_pull_requests`: Pull request event stream with action sequencing and lifecycle metrics.
- `silver_issues`: Issue event stream with action sequencing and lifecycle metrics.
- `silver_push_commits`: One row per pushed commit with hashed commit author email fields.

## Gold

Dimensions:

- `dim_date`: Calendar dimension.
- `dim_event_type`: Event type and event family dimension.
- `dim_actor`: Actor dimension.
- `dim_repository`: Repository dimension.
- `dim_organization`: Organization dimension.

Facts:

- `fact_github_events`: One row per GitHub event.
- `fact_pushes`: One row per pushed commit.
- `fact_pull_requests`: One row per pull request event.
- `fact_issues`: One row per issue event.

## Marts

- `mart_repository_activity_daily`: Daily repository activity, rolling seven-day activity, and rankings.
- `mart_actor_contributions_daily`: Daily actor contribution metrics and rankings.
- `mart_open_source_project_health`: Repository health scoring based on events, contributors, commits, issues, and pull requests.
