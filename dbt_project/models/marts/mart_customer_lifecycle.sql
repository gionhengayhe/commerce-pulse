with first_session as (
    select
        customer_id,
        session_source as first_session_source,
        session_device as first_session_device,
        session_country as first_session_country
    from (
        select
            customer_id,
            session_source,
            session_device,
            session_country,
            row_number() over (
                partition by customer_id
                order by session_started_at, session_id
            ) as session_number
        from {{ ref('fct_sessions') }}
    )
    where session_number = 1
),

session_rollup as (
    select
        customer_id,
        min(session_started_at) as first_session_at,
        max(session_started_at) as last_session_at,
        count(*) as session_count
    from {{ ref('fct_sessions') }}
    group by customer_id
),

order_rollup as (
    select
        customer_id,
        min(ordered_at) as first_order_at,
        max(ordered_at) filter (where customer_order_number = 2) as second_order_at,
        max(ordered_at) as last_order_at,
        count(*) as order_count,
        sum(units_sold) as units_purchased,
        sum(gross_sales_usd) as gross_sales_usd,
        sum(discount_amount_usd) as discount_amount_usd,
        sum(net_sales_usd) as net_sales_usd,
        sum(estimated_cogs_usd) as estimated_cogs_usd,
        sum(estimated_gross_profit_usd) as estimated_gross_profit_usd
    from {{ ref('fct_orders') }}
    group by customer_id
),

product_rollup as (
    select
        l.customer_id,
        count(distinct l.product_id) as distinct_products_purchased,
        count(distinct p.category) as distinct_categories_purchased
    from {{ ref('fct_order_lines') }} as l
    inner join {{ ref('dim_product') }} as p using (product_id)
    group by l.customer_id
),

review_rollup as (
    select
        customer_id,
        count(*) as review_count,
        avg(rating) as average_rating
    from {{ ref('fct_reviews') }}
    group by customer_id
),

observation as (
    select max(date_day) as as_of_date
    from {{ ref('dim_date') }}
)

select
    c.customer_id,
    c.customer_country,
    c.age,
    c.age_band,
    c.signup_date,
    c.is_marketing_opt_in,
    s.first_session_at,
    s.last_session_at,
    f.first_session_source,
    f.first_session_device,
    f.first_session_country,
    coalesce(s.session_count, 0) as session_count,
    o.first_order_at,
    o.second_order_at,
    o.last_order_at,
    coalesce(o.order_count, 0) as order_count,
    coalesce(o.units_purchased, 0) as units_purchased,
    coalesce(p.distinct_products_purchased, 0) as distinct_products_purchased,
    coalesce(p.distinct_categories_purchased, 0) as distinct_categories_purchased,
    date_diff('day', c.signup_date, cast(o.first_order_at as date)) as days_signup_to_first_order,
    o.first_order_at is null
        or cast(o.first_order_at as date) >= c.signup_date as is_first_order_on_or_after_signup,
    date_diff('day', o.first_order_at, o.second_order_at) as days_to_second_order,
    date_diff('day', cast(o.last_order_at as date), x.as_of_date) as recency_days,
    coalesce(o.order_count, 0) > 1 as is_repeat_customer,
    o.first_order_at is not null
        and cast(o.first_order_at as date) <= x.as_of_date - interval '30 day' as is_eligible_30d,
    o.second_order_at is not null
        and o.second_order_at <= o.first_order_at + interval '30 day' as repeat_30d,
    o.first_order_at is not null
        and cast(o.first_order_at as date) <= x.as_of_date - interval '60 day' as is_eligible_60d,
    o.second_order_at is not null
        and o.second_order_at <= o.first_order_at + interval '60 day' as repeat_60d,
    o.first_order_at is not null
        and cast(o.first_order_at as date) <= x.as_of_date - interval '90 day' as is_eligible_90d,
    o.second_order_at is not null
        and o.second_order_at <= o.first_order_at + interval '90 day' as repeat_90d,
    coalesce(o.gross_sales_usd, 0) as gross_sales_usd,
    coalesce(o.discount_amount_usd, 0) as discount_amount_usd,
    coalesce(o.net_sales_usd, 0) as net_sales_usd,
    coalesce(o.estimated_cogs_usd, 0) as estimated_cogs_usd,
    coalesce(o.estimated_gross_profit_usd, 0) as estimated_gross_profit_usd,
    coalesce(r.review_count, 0) as review_count,
    r.average_rating,
    coalesce(o.order_count, 0) as frequency_orders,
    coalesce(o.net_sales_usd, 0) as monetary_net_sales_usd,
    coalesce(o.estimated_gross_profit_usd, 0) as monetary_estimated_gross_profit_usd,
    x.as_of_date
from {{ ref('dim_customer') }} as c
left join session_rollup as s using (customer_id)
left join first_session as f using (customer_id)
left join order_rollup as o using (customer_id)
left join product_rollup as p using (customer_id)
left join review_rollup as r using (customer_id)
cross join observation as x
