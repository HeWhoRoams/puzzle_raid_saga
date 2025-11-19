extends Node

const SCENE_MAIN_MENU := "res://scenes/ui/MainMenu.tscn"
const SCENE_CLASS_SELECT := "res://scenes/ui/ClassSelect.tscn"
const SCENE_GAME_BOARD := "res://scenes/ui/GameBoard.tscn"
const SCENE_RUN_SUMMARY := "res://scenes/ui/RunSummary.tscn"
const SCENE_SETTINGS := "res://scenes/ui/Settings.tscn"
const SCENE_UNLOCK_STORE := "res://scenes/ui/UnlockStore.tscn"

var current_scene: Node = null
var scene_data: Dictionary = {}
var _current_path: String = ""


func change_scene(path: String, data: Dictionary = {}) -> void:
	scene_data = data.duplicate(true)
	_current_path = path
	if is_instance_valid(current_scene):
		current_scene.free()

	var err = ResourceLoader.load_threaded_request(path)
	if err != OK:
		push_error("SceneManager: Failed to request load for %s: %s" % [path, err])
		return

	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame

	var packed = ResourceLoader.load_threaded_get(path)
	if packed == null:
		push_error("SceneManager: Failed to load %s" % path)
		return

	current_scene = packed.instantiate()
	if current_scene == null:
		push_error("SceneManager: Failed to instantiate %s" % path)
		return
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene

	if current_scene.has_method("_receive_data"):
		current_scene.call("_receive_data", scene_data)


func reload() -> void:
	if _current_path.is_empty():
		return
	change_scene(_current_path, scene_data)


func get_data() -> Dictionary:
	return scene_data.duplicate(true)
