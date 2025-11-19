extends Control

signal start_run_pressed(selected_class: String)

const CLASS_CARD_SCENE: PackedScene = preload("res://scenes/ui/ClassCard.tscn")

@onready var _grid: GridContainer = %ClassGrid
@onready var _start_button: Button = %StartRunButton

var _selected_class_id := ""


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_clear_placeholder()
	_populate_classes()
	_start_button.disabled = _selected_class_id.is_empty()
	_highlight_selection()


func _clear_placeholder() -> void:
	for child in _grid.get_children():
		if not child.visible:
			child.queue_free()


func _populate_classes() -> void:
	for class_id in GameState.class_definitions.keys():
		if not GameState.is_class_unlocked(class_id):
			continue
		var def := GameState.get_class_definition(class_id)
		if def == null or not def is Dictionary:
			continue
		var card: Control = CLASS_CARD_SCENE.instantiate()
		card.set_meta("class_id", class_id)
		if card.has_method("set_title"):
			card.set_title(def.get("name", class_id.capitalize()))
		if card.has_method("set_description"):
			card.set_description(def.get("description", ""))
		if card.has_signal("pressed"):
			card.connect("pressed", Callable(self, "_on_class_card_pressed").bind(class_id))
		else:
			card.gui_input.connect(
				Callable(self, "_on_class_card_gui_input").bind(class_id)
			)
		_grid.add_child(card)


func _on_class_card_pressed(class_id: String) -> void:
	_selected_class_id = class_id
	_start_button.disabled = _selected_class_id.is_empty()
	_highlight_selection()


func _highlight_selection() -> void:
	for child in _grid.get_children():
		var is_selected: bool = child.get_meta("class_id", "") == _selected_class_id
		if child.has_method("set_selected"):
			child.set_selected(is_selected)
		else:
			child.modulate = Color(1, 1, 1, 1) if is_selected else Color(0.75, 0.75, 0.75, 1)


func _on_start_pressed() -> void:
	if _selected_class_id.is_empty():
		return
	start_run_pressed.emit(_selected_class_id)
	SceneManager.change_scene(SceneManager.SCENE_GAME_BOARD, {"class_id": _selected_class_id})


func _on_class_card_gui_input(event: InputEvent, class_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_class_card_pressed(class_id)


func _receive_data(_data := {}) -> void:
	if _data is Dictionary and _data.has("class_id"):
		_selected_class_id = str(_data.get("class_id", ""))
		if is_instance_valid(_start_button):
			_start_button.disabled = _selected_class_id.is_empty()
			_highlight_selection()
