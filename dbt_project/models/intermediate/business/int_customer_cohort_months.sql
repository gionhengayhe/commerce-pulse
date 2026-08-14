with customer_cohorts as (
    select
        customer_id,
        min(order_date) as first_order_date,
        cast(date_trunc('month', min(order_date)) as date) as first_order_cohort_month
    from {{ ref('fct_orders') }}
    group by customer_id
),

observation as (
    select
        cast(date_trunc('month', max(order_date)) as date) as observation_month,
        date_diff(
            'month',
            min(cast(date_trunc('month', order_date) as date)),
            max(cast(date_trunc('month', order_date) as date))
        ) as max_horizon
    from {{ ref('fct_orders') }}
),

month_offsets as (
    select months_since_first_order
    from observation,
    generate_series(0, max_horizon) as offsets(months_since_first_order)
),

customer_months as (
    select
        c.customer_id,
        c.first_order_date,
        c.first_order_cohort_month,
        m.months_since_first_order,
        cast(
            c.first_order_cohort_month
            + (m.months_since_first_order * interval '1 month')
            as date
        ) as activity_month,
        o.observation_month
    from customer_cohorts as c
    cross join month_offsets as m
    cross join observation as o
    where cast(
        c.first_order_cohort_month
        + (m.months_since_first_order * interval '1 month')
        as date
    ) <= o.observation_month
),

monthly_orders as (
    select
        customer_id,
        cast(date_trunc('month', order_date) as date) as activity_month,
        count(*) as order_count,
        sum(net_sales_usd) as net_sales_usd,
        sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('fct_orders') }}
    group by customer_id, cast(date_trunc('month', order_date) as date)
)

select
    c.customer_id,
    c.first_order_date,
    c.first_order_cohort_month,
    c.months_since_first_order,
    c.activity_month,
    true as is_eligible,
    coalesce(o.order_count, 0) > 0 as is_active,
    coalesce(o.order_count, 0) as order_count,
    coalesce(o.net_sales_usd, 0) as net_sales_usd,
    coalesce(o.estimated_gross_profit_usd, 0) as estimated_gross_profit_usd
from customer_months as c
left join monthly_orders as o using (customer_id, activity_month)
