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


func _ready() -> void:
	_load_class_json()
	_load_ability_json()
	_load_relic_json()
	_load_board_modifier_json()
	_load_enemy_actions_json()
	load_state()


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
