#!/usr/bin/env python3
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CSV_PATH = ROOT / "localization.csv"
TRANSLATION_PATH = ROOT / "translations" / "en.translation"

def main():
    TRANSLATION_PATH.parent.mkdir(parents=True, exist_ok=True)
    with CSV_PATH.open(encoding="utf-8") as f, TRANSLATION_PATH.open("w", encoding="utf-8") as out:
        reader = csv.DictReader(f)
        out.write("[translation]\n")
        for row in reader:
            key = row["key"]
            value = row["en"].replace('"', '\\"')
            out.write(f"{key}={value}\n")
    print("Exported translations to", TRANSLATION_PATH)

if __name__ == "__main__":
    main()
