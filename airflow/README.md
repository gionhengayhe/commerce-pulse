# Airflow orchestration

`commerce_pulse_daily` is a stage-level DAG for the complete local analytics
pipeline:

```text
fetch_raw -> ingest_raw -> dbt_build -> validate_analytics -> export_tableau
```

The DAG runs every day at 02:00 in `Asia/Ho_Chi_Minh`, supports manual runs,
disables historical catchup, and allows only one active run. Each stage fails
fast, retries once, and calls a standalone command that can also be run without
Airflow.

## Runtime contract

| Stage | Command | Contract |
|---|---|---|
| `fetch_raw` | `python airflow/scripts/fetch_raw.py` | Downloads and validates all seven source CSVs from Kaggle Hub |
| `ingest_raw` | `python airflow/scripts/load_raw.py` | Transactionally replaces all seven raw tables from CSV |
| `dbt_build` | `dbt build` | Builds the complete dbt DAG and runs model/schema tests |
| `validate_analytics` | `dbt test --select test_type:singular` | Re-runs the 27 grain, reconciliation, and semantic acceptance tests as a visible gate |
| `export_tableau` | `python airflow/scripts/export_tableau.py` | Atomically replaces all eight Tableau/analysis CSV extracts |

The build and acceptance stages are intentionally separate. `dbt_build`
provides the normal dbt contract, while `validate_analytics` creates an explicit
Airflow gate for the high-value singular tests.

## Configuration

The defaults run directly against this repository. Containers can override the
same paths without changing code.

| Environment variable | Default |
|---|---|
| `COMMERCE_PULSE_REPO_ROOT` | Repository root inferred from the DAG file |
| `COMMERCE_PULSE_KAGGLE_DATASET` | `wafaaelhusseini/e-commerce-transactions-clickstream` |
| `COMMERCE_PULSE_DB_PATH` | `dbt_project/dev.duckdb` |
| `COMMERCE_PULSE_RAW_DIR` | `data/raw` |
| `COMMERCE_PULSE_EXPORT_DIR` | `data/export` |
| `COMMERCE_PULSE_MART_SCHEMA` | `main_marts` |
| `COMMERCE_PULSE_PYTHON_EXECUTABLE` | Python running the Airflow task |
| `COMMERCE_PULSE_DBT_EXECUTABLE` | `dbt` |

## Local Airflow setup

The supported project runtime is Docker Compose. It uses:

```text
PostgreSQL          -> Airflow metadata only
Airflow API server  -> UI and task execution API
Airflow scheduler   -> LocalExecutor task execution
Airflow DAG processor
DuckDB file         -> analytics warehouse on the mounted host repository
```

LocalExecutor is intentional: the pipeline stages are sequential, and a
Redis/Celery worker tier would add infrastructure without adding useful
parallelism. The official Airflow Docker Compose guide is a local-development
quick start rather than a production deployment; this project has the same
scope.

### Start on Windows, macOS, or Linux

Install Docker Desktop or Docker Engine with Docker Compose 2.14 or newer and
allocate at least 4 GB of memory to Docker. From the repository root:

```powershell
Copy-Item .env.example .env
docker compose build
docker compose up airflow-init
docker compose up -d
docker compose ps
```

On Linux or WSL2, set `AIRFLOW_UID` in `.env` to the result of `id -u` so files
created in bind-mounted directories retain the host user's ownership.

Airflow is available at <http://localhost:8080>. The local defaults are:

```text
username: airflow
password: airflow
```

Change the admin password, PostgreSQL password, JWT secret, and Fernet key in
`.env` before sharing the environment or storing connections. `.env` is ignored
by Git.

### Validate the container runtime

After the services are healthy:

```powershell
docker compose exec airflow-scheduler airflow dags list
docker compose exec airflow-scheduler airflow dags list-import-errors
docker compose exec airflow-scheduler airflow tasks list commerce_pulse_daily --tree
docker compose exec airflow-scheduler airflow dags test commerce_pulse_daily 2026-08-26
```

The DAG starts paused. Enable it in the UI for the daily schedule, or trigger it
manually:

```powershell
docker compose exec airflow-scheduler airflow dags unpause commerce_pulse_daily
docker compose exec airflow-scheduler airflow dags trigger commerce_pulse_daily
```

Watch task logs in the UI or with:

```powershell
docker compose logs -f airflow-scheduler airflow-dag-processor
```

Stop services without deleting Airflow metadata:

```powershell
docker compose down
```

`docker compose down --volumes` also deletes the PostgreSQL metadata and Airflow
log volumes. It does not delete the bind-mounted raw data, DuckDB warehouse, or
exports in this repository.

## Idempotency

- Kaggle downloads are cached and all seven files are validated before each CSV
  atomically replaces its counterpart in `data/raw`.
- Raw ingestion uses one transaction and `create or replace table`.
- dbt models are deterministic and rebuild their declared relations.
- Tableau exports are written to temporary files and atomically replace prior
  extracts.
- `max_active_runs=1` prevents two DAG runs from writing the shared DuckDB file
  simultaneously.
- The Compose runtime uses LocalExecutor and the DAG stages form one sequential
  dependency chain, so only one process writes the DuckDB file during a run.
