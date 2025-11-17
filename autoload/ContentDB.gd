extends Node
class_name ContentDB

## Responsible for loading and indexing game definitions.

var _config: GameConfigResource
var _ability_map: Dictionary = {}
var _class_map: Dictionary = {}
var _enemy_map: Dictionary = {}
var _item_map: Dictionary = {}
var _difficulty_map: Dictionary = {}

func load_from_resource(config_resource: GameConfigResource) -> void:
	_config = config_resource
	_index_resources()

func get_config() -> GameConfigResource:
	return _config

func get_ability(id: StringName) -> AbilityDefinitionResource:
	return _ability_map.get(id)

func get_class(id: StringName) -> ClassDefinitionResource:
	return _class_map.get(id)

func get_enemy(id: StringName) -> EnemyDefinitionResource:
	return _enemy_map.get(id)

func get_item(id: StringName) -> ItemDefinitionResource:
	return _item_map.get(id)

func get_difficulty(id: StringName) -> DifficultyDefinitionResource:
	return _difficulty_map.get(id)

func _index_resources() -> void:
	_ability_map.clear()
	_class_map.clear()
	_enemy_map.clear()
	_item_map.clear()
	_difficulty_map.clear()

	for ability in _config.abilities:
		_ability_map[ability.content_id] = ability

	for cls in _config.classes:
		_class_map[cls.content_id] = cls

	for enemy in _config.enemies:
		_enemy_map[enemy.content_id] = enemy

	for item in _config.items:
		_item_map[item.content_id] = item

	for diff in _config.difficulties:
		_difficulty_map[diff.content_id] = diff
