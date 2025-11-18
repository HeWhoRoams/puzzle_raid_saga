extends Node

## Primary runtime state machine and orchestration point.

signal run_state_changed(new_state: RunState)

const ItemOfferGenerator = preload("res://scripts/gameplay/item_offer_generator.gd")

enum RunState {
	ATTRACT,
	CLASS_SELECT,
	GAMEPLAY,
	ITEM_OFFER,
	RUN_HISTORY,
	GAME_OVER,
}

@export_file("*.tres") var config_resource_path := "res://resources/game_config.tres"

var _config: GameConfigResource
var _initialized := false
var current_state: RunState = RunState.ATTRACT

var _player_stats: Dictionary = {}
var _depth := 1
var _game_log: Array[String] = []
var _current_class_id: StringName = StringName()
var _pending_item_offers: Array = []


func ensure_initialized() -> void:
	if _initialized:
		return

	if _config == null:
		if config_resource_path.is_empty():
			push_error("No config resource assigned to GameState.")
			return
		_config = load(config_resource_path)
		if _config == null:
			push_error("Failed to load config at %s" % config_resource_path)
			return

	ContentDB.load_from_resource(_config)
	SaveService.ensure_directories()
	BoardService.configure(_config, _config.default_difficulty)
	BoardService.regenerate_board(1)
	TurnResolver.configure(_config)
	_depth = 1
	_initialized = true


