{{
  config(
    cluster_by=['org_id', 'org_login'],
    tags=['gold', 'dimension']
  )
}}

select
    {{ generate_surrogate_key(['org_id']) }} as organization_key,
    org_id,
    org_login,
    org_url,
    first_seen_at,
    last_seen_at,
    observed_event_rows,
    current_timestamp() as loaded_at
from {{ ref('silver_organizations') }}
