extends Control

signal tab_changed(tab_index: int)
signal help_pressed
signal return_pressed

enum Tabs {
	CLASS,
	RACE,
	PERKS,
	SKILLS,
}

const CLASSES_FILE := "res://content/classes.json"
const RACES_FILE := "res://content/races.json"

@onready var _tab_buttons: Array = [
	%ClassTabButton,
	%RaceTabButton,
	%PerksTabButton,
	%SkillsTabButton,
]
@onready var _content_stack: VBoxContainer = %ContentStack
@onready var _context_title: Label = %ContextTitle
@onready var _context_body: RichTextLabel = %ContextBody
@onready var _class_title: Label = %ClassTitle
@onready var _class_stats_grid: GridContainer = %ClassStatsGrid
@onready var _class_description: RichTextLabel = %ClassDescription
@onready var _level_rewards: HBoxContainer = %LevelRewards
@onready var _race_title: Label = %RaceTitle
@onready var _race_description: RichTextLabel = %RaceDescription
@onready var _race_traits_list: ItemList = %RaceTraitsList
@onready var _perks_list: ItemList = %PerksList
@onready var _skills_grid: GridContainer = %SkillsGrid

var _context_defaults := [
	"Choose a class",
	"Choose a race",
	"Select perks & flaws",
	"Prepare your skills",
]

var _classes: Array = []
var _races: Dictionary = {}
var _active_class_index := 0


func _ready() -> void:
	_load_data_sources()
	for i in range(_tab_buttons.size()):
		var button: Button = _tab_buttons[i]
		button.toggle_mode = true
		button.pressed.connect(func(tab_index := i): _select_tab(tab_index))
	_select_tab(Tabs.CLASS)
	%HelpButton.pressed.connect(func(): help_pressed.emit())
	%ReturnButton.pressed.connect(func(): return_pressed.emit())
	_refresh_all_panels()


func _load_data_sources() -> void:
	_classes = _load_json_array(CLASSES_FILE, "classes")
	var race_array := _load_json_array(RACES_FILE, "races")
	for race in race_array:
		var race_id: String = race.get("id", "")
		if not race_id.is_empty():
			_races[race_id] = race


func _load_json_array(path: String, field: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	return parsed.get(field, [])


func _select_tab(index: int) -> void:
	for i in range(_tab_buttons.size()):
		var button: Button = _tab_buttons[i]
		button.button_pressed = i == index
	for child_index in range(_content_stack.get_child_count()):
		var child := _content_stack.get_child(child_index)
		child.visible = child_index == index
	_context_title.text = _tab_buttons[index].text
	_context_body.text = _context_defaults[index]
	tab_changed.emit(index)


func update_tab_context(tab_index: int, title: String, body: String) -> void:
	if tab_index < 0 or tab_index >= _tab_buttons.size():
		return
	_context_defaults[tab_index] = body
	if _tab_buttons[tab_index].button_pressed:
		_context_title.text = title
		_context_body.text = body


func set_tab_enabled(tab_index: int, enabled: bool) -> void:
	if tab_index < 0 or tab_index >= _tab_buttons.size():
		return
	_tab_buttons[tab_index].disabled = not enabled


func _refresh_all_panels() -> void:
	if _classes.is_empty():
		return
	_active_class_index = clampi(_active_class_index, 0, _classes.size() - 1)
	var class_data := _classes[_active_class_index]
	_populate_class_panel(class_data)
	_populate_race_panel(class_data)
	_populate_perks_panel(class_data)
	_populate_skills_panel(class_data)
	_update_context_from_class(class_data)


func _populate_class_panel(class_data: Dictionary) -> void:
	var title := (
		"%s (Level %d)"
		% [
			class_data.get("name", "Class"),
			class_data.get("level", 1),
		]
	)
	_class_title.text = title
	_class_description.text = class_data.get("description", "")
	_clear_children(_class_stats_grid)
	var stats: Dictionary = class_data.get("stats", {})
	for key in stats.keys():
		var name_label := Label.new()
		name_label.text = "%s:" % key
		_class_stats_grid.add_child(name_label)
		var value_label := Label.new()
		value_label.text = str(stats[key])
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_class_stats_grid.add_child(value_label)
	_clear_children(_level_rewards)
	for reward in class_data.get("level_rewards", []):
		var button := Button.new()
		button.text = "Lvl %s" % reward.get("level", "?")
		button.tooltip_text = reward.get("summary", "")
		button.disabled = true
		_level_rewards.add_child(button)


func _populate_race_panel(class_data: Dictionary) -> void:
	_race_traits_list.clear()
	var race_ids: Array = class_data.get("races", [])
	if race_ids.is_empty():
		_race_description.text = "No races available yet."
		return
	var race_id: String = race_ids[0]
	var race_data: Dictionary = _races.get(race_id, {})
	_race_title.text = race_data.get("name", "Race")
	_race_description.text = race_data.get("description", "")
	var traits: Array = race_data.get("traits", [])
	for trait_index in range(traits.size()):
		var trait: Dictionary = traits[trait_index]
		var name := trait.get("name", "Trait")
		var summary := trait.get("summary", "")
		_race_traits_list.add_item("%s: %s" % [name, summary])


func _populate_perks_panel(class_data: Dictionary) -> void:
	_perks_list.clear()
	for perk in class_data.get("perks", []):
		var entry := "%s: %s" % [perk.get("name", "Perk"), perk.get("summary", "")]
		var idx := _perks_list.add_item(entry)
		if perk.get("type", "perk") == "flaw":
			_perks_list.set_item_custom_fg_color(idx, Color(0.82, 0.23, 0.29))
		else:
			_perks_list.set_item_custom_fg_color(idx, Color(0.35, 0.78, 0.93))


func _populate_skills_panel(class_data: Dictionary) -> void:
	_clear_children(_skills_grid)
	for skill in class_data.get("skills", []):
		var slot := Button.new()
		slot.text = skill.get("name", "Skill")
		slot.tooltip_text = skill.get("summary", "")
		slot.disabled = true
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_skills_grid.add_child(slot)


func _update_context_from_class(class_data: Dictionary) -> void:
	_context_defaults[Tabs.CLASS] = class_data.get("description", "")
	var race_ids: Array = class_data.get("races", [])
	if not race_ids.is_empty():
		var race := _races.get(race_ids[0], {})
		_context_defaults[Tabs.RACE] = race.get("description", "")
	_context_defaults[Tabs.PERKS] = (
		"Review the perks and flaws granted by %s." % class_data.get("name", "this class")
	)
	_context_defaults[Tabs.SKILLS] = "These skills may appear as you level up."
	var current_index := _get_current_tab_index()
	if current_index != -1:
		_context_body.text = _context_defaults[current_index]


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func _get_current_tab_index() -> int:
	for i in range(_tab_buttons.size()):
		var button: Button = _tab_buttons[i]
		if button.button_pressed:
			return i
	return -1
