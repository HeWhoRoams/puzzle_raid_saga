extends Control

signal play_pressed
signal settings_pressed
signal unlock_store_pressed

var _background_texture: Texture2D

@export var background_texture: Texture2D:
	set(value):
		_background_texture = value
		_update_background_texture()
	get:
		return _background_texture

@onready var _background: TextureRect = %Background
@onready var _play_button: Button = %PlayButton
@onready var _settings_button: Button = %SettingsButton
@onready var _unlock_button: Button = %UnlockButton


func _ready() -> void:
	_update_background_texture()
	_play_button.pressed.connect(_on_play_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_unlock_button.pressed.connect(_on_unlock_pressed)


func _receive_data(_data := {}) -> void:
	pass


func _update_background_texture() -> void:
	if is_instance_valid(_background):
		_background.texture = _background_texture


func _on_play_pressed() -> void:
	play_pressed.emit()
	SceneManager.change_scene(SceneManager.SCENE_CLASS_SELECT)


func _on_settings_pressed() -> void:
	settings_pressed.emit()
	SceneManager.change_scene(
		SceneManager.SCENE_SETTINGS, {"return_scene": SceneManager.SCENE_MAIN_MENU}
	)


func _on_unlock_pressed() -> void:
	unlock_store_pressed.emit()
	SceneManager.change_scene(
		SceneManager.SCENE_UNLOCK_STORE, {"return_scene": SceneManager.SCENE_MAIN_MENU}
	)
