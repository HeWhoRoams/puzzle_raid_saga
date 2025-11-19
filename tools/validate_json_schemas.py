#!/usr/bin/env python3
"""
Validate JSON files against their schemas.
"""

import json
import sys
from pathlib import Path
from jsonschema import validate, ValidationError

def validate_json_with_schema(json_path: Path, schema_path: Path) -> bool:
    """Validate a JSON file against a schema. Returns True if valid."""
    try:
        with open(json_path, 'r') as f:
            data = json.load(f)
        with open(schema_path, 'r') as f:
            schema = json.load(f)
        validate(instance=data, schema=schema)
        print(f"✓ {json_path} is valid against {schema_path}")
        return True
    except ValidationError as e:
        print(f"✗ Validation error in {json_path}: {e.message}")
        print(f"  Path: {' -> '.join(str(p) for p in e.absolute_path)}")
        return False
    except Exception as e:
        print(f"✗ Error validating {json_path}: {e}")
        return False

def main():
    """Main validation function."""
    repo_root = Path(__file__).parent.parent
    validations = [
        (repo_root / "data" / "enemy_actions.json", repo_root / "data" / "schemas" / "enemy_actions.schema.json"),
        (repo_root / "data" / "abilities.json", repo_root / "data" / "schemas" / "abilities.schema.json"),
        (repo_root / "data" / "classes.json", repo_root / "data" / "schemas" / "classes.schema.json"),
    ]

    all_valid = True
    for json_file, schema_file in validations:
        if not json_file.exists():
            print(f"✗ JSON file not found: {json_file}")
            all_valid = False
            continue
        if not schema_file.exists():
            print(f"✗ Schema file not found: {schema_file}")
            all_valid = False
            continue
        if not validate_json_with_schema(json_file, schema_file):
            all_valid = False

    if not all_valid:
        sys.exit(1)
    print("All validations passed!")

if __name__ == "__main__":
    main()