with line_rollup as (
    select
        order_id,
        count(*) as order_line_count,
        count(distinct product_id) as distinct_product_count,
        sum(quantity) as units_sold,
        sum(gross_line_sales_usd) as calculated_gross_sales_usd,
        sum(allocated_discount_usd) as discount_amount_usd,
        sum(net_line_sales_usd) as allocated_net_sales_usd,
        sum(estimated_cogs_usd) as estimated_cogs_usd,
        sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('int_order_lines_enriched') }}
    group by order_id
)

select
    o.order_id,
    l.order_line_count,
    l.distinct_product_count,
    l.units_sold,
    l.calculated_gross_sales_usd,
    o.subtotal_usd as source_subtotal_usd,
    cast(l.calculated_gross_sales_usd - o.subtotal_usd as decimal(18, 4)) as subtotal_difference_usd,
    l.discount_amount_usd,
    l.allocated_net_sales_usd,
    o.total_usd as source_total_usd,
    cast(l.allocated_net_sales_usd - o.total_usd as decimal(18, 4)) as net_sales_difference_usd,
    l.estimated_cogs_usd,
    l.estimated_gross_profit_usd,
    abs(l.calculated_gross_sales_usd - o.subtotal_usd) <= 0.01 as is_subtotal_reconciled,
    abs(l.allocated_net_sales_usd - o.total_usd) <= 0.01 as is_net_sales_reconciled,
    (
        abs(l.calculated_gross_sales_usd - o.subtotal_usd) <= 0.01
        and abs(l.allocated_net_sales_usd - o.total_usd) <= 0.01
    ) as is_financially_reconciled
from {{ ref('stg_orders') }} as o
left join line_rollup as l using (order_id)
