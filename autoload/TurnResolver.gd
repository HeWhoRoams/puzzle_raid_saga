extends Node
class_name TurnResolver

## Handles turn resolution, including player chains and enemy counter-attacks.

var _config: GameConfigResource

const TILE_SWORD := BoardService.TILE_SWORD
const TILE_SKULL := BoardService.TILE_SKULL
const TILE_SHIELD := BoardService.TILE_SHIELD
const TILE_POTION := BoardService.TILE_POTION
const TILE_COIN := BoardService.TILE_COIN

func configure(config: GameConfigResource) -> void:
	_config = config

func resolve_player_action(board: Array, base_stats: Dictionary, path: Array[Vector2i]) -> Dictionary:
	var new_board := BoardService.duplicate_board(board)
	var player_stats := StatBlock.duplicate(base_stats)
	var logs: Array[String] = []
	var defeated_enemies: Array = []
	var removal_positions: Array[Vector2i] = path.duplicate()

	var validation := BoardService.validate_path(new_board, path, _config.min_path_length)
	if not validation.get("valid", false):
		return {
			"valid": false,
			"reason": validation.get("reason", "invalid"),
			"board": new_board,
			"player_stats": player_stats,
			"logs": logs,
			"defeated_enemies": defeated_enemies,
		}

	var path_type: StringName = validation["path_type"]
	var chain_length := path.size()
	var chain_multiplier := _get_chain_multiplier(chain_length)
	var effective_stats := StatBlock.apply_equipment(player_stats, _config)

	match path_type:
		TILE_SWORD, TILE_SKULL:
			_resolve_attack_chain(new_board, path, player_stats, effective_stats, chain_length, chain_multiplier, logs, defeated_enemies)
		TILE_SHIELD:
			_resolve_shield_chain(player_stats, effective_stats, chain_length, chain_multiplier, logs)
		TILE_POTION:
			_resolve_potion_chain(player_stats, effective_stats, chain_length, chain_multiplier, logs)
		TILE_COIN:
			_resolve_coin_chain(player_stats, effective_stats, chain_length, chain_multiplier, logs)

	if BoardService.is_attack_path(path_type):
		for row_idx in range(new_board.size()):
			for col_idx in range(new_board[row_idx].size()):
				var tile = new_board[row_idx][col_idx]
				if tile and tile.get("type") == TILE_SKULL and tile.get("hp", 1) <= 0:
					var pos := Vector2i(col_idx, row_idx)
					if not removal_positions.has(pos):
						removal_positions.append(pos)

	return {
		"valid": true,
		"board": new_board,
		"player_stats": player_stats,
		"logs": logs,
		"defeated_enemies": defeated_enemies,
		"path_type": path_type,
		"removed_positions": removal_positions,
	}

func resolve_enemy_pre_attacks(board: Array) -> Dictionary:
	var new_board := BoardService.duplicate_board(board)
	var logs: Array[String] = []
	var healer_tiles: Array = []

	for row in new_board:
		for tile in row:
			if tile and tile.get("type") == TILE_SKULL:
				var traits: Array = tile.get("traits", [])
				if "HEAL_ALLIES" in traits:
					healer_tiles.append(tile)

	if healer_tiles.is_empty():
		return {"board": new_board, "logs": logs}

	var heal_amount := 5 * healer_tiles.size()
	var total_healed := 0
	for row in new_board:
		for tile in row:
			if tile and tile.get("type") == TILE_SKULL:
				var hp := tile.get("hp", 0)
				var max_hp := tile.get("max_hp", hp)
				var delta := min(heal_amount, max_hp - hp)
				if delta > 0:
					tile["hp"] = hp + delta
					total_healed += delta

	if total_healed > 0:
		logs.append("[color=lightgreen]Enemy shamans heal their allies![/color]")
	return {"board": new_board, "logs": logs}

