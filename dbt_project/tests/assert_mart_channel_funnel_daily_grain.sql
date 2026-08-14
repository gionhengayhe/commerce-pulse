select date_day, session_source, session_device, session_country
from {{ ref('mart_channel_funnel_daily') }}
group by date_day, session_source, session_device, session_country
having count(*) > 1
