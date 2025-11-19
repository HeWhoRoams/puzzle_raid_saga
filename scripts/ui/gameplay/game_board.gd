extends Control

signal menu_pressed
signal run_finished(results: Dictionary)

const BOARD_SIZE := 6
const TILE_TYPES := ["SWORD", "POTION", "SHIELD", "COIN", "XP", "MASK"]
const SWORD_DAMAGE := 2
const POTION_HEAL := 3
const SHIELD_GAIN := 1
const COIN_GAIN := 1
const XP_GAIN := 2
const MASK_DAMAGE := 2

enum TurnState {
	START_RUN,
	PLAYER_TURN,
	RESOLVE_CHAIN,
	ENEMY_TURN,
	CLEANUP,
	CHECK_END,
}

@onready var board_view: Control = %BoardView
@onready var ability_bar: HBoxContainer = %AbilityBar
@onready var pause_button: Button = %PauseButton
@onready var description_title: Label = %DescriptionTitle
@onready var description_body: RichTextLabel = %DescriptionBody
@onready var hp_value_label: Label = %HPValueLabel
@onready var armor_value_label: Label = %ArmorValueLabel
@onready var attack_value_label: Label = %AttackValueLabel
@onready var coins_value_label: Label = %CoinsValueLabel
@onready var xp_value_label: Label = %XPValueLabel
@onready var depth_value_label: Label = %DepthValueLabel
@onready var enemy_value_label: Label = %EnemyValueLabel
@onready var debug_info_label: Label = %DebugInfoLabel
@onready var run_stats_label: Label = %RunStatsLabel

var _run_config: Dictionary = {}
var _pending_setup: Dictionary = {}
var _board: Array = []
var _rng := RandomNumberGenerator.new()
var _selected_class_id := "warrior"
var _class_definition: Dictionary = {}
var _player_hp_max := 40
var _player_hp := 40
var _player_armor := 0
var _player_attack := 0
var _current_attack := 0
var _player_gold := 0
var _player_xp := 0
var _xp_target := 30

var _enemy_hp := 25
var _enemy_max_hp := 25
var _enemy_attack := 5
var _enemy_attack_bonus := 0
var _enemy_armor := 0
var _enemy_actions: Array[String] = []

var _depth := 0
var _kills := 0
var _log_lines: Array[String] = []

var _state: TurnState = TurnState.START_RUN
var _pending_chain: Array[Vector2i] = []
var _pending_messages: Array[String] = []
var _turn_consumed := false
var _current_chain_type := ""
var _current_chain_length := 0
var _last_damage_dealt := 0
var _relics: Array[String] = []
var _board_modifiers: Array[String] = []
var _spawn_rate_overrides: Dictionary = {}
var _player_status: Dictionary = {}
var _enemy_status: Dictionary = {}


func _configure_class(data: Dictionary) -> void:
	_selected_class_id = str(data.get("class_id", "warrior"))
	_class_definition = GameState.get_class_definition(_selected_class_id)


func _ready() -> void:
	pause_button.pressed.connect(_on_pause_pressed)
	board_view.path_committed.connect(_on_path_committed)
	ability_bar.ability_pressed.connect(_on_ability_pressed)
	_rng.randomize()
	description_title.text = "Event Log"
	var initial_data := _pending_setup if not _pending_setup.is_empty() else {}
	_configure_class(initial_data)
	_pending_setup.clear()
	_state = TurnState.START_RUN
	advance_state()


func _receive_data(data := {}) -> void:
	_pending_setup = data if data is Dictionary else {}
	if is_inside_tree():
		_configure_class(_pending_setup)
		_pending_setup.clear()
		_state = TurnState.START_RUN
		advance_state()


func finish_run(results: Dictionary) -> void:
	var payload := results.duplicate(true)
	if not payload.has("class_id"):
		payload["class_id"] = _selected_class_id
	run_finished.emit(payload)
	SceneManager.change_scene(SceneManager.SCENE_RUN_SUMMARY, payload)


