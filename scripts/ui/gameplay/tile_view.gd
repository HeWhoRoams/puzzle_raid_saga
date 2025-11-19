extends Panel

signal tile_pressed(tile: Control)
signal tile_dragged(tile: Control)

const TYPE_COLORS := {
	"SWORD": Color(0.8, 0.25, 0.25),
	"SHIELD": Color(0.2, 0.4, 0.8),
	"POTION": Color(0.2, 0.6, 0.3),
	"COIN": Color(0.9, 0.8, 0.3),
	"XP": Color(0.7, 0.5, 0.9),
	"MASK": Color(0.2, 0.2, 0.2),
}
const TYPE_LABELS := {
	"SWORD": "S",
	"SHIELD": "D",
	"POTION": "P",
	"COIN": "C",
	"XP": "XP",
	"MASK": "M",
}

@export var grid_x: int = 0
@export var grid_y: int = 0
@export var tile_type: String = "SWORD"

@onready var type_label: Label = $Label

var tile_data: Dictionary = {}
var _is_selected := false


func configure(data: Dictionary, pos: Vector2i) -> void:
	tile_data = data
	grid_x = pos.x
	grid_y = pos.y
	tile_type = tile_data.get("type", "SWORD")
	_update_visuals()


func set_type(new_type: String) -> void:
	tile_type = new_type
	_update_visuals()


func highlight() -> void:
	_is_selected = true
	_update_visuals()


func unhighlight() -> void:
	_is_selected = false
	_update_visuals()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			tile_pressed.emit(self)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		tile_dragged.emit(self)
	elif event is InputEventScreenTouch:
		if event.pressed:
			tile_pressed.emit(self)
	elif event is InputEventScreenDrag:
		tile_dragged.emit(self)


func _update_visuals() -> void:
	var color: Color = TYPE_COLORS.get(tile_type, Color(0.3, 0.3, 0.35))
	if _is_selected:
		color = color.lightened(0.3)
	modulate = color
	type_label.text = TYPE_LABELS.get(tile_type, tile_type.left(2))
