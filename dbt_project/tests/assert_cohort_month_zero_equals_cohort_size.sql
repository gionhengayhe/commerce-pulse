select *
from {{ ref('mart_cohort_retention_monthly') }}
where
    months_since_first_order = 0
    and active_customers != cohort_size
