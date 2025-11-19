extends Node

const SAVE_PATH := "user://meta.json"

var meta_data: Dictionary = {
	"schema_version": 1,
	"meta_xp": 0,
	"meta_gold": 0,
	"unlocked_classes": ["warrior"],
	"unlocked_abilities": [],
	"permanent_upgrades": {},
	"settings": {
		"sound_enabled": true,
		"music_enabled": true,
	},
}
var class_definitions: Dictionary = {}
var ability_definitions: Dictionary = {}
var relic_definitions: Dictionary = {}
var board_modifier_definitions: Dictionary = {}
var enemy_action_definitions: Dictionary = {}

var _config_resource = null
var _initialized: bool = false
var _current_board: Array = []
var _player_class_id: String = ""


func _ready() -> void:
	_load_class_json()
	_load_ability_json()
	_load_relic_json()
	_load_board_modifier_json()
	_load_enemy_actions_json()
	load_state()
	_load_game_config()


func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("GameState: No save file found, using defaults.")
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("GameState: Unable to open save file for reading.")
		return

	var content: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameState: Invalid save data, using defaults.")
		file.close()
		return

	_merge_defaults(meta_data, parsed)
	file.close()


func save_state() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: Unable to open save file for writing.")
		return
	file.store_string(JSON.stringify(meta_data, "\t"))
	file.close()


func add_meta_xp(amount: int, auto_save: bool = true) -> void:
	meta_data["meta_xp"] = max(0, meta_data.get("meta_xp", 0) + amount)
	if auto_save:
		save_state()


func add_meta_gold(amount: int, auto_save: bool = true) -> void:
	meta_data["meta_gold"] = max(0, meta_data.get("meta_gold", 0) + amount)
	if auto_save:
		save_state()


func unlock_class(class_id: String) -> void:
	var list: Array = meta_data.get("unlocked_classes", [])
	if class_id in list:
		return
	list.append(class_id)
	meta_data["unlocked_classes"] = list
	save_state()


func unlock_ability(ability_id: String) -> void:
	var list: Array = meta_data.get("unlocked_abilities", [])
	if ability_id in list:
		return
	list.append(ability_id)
	meta_data["unlocked_abilities"] = list
	save_state()


func set_upgrade(key: String, value: Variant) -> void:
	var upgrades: Dictionary = meta_data.get("permanent_upgrades", {})
	upgrades[key] = value
	meta_data["permanent_upgrades"] = upgrades
	save_state()


func is_class_unlocked(class_id: String) -> bool:
	return class_id in meta_data.get("unlocked_classes", [])


func is_ability_unlocked(ability_id: String) -> bool:
	return ability_id in meta_data.get("unlocked_abilities", [])


func get_meta_snapshot() -> Dictionary:
	return meta_data.duplicate(true)


func get_class_definition(class_id: String) -> Dictionary:
	return class_definitions.get(class_id, {}).duplicate(true)


func get_ability_definition(ability_id: String) -> Dictionary:
	return ability_definitions.get(ability_id, {}).duplicate(true)


func get_relic_definition(relic_id: String) -> Dictionary:
	return relic_definitions.get(relic_id, {}).duplicate(true)


func get_board_modifier_definition(modifier_id: String) -> Dictionary:
	return board_modifier_definitions.get(modifier_id, {}).duplicate(true)


func get_enemy_action_definition(action_id: String) -> Dictionary:
	return enemy_action_definitions.get(action_id, {}).duplicate(true)


func _load_game_config() -> void:
	var cfg := load("res://resources/game_config.tres")
	if cfg:
		_config_resource = cfg
	else:
		push_warning("GameState: game_config.tres not found; get_config() will return a minimal stub.")


func ensure_initialized() -> void:
	if _initialized:
		return
	if _config_resource:
		ContentDB.load_from_resource(_config_resource)
		BoardService.configure(_config_resource)
		TurnResolver.configure(_config_resource)
	else:
		push_warning("GameState: ensure_initialized called but no config resource loaded.")
	_initialized = true


func get_config() -> Variant:
	return _config_resource if _config_resource else {
		"classes": [],
		"min_path_length": 3,
		"board_size": 6,
	}


func start_new_run(class_id: String) -> void:
	_player_class_id = class_id
	if _config_resource:
		BoardService.regenerate_board(1)
		_current_board = BoardService.get_board()


func get_player_abilities() -> Array:
	return []


func activate_ability(ability_id: String) -> void:
	# Minimal stub; abilities are not required for smoke tests
	return


func suspend_run_to_menu() -> void:
	# Minimal stub used by smoke tests
	return


func get_board_snapshot() -> Array:
	return BoardService.get_board()


func resolve_path(path: Array) -> Dictionary:
	# Minimal local resolver for smoke tests: validate path, remove tiles, apply gravity/refill.
	var board := BoardService.get_board()
	var cfg: Variant = get_config()
	var minlen: int = 3
	if typeof(cfg) == TYPE_DICTIONARY:
		minlen = int(cfg.get("min_path_length", 3))
	var validation := BoardService.validate_path(board, path, minlen)
	if not validation.get("valid", false):
		return {"success": false}

	# Remove tiles in path
	BoardService.remove_tiles(board, path)
	var new_board := BoardService.apply_gravity_and_refill(board, BoardService.get_depth())
	BoardService.set_board(new_board, BoardService.get_depth())
	return {"success": true}


func _merge_defaults(defaults: Dictionary, loaded: Dictionary) -> void:
	for key in defaults.keys():
		if loaded.has(key):
			if defaults[key] is Dictionary and loaded[key] is Dictionary:
				_merge_defaults(defaults[key], loaded[key])
			else:
				defaults[key] = loaded[key]
	# Optionally preserve keys from loaded that aren't in defaults
	for key in loaded.keys():
		if not defaults.has(key):
			defaults[key] = loaded[key]

func _load_class_json() -> void:
	class_definitions = _load_json_dictionary("res://data/classes.json")


func _load_ability_json() -> void:
	ability_definitions = _load_json_dictionary("res://data/abilities.json")


func _load_relic_json() -> void:
	relic_definitions = _load_json_dictionary("res://data/relics.json")


func _load_board_modifier_json() -> void:
	board_modifier_definitions = _load_json_dictionary("res://data/board_modifiers.json")


func _load_enemy_actions_json() -> void:
	enemy_action_definitions = _load_json_dictionary("res://data/enemy_actions.json")


func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("GameState: Missing data file %s" % path)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameState: Unable to read %s" % path)
		return {}
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameState: Invalid JSON format in %s" % path)
		file.close()
		return {}
	file.close()
	return parsed
