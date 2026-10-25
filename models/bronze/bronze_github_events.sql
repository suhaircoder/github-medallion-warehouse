{{
  config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      "field": "event_created_at",
      "data_type": "timestamp",
      "granularity": "day"
    },
    cluster_by=['event_type', 'repo_id', 'actor_id'],
    require_partition_filter=true,
    tags=['bronze', 'github_archive']
  )
}}

with source_events as (

    select
        id as event_id,
        type as event_type,
        public as is_public,
        payload,
        repo.id as repo_id,
        repo.name as repo_name,
        repo.url as repo_url,
        actor.id as actor_id,
        actor.login as actor_login,
        actor.url as actor_url,
        actor.avatar_url as actor_avatar_url,
        org.id as org_id,
        org.login as org_login,
        org.url as org_url,
        created_at as event_created_at,
        parse_date('%Y%m%d', _table_suffix) as source_table_date,
        _table_suffix as source_table_suffix
    from `githubarchive.day.*`
    where _table_suffix between format_date('%Y%m%d', date('{{ var("bronze_start_date") }}'))
                            and format_date('%Y%m%d', date('{{ var("bronze_end_date") }}'))

),

payload_enriched as (

    select
        source_events.*,
        json_value(payload, '$.action') as payload_action,
        json_value(payload, '$.ref') as payload_ref,
        json_value(payload, '$.ref_type') as payload_ref_type,
        json_value(payload, '$.pull_request.id') as pull_request_id,
        json_value(payload, '$.pull_request.number') as pull_request_number,
        json_value(payload, '$.pull_request.state') as pull_request_state,
        json_value(payload, '$.issue.id') as issue_id,
        json_value(payload, '$.issue.number') as issue_number,
        json_value(payload, '$.issue.state') as issue_state,
        json_value(payload, '$.release.id') as release_id,
        json_value(payload, '$.size') as push_size,
        json_value(payload, '$.distinct_size') as push_distinct_size,
        json_query_array(payload, '$.commits') as push_commits
    from source_events

),

commit_flattened as (

    select
        payload_enriched.* except (push_commits),
        commit_offset + 1 as commit_sequence_number,
        json_value(commit_json, '$.sha') as commit_sha,
        json_value(commit_json, '$.author.name') as commit_author_name,
        json_value(commit_json, '$.author.email') as commit_author_email,
        json_value(commit_json, '$.message') as commit_message
    from payload_enriched
    left join unnest(
        if(
            coalesce(array_length(push_commits), 0) > 0,
            push_commits,
            [cast(null as string)]
        )
    ) as commit_json with offset as commit_offset

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by event_id, coalesce(commit_sha, '__no_commit__')
            order by event_created_at desc, source_table_suffix desc
        ) as event_commit_dedupe_rank
    from commit_flattened

)

select
    event_id,
    event_type,
    is_public,
    repo_id,
    repo_name,
    repo_url,
    actor_id,
    actor_login,
    actor_url,
    actor_avatar_url,
    org_id,
    org_login,
    org_url,
    event_created_at,
    source_table_date,
    source_table_suffix,
    payload_action,
    payload_ref,
    payload_ref_type,
    safe_cast(pull_request_id as int64) as pull_request_id,
    safe_cast(pull_request_number as int64) as pull_request_number,
    pull_request_state,
    safe_cast(issue_id as int64) as issue_id,
    safe_cast(issue_number as int64) as issue_number,
    issue_state,
    safe_cast(release_id as int64) as release_id,
    safe_cast(push_size as int64) as push_size,
    safe_cast(push_distinct_size as int64) as push_distinct_size,
    commit_sequence_number,
    commit_sha,
    commit_author_name,
    commit_author_email,
    commit_message,
    payload as raw_payload,
    current_timestamp() as loaded_at
from deduplicated
where event_commit_dedupe_rank = 1
