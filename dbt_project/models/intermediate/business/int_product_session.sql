with event_activity as (
    select
        e.session_id,
        e.product_id,
        count(*) filter (where e.event_type = 'page_view') as view_event_count,
        count(*) filter (where e.event_type = 'add_to_cart') as add_to_cart_event_count,
        coalesce(sum(e.quantity) filter (where e.event_type = 'add_to_cart'), 0) as units_added_to_cart,
        count(*) filter (where e.event_type = 'page_view') > 0 as has_view,
        count(*) filter (where e.event_type = 'add_to_cart') > 0 as has_add_to_cart
    from {{ ref('fct_events') }} as e
    where e.product_id is not null
    group by e.session_id, e.product_id
),

purchase_activity as (
    select
        o.matched_session_id as session_id,
        l.product_id,
        sum(l.quantity) as purchased_quantity,
        sum(l.gross_line_sales_usd) as gross_sales_usd,
        sum(l.allocated_discount_usd) as discount_amount_usd,
        sum(l.net_line_sales_usd) as net_sales_usd,
        sum(l.estimated_cogs_usd) as estimated_cogs_usd,
        sum(l.estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('fct_orders') }} as o
    inner join {{ ref('fct_order_lines') }} as l using (order_id)
    group by o.matched_session_id, l.product_id
),

session_products as (
    select session_id, product_id from event_activity
    union
    select session_id, product_id from purchase_activity
)

select
    k.session_id,
    s.customer_id,
    k.product_id,
    s.session_date,
    s.session_source,
    s.session_device,
    s.session_country,
    coalesce(e.view_event_count, 0) as view_event_count,
    coalesce(e.add_to_cart_event_count, 0) as add_to_cart_event_count,
    coalesce(e.units_added_to_cart, 0) as units_added_to_cart,
    coalesce(e.has_view, false) as has_view,
    coalesce(e.has_add_to_cart, false) as has_add_to_cart,
    p.session_id is not null as has_purchase,
    coalesce(p.purchased_quantity, 0) as purchased_quantity,
    coalesce(p.gross_sales_usd, 0) as gross_sales_usd,
    coalesce(p.discount_amount_usd, 0) as discount_amount_usd,
    coalesce(p.net_sales_usd, 0) as net_sales_usd,
    coalesce(p.estimated_cogs_usd, 0) as estimated_cogs_usd,
    coalesce(p.estimated_gross_profit_usd, 0) as estimated_gross_profit_usd
from session_products as k
inner join {{ ref('fct_sessions') }} as s using (session_id)
left join event_activity as e using (session_id, product_id)
left join purchase_activity as p using (session_id, product_id)
