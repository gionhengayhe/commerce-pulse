select
    p.session_id,
    p.customer_id,
    d.category,
    p.session_date,
    p.session_source,
    p.session_device,
    p.session_country,
    sum(p.view_event_count) as view_event_count,
    sum(p.add_to_cart_event_count) as add_to_cart_event_count,
    sum(p.units_added_to_cart) as units_added_to_cart,
    bool_or(p.has_view) as has_view,
    bool_or(p.has_add_to_cart) as has_add_to_cart,
    bool_or(p.has_purchase) as has_purchase,
    sum(p.purchased_quantity) as purchased_quantity,
    sum(p.gross_sales_usd) as gross_sales_usd,
    sum(p.discount_amount_usd) as discount_amount_usd,
    sum(p.net_sales_usd) as net_sales_usd,
    sum(p.estimated_cogs_usd) as estimated_cogs_usd,
    sum(p.estimated_gross_profit_usd) as estimated_gross_profit_usd
from {{ ref('int_product_session') }} as p
inner join {{ ref('dim_product') }} as d using (product_id)
group by
    p.session_id,
    p.customer_id,
    d.category,
    p.session_date,
    p.session_source,
    p.session_device,
    p.session_country