func resolve_enemy_attacks(board: Array, base_stats: Dictionary, effective_stats: Dictionary, path: Array[Vector2i]) -> Dictionary:
	var new_player := StatBlock.duplicate(base_stats)
	var logs: Array[String] = []
	var total_armor_damage := 0
	var total_health_damage := 0
	var total_pierce := 0
	var poison_stacks := new_player.get("poison_stacks", 0)

	var path_lookup := {}
	for pos in path:
		path_lookup[pos] = true

	for row_idx in range(board.size()):
		for col_idx in range(board[row_idx].size()):
			var tile = board[row_idx][col_idx]
			if tile == null:
				continue
			if tile.get("type") != TILE_SKULL:
				continue
			if tile.get("hp", 1) <= 0:
				continue
			var tile_pos := Vector2i(col_idx, row_idx)
			if path_lookup.has(tile_pos):
				continue
			var attack_value := tile.get("attack", 0)
			if attack_value <= 0:
				continue

			var traits: Array = tile.get("traits", [])
			if "ARMOR_PIERCING" in traits:
				total_pierce += attack_value
			else:
				var mitigated := max(1, attack_value - effective_stats.get("armor", 0))
				total_health_damage += mitigated
			if "POISON" in traits:
				poison_stacks += 1
		}

	if total_pierce > 0:
		new_player["hp"] -= total_pierce
		logs.append("[color=violet]Armor-piercing attacks deal %s direct damage![/color]" % total_pierce)

	if total_health_damage > 0:
		var armor_damage := min(new_player.get("armor", 0), total_health_damage)
		new_player["armor"] = max(0, new_player.get("armor", 0) - armor_damage)
		var remaining := total_health_damage - armor_damage
		if remaining > 0:
			new_player["hp"] -= remaining
		total_armor_damage = armor_damage
		logs.append("Enemies attack! [color=orange]%s[/color] damage, [color=lightblue]%s[/color] armor lost." % [remaining, armor_damage])

	new_player["poison_stacks"] = poison_stacks
	return {"player_stats": new_player, "logs": logs}

func tick_down_cooldowns_and_buffs(player_stats: Dictionary) -> Dictionary:
	var new_player := StatBlock.duplicate(player_stats)
	var logs: Array[String] = []

	if new_player.has("abilities"):
		for ability in new_player["abilities"]:
			var cooldown := ability.get("current_cooldown", 0)
			if cooldown > 0:
				ability["current_cooldown"] = max(0, cooldown - 1)

	if new_player.has("buffs"):
		var buffs: Array = new_player["buffs"]
		for i in range(buffs.size() - 1, -1, -1):
			var buff := buffs[i]
			var duration_key := "duration_turns" if buff.has("duration_turns") else "durationTurns"
			var duration := buff.get(duration_key, 0) - 1
			if duration <= 0:
				buffs.remove_at(i)
				logs.append("Buff %s has expired." % buff.get("id", "?"))
			else:
				buff[duration_key] = duration

	return {"player_stats": new_player, "logs": logs}

func resolve_level_ups(player_stats: Dictionary, class_id: StringName) -> Dictionary:
	var new_player := StatBlock.duplicate(player_stats)
	var logs: Array[String] = []
	var leveled_up := false

	var class_def := ContentDB.get_class(class_id)
	if class_def == null:
		return {"player_stats": new_player, "logs": logs, "leveled_up": false}

	while new_player.get("xp", 0) >= _xp_required_for_level(new_player.get("level", 1)):
		var xp_needed := _xp_required_for_level(new_player["level"])
		new_player["xp"] -= xp_needed
		new_player["level"] += 1
		leveled_up = true

		var gains := class_def.stat_growth
		new_player["max_hp"] = new_player.get("max_hp", 0) + gains.get("max_hp", 0)
		new_player["max_armor"] = new_player.get("max_armor", 0) + gains.get("max_armor", 0)
		new_player["attack"] = new_player.get("attack", 0) + gains.get("attack", 0)
		new_player["hp"] = new_player["max_hp"]
		new_player["armor"] = new_player["max_armor"]
		new_player["poison_stacks"] = 0

		logs.append("[color=cyan]LEVEL UP! You reached level %s.[/color]" % new_player["level"])

	return {"player_stats": new_player, "logs": logs, "leveled_up": leveled_up}