func advance_state() -> void:
	match _state:
		TurnState.START_RUN:
			_do_start_run()
		TurnState.PLAYER_TURN:
			_do_player_turn()
		TurnState.RESOLVE_CHAIN:
			_do_resolve_chain()
		TurnState.ENEMY_TURN:
			_do_enemy_turn()
		TurnState.CLEANUP:
			_do_cleanup()
		TurnState.CHECK_END:
			_do_check_end()
		_:
			push_error("GameBoard: Unexpected state %s at depth %d" % [_state, _depth])
			_state = TurnState.CLEANUP
			advance_state()


func _do_start_run() -> void:
	_initialize_run()
	_apply_start_turn_effects()
	_state = TurnState.PLAYER_TURN
	advance_state()


func _do_player_turn() -> void:
	# Waiting for chain or ability input.
	pass


func _do_resolve_chain() -> void:
	if _pending_chain.is_empty():
		_state = TurnState.CHECK_END
		advance_state()
		return
	var summary := resolve_chain(_pending_chain)
	_pending_chain.clear()
	_queue_message(summary)
	_state = TurnState.ENEMY_TURN
	advance_state()


func _do_enemy_turn() -> void:
	var message := ""
	if _turn_consumed and _enemy_hp > 0:
		message = _enemy_turn()
	_queue_message(message)
	_state = TurnState.CLEANUP
	advance_state()


func _do_cleanup() -> void:
	if _turn_consumed:
		ability_bar.reduce_cooldowns()
		_depth += 1
	_process_status_effects()
	var message := "\n".join(_pending_messages)
	_pending_messages.clear()
	_update_stats_ui(message)
	_turn_consumed = false
	_state = TurnState.CHECK_END
	advance_state()


func _do_check_end() -> void:
	if _player_hp <= 0:
		_end_run()
		return
	_apply_start_turn_effects()
	_state = TurnState.PLAYER_TURN




func _initialize_run() -> void:
	_player_hp_max = int(_class_definition.get("base_hp", 40))
	_player_hp = _player_hp_max
	_player_armor = int(_class_definition.get("base_armor", 0))
	_player_attack = int(_class_definition.get("base_atk", 0))
	_player_gold = 0
	_player_xp = 0
	_xp_target = 30
	_depth = 0
	_kills = 0
	_relics = _class_definition.get("starting_relics", []).duplicate(true)
	_board_modifiers = _class_definition.get("starting_board_modifiers", []).duplicate(true)
	_spawn_rate_overrides.clear()
	_player_status.clear()
	_enemy_status.clear()
	var enemy := _generate_enemy_for_depth(0)
	_enemy_hp = enemy.get("hp", 20)
	_enemy_max_hp = enemy.get("hp", 20)
	_enemy_attack = enemy.get("atk", 5)
	_enemy_armor = enemy.get("armor", 0)
	_enemy_actions = enemy.get("actions", ["attack"])
	_log_lines.clear()
	_pending_messages.clear()
	_pending_chain.clear()
	_turn_consumed = false
	_recompute_spawn_overrides()
	_board = _generate_board()
	board_view.generate_new_board(_board)
	ability_bar.reset_cooldowns()
	if _class_definition.has("abilities"):
		ability_bar.set_active_abilities(_class_definition.get("abilities", []))
	_update_stats_ui("Run started.")


func _generate_board() -> Array:
	var board: Array = []
	for y in range(BOARD_SIZE):
		var row: Array = []
		for x in range(BOARD_SIZE):
			row.append(_random_tile())
		board.append(row)
	return board


func _random_tile() -> Dictionary:
	var weights: Dictionary = {}
	var total := 0.0
	for type_name in TILE_TYPES:
		var weight := float(_spawn_rate_overrides.get(type_name, 1.0))
		if weight <= 0.0:
			continue
		weights[type_name] = weight
		total += weight
	if total <= 0.0:
		var fallback := TILE_TYPES[_rng.randi_range(0, TILE_TYPES.size() - 1)]
		return {"type": fallback}
	var roll := _rng.randf_range(0.0, total)
	for type_name in TILE_TYPES:
		var weight := weights.get(type_name, 0.0)
		if weight <= 0.0:
			continue
		roll -= weight
		if roll <= 0.0:
			return {"type": type_name}
	return {"type": TILE_TYPES.back()}


