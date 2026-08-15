with mart_totals as (
    select
        sum(units_sold) as units_sold,
        sum(gross_sales_usd) as gross_sales_usd,
        sum(discount_amount_usd) as discount_amount_usd,
        sum(net_sales_usd) as net_sales_usd,
        sum(estimated_cogs_usd) as estimated_cogs_usd,
        sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('mart_category_performance_monthly') }}
),
fact_totals as (
    select
        sum(quantity) as units_sold,
        sum(gross_line_sales_usd) as gross_sales_usd,
        sum(allocated_discount_usd) as discount_amount_usd,
        sum(net_line_sales_usd) as net_sales_usd,
        sum(estimated_cogs_usd) as estimated_cogs_usd,
        sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('fct_order_lines') }}
)
select *
from mart_totals
cross join fact_totals
where
    mart_totals.units_sold != fact_totals.units_sold
    or abs(mart_totals.gross_sales_usd - fact_totals.gross_sales_usd) > 0.01
    or abs(mart_totals.discount_amount_usd - fact_totals.discount_amount_usd) > 0.01
    or abs(mart_totals.net_sales_usd - fact_totals.net_sales_usd) > 0.01
    or abs(mart_totals.estimated_cogs_usd - fact_totals.estimated_cogs_usd) > 0.01
    or abs(mart_totals.estimated_gross_profit_usd - fact_totals.estimated_gross_profit_usd) > 0.01
