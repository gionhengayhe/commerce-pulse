with source_fact_counts as (
    select 'customers' as metric, count(*)::decimal(38, 4) as metric_value from {{ ref('dim_customer') }}
    union all select 'products', count(*)::decimal(38, 4) from {{ ref('dim_product') }}
    union all select 'sessions', count(*)::decimal(38, 4) from {{ ref('fct_sessions') }}
    union all select 'events', count(*)::decimal(38, 4) from {{ ref('fct_events') }}
    union all select 'orders', count(*)::decimal(38, 4) from {{ ref('fct_orders') }}
    union all select 'order_lines', count(*)::decimal(38, 4) from {{ ref('fct_order_lines') }}
    union all select 'reviews', count(*)::decimal(38, 4) from {{ ref('fct_reviews') }}
),

financials as (
    select 'order_gross_sales_usd' as metric, sum(gross_sales_usd)::decimal(38, 4) as metric_value from {{ ref('fct_orders') }}
    union all select 'order_discount_usd', sum(discount_amount_usd)::decimal(38, 4) from {{ ref('fct_orders') }}
    union all select 'order_net_sales_usd', sum(net_sales_usd)::decimal(38, 4) from {{ ref('fct_orders') }}
    union all select 'order_estimated_cogs_usd', sum(estimated_cogs_usd)::decimal(38, 4) from {{ ref('fct_orders') }}
    union all select 'order_estimated_gross_profit_usd', sum(estimated_gross_profit_usd)::decimal(38, 4) from {{ ref('fct_orders') }}
    union all select 'executive_net_sales_usd', sum(net_sales_usd)::decimal(38, 4) from {{ ref('mart_executive_daily') }}
    union all select 'channel_net_sales_usd', sum(net_sales_usd)::decimal(38, 4) from {{ ref('mart_channel_funnel_daily') }}
    union all select 'product_net_sales_usd', sum(net_sales_usd)::decimal(38, 4) from {{ ref('mart_product_performance_monthly') }}
    union all select 'category_net_sales_usd', sum(net_sales_usd)::decimal(38, 4) from {{ ref('mart_category_performance_monthly') }}
),

funnel as (
    select 'sessions' as metric, count(*)::decimal(38, 4) as metric_value from {{ ref('fct_sessions') }}
    union all select 'view_sessions', count(*) filter (where has_view)::decimal(38, 4) from {{ ref('fct_sessions') }}
    union all select 'cart_sessions', count(*) filter (where has_add_to_cart)::decimal(38, 4) from {{ ref('fct_sessions') }}
    union all select 'checkout_sessions', count(*) filter (where has_checkout)::decimal(38, 4) from {{ ref('fct_sessions') }}
    union all select 'purchase_sessions', count(*) filter (where has_purchase)::decimal(38, 4) from {{ ref('fct_sessions') }}
),

customer as (
    select 'total_customers' as metric, count(*)::decimal(38, 4) as metric_value from {{ ref('mart_customer_lifecycle') }}
    union all select 'purchasing_customers', count(*) filter (where order_count > 0)::decimal(38, 4) from {{ ref('mart_customer_lifecycle') }}
    union all select 'repeat_customers', count(*) filter (where is_repeat_customer)::decimal(38, 4) from {{ ref('mart_customer_lifecycle') }}
    union all select 'eligible_30d', count(*) filter (where is_eligible_30d)::decimal(38, 4) from {{ ref('mart_customer_lifecycle') }}
    union all select 'repeat_30d', count(*) filter (where is_eligible_30d and repeat_30d)::decimal(38, 4) from {{ ref('mart_customer_lifecycle') }}
    union all select 'eligible_60d', count(*) filter (where is_eligible_60d)::decimal(38, 4) from {{ ref('mart_customer_lifecycle') }}
    union all select 'repeat_60d', count(*) filter (where is_eligible_60d and repeat_60d)::decimal(38, 4) from {{ ref('mart_customer_lifecycle') }}
    union all select 'eligible_90d', count(*) filter (where is_eligible_90d)::decimal(38, 4) from {{ ref('mart_customer_lifecycle') }}
    union all select 'repeat_90d', count(*) filter (where is_eligible_90d and repeat_90d)::decimal(38, 4) from {{ ref('mart_customer_lifecycle') }}
)

select 'SOURCE_FACT_COUNTS' as report_section, metric, metric_value from source_fact_counts
union all
select 'FINANCIAL_RECONCILIATION', metric, metric_value from financials
union all
select 'FUNNEL', metric, metric_value from funnel
union all
select 'CUSTOMER', metric, metric_value from customer
