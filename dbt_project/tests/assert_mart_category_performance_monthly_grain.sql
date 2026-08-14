select calendar_month, category
from {{ ref('mart_category_performance_monthly') }}
group by calendar_month, category
having count(*) > 1
