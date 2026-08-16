select
    first_order_cohort_month,
    months_since_first_order
from {{ ref('mart_cohort_retention_monthly') }}
where
    active_customers > eligible_customers
    or eligible_customers > cohort_size
