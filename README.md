# Commerce Pulse

Commerce Pulse is a reproducible e-commerce analytics pipeline built with
Python, DuckDB, dbt, Apache Airflow, and Tableau.

```text
Raw CSVs
   -> transactional DuckDB ingestion
   -> dbt staging, intermediate, dimensions, facts, and marts
   -> semantic and reconciliation acceptance gates
   -> atomic Tableau CSV exports
```

## Project components

- [`dbt_project`](dbt_project/README.md): transformation DAG, analytical tests,
  model inventory, and metric contracts.
- [`airflow`](airflow/README.md): daily Airflow DAG and its runtime
  contract.
- `data/raw`: seven immutable source CSV extracts.
- `export`: generated Tableau-ready datasets.
- `tableau`: dashboard workbook maintained locally.

## Run the pipeline stages manually

```powershell
python dbt_project/scripts/load_raw.py
Push-Location dbt_project
dbt build --profiles-dir .
dbt test --profiles-dir . --select test_type:singular
Pop-Location
python dbt_project/scripts/export_tableau.py
```

For scheduling, environment variables, WSL2 setup, and DAG validation, see the
[Airflow orchestration guide](airflow/README.md).
