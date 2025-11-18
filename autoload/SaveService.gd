extends Node

const SAVE_ROOT := "user://saves"
const ACTIVE_RUN_PATH := SAVE_ROOT + "/active_run.save"
const RUN_HISTORY_PATH := SAVE_ROOT + "/run_history.save"


func ensure_directories() -> void:
	if DirAccess.dir_exists_absolute(SAVE_ROOT):
		return
	var err := DirAccess.make_dir_recursive_absolute(SAVE_ROOT)
	if err != OK:
		push_error("Failed to create save directory: %s" % SAVE_ROOT)


func save_active_run(payload: Dictionary) -> void:
	ensure_directories()
	var file := FileAccess.open(ACTIVE_RUN_PATH, FileAccess.WRITE)
	if file:
		file.store_var(payload, true)


func load_active_run() -> Dictionary:
	if not FileAccess.file_exists(ACTIVE_RUN_PATH):
		return {}
	var file := FileAccess.open(ACTIVE_RUN_PATH, FileAccess.READ)
	if file:
		return file.get_var(true)
	return {}


func clear_active_run() -> void:
	if FileAccess.file_exists(ACTIVE_RUN_PATH):
		DirAccess.remove_absolute(ACTIVE_RUN_PATH)


func save_run_history(entries: Array) -> void:
	ensure_directories()
	var file := FileAccess.open(RUN_HISTORY_PATH, FileAccess.WRITE)
	if file:
		file.store_var(entries, true)


func load_run_history() -> Array:
	if not FileAccess.file_exists(RUN_HISTORY_PATH):
		return []
	var file := FileAccess.open(RUN_HISTORY_PATH, FileAccess.READ)
	if file:
		return file.get_var(true)
	return []


func append_run_history(entry: Dictionary) -> void:
	var history := load_run_history()
	history.push_front(entry)
	if history.size() > 50:
		history = history.slice(0, 50)
	save_run_history(history)
