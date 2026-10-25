# GitHub Publish Guide

## Recommended Repository Name

`github-archive-dbt-bigquery-warehouse`

## Before Publishing

Run these checks locally after configuring BigQuery:

```bash
dbt deps
dbt seed
dbt run
dbt test
dbt docs generate
```

## GitHub Secrets For CI

Add these secrets in the target GitHub repository:

- `GCP_PROJECT_ID`
- `GCP_SERVICE_ACCOUNT_JSON`

The service account should have permission to create and query BigQuery datasets
in the selected GCP project.

## Suggested Repository Description

Production-style BigQuery data warehouse using dbt Core, GitHub Archive public
data, Medallion Architecture, JSON parsing, UNNEST, star schema modeling, tests,
documentation, and CI.

## Suggested Topics

- dbt
- bigquery
- data-engineering
- analytics-engineering
- medallion-architecture
- star-schema
- sql
- github-archive
