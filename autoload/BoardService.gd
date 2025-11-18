extends Node

## Handles board creation, tile validation, and refill logic.

const TILE_SWORD := &"SWORD"
const TILE_SKULL := &"SKULL"
const TILE_SHIELD := &"SHIELD"
const TILE_POTION := &"POTION"
const TILE_COIN := &"COIN"

var _rng := RandomNumberGenerator.new()
var _config: GameConfigResource
var _difficulty: DifficultyDefinitionResource
var _board: Array = []
var _current_depth := 1


func configure(config: GameConfigResource, difficulty_id: StringName = &"Normal") -> void:
	if config == null:
		push_error("BoardService: Config is null.")
		return
	_config = config
	_rng.randomize()
	_difficulty = ContentDB.get_difficulty(difficulty_id) if difficulty_id != StringName() else null
	if _difficulty == null and config.difficulties.size() > 0:
		_difficulty = config.difficulties[0]
	if _difficulty == null:
		push_error("BoardService: No difficulty definition available.")


func regenerate_board(depth: int = 1) -> void:
	if _config == null:
		push_error("BoardService: configure must be called before regenerating the board.")
		return
	_current_depth = depth
	_board = []
	for row in range(_config.board_size):
		var row_data: Array = []
		for col in range(_config.board_size):
			row_data.append(_create_new_tile(depth))
		_board.append(row_data)


func get_board() -> Array:
	return _duplicate_board(_board)


func set_board(new_board: Array, depth: int) -> void:
	_board = _duplicate_board(new_board)
	_current_depth = depth


func get_depth() -> int:
	return _current_depth


func get_difficulty() -> DifficultyDefinitionResource:
	return _difficulty


func duplicate_board(board: Array) -> Array:
	return _duplicate_board(board)


func validate_path(board: Array, path: Array, min_length: int) -> Dictionary:
	var failure := {"valid": false, "reason": "invalid_path"}
	if path.is_empty():
		return failure
	if path.size() < min_length:
		return {"valid": false, "reason": "Path too short."}

	var visited: Dictionary = {}

	if not _is_inside_board(board, path[0]):
		return failure

	var start_tile: Dictionary = board[path[0].y][path[0].x]
	if start_tile == null:
		return failure

	var base_type: StringName = start_tile.get("type", TILE_SWORD)
	var attack_path := base_type == TILE_SWORD or base_type == TILE_SKULL

	for index in range(path.size()):
		var pos: Vector2i = path[index]
		if not _is_inside_board(board, pos):
			return {"valid": false, "reason": "Path left the board."}
		var tile = board[pos.y][pos.x]
		if tile == null:
			return failure
		if visited.has(pos):
			return {"valid": false, "reason": "Path revisited a tile."}
		visited[pos] = true

		if index > 0:
			var prev: Vector2i = path[index - 1]
			if not _is_adjacent(prev, pos):
				return {"valid": false, "reason": "Path is not adjacent."}

		if attack_path:
			var tile_type: StringName = tile.get("type", TILE_SWORD)
			if tile_type != TILE_SWORD and tile_type != TILE_SKULL:
				return {"valid": false, "reason": "Attack chain hit invalid tile."}
		elif tile.get("type") != base_type:
			return {"valid": false, "reason": "Chain mixed incompatible tiles."}

	return {"valid": true, "path_type": base_type, "is_attack_path": attack_path}


func is_attack_path(path_type: StringName) -> bool:
	return path_type == TILE_SWORD or path_type == TILE_SKULL


func apply_gravity_and_refill(board: Array, depth: int) -> Array:
	var size := _config.board_size
	var new_board := _duplicate_board(board)

	for col in range(size):
		var write_row := size - 1
		for read_row in range(size - 1, -1, -1):
			if new_board[read_row][col] != null:
				if write_row != read_row:
					new_board[write_row][col] = new_board[read_row][col]
					new_board[read_row][col] = null
				write_row -= 1

	for row in range(size):
		for col in range(size):
			if new_board[row][col] == null:
				new_board[row][col] = _create_new_tile(depth)

	return new_board


func remove_tiles(board: Array, positions: Array) -> void:
	for pos in positions:
		if pos.y >= 0 and pos.y < board.size():
			var row: Array = board[pos.y]
			if pos.x >= 0 and pos.x < row.size():
				row[pos.x] = null


func next_tile_id() -> String:
	return "%s_%s" % [Time.get_ticks_usec(), _rng.randi()]


func _create_new_tile(depth: int) -> Dictionary:
	var tile_def := _pick_weighted_tile()
	if tile_def == null:
		return {}
	if tile_def.tile_type == TILE_SKULL:
		var enemy_def := _select_enemy_for_spawn(depth)
		if enemy_def:
			return _create_skull_tile(enemy_def)
		return {"id": next_tile_id(), "type": TILE_SWORD}
	return {"id": next_tile_id(), "type": tile_def.tile_type, "is_new": true}


func _create_skull_tile(enemy_def: EnemyDefinitionResource) -> Dictionary:
	var multiplier := _difficulty.stat_multiplier if _difficulty else 1.0
	var hp := int(ceil(enemy_def.base_hp * multiplier))
	var atk := int(ceil(enemy_def.base_attack * multiplier))
	return {
		"id": next_tile_id(),
		"type": TILE_SKULL,
		"enemy_id": enemy_def.content_id,
		"name": enemy_def.display_name,
		"hp": hp,
		"max_hp": hp,
		"attack": atk,
		"armor": enemy_def.base_armor,
		"traits": enemy_def.traits.duplicate(true),
		"is_new": true,
	}


func _pick_weighted_tile() -> TileDefinitionResource:
	var total := 0.0
	for def in _config.tile_types:
		total += def.weight
	var roll := _rng.randf_range(0, total)
	for def in _config.tile_types:
		if roll <= def.weight:
			return def
		roll -= def.weight
	return null if _config.tile_types.is_empty() else _config.tile_types[0]


func _select_enemy_for_spawn(depth: int) -> EnemyDefinitionResource:
	var eligible: Array[EnemyDefinitionResource] = []
	for enemy in _config.enemies:
		if depth >= enemy.min_depth and depth <= enemy.max_depth:
			eligible.append(enemy)
	if eligible.is_empty():
		return null
	var total := 0.0
	for enemy in eligible:
		var modifier := 1.0
		if _difficulty and enemy.min_depth > 0:
			modifier = _difficulty.special_enemy_spawn_modifier
		total += enemy.rarity * modifier
	var roll := _rng.randf_range(0, total)
	for enemy in eligible:
		var modifier := 1.0
		if _difficulty and enemy.min_depth > 0:
			modifier = _difficulty.special_enemy_spawn_modifier
		var effective_rarity := enemy.rarity * modifier
		if roll <= effective_rarity:
			return enemy
		roll -= effective_rarity
	return eligible[0]


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var diff := a - b
	return abs(diff.x) <= 1 and abs(diff.y) <= 1 and (diff.x != 0 or diff.y != 0)


func _duplicate_board(board: Array) -> Array:
	var copy: Array = []
	for row in board:
		copy.append(row.duplicate(true))
	return copy


func _is_inside_board(board: Array, pos: Vector2i) -> bool:
	if pos.y < 0 or pos.y >= board.size():
		return false
	var row: Array = board[pos.y]
	return pos.x >= 0 and pos.x < row.size()
