import ast
import csv
import importlib.util
import tempfile
import unittest
from pathlib import Path

import duckdb


REPO_ROOT = Path(__file__).resolve().parents[2]
FETCH_SCRIPT = REPO_ROOT / "airflow" / "scripts" / "fetch_raw.py"
LOAD_SCRIPT = REPO_ROOT / "airflow" / "scripts" / "load_raw.py"
EXPORT_SCRIPT = REPO_ROOT / "airflow" / "scripts" / "export_tableau.py"
DAG_FILE = REPO_ROOT / "airflow" / "dags" / "commerce_pulse_daily.py"
COMPOSE_FILE = REPO_ROOT / "docker-compose.yml"
DOCKERFILE = REPO_ROOT / "docker" / "Dockerfile"
DOCKER_REQUIREMENTS = REPO_ROOT / "docker" / "requirements.txt"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class ExportTableauTests(unittest.TestCase):
    def test_default_output_lives_under_data(self):
        exporter = load_module("export_tableau_defaults", EXPORT_SCRIPT)
        self.assertEqual(exporter.DEFAULT_OUTPUT_DIR, REPO_ROOT / "data" / "export")

    def test_export_is_idempotent_and_replaces_existing_csv(self):
        exporter = load_module("export_tableau", EXPORT_SCRIPT)
        with tempfile.TemporaryDirectory() as directory:
            temp_dir = Path(directory)
            database_path = temp_dir / "warehouse.duckdb"
            output_dir = temp_dir / "export"
            model = "mart_executive_daily"

            with duckdb.connect(str(database_path)) as connection:
                connection.execute("create schema main_marts")
                connection.execute(
                    "create table main_marts.mart_executive_daily as "
                    "select date '2026-01-01' as date_day, 10 as sessions"
                )

            exporter.export_tableau(database_path, output_dir, "main_marts", (model,))

            with duckdb.connect(str(database_path)) as connection:
                connection.execute(
                    "create or replace table main_marts.mart_executive_daily as "
                    "select date '2026-01-02' as date_day, 20 as sessions"
                )

            exporter.export_tableau(database_path, output_dir, "main_marts", (model,))

            with (output_dir / f"{model}.csv").open(newline="", encoding="utf-8") as file:
                rows = list(csv.DictReader(file))

            self.assertEqual(rows, [{"date_day": "2026-01-02", "sessions": "20"}])
            self.assertFalse((output_dir / f".{model}.csv.tmp").exists())


class FetchRawTests(unittest.TestCase):
    def test_sync_sources_validates_and_replaces_the_complete_snapshot(self):
        fetcher = load_module("fetch_raw", FETCH_SCRIPT)
        with tempfile.TemporaryDirectory() as directory:
            temp_dir = Path(directory)
            source_dir = temp_dir / "kaggle"
            raw_dir = temp_dir / "data" / "raw"
            source_dir.mkdir()

            sources = {}
            for filename, header in fetcher.EXPECTED_HEADERS.items():
                source = source_dir / filename
                source.write_text(",".join(header) + "\n", encoding="utf-8")
                sources[filename] = source

            raw_dir.mkdir(parents=True)
            (raw_dir / "customers.csv").write_text("stale\n", encoding="utf-8")
            fetcher.sync_sources(sources, raw_dir)

            self.assertEqual(
                {path.name for path in raw_dir.glob("*.csv")},
                set(fetcher.EXPECTED_HEADERS),
            )
            self.assertEqual(
                (raw_dir / "customers.csv").read_text(encoding="utf-8"),
                ",".join(fetcher.EXPECTED_HEADERS["customers.csv"]) + "\n",
            )


class DagContractTests(unittest.TestCase):
    def test_dag_contains_the_five_stage_contract(self):
        tree = ast.parse(DAG_FILE.read_text(encoding="utf-8"))
        functions = {node.name for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)}
        self.assertTrue(
            {
                "commerce_pulse_daily",
                "fetch_raw",
                "ingest_raw",
                "dbt_build",
                "validate_analytics",
                "export_tableau",
            }
            <= functions
        )

        source = DAG_FILE.read_text(encoding="utf-8")
        self.assertIn('dag_id="commerce_pulse_daily"', source)
        self.assertIn('schedule="0 2 * * *"', source)
        self.assertIn("max_active_runs=1", source)
        self.assertIn('REPO_ROOT / "airflow" / "scripts" / "fetch_raw.py"', source)
        self.assertIn('REPO_ROOT / "airflow" / "scripts" / "load_raw.py"', source)
        self.assertIn('REPO_ROOT / "airflow" / "scripts" / "export_tableau.py"', source)
        self.assertIn('REPO_ROOT / "data" / "export"', source)
        self.assertIn(
            "fetch_raw() >> ingest_raw() >> dbt_build() >> validate_analytics() >> export_tableau()",
            source,
        )


class PipelineLayoutTests(unittest.TestCase):
    def test_pipeline_commands_live_with_the_airflow_runtime(self):
        self.assertTrue(FETCH_SCRIPT.is_file())
        self.assertTrue(LOAD_SCRIPT.is_file())
        self.assertTrue(EXPORT_SCRIPT.is_file())
        self.assertFalse((REPO_ROOT / "dbt_project" / "scripts").exists())


class DockerContractTests(unittest.TestCase):
    def test_compose_contains_the_local_executor_runtime(self):
        source = COMPOSE_FILE.read_text(encoding="utf-8")
        for service in (
            "postgres:",
            "airflow-init:",
            "airflow-apiserver:",
            "airflow-scheduler:",
            "airflow-dag-processor:",
        ):
            self.assertIn(service, source)

        self.assertIn("AIRFLOW__CORE__EXECUTOR: LocalExecutor", source)
        self.assertIn("COMMERCE_PULSE_REPO_ROOT: /opt/commerce-pulse", source)
        self.assertIn("COMMERCE_PULSE_KAGGLE_DATASET:", source)
        self.assertIn("/entrypoint airflow version", source)
        self.assertNotIn("CeleryExecutor", source)

    def test_custom_image_pins_the_analytics_runtime(self):
        dockerfile = DOCKERFILE.read_text(encoding="utf-8")
        requirements = DOCKER_REQUIREMENTS.read_text(encoding="utf-8").splitlines()

        self.assertIn("FROM apache/airflow:${AIRFLOW_VERSION}", dockerfile)
        self.assertEqual(
            requirements,
            [
                "kagglehub==1.0.2",
                "dbt-core==1.12.0",
                "dbt-duckdb==1.11.0",
                "duckdb==1.5.5",
            ],
        )


if __name__ == "__main__":
    unittest.main()
