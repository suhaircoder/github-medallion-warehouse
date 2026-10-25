{{
  config(
    partition_by={
      "field": "event_created_at",
      "data_type": "timestamp",
      "granularity": "day"
    },
    cluster_by=['repository_key', 'actor_key', 'commit_sha'],
    tags=['gold', 'fact']
  )
}}

with push_commits as (

    select *
    from {{ ref('silver_push_commits') }}

)

select
    push_commits.push_commit_key,
    push_commits.event_key,
    format_date('%Y%m%d', push_commits.event_date) as date_key,
    dim_repository.repository_key,
    dim_actor.actor_key,
    dim_organization.organization_key,
    push_commits.event_id,
    push_commits.event_created_at,
    push_commits.event_date,
    push_commits.payload_ref,
    push_commits.push_size,
    push_commits.push_distinct_size,
    push_commits.commit_sequence_number,
    push_commits.commits_in_push_event,
    push_commits.commit_sha,
    push_commits.commit_author_name,
    push_commits.commit_author_email_hash,
    push_commits.commit_author_email_domain,
    push_commits.commit_message,
    1 as commit_count,
    current_timestamp() as loaded_at
from push_commits
left join {{ ref('dim_repository') }} as dim_repository
    on push_commits.repo_id = dim_repository.repo_id
left join {{ ref('dim_actor') }} as dim_actor
    on push_commits.actor_id = dim_actor.actor_id
left join {{ ref('dim_organization') }} as dim_organization
    on push_commits.org_id = dim_organization.org_id
