extends Node

## 사운드 카탈로그는 게임 모듈이 register_catalog() 로 주입한다 (core는 게임을 모른다).
var Catalog = null  # lint-gd: public-api

func register_catalog(catalog: Object) -> void:  # lint-gd: public-api
	# 스크립트 리소스면 인스턴스로 만든다. Script.call("stream_for") 는 웹에서 빈 값을 돌려 전체가 무음이 된다.
	if catalog is Script:
		Catalog = (catalog as Script).new()
	else:
		Catalog = catalog

const POOL_SIZE := 12  # lint-gd: public-api
const WORLD_POOL := 16  # lint-gd: public-api
const WORLD_MAX_DIST := 3200.0  # lint-gd: public-api
const CROSSFADE_DEFAULT := 0.8  # lint-gd: public-api

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _world_players: Array[AudioStreamPlayer2D] = []
var _world_cursor: int = 0
var _tide_voices: Dictionary = {}
var _world_host: Node2D
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _crossfade_time := 0.0
var _crossfade_duration := 0.0
var _fading := false
var master_volume := 1.0  # lint-gd: public-api
var sfx_volume := 1.0  # lint-gd: public-api
var music_volume := 0.28  # lint-gd: public-api
var _current_track := ""
var _lp: AudioEffectLowPassFilter
var _impact: AudioStreamPlayer
var _muffle_t := 0.0
var _muffle_dur := 0.0
var _muffling := false
var _unlock_cb = null

func _ready() -> void:
	_setup_world_bus()
	_build_sfx_pool()
	_build_world_pool()
	_build_music_players()
	get_tree().node_added.connect(_hook_button)
	_hook_tree(get_tree().root)
	_bind_web_unlock()

func _bind_web_unlock() -> void:
	if not OS.has_feature("web"):
		return
	_unlock_cb = JavaScriptBridge.create_callback(_on_web_audio_unlock)
	var win = JavaScriptBridge.get_interface("window")
	if win == null:
		return
	win.addEventListener("dagul-audio-unlock", _unlock_cb)

func _on_web_audio_unlock(_args: Array) -> void:
	if _current_track == "":
		return
	var track := _current_track
	_current_track = ""
	play_music(track, 0.0)

func _stream_for(sound_id: String) -> AudioStream:
	if Catalog == null:
		return null
	return Catalog.stream_for(sound_id)

func _music_for(track: String) -> AudioStream:
	if Catalog == null:
		return null
	return Catalog.music_for(track)

func _build_sfx_pool() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SfxPool%d" % i
		p.bus = &"World"
		add_child(p)
		_sfx_players.append(p)

func _build_music_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.name = "MusicA"
	_music_a.bus = &"World"
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.name = "MusicB"
	_music_b.bus = &"World"
	add_child(_music_b)

func _bus_for(sound_id: String) -> StringName:
	if sound_id.begins_with("gun_fire"):
		return &"Arena"
	return &"World"

func play_sfx(sound_id: String, volume_db: float = -5.0, pitch_variance: float = 0.04) -> void:  # lint-gd: public-api
	var stream = _stream_for(sound_id)
	if stream == null:
		return
	_play_stream(stream, volume_db, pitch_variance, _bus_for(sound_id))

func play_stream(stream: AudioStream, volume_db: float = -5.0, pitch_variance: float = 0.04) -> void:  # lint-gd: public-api
	if stream == null:
		return
	_play_stream(stream, volume_db, pitch_variance, &"World")

func _play_stream(stream: AudioStream, volume_db: float, pitch_variance: float, bus: StringName = &"World") -> void:
	if _sfx_players.is_empty():
		return
	var player := _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	player.bus = bus
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	if pitch_variance > 0.0:
		player.pitch_scale = 1.0 - pitch_variance + randf() * pitch_variance * 2.0
	else:
		player.pitch_scale = 1.0
	player.play()

func play_music(track: String, crossfade: float = CROSSFADE_DEFAULT) -> void:  # lint-gd: public-api
	if track == _current_track and (_music_a.playing or _music_b.playing):
		return
	var stream = _music_for(track)
	if stream == null:
		return
	_current_track = track
	_set_music_pitch(1.0)
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

func stop_music(fade_out: float = 0.5) -> void:  # lint-gd: public-api
	_current_track = ""
	_set_music_pitch(1.0)
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
	_tick_muffle(delta)
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

