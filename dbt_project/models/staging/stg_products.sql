select
    cast(product_id as bigint) as product_id,
    trim(category) as category,
    trim(name) as product_name,
    cast(price_usd as decimal(18, 2)) as price_usd,
    cast(cost_usd as decimal(18, 2)) as cost_usd,
    cast(margin_usd as decimal(18, 2)) as margin_usd
from {{ source('raw', 'products') }}
