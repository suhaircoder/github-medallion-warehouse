{{
  config(
    cluster_by=['repo_id', 'repository_owner'],
    tags=['gold', 'dimension']
  )
}}

select
    {{ generate_surrogate_key(['repo_id']) }} as repository_key,
    repo_id,
    repo_name,
    repository_owner,
    repository_name,
    repo_url,
    first_seen_at,
    last_seen_at,
    observed_event_rows,
    active_event_timestamps,
    current_timestamp() as loaded_at
from {{ ref('silver_repositories') }}
