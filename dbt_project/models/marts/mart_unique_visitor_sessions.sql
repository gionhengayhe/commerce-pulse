select
    session_id as visitor_session_id,
    customer_id as visitor_customer_id,
    session_date as visitor_date_day,
    session_source as visitor_session_source,
    session_device as visitor_session_device,
    session_country as visitor_session_country
from {{ ref('fct_sessions') }}
