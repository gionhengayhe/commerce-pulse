# E-commerce analytics dbt project

## Local setup

From the repository root:

```powershell
python dbt_project/scripts/load_raw.py
Set-Location dbt_project
dbt build --profiles-dir .
```

The loader replaces only the seven tables in the DuckDB `raw` schema from the
immutable CSV files in `data/raw`. Staging models are views and apply naming and
type normalization without changing business grain.

## Model layers

The dependency flow is:

```text
raw -> staging -> intermediate/prep -> dimensions + facts
    -> intermediate/business -> marts
```

- `staging`: source-conformed views with renamed and typed columns.
- `intermediate/prep`: purchase-order matching, line economics, order
  reconciliation, customer order sequencing, and session funnel preparation.
- `dimensions` and `facts`: canonical analytical entities and events.
- `intermediate/business`: reusable product-session, category-session, and
  customer-cohort grains.
- `marts`: six governed reporting outputs plus two optional product/cohort
  analysis tables.

`order_items` deliberately retains duplicate-looking source rows. The ingestion
step records `_source_row_number`, which staging exposes as `source_row_number`
and downstream logic uses to generate a stable `order_line_key`.

## Metric behavior

Mart columns are additive counts and amounts. Ratios should be calculated at
query time from their components, for example:

```text
conversion_rate = purchase_sessions / sessions
view_to_purchase_rate = viewed_purchase_sessions / view_sessions
cart_to_purchase_rate = carted_purchase_sessions / cart_sessions
average_order_value = net_sales_usd / orders
gross_margin_pct = estimated_gross_profit_usd / net_sales_usd
retention_rate = active_customers / eligible_customers
```

Product and category monthly marts are separate because distinct category
sessions cannot be recovered by summing distinct product sessions.

The complete semantic contract, including additivity and known limitations, is
maintained in `docs/metric_definitions.md`.

After a successful build, refresh the Tableau extracts atomically from the
repository root:

```powershell
python dbt_project/scripts/export_tableau.py
```

In product and category marts, `purchase_sessions` includes all attributed
purchases, including purchases without a recorded product view.
`viewed_purchase_sessions` is the subset that also had a view and is therefore
the valid numerator for a view-to-purchase rate. Reviews are assigned to the
linked order month so review measures align with the same purchase cohort as
sales; `fct_reviews.review_date` remains available for review-submission trends.

## Known source timestamp caveats

The synthetic source does not enforce every lifecycle timestamp sequence. Some
reviews predate their linked order, and some customers have an observed first
order before their signup date. These rows are retained. `fct_reviews` exposes
`is_review_on_or_after_order`, while `mart_customer_lifecycle` exposes
`is_first_order_on_or_after_signup`; the corresponding day differences remain
signed so the source inconsistency is visible rather than silently corrected.
