#!/usr/bin/env python3
"""
Simple asset sanity checker for PNG textures.

Ensures that every PNG under art/ has a matching .import file and that the
image dimensions are larger than 1×1 unless the asset is explicitly whitelisted.
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Iterable, Set, Tuple


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ART_DIR = PROJECT_ROOT / "art"
WHITELIST_PATH = PROJECT_ROOT / "docs" / "missing_graphics_assets.md"


def _load_whitelist() -> Set[Path]:
    entries: Set[Path] = set()
    if not WHITELIST_PATH.exists():
        return entries
    for line in WHITELIST_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line[0].isdigit():
            # Strip enumerated prefix like "1. path"
            line = line.split(".", 1)[-1].strip()
        line = line.strip("`")
        if line.startswith("art/") or line.startswith("art\\"):
            entries.add((PROJECT_ROOT / line).resolve())
    return entries


def _read_png_dimensions(path: Path) -> Tuple[int, int] | None:
    try:
        header = path.read_bytes()[:24]
    except OSError:
        return None
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    width = int.from_bytes(header[16:20], "big")
    height = int.from_bytes(header[20:24], "big")
    return width, height


def _iter_pngs() -> Iterable[Path]:
    if not ART_DIR.exists():
        return []
    return ART_DIR.rglob("*.png")


def main() -> int:
    whitelist = _load_whitelist()
    problems: list[str] = []

    for png_path in _iter_pngs():
        dimensions = _read_png_dimensions(png_path)
        if dimensions is None:
            problems.append(f"{png_path}: invalid or unreadable PNG header")
            continue

        width, height = dimensions
        if (
            (width <= 1 or height <= 1)
            and png_path.resolve() not in whitelist
        ):
            problems.append(
                f"{png_path}: suspicious size {width}x{height}; likely placeholder"
            )

        import_path = Path(str(png_path) + ".import")
        if not import_path.exists():
            problems.append(f"{png_path}: missing companion file {import_path.name}")

    if problems:
        print("Texture check failed:")
        for issue in problems:
            print(f" - {issue}")
        return 1

    print("Texture check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
