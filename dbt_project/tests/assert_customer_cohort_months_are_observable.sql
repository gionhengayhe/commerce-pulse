with observation as (
    select cast(date_trunc('month', max(order_date)) as date) as observation_month
    from {{ ref('fct_orders') }}
)

select c.customer_id, c.activity_month, o.observation_month
from {{ ref('int_customer_cohort_months') }} as c
cross join observation as o
where c.activity_month > o.observation_month
