extends Control
class_name MainShell

const ATTRACT_SCENE := preload("res://scenes/ui/AttractScreen.tscn")
const CLASS_SELECT_SCENE := preload("res://scenes/ui/ClassSelectScreen.tscn")
const GAMEPLAY_SCENE := preload("res://scenes/ui/GameplayShell.tscn")
const RUN_HISTORY_SCENE := preload("res://scenes/ui/RunHistoryScreen.tscn")

@onready var screen_root: Control = $"ScreenRoot"

var _current_screen: Control

func _ready() -> void:
	GameState.ensure_initialized()
	GameState.run_state_changed.connect(_on_state_changed)
	_swap_to_state(GameState.get_run_state())

func _on_state_changed(new_state: GameState.RunState) -> void:
	_swap_to_state(new_state)

func _swap_to_state(state: GameState.RunState) -> void:
	if _current_screen:
		_current_screen.queue_free()
		_current_screen = null

	var next_screen: Control
	match state:
		GameState.RunState.ATTRACT:
			next_screen = _create_attract_screen()
		GameState.RunState.CLASS_SELECT:
			next_screen = _create_class_selection_screen()
		GameState.RunState.GAMEPLAY:
			next_screen = _create_gameplay_screen(false, false)
		GameState.RunState.GAME_OVER:
			next_screen = _create_gameplay_screen(true, false)
		GameState.RunState.ITEM_OFFER:
			next_screen = _create_gameplay_screen(false, true)
		GameState.RunState.RUN_HISTORY:
			next_screen = _create_run_history_screen()
		default:
			next_screen = _build_placeholder("State %s not implemented." % state)

	if next_screen:
		screen_root.add_child(next_screen)
		_current_screen = next_screen

func _create_attract_screen() -> Control:
	var screen: Control = ATTRACT_SCENE.instantiate()
	screen.new_run_requested.connect(_on_new_run_requested)
	screen.continue_run_requested.connect(_on_continue_run_requested)
	screen.run_history_requested.connect(_on_run_history_requested)
	screen.clear_save_requested.connect(_on_clear_save_requested)
	screen.clear_history_requested.connect(_on_clear_history_requested)
	screen.set_has_saved_run(GameState.has_saved_run())
	return screen

func _create_class_selection_screen() -> Control:
	var screen: Control = CLASS_SELECT_SCENE.instantiate()
	screen.class_selected.connect(_on_class_selected)
	screen.back_requested.connect(_on_class_select_back)
	screen.set_classes(GameState.get_config().classes)
	return screen

func _create_gameplay_screen(is_game_over: bool, show_offers: bool) -> Control:
	var screen: Control = GAMEPLAY_SCENE.instantiate()
	screen.run_abandoned.connect(_on_abandon_run)
	screen.return_to_menu_requested.connect(_on_save_and_quit)
	screen.set_is_game_over(is_game_over)
	screen.set_show_item_offers(show_offers)
	screen.refresh_from_state()
	return screen

func _create_run_history_screen() -> Control:
	var screen: Control = RUN_HISTORY_SCENE.instantiate()
	screen.back_requested.connect(_on_history_back)
	screen.clear_requested.connect(_on_clear_history_requested)
	screen.set_history(GameState.get_run_history())
	return screen

func _build_placeholder(text: String) -> Control:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _on_new_run_requested() -> void:
	GameState.change_state(GameState.RunState.CLASS_SELECT)

func _on_continue_run_requested() -> void:
	if not GameState.continue_saved_run():
		push_warning("No saved run to continue.")
		if _current_screen and _current_screen.has_method("set_status"):
			_current_screen.set_status("Unable to load saved run.")
		else:
			_swap_to_state(GameState.RunState.ATTRACT)

func _on_class_selected(class_id: StringName) -> void:
	GameState.start_new_run(class_id)

func _on_class_select_back() -> void:
	GameState.change_state(GameState.RunState.ATTRACT)

func _on_run_history_requested() -> void:
	GameState.change_state(GameState.RunState.RUN_HISTORY)

func _on_history_back() -> void:
	GameState.change_state(GameState.RunState.ATTRACT)

func _on_clear_save_requested() -> void:
	GameState.abandon_run()
	_swap_to_state(GameState.RunState.ATTRACT)

func _on_clear_history_requested() -> void:
	SaveService.save_run_history([])
	if GameState.get_run_state() == GameState.RunState.RUN_HISTORY and _current_screen:
		if _current_screen.has_method("set_history"):
			_current_screen.set_history([])

func _on_abandon_run() -> void:
	GameState.abandon_run()

func _on_save_and_quit() -> void:
	GameState.suspend_run_to_menu()