func apply_poison_damage(player_stats: Dictionary) -> Dictionary:
	var new_player := StatBlock.duplicate(player_stats)
	var stacks := new_player.get("poison_stacks", 0)
	var logs: Array[String] = []
	if stacks > 0:
		new_player["hp"] -= stacks
		new_player["poison_stacks"] = max(0, stacks - 1)
		logs.append("[color=lightgreen]Poison deals %s damage.[/color]" % stacks)
	return {"player_stats": new_player, "logs": logs}

func _resolve_attack_chain(board: Array, path: Array[Vector2i], base_stats: Dictionary, effective_stats: Dictionary, chain_length: int, chain_multiplier: float, logs: Array, defeated_enemies: Array) -> void:
	var buffs: Array = base_stats.get("buffs", [])
	var attack_multiplier := 1.0
	for i in range(buffs.size() - 1, -1, -1):
		var buff := buffs[i]
		if buff.get("id") == "double_attack":
			attack_multiplier *= 2.0
			buffs.remove_at(i)
			logs.append("[color=yellow]BERSERK! Attack is doubled![/color]")
			break

	var total_damage := int(floor(effective_stats.get("attack", 0) * chain_length * chain_multiplier * attack_multiplier))
	if total_damage <= 0:
		return

	var skull_targets: Array = []
	for pos in path:
		var tile = board[pos.y][pos.x]
		if tile.get("type") == TILE_SKULL:
			skull_targets.append({"pos": pos, "tile": tile})

	if skull_targets.is_empty():
		logs.append("You swing but hit nothing.")
		return

	logs.append("You attack for [color=red]%s[/color] total damage." % total_damage)
	var remaining_damage := total_damage
	for target in skull_targets:
		if remaining_damage <= 0:
			break
		var tile: Dictionary = target["tile"]
		var hp := tile.get("hp", 0)
		var damage_to_tile := min(remaining_damage, hp)
		tile["hp"] = hp - damage_to_tile
		remaining_damage -= damage_to_tile

		if tile["hp"] <= 0:
			var enemy_def := ContentDB.get_enemy(tile.get("enemy_id", ""))
			if enemy_def:
				defeated_enemies.append(enemy_def)
			logs.append("You defeated %s." % tr(enemy_def.display_name))
		else:
			logs.append("%s takes [color=red]%s[/color] damage." % [tile.get("name", "Enemy"), damage_to_tile])

func _resolve_shield_chain(player_stats: Dictionary, effective_stats: Dictionary, length: int, multiplier: float, logs: Array) -> void:
	var gain := int(floor(5 * length * multiplier))
	player_stats["armor"] = min(effective_stats.get("max_armor", player_stats.get("max_armor", 0)), player_stats.get("armor", 0) + gain)
	logs.append("You repaired [color=lightblue]%s[/color] armor." % gain)

func _resolve_potion_chain(player_stats: Dictionary, effective_stats: Dictionary, length: int, multiplier: float, logs: Array) -> void:
	var heal := int(floor(10 * length * multiplier))
	player_stats["hp"] = min(effective_stats.get("max_hp", player_stats.get("max_hp", 0)), player_stats.get("hp", 0) + heal)
	logs.append("You healed for [color=green]%s[/color] HP." % heal)

func _resolve_coin_chain(player_stats: Dictionary, effective_stats: Dictionary, length: int, multiplier: float, logs: Array) -> void:
	var gold_multiplier := effective_stats.get("gold_multiplier", 1.0)
	var buffs: Array = player_stats.get("buffs", [])
	for i in range(buffs.size() - 1, -1, -1):
		var buff := buffs[i]
		if buff.get("id") == "double_gold":
			gold_multiplier *= 2.0
			buffs.remove_at(i)
			logs.append("[color=yellow]GOLD RUSH! Coins are doubled![/color]")
			break

	var gold_gained := int(floor(length * multiplier * gold_multiplier))
	player_stats["gold"] = player_stats.get("gold", 0) + gold_gained
	logs.append("You collect [color=yellow]%s[/color] gold." % gold_gained)

