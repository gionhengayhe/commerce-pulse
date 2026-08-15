with match_stats as (
    select
        count(*) as matched_rows,
        count(distinct event_id) as matched_events,
        count(distinct order_id) as matched_orders,
        count(*) filter (where order_id is null) as unmatched_rows
    from {{ ref('int_purchase_events_matched_to_orders') }}
),

expected as (
    select
        count(*) filter (where event_type = 'purchase') as purchase_events,
        (select count(*) from {{ ref('stg_orders') }}) as orders
    from {{ ref('stg_events') }}
)

select *
from match_stats
cross join expected
where
    matched_rows != matched_events
    or matched_rows != matched_orders
    or unmatched_rows > 0
    or matched_rows != purchase_events
    or matched_rows != orders