func hurry_music(scale: float = 1.3) -> void:  # lint-gd: public-api
	_set_music_pitch(scale)

func _set_music_pitch(scale: float) -> void:
	var p := clampf(scale, 0.5, 2.0)
	if _music_a != null:
		_music_a.pitch_scale = p
	if _music_b != null:
		_music_b.pitch_scale = p

func set_master_volume(vol: float) -> void:  # lint-gd: public-api
	master_volume = clampf(vol, 0.0, 1.0)

func set_sfx_volume(vol: float) -> void:  # lint-gd: public-api
	sfx_volume = clampf(vol, 0.0, 1.0)

func set_music_volume(vol: float) -> void:  # lint-gd: public-api
	music_volume = clampf(vol, 0.0, 1.0)
	if _music_a.playing and not _fading:
		_music_a.volume_db = linear_to_db(music_volume * master_volume)

func _ensure_bus(name: String, send: String) -> int:
	var idx := AudioServer.get_bus_index(name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, name)
	AudioServer.set_bus_send(idx, send)
	return idx

func _setup_world_bus() -> void:
	var widx := _ensure_bus("World", "Master")
	var aidx := _ensure_bus("Arena", "World")
	_ensure_world_lowpass(widx)
	_ensure_arena_reverb(aidx)
	if _impact == null:
		_impact = AudioStreamPlayer.new()
		_impact.name = "ImpactSfx"
		_impact.bus = &"Master"
		add_child(_impact)

func _ensure_world_lowpass(widx: int) -> void:
	for i in AudioServer.get_bus_effect_count(widx):
		if AudioServer.get_bus_effect(widx, i) is AudioEffectLowPassFilter:
			_lp = AudioServer.get_bus_effect(widx, i)
			return
	_lp = AudioEffectLowPassFilter.new()
	_lp.cutoff_hz = 20500.0
	_lp.resonance = 0.35
	AudioServer.add_bus_effect(widx, _lp)

func _ensure_arena_reverb(aidx: int) -> void:
	for i in AudioServer.get_bus_effect_count(aidx):
		if AudioServer.get_bus_effect(aidx, i) is AudioEffectReverb:
			return
	var rv := AudioEffectReverb.new()
	rv.room_size = 0.42
	rv.damping = 0.78
	rv.spread = 0.85
	rv.hipass = 0.22
	rv.dry = 1.0
	rv.wet = 0.14
	rv.predelay_msec = 16.0
	rv.predelay_feedback = 0.04
	AudioServer.add_bus_effect(aidx, rv)

func play_impact(sound_id: String, volume_db: float = -2.0) -> void:  # lint-gd: public-api
	var stream = _stream_for(sound_id)
	if stream == null:
		return
	if _impact == null:
		_play_stream(stream, volume_db, 0.0, &"Master")
		return
	_impact.bus = &"Master"
	_impact.stream = stream
	_impact.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	_impact.pitch_scale = 1.0
	_impact.play()

func muffle(seconds: float = 0.9) -> void:  # lint-gd: public-api
	_muffle_t = 0.0
	_muffle_dur = maxf(0.25, seconds)
	_muffling = true
	if _lp != null:
		_lp.cutoff_hz = 620.0

