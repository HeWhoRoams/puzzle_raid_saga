extends Control

signal purchase_requested
signal back_pressed
var _return_scene_path := SceneManager.SCENE_MAIN_MENU
var _return_scene_data: Dictionary = {}

@onready var _purchase_button: Button = %PurchaseButton
@onready var _back_button: Button = %BackButton

var purchase_price := 4.99:
	set(value):
		purchase_price = value
		_update_purchase_label()


func _ready() -> void:
	_update_purchase_label()
	_purchase_button.pressed.connect(_on_purchase_pressed)
	_back_button.pressed.connect(_on_back_pressed)


func _update_purchase_label() -> void:
	if not is_instance_valid(_purchase_button):
		return
	_purchase_button.text = "Unlock - $%.2f" % purchase_price


func _receive_data(data := {}) -> void:
	if data is Dictionary:
		if data.has("price"):
			var price_value = data["price"]
			if price_value is float or price_value is int:
				purchase_price = float(price_value)
			elif price_value is String:
				purchase_price = float(price_value) if price_value.is_valid_float() else purchase_price
			else:
				push_warning("Invalid price type in _receive_data: %s" % typeof(price_value))
		var return_scene = data.get("return_scene", SceneManager.SCENE_MAIN_MENU)
		_return_scene_path = return_scene if return_scene is String else SceneManager.SCENE_MAIN_MENU
		var return_data = data.get("return_data", {})
		_return_scene_data = return_data if return_data is Dictionary else {}
	else:
		push_warning("Invalid data type passed to _receive_data: expected Dictionary")
		_return_scene_path = SceneManager.SCENE_MAIN_MENU
		_return_scene_data = {}


func _on_purchase_pressed() -> void:
	purchase_requested.emit()


func _on_back_pressed() -> void:
	back_pressed.emit()
	call_deferred("_deferred_change_scene")


func _deferred_change_scene() -> void:
	SceneManager.change_scene(_return_scene_path, _return_scene_data)
