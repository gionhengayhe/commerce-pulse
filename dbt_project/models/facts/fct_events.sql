select
    e.event_id,
    e.session_id,
    s.customer_id,
    e.product_id,
    m.order_id as matched_order_id,
    e.event_at,
    cast(e.event_at as date) as event_date,
    e.event_type,
    e.quantity,
    e.cart_size,
    e.payment_method,
    e.discount_pct,
    e.amount_usd,
    s.session_source,
    s.session_device,
    s.session_country
from {{ ref('stg_events') }} as e
inner join {{ ref('stg_sessions') }} as s using (session_id)
left join {{ ref('int_purchase_events_matched_to_orders') }} as m using (event_id)
