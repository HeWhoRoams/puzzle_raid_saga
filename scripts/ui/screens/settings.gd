extends Control

signal close_requested
signal audio_settings_changed(music: float, sfx: float)
signal gameplay_settings_changed(vibration_enabled: bool, hints_enabled: bool)
signal unlock_store_requested
var _return_scene_path := SceneManager.SCENE_MAIN_MENU
var _return_scene_data: Dictionary = {}

@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _vibration_toggle: CheckBox = %VibrationToggle
@onready var _hint_toggle: CheckBox = %HintToggle
@onready var _close_button: Button = %CloseButton
@onready var _unlock_button: Button = %UnlockStoreButton

var music_volume := 0.5:
	set(value):
		music_volume = clamp(value, 0.0, 1.0)
		if is_instance_valid(_music_slider):
			_music_slider.value = music_volume
var sfx_volume := 0.5:
	set(value):
		sfx_volume = clamp(value, 0.0, 1.0)
		if is_instance_valid(_sfx_slider):
			_sfx_slider.value = sfx_volume
var vibration_enabled := true:
	set(value):
		vibration_enabled = value
		if is_instance_valid(_vibration_toggle):
			_vibration_toggle.button_pressed = vibration_enabled
var hints_enabled := true:
	set(value):
		hints_enabled = value
		if is_instance_valid(_hint_toggle):
			_hint_toggle.button_pressed = hints_enabled


func _ready() -> void:
	_music_slider.value = music_volume
	_sfx_slider.value = sfx_volume
	_vibration_toggle.button_pressed = vibration_enabled
	_hint_toggle.button_pressed = hints_enabled
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_vibration_toggle.toggled.connect(_on_vibration_toggled)
	_hint_toggle.toggled.connect(_on_hint_toggled)
	_close_button.pressed.connect(_on_close_pressed)
	_unlock_button.pressed.connect(_on_unlock_pressed)


func _on_music_changed(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	audio_settings_changed.emit(music_volume, sfx_volume)


func _on_sfx_changed(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	audio_settings_changed.emit(music_volume, sfx_volume)


func _on_vibration_toggled(pressed: bool) -> void:
	vibration_enabled = pressed
	gameplay_settings_changed.emit(vibration_enabled, hints_enabled)


func _on_hint_toggled(pressed: bool) -> void:
	hints_enabled = pressed
	gameplay_settings_changed.emit(vibration_enabled, hints_enabled)


func _receive_data(data := {}) -> void:
	if data is Dictionary:
		_return_scene_path = str(data.get("return_scene", SceneManager.SCENE_MAIN_MENU))
		_return_scene_data = data.get("return_data", {})
	else:
		_return_scene_path = SceneManager.SCENE_MAIN_MENU
		_return_scene_data = {}


func _on_close_pressed() -> void:
	close_requested.emit()
	SceneManager.change_scene(_return_scene_path, _return_scene_data)


func _on_unlock_pressed() -> void:
	unlock_store_requested.emit()
	SceneManager.change_scene(
		SceneManager.SCENE_UNLOCK_STORE,
		{
			"return_scene": SceneManager.SCENE_SETTINGS,
			"return_data": {
				"return_scene": _return_scene_path,
				"return_data": _return_scene_data,
			},
		}
	)
