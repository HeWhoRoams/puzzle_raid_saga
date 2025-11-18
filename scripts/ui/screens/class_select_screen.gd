extends Control

signal class_selected(class_id: StringName)
signal back_requested

@onready var class_list: VBoxContainer = %ClassList
@onready var status_label: Label = %StatusLabel

var _classes: Array = []


func _ready() -> void:
	%BackButton.pressed.connect(_on_back_pressed)


func set_classes(classes: Array) -> void:
	_classes = classes
	_refresh_list()


func _refresh_list() -> void:
	for child in class_list.get_children():
		child.queue_free()

	for class_def in _classes:
		var button := Button.new()
		button.text = "%s\n%s" % [tr(class_def.display_name), tr(class_def.description)]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD
		var class_id: StringName = class_def.content_id
		button.pressed.connect(func(): class_selected.emit(class_id))
		class_list.add_child(button)


func set_status(text: String) -> void:
	status_label.text = text


func _on_back_pressed() -> void:
	back_requested.emit()
