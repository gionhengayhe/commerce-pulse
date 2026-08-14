select calendar_month, product_id
from {{ ref('mart_product_performance_monthly') }}
group by calendar_month, product_id
having count(*) > 1
