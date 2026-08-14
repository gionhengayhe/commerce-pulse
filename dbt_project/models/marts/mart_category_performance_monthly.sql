with funnel as (
    select
        cast(date_trunc('month', session_date) as date) as calendar_month,
        category,
        count(distinct customer_id) filter (where has_view) as viewing_customers,
        count(*) filter (where has_view) as view_sessions,
        sum(view_event_count) as view_event_count,
        count(*) filter (where has_add_to_cart) as cart_sessions,
        sum(add_to_cart_event_count) as add_to_cart_event_count,
        sum(units_added_to_cart) as units_added_to_cart,
        count(*) filter (where has_purchase) as purchase_sessions,
        count(*) filter (where has_view and has_purchase) as viewed_purchase_sessions,
        count(distinct customer_id) filter (where has_purchase) as purchasing_customers
    from {{ ref('int_category_session') }}
    group by cast(date_trunc('month', session_date) as date), category
),

sales as (
    select
        cast(date_trunc('month', l.order_date) as date) as calendar_month,
        p.category,
        count(distinct l.order_id) as orders,
        sum(l.quantity) as units_sold,
        sum(l.gross_line_sales_usd) as gross_sales_usd,
        sum(l.allocated_discount_usd) as discount_amount_usd,
        sum(l.net_line_sales_usd) as net_sales_usd,
        sum(l.estimated_cogs_usd) as estimated_cogs_usd,
        sum(l.estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('fct_order_lines') }} as l
    inner join {{ ref('dim_product') }} as p using (product_id)
    group by cast(date_trunc('month', l.order_date) as date), p.category
),

reviews as (
    select
        cast(date_trunc('month', r.order_date) as date) as calendar_month,
        p.category,
        count(*) as review_count,
        avg(r.rating) as average_rating
    from {{ ref('fct_reviews') }} as r
    inner join {{ ref('dim_product') }} as p using (product_id)
    group by cast(date_trunc('month', r.order_date) as date), p.category
),

month_categories as (
    select calendar_month, category from funnel
    union
    select calendar_month, category from sales
    union
    select calendar_month, category from reviews
)

select
    k.calendar_month,
    k.category,
    coalesce(f.viewing_customers, 0) as viewing_customers,
    coalesce(f.view_sessions, 0) as view_sessions,
    coalesce(f.view_event_count, 0) as view_event_count,
    coalesce(f.cart_sessions, 0) as cart_sessions,
    coalesce(f.add_to_cart_event_count, 0) as add_to_cart_event_count,
    coalesce(f.units_added_to_cart, 0) as units_added_to_cart,
    coalesce(f.purchase_sessions, 0) as purchase_sessions,
    coalesce(f.viewed_purchase_sessions, 0) as viewed_purchase_sessions,
    coalesce(f.purchasing_customers, 0) as purchasing_customers,
    coalesce(s.orders, 0) as orders,
    coalesce(s.units_sold, 0) as units_sold,
    coalesce(s.gross_sales_usd, 0) as gross_sales_usd,
    coalesce(s.discount_amount_usd, 0) as discount_amount_usd,
    coalesce(s.net_sales_usd, 0) as net_sales_usd,
    coalesce(s.estimated_cogs_usd, 0) as estimated_cogs_usd,
    coalesce(s.estimated_gross_profit_usd, 0) as estimated_gross_profit_usd,
    coalesce(r.review_count, 0) as review_count,
    r.average_rating
from month_categories as k
left join funnel as f using (calendar_month, category)
left join sales as s using (calendar_month, category)
left join reviews as r using (calendar_month, category)
