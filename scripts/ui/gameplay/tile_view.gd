extends Control

const TYPE_COLORS := {
	"SWORD": Color(0.8, 0.25, 0.25),
	"SKULL": Color(0.3, 0.3, 0.3),
	"SHIELD": Color(0.2, 0.4, 0.8),
	"POTION": Color(0.2, 0.6, 0.3),
	"COIN": Color(0.9, 0.8, 0.3),
}

@onready var background: ColorRect = %Background
@onready var type_label: Label = %TypeLabel
@onready var info_label: Label = %InfoLabel
@onready var intent_icon: TextureRect = %IntentIcon

var tile_data: Dictionary = {}
var grid_position: Vector2i = Vector2i.ZERO
var _is_selected := false


func configure(data: Dictionary, pos: Vector2i) -> void:
	tile_data = data
	grid_position = pos
	_update_visuals()


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_visuals()


func set_faded(faded: bool) -> void:
	modulate.a = 0.4 if faded else 1.0


func _update_visuals() -> void:
	if tile_data.is_empty():
		return
	var type_name: String = str(tile_data.get("type", "?"))
	type_label.text = type_name.left(1)

	var color: Color = TYPE_COLORS.get(type_name, Color(0.2, 0.2, 0.25))
	if _is_selected:
		color = color.lightened(0.3)
	background.color = color

	if type_name == "SKULL":
		var hp: int = tile_data.get("hp", 0)
		var max_hp: int = tile_data.get("max_hp", tile_data.get("maxHp", hp))
		info_label.text = "%s\n%s/%s" % [tile_data.get("name", "Skull"), hp, max_hp]
		_update_intent_icon(tile_data.get("traits", []))
	else:
		info_label.text = ""
		intent_icon.texture = null


func _update_intent_icon(traits: Array) -> void:
	if traits.is_empty():
		intent_icon.texture = null
		return
	var trait_id: String = traits[0]
	var path := "res://art/icons/traits/%s.png" % trait_id.to_lower()
	var tex := ResourceLoader.load(path)
	if tex is Texture2D:
		intent_icon.texture = tex
	else:
		intent_icon.texture = null
