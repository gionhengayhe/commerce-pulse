# Airflow orchestration

`commerce_pulse_daily` is a stage-level DAG for the complete local analytics
pipeline:

```text
ingest_raw -> dbt_build -> validate_analytics -> export_tableau
```

The DAG runs every day at 02:00 in `Asia/Ho_Chi_Minh`, supports manual runs,
disables historical catchup, and allows only one active run. Each stage fails
fast, retries once, and calls a standalone command that can also be run without
Airflow.

## Runtime contract

| Stage | Command | Contract |
|---|---|---|
| `ingest_raw` | `python dbt_project/scripts/load_raw.py` | Transactionally replaces all seven raw tables from CSV |
| `dbt_build` | `dbt build` | Builds the complete dbt DAG and runs model/schema tests |
| `validate_analytics` | `dbt test --select test_type:singular` | Re-runs the 27 grain, reconciliation, and semantic acceptance tests as a visible gate |
| `export_tableau` | `python dbt_project/scripts/export_tableau.py` | Atomically replaces all eight Tableau/analysis CSV extracts |

The build and acceptance stages are intentionally separate. `dbt_build`
provides the normal dbt contract, while `validate_analytics` creates an explicit
Airflow gate for the high-value singular tests.

## Configuration

The defaults run directly against this repository. Containers can override the
same paths without changing code.

| Environment variable | Default |
|---|---|
| `COMMERCE_PULSE_REPO_ROOT` | Repository root inferred from the DAG file |
| `COMMERCE_PULSE_DB_PATH` | `dbt_project/dev.duckdb` |
| `COMMERCE_PULSE_RAW_DIR` | `data/raw` |
| `COMMERCE_PULSE_EXPORT_DIR` | `export` |
| `COMMERCE_PULSE_MART_SCHEMA` | `main_marts` |
| `COMMERCE_PULSE_PYTHON_EXECUTABLE` | Python running the Airflow task |
| `COMMERCE_PULSE_DBT_EXECUTABLE` | `dbt` |

## Local Airflow setup

Apache Airflow should run on Windows through WSL2 or Linux containers. From a
WSL2 checkout, install Airflow with its official constraints file:

```bash
python -m venv .venv-airflow
source .venv-airflow/bin/activate

AIRFLOW_VERSION=3.3.1
PYTHON_VERSION=3.13
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

python -m pip install -r requirements-airflow.txt --constraint "${CONSTRAINT_URL}"
python -m pip install "apache-airflow==${AIRFLOW_VERSION}" -r requirements.txt
python -m pip check

export AIRFLOW_HOME="$HOME/airflow"
export AIRFLOW__CORE__DAGS_FOLDER="$PWD/airflow/dags"
export COMMERCE_PULSE_REPO_ROOT="$PWD"

airflow db migrate
airflow standalone
```

Validate discovery and task order before enabling the schedule:

```bash
airflow dags list
airflow tasks list commerce_pulse_daily --tree
airflow dags test commerce_pulse_daily 2026-08-25
```

The next infrastructure phase will package this runtime in Docker Compose so
Airflow does not depend on a native Windows installation.

## Idempotency

- Raw ingestion uses one transaction and `create or replace table`.
- dbt models are deterministic and rebuild their declared relations.
- Tableau exports are written to temporary files and atomically replace prior
  extracts.
- `max_active_runs=1` prevents two DAG runs from writing the shared DuckDB file
  simultaneously.
