"""Export governed dbt marts to Tableau-ready CSV files atomically."""

import argparse
import os
from pathlib import Path

import duckdb


REPO_DIR = Path(__file__).resolve().parents[2]
DBT_PROJECT_DIR = REPO_DIR / "dbt_project"
DEFAULT_DATABASE_PATH = DBT_PROJECT_DIR / "dev.duckdb"
DEFAULT_OUTPUT_DIR = REPO_DIR / "data" / "export"
DEFAULT_SCHEMA = "main_marts"

TABLEAU_MODELS = (
    "mart_executive_daily",
    "mart_channel_funnel_daily",
    "mart_customer_lifecycle",
    "mart_category_performance_monthly",
    "mart_purchase_journey_daily",
    "mart_unique_visitor_sessions",
    "mart_product_performance_monthly",
    "mart_cohort_retention_monthly",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--database-path",
        type=Path,
        default=Path(os.getenv("COMMERCE_PULSE_DB_PATH", DEFAULT_DATABASE_PATH)),
        help="DuckDB warehouse path",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(os.getenv("COMMERCE_PULSE_EXPORT_DIR", DEFAULT_OUTPUT_DIR)),
        help="Destination directory for Tableau CSV extracts",
    )
    parser.add_argument(
        "--schema",
        default=os.getenv("COMMERCE_PULSE_MART_SCHEMA", DEFAULT_SCHEMA),
        help="DuckDB schema containing dbt marts",
    )
    parser.add_argument(
        "--models",
        nargs="+",
        choices=TABLEAU_MODELS,
        default=TABLEAU_MODELS,
        help="Subset of Tableau marts to export",
    )
    return parser.parse_args()


def quote_identifier(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def export_tableau(database_path: Path, output_dir: Path, schema: str, models: tuple[str, ...]) -> None:
    database_path = database_path.resolve()
    output_dir = output_dir.resolve()
    if not database_path.is_file():
        raise FileNotFoundError(f"DuckDB warehouse does not exist: {database_path}")

    output_dir.mkdir(parents=True, exist_ok=True)
    with duckdb.connect(str(database_path), read_only=True) as connection:
        existing_models = {
            row[0]
            for row in connection.execute(
                "select table_name from information_schema.tables where table_schema = ?",
                [schema],
            ).fetchall()
        }
        missing = [model for model in models if model not in existing_models]
        if missing:
            raise RuntimeError(f"Missing dbt marts in {schema}: {', '.join(missing)}")

        for model in models:
            destination = output_dir / f"{model}.csv"
            temporary = output_dir / f".{model}.csv.tmp"
            temporary.unlink(missing_ok=True)
            relation = f"{quote_identifier(schema)}.{quote_identifier(model)}"
            copy_path = temporary.as_posix().replace("'", "''")
            connection.execute(
                f"copy (select * from {relation}) to '{copy_path}' "
                "(format csv, header true)"
            )
            os.replace(temporary, destination)
            row_count = connection.execute(f"select count(*) from {relation}").fetchone()[0]
            print(f"{destination.name}: {row_count:,} rows")


def main() -> None:
    args = parse_args()
    export_tableau(args.database_path, args.output_dir, args.schema, tuple(args.models))


if __name__ == "__main__":
    main()
