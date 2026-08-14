with sequenced as (
    select
        order_id,
        customer_id,
        ordered_at,
        row_number() over (
            partition by customer_id
            order by ordered_at, order_id
        ) as customer_order_number,
        min(ordered_at) over (partition by customer_id) as first_order_at,
        lag(ordered_at) over (
            partition by customer_id
            order by ordered_at, order_id
        ) as previous_order_at,
        lead(ordered_at) over (
            partition by customer_id
            order by ordered_at, order_id
        ) as next_order_at
    from {{ ref('stg_orders') }}
)

select
    order_id,
    customer_id,
    ordered_at,
    customer_order_number,
    first_order_at,
    previous_order_at,
    next_order_at,
    date_diff('day', previous_order_at, ordered_at) as days_since_previous_order,
    date_diff('day', ordered_at, next_order_at) as days_to_next_order,
    customer_order_number = 1 as is_first_order,
    customer_order_number > 1 as is_repeat_order
from sequenced
