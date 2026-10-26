select
    fact_github_events.event_key,
    fact_github_events.event_family as fact_event_family,
    dim_event_type.event_family as dimension_event_family
from {{ ref('fact_github_events') }} as fact_github_events
inner join {{ ref('dim_event_type') }} as dim_event_type
    on fact_github_events.event_type_key = dim_event_type.event_type_key
where fact_github_events.event_family != dim_event_type.event_family
