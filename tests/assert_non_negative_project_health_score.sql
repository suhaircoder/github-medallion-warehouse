select
    repository_key,
    activity_date,
    activity_health_score
from {{ ref('mart_open_source_project_health') }}
where activity_health_score < 0
