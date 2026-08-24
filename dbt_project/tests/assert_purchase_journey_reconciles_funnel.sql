with expected as (
    select
        f.date_day as journey_date_day,
        f.session_source as journey_session_source,
        f.session_device as journey_session_device,
        f.session_country as journey_session_country,
        s.stage,
        s.stage_order,
        s.stage_sessions,
        f.sessions as base_sessions
    from {{ ref('mart_channel_funnel_daily') }} as f
    cross join lateral (
        values
            ('1. Sessions', 1, f.sessions),
            ('2. Product Views', 2, f.view_sessions),
            ('3. Added to Cart', 3, f.cart_sessions),
            ('4. Checkout', 4, f.checkout_sessions),
            ('5. Purchase', 5, f.purchase_sessions)
    ) as s(stage, stage_order, stage_sessions)
),

actual as (
    select
        journey_date_day,
        journey_session_source,
        journey_session_device,
        journey_session_country,
        stage,
        max(stage_order) as stage_order,
        count(*) as slice_rows,
        count(*) filter (where slice = 'Achieved') as achieved_rows,
        count(*) filter (where slice = 'Remaining') as remaining_rows,
        sum(slice_value) as reconstructed_base_sessions,
        max(stage_sessions_display) as stage_sessions,
        max(base_sessions_display) as base_sessions,
        min(stage_size_value) as min_stage_size,
        max(stage_size_value) as max_stage_size
    from {{ ref('mart_purchase_journey_daily') }}
    group by
        journey_date_day,
        journey_session_source,
        journey_session_device,
        journey_session_country,
        stage
)

select
    coalesce(e.journey_date_day, a.journey_date_day) as journey_date_day,
    coalesce(e.journey_session_source, a.journey_session_source) as journey_session_source,
    coalesce(e.journey_session_device, a.journey_session_device) as journey_session_device,
    coalesce(e.journey_session_country, a.journey_session_country) as journey_session_country,
    coalesce(e.stage, a.stage) as stage
from expected as e
full outer join actual as a
    on e.journey_date_day = a.journey_date_day
    and e.journey_session_source = a.journey_session_source
    and e.journey_session_device = a.journey_session_device
    and e.journey_session_country = a.journey_session_country
    and e.stage = a.stage
where
    e.stage is null
    or a.stage is null
    or a.stage_order != e.stage_order
    or a.slice_rows != 2
    or a.achieved_rows != 1
    or a.remaining_rows != 1
    or a.reconstructed_base_sessions != e.base_sessions
    or a.stage_sessions != e.stage_sessions
    or a.base_sessions != e.base_sessions
    or a.min_stage_size != e.stage_sessions
    or a.max_stage_size != e.stage_sessions
