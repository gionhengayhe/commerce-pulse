with session_daily as (
    select
        session_date as date_day,
        count(distinct customer_id) as visitors,
        count(*) as sessions,
        count(*) filter (where has_view) as view_sessions,
        count(*) filter (where has_add_to_cart) as cart_sessions,
        count(*) filter (where has_checkout) as checkout_sessions,
        count(*) filter (where has_purchase) as purchase_sessions
    from {{ ref('fct_sessions') }}
    group by session_date
),

order_daily as (
    select
        order_date as date_day,
        count(*) as orders,
        count(distinct customer_id) as purchasing_customers,
        count(distinct customer_id) filter (where is_first_order) as new_purchasing_customers,
        count(distinct customer_id) filter (where is_repeat_order) as repeat_purchasing_customers,
        sum(gross_sales_usd) as gross_sales_usd,
        sum(discount_amount_usd) as discount_amount_usd,
        sum(net_sales_usd) as net_sales_usd,
        sum(estimated_cogs_usd) as estimated_cogs_usd,
        sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('fct_orders') }}
    group by order_date
),

customer_first_purchase_by_year as (
    select
        customer_id,
        min(order_date) as first_purchase_date_in_year
    from {{ ref('fct_orders') }}
    group by
        customer_id,
        year(order_date)
),

customer_first_purchase_daily as (
    select
        first_purchase_date_in_year as date_day,
        count(*) as first_purchase_customers
    from customer_first_purchase_by_year
    group by first_purchase_date_in_year
),

customer_ytd as (
    select
        d.date_day,
        sum(coalesce(c.first_purchase_customers, 0)) over (
            partition by year(d.date_day)
            order by d.date_day
            rows between unbounded preceding and current row
        ) as purchasing_customers_ytd
    from {{ ref('dim_date') }} as d
    left join customer_first_purchase_daily as c using (date_day)
),

line_daily as (
    select
        order_date as date_day,
        sum(quantity) as units_sold
    from {{ ref('fct_order_lines') }}
    group by order_date
)

select
    d.date_day,
    coalesce(s.visitors, 0) as visitors,
    coalesce(s.sessions, 0) as sessions,
    coalesce(s.view_sessions, 0) as view_sessions,
    coalesce(s.cart_sessions, 0) as cart_sessions,
    coalesce(s.checkout_sessions, 0) as checkout_sessions,
    coalesce(s.purchase_sessions, 0) as purchase_sessions,
    coalesce(o.orders, 0) as orders,
    coalesce(o.purchasing_customers, 0) as purchasing_customers,
    coalesce(o.new_purchasing_customers, 0) as new_purchasing_customers,
    coalesce(o.repeat_purchasing_customers, 0) as repeat_purchasing_customers,
    coalesce(l.units_sold, 0) as units_sold,
    coalesce(o.gross_sales_usd, 0) as gross_sales_usd,
    coalesce(o.discount_amount_usd, 0) as discount_amount_usd,
    coalesce(o.net_sales_usd, 0) as net_sales_usd,
    coalesce(o.estimated_cogs_usd, 0) as estimated_cogs_usd,
    coalesce(o.estimated_gross_profit_usd, 0) as estimated_gross_profit_usd,
    coalesce(c.purchasing_customers_ytd, 0) as purchasing_customers_ytd
from {{ ref('dim_date') }} as d
left join session_daily as s using (date_day)
left join order_daily as o using (date_day)
left join line_daily as l using (date_day)
left join customer_ytd as c using (date_day)
