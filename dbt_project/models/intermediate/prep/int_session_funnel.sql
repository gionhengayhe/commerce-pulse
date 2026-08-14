with event_rollup as (
    select
        s.session_id,
        s.customer_id,
        s.session_started_at,
        s.session_source,
        s.session_device,
        s.session_country,
        count(e.event_id) as event_count,
        count(e.event_id) filter (where e.event_type = 'page_view') as page_view_event_count,
        count(e.event_id) filter (where e.event_type = 'add_to_cart') as add_to_cart_event_count,
        count(e.event_id) filter (where e.event_type = 'checkout') as checkout_event_count,
        count(e.event_id) filter (where e.event_type = 'purchase') as purchase_event_count,
        count(distinct e.product_id) filter (where e.event_type = 'page_view') as distinct_products_viewed,
        count(distinct e.product_id) filter (where e.event_type = 'add_to_cart') as distinct_products_added_to_cart,
        coalesce(sum(e.quantity) filter (where e.event_type = 'add_to_cart'), 0) as units_added_to_cart,
        count(e.event_id) filter (where e.event_type = 'page_view') > 0 as has_view,
        count(e.event_id) filter (where e.event_type = 'add_to_cart') > 0 as has_add_to_cart,
        count(e.event_id) filter (where e.event_type = 'checkout') > 0 as has_checkout,
        count(e.event_id) filter (where e.event_type = 'purchase') > 0 as has_purchase,
        min(e.event_at) filter (where e.event_type = 'page_view') as first_view_at,
        min(e.event_at) filter (where e.event_type = 'add_to_cart') as first_add_to_cart_at,
        min(e.event_at) filter (where e.event_type = 'checkout') as first_checkout_at,
        min(e.event_at) filter (where e.event_type = 'purchase') as first_purchase_at,
        max(e.event_at) as last_event_at
    from {{ ref('stg_sessions') }} as s
    left join {{ ref('stg_events') }} as e using (session_id)
    group by
        s.session_id,
        s.customer_id,
        s.session_started_at,
        s.session_source,
        s.session_device,
        s.session_country
),

matched_orders as (
    select
        session_id,
        count(distinct order_id) as matched_order_count
    from {{ ref('int_purchase_events_matched_to_orders') }}
    group by session_id
)

select
    e.session_id,
    e.customer_id,
    e.session_started_at,
    e.session_source,
    e.session_device,
    e.session_country,
    e.event_count,
    e.page_view_event_count,
    e.add_to_cart_event_count,
    e.checkout_event_count,
    e.purchase_event_count,
    e.distinct_products_viewed,
    e.distinct_products_added_to_cart,
    e.units_added_to_cart,
    e.has_view,
    e.has_add_to_cart,
    e.has_checkout,
    e.has_purchase,
    e.first_view_at,
    e.first_add_to_cart_at,
    e.first_checkout_at,
    e.first_purchase_at,
    e.last_event_at,
    date_diff('second', e.session_started_at, e.last_event_at) as observed_activity_span_seconds,
    coalesce(m.matched_order_count, 0) as matched_order_count
from event_rollup as e
left join matched_orders as m using (session_id)
