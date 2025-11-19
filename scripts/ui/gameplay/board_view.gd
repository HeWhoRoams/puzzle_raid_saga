extends Control

signal path_committed(path: Array[Vector2i])

@export var board_width := 6: set = _set_board_width
@export var board_height := 6
@export var tile_scene: PackedScene

@onready var tile_grid: GridContainer = %TileGrid

var _board: Array = []
var _tile_nodes: Dictionary = {}
var _is_dragging := false
var _current_type := ""
var _current_chain_tiles: Array[Control] = []
var _current_chain_cells: Array[Vector2i] = []
var min_path_length := 3


func _ready() -> void:
	set_process_unhandled_input(true)
	tile_grid.columns = board_width
	tile_grid.add_theme_constant_override("h_separation", 4)
	tile_grid.add_theme_constant_override("v_separation", 4)


func _set_board_width(value: int) -> void:
	board_width = value
	if tile_grid:
		tile_grid.columns = value
		tile_grid.queue_redraw()


func set_board(board: Array) -> void:
	_board = board
	_build_tiles()
	_clear_chain()


func generate_new_board(board: Array) -> void:
	_board = board
	_build_tiles()
	_clear_chain()


func set_min_path_length(value: int) -> void:
	min_path_length = value


func reset_selection() -> void:
	_clear_chain()


func _build_tiles() -> void:
	for child in tile_grid.get_children():
		child.queue_free()
	_tile_nodes.clear()

	for row_idx in range(_board.size()):
		var row: Array = _board[row_idx]
		for col_idx in range(row.size()):
			var tile_data = row[col_idx]
			if tile_data == null:
				continue
			var tile_view: Control = tile_scene.instantiate()
			tile_grid.add_child(tile_view)
			if tile_view.has_method("configure"):
				tile_view.configure(tile_data, Vector2i(col_idx, row_idx))
			if tile_view.has_signal("tile_pressed"):
				tile_view.tile_pressed.connect(_on_tile_pressed)
			if tile_view.has_signal("tile_dragged"):
				tile_view.tile_dragged.connect(_on_tile_dragged)
			_tile_nodes[Vector2i(col_idx, row_idx)] = tile_view


func _on_tile_pressed(tile: Control) -> void:
	if tile == null:
		return
	_start_chain(tile)


func _on_tile_dragged(tile: Control) -> void:
	if not _is_dragging or tile == null:
		return
	_update_chain(tile)


func _start_chain(tile: Control) -> void:
	_clear_chain()
	var tile_type := str(tile.get("tile_type", ""))
	if tile_type.is_empty():
		return
	_is_dragging = true
	_current_type = tile_type
	_current_chain_tiles.append(tile)
	_highlight_tile(tile)
	var pos := Vector2i(int(tile.get("grid_x", 0)), int(tile.get("grid_y", 0)))
	_current_chain_cells.append(pos)


func _update_chain(tile: Control) -> void:
	if not _is_dragging:
		return
	var tile_type := str(tile.get("tile_type", ""))
	if tile_type != _current_type:
		return

	if _current_chain_tiles.size() > 1:
		var last_tile: Control = _current_chain_tiles.back()
		var prev_tile: Control = _current_chain_tiles[_current_chain_tiles.size() - 2]
		if tile == prev_tile:
			# backtrack
			_unhighlight_tile(last_tile)
			_current_chain_tiles.pop_back()
			_current_chain_cells.pop_back()
			return

	if tile in _current_chain_tiles:
		return

	var last := _current_chain_tiles.back()
	if not _tiles_are_adjacent(last, tile):
		return

	_current_chain_tiles.append(tile)
	var pos := Vector2i(int(tile.get("grid_x", 0)), int(tile.get("grid_y", 0)))
	_current_chain_cells.append(pos)
	_highlight_tile(tile)


func _tiles_are_adjacent(a: Control, b: Control) -> bool:
	var diff_x := abs(int(a.get("grid_x", 0)) - int(b.get("grid_x", 0)))
	var diff_y := abs(int(a.get("grid_y", 0)) - int(b.get("grid_y", 0)))
	return diff_x + diff_y == 1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag()
	elif event is InputEventScreenTouch and not event.pressed:
		_end_drag()


func _end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	if _current_chain_cells.size() >= min_path_length:
		path_committed.emit(_current_chain_cells.duplicate())
	_clear_chain()


func _highlight_tile(tile: Control) -> void:
	if tile.has_method("highlight"):
		tile.highlight()


func _unhighlight_tile(tile: Control) -> void:
	if tile.has_method("unhighlight"):
		tile.unhighlight()


func _clear_chain() -> void:
	for tile in _current_chain_tiles:
		_unhighlight_tile(tile)
	_current_chain_tiles.clear()
	_current_chain_cells.clear()
	_current_type = ""
	_is_dragging = false
