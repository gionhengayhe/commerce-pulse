with order_by_session as (
    select
        matched_session_id as session_id,
        count(*) as orders,
        count(*) filter (where is_first_order) as first_orders,
        sum(gross_sales_usd) as gross_sales_usd,
        sum(discount_amount_usd) as discount_amount_usd,
        sum(net_sales_usd) as net_sales_usd,
        sum(estimated_cogs_usd) as estimated_cogs_usd,
        sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('fct_orders') }}
    group by matched_session_id
),

session_enriched as (
    select
        s.*,
        coalesce(o.orders, 0) as orders,
        coalesce(o.first_orders, 0) as first_orders,
        coalesce(o.gross_sales_usd, 0) as gross_sales_usd,
        coalesce(o.discount_amount_usd, 0) as discount_amount_usd,
        coalesce(o.net_sales_usd, 0) as net_sales_usd,
        coalesce(o.estimated_cogs_usd, 0) as estimated_cogs_usd,
        coalesce(o.estimated_gross_profit_usd, 0) as estimated_gross_profit_usd
    from {{ ref('fct_sessions') }} as s
    left join order_by_session as o using (session_id)
)

select
    session_date as date_day,
    session_source,
    session_device,
    session_country,
    count(distinct customer_id) as visitors,
    count(*) as sessions,
    count(*) filter (where has_view) as view_sessions,
    count(*) filter (where has_add_to_cart) as cart_sessions,
    count(*) filter (where has_checkout) as checkout_sessions,
    count(*) filter (where has_purchase) as purchase_sessions,
    sum(orders) as orders,
    count(distinct customer_id) filter (where orders > 0) as purchasing_customers,
    count(distinct customer_id) filter (where first_orders > 0) as new_purchasing_customers,
    sum(gross_sales_usd) as gross_sales_usd,
    sum(discount_amount_usd) as discount_amount_usd,
    sum(net_sales_usd) as net_sales_usd,
    sum(estimated_cogs_usd) as estimated_cogs_usd,
    sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
from session_enriched
group by
    session_date,
    session_source,
    session_device,
    session_country
