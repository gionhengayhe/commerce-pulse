with comparisons as (
    select
        'customers_to_dim_customer' as comparison,
        (select count(*) from {{ ref('stg_customers') }}) as source_rows,
        (select count(*) from {{ ref('dim_customer') }}) as target_rows

    union all

    select
        'products_to_dim_product',
        (select count(*) from {{ ref('stg_products') }}),
        (select count(*) from {{ ref('dim_product') }})

    union all

    select
        'sessions_to_fct_sessions',
        (select count(*) from {{ ref('stg_sessions') }}),
        (select count(*) from {{ ref('fct_sessions') }})

    union all

    select
        'events_to_fct_events',
        (select count(*) from {{ ref('stg_events') }}),
        (select count(*) from {{ ref('fct_events') }})

    union all

    select
        'orders_to_fct_orders',
        (select count(*) from {{ ref('stg_orders') }}),
        (select count(*) from {{ ref('fct_orders') }})

    union all

    select
        'order_items_to_fct_order_lines',
        (select count(*) from {{ ref('stg_order_items') }}),
        (select count(*) from {{ ref('fct_order_lines') }})

    union all

    select
        'reviews_to_fct_reviews',
        (select count(*) from {{ ref('stg_reviews') }}),
        (select count(*) from {{ ref('fct_reviews') }})
)

select *
from comparisons
where source_rows != target_rows
