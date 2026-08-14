with purchase_events as (
    select
        e.event_id,
        e.session_id,
        s.customer_id,
        e.event_at as purchased_at,
        e.payment_method as event_payment_method,
        e.discount_pct as event_discount_pct,
        e.amount_usd as event_amount_usd,
        s.session_source,
        s.session_device,
        s.session_country
    from {{ ref('stg_events') }} as e
    inner join {{ ref('stg_sessions') }} as s using (session_id)
    where e.event_type = 'purchase'
)

select
    p.event_id,
    p.session_id,
    p.customer_id,
    p.purchased_at,
    o.order_id,
    o.ordered_at,
    p.event_payment_method,
    p.event_discount_pct,
    p.event_amount_usd,
    o.payment_method as order_payment_method,
    o.discount_pct as order_discount_pct,
    o.total_usd as order_total_usd,
    p.session_source,
    p.session_device,
    p.session_country,
    o.order_source,
    o.order_device,
    o.order_country,
    p.session_source = o.order_source as is_source_match,
    p.session_device = o.order_device as is_device_match,
    p.session_country = o.order_country as is_country_match,
    cast('customer_timestamp_amount_discount_payment' as varchar) as match_method
from purchase_events as p
left join {{ ref('stg_orders') }} as o
    on p.customer_id = o.customer_id
    and p.purchased_at = o.ordered_at
    and p.event_payment_method = o.payment_method
    and p.event_discount_pct = o.discount_pct
    and abs(p.event_amount_usd - o.total_usd) < 0.01
