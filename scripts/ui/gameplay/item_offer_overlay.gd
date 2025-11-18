extends ColorRect

signal offer_selected(index: int)
signal offers_skipped

@onready var offers_container: VBoxContainer = %Offers

var _offers: Array = []


func _ready() -> void:
	%SkipButton.pressed.connect(_on_skip)


func set_offers(offers: Array) -> void:
	_offers = offers
	visible = not _offers.is_empty()
	_refresh_offers()


func _refresh_offers() -> void:
	for child in offers_container.get_children():
		child.queue_free()

	for index in range(_offers.size()):
		var offer: Dictionary = _offers[index]
		var panel := PanelContainer.new()
		var vbox := VBoxContainer.new()
		vbox.theme_override_constants.separation = 4
		panel.add_child(vbox)

		var title := Label.new()
		title.text = tr(offer.get("name", "Mystery Item"))
		title.theme_override_font_sizes.font_size = 18
		vbox.add_child(title)

		var icon := TextureRect.new()
		icon.texture = _load_icon(offer.get("icon_path", ""))
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		vbox.add_child(icon)

		var desc := Label.new()
		desc.text = tr(offer.get("description", ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(desc)

		var modifiers: Dictionary = offer.get("modifiers", {})
		if not modifiers.is_empty():
			var mods_label := Label.new()
			mods_label.text = "Mods: %s" % _format_modifiers(modifiers)
			mods_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(mods_label)

		var cost_label := Label.new()
		var cost: int = offer.get("cost", 0)
		if cost > 0:
			cost_label.text = "Cost: %d gold" % cost
		else:
			cost_label.text = "Cost: Free"
		vbox.add_child(cost_label)

		var button := Button.new()
		button.text = "Select"
		var offer_index := index
		button.pressed.connect(func(): offer_selected.emit(offer_index))
		vbox.add_child(button)

		offers_container.add_child(panel)


func _on_skip() -> void:
	offers_skipped.emit()


func _load_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var tex := ResourceLoader.load(path)
	return tex if tex is Texture2D else null


func _format_modifiers(modifiers: Dictionary) -> String:
	var parts: Array[String] = []
	for key in modifiers.keys():
		var value = modifiers[key]
		var label := str(key).capitalize().replace("_", " ")
		parts.append("%s %+s" % [label, value])
	return ", ".join(parts)