func _on_pause_pressed() -> void:
	menu_pressed.emit()
	SceneManager.change_scene(SceneManager.SCENE_MAIN_MENU)


func _on_path_committed(cells: Array[Vector2i]) -> void:
	if cells.size() < 2 or _state != TurnState.PLAYER_TURN:
		return
	var tile := _board[cells[0].y][cells[0].x]
	_current_chain_type = str(tile.get("type", ""))
	_current_chain_length = cells.size()
	_pending_chain = cells.duplicate(true)
	_turn_consumed = true
	_state = TurnState.RESOLVE_CHAIN
	advance_state()


func _on_ability_pressed(id: StringName) -> void:
	if _state != TurnState.PLAYER_TURN:
		return
	AbilitySystem.execute(id, self)
	var ability_def := GameState.get_ability_definition(id)
	var cooldown := int(ability_def.get("cooldown", 0))
	var ctx := {"cooldown": cooldown}
	RelicSystem.apply_effects("on_cooldown", ctx, self)
	cooldown = max(0, int(ctx.get("cooldown", cooldown)))
	if cooldown > 0:
		ability_bar.set_cooldown(id, cooldown)
	_turn_consumed = true
	_state = TurnState.ENEMY_TURN
	advance_state()


func resolve_chain(cells: Array[Vector2i]) -> String:
	if cells.is_empty():
		return ""
	var chain_type := str(_board[cells[0].y][cells[0].x].get("type", ""))
	var amount := cells.size()
	var summary_lines: Array[String] = []
	_last_damage_dealt = 0

	match chain_type:
		"SWORD":
			summary_lines.append(_resolve_sword(amount))
		"POTION":
			summary_lines.append(_resolve_potion(amount))
		"SHIELD":
			summary_lines.append(_resolve_shield(amount))
		"COIN":
			summary_lines.append(_resolve_coins(amount))
		"XP":
			summary_lines.append(_resolve_xp(amount))
		"MASK":
			summary_lines.append(_resolve_mask(amount))
		_:
			summary_lines.append("Cleared %d tiles." % amount)

	_replace_chain_tiles(cells)
	return "\n".join(summary_lines.filter(func(line): return not line.is_empty()))


func _resolve_sword(amount: int) -> String:
	var damage := amount * SWORD_DAMAGE
	_current_attack = damage
	var dealt := apply_enemy_damage(damage)
	_last_damage_dealt = dealt
	return "Sword chain %d: dealt %d damage (%d raw)." % [amount, dealt, damage]


func _resolve_potion(amount: int) -> String:
	var heal_amount := amount * POTION_HEAL
	var healed := apply_player_heal(heal_amount)
	return "Potion chain %d: healed %d HP." % [amount, healed]


func _resolve_shield(amount: int) -> String:
	var gain := apply_player_armor(amount * SHIELD_GAIN)
	return "Shield chain %d: +%d armor." % [amount, gain]


func _resolve_coins(amount: int) -> String:
	var gold_gain := apply_coin_gain(amount * COIN_GAIN)
	return "Coin chain %d: +%d gold." % [amount, gold_gain]


func _resolve_xp(amount: int) -> String:
	var xp_gain := amount * XP_GAIN
	_player_xp += xp_gain
	var lines := "XP chain %d: +%d XP." % [amount, xp_gain]
	while _player_xp >= _xp_target:
		_player_xp -= _xp_target
		_xp_target += 10
		_player_hp_max += 5
		_player_hp = min(_player_hp + 5, _player_hp_max)
		lines += "\nLevel up! Max HP %d." % _player_hp_max
	return lines


func _resolve_mask(amount: int) -> String:
	var damage := amount * MASK_DAMAGE
	var dealt := apply_enemy_damage(damage)
	_last_damage_dealt = dealt
	return "Mask chain %d: enemy takes %d damage." % [amount, dealt]


