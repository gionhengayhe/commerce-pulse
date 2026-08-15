select customer_id
from {{ ref('mart_customer_lifecycle') }}
where
    (repeat_30d and second_order_at > first_order_at + interval '30 day')
    or (repeat_60d and second_order_at > first_order_at + interval '60 day')
    or (repeat_90d and second_order_at > first_order_at + interval '90 day')
    or (repeat_30d and not repeat_60d)
    or (repeat_60d and not repeat_90d)
    or (is_eligible_90d and not is_eligible_60d)
    or (is_eligible_60d and not is_eligible_30d)
