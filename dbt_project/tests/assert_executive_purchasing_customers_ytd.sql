with customer_first_purchase_by_year as (
    select
        customer_id,
        min(order_date) as first_purchase_date_in_year
    from {{ ref('fct_orders') }}
    group by
        customer_id,
        year(order_date)
),

customer_first_purchase_daily as (
    select
        first_purchase_date_in_year as date_day,
        count(*) as first_purchase_customers
    from customer_first_purchase_by_year
    group by first_purchase_date_in_year
),

expected as (
    select
        d.date_day,
        sum(coalesce(c.first_purchase_customers, 0)) over (
            partition by year(d.date_day)
            order by d.date_day
            rows between unbounded preceding and current row
        ) as purchasing_customers_ytd
    from {{ ref('dim_date') }} as d
    left join customer_first_purchase_daily as c using (date_day)
)

select
    a.date_day,
    a.purchasing_customers_ytd as actual_purchasing_customers_ytd,
    e.purchasing_customers_ytd as expected_purchasing_customers_ytd
from {{ ref('mart_executive_daily') }} as a
inner join expected as e using (date_day)
where a.purchasing_customers_ytd != e.purchasing_customers_ytd
