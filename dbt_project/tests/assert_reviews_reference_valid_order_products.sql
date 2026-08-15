with valid_order_products as (
    select distinct order_id, product_id
    from {{ ref('fct_order_lines') }}
)

select r.review_id
from {{ ref('fct_reviews') }} as r
left join valid_order_products as v
    on r.order_id = v.order_id
    and r.product_id = v.product_id
where v.order_id is null
