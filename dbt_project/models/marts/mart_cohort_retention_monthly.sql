select
    first_order_cohort_month,
    months_since_first_order,
    activity_month,
    count(distinct customer_id) as cohort_size,
    count(distinct customer_id) filter (where   ) as eligible_customers,
    count(distinct customer_id) filter (where is_eligible and is_active) as active_customers,
    sum(order_count) filter (where is_eligible) as orders,
    sum(net_sales_usd) filter (where is_eligible) as net_sales_usd,
    sum(estimated_gross_profit_usd) filter (where is_eligible) as estimated_gross_profit_usd
from {{ ref('int_customer_cohort_months') }}
group by
    first_order_cohort_month,
    months_since_first_order,
    activity_month
