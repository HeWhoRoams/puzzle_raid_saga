extends Control

signal new_game_pressed
signal continue_pressed
signal scores_pressed

var _background_texture: Texture2D

@export var background_texture: Texture2D:
	set(value):
		_background_texture = value
		_update_background_texture()
	get:
		return _background_texture

@onready var _background: TextureRect = %Background
@onready var _new_game_button: Button = %NewGameButton
@onready var _continue_button: Button = %ContinueButton
@onready var _scores_button: Button = %ScoresButton


func _ready() -> void:
	_update_background_texture()
	_new_game_button.pressed.connect(func():
		new_game_pressed.emit()
	)
	_continue_button.pressed.connect(func():
		continue_pressed.emit()
	)
	_scores_button.pressed.connect(func():
		scores_pressed.emit()
	)


func set_continue_enabled(enabled: bool) -> void:
	_continue_button.disabled = not enabled


func _update_background_texture() -> void:
	if is_instance_valid(_background):
		_background.texture = _background_texture
