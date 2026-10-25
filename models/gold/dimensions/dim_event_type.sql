{{
  config(
    cluster_by=['event_family', 'event_type'],
    tags=['gold', 'dimension']
  )
}}

with mapped_event_types as (

    select
        event_type,
        event_family,
        cast(is_core_warehouse_event as bool) as is_core_warehouse_event
    from {{ ref('event_type_mapping') }}

),

observed_event_types as (

    select distinct
        event_type,
        event_family,
        true as is_observed_in_source_window
    from {{ ref('silver_github_events') }}

),

combined as (

    select
        observed_event_types.event_type,
        coalesce(mapped_event_types.event_family, observed_event_types.event_family, 'other') as event_family,
        coalesce(mapped_event_types.is_core_warehouse_event, false) as is_core_warehouse_event,
        observed_event_types.is_observed_in_source_window
    from observed_event_types
    left join mapped_event_types
        on observed_event_types.event_type = mapped_event_types.event_type

    union all

    select
        mapped_event_types.event_type,
        mapped_event_types.event_family,
        mapped_event_types.is_core_warehouse_event,
        false as is_observed_in_source_window
    from mapped_event_types
    left join observed_event_types
        on mapped_event_types.event_type = observed_event_types.event_type
    where observed_event_types.event_type is null

)

select
    {{ generate_surrogate_key(['event_type']) }} as event_type_key,
    event_type,
    event_family,
    is_core_warehouse_event,
    is_observed_in_source_window,
    current_timestamp() as loaded_at
from combined
