#!/usr/bin/env python3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TRANSLATION_PATH = ROOT / "translations" / "en.translation"

def load_translations():
    keys = set()
    if not TRANSLATION_PATH.exists():
        return keys
    for line in TRANSLATION_PATH.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("[") or "=" not in line:
            continue
        key = line.split("=", 1)[0].strip()
        keys.add(key)
    return keys

def parse_properties(path: Path) -> dict:
    props = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("["):
            continue
        if "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        props[key.strip()] = value.strip().strip('"')
    return props

def upgrade_path_has_entries(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    marker = "upgrade_path"
    if marker not in text:
        return False
    segment = text.split(marker, 1)[1]
    before_close = segment.split("]", 1)[0]
    return "{" in before_close

def ensure_file_exists(rel_path: str) -> bool:
    if not rel_path.startswith("res://"):
        return True
    full = ROOT / rel_path.replace("res://", "")
    return full.exists()

def validate():
    translations = load_translations()
    errors = []
    for tres in (ROOT / "resources" / "abilities").glob("*.tres"):
        props = parse_properties(tres)
        if not ensure_file_exists(props.get("icon_path", "")):
            errors.append(f"{tres}: Missing ability icon {props.get('icon_path')}")
        for key_name in ("display_name", "description"):
            key = props.get(key_name, "")
            if key and key not in translations:
                errors.append(f"{tres}: Missing translation key {key}")
    for tres in (ROOT / "resources" / "classes").glob("*.tres"):
        props = parse_properties(tres)
        if not ensure_file_exists(props.get("icon_path", "")):
            errors.append(f"{tres}: Missing class icon {props.get('icon_path')}")
        for key_name in ("display_name", "description"):
            key = props.get(key_name, "")
            if key and key not in translations:
                errors.append(f"{tres}: Missing translation key {key}")
    for tres in (ROOT / "resources" / "items").glob("*.tres"):
        props = parse_properties(tres)
        if not ensure_file_exists(props.get("icon_path", "")):
            errors.append(f"{tres}: Missing item icon {props.get('icon_path')}")
        if not upgrade_path_has_entries(tres):
            errors.append(f"{tres}: upgrade_path appears empty")
        for key_name in ("display_name", "description"):
            key = props.get(key_name, "")
            if key and key not in translations:
                errors.append(f"{tres}: Missing translation key {key}")
    if errors:
        print("Resource validation failed:")
        print("\n".join(errors))
        sys.exit(1)
    print("Resource validation passed.")

if __name__ == "__main__":
    validate()
