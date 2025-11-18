extends RefCounted
class_name PlayerStateFactory

const BASE_STATS := {
	"hp": 100,
	"max_hp": 100,
	"armor": 10,
	"max_armor": 10,
	"attack": 5,
	"gold": 0,
	"xp": 0,
	"level": 1,
	"class_id": "",
	"abilities": [],
	"poison_stacks": 0,
	"buffs": [],
	"equipment":
	{
		"weapon": null,
		"armor": null,
		"accessory1": null,
		"accessory2": null,
	},
}


static func create_for_class(class_def: ClassDefinitionResource) -> Dictionary:
	var stats := BASE_STATS.duplicate(true)
	if class_def:
		stats["class_id"] = class_def.content_id
		stats["max_hp"] += class_def.base_stat_modifiers.get("max_hp", 0)
		stats["max_armor"] += class_def.base_stat_modifiers.get("max_armor", 0)
		stats["attack"] += class_def.base_stat_modifiers.get("attack", 0)
	else:
		stats["class_id"] = StringName()

	stats["hp"] = stats["max_hp"]
	stats["armor"] = stats["max_armor"]
	stats["abilities"] = []

	if class_def:
		for ability_id in class_def.starting_ability_ids:
			(
				stats["abilities"]
				. append(
					{
						"id": ability_id,
						"current_level": 1,
						"current_cooldown": 0,
					}
				)
			)

	return stats
