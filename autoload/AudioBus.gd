extends Node
class_name AudioBus

var _music_player := AudioStreamPlayer.new()
var _sfx_player := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(_music_player)
	add_child(_sfx_player)
	_music_player.bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
	_sfx_player.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"

func play_music(stream_path: String, loop := true) -> void:
	var stream := _load_stream(stream_path)
	if stream == null:
		return
	_music_player.stop()
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func play_sfx(stream_path: String) -> void:
	var stream := _load_stream(stream_path)
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()

func play_named_sfx(name: String) -> void:
	# Placeholder mapping, to be wired with actual assets.
	print_debug("AudioBus: play sfx ", name)

func play_named_music(name: String) -> void:
	print_debug("AudioBus: play music ", name)

func _load_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	var stream := ResourceLoader.load(path)
	if not (stream is AudioStream):
		push_warning("AudioBus: missing or invalid audio stream at %s" % path)
		return null
	return stream
