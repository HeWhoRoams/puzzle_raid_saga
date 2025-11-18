extends Control

signal purchase_requested
signal back_requested

@onready var _purchase_button: Button = %PurchaseButton
@onready var _back_button: Button = %BackButton

var purchase_price := 4.99:
	set(value):
		purchase_price = value
		_update_purchase_label()


func _ready() -> void:
	_update_purchase_label()
	_purchase_button.pressed.connect(func(): purchase_requested.emit())
	_back_button.pressed.connect(func(): back_requested.emit())


func _update_purchase_label() -> void:
	if not is_instance_valid(_purchase_button):
		return
	_purchase_button.text = "Unlock – $%.2f" % purchase_price
