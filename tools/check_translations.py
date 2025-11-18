#!/usr/bin/env python3
"""
Validates localization.csv for duplicate or empty keys and ensures the
compiled localization.en.translation resource exists.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = PROJECT_ROOT / "localization.csv"
TRANSLATION_PATH = PROJECT_ROOT / "localization.en.translation"


def main() -> int:
    problems: list[str] = []
    if not CSV_PATH.exists():
        print(f"{CSV_PATH} missing", file=sys.stderr)
        return 1

    seen_keys: dict[str, int] = {}
    with CSV_PATH.open(encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or "key" not in reader.fieldnames:
            problems.append("localization.csv must have a 'key' column.")
        if reader.fieldnames is None or "en" not in reader.fieldnames:
            problems.append("localization.csv must have an 'en' column.")

        for row_number, row in enumerate(reader, start=2):
            key = (row.get("key") or "").strip()
            text = (row.get("en") or "").strip()
            if not key:
                problems.append(f"Row {row_number}: empty key")
                continue
            if key in seen_keys:
                problems.append(
                    f"Row {row_number}: duplicate key '{key}' (first seen at row {seen_keys[key]})"
                )
            else:
                seen_keys[key] = row_number
            if not text:
                problems.append(f"Row {row_number}: key '{key}' has empty English text")

    if not TRANSLATION_PATH.exists():
        problems.append("Compiled translation resource localization.en.translation is missing.")

    if problems:
        print("Translation check failed:")
        for issue in problems:
            print(f" - {issue}")
        return 1

    print(f"Translation check passed ({len(seen_keys)} keys).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
