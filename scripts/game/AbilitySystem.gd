extends Node

class_name AbilitySystem


static func execute(ability_id: String, board: Node) -> void:
	var definition: Dictionary = GameState.get_ability_definition(ability_id)
	if definition == null or definition.is_empty():
		push_error("AbilitySystem: Unknown ability %s" % ability_id)
		return

	for effect in definition.get("effects", []):
		_apply_effect(effect, board)


static func _apply_effect(effect: Dictionary, board: Node) -> void:
	match effect.get("type", ""):
		"damage_enemy":
			var amount := int(effect.get("amount", 0))
			if board.has_method("apply_enemy_damage"):
				board.apply_enemy_damage(amount)
			else:
				push_error("AbilitySystem: Board lacks apply_enemy_damage method")
		"heal_player":
			var heal_amount := int(effect.get("amount", 0))
			if board.has_method("apply_player_heal"):
				board.apply_player_heal(heal_amount)
			else:
				push_error("AbilitySystem: Board lacks apply_player_heal method")
		"gain_armor":
			var armor_amount := int(effect.get("amount", 0))
			if board.has_method("apply_player_armor"):
				board.apply_player_armor(armor_amount)
			else:
				push_error("AbilitySystem: Board lacks apply_player_armor method")
		"replace_tile_type":
			var match_type := str(effect.get("match", ""))
			var replace_to := str(effect.get("replace_to", ""))
			if board.has_method("replace_tiles_of_type"):
				board.replace_tiles_of_type(match_type, replace_to)
			else:
				push_error("AbilitySystem: Board lacks replace_tiles_of_type method")
		_:
			push_warning("AbilitySystem: Unhandled effect type %s" % effect.get("type"))