func _replace_chain_tiles(cells: Array[Vector2i]) -> void:
	for cell in cells:
		_board[cell.y][cell.x] = _random_tile()
	board_view.set_board(_board)


func _enemy_turn() -> String:
	if not _turn_consumed or _enemy_hp <= 0:
		return ""
	var actions := _enemy_actions.duplicate()
	if actions.is_empty():
		actions = ["attack"]
	var action_id := actions[_rng.randi_range(0, actions.size() - 1)]
	var ctx := {"enemy_attack_bonus": 0}
	BoardModifierSystem.apply("enemy_turn", ctx, self)
	RelicSystem.apply_effects("enemy_turn", ctx, self)
	_enemy_attack_bonus = int(ctx.get("enemy_attack_bonus", 0))
	EnemyActionSystem.execute(action_id, self)
	_enemy_attack_bonus = 0
	return "Enemy acts (%s)." % action_id


func _spawn_next_enemy() -> void:
	var enemy := _generate_enemy_for_depth(_depth + 1)
	_depth = enemy.get("depth", _depth + 1)
	_enemy_hp = enemy.get("hp", 25)
	_enemy_max_hp = enemy.get("hp", 25)
	_enemy_attack = enemy.get("atk", 5)
	_enemy_armor = enemy.get("armor", 0)
	_enemy_actions = enemy.get("actions", ["attack"])
	_maybe_add_board_modifier_for_depth(_depth)


func _generate_enemy_for_depth(depth: int) -> Dictionary:
	return EnemyGenerator.get_enemy_for_depth(depth)


func _handle_enemy_defeat(prefix := "Enemy defeated!") -> String:
	if _enemy_hp > 0:
		return ""
	_kills += 1
	var message := "%s Total KOs: %d." % [prefix, _kills]
	_spawn_next_enemy()
	_maybe_award_relic()
	return message


func apply_enemy_damage(amount: int) -> int:
	var ctx := {"damage_amount": amount}
	RelicSystem.apply_effects("on_damage", ctx, self)
	BoardModifierSystem.apply("on_damage", ctx, self)
	var final := max(0, int(ctx.get("damage_amount", amount)))
	_enemy_hp = max(0, _enemy_hp - final)
	return final


func apply_player_heal(amount: int) -> int:
	var ctx := {"heal_amount": amount}
	RelicSystem.apply_effects("on_heal", ctx, self)
	BoardModifierSystem.apply("on_heal", ctx, self)
	var final := max(0, int(ctx.get("heal_amount", amount)))
	var previous := _player_hp
	_player_hp = min(_player_hp_max, _player_hp + final)
	return _player_hp - previous


func apply_player_armor(amount: int) -> int:
	var ctx := {"armor_amount": amount}
	RelicSystem.apply_effects("on_gain_armor", ctx, self)
	BoardModifierSystem.apply("on_gain_armor", ctx, self)
	var final := max(0, int(ctx.get("armor_amount", amount)))
	_player_armor += final
	return final


func apply_coin_gain(amount: int) -> int:
	var ctx := {"coin_gain": amount}
	RelicSystem.apply_effects("on_coin_gain", ctx, self)
	BoardModifierSystem.apply("on_coin_gain", ctx, self)
	var final := max(0, int(ctx.get("coin_gain", amount)))
	_player_gold += final
	return final


func apply_player_damage(amount: int) -> void:
	if amount <= 0:
		return
	_player_hp = max(0, _player_hp - amount)


func player_take_damage(amount: int) -> void:
	apply_player_damage(amount)


func replace_tiles_of_type(match_type: String) -> int:
	if match_type.is_empty():
		return 0
	var replaced := 0
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var tile := _board[y][x]
			if tile.get("type", "") == match_type:
				_board[y][x] = _random_tile()
				replaced += 1
	if replaced > 0:
		board_view.set_board(_board)
		_queue_message("Replaced %d %s tiles." % [replaced, match_type])
	return replaced


func remove_player_armor(amount: int) -> int:
	if amount <= 0:
		return 0
	var removed := min(_player_armor, amount)
	_player_armor = max(0, _player_armor - removed)
	return removed


