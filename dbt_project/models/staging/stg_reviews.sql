select
    cast(review_id as bigint) as review_id,
    cast(order_id as bigint) as order_id,
    cast(product_id as bigint) as product_id,
    cast(rating as integer) as rating,
    review_text,
    cast(review_time as timestamp) as reviewed_at
from {{ source('raw', 'reviews') }}
