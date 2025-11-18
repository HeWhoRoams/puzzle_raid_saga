extends SceneTree


func _init() -> void:
	GameState.ensure_initialized()
	_test_sword_damage_distribution()
	_test_buff_consumption()
	_test_poison_tick()
	_test_activate_ability()
	print("TurnResolver unit tests passed.")
	quit()


func _test_sword_damage_distribution() -> void:
	var stats := {
		"attack": 10,
		"hp": 50,
		"max_hp": 50,
		"armor": 5,
		"max_armor": 5,
		"gold": 0,
		"xp": 0,
		"level": 1,
		"class_id": "warrior",
		"abilities": [],
		"poison_stacks": 0,
		"buffs": [],
		"equipment": {},
	}
	var board := [
		[{"type": "SWORD"}, {"type": "SKULL", "hp": 15, "enemy_id": "goblin_01"}],
	]
	var path := [Vector2i(0, 0), Vector2i(1, 0)]
	var result := TurnResolver.resolve_player_action(
		board, stats, stats, path, GameState.get_config()
	)
	assert(result.defeated_enemies.size() == 1)


func _test_buff_consumption() -> void:
	var stats := {
		"attack": 10,
		"hp": 50,
		"max_hp": 50,
		"armor": 5,
		"max_armor": 5,
		"gold": 0,
		"xp": 0,
		"level": 1,
		"class_id": "warrior",
		"abilities": [],
		"poison_stacks": 0,
		"buffs": [{"id": "double_attack", "duration_turns": 1}],
		"equipment": {},
	}
	var board := [
		[{"type": "SWORD"}, {"type": "SWORD"}],
	]
	var path := [Vector2i(0, 0), Vector2i(1, 0)]
	var result := TurnResolver.resolve_player_action(
		board, stats, stats, path, GameState.get_config()
	)
	assert(result.player_stats.buffs.is_empty())


func _test_poison_tick() -> void:
	var stats := {
		"attack": 10,
		"hp": 50,
		"max_hp": 50,
		"armor": 5,
		"max_armor": 5,
		"gold": 0,
		"xp": 0,
		"level": 1,
		"class_id": "warrior",
		"abilities": [],
		"poison_stacks": 2,
		"buffs": [],
		"equipment": {},
	}
	var result := TurnResolver.apply_poison_damage(stats)
	assert(result.player_stats.hp == 48)
	assert(result.player_stats.poison_stacks == 1)


func _test_activate_ability() -> void:
	var board := [
		[{"type": "SKULL", "hp": 10, "max_hp": 10}],
	]
	var stats := {
		"attack": 5,
		"hp": 40,
		"max_hp": 50,
		"armor": 5,
		"max_armor": 5,
		"abilities": [{"id": "minor_heal", "current_level": 1, "current_cooldown": 0}],
		"equipment": {},
	}
	var result := TurnResolver.activate_ability("minor_heal", board, stats)
	assert(result.success)
	assert(result.player_stats.hp > 40)
