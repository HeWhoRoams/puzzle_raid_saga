extends HBoxContainer

signal ability_pressed(ability_id: StringName)

var _cooldowns := {}
var _buttons: Array[Button] = []
var _ability_to_button: Dictionary = {}
var _ability_labels: Dictionary = {}
var _slot_abilities: Array[String] = []
var _active_abilities: Array[String] = []


func _ready() -> void:
	_buttons = [
		%AbilityButton1,
		%AbilityButton2,
		%AbilityButton3,
		%AbilityButton4,
	]
	_slot_abilities.resize(_buttons.size())
	for i in range(_buttons.size()):
		_slot_abilities[i] = ""
		var button := _buttons[i]
		button.visible = false
		button.text = ""
		var slot_index := i
		button.pressed.connect(func(): _on_button_pressed(slot_index))


func _trigger_ability(id: String) -> void:
	if _cooldowns.get(id, 0) > 0:
		print("%s is on cooldown (%d)" % [id, _cooldowns[id]])
		return
	ability_pressed.emit(StringName(id))


func set_cooldown(id: String, turns: int) -> void:
	_cooldowns[id] = max(turns, 0)
	_update_button(id)


func reduce_cooldowns() -> void:
	for id in _active_abilities:
		if _cooldowns.get(id, 0) > 0:
			_cooldowns[id] = max(0, _cooldowns[id] - 1)
			_update_button(id)


func reset_cooldowns() -> void:
	for id in _cooldowns.keys():
		_cooldowns[id] = 0
	_update_all_buttons()


func set_active_abilities(list: Array[String]) -> void:
	_active_abilities = list.duplicate(true)
	_ability_to_button.clear()
	_ability_labels.clear()
	for button in _buttons:
		button.visible = false
	for i in range(_slot_abilities.size()):
		_slot_abilities[i] = ""
	for i in range(min(_active_abilities.size(), _buttons.size())):
		var ability_id := _active_abilities[i]
		var def := GameState.get_ability_definition(ability_id)
		var button: Button = _buttons[i]
		var label: String
		if def == null:
			push_warning("AbilityBar: Missing ability definition for '%s'" % ability_id)
			label = ability_id
		else:
			label = def.get("label", ability_id)
		button.visible = true
		button.text = label
		_slot_abilities[i] = ability_id
		_ability_to_button[ability_id] = button
		_ability_labels[ability_id] = label
		if not _cooldowns.has(ability_id):
			_cooldowns[ability_id] = 0
	_update_all_buttons()


func _update_button(id: String) -> void:
	var button: Button = _ability_to_button.get(id)
	if button == null:
		return
	var turns := _cooldowns.get(id, 0)
	var label := _ability_labels.get(id, id)
	if turns <= 0:
		button.text = label
		button.disabled = false
	else:
		button.text = "%s (%d)" % [label, turns]
		button.disabled = true


func _update_all_buttons() -> void:
	for ability_id in _active_abilities:
		_update_button(ability_id)


func _on_button_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slot_abilities.size():
		return
	var ability_id := _slot_abilities[slot_index]
	if ability_id.is_empty():
		return
	_trigger_ability(ability_id)
