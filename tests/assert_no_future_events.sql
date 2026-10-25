select
    event_id,
    event_created_at
from {{ ref('bronze_github_events') }}
where event_created_at > current_timestamp()
