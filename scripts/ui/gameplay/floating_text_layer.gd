extends Control

@export var lifetime := 1.0
@export var rise_distance := 50.0


func show_message(text: String, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = size * 0.5
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -rise_distance), lifetime)
	tween.parallel().tween_property(label, "modulate:a", 0.0, lifetime)
	tween.finished.connect(Callable(self, "_cleanup_label").bind(label))


func _cleanup_label(label: Label) -> void:
	if is_instance_valid(label):
		label.queue_free()
