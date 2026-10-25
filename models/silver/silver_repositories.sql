{{
  config(
    cluster_by=['repo_id', 'repo_name'],
    tags=['silver', 'entities']
  )
}}

with repository_events as (

    select
        repo_id,
        repo_name,
        repo_url,
        event_created_at,
        loaded_at
    from {{ ref('bronze_github_events') }}
    where repo_id is not null

),

ranked as (

    select
        *,
        split(repo_name, '/')[safe_offset(0)] as repository_owner,
        split(repo_name, '/')[safe_offset(1)] as repository_name,
        min(event_created_at) over (partition by repo_id) as first_seen_at,
        max(event_created_at) over (partition by repo_id) as last_seen_at,
        count(*) over (partition by repo_id) as observed_event_rows,
        count(distinct event_created_at) over (partition by repo_id) as active_event_timestamps,
        row_number() over (
            partition by repo_id
            order by event_created_at desc, loaded_at desc
        ) as repository_rank
    from repository_events

)

select
    repo_id,
    repo_name,
    repository_owner,
    repository_name,
    repo_url,
    first_seen_at,
    last_seen_at,
    observed_event_rows,
    active_event_timestamps,
    current_timestamp() as transformed_at
from ranked
where repository_rank = 1