func _get_chain_multiplier(length: int) -> float:
	var multiplier := 1.0
	for bonus in _config.chain_bonuses:
		if length >= bonus.length:
			multiplier = bonus.multiplier
	return multiplier

func _xp_required_for_level(level: int) -> int:
	var progression := _config.level_progression
	return int(floor(progression.base_xp * pow(progression.xp_multiplier, level - 1)))

func activate_ability(ability_id: StringName, board: Array, player_stats: Dictionary) -> Dictionary:
	var new_board := BoardService.duplicate_board(board)
	var new_player := StatBlock.duplicate(player_stats)
	var logs: Array[String] = []

	var player_ability: Dictionary
	for ability in new_player.get("abilities", []):
		if ability.get("id") == ability_id:
			player_ability = ability
			break

	if player_ability == null:
		return {"success": false, "reason": "ability_not_owned"}

	if player_ability.get("current_cooldown", player_ability.get("currentCooldown", 0)) > 0:
		return {"success": false, "reason": "ability_on_cooldown"}

	var ability_def := ContentDB.get_ability(ability_id)
	if ability_def == null:
		return {"success": false, "reason": "ability_not_found"}

	logs.append("You used %s." % tr(ability_def.display_name))

	var effect: Dictionary = ability_def.effect
	match effect.get("type", ""):
		"HEAL":
			var amount := effect.get("amount", 0)
			var healed := min(amount, new_player.get("max_hp", new_player.get("maxHp", 0)) - new_player.get("hp", 0))
			new_player["hp"] = new_player.get("hp", 0) + healed
			logs.append("You heal for %d HP." % healed)
		"DAMAGE_ALL_SKULLS":
			var damage := effect.get("amount", 0)
			_apply_damage_to_all_skulls(new_board, damage, logs)
		"APPLY_BUFF":
			var buff_id := effect.get("buffId", "")
			var duration := effect.get("duration", 1)
			var buffs: Array = new_player.get("buffs", [])
			if not new_player.has("buffs"):
				new_player["buffs"] = buffs
			buffs.append({"id": buff_id, "duration_turns": duration})
			logs.append("Buff %s applied for %d turns." % [buff_id, duration])
		"CONVERT_TILES":
			_convert_tiles(new_board, effect.get("from", ""), effect.get("to", ""))
			logs.append("Tiles converted.")
		"SHIELD_EXPLOSION":
			var base_amount := effect.get("baseAmount", 0)
			var armor := new_player.get("armor", 0)
			new_player["armor"] = 0
			var total := base_amount + armor
			_apply_damage_to_all_skulls(new_board, total, logs, true)
		_:
			return {"success": false, "reason": "effect_not_supported"}

	var ability_level := player_ability.get("current_level", player_ability.get("currentLevel", 1))
	var cooldown := ability_def.base_cooldown - (ability_def.cooldown_reduction_per_level * (ability_level - 1))
	player_ability["current_cooldown"] = max(0, cooldown)

	return {"success": true, "board": new_board, "player_stats": new_player, "logs": logs}

func _apply_damage_to_all_skulls(board: Array, damage: int, logs: Array, consumes_armor := false) -> void:
	if damage <= 0:
		return
	var defeated := 0
	for row in board:
		for tile in row:
			if tile and tile.get("type") == TILE_SKULL:
				var hp := tile.get("hp", 0)
				if hp <= 0:
					continue
				tile["hp"] = max(0, hp - damage)
				if tile["hp"] == 0:
					defeated += 1
	if defeated > 0:
		logs.append("%d enemies are destroyed." % defeated)
	if consumes_armor:
		logs.append("Your armor detonates dealing %d damage." % damage)

func _convert_tiles(board: Array, from_type: String, to_type: String) -> void:
	if from_type.is_empty() or to_type.is_empty():
		return
	for row in board:
		for tile in row:
			if tile and tile.get("type") == from_type:
				tile["type"] = to_type
				if to_type != TILE_SKULL:
					for key in ["hp", "max_hp", "attack", "armor", "enemy_id", "name", "traits"]:
						if tile.has(key):
							tile.erase(key)
