"""Daily, idempotent orchestration for the Commerce Pulse analytics pipeline."""

from __future__ import annotations

import os
import subprocess
import sys
from datetime import timedelta
from pathlib import Path

import pendulum
from airflow.sdk import dag, task


REPO_ROOT = Path(
    os.getenv("COMMERCE_PULSE_REPO_ROOT", Path(__file__).resolve().parents[2])
).resolve()
DBT_PROJECT_DIR = REPO_ROOT / "dbt_project"
PYTHON_EXECUTABLE = os.getenv("COMMERCE_PULSE_PYTHON_EXECUTABLE", sys.executable)
DBT_EXECUTABLE = os.getenv("COMMERCE_PULSE_DBT_EXECUTABLE", "dbt")


def run_command(command: list[str], cwd: Path) -> None:
    environment = os.environ.copy()
    path_defaults = {
        "COMMERCE_PULSE_DB_PATH": DBT_PROJECT_DIR / "dev.duckdb",
        "COMMERCE_PULSE_RAW_DIR": REPO_ROOT / "data" / "raw",
        "COMMERCE_PULSE_EXPORT_DIR": REPO_ROOT / "data" / "export",
    }
    for name, default in path_defaults.items():
        configured = Path(environment.get(name, default))
        if not configured.is_absolute():
            configured = REPO_ROOT / configured
        environment[name] = str(configured.resolve())
    subprocess.run(command, cwd=cwd, env=environment, check=True)


@dag(
    dag_id="commerce_pulse_daily",
    description="Fetch source data, load DuckDB, build dbt, validate analytics, and export Tableau datasets.",
    schedule="0 2 * * *",
    start_date=pendulum.datetime(2025, 1, 1, tz="Asia/Ho_Chi_Minh"),
    catchup=False,
    max_active_runs=1,
    default_args={
        "owner": "analytics-engineering",
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
        "execution_timeout": timedelta(hours=2),
    },
    tags=["commerce-pulse", "analytics", "daily"],
)
def commerce_pulse_daily():
    @task()
    def fetch_raw() -> None:
        run_command(
            [PYTHON_EXECUTABLE, str(REPO_ROOT / "airflow" / "scripts" / "fetch_raw.py")],
            REPO_ROOT,
        )

    @task()
    def ingest_raw() -> None:
        run_command(
            [PYTHON_EXECUTABLE, str(REPO_ROOT / "airflow" / "scripts" / "load_raw.py")],
            REPO_ROOT,
        )

    @task()
    def dbt_build() -> None:
        run_command(
            [
                DBT_EXECUTABLE,
                "build",
                "--project-dir",
                str(DBT_PROJECT_DIR),
                "--profiles-dir",
                str(DBT_PROJECT_DIR),
                "--target",
                "dev",
                "--no-version-check",
            ],
            DBT_PROJECT_DIR,
        )

    @task()
    def validate_analytics() -> None:
        run_command(
            [
                DBT_EXECUTABLE,
                "test",
                "--project-dir",
                str(DBT_PROJECT_DIR),
                "--profiles-dir",
                str(DBT_PROJECT_DIR),
                "--target",
                "dev",
                "--select",
                "test_type:singular",
                "--no-version-check",
            ],
            DBT_PROJECT_DIR,
        )

    @task()
    def export_tableau() -> None:
        run_command(
            [PYTHON_EXECUTABLE, str(REPO_ROOT / "airflow" / "scripts" / "export_tableau.py")],
            REPO_ROOT,
        )

    fetch_raw() >> ingest_raw() >> dbt_build() >> validate_analytics() >> export_tableau()


commerce_pulse_daily()
