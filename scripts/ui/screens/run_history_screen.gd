extends Control

signal back_requested
signal clear_requested

@onready var history_list: VBoxContainer = %HistoryList

var _history: Array = []


func _ready() -> void:
	%BackButton.pressed.connect(_on_back_pressed)
	%ClearHistoryButton.pressed.connect(_on_clear_pressed)


func set_history(entries: Array) -> void:
	_history = entries
	_refresh_history()


func _refresh_history() -> void:
	for child in history_list.get_children():
		child.queue_free()

	if _history.is_empty():
		var label := Label.new()
		label.text = "No runs recorded yet. Go fight!"
		history_list.add_child(label)
		return

	for entry in _history:
		var panel := PanelContainer.new()
		var vbox := VBoxContainer.new()
		vbox.theme_override_constants.separation = 2
		panel.add_child(vbox)

		var header := Label.new()
		header.text = "%s — %s" % [tr(entry.get("class_name", "Unknown")), entry.get("date", "")]
		header.theme_override_font_sizes.font_size = 16
		vbox.add_child(header)

		var stats_label := Label.new()
		stats_label.text = (
			"Depth %d | Level %d | Score %d"
			% [
				entry.get("final_depth", 0),
				entry.get("final_level", 1),
				entry.get("score", 0),
			]
		)
		vbox.add_child(stats_label)

		history_list.add_child(panel)


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_clear_pressed() -> void:
	clear_requested.emit()
