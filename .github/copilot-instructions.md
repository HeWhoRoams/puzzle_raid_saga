# Puzzle Raid Saga - AI Coding Guidelines

These notes are written specifically to help AI coding agents (Copilot-style helpers) be productive in this repository.

## Quick Summary (copy/paste)
- Use autoloads for all cross-component communication. Direct method calls for logic/state; signals only for UI updates.
- All game definitions (abilities, relics, board modifiers, enemy actions) come from JSON files loaded in `GameState`.
- No networking, no external APIs. Only Godot + simple Python tooling for validation/formatting.
- When implementing features, update JSON definitions and use the appropriate system executor (AbilitySystem, RelicSystem, BoardModifierSystem, EnemyActionSystem).
- Do not hardcode gameplay logic inside `GameBoard`.
- Ignore `archive/react_legacy` — legacy UI only.

## Architecture Overview
This is a Godot 4.x turn-based puzzle-raid game. The project centers around autoload singletons (see `project.godot`) that provide global services:
- `GameState`: Loads JSON definitions, manages meta-progression (`user://meta.json`), starts/suspends runs, and exposes player/run state.
- `ContentDB`: Indexes resource objects (when used) and exposes lookups for abilities, classes, enemies.
- `BoardService`: Board generation, validation, duplication helpers and tile helpers.
- `TurnResolver`: Resolves player chains, enemy pre/post actions, and applies stat/effect calculations.

Data sources:
- Primary: `data/*.json` files (abilities, classes, enemy_actions, relics, board_modifiers, etc.).
- Secondary: `.tres` resources under `resources/` and `game_config.tres` / `GameConfigResource` exist but are not the primary runtime path currently.

## Cross-Component Communication (critical)
- Pattern: Use direct method calls to autoload singletons for all game logic and state. Scenes call autoload methods directly (e.g., `GameState.start_new_run()`), not each other.
- Signals: Reserved for UI notifications and event bubbling to UI; do not rely on signals for core game-turn execution.
- Turn logic: Implemented through `TurnResolver` and supporting systems (EnemyActionSystem, AbilitySystem). Avoid placing game rules in scene scripts.

Copilot Rule: "Use direct method calls to autoloads for logic/state. Use signals only to notify UI or bubble events."

## External Dependencies & Integrations
- Godot 4.x is the runtime.
- Python dev tooling: `gdtoolkit` (gdformat/gdlint) and `jsonschema` used in `lint-gd.ps1` and `tools/` scripts.
- No networking, no external APIs, no custom asset pipeline, and no specialized audio/network libraries in the repo.

Copilot Rule: "Assume no networking, no external APIs, no custom backend. All data comes from local JSON files or Godot resources."

## Data Flow Nuances (important)
Two observed patterns. Agents must prefer A unless code shows explicit resource usage.

A) JSON-first runtime (active)
- Many systems load plain JSON at runtime using `GameState` and treat them as dictionaries (examples: `data/abilities.json`, `data/relics.json`, `data/board_modifiers.json`, `data/enemy_actions.json`).
- When changing gameplay content, update these JSON files and update any schema-required fields (see `data/schemas/`).

B) Resource pipeline (present but not primary)
- There are `.tres` resources and a `GameConfigResource` + `ContentDB` indexing. These appear available but not always wired into the JSON-loading runtime path.
- Do not assume hot-reload of `.tres` resources; JSON changes reload on next run.

Development reload behavior:
- Edit JSON -> restart/run Godot -> `GameState` will pick up changed definitions.
- `.tres` changes require explicit reloading or editor-managed export; no automatic hot-reload expected.

Copilot Rule: "Prefer JSON → GameState loading for definitions. Do not assume resources are used unless the file explicitly imports them."

## Testing & Debugging Workflows
- Lint & formatting: Run `lint-gd.ps1`. It installs dev Python deps, runs `gdlint` and `gdformat`, validates JSON schemas, and attempts smoke/unit tests if Godot CLI is available.
- Smoke tests: `godot --headless --script tests/run_smoke_tests.gd` (see `tests/run_smoke_tests.gd`). These validate autoloads and perform a minimal run-through.
- Unit tests: Light Godot tests under `tests/unit/` (invoked by the lint script when available).
- Debugging: `print()` logging is common; Godot debugger breakpoints occasionally used. The `GameBoard`/`TurnResolver` code paths are primary debug targets for gameplay bugs.

Copilot Rule: "When adding new systems, write small smoke tests or run Godot headless to ensure no script errors. Use print-style debugging inside complex turn logic."

