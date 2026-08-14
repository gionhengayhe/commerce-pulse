with expected as (
    select
        matched_session_id as session_id,
        count(*) as matched_order_count,
        sum(net_sales_usd) as net_sales_usd
    from {{ ref('fct_orders') }}
    group by matched_session_id
)
select s.session_id
from {{ ref('fct_sessions') }} as s
left join expected as e using (session_id)
where
    s.matched_order_count != coalesce(e.matched_order_count, 0)
    or abs(s.net_sales_usd - coalesce(e.net_sales_usd, 0)) > 0.01
