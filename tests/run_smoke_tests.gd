extends SceneTree

var _game_state: Node
var _board_service: Node


func _initialize() -> void:
	call_deferred("_run_smoke_tests")


func _run_smoke_tests() -> void:
	if not _cache_singletons():
		push_error("Required autoloads not found.")
		quit(1)
		return
	_game_state.ensure_initialized()
	var classes: Array = _game_state.get_config().classes
	if classes.is_empty():
		push_error("No classes defined for smoke test.")
		quit(1)
		return
	_game_state.start_new_run(classes[0].content_id)
	var success := _play_one_turn()
	if not success:
		push_error("Smoke test failed: no valid path found.")
		quit(1)
		return
	var abilities: Array = _game_state.get_player_abilities()
	if not abilities.is_empty():
		_game_state.activate_ability(abilities[0].get("id"))
	_game_state.suspend_run_to_menu()
	print("Smoke tests passed.")
	quit()


func _play_one_turn() -> bool:
	var attempts := 0
	while attempts < 5:
		var board: Array = _game_state.get_board_snapshot()
		var path := _find_valid_path(board, _game_state.get_config().min_path_length)
		if not path.is_empty():
			var result: Dictionary = _game_state.resolve_path(path)
			return result.get("success", false)
		_board_service.regenerate_board(1)
		attempts += 1
	return false


func _find_valid_path(board: Array, min_length: int) -> Array[Vector2i]:
	var size := board.size()
	for y in range(size):
		for x in range(board[y].size()):
			var tile: Dictionary = board[y][x]
			if tile == null:
				continue
			var base_type := str(tile.get("type"))
			var allowed := [base_type]
			if base_type == "SWORD" or base_type == "SKULL":
				allowed = ["SWORD", "SKULL"]
			var path := _search_from(board, Vector2i(x, y), allowed, min_length)
			if path.size() >= min_length:
				return path
	return _to_vector2i_path([])


func _search_from(
	board: Array, start: Vector2i, allowed: Array, min_length: int
) -> Array[Vector2i]:
	var stack: Array = [[start]]
	var visited := {}
	while not stack.is_empty():
		var current: Array = stack.pop_back()
		if current.size() >= min_length:
			return _to_vector2i_path(current)
		var last: Vector2i = current.back()
		for neighbor in _neighbors(last, board.size()):
			if current.has(neighbor):
				continue
			var tile: Dictionary = board[neighbor.y][neighbor.x]
			if tile == null:
				continue
			var tile_type := str(tile.get("type"))
			if not allowed.has(tile_type):
				continue
			var next_path: Array = current.duplicate()
			next_path.append(neighbor)
			stack.append(next_path)
	return _to_vector2i_path([])


func _neighbors(pos: Vector2i, size: int) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var np := Vector2i(pos.x + dx, pos.y + dy)
			if np.x >= 0 and np.y >= 0 and np.x < size and np.y < size:
				points.append(np)
	return points


func _cache_singletons() -> bool:
	var root_viewport := root
	if not root_viewport.has_node("GameState"):
		return false
	if not root_viewport.has_node("BoardService"):
		return false
	_game_state = root_viewport.get_node("GameState")
	_board_service = root_viewport.get_node("BoardService")
	return _game_state != null and _board_service != null


func _to_vector2i_path(source: Array) -> Array[Vector2i]:
	var converted: Array[Vector2i] = []
	for entry in source:
		converted.append(entry)
	return converted
