# Commerce Pulse

Commerce Pulse is a local e-commerce analytics project built for learning and
portfolio use. It turns a public Kaggle dataset into tested dbt models and
Tableau-ready CSV files through one reproducible Airflow pipeline.

```text
Kaggle
  -> data/raw/*.csv
  -> DuckDB raw tables
  -> dbt models and tests
  -> data/export/*.csv
  -> Tableau
```

The design is intentionally small:

- DuckDB is the analytics warehouse; it does not need a database server.
- PostgreSQL stores Airflow metadata only.
- Airflow orchestrates pipeline stages while dbt owns model dependencies.
- Generated data and the local DuckDB file are not committed to Git.
- Docker is the supported runtime, so no local Airflow installation is needed.

## Pipeline

The `commerce_pulse_daily` DAG runs every day at 02:00 Asia/Ho_Chi_Minh and can
also be triggered manually.

```text
fetch_raw -> ingest_raw -> dbt_build -> export_tableau
```

| Task | Responsibility |
| --- | --- |
| `fetch_raw` | Download and validate the seven source CSVs from Kaggle Hub. |
| `ingest_raw` | Replace the DuckDB raw tables in one transaction. |
| `dbt_build` | Build all models and run all dbt data and singular tests. |
| `export_tableau` | Replace each of the eight Tableau-ready CSVs atomically. |

There is no separate validation task because `dbt build` already runs the full
test suite and prevents exports when a model or test fails.

## Repository structure

```text
commerce-pulse/
|-- airflow/
|   |-- dags/                 # Pipeline definition
|   |-- scripts/              # Fetch, ingest, and export commands
|   `-- tests/                # Runtime contract tests
|-- dbt_project/
|   |-- models/               # Staging, intermediate, core, and marts
|   |-- tests/                # Cross-model reconciliation tests
|   |-- analyses/             # Optional acceptance report
|   `-- docs/                 # Metric definitions and model inventory
|-- data/
|   |-- raw/                  # Generated Kaggle snapshot (ignored by Git)
|   |-- export/               # Generated Tableau datasets (ignored by Git)
|   `-- warehouse.duckdb      # Local analytics warehouse (ignored by Git)
|-- tableau/dashboard.twb
|-- docker/Dockerfile
|-- docker-compose.yml
|-- requirements.txt
|-- test_data.ipynb           # Source-data exploration notebook
`-- README.md
```

## Run with Docker

Requirements: Docker Desktop with Docker Compose and internet access for the
first image build and Kaggle download.

From the repository root:

```powershell
Copy-Item .env.example .env
docker compose up --build -d
```

Open <http://localhost:8080> and sign in with `airflow` / `airflow` unless you
changed the values in `.env`. Enable and trigger `commerce_pulse_daily` in the
Airflow UI.

The defaults are suitable for local use. `.env` only needs to be edited when you
want different credentials, port, Airflow version, or Kaggle dataset handle.

Useful checks:

```powershell
docker compose ps
docker compose logs airflow-scheduler
docker compose down
```

`docker compose down` stops the platform but preserves Airflow metadata and
logs. Add `--volumes` only when you intentionally want to reset them.

## Run without Docker

Docker is recommended, but the analytics stages can also run in a local Python
environment:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt

python airflow/scripts/fetch_raw.py
python airflow/scripts/load_raw.py
dbt build --project-dir dbt_project --profiles-dir dbt_project
python airflow/scripts/export_tableau.py
```

The commands use repository-relative paths by default. Each Python script also
provides `--help` for explicit input or output overrides.

## Data model and quality

The dbt project contains 31 models across four layers:

```text
staging -> intermediate -> dimensions/facts -> marts
```

The dimensional core remains the reusable analytical backbone. Marts are kept
only for dashboard-specific grains or business logic. `dbt build` executes 182
tests, including 27 cross-model reconciliation tests, before Tableau exports are
allowed.

- [Model inventory](dbt_project/docs/model_inventory.md)
- [Metric definitions](dbt_project/docs/metric_definitions.md)
- [Acceptance report](dbt_project/analyses/acceptance_report.sql)

## Tableau

The workbook is [tableau/dashboard.twb](tableau/dashboard.twb). It consumes the
eight CSV files generated in `data/export`.

Tableau stores local CSV connection paths in the workbook. After cloning the
repository to another location, open the workbook and use **Edit Connection** to
point each source to the new `data/export` directory. The pipeline does not
rewrite the workbook because connection management belongs to Tableau, not the
data transformation layer.

## Local configuration

The checked-in `.env.example` documents the small set of Docker settings. Copy
it to `.env`; never commit `.env` or credentials. Kaggle Hub can download this
public dataset without repository-specific credentials. If Kaggle requires
authentication in your environment, use Kaggle Hub's normal local credential
setup rather than storing a token in this repository.

## Scope and trade-offs

This is deliberately not a distributed production platform. It has no Celery,
Redis, Kubernetes, streaming layer, or separate DuckDB service because the
dataset and learning goals do not justify them. The repository favors explicit
scripts, one Airflow DAG, one dependency file, and one primary README over
framework abstractions or duplicated configuration.
