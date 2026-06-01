extends Node

const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const BUS_UI := "UI"
const BUS_AMBIENCE := "Ambience"

var _music_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer


func _ready() -> void:
	_ensure_bus(BUS_SFX)
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_UI)
	_ensure_bus(BUS_AMBIENCE)

	_music_player = _create_persistent_player(BUS_MUSIC)
	_ui_player = _create_persistent_player(BUS_UI)
	_ambience_player = _create_persistent_player(BUS_AMBIENCE)


func play_sfx_2d(
	stream: AudioStream,
	position: Vector2,
	volume_db: float = 0.0,
	pitch_min: float = 1.0,
	pitch_max: float = 1.0,
	bus: StringName = BUS_SFX
) -> void:
	if stream == null:
		return

	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = bus
	player.top_level = true
	player.global_position = position
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	var parent := get_tree().current_scene if get_tree().current_scene != null else self
	parent.add_child(player)
	player.finished.connect(func() -> void:
		if is_instance_valid(player):
			player.queue_free()
	)
	player.play()


func play_ui(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	_play_stream_1d(_ui_player, stream, volume_db, pitch)


func play_music(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	_play_stream_1d(_music_player, stream, volume_db, pitch)


func play_ambience(stream: AudioStream, volume_db: float = -6.0, pitch: float = 1.0) -> void:
	_play_stream_1d(_ambience_player, stream, volume_db, pitch)


func stop_music() -> void:
	if _music_player:
		_music_player.stop()


func stop_ambience() -> void:
	if _ambience_player:
		_ambience_player.stop()


func _play_stream_1d(player: AudioStreamPlayer, stream: AudioStream, volume_db: float, pitch: float) -> void:
	if player == null or stream == null:
		return
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


func _create_persistent_player(bus_name: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player


func _ensure_bus(bus_name: String) -> void:
	for i in range(AudioServer.get_bus_count()):
		if AudioServer.get_bus_name(i) == bus_name:
			return

	AudioServer.add_bus(AudioServer.get_bus_count())
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")
