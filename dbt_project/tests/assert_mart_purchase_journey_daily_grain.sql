select
    journey_date_day,
    journey_session_source,
    journey_session_device,
    journey_session_country,
    stage,
    slice
from {{ ref('mart_purchase_journey_daily') }}
group by
    journey_date_day,
    journey_session_source,
    journey_session_device,
    journey_session_country,
    stage,
    slice
having count(*) > 1
