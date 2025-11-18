extends Control

signal menu_pressed
signal stats_pressed

@onready var board_view: Control = %BoardView
@onready var ability_bar: Control = %AbilityBar
@onready var menu_button: Button = %MenuButton
@onready var stats_button: Button = %StatsButton
@onready var description_title: Label = %DescriptionTitle
@onready var description_body: RichTextLabel = %DescriptionBody
@onready var coin_value_label: Label = %CoinValueLabel
@onready var coin_progress: ProgressBar = %CoinProgress
@onready var monster_stats_label: Label = %MonsterStatsLabel
@onready var shield_ratio_label: Label = %ShieldRatioLabel
@onready var attack_value_label: Label = %AttackValueLabel
@onready var gear_progress: ProgressBar = %GearProgress
@onready var xp_progress: ProgressBar = %XPProgress
@onready var health_label: Label = %HealthLabel
@onready var health_progress: ProgressBar = %HealthProgress


func _ready() -> void:
	menu_button.pressed.connect(func(): menu_pressed.emit())
	stats_button.pressed.connect(func(): stats_pressed.emit())


func get_board_view() -> Control:
	return board_view


func get_ability_bar() -> Control:
	return ability_bar


func set_description(title: String, body: String) -> void:
	description_title.text = title
	description_body.text = body


func set_coin_state(current: int, target: int) -> void:
	coin_value_label.text = str(current)
	var max_value: int = max(target, 1)
	coin_progress.max_value = max_value
	coin_progress.value = clampi(current, 0, max_value)


func set_monster_strength(strength: int) -> void:
	monster_stats_label.text = "Monster Str: %d" % strength


func set_shield_stats(current: int, maximum: int) -> void:
	shield_ratio_label.text = "Shield %d / %d" % [current, maximum]
	gear_progress.max_value = max(maximum, 1)
	gear_progress.value = clampi(current, 0, maximum)


func set_attack_value(value: int) -> void:
	attack_value_label.text = "ATK %d" % value


func set_xp_progress(current: int, required: int) -> void:
	xp_progress.max_value = max(required, 1)
	xp_progress.value = clampi(current, 0, required)


func set_health(current: int, max_value: int) -> void:
	var max_health: int = max(max_value, 1)
	health_label.text = "%d / %d" % [current, max_health]
	health_progress.max_value = max_health
	health_progress.value = clampi(current, 0, max_health)
