with mart_totals as (
    select
        sum(orders) as orders,
        sum(net_sales_usd) as net_sales_usd
    from {{ ref('mart_executive_daily') }}
),
fact_totals as (
    select
        count(*) as orders,
        sum(net_sales_usd) as net_sales_usd
    from {{ ref('fct_orders') }}
)
select *
from mart_totals
cross join fact_totals
where
    mart_totals.orders != fact_totals.orders
    or abs(mart_totals.net_sales_usd - fact_totals.net_sales_usd) > 0.01
