with mart_totals as (
    select
        sum(orders) as orders,
        sum(gross_sales_usd) as gross_sales_usd,
        sum(discount_amount_usd) as discount_amount_usd,
        sum(net_sales_usd) as net_sales_usd,
        sum(estimated_cogs_usd) as estimated_cogs_usd,
        sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('mart_channel_funnel_daily') }}
),
fact_totals as (
    select
        count(*) as orders,
        sum(gross_sales_usd) as gross_sales_usd,
        sum(discount_amount_usd) as discount_amount_usd,
        sum(net_sales_usd) as net_sales_usd,
        sum(estimated_cogs_usd) as estimated_cogs_usd,
        sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('fct_orders') }}
)
select *
from mart_totals
cross join fact_totals
where
    mart_totals.orders != fact_totals.orders
    or abs(mart_totals.gross_sales_usd - fact_totals.gross_sales_usd) > 0.01
    or abs(mart_totals.discount_amount_usd - fact_totals.discount_amount_usd) > 0.01
    or abs(mart_totals.net_sales_usd - fact_totals.net_sales_usd) > 0.01
    or abs(mart_totals.estimated_cogs_usd - fact_totals.estimated_cogs_usd) > 0.01
    or abs(mart_totals.estimated_gross_profit_usd - fact_totals.estimated_gross_profit_usd) > 0.01