## Example Changes & Common Pitfalls
- Adding abilities/relics/modifiers: update the correct `data/*.json`, ensure IDs and schema fields match, and only extend system executors (AbilitySystem, RelicSystem, BoardModifierSystem) if adding new effect types.
- Modifying turn logic: integrate with `TurnResolver` and `TurnStateMachine`. Ensure cleanup phases and statuses are applied correctly.
- Adding a class: update `data/classes.json` (or `GameState` dictionaries if that pattern is used) and confirm referenced abilities exist.

Pitfalls to avoid:
- Forgetting to add load calls in `GameState` for new JSON files.
- Misnaming IDs (ability/relic/class ids are string keys used throughout systems).
- Hardcoding logic into `GameBoard` instead of the designated systems.

Copilot Rule: "Always update JSON definitions and use the system executors. Never hardcode logic directly into `GameBoard`."

## React legacy folder
- `archive/react_legacy/` contains old React code (e.g., `AbilityBar.tsx`) that is not referenced by the Godot project.
- It is provided only for design reference and should be ignored for runtime or integration tasks.

Copilot Rule: "Ignore the react_legacy folder. It is not part of the active project."

## Files & Places To Inspect For Common Tasks
- Autoloads: `autoload/GameState.gd`, `autoload/ContentDB.gd`, `autoload/BoardService.gd`, `autoload/TurnResolver.gd`.
- Data & Schemas: `data/*.json`, `data/schemas/*.schema.json`, `tools/validate_json_schemas.py`.
- Tests: `tests/run_smoke_tests.gd`, `tests/unit/`.
- Lint script: `lint-gd.ps1`.

## Final Copilot Checklist (short)
1. Look for JSON definition under `data/` and schema in `data/schemas/`.
2. Update JSON, validate with `tools/validate_json_schemas.py` or `lint-gd.ps1`.
3. Modify systems (AbilitySystem, TurnResolver) — call autoloads directly.
4. Run headless smoke tests: `godot --headless --script tests/run_smoke_tests.gd`.

---

If you'd like, I can run `lint-gd.ps1` or open specific autoload files and annotate hotspots or common change patterns. Which would you prefer next?
# Puzzle Raid Saga - AI Coding Guidelines

## Architecture Overview
This is a Godot 4.5 turn-based puzzle raid game. Core architecture uses autoload singletons for global services:
- `GameState`: Manages meta-progress (XP, unlocks), run state, and loads JSON data definitions.
- `ContentDB`: Indexes game resources (abilities, classes, enemies) from `GameConfigResource`.
- `TurnResolver`: Handles player path resolution, enemy actions, and stat calculations.
- `BoardService`: Manages board generation, validation, and tile logic.

Data flows from JSON files in `data/` (validated against schemas in `data/schemas/`) to `.tres` resources in `resources/`, loaded via `GameConfigResource`.

## Key Patterns
- **Stat Management**: Use `StatBlock.gd` for player/enemy stats; apply equipment via `StatBlock.apply_equipment()`.
- **Board Logic**: Paths are arrays of `Vector2i`; validate with `BoardService.validate_path()` before resolving.
- **Abilities/Effects**: Defined in JSON with types like "damage_enemy", "heal_player"; effects applied in `TurnResolver`.
- **Localization**: Use `tr()` for strings; translations in `localization.en.translation`.
- **Persistence**: Meta data saved as JSON to `user://meta.json`; no run persistence yet.

## Development Workflows
- **Linting/Formatting**: Run `lint-gd.ps1` to check GDScript with gdlint/gdformat, validate JSON schemas, and execute smoke tests.
- **Testing**: Smoke tests via `godot --headless --script tests/run_smoke_tests.gd`; unit tests in `tests/unit/`.
- **Validation**: Use `tools/validate_json_schemas.py` for data integrity; `tools/check_textures.py` for assets.
- **Build/Export**: Use Godot editor's export feature; no custom build scripts.

## Conventions
- GDScript: snake_case functions/variables, PascalCase classes.
- JSON: Keys in snake_case; required fields per schemas (e.g., abilities need "label", "cooldown", "effects").
- Resources: `.tres` files for Godot resources; edit in editor or via code.
- File Structure: `autoload/` for singletons, `scenes/` for UI/gameplay, `data/` for JSON, `resources/` for assets.

## Examples
- Adding ability: Define in `data/abilities.json`, validate schema, reload `GameConfigResource`.
- Modifying turn logic: Edit `TurnResolver.resolve_player_action()`, test with smoke tests.
- New class: Add to `data/classes.json`, ensure stats via `StatBlock`.

Reference: `project.godot` for autoloads, `data/schemas/` for data structures.</content>
<parameter name="filePath">c:\github\puzzle_raid_saga\puzzle_raid_saga\.github\copilot-instructions.md