select
    o.order_id,
    o.customer_id,
    m.session_id as matched_session_id,
    o.ordered_at,
    cast(o.ordered_at as date) as order_date,
    o.payment_method,
    o.order_source,
    o.order_device,
    o.order_country,
    m.session_source,
    m.session_device,
    m.session_country,
    s.customer_order_number,
    s.is_first_order,
    s.is_repeat_order,
    s.previous_order_at,
    s.days_since_previous_order,
    f.order_line_count,
    f.distinct_product_count,
    f.units_sold,
    f.source_subtotal_usd as gross_sales_usd,
    o.discount_pct,
    f.discount_amount_usd,
    f.source_total_usd as net_sales_usd,
    f.estimated_cogs_usd,
    f.estimated_gross_profit_usd
from {{ ref('stg_orders') }} as o
inner join {{ ref('int_order_financials') }} as f using (order_id)
inner join {{ ref('int_customer_order_sequence') }} as s using (order_id)
left join {{ ref('int_purchase_events_matched_to_orders') }} as m using (order_id)
