with order_rollup as (
    select
        matched_session_id as session_id,
        sum(gross_sales_usd) as gross_sales_usd,
        sum(discount_amount_usd) as discount_amount_usd,
        sum(net_sales_usd) as net_sales_usd,
        sum(estimated_cogs_usd) as estimated_cogs_usd,
        sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('fct_orders') }}
    group by matched_session_id
)

select
    s.session_id,
    s.customer_id,
    s.session_started_at,
    cast(s.session_started_at as date) as session_date,
    s.session_source,
    s.session_device,
    s.session_country,
    s.last_event_at,
    s.observed_activity_span_seconds,
    s.event_count,
    s.page_view_event_count,
    s.add_to_cart_event_count,
    s.checkout_event_count,
    s.purchase_event_count,
    s.distinct_products_viewed,
    s.distinct_products_added_to_cart,
    s.units_added_to_cart,
    s.has_view,
    s.has_add_to_cart,
    s.has_checkout,
    s.has_purchase,
    s.first_view_at,
    s.first_add_to_cart_at,
    s.first_checkout_at,
    s.first_purchase_at,
    s.matched_order_count,
    coalesce(o.gross_sales_usd, 0) as gross_sales_usd,
    coalesce(o.discount_amount_usd, 0) as discount_amount_usd,
    coalesce(o.net_sales_usd, 0) as net_sales_usd,
    coalesce(o.estimated_cogs_usd, 0) as estimated_cogs_usd,
    coalesce(o.estimated_gross_profit_usd, 0) as estimated_gross_profit_usd
from {{ ref('int_session_funnel') }} as s
left join order_rollup as o using (session_id)
