with expected as (
    select max(order_date) as as_of_date
    from {{ ref('fct_orders') }}
)

select l.customer_id, l.as_of_date, e.as_of_date as expected_as_of_date
from {{ ref('mart_customer_lifecycle') }} as l
cross join expected as e
where l.as_of_date != e.as_of_date
