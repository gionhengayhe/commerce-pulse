with observed_dates as (
    select signup_date as observed_date from {{ ref('stg_customers') }}
    union all
    select cast(session_started_at as date) from {{ ref('stg_sessions') }}
    union all
    select cast(event_at as date) from {{ ref('stg_events') }}
    union all
    select cast(ordered_at as date) from {{ ref('stg_orders') }}
    union all
    select cast(reviewed_at as date) from {{ ref('stg_reviews') }}
),

bounds as (
    select
        min(observed_date) as min_date,
        max(observed_date) as max_date
    from observed_dates
),

date_spine as (
    select cast(generated_date as date) as date_day
    from bounds,
    generate_series(min_date, max_date, interval 1 day) as dates(generated_date)
)

select
    date_day,
    year(date_day) as year,
    quarter(date_day) as quarter,
    month(date_day) as month_number,
    strftime(date_day, '%B') as month_name,
    cast(date_trunc('month', date_day) as date) as year_month,
    week(date_day) as week_of_year,
    day(date_day) as day_of_month,
    isodow(date_day) as day_of_week_number,
    strftime(date_day, '%A') as day_of_week_name,
    isodow(date_day) in (6, 7) as is_weekend
from date_spine
