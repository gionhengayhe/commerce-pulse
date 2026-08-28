"""Download and validate the Commerce Pulse source snapshot from Kaggle Hub."""

from __future__ import annotations

import argparse
import csv
import os
import shutil
import tempfile
from pathlib import Path

import kagglehub


REPO_DIR = Path(__file__).resolve().parents[2]
DEFAULT_RAW_DIR = REPO_DIR / "data" / "raw"
DEFAULT_DATASET_HANDLE = "wafaaelhusseini/e-commerce-transactions-clickstream"
EXPECTED_HEADERS = {
    "customers.csv": (
        "customer_id", "name", "email", "country", "age", "signup_date", "marketing_opt_in",
    ),
    "events.csv": (
        "event_id", "session_id", "timestamp", "event_type", "product_id", "qty",
        "cart_size", "payment", "discount_pct", "amount_usd",
    ),
    "orders.csv": (
        "order_id", "customer_id", "order_time", "payment_method", "discount_pct",
        "subtotal_usd", "total_usd", "country", "device", "source",
    ),
    "order_items.csv": (
        "order_id", "product_id", "unit_price_usd", "quantity", "line_total_usd",
    ),
    "products.csv": (
        "product_id", "category", "name", "price_usd", "cost_usd", "margin_usd",
    ),
    "reviews.csv": (
        "review_id", "order_id", "product_id", "rating", "review_text", "review_time",
    ),
    "sessions.csv": (
        "session_id", "customer_id", "start_time", "device", "source", "country",
    ),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dataset",
        default=os.getenv("COMMERCE_PULSE_KAGGLE_DATASET", DEFAULT_DATASET_HANDLE),
        help="Kaggle dataset handle",
    )
    parser.add_argument(
        "--raw-dir",
        type=Path,
        default=Path(os.getenv("COMMERCE_PULSE_RAW_DIR", DEFAULT_RAW_DIR)),
        help="Destination directory for the seven validated source CSVs",
    )
    parser.add_argument(
        "--force-download",
        action="store_true",
        help="Ignore the Kaggle Hub cache and download the current version again",
    )
    return parser.parse_args()


def find_source_file(download_path: Path, filename: str) -> Path | None:
    if download_path.is_file():
        return download_path if download_path.name == filename else None

    matches = list(download_path.rglob(filename))
    if len(matches) > 1:
        raise RuntimeError(f"Kaggle download contains multiple {filename} files: {matches}")
    return matches[0] if matches else None


def validate_header(csv_path: Path, expected_header: tuple[str, ...]) -> None:
    with csv_path.open("r", encoding="utf-8-sig", newline="") as file:
        actual_header = tuple(next(csv.reader(file), ()))
    if actual_header != expected_header:
        raise RuntimeError(
            f"Unexpected schema for {csv_path.name}: "
            f"expected {expected_header}, received {actual_header}"
        )


def download_sources(dataset: str, force_download: bool) -> dict[str, Path]:
    download_path = Path(
        kagglehub.dataset_download(dataset, force_download=force_download)
    ).resolve()
    sources: dict[str, Path] = {}

    for filename in EXPECTED_HEADERS:
        source = find_source_file(download_path, filename)
        if source is None:
            targeted_path = Path(
                kagglehub.dataset_download(
                    dataset,
                    path=filename,
                    force_download=force_download,
                )
            ).resolve()
            source = find_source_file(targeted_path, filename)
        if source is None:
            raise FileNotFoundError(f"Kaggle dataset {dataset} is missing {filename}")
        validate_header(source, EXPECTED_HEADERS[filename])
        sources[filename] = source

    return sources


def sync_sources(sources: dict[str, Path], raw_dir: Path) -> None:
    raw_dir = raw_dir.resolve()
    raw_dir.parent.mkdir(parents=True, exist_ok=True)

    missing = sorted(set(EXPECTED_HEADERS) - set(sources))
    if missing:
        raise FileNotFoundError(f"Source snapshot is missing: {', '.join(missing)}")

    with tempfile.TemporaryDirectory(prefix=".raw-download-", dir=raw_dir.parent) as directory:
        staging_dir = Path(directory)
        for filename, expected_header in EXPECTED_HEADERS.items():
            staged_file = staging_dir / filename
            shutil.copy2(sources[filename], staged_file)
            validate_header(staged_file, expected_header)

        raw_dir.mkdir(parents=True, exist_ok=True)
        for filename in EXPECTED_HEADERS:
            staged_file = staging_dir / filename
            destination = raw_dir / filename
            os.replace(staged_file, destination)
            print(f"{destination}: {destination.stat().st_size:,} bytes")


def fetch_raw(dataset: str, raw_dir: Path, force_download: bool = False) -> None:
    sources = download_sources(dataset, force_download)
    sync_sources(sources, raw_dir)


def main() -> None:
    args = parse_args()
    fetch_raw(args.dataset, args.raw_dir, args.force_download)


if __name__ == "__main__":
    main()
