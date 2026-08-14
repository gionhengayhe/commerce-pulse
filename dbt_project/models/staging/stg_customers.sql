select
    cast(customer_id as bigint) as customer_id,
    trim(name) as customer_name,
    lower(trim(email)) as email,
    trim(country) as customer_country,
    cast(age as integer) as age,
    cast(signup_date as date) as signup_date,
    cast(marketing_opt_in as boolean) as is_marketing_opt_in
from {{ source('raw', 'customers') }}
