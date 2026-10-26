{{
  config(
    tags=['gold', 'dimension']
  )
}}

with date_spine as (

    select calendar_date
    from unnest(
        generate_date_array(
            date_sub(date('{{ var("bronze_start_date") }}'), interval 1 day),
            date_add(date('{{ var("bronze_end_date") }}'), interval 1 day)
        )
    ) as calendar_date

)

select
    format_date('%Y%m%d', calendar_date) as date_key,
    calendar_date,
    extract(year from calendar_date) as year_number,
    extract(quarter from calendar_date) as quarter_number,
    extract(month from calendar_date) as month_number,
    format_date('%B', calendar_date) as month_name,
    extract(week from calendar_date) as week_number,
    extract(dayofweek from calendar_date) as day_of_week_number,
    format_date('%A', calendar_date) as day_of_week_name,
    calendar_date = date_trunc(calendar_date, month) as is_first_day_of_month,
    calendar_date = last_day(calendar_date, month) as is_last_day_of_month,
    current_timestamp() as loaded_at
from date_spine
