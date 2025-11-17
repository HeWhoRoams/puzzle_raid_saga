extends RefCounted
class_name ItemOfferGenerator

static func generate_offers(player_stats: Dictionary, config: GameConfigResource, max_offers: int = 3) -> Array:
	var offers: Array = []
	if config == null:
		return offers

	var equipment: Dictionary = player_stats.get("equipment", {})
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Potential new equipment for empty slots
	for slot in equipment.keys():
		if equipment[slot] != null:
			continue
		var candidates := _items_for_slot(config.items, slot)
		if candidates.is_empty():
			continue
		var item: ItemDefinitionResource = candidates[rng.randi_range(0, candidates.size() - 1)]
		offers.append(_build_new_item_offer(item))

	# Upgrades for equipped items
	for slot in equipment.keys():
		var equipped = equipment[slot]
		if equipped == null:
			continue
		var equipped_id = equipped.get("item_id", equipped.get("itemId", ""))
		var item_def := _find_item(config.items, equipped_id)
		if item_def == null:
			continue
		var current_level := int(equipped.get("current_upgrade_level", equipped.get("currentUpgradeLevel", 1)))
		if current_level >= item_def.upgrade_path.size():
			continue
		var next_level := current_level + 1
		var upgrade_info: Dictionary = item_def.upgrade_path[next_level - 1]
		offers.append({
			"type": "upgrade",
			"item_id": item_def.content_id,
			"name": item_def.display_name,
			"description": item_def.description,
			"slot": slot,
			"current_level": current_level,
			"next_level": next_level,
			"cost": upgrade_info.get("cost", 0),
			"modifiers": upgrade_info.get("modifiers", {}),
			"icon_path": item_def.icon_path,
		})

	if offers.size() > max_offers:
		offers.shuffle()
		return offers.slice(0, max_offers)
	return offers

static func _items_for_slot(items: Array, slot: StringName) -> Array:
	var filtered: Array = []
	for item in items:
		if item.slot == slot:
			filtered.append(item)
	return filtered

static func _find_item(items: Array, item_id: String) -> ItemDefinitionResource:
	for item in items:
		if item.content_id == item_id:
			return item
	return null

static func _build_new_item_offer(item_def: ItemDefinitionResource) -> Dictionary:
	return {
		"type": "new",
		"item_id": item_def.content_id,
		"name": item_def.display_name,
		"description": item_def.description,
		"slot": item_def.slot,
		"cost": 0,
		"modifiers": item_def.upgrade_path[0].get("modifiers", {}) if item_def.upgrade_path.size() > 0 else {},
		"icon_path": item_def.icon_path,
	}
