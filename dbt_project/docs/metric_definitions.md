# Metric dictionary

This dictionary is the semantic contract for analysis and BI. Monetary values are
in USD. Ratios must always be recomputed from their additive components at the
requested reporting grain; stored or averaged percentages must not be summed.

## Customer journey and funnel

| Metric | Definition | Formula | Base mart | Aggregation behavior | Limitation |
|---|---|---|---|---|---|
| Sessions | Observed browsing sessions | `sum(sessions)` | `mart_executive_daily`, `mart_channel_funnel_daily` | Additive across disjoint dimensions and dates | A session is source-defined; inactivity duration is unavailable |
| Purchase Sessions | Sessions containing a purchase event | `sum(purchase_sessions)` | `mart_executive_daily`, `mart_channel_funnel_daily` | Additive across disjoint dimensions and dates | Measures sessions, not orders or customers |
| Session Conversion Rate | Share of sessions containing a purchase | `sum(purchase_sessions) / sum(sessions)` | `mart_executive_daily`, `mart_channel_funnel_daily` | Derived ratio; recompute | Historical observational data does not establish causality |
| View to Cart Rate | Share of viewing sessions that reached add-to-cart | `sum(cart_sessions) / sum(view_sessions)` | `mart_executive_daily`, `mart_channel_funnel_daily` | Derived ratio; recompute | Relies on the validated sequential session funnel |
| Cart to Checkout Rate | Share of cart sessions that reached checkout | `sum(checkout_sessions) / sum(cart_sessions)` | `mart_executive_daily`, `mart_channel_funnel_daily` | Derived ratio; recompute | Relies on the validated sequential session funnel |
| Checkout to Purchase Rate | Share of checkout sessions that purchased | `sum(purchase_sessions) / sum(checkout_sessions)` | `mart_executive_daily`, `mart_channel_funnel_daily` | Derived ratio; recompute | Relies on the validated sequential session funnel |

## Orders and economics

| Metric | Definition | Formula | Base mart | Aggregation behavior | Limitation |
|---|---|---|---|---|---|
| Orders | Observed purchase orders | `sum(orders)` | `mart_executive_daily`, `mart_channel_funnel_daily` | Additive across dates and exclusive channel groups | Product/category order counts are non-additive because one order can contain multiple products/categories |
| Units Sold | Purchased item quantity | `sum(units_sold)` | `mart_executive_daily`, product/category marts | Additive | Duplicate-looking source lines are intentionally retained and reconciled |
| Gross Sales | Sales before order discount | `sum(gross_sales_usd)` | Executive, channel, product/category marts | Additive | Based on source order and line prices |
| Discount Amount | Discount allocated from order to retained lines | `sum(discount_amount_usd)` | Executive, channel, product/category marts | Additive | Line allocation may introduce sub-cent intermediate rounding |
| Net Sales | Sales after discount | `sum(net_sales_usd)` | Executive, channel, product/category marts | Additive | Excludes taxes, shipping, refunds, and returns not present in source |
| Weighted Discount Rate | Discount as a share of gross sales | `sum(discount_amount_usd) / sum(gross_sales_usd)` | Executive, channel, product/category marts | Derived ratio; recompute | Do not average order- or row-level discount percentages |
| Average Order Value | Net sales per order | `sum(net_sales_usd) / sum(orders)` | `mart_executive_daily`, `mart_channel_funnel_daily` | Derived ratio; recompute | Product/category order denominators overlap and cannot be summed |
| Estimated COGS | Quantity valued at current catalog unit cost | `sum(estimated_cogs_usd)` | Executive, channel, product/category marts | Additive | Catalog cost is a current snapshot, not historical cost at order time |
| Estimated Gross Profit | Net sales less estimated COGS | `sum(estimated_gross_profit_usd)` | Executive, channel, product/category marts | Additive | Estimated because historical product cost is unavailable |
| Estimated Gross Margin % | Estimated gross profit as a share of net sales | `sum(estimated_gross_profit_usd) / sum(net_sales_usd)` | Executive, channel, product/category marts | Derived ratio; recompute | Inherits current-cost and missing-refund limitations |

## Customer retention

| Metric | Definition | Formula | Base mart | Aggregation behavior | Limitation |
|---|---|---|---|---|---|
| Repeat 30D | Eligible first-time purchasers with a second order within 30 days | `count_if(is_eligible_30d and repeat_30d) / count_if(is_eligible_30d)` | `mart_customer_lifecycle` | Derived ratio over customers | Exclude right-censored customers from the denominator |
| Repeat 60D | Eligible first-time purchasers with a second order within 60 days | `count_if(is_eligible_60d and repeat_60d) / count_if(is_eligible_60d)` | `mart_customer_lifecycle` | Derived ratio over customers | Exclude right-censored customers from the denominator |
| Repeat 90D | Eligible first-time purchasers with a second order within 90 days | `count_if(is_eligible_90d and repeat_90d) / count_if(is_eligible_90d)` | `mart_customer_lifecycle` | Derived ratio over customers | Exclude right-censored customers from the denominator |
| Cohort Retention | Share of eligible first-purchase cohort customers active in a cohort-age month | `sum(active_customers) / sum(eligible_customers)` | `mart_cohort_retention_monthly` | Derived ratio; recompute only across compatible cohort cells | Monthly activity is purchase-based and future cohort ages are not materialized |

## Product and category performance

| Metric | Definition | Formula | Base mart | Aggregation behavior | Limitation |
|---|---|---|---|---|---|
| Product View to Purchase Rate | Product viewing sessions that also purchased that product | `sum(viewed_purchase_sessions) / sum(view_sessions)` | `mart_product_performance_monthly` | Derived ratio; recompute | Purchases without a recorded product view remain in `purchase_sessions` but not the numerator |
| Product Cart to Purchase Rate | Product cart sessions that also purchased that product | `sum(carted_purchase_sessions) / sum(cart_sessions)` | `mart_product_performance_monthly` | Derived ratio; recompute | Purchases without a recorded product cart event remain outside the numerator |
| Category View to Purchase Rate | Category viewing sessions that also purchased within that category | `sum(viewed_purchase_sessions) / sum(view_sessions)` | `mart_category_performance_monthly` | Derived ratio; recompute | Category sessions are calculated directly and must not be reconstructed by summing products |
| Category Cart to Purchase Rate | Category cart sessions that also purchased within that category | `sum(carted_purchase_sessions) / sum(cart_sessions)` | `mart_category_performance_monthly` | Derived ratio; recompute | Category sessions are calculated directly and must not be reconstructed by summing products |
| Review Coverage | Reviewed order-product pairs as a share of purchased order-product pairs | `sum(reviewed_order_product_count) / sum(orders)` only at product-month grain | `mart_product_performance_monthly` | Derived ratio; product-specific calculation | Product mart `orders` is distinct order-product coverage; do not sum it into company orders |
| Average Rating | Mean structured rating | `sum(rating) / count(rating)` from review fact, or weighted rollup | `fct_reviews`, product/category marts | Derived average; weight by review count | Review text is synthetic and low-cardinality; no NLP sentiment claim is supported |

## Non-additive fields

Distinct people and order coverage fields—including `visitors`,
`purchasing_customers`, `viewing_customers`, and product/category `orders`—must
not be summed across overlapping groups. Recalculate distinct counts from the
appropriate fact/intermediate model when changing the reporting grain.
