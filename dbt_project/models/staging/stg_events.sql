select
    cast(event_id as bigint) as event_id,
    cast(session_id as bigint) as session_id,
    cast(timestamp as timestamp) as event_at,
    trim(event_type) as event_type,
    cast(product_id as bigint) as product_id,
    cast(qty as integer) as quantity,
    cast(cart_size as integer) as cart_size,
    trim(payment) as payment_method,
    cast(discount_pct as decimal(7, 4)) as discount_pct,
    cast(amount_usd as decimal(18, 2)) as amount_usd
from {{ source('raw', 'events') }}
