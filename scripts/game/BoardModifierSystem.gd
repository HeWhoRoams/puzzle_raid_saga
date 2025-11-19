extends Node

class_name BoardModifierSystem


static func apply(trigger: String, context: Dictionary, board: Node) -> void:
	if not board.has_method("get_board_modifiers"):
		return
	var modifiers := board.get_board_modifiers()
	if modifiers.is_empty():
		return
	for modifier_id in modifiers:
		var definition := GameState.board_modifier_definitions.get(modifier_id, {})
		if definition.is_empty():
			continue
		for effect in definition.get("effects", []):
			var effect_trigger := effect.get("trigger", "")
			if effect_trigger != "" and effect_trigger != trigger:
				continue
			_apply_effect(effect, context, board)


static func _apply_effect(effect: Dictionary, context: Dictionary, board: Node) -> void:
	match effect.get("type", ""):
		"multiply_heal":
			var factor := float(effect.get("factor", 1.0))
			context["heal_amount"] = context.get("heal_amount", 0.0) * factor
		"add_enemy_damage":
			var bonus := int(effect.get("amount", 0))
			context["enemy_attack_bonus"] = context.get("enemy_attack_bonus", 0) + bonus
		"subtract_armor":
			if board.has_method("remove_player_armor"):
				var removed := board.remove_player_armor(int(effect.get("amount", 0)))
				if removed > 0 and board.has_method("queue_message"):
					board.queue_message("Lost %d armor from board effect." % removed)
		"modify_spawn_rate":
			if board.has_method("apply_spawn_override"):
				var tile := str(effect.get("tile", ""))
				var multiplier := float(effect.get("multiplier", 1.0))
				board.apply_spawn_override(tile, multiplier)
		"modify_coin_gain":
			var bonus_gold := int(effect.get("amount", 0))
			context["coin_gain"] = context.get("coin_gain", 0) + bonus_gold
		"start_turn_gain_armor":
			if board.has_method("apply_player_armor"):
				var gained := board.apply_player_armor(int(effect.get("amount", 0)))
				if gained > 0 and board.has_method("queue_message"):
					board.queue_message("Bonus armor +%d from modifier." % gained)
		_:
			push_warning("BoardModifierSystem: Unhandled effect type %s" % effect.get("type"))