func apply_spawn_override(tile_type: String, multiplier: float) -> void:
	if tile_type.is_empty():
		return
	var current := _spawn_rate_overrides.get(tile_type, 1.0)
	_spawn_rate_overrides[tile_type] = current * multiplier


func get_board_modifiers() -> Array[String]:
	return _board_modifiers


func add_board_modifier(modifier_id: String) -> void:
	if modifier_id.is_empty() or _board_modifiers.has(modifier_id):
		return
	if not GameState.board_modifier_definitions.has(modifier_id):
		return
	_board_modifiers.append(modifier_id)
	_recompute_spawn_overrides()
	var label := GameState.board_modifier_definitions[modifier_id].get("label", modifier_id)
	_queue_message("Board modifier active: %s" % label)


func get_relics() -> Array[String]:
	return _relics


func queue_message(text: String) -> void:
	_queue_message(text)


func get_enemy_attack() -> int:
	return _enemy_attack + _enemy_attack_bonus


func apply_status_effect(target: String, status: String, amount: int, duration: int) -> void:
	if status.is_empty() or duration <= 0:
		return
	var table := target == "enemy" ? _enemy_status : _player_status
	table[status] = {
		"amount": amount,
		"duration": duration,
	}
	var label := target == "enemy" ? "Enemy" : "Player"
	_queue_message("%s afflicted with %s (%d for %d turns)." % [label, status, amount, duration])


func _process_status_effects() -> void:
	_tick_status_dictionary(_player_status, true)
	_tick_status_dictionary(_enemy_status, false)


func _tick_status_dictionary(table: Dictionary, is_player: bool) -> void:
	var to_remove: Array[String] = []
	for status in table.keys():
		var data: Dictionary = table[status]
		var amount := int(data.get("amount", 0))
		match status:
			"poison":
				if amount > 0:
					if is_player:
						apply_player_damage(amount)
						_queue_message("Poison deals %d to you." % amount)
					else:
						var dealt := apply_enemy_damage(amount)
						if dealt > 0:
							_queue_message("Poison deals %d to enemy." % dealt)
		data["duration"] = int(data.get("duration", 0)) - 1
		if data["duration"] <= 0:
			to_remove.append(status)
	for status in to_remove:
		table.erase(status)


func _recompute_spawn_overrides() -> void:
	_spawn_rate_overrides.clear()
	BoardModifierSystem.apply("tile_generation", {}, self)


func _maybe_add_board_modifier_for_depth(depth: int) -> void:
	if depth <= 0:
		return
	if GameState.board_modifier_definitions.is_empty():
		return
	if depth % 4 != 0:
		return
	_add_random_board_modifier()


func _add_random_board_modifier() -> void:
	var keys := GameState.board_modifier_definitions.keys()
	var choices: Array[String] = []
	for id in keys:
		if _board_modifiers.has(id):
			continue
		choices.append(id)
	if choices.is_empty():
		return
	var chosen := choices[_rng.randi_range(0, choices.size() - 1)]
	add_board_modifier(chosen)


func get_relics() -> Array[String]:
	return _relics


func add_relic(relic_id: String) -> void:
	if relic_id.is_empty() or _relics.has(relic_id):
		return
	_relics.append(relic_id)
	var label := GameState.get_relic_definition(relic_id).get("label", relic_id)
	_queue_message("Gained relic: %s" % label)


func _maybe_award_relic() -> void:
	if GameState.relic_definitions.is_empty():
		return
	if _rng.randf() > 0.15:
		return
	var keys := GameState.relic_definitions.keys()
	var relic_id := keys[_rng.randi_range(0, keys.size() - 1)]
	add_relic(relic_id)


func _apply_start_turn_effects() -> void:
	var ctx := {}
	RelicSystem.apply_effects("start_turn", ctx, self)
	BoardModifierSystem.apply("start_turn", ctx, self)
	var armor_bonus := int(ctx.get("add_armor", 0))
	if armor_bonus != 0:
		var gained := apply_player_armor(armor_bonus)
		if gained > 0:
			_queue_message("Start turn armor +%d." % gained)


