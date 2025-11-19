extends Node

class_name EnemyGenerator

const ARCHETYPES := {
	"brute": {
		"base_hp": 20,
		"base_atk": 4,
		"base_armor": 0,
		"hp_scale": 3.0,
		"atk_scale": 1.0,
		"armor_scale": 0.2,
		"actions": ["attack", "armorbuff"],
	},
	"assassin": {
		"base_hp": 12,
		"base_atk": 6,
		"base_armor": 0,
		"hp_scale": 2.0,
		"atk_scale": 1.5,
		"armor_scale": 0.1,
		"actions": ["attack", "poison_player"],
	},
	"guardian": {
		"base_hp": 18,
		"base_atk": 3,
		"base_armor": 2,
		"hp_scale": 2.5,
		"atk_scale": 0.8,
		"armor_scale": 0.4,
		"actions": ["attack", "armorbuff"],
	},
	"leech": {
		"base_hp": 15,
		"base_atk": 4,
		"base_armor": 0,
		"hp_scale": 2.2,
		"atk_scale": 1.0,
		"armor_scale": 0.2,
		"actions": ["attack", "heal_self"],
	},
}


func get_enemy_for_depth(depth: int) -> Dictionary:
	var ids := ARCHETYPES.keys()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var archetype_id := ids[rng.randi_range(0, ids.size() - 1)]
	var archetype: Dictionary = ARCHETYPES.get(archetype_id, {})
	var hp := archetype.get("base_hp", 10) + depth * float(archetype.get("hp_scale", 2.0))
	var atk := archetype.get("base_atk", 3) + depth * float(archetype.get("atk_scale", 1.0))
	var armor := archetype.get("base_armor", 0) + depth * float(archetype.get("armor_scale", 0.1))
	var actions: Array = archetype.get("actions", ["attack"])
	return {
		"type": archetype_id,
		"hp": max(5, int(round(hp))),
		"atk": max(1, int(round(atk))),
		"armor": max(0, int(round(armor))),
		"actions": actions,
		"depth": depth,
	}
