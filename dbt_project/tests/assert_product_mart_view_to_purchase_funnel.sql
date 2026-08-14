select *
from {{ ref('mart_product_performance_monthly') }}
where
    viewed_purchase_sessions > view_sessions
    or viewed_purchase_sessions > purchase_sessions
