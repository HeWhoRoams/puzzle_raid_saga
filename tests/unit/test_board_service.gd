extends SceneTree

func _init() -> void:
	GameState.ensure_initialized()
	_test_valid_path()
	_test_invalid_path_diagonal()
	_test_invalid_path_mixed()
	print("BoardService path tests passed.")
	quit()

func _test_valid_path() -> void:
	var board := [
		[{"type": "SWORD"}, {"type": "SWORD"}],
	]
	var path := [Vector2i(0, 0), Vector2i(1, 0)]
	var result := BoardService.validate_path(board, path, 2)
	assert(result.valid)

func _test_invalid_path_diagonal() -> void:
	var board := [
		[{"type": "SWORD"}, null],
		[null, {"type": "SWORD"}],
	]
	var path := [Vector2i(0, 0), Vector2i(1, 1)]
	var result := BoardService.validate_path(board, path, 2)
	assert(not result.valid)

func _test_invalid_path_mixed() -> void:
	var board := [
		[{"type": "SWORD"}, {"type": "POTION"}],
	]
	var path := [Vector2i(0, 0), Vector2i(1, 0)]
	var result := BoardService.validate_path(board, path, 2)
	assert(not result.valid)
