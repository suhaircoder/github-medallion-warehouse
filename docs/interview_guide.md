# Interview Guide

## Project Pitch

I built a production-style analytics warehouse on BigQuery using dbt Core and
GitHub Archive public data. The project implements a Medallion Architecture,
parses nested JSON payloads, flattens commit arrays with `UNNEST()`, deduplicates
events with window functions, optimizes BigQuery tables with partitioning and
clustering, and publishes analytics-ready facts, dimensions, and marts.

## Why This Dataset

GitHub Archive is useful for a portfolio because it behaves like a real event
stream:

- high volume
- semi-structured JSON
- nested arrays
- multiple event types
- actor, repository, issue, pull request, and commit activity

## Architecture Explanation

Bronze keeps raw event context and extracts common payload fields.

Silver cleans and normalizes the data into reusable event and entity models.

Gold exposes a star schema with conformed dimensions and measurable facts.

Marts answer analytics questions such as repository activity, contributor
activity, and project health.

## Technical Highlights

- BigQuery wildcard tables: `githubarchive.day.*`
- Cost control with `_TABLE_SUFFIX`
- JSON extraction with `json_value()`
- Array flattening with `UNNEST()`
- Deduplication with `row_number()`
- Lifecycle analysis with `lag()`, `min()`, and `max()` window functions
- Rolling metrics with window frames
- Partitioning by event date
- Clustering by event, repository, actor, and commit keys
- dbt tests for uniqueness, not-null checks, relationships, and accepted values
- dbt exposures to document downstream analytics assets
- GitHub Actions workflow for CI

## How To Explain The Star Schema

Facts store measurable activity:

- `fact_github_events`
- `fact_pushes`
- `fact_pull_requests`
- `fact_issues`

Dimensions provide descriptive context:

- `dim_date`
- `dim_actor`
- `dim_repository`
- `dim_organization`
- `dim_event_type`

## Strong Interview Answer

The most challenging part was designing a clean event model from semi-structured
source data. GitHub events share common fields, but each event type has different
payload attributes. I solved this by keeping Bronze flexible, then creating typed
Silver models for events, commits, pull requests, and issues. Gold then joins
those cleaned models into a star schema optimized for analytics.

## Questions This Warehouse Can Answer

- Which repositories have the most daily activity?
- Which actors contribute across the most repositories?
- Which repositories have the highest pull request and issue activity?
- Which projects show strong health signals from contributors, commits, PRs, and issues?
- How does repository activity trend over time?
