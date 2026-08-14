with mart_totals as (
    select sum(sessions) as sessions
    from {{ ref('mart_executive_daily') }}
),
fact_totals as (
    select count(*) as sessions
    from {{ ref('fct_sessions') }}
)
select *
from mart_totals
cross join fact_totals
where mart_totals.sessions != fact_totals.sessions
