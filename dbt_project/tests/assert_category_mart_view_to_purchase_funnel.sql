select *
from {{ ref('mart_category_performance_monthly') }}
where
    viewed_purchase_sessions > view_sessions
    or viewed_purchase_sessions > purchase_sessions
    or carted_purchase_sessions > cart_sessions
    or carted_purchase_sessions > purchase_sessions
