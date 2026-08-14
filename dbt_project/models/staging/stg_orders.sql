select
    cast(order_id as bigint) as order_id,
    cast(customer_id as bigint) as customer_id,
    cast(order_time as timestamp) as ordered_at,
    trim(payment_method) as payment_method,
    cast(discount_pct as decimal(7, 4)) as discount_pct,
    cast(subtotal_usd as decimal(18, 2)) as subtotal_usd,
    cast(total_usd as decimal(18, 2)) as total_usd,
    trim(source) as order_source,
    trim(device) as order_device,
    trim(country) as order_country
from {{ source('raw', 'orders') }}