func _tick_muffle(delta: float) -> void:
	if not _muffling or _lp == null:
		return
	_muffle_t += delta
	var t := clampf(_muffle_t / _muffle_dur, 0.0, 1.0)
	var hold := 0.32
	var u := 0.0 if t < hold else clampf((t - hold) / (1.0 - hold), 0.0, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	_lp.cutoff_hz = lerpf(620.0, 20500.0, u)
	if t >= 1.0:
		_muffling = false
		_lp.cutoff_hz = 20500.0

func attach_world(host: Node2D, camera: Camera2D) -> void:  # lint-gd: public-api
	_world_host = host
	_attach_listener(camera)
	if host == null:
		return
	for p2 in _world_players:
		_reparent_world_player(p2, host)

func _attach_listener(camera: Camera2D) -> void:
	if camera == null or camera.get_node_or_null("SfxListener") != null:
		return
	var lis := AudioListener2D.new()
	lis.name = "SfxListener"
	camera.add_child(lis)
	lis.make_current()

func _reparent_world_player(p2: AudioStreamPlayer2D, host: Node2D) -> void:
	if p2.get_parent() == host:
		return
	if p2.get_parent() != null:
		p2.get_parent().remove_child(p2)
	host.add_child(p2)

func _build_world_pool() -> void:
	for i in WORLD_POOL:
		var p := AudioStreamPlayer2D.new()
		p.name = "SfxWorld%d" % i
		p.bus = &"World"
		p.max_distance = WORLD_MAX_DIST
		p.attenuation = 0.9
		p.area_mask = 0
		add_child(p)
		_world_players.append(p)

func play_sfx_at(sound_id: String, pos: Vector2, volume_db: float = -5.0, pitch_variance: float = 0.04) -> void:  # lint-gd: public-api
	var stream = _stream_for(sound_id)
	if stream == null:
		return
	if _world_players.is_empty():
		_play_stream(stream, volume_db, pitch_variance, _bus_for(sound_id))
		return
	var player := _world_players[_world_cursor]
	_world_cursor = (_world_cursor + 1) % _world_players.size()
	player.bus = _bus_for(sound_id)
	player.stream = stream
	player.global_position = pos
	player.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	if pitch_variance > 0.0:
		player.pitch_scale = 1.0 - pitch_variance + randf() * pitch_variance * 2.0
	else:
		player.pitch_scale = 1.0
	player.max_distance = WORLD_MAX_DIST
	player.attenuation = 0.9
	player.play()

func tick_world_sfx(world) -> void:  # lint-gd: public-api
	if world == null:
		return
	var tides = world.get("rat_tides")
	if tides == null:
		return
	var live := {}
	for tide in tides:
		_keep_tide_voice(tide, live)
	_drop_dead_tides(live)

func _keep_tide_voice(tide, live: Dictionary) -> void:
	var key := int(tide.get("owner", -1))
	if key < 0:
		return
	live[key] = true
	var pos: Vector2 = Vector2(tide.get("pos", Vector2.ZERO))
	var voice: AudioStreamPlayer2D = _tide_voices.get(key)
	if voice == null or not is_instance_valid(voice):
		_spawn_tide_voice(key, pos)
	else:
		voice.global_position = pos

func _spawn_tide_voice(key: int, pos: Vector2) -> void:
	var voice := AudioStreamPlayer2D.new()
	voice.name = "RatTide%d" % key
	voice.bus = &"World"
	voice.max_distance = WORLD_MAX_DIST
	voice.attenuation = 1.0
	var host: Node = _world_host if _world_host != null else self
	host.add_child(voice)
	_tide_voices[key] = voice
	var pick := "ult_rat_%s" % str(1 + randi() % 4)
	var stream = _stream_for(pick)
	if stream == null:
		stream = _stream_for("ult_rat")
	voice.stream = stream
	voice.global_position = pos
	voice.volume_db = -4.0 + linear_to_db(sfx_volume * master_volume)
	voice.play()

func _drop_dead_tides(live: Dictionary) -> void:
	var drop: Array = []
	for key in _tide_voices.keys():
		if not live.has(key):
			drop.append(key)
	for key in drop:
		var voice: AudioStreamPlayer2D = _tide_voices[key]
		if is_instance_valid(voice):
			voice.stop()
			voice.queue_free()
		_tide_voices.erase(key)

func _hook_tree(n: Node) -> void:
	_hook_button(n)
	for c in n.get_children():
		_hook_tree(c)

func _hook_button(n: Node) -> void:
	if n is BaseButton and not n.pressed.is_connected(_on_ui_button):
		n.pressed.connect(_on_ui_button)

func _on_ui_button() -> void:
	play_ui("ui_click", -8.0, 0.02)

func play_ui(sound_id: String, volume_db: float = -8.0, pitch_variance: float = 0.02) -> void:  # lint-gd: public-api
	var stream = _stream_for(sound_id)
	if stream == null:
		return
	if _impact == null:
		_play_stream(stream, volume_db, pitch_variance)
		return
	_impact.stream = stream
	_impact.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	if pitch_variance > 0.0:
		_impact.pitch_scale = 1.0 - pitch_variance + randf() * pitch_variance * 2.0
	else:
		_impact.pitch_scale = 1.0
	_impact.play()
