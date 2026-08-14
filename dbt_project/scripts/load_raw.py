"""Load immutable source CSVs into the local DuckDB raw schema."""

from pathlib import Path

import duckdb


PROJECT_DIR = Path(__file__).resolve().parents[1]
REPO_DIR = PROJECT_DIR.parent
DATABASE_PATH = PROJECT_DIR / "dev.duckdb"
RAW_DIR = REPO_DIR / "data" / "raw"
TABLES = (
    "customers",
    "products",
    "sessions",
    "events",
    "orders",
    "order_items",
    "reviews",
)


def main() -> None:
    missing = [str(RAW_DIR / f"{table}.csv") for table in TABLES if not (RAW_DIR / f"{table}.csv").is_file()]
    if missing:
        raise FileNotFoundError(f"Missing raw CSV files: {', '.join(missing)}")

    with duckdb.connect(str(DATABASE_PATH)) as connection:
        connection.execute("create schema if not exists raw")
        for table in TABLES:
            csv_path = (RAW_DIR / f"{table}.csv").as_posix().replace("'", "''")
            select_clause = "*"
            if table == "order_items":
                # The source has no line identifier and duplicate-looking rows are
                # valid. Capture CSV row order at ingestion so every line retains
                # a stable identity without deduplicating business data.
                select_clause = "row_number() over () as _source_row_number, *"
            connection.execute(
                f"create or replace table raw.{table} as "
                f"select {select_clause} from read_csv_auto('{csv_path}', header = true)"
            )
            row_count = connection.execute(f"select count(*) from raw.{table}").fetchone()[0]
            print(f"raw.{table}: {row_count:,} rows")


if __name__ == "__main__":
    main()
