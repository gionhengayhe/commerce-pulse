select
    product_id,
    product_name,
    category,
    price_usd as catalog_price_usd,
    cost_usd as catalog_cost_usd,
    margin_usd as catalog_margin_usd,
    cast(margin_usd / nullif(price_usd, 0) as decimal(18, 6)) as catalog_margin_pct
from {{ ref('stg_products') }}
