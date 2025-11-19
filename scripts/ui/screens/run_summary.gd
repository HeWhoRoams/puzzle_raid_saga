extends Control

signal retry_requested
signal class_select_requested

@onready var _depth_label: Label = %DepthLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _enemies_label: Label = %EnemiesLabel
@onready var _unlocks_label: Label = %UnlocksLabel
@onready var _retry_button: Button = %RetryButton
@onready var _class_select_button: Button = %ClassSelectButton

var _summary_payload: Dictionary = {}


func _ready() -> void:
	_retry_button.pressed.connect(_on_retry_pressed)
	_class_select_button.pressed.connect(_on_class_select_pressed)


func set_summary(depth: int, gold: int, enemies: int, unlocks: Array) -> void:
	_depth_label.text = "Depth Reached: %d" % depth
	_gold_label.text = "Gold Collected: %d" % gold
	_enemies_label.text = "Enemies Defeated: %d" % enemies
	if unlocks.is_empty():
		_unlocks_label.text = "Unlocks: None"
	else:
		_unlocks_label.text = "Unlocks: %s" % ", ".join(unlocks)


func _receive_data(data := {}) -> void:
	_summary_payload = data if data is Dictionary else {}
	var depth := int(_summary_payload.get("depth", 0))
	var gold := int(_summary_payload.get("gold", 0))
	var enemies := int(_summary_payload.get("enemies_defeated", 0))
	var unlocks: Array = _summary_payload.get("unlocks", [])
	set_summary(depth, gold, enemies, unlocks)


func _on_retry_pressed() -> void:
	var class_id := str(_summary_payload.get("class_id", ""))
	retry_requested.emit()
	SceneManager.change_scene(SceneManager.SCENE_GAME_BOARD, {"class_id": class_id})


func _on_class_select_pressed() -> void:
	class_select_requested.emit()
	SceneManager.change_scene(SceneManager.SCENE_CLASS_SELECT)
