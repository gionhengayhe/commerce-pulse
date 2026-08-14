select
    customer_id,
    customer_country,
    age,
    case
        when age between 18 and 24 then '18-24'
        when age between 25 and 34 then '25-34'
        when age between 35 and 44 then '35-44'
        when age between 45 and 54 then '45-54'
        when age between 55 and 64 then '55-64'
        when age >= 65 then '65+'
        else 'Unknown'
    end as age_band,
    signup_date,
    is_marketing_opt_in
from {{ ref('stg_customers') }}
