{{
  config(
    partition_by={
      "field": "event_created_at",
      "data_type": "timestamp",
      "granularity": "day"
    },
    cluster_by=['repo_id', 'actor_id', 'commit_sha'],
    tags=['silver', 'pushes']
  )
}}

with push_commit_rows as (

    select
        event_id,
        repo_id,
        actor_id,
        org_id,
        event_created_at,
        date(event_created_at) as event_date,
        payload_ref,
        push_size,
        push_distinct_size,
        commit_sequence_number,
        commit_sha,
        commit_author_name,
        lower(trim(commit_author_email)) as commit_author_email,
        commit_message,
        loaded_at
    from {{ ref('bronze_github_events') }}
    where event_type = 'PushEvent'
      and commit_sha is not null

),

cleaned as (

    select
        *,
        regexp_extract(commit_author_email, r'@(.+)$') as commit_author_email_domain,
        to_hex(sha256(commit_author_email)) as commit_author_email_hash,
        row_number() over (
            partition by event_id, commit_sha
            order by event_created_at desc, loaded_at desc
        ) as commit_rank,
        count(*) over (partition by event_id) as commits_in_push_event
    from push_commit_rows

)

select
    {{ generate_surrogate_key(['event_id', 'commit_sha']) }} as push_commit_key,
    {{ generate_surrogate_key(['event_id']) }} as event_key,
    event_id,
    repo_id,
    actor_id,
    org_id,
    event_created_at,
    event_date,
    payload_ref,
    push_size,
    push_distinct_size,
    commit_sequence_number,
    commits_in_push_event,
    commit_sha,
    commit_author_name,
    commit_author_email_hash,
    commit_author_email_domain,
    commit_message,
    current_timestamp() as transformed_at
from cleaned
where commit_rank = 1
