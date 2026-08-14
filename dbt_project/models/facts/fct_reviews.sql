select
    r.review_id,
    r.order_id,
    o.customer_id,
    r.product_id,
    r.reviewed_at,
    cast(r.reviewed_at as date) as review_date,
    o.order_date,
    date_diff('day', o.ordered_at, r.reviewed_at) as days_after_order,
    r.reviewed_at >= o.ordered_at as is_review_on_or_after_order,
    r.rating,
    r.review_text
from {{ ref('stg_reviews') }} as r
inner join {{ ref('fct_orders') }} as o using (order_id)
