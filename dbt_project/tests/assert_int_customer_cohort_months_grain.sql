select customer_id, months_since_first_order
from {{ ref('int_customer_cohort_months') }}
group by customer_id, months_since_first_order
having count(*) > 1
