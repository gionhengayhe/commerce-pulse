select
    cast(session_id as bigint) as session_id,
    cast(customer_id as bigint) as customer_id,
    cast(start_time as timestamp) as session_started_at,
    trim(source) as session_source,
    trim(device) as session_device,
    trim(country) as session_country
from {{ source('raw', 'sessions') }}
