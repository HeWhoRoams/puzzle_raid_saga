extends PanelContainer

@export var max_entries := 200

@onready var _label: RichTextLabel = %LogLabel


func add_entry(text: String) -> void:
	if text.is_empty():
		return
	_label.append_text(text + "\n")
	_trim_if_needed()
	_label.scroll_to_line(_label.get_line_count())


func set_entries(entries: Array) -> void:
	_label.clear()
	for entry in entries:
		add_entry(str(entry))


func clear() -> void:
	_label.clear()


func _trim_if_needed() -> void:
	var count := _label.get_line_count()
	if count <= max_entries:
		return
	var remove_count := count - max_entries
	var text := _label.text
	var lines := text.split("\n")
	lines = lines.slice(remove_count, lines.size())
	_label.text = "\n".join(lines)