func apply_enemy_damage(amount: int) -> int:
	var ctx := {"damage_amount": amount}
	RelicSystem.apply_effects("on_enemy_damage", ctx, self)
	BoardModifierSystem.apply("on_enemy_damage", ctx, self)
	var final := max(0, int(ctx.get("damage_amount", amount)))
	_enemy_hp = max(0, _enemy_hp - final)
	if _enemy_hp <= 0:
		var defeat := _handle_enemy_defeat("Enemy defeated!")
		if not defeat.is_empty():
			_queue_message(defeat)
	return final


func apply_enemy_heal(amount: int) -> int:
	if amount <= 0:
		return 0
	var previous := _enemy_hp
	_enemy_hp = min(_enemy_max_hp, _enemy_hp + amount)
	return _enemy_hp - previous


func increase_enemy_armor(amount: int) -> void:
	_enemy_armor += amount


func apply_player_heal(amount: int) -> int:
	var ctx := {"heal_amount": amount}
	RelicSystem.apply_effects("on_heal", ctx, self)
	BoardModifierSystem.apply("on_heal", ctx, self)
	var final := max(0, int(ctx.get("heal_amount", amount)))
	var previous := _player_hp
	_player_hp = min(_player_hp_max, _player_hp + final)
	return _player_hp - previous


func apply_player_armor(amount: int) -> int:
	var ctx := {"armor_amount": amount}
	RelicSystem.apply_effects("on_gain_armor", ctx, self)
	BoardModifierSystem.apply("on_gain_armor", ctx, self)
	var final := max(0, int(ctx.get("armor_amount", amount)))
	_player_armor += final
	return final


func apply_player_damage(amount: int) -> void:
	if amount <= 0:
		return
	_player_hp = max(0, _player_hp - amount)


func remove_player_armor(amount: int) -> int:
	if amount <= 0:
		return 0
	var removed := min(_player_armor, amount)
	_player_armor -= removed
	return removed


func replace_tiles_of_type(match_type: String) -> int:
	if match_type.is_empty():
		return 0
	var replaced := 0
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var tile := _board[y][x]
			if tile.get("type", "") == match_type:
				_board[y][x] = _random_tile()
				replaced += 1
	if replaced > 0:
		board_view.set_board(_board)
		_queue_message("Replaced %d %s tiles." % [replaced, match_type])
	return replaced


func _queue_message(text: String) -> void:
	var trimmed := text.strip_edges()
	if not trimmed.is_empty():
		_pending_messages.append(trimmed)


func _update_stats_ui(message: String) -> void:
	if not message.is_empty():
		_log_lines.append(message)
		if _log_lines.size() > 4:
			var start := max(0, _log_lines.size() - 4)
			_log_lines = _log_lines.slice(start, _log_lines.size())
		description_body.text = "\n\n".join(_log_lines)

	hp_value_label.text = "%d / %d" % [_player_hp, _player_hp_max]
	armor_value_label.text = str(_player_armor)
	attack_value_label.text = str(_player_attack)
	coins_value_label.text = "%d" % _player_gold
	xp_value_label.text = "%d / %d" % [_player_xp, _xp_target]
	depth_value_label.text = str(_depth)
	enemy_value_label.text = "%d HP" % _enemy_hp

	var debug_text := (
		"Selected: %s | Chain: %d | Damage: %d | Enemy HP: %d"
		% [_current_chain_type, _current_chain_length, _last_damage_dealt, _enemy_hp]
	)
	debug_info_label.text = debug_text
	run_stats_label.text = (
		"Run Stats: HP %d/%d | Armor %d | Gold %d | XP %d/%d | Depth %d | Kills %d"
		% [
			_player_hp,
			_player_hp_max,
			_player_armor,
			_player_gold,
			_player_xp,
			_xp_target,
			_depth,
			_kills,
		]
	)
	print(debug_text)
	print(run_stats_label.text)


func _end_run() -> void:
	var summary := {
		"depth": _depth,
		"gold": _player_gold,
		"enemies_defeated": _kills,
		"class_id": _selected_class_id,
	}
	finish_run(summary)
