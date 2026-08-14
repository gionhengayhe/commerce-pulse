select
    order_line_key,
    source_row_number,
    order_id,
    customer_id,
    product_id,
    ordered_at,
    cast(ordered_at as date) as order_date,
    quantity,
    unit_price_usd,
    gross_line_sales_usd,
    allocated_discount_usd,
    net_line_sales_usd,
    catalog_unit_cost_usd,
    estimated_cogs_usd,
    estimated_gross_profit_usd
from {{ ref('int_order_lines_enriched') }}
