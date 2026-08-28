"""Load immutable source CSVs into the DuckDB raw schema."""

import argparse
import os
from pathlib import Path

import duckdb


REPO_DIR = Path(__file__).resolve().parents[2]
DEFAULT_DATABASE_PATH = REPO_DIR / "data" / "warehouse.duckdb"
DEFAULT_RAW_DIR = REPO_DIR / "data" / "raw"
TABLES = (
    "customers",
    "products",
    "sessions",
    "events",
    "orders",
    "order_items",
    "reviews",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--database-path",
        type=Path,
        default=Path(os.getenv("COMMERCE_PULSE_DB_PATH", DEFAULT_DATABASE_PATH)),
        help="DuckDB warehouse path (default: COMMERCE_PULSE_DB_PATH or data/warehouse.duckdb)",
    )
    parser.add_argument(
        "--raw-dir",
        type=Path,
        default=Path(os.getenv("COMMERCE_PULSE_RAW_DIR", DEFAULT_RAW_DIR)),
        help="Directory containing the seven raw CSV files",
    )
    return parser.parse_args()


def load_raw(database_path: Path, raw_dir: Path) -> None:
    database_path = database_path.resolve()
    raw_dir = raw_dir.resolve()
    missing = [str(raw_dir / f"{table}.csv") for table in TABLES if not (raw_dir / f"{table}.csv").is_file()]
    if missing:
        raise FileNotFoundError(f"Missing raw CSV files: {', '.join(missing)}")

    database_path.parent.mkdir(parents=True, exist_ok=True)
    with duckdb.connect(str(database_path)) as connection:
        connection.execute("begin transaction")
        try:
            connection.execute("create schema if not exists raw")
            for table in TABLES:
                csv_path = (raw_dir / f"{table}.csv").as_posix().replace("'", "''")
                select_clause = "*"
                if table == "order_items":
                    # The source has no line identifier and duplicate-looking rows
                    # are valid. Preserve CSV row order as a stable line identity.
                    select_clause = "row_number() over () as _source_row_number, *"
                connection.execute(
                    f"create or replace table raw.{table} as "
                    f"select {select_clause} from read_csv_auto('{csv_path}', header = true)"
                )
                row_count = connection.execute(f"select count(*) from raw.{table}").fetchone()[0]
                print(f"raw.{table}: {row_count:,} rows")
            connection.execute("commit")
        except Exception:
            connection.execute("rollback")
            raise


def main() -> None:
    args = parse_args()
    load_raw(args.database_path, args.raw_dir)


if __name__ == "__main__":
    main()
