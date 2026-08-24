extends Node

const Catalog = preload("res://scripts/audio/sfx_catalog.gd")
const POOL_SIZE := 12
const CROSSFADE_DEFAULT := 0.8

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _crossfade_time := 0.0
var _crossfade_duration := 0.0
var _fading := false
var master_volume := 1.0
var sfx_volume := 1.0
var music_volume := 0.6

func _ready() -> void:
	_build_sfx_pool()
	_build_music_players()

func _build_sfx_pool() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SfxPool%d" % i
		p.bus = &"Master"
		add_child(p)
		_sfx_players.append(p)

func _build_music_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.name = "MusicA"
	_music_a.bus = &"Master"
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.name = "MusicB"
	_music_b.bus = &"Master"
	add_child(_music_b)

func play_sfx(sound_id: String, volume_db: float = -5.0, pitch_variance: float = 0.04) -> void:
	var stream = Catalog.stream_for(sound_id)
	if stream == null:
		return
	_play_stream(stream, volume_db, pitch_variance)

func play_stream(stream: AudioStream, volume_db: float = -5.0, pitch_variance: float = 0.04) -> void:
	if stream == null:
		return
	_play_stream(stream, volume_db, pitch_variance)

func _play_stream(stream: AudioStream, volume_db: float, pitch_variance: float) -> void:
	if _sfx_players.is_empty():
		return
	var player := _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	if pitch_variance > 0.0:
		player.pitch_scale = 1.0 - pitch_variance + randf() * pitch_variance * 2.0
	else:
		player.pitch_scale = 1.0
	player.play()

func play_music(track: String, crossfade: float = CROSSFADE_DEFAULT) -> void:
	var stream = Catalog.music_for(track)
	if stream == null:
		return
	_start_music(stream, crossfade)

func _start_music(stream: AudioStream, crossfade: float) -> void:
	if _music_a.playing:
		_music_b.stream = stream
		_music_b.volume_db = -80.0
		_music_b.play()
		_crossfade_duration = maxf(crossfade, 0.05)
		_crossfade_time = 0.0
		_fading = true
	else:
		_music_a.stream = stream
		_music_a.volume_db = linear_to_db(music_volume * master_volume)
		_music_a.play()

func stop_music(fade_out: float = 0.5) -> void:
	if fade_out <= 0.0:
		_music_a.stop()
		_music_b.stop()
		_fading = false
		return
	_music_b.stream = null
	_crossfade_duration = fade_out
	_crossfade_time = 0.0
	_fading = true

func _process(delta: float) -> void:
	if not _fading:
		return
	_crossfade_time += delta
	var t := clampf(_crossfade_time / _crossfade_duration, 0.0, 1.0)
	var target_db := linear_to_db(music_volume * master_volume)
	_music_a.volume_db = target_db + linear_to_db(maxf(1.0 - t, 0.001))
	if _music_b.playing:
		_music_b.volume_db = target_db + linear_to_db(maxf(t, 0.001))
	if t >= 1.0:
		_fading = false
		_music_a.stop()
		var tmp := _music_a
		_music_a = _music_b
		_music_b = tmp

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	if _music_a.playing and not _fading:
		_music_a.volume_db = linear_to_db(music_volume * master_volume)