func change_state(new_state: RunState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	run_state_changed.emit(new_state)


func get_config() -> GameConfigResource:
	return _config


func get_run_state() -> RunState:
	return current_state


func has_saved_run() -> bool:
	return not SaveService.load_active_run().is_empty()


func get_current_class_definition() -> ClassDefinitionResource:
	if _current_class_id == StringName():
		return null
	return ContentDB.get_class_definition(_current_class_id)


func get_xp_progress() -> Dictionary:
	var stats: Dictionary = _player_stats
	if stats.is_empty():
		return {"current": 0, "required": _xp_required_for_level(1), "remaining": 0}
	var current_xp: int = stats.get("xp", 0)
	var required: int = _xp_required_for_level(stats.get("level", 1))
	return {
		"current": current_xp,
		"required": required,
		"remaining": max(0, required - current_xp),
	}


func start_new_run(class_id: StringName) -> void:
	ensure_initialized()

	var class_def: ClassDefinitionResource = ContentDB.get_class_definition(class_id)
	_player_stats = PlayerStateFactory.create_for_class(class_def)
	_current_class_id = class_id
	_depth = 1
	_game_log = []
	_pending_item_offers.clear()

	BoardService.regenerate_board(_depth)
	_append_logs(
		["A %s enters the dungeon." % (tr(class_def.display_name) if class_def else "wanderer")]
	)

	_persist_active_run()
	change_state(RunState.GAMEPLAY)


func continue_saved_run() -> bool:
	ensure_initialized()
	var data: Dictionary = SaveService.load_active_run()
	if data.is_empty():
		return false

	_player_stats = data.get("player_stats", {})
	_depth = data.get("depth", 1)
	_game_log = data.get("log", [])
	_current_class_id = _player_stats.get("class_id", StringName())

	var board: Array = data.get("board", []) as Array
	if board.is_empty():
		return false

	_pending_item_offers = data.get("pending_offers", [])

	BoardService.set_board(board, _depth)
	var saved_state: RunState = data.get("state", RunState.GAMEPLAY)
	if saved_state == RunState.ITEM_OFFER and not _pending_item_offers.is_empty():
		change_state(RunState.ITEM_OFFER)
	else:
		change_state(RunState.GAMEPLAY)
	return true


func abandon_run() -> void:
	SaveService.clear_active_run()
	_player_stats.clear()
	_game_log.clear()
	_depth = 1
	_current_class_id = StringName()
	_pending_item_offers.clear()
	change_state(RunState.ATTRACT)


func suspend_run_to_menu() -> void:
	if current_state == RunState.GAMEPLAY or current_state == RunState.ITEM_OFFER:
		_persist_active_run()
	change_state(RunState.ATTRACT)


func get_board_snapshot() -> Array:
	return BoardService.get_board()


func get_player_stats_snapshot() -> Dictionary:
	return _player_stats.duplicate(true)


func get_depth() -> int:
	return _depth


func get_log_snapshot() -> Array:
	return _game_log.duplicate()


func get_player_abilities() -> Array:
	var abilities: Array = []
	if _player_stats.is_empty():
		return abilities
	for ability in _player_stats.get("abilities", []):
		var ability_id: StringName = ability.get("id", StringName())
		var ability_def: AbilityDefinitionResource = ContentDB.get_ability(ability_id)
		if ability_def == null:
			continue
		(
			abilities
			. append(
				{
					"id": ability_id,
					"current_level": ability.get("current_level", ability.get("currentLevel", 1)),
					"current_cooldown":
					ability.get("current_cooldown", ability.get("currentCooldown", 0)),
					"definition": ability_def,
				}
			)
		)
	return abilities


func get_item_offers() -> Array:
	return _pending_item_offers.duplicate(true)


func get_run_history() -> Array:
	return SaveService.load_run_history()


func resolve_path(path: Array[Vector2i]) -> Dictionary:
	ensure_initialized()
	if current_state != RunState.GAMEPLAY:
		return {"success": false, "reason": "not_in_gameplay"}

	var board: Array = BoardService.get_board()
	var action_result: Dictionary = TurnResolver.resolve_player_action(board, _player_stats, path)
	if not action_result.get("valid", false):
		return {"success": false, "reason": action_result.get("reason", "invalid_path")}

	var logs: Array[String] = action_result.get("logs", [])

	for enemy_def in action_result.get("defeated_enemies", []):
		_player_stats["gold"] = _player_stats.get("gold", 0) + enemy_def.gold_reward
		_player_stats["xp"] = _player_stats.get("xp", 0) + enemy_def.xp_reward
		logs.append(
			(
				"You defeated %s. (+%s gold, +%s xp)"
				% [tr(enemy_def.display_name), enemy_def.gold_reward, enemy_def.xp_reward]
			)
		)

	var working_board: Array = action_result.get("board", board) as Array
	var removal_positions: Array = action_result.get("removed_positions", path) as Array
	BoardService.remove_tiles(working_board, removal_positions)

	var pre_attack: Dictionary = TurnResolver.resolve_enemy_pre_attacks(working_board)
	working_board = pre_attack.get("board", working_board)
	logs.append_array(pre_attack.get("logs", []))

	var effective_stats: Dictionary = StatBlock.apply_equipment(_player_stats, _config)
	var enemy_attacks: Dictionary = TurnResolver.resolve_enemy_attacks(
		working_board, _player_stats, effective_stats, path
	)
	_player_stats = enemy_attacks.get("player_stats", _player_stats)
	logs.append_array(enemy_attacks.get("logs", []))

	var poison: Dictionary = TurnResolver.apply_poison_damage(_player_stats)
	_player_stats = poison.get("player_stats", _player_stats)
	logs.append_array(poison.get("logs", []))

	var cooldown_tick: Dictionary = TurnResolver.tick_down_cooldowns_and_buffs(_player_stats)
	_player_stats = cooldown_tick.get("player_stats", _player_stats)
	logs.append_array(cooldown_tick.get("logs", []))

	var level_ups: Dictionary = TurnResolver.resolve_level_ups(_player_stats, _current_class_id)
	_player_stats = level_ups.get("player_stats", _player_stats)
	logs.append_array(level_ups.get("logs", []))

	_depth += 1
	var gravity_board: Array = BoardService.apply_gravity_and_refill(working_board, _depth)
	BoardService.set_board(gravity_board, _depth)

	_append_logs(logs)

	var player_dead: bool = _player_stats.get("hp", 0) <= 0
	if player_dead:
		_record_run_history(_player_stats, _depth - 1)
		change_state(RunState.GAME_OVER)
		SaveService.clear_active_run()
	else:
		_handle_post_turn_rewards(level_ups.get("leveled_up", false))
		_persist_active_run()

	return {
		"success": true,
		"logs": logs,
		"player_stats": _player_stats.duplicate(true),
		"board": gravity_board,
		"depth": _depth,
		"game_over": player_dead,
	}


func activate_ability(ability_id: StringName) -> Dictionary:
	ensure_initialized()
	if current_state != RunState.GAMEPLAY:
		return {"success": false, "reason": "not_in_gameplay"}

	var board: Array = BoardService.get_board()
	var result: Dictionary = TurnResolver.activate_ability(ability_id, board, _player_stats)
	if not result.get("success", false):
		return result

	_player_stats = result.get("player_stats", _player_stats)
	var new_board: Array = result.get("board", board) as Array
	BoardService.set_board(new_board, _depth)
	_append_logs(result.get("logs", []))
	_persist_active_run()
	return {"success": true}


func purchase_item_offer(index: int) -> Dictionary:
	if current_state != RunState.ITEM_OFFER:
		return {"success": false, "reason": "not_offer_state"}
	if _pending_item_offers.is_empty():
		return {"success": false, "reason": "no_offers"}
	if index < 0 or index >= _pending_item_offers.size():
		return {"success": false, "reason": "invalid_index"}

	var offer: Dictionary = _pending_item_offers[index]
	var equipment: Dictionary = _player_stats.get("equipment", {})
	if not _player_stats.has("equipment"):
		_player_stats["equipment"] = equipment

	match offer.get("type", ""):
		"new":
			equipment[offer["slot"]] = {
				"item_id": offer["item_id"],
				"itemId": offer["item_id"],
				"current_upgrade_level": 1,
				"currentUpgradeLevel": 1,
			}
			_append_logs(["You equipped the %s." % tr(offer.get("name", "item"))])
		"upgrade":
			var cost: int = offer.get("cost", 0)
			if _player_stats.get("gold", 0) < cost:
				return {"success": false, "reason": "not_enough_gold"}
			_player_stats["gold"] -= cost
			var slot: StringName = offer.get("slot", StringName())
			var equipped: Variant = equipment.get(slot)
			if equipped == null:
				return {"success": false, "reason": "missing_item"}
			equipped["current_upgrade_level"] = offer["next_level"]
			equipped["currentUpgradeLevel"] = offer["next_level"]
			_append_logs(
				["Upgraded %s to Level %d." % [tr(offer.get("name", "item")), offer["next_level"]]]
			)
		_:
			return {"success": false, "reason": "unknown_offer"}

	_pending_item_offers.clear()
	change_state(RunState.GAMEPLAY)
	_persist_active_run()
	return {"success": true}


func skip_item_offers() -> void:
	if current_state != RunState.ITEM_OFFER:
		return
	_pending_item_offers.clear()
	change_state(RunState.GAMEPLAY)
	_persist_active_run()


func _append_logs(new_logs: Array) -> void:
	_game_log.append_array(new_logs)
	var max_entries: int = 60
	if _game_log.size() > max_entries:
		_game_log = _game_log.slice(_game_log.size() - max_entries, _game_log.size())


func _handle_post_turn_rewards(leveled_up: bool) -> void:
	if not leveled_up:
		return
	_pending_item_offers = ItemOfferGenerator.generate_offers(_player_stats, _config, 3)
	if _pending_item_offers.is_empty():
		return
	change_state(RunState.ITEM_OFFER)


func _persist_active_run() -> void:
	var payload: Dictionary = {
		"player_stats": _player_stats,
		"depth": _depth,
		"log": _game_log,
		"board": BoardService.get_board(),
		"state": current_state,
		"pending_offers": _pending_item_offers,
	}
	SaveService.save_active_run(payload)


func _xp_required_for_level(level: int) -> int:
	if _config == null or _config.level_progression == null:
		return 0
	var progression: LevelProgressionResource = _config.level_progression
	return int(floor(progression.base_xp * pow(progression.xp_multiplier, level - 1)))


func _record_run_history(final_stats: Dictionary, final_depth: int) -> void:
	var class_def: ClassDefinitionResource = get_current_class_definition()
	var entry: Dictionary = {
		"id": int(Time.get_unix_time_from_system() * 1000.0),
		"date": Time.get_datetime_string_from_system(),
		"class_name": class_def.display_name if class_def else "Unknown",
		"final_level": final_stats.get("level", 1),
		"final_depth": max(1, final_depth),
		"score": _calculate_final_score(final_stats, final_depth),
	}
	SaveService.append_run_history(entry)


func _calculate_final_score(stats: Dictionary, depth: int) -> int:
	return int(depth * 100 + stats.get("gold", 0) * 5 + stats.get("level", 1) * 50)
