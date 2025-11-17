extends SceneTree

func _init() -> void:
	GameState.ensure_initialized()
	SaveService.clear_active_run()
	var classes := GameState.get_config().classes
	GameState.start_new_run(classes[0].content_id)
	var board_before := GameState.get_board_snapshot()
	var stats_before := GameState.get_player_stats_snapshot()
	GameState.suspend_run_to_menu()
	var resumed := GameState.continue_saved_run()
	assert(resumed)
	var board_after := GameState.get_board_snapshot()
	var stats_after := GameState.get_player_stats_snapshot()
	assert(board_before.hash() == board_after.hash())
	assert(stats_before.get("hp") == stats_after.get("hp"))
	print("Persistence round-trip test passed.")
	quit()
