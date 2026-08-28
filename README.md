# Commerce Pulse

Commerce Pulse is a reproducible e-commerce analytics pipeline built with
Python, DuckDB, dbt, Apache Airflow, and Tableau.

```text
Kaggle source
   -> validated CSV snapshot in data/raw
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
- `data/raw`: seven validated source CSVs synchronized from Kaggle Hub.
- `data/export`: generated Tableau-ready datasets.
- `tableau`: dashboard workbook maintained locally.

## Run the pipeline stages manually

```powershell
python airflow/scripts/fetch_raw.py
python airflow/scripts/load_raw.py
Push-Location dbt_project
dbt build --profiles-dir .
dbt test --profiles-dir . --select test_type:singular
Pop-Location
python airflow/scripts/export_tableau.py
```

For scheduling, environment variables, WSL2 setup, and DAG validation, see the
[Airflow orchestration guide](airflow/README.md).

## Run the complete platform with Docker

The Docker runtime uses PostgreSQL for Airflow metadata and keeps DuckDB as the
embedded analytics warehouse. From the repository root:

```powershell
Copy-Item .env.example .env
docker compose build
docker compose up airflow-init
docker compose up -d
```

Open Airflow at <http://localhost:8080>, then enable or manually trigger
`commerce_pulse_daily`. The default local credentials are `airflow` / `airflow`;
change them in `.env` for any shared environment.

The repository is mounted at `/opt/commerce-pulse`, so a successful DAG run
updates `dbt_project/dev.duckdb` and the CSV files in `data/export` on the host.
