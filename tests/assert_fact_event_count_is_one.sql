select
    event_key,
    event_count
from {{ ref('fact_github_events') }}
where event_count != 1
