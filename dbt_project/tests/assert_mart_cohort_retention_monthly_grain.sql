select first_order_cohort_month, months_since_first_order
from {{ ref('mart_cohort_retention_monthly') }}
group by first_order_cohort_month, months_since_first_order
having count(*) > 1
