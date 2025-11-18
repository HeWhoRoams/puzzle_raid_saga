extends Control

signal path_committed(path: Array[Vector2i])

@export var tile_scene: PackedScene

@onready var tiles_layer: Control = %TilesLayer

var _board: Array = []
var _tile_nodes: Dictionary = {}
var _current_path: Array[Vector2i] = []
var _dragging := false
var _tile_size := 0.0
var _grid_origin := Vector2.ZERO
var min_path_length := 3


func set_board(board: Array) -> void:
	_board = board
	_build_tiles()
	_layout_tiles()


func set_min_path_length(value: int) -> void:
	min_path_length = value


func reset_selection() -> void:
	_current_path.clear()
	_dragging = false
	_update_highlights()


func _build_tiles() -> void:
	for child in tiles_layer.get_children():
		child.queue_free()
	_tile_nodes.clear()

	for row_idx in range(_board.size()):
		var row: Array = _board[row_idx]
		for col_idx in range(row.size()):
			var tile_data = row[col_idx]
			if tile_data == null:
				continue
			var tile_view: Control = tile_scene.instantiate()
			tiles_layer.add_child(tile_view)
			if tile_view.has_method("configure"):
				tile_view.configure(tile_data, Vector2i(col_idx, row_idx))
			_tile_nodes[Vector2i(col_idx, row_idx)] = tile_view


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_tiles()


func _layout_tiles() -> void:
	if _board.is_empty():
		return
	var control_size: Vector2 = size
	var usable_size: float = min(control_size.x, control_size.y)
	if is_zero_approx(usable_size):
		return
	var board_size: int = _board.size()
	_tile_size = usable_size / board_size
	var offset: Vector2 = (control_size - Vector2(usable_size, usable_size)) * 0.5
	_grid_origin = offset

	for pos in _tile_nodes.keys():
		var tile_view: Control = _tile_nodes[pos]
		var pixel_pos: Vector2 = offset + Vector2(pos.x, pos.y) * _tile_size
		tile_view.position = pixel_pos
		tile_view.size = Vector2(_tile_size, _tile_size)


func _gui_input(event: InputEvent) -> void:
	if _board.is_empty():
		return

	var position: Vector2
	var handled := false

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		position = event.position
		var cell := _point_to_cell(position)
		if event.pressed:
			_start_path(cell)
		else:
			_finish_path()
		handled = true
	elif event is InputEventMouseMotion and _dragging:
		position = event.position
		var cell := _point_to_cell(position)
		_extend_path(cell)
		handled = true
	elif event is InputEventScreenTouch:
		position = _screen_point_to_local(event.position)
		var cell := _point_to_cell(position)
		if event.pressed:
			_start_path(cell)
		else:
			_finish_path()
		handled = true
	elif event is InputEventScreenDrag and _dragging:
		position = _screen_point_to_local(event.position)
		var cell := _point_to_cell(position)
		_extend_path(cell)
		handled = true

	if handled:
		accept_event()


func _point_to_cell(point: Vector2) -> Vector2i:
	if _tile_size <= 0:
		return Vector2i(-1, -1)
	var local := point - _grid_origin
	var col := int(floor(local.x / _tile_size))
	var row := int(floor(local.y / _tile_size))
	return Vector2i(col, row)


func _is_cell_valid(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0:
		return false
	if cell.y >= _board.size():
		return false
	var row: Array = _board[cell.y]
	if cell.x >= row.size():
		return false
	return row[cell.x] != null


func _start_path(cell: Vector2i) -> void:
	if not _is_cell_valid(cell):
		return
	_current_path = [cell]
	_dragging = true
	_update_highlights()


func _extend_path(cell: Vector2i) -> void:
	if not _dragging:
		return
	if not _is_cell_valid(cell):
		return
	if _current_path.is_empty():
		return
	var last: Vector2i = _current_path.back()
	if cell == last:
		return
	if _current_path.size() > 1 and cell == _current_path[_current_path.size() - 2]:
		_current_path.pop_back()
		_update_highlights()
		return
	if _current_path.has(cell):
		return
	if not _is_adjacent(last, cell):
		return
	if not _is_tile_compatible(cell):
		return
	_current_path.append(cell)
	_update_highlights()


func _finish_path() -> void:
	if not _dragging:
		return
	_dragging = false
	if _current_path.size() >= min_path_length:
		path_committed.emit(_current_path.duplicate())
	_current_path.clear()
	_update_highlights()


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var diff := a - b
	return abs(diff.x) <= 1 and abs(diff.y) <= 1 and (diff.x != 0 or diff.y != 0)


func _is_tile_compatible(cell: Vector2i) -> bool:
	if _current_path.is_empty():
		return true
	var start_tile: Dictionary = _board[_current_path[0].y][_current_path[0].x]
	var base_type := str(start_tile.get("type"))
	var current_tile: Dictionary = _board[cell.y][cell.x]
	var tile_type := str(current_tile.get("type"))
	var attack_path := base_type == "SWORD" or base_type == "SKULL"
	if attack_path:
		return tile_type == "SWORD" or tile_type == "SKULL"
	return tile_type == base_type


func _update_highlights() -> void:
	for pos in _tile_nodes.keys():
		var tile_view: Control = _tile_nodes[pos]
		if tile_view.has_method("set_selected"):
			tile_view.set_selected(_current_path.has(pos))


func _screen_point_to_local(point: Vector2) -> Vector2:
	var inv := get_global_transform_with_canvas().affine_inverse()
	return inv * point
