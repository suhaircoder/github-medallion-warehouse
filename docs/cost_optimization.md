# Cost Optimization

## BigQuery Scan Reduction

The Bronze model reads from `githubarchive.day.*` using `_TABLE_SUFFIX` filters
driven by dbt variables:

- `bronze_start_date`
- `bronze_end_date`

This prevents accidental full-history scans of GitHub Archive.

## Partitioning

Warehouse tables are partitioned on event timestamps so downstream queries can
filter by date and scan only relevant partitions.

## Clustering

Large event models are clustered by keys commonly used in filters, joins, and
aggregations:

- `event_type`
- `repo_id`
- `actor_id`

## Development Defaults

The project defaults to one week of source data. Expand the date range only when
testing broader analytics or building production-scale tables.
