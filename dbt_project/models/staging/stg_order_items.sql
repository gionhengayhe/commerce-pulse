select
    cast(_source_row_number as bigint) as source_row_number,
    cast(order_id as bigint) as order_id,
    cast(product_id as bigint) as product_id,
    cast(unit_price_usd as decimal(18, 2)) as unit_price_usd,
    cast(quantity as integer) as quantity,
    cast(line_total_usd as decimal(18, 2)) as line_total_usd
from {{ source('raw', 'order_items') }}
