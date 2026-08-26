with stage_counts as (
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

stage_slices as (
    select
        c.*,
        s.slice,
        s.slice_order
    from stage_counts as c
    cross join (
        values
            ('Achieved', 1),
            ('Remaining', 2)
    ) as s(slice, slice_order)
)

select
    journey_date_day,
    journey_session_source,
    journey_session_device,
    journey_session_country,
    stage,
    stage_order,
    slice,
    slice_order,
    case
        when slice = 'Achieved' then stage_sessions
        else base_sessions - stage_sessions
    end as slice_value,
    case when slice = 'Achieved' then stage_sessions else 0 end as stage_sessions_display,
    case when slice = 'Achieved' then base_sessions else 0 end as base_sessions_display,
    stage_sessions as stage_size_value
from stage_slices
