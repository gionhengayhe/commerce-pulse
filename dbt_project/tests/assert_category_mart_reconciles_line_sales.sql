with mart_totals as (
    select sum(net_sales_usd) as net_sales_usd
    from {{ ref('mart_category_performance_monthly') }}
),
fact_totals as (
    select sum(net_line_sales_usd) as net_sales_usd
    from {{ ref('fct_order_lines') }}
)
select *
from mart_totals
cross join fact_totals
where abs(mart_totals.net_sales_usd - fact_totals.net_sales_usd) > 0.01
