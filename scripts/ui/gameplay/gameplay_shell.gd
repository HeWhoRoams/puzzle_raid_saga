extends Control

signal run_abandoned
signal return_to_menu_requested

@onready var game_board: Control = %GameBoard
@onready var board_view: Control = %BoardView
@onready var buff_container: HBoxContainer = %BuffContainer
@onready var log_label: RichTextLabel = %LogLabel
@onready var game_over_label: Label = %GameOverLabel
@onready var ability_bar: Control = %AbilityBar
@onready var item_offer_overlay: Control = %ItemOfferOverlay
@onready var floating_text_layer: Control = %FloatingTexts

var _is_game_over := false
var _show_item_offers := false


func _ready() -> void:
	board_view.path_committed.connect(_on_path_committed)
	%AbandonButton.pressed.connect(_on_abandon_pressed)
	%SaveQuitButton.pressed.connect(_on_save_quit_pressed)
	ability_bar.ability_pressed.connect(_on_ability_pressed)
	item_offer_overlay.offer_selected.connect(_on_offer_selected)
	item_offer_overlay.offers_skipped.connect(_on_offers_skipped)
	game_board.menu_pressed.connect(_on_save_quit_pressed)
	game_board.stats_pressed.connect(_on_stats_button_pressed)
	refresh_from_state()


func _unhandled_input(_event: InputEvent) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed("ui_save_run"):
		_on_save_quit_pressed()
	elif Input.is_action_just_pressed("ui_abandon_run"):
		_on_abandon_pressed()


func set_is_game_over(value: bool) -> void:
	_is_game_over = value
	_update_game_over_label()


func set_show_item_offers(value: bool) -> void:
	_show_item_offers = value
	_refresh_item_offers()


func refresh_from_state() -> void:
	if not is_instance_valid(board_view):
		return
	var board := GameState.get_board_snapshot()
	board_view.set_board(board)
	board_view.set_min_path_length(GameState.get_config().min_path_length)
	board_view.reset_selection()
	ability_bar.set_abilities(GameState.get_player_abilities())
	_update_stats()
	_update_log()
	_update_game_over_label()
	_refresh_item_offers()


func _update_stats() -> void:
	var stats: Dictionary = GameState.get_player_stats_snapshot()
	var selected_class = GameState.get_current_class_definition()
	var class_label := "Adventurer"
	var class_description := ""
	if selected_class:
		class_label = tr(selected_class.display_name)
		if selected_class.description != "":
			class_description = tr(selected_class.description)
	game_board.set_description(class_label, class_description)
	var depth: int = GameState.get_depth()
	game_board.set_monster_strength(depth)
	var gold: int = int(stats.get("gold", 0))
	var treasure_goal: int = int(stats.get("treasure_goal", 100))
	game_board.set_coin_state(gold, treasure_goal)
	var armor: int = int(stats.get("armor", 0))
	var max_armor: int = int(stats.get("max_armor", stats.get("maxArmor", 0)))
	game_board.set_shield_stats(armor, max_armor)
	var attack_value: int = int(stats.get("attack", 0))
	game_board.set_attack_value(attack_value)
	var xp_progress: Dictionary = GameState.get_xp_progress()
	var xp_current: int = int(xp_progress.get("current", 0))
	var xp_required: int = int(xp_progress.get("required", 1))
	game_board.set_xp_progress(xp_current, xp_required)
	var hp: int = int(stats.get("hp", 0))
	var max_hp: int = int(stats.get("max_hp", stats.get("maxHp", 0)))
	game_board.set_health(hp, max_hp)


func _update_log() -> void:
	var logs := GameState.get_log_snapshot()
	log_label.text = "\n".join(logs)
	log_label.scroll_to_line(log_label.get_line_count())


func _update_game_over_label() -> void:
	game_over_label.visible = _is_game_over
	game_over_label.text = "Game Over" if _is_game_over else ""
	%SaveQuitButton.disabled = _is_game_over
	%AbandonButton.disabled = _is_game_over
	ability_bar.visible = not _is_game_over


func _update_buffs(buffs: Array) -> void:
	if not is_instance_valid(buff_container):
		return
	for child in buff_container.get_children():
		child.queue_free()
	for buff in buffs:
		var badge := Label.new()
		badge.text = (
			"%s (%d)"
			% [buff.get("id", "buff"), buff.get("duration_turns", buff.get("durationTurns", 0))]
		)
		badge.add_theme_color_override("font_color", Color.YELLOW)
		badge.add_theme_font_size_override("font_size", 14)
		buff_container.add_child(badge)


func _on_path_committed(path: Array[Vector2i]) -> void:
	if _is_game_over:
		return
	var result := GameState.resolve_path(path)
	if not result.get("success", false):
		log_label.text = "Path invalid: %s" % result.get("reason", "unknown")
		return
	_is_game_over = result.get("game_over", false)
	refresh_from_state()
	_show_turn_feedback(result.get("logs", []))
	AudioBus.play_named_sfx("chain")


func _on_abandon_pressed() -> void:
	run_abandoned.emit()


func _on_save_quit_pressed() -> void:
	return_to_menu_requested.emit()


func _on_ability_pressed(ability_id: StringName) -> void:
	var result := GameState.activate_ability(ability_id)
	if not result.get("success", false):
		log_label.text = "Ability failed: %s" % result.get("reason", "unknown")
		return
	refresh_from_state()
	floating_text_layer.show_message("Ability!", Color.YELLOW)
	AudioBus.play_named_sfx("ability")


func _refresh_item_offers() -> void:
	if not is_instance_valid(item_offer_overlay):
		return
	if _show_item_offers:
		item_offer_overlay.set_offers(GameState.get_item_offers())
		ability_bar.visible = false
	else:
		item_offer_overlay.visible = false
		if not _is_game_over:
			ability_bar.visible = true


func _on_offer_selected(index: int) -> void:
	var result := GameState.purchase_item_offer(index)
	if not result.get("success", false):
		log_label.text = "Cannot take offer: %s" % result.get("reason", "unknown")
		return
	refresh_from_state()
	AudioBus.play_named_sfx("offer_pick")


func _on_offers_skipped() -> void:
	GameState.skip_item_offers()
	refresh_from_state()
	AudioBus.play_named_sfx("offer_skip")


func _show_turn_feedback(logs: Array) -> void:
	if logs.is_empty():
		return
	var last_log: String = str(logs.back())
	var sanitized: String = last_log.strip_edges()
	if sanitized.length() == 0:
		return
	floating_text_layer.show_message(sanitized)
	var stats: Dictionary = GameState.get_player_stats_snapshot()
	_update_buffs(stats.get("buffs", []))


func _on_stats_button_pressed() -> void:
	log_label.visible = not log_label.visible
