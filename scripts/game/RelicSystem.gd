class_name RelicSystem


static func apply_effects(trigger: String, context: Dictionary, board: Node) -> void:
	if board == null or not board.has_method("get_relics"):
		return
	for relic_id in board.get_relics():
		var definition := GameState.get_relic_definition(relic_id)
		if definition.is_empty():
			continue
		for effect in definition.get("effects", []):
			var effect_trigger := effect.get("trigger", "")
			if effect_trigger != "" and effect_trigger != trigger:
				continue
			_apply_effect(relic_id, effect, context, board)


static func _validate_int(value, relic_name: String, effect_type: String, key: String) -> Variant:
	if value is int:
		return value
	elif value is float:
		return int(value)
	elif value is String and value.is_valid_int():
		return int(value)
	else:
		push_warning("RelicSystem: Invalid value for '%s' in effect '%s' for relic '%s': %s. Skipping effect." % [key, effect_type, relic_name, value])
		return null


static func _apply_effect(relic_id: String, effect: Dictionary, context: Dictionary, board: Node) -> void:
	var definition := GameState.get_relic_definition(relic_id)
	var relic_name := definition.get("name", relic_id)
	var effect_type := effect.get("type", "")
	match effect_type:
		"modify_heal":
			var amount = _validate_int(effect.get("amount", 0), relic_name, effect_type, "amount")
			if amount == null:
				return
			context["heal_amount"] = context.get("heal_amount", 0) + amount
		"modify_damage":
			var amount = _validate_int(effect.get("amount", 0), relic_name, effect_type, "amount")
			if amount == null:
				return
			context["damage_amount"] = context.get("damage_amount", 0) + amount
		"modify_coin_gain":
			var amount = _validate_int(effect.get("amount", 0), relic_name, effect_type, "amount")
			if amount == null:
				return
			context["coin_gain"] = context.get("coin_gain", 0) + amount
		"start_turn_gain_armor":
			var amount = _validate_int(effect.get("amount", 0), relic_name, effect_type, "amount")
			if amount == null:
				return
			context["add_armor"] = context.get("add_armor", 0) + amount
		"cooldown_modifier":
			var min_cd = _validate_int(effect.get("min", 0), relic_name, effect_type, "min")
			if min_cd == null:
				return
			var amount = _validate_int(effect.get("amount", 0), relic_name, effect_type, "amount")
			if amount == null:
				return
			context["cooldown"] = max(min_cd, context.get("cooldown", 0) + amount)
		_:
			push_warning("RelicSystem: Unhandled effect type %s for relic %s" % [effect_type, relic_name])
