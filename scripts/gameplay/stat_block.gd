extends RefCounted
class_name StatBlock

## Utility methods for manipulating player stat dictionaries.

static func duplicate(stats: Dictionary) -> Dictionary:
	return stats.duplicate(true)

static func apply_equipment(base_stats: Dictionary, config: GameConfigResource) -> Dictionary:
	var effective := duplicate(base_stats)
	if not effective.has("equipment"):
		return _clamp_caps(effective)

	for slot in effective["equipment"].keys():
		var player_item = effective["equipment"][slot]
		if typeof(player_item) != TYPE_DICTIONARY:
			continue

		var item_id_value = player_item.get("item_id", player_item.get("itemId", ""))
		var item_id: StringName = item_id_value if item_id_value is StringName else StringName(str(item_id_value))
		if item_id.is_empty():
			continue

		var item_def: ItemDefinitionResource = ContentDB.get_item(item_id)
		if item_def == null:
			continue

		if item_def.upgrade_path.is_empty():
			continue

		var upgrade_level := int(player_item.get("current_upgrade_level", player_item.get("currentUpgradeLevel", 1)))
		upgrade_level = clampi(upgrade_level, 1, item_def.upgrade_path.size())
		if upgrade_level <= 0:
			continue

		var upgrade_data: Dictionary = item_def.upgrade_path[upgrade_level - 1]
		var modifiers: Dictionary = upgrade_data.get("modifiers", {})

		effective["max_hp"] = effective.get("max_hp", effective.get("maxHp", 0)) + modifiers.get("max_hp", modifiers.get("maxHp", 0))
		effective["max_armor"] = effective.get("max_armor", effective.get("maxArmor", 0)) + modifiers.get("max_armor", modifiers.get("maxArmor", 0))
		effective["attack"] = effective.get("attack", 0) + modifiers.get("attack", 0)

		var coin_mod := modifiers.get("coin_multiplier", modifiers.get("coinMultiplier", 1.0))
		if coin_mod != 1.0:
			effective["gold_multiplier"] = effective.get("gold_multiplier", 1.0) * coin_mod

		var xp_mod := modifiers.get("xp_multiplier", modifiers.get("xpGainMultiplier", 1.0))
		if xp_mod != 1.0:
			effective["xp_multiplier"] = effective.get("xp_multiplier", 1.0) * xp_mod

	return _clamp_caps(effective)

static func _clamp_caps(stats: Dictionary) -> Dictionary:
	stats["hp"] = clamp(stats.get("hp", 0), 0, stats.get("max_hp", stats.get("maxHp", 0)))
	stats["armor"] = clamp(stats.get("armor", 0), 0, stats.get("max_armor", stats.get("maxArmor", 0)))
	return stats
