select session_id
from {{ ref('fct_sessions') }}
where
    (has_purchase and not has_checkout)
    or (has_checkout and not has_add_to_cart)
    or (has_add_to_cart and not has_view)
    or matched_order_count != purchase_event_count
