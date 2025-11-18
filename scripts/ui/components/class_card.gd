extends Button

@export var title := "Class":
	set(value):
		title = value
		text = title

@export var selected_color := Color(1, 1, 1, 1)
@export var unselected_color := Color(0.75, 0.75, 0.75, 1)

var _is_selected := false


func _ready() -> void:
	text = title
	_update_style()


func set_title(value: String) -> void:
	title = value
	text = title


func set_selected(value: bool) -> void:
	_is_selected = value
	_update_style()


func _update_style() -> void:
	modulate = selected_color if _is_selected else unselected_color
