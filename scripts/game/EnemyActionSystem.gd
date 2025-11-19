extends Node

class_name EnemyActionSystem

const DYNAMIC_VALUE_MAP := {"enemy_attack": "get_enemy_attack"}


static func execute(action_id: String, board: Node) -> void:
	var definition := GameState.get_enemy_action_definition(action_id)
	if definition == null or definition.is_empty():
		push_error("EnemyActionSystem: Unknown enemy action %s" % action_id)
		return

	if board.has_method("queue_message"):
		var label := definition.get("label", action_id)
		board.queue_message("Enemy uses %s." % label)

	var ctx := {
		"player_damage": 0,
		"heal_amount": 0,
	}

	for effect in definition.get("effects", []):
		_apply_effect(effect, ctx, board)

	_resolve_context(ctx, board)


static func _apply_effect(effect: Dictionary, context: Dictionary, board: Node) -> void:
	match effect.get("type", ""):
		"deal_damage":
			var value := _resolve_value(effect.get("amount", 0), board)
			context["player_damage"] = context.get("player_damage", 0) + value
		"gain_armor":
			if board.has_method("increase_enemy_armor"):
				var value := _resolve_value(effect.get("amount", 0), board)
				board.increase_enemy_armor(value)
		"heal_enemy":
			var value := _resolve_value(effect.get("amount", 0), board)
			context["heal_amount"] = context.get("heal_amount", 0) + value
		"apply_status":
			if board.has_method("apply_status_effect"):
				board.apply_status_effect(
					str(effect.get("target", "player")),
					str(effect.get("status", "")),
					int(effect.get("amount", 0)),
					int(effect.get("duration", 1))
				)
		_:
			push_warning("EnemyActionSystem: Unhandled effect type %s" % effect.get("type"))


static func _resolve_context(context: Dictionary, board: Node) -> void:
	var damage := int(context.get("player_damage", 0))
	if damage > 0 and board.has_method("apply_player_damage"):
		board.apply_player_damage(damage)

	var heal_amount := int(context.get("heal_amount", 0))
	if heal_amount > 0 and board.has_method("apply_enemy_heal"):
		var healed := board.apply_enemy_heal(heal_amount)
		if healed > 0 and board.has_method("queue_message"):
			board.queue_message("Enemy heals %d HP." % healed)


static func _resolve_value(value, board: Node) -> int:
	if typeof(value) == TYPE_STRING:
		if DYNAMIC_VALUE_MAP.has(value):
			var method := DYNAMIC_VALUE_MAP[value]
			if board.has_method(method):
				return int(board.call(method))
		else:
			if value.is_valid_int():
				return int(value)
			else:
				push_warning("EnemyActionSystem: Unknown dynamic value key: %s" % value)
				return 0
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_REAL:
		return int(value)
	push_warning("EnemyActionSystem: Invalid value type for _resolve_value: %s" % typeof(value))
	return 0
