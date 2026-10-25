{{
  config(
    cluster_by=['actor_id', 'actor_login'],
    tags=['gold', 'dimension']
  )
}}

select
    {{ generate_surrogate_key(['actor_id']) }} as actor_key,
    actor_id,
    actor_login,
    actor_url,
    actor_avatar_url,
    first_seen_at,
    last_seen_at,
    observed_event_rows,
    current_timestamp() as loaded_at
from {{ ref('silver_actors') }}
