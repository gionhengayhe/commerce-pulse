with joined as (
    select
        md5(
            cast(i.order_id as varchar)
            || '-'
            || cast(i.source_row_number as varchar)
        ) as order_line_key,
        i.source_row_number,
        i.order_id,
        o.customer_id,
        i.product_id,
        o.ordered_at,
        i.quantity,
        i.unit_price_usd,
        i.line_total_usd as gross_line_sales_usd,
        o.subtotal_usd as order_subtotal_usd,
        o.total_usd as order_total_usd,
        o.discount_pct as order_discount_pct,
        o.total_usd / nullif(o.subtotal_usd, 0) as order_net_factor,
        p.cost_usd as catalog_unit_cost_usd
    from {{ ref('stg_order_items') }} as i
    inner join {{ ref('stg_orders') }} as o using (order_id)
    inner join {{ ref('stg_products') }} as p using (product_id)
)

select
    order_line_key,
    source_row_number,
    order_id,
    customer_id,
    product_id,
    ordered_at,
    quantity,
    unit_price_usd,
    gross_line_sales_usd,
    order_subtotal_usd,
    order_total_usd,
    order_discount_pct,
    cast(order_net_factor as decimal(18, 8)) as order_net_factor,
    cast(gross_line_sales_usd * (1 - order_net_factor) as decimal(18, 4)) as allocated_discount_usd,
    cast(gross_line_sales_usd * order_net_factor as decimal(18, 4)) as net_line_sales_usd,
    catalog_unit_cost_usd,
    cast(catalog_unit_cost_usd * quantity as decimal(18, 2)) as estimated_cogs_usd,
    cast(
        (gross_line_sales_usd * order_net_factor) - (catalog_unit_cost_usd * quantity)
        as decimal(18, 4)
    ) as estimated_gross_profit_usd
from joined
