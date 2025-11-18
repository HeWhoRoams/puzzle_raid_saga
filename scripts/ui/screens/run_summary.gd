extends Control

signal retry_requested
signal class_select_requested

@onready var _depth_label: Label = %DepthLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _enemies_label: Label = %EnemiesLabel
@onready var _unlocks_label: Label = %UnlocksLabel
@onready var _retry_button: Button = %RetryButton
@onready var _class_select_button: Button = %ClassSelectButton


func _ready() -> void:
	_retry_button.pressed.connect(func(): retry_requested.emit())
	_class_select_button.pressed.connect(func(): class_select_requested.emit())


func set_summary(depth: int, gold: int, enemies: int, unlocks: Array) -> void:
	_depth_label.text = "Depth Reached: %d" % depth
	_gold_label.text = "Gold Collected: %d" % gold
	_enemies_label.text = "Enemies Defeated: %d" % enemies
	if unlocks.is_empty():
		_unlocks_label.text = "Unlocks: None"
	else:
		_unlocks_label.text = "Unlocks: %s" % ", ".join(unlocks)
