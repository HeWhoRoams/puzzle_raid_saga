extends Control

signal new_run_requested
signal continue_run_requested
signal run_history_requested
signal clear_save_requested
signal clear_history_requested

@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	%NewRunButton.pressed.connect(_on_new_run_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	%HistoryButton.pressed.connect(_on_history_pressed)
	%ClearSaveButton.pressed.connect(_on_clear_save_pressed)
	%ClearHistoryButton.pressed.connect(_on_clear_history_pressed)


func set_has_saved_run(has_saved: bool) -> void:
	continue_button.disabled = not has_saved
	if not has_saved:
		set_status("No saved run found.")
	else:
		set_status("")


func set_status(text: String) -> void:
	status_label.text = text


func _on_new_run_pressed() -> void:
	new_run_requested.emit()


func _on_continue_pressed() -> void:
	continue_run_requested.emit()


func _on_history_pressed() -> void:
	run_history_requested.emit()


func _on_clear_save_pressed() -> void:
	clear_save_requested.emit()


func _on_clear_history_pressed() -> void:
	clear_history_requested.emit()
