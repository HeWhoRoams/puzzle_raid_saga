extends HBoxContainer

signal ability_pressed(ability_id: StringName)

var _abilities: Array = []


func set_abilities(abilities: Array) -> void:
	_abilities = abilities
	_refresh()


func _refresh() -> void:
	for child in get_children():
		child.queue_free()

	for ability in _abilities:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		card.theme_override_constants.separation = 4

		var def: AbilityDefinitionResource = ability.get("definition")
		var icon_texture := _load_icon(def.icon_path)
		if icon_texture:
			var icon := TextureRect.new()
			icon.texture = icon_texture
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(48, 48)
			card.add_child(icon)

		var label := Label.new()
		label.text = tr(def.display_name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		card.add_child(label)

		var button := Button.new()
		var cooldown: int = ability.get("current_cooldown", 0)
		var button_text := "Cooling (%d)" % cooldown if cooldown > 0 else "Activate"
		button.text = button_text
		button.disabled = cooldown > 0
		button.tooltip_text = tr(def.description)
		button.shortcut = _build_shortcut(card.get_child_count())
		var ability_id: StringName = ability.get("id", StringName())
		button.pressed.connect(func(): ability_pressed.emit(ability_id))
		card.add_child(button)

		add_child(card)


func _load_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var res := ResourceLoader.load(path)
	return res if res is Texture2D else null


func _build_shortcut(index: int) -> Shortcut:
	var shortcut := Shortcut.new()
	var ev := InputEventKey.new()
	ev.keycode = KEY_1 + index
	shortcut.events = [ev]
	return shortcut
