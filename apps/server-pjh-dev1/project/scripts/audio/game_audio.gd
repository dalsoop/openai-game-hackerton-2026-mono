extends Node

const Catalog = preload("res://scripts/audio/sfx_catalog.gd")
const POOL_SIZE := 12
const WORLD_POOL := 16
const WORLD_MAX_DIST := 3200.0
const CROSSFADE_DEFAULT := 0.8

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
var master_volume := 1.0
var sfx_volume := 1.0
var music_volume := 0.28
var _current_track := ""
var _lp: AudioEffectLowPassFilter
var _impact: AudioStreamPlayer
var _muffle_t := 0.0
var _muffle_dur := 0.0
var _muffling := false

func _ready() -> void:
	_setup_world_bus()
	_build_sfx_pool()
	_build_world_pool()
	_build_music_players()
	get_tree().node_added.connect(_hook_button)
	_hook_tree(get_tree().root)

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

func play_sfx(sound_id: String, volume_db: float = -5.0, pitch_variance: float = 0.04) -> void:
	var stream = Catalog.stream_for(sound_id)
	if stream == null:
		return
	_play_stream(stream, volume_db, pitch_variance, _bus_for(sound_id))

func play_stream(stream: AudioStream, volume_db: float = -5.0, pitch_variance: float = 0.04) -> void:
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

func play_music(track: String, crossfade: float = CROSSFADE_DEFAULT) -> void:
	if track == _current_track and (_music_a.playing or _music_b.playing):
		return
	var stream = Catalog.music_for(track)
	if stream == null:
		print("[gangup] music null %s" % track)
		return
	_current_track = track
	_set_music_pitch(1.0)
	print("[gangup] music play %s" % track)
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
	_current_track = ""
	_set_music_pitch(1.0)
	print("[gangup] music stop")
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


func hurry_music(scale: float = 1.3) -> void:
	_set_music_pitch(scale)
	print("[gangup] music hurry %s" % scale)

func _set_music_pitch(scale: float) -> void:
	var p := clampf(scale, 0.5, 2.0)
	if _music_a != null:
		_music_a.pitch_scale = p
	if _music_b != null:
		_music_b.pitch_scale = p

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)

func set_music_volume(vol: float) -> void:
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
	var has_lp := false
	for i in AudioServer.get_bus_effect_count(widx):
		if AudioServer.get_bus_effect(widx, i) is AudioEffectLowPassFilter:
			_lp = AudioServer.get_bus_effect(widx, i)
			has_lp = true
			break
	if not has_lp:
		_lp = AudioEffectLowPassFilter.new()
		_lp.cutoff_hz = 20500.0
		_lp.resonance = 0.35
		AudioServer.add_bus_effect(widx, _lp)
	var has_rv := false
	for i in AudioServer.get_bus_effect_count(aidx):
		if AudioServer.get_bus_effect(aidx, i) is AudioEffectReverb:
			has_rv = true
			break
	if not has_rv:
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
	if _impact == null:
		_impact = AudioStreamPlayer.new()
		_impact.name = "ImpactSfx"
		_impact.bus = &"Master"
		add_child(_impact)
	print("[gangup] audio world+arena bus")

func play_impact(sound_id: String, volume_db: float = -2.0) -> void:
	var stream = Catalog.stream_for(sound_id)
	if stream == null:
		stream = Catalog._load_wav_raw(Catalog.SOUNDS.get(sound_id, ""))
		print("[gangup] sfx impact raw %s" % sound_id)
	if stream == null:
		print("[gangup] sfx impact miss %s" % sound_id)
		return
	if _impact == null:
		_play_stream(stream, volume_db, 0.0, &"Master")
		print("[gangup] sfx impact pool %s db=%s" % [sound_id, volume_db])
		return
	_impact.bus = &"Master"
	_impact.stream = stream
	_impact.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	_impact.pitch_scale = 1.0
	_impact.play()
	print("[gangup] sfx impact %s db=%s" % [sound_id, volume_db])

func muffle(seconds: float = 0.9) -> void:
	_muffle_t = 0.0
	_muffle_dur = maxf(0.25, seconds)
	_muffling = true
	if _lp != null:
		_lp.cutoff_hz = 620.0
	print("[gangup] audio muffle")

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
		print("[gangup] audio muffle end")

func attach_world(host: Node2D, camera: Camera2D) -> void:
	_world_host = host
	if camera != null and camera.get_node_or_null("SfxListener") == null:
		var lis := AudioListener2D.new()
		lis.name = "SfxListener"
		camera.add_child(lis)
		lis.make_current()
		print("[gangup] sfx listener on camera")
	for p2 in _world_players:
		if p2.get_parent() != host and host != null:
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

func play_sfx_at(sound_id: String, pos: Vector2, volume_db: float = -5.0, pitch_variance: float = 0.04) -> void:
	var stream = Catalog.stream_for(sound_id)
	if stream == null:
		return
	if _world_players.is_empty():
		_play_stream(stream, volume_db, pitch_variance)
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

func tick_world_sfx(world) -> void:
	if world == null:
		return
	var live := {}
	var tides = world.get("rat_tides")
	if tides == null:
		return
	for tide in tides:
		var key := int(tide.get("owner", -1))
		if key < 0:
			continue
		live[key] = true
		var pos: Vector2 = Vector2(tide.get("pos", Vector2.ZERO))
		var voice: AudioStreamPlayer2D = _tide_voices.get(key)
		if voice == null or not is_instance_valid(voice):
			voice = AudioStreamPlayer2D.new()
			voice.name = "RatTide%d" % key
			voice.bus = &"World"
			voice.max_distance = WORLD_MAX_DIST
			voice.attenuation = 1.0
			var host: Node = _world_host if _world_host != null else self
			host.add_child(voice)
			_tide_voices[key] = voice
			var pick := "ult_rat_%s" % str(1 + randi() % 4)
			var stream = Catalog.stream_for(pick)
			if stream == null:
				stream = Catalog.stream_for("ult_rat")
			voice.stream = stream
			voice.global_position = pos
			voice.volume_db = -4.0 + linear_to_db(sfx_volume * master_volume)
			voice.play()
			print("[gangup] rat voice owner=%s pos=%s pick=%s" % [key, pos, pick])
		else:
			voice.global_position = pos
			if not voice.playing and stream_len_ok(voice):
				pass
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

func stream_len_ok(_p: AudioStreamPlayer2D) -> bool:
	return true

func _hook_tree(n: Node) -> void:
	_hook_button(n)
	for c in n.get_children():
		_hook_tree(c)

func _hook_button(n: Node) -> void:
	if n is BaseButton and not n.pressed.is_connected(_on_ui_button):
		n.pressed.connect(_on_ui_button)

func _on_ui_button() -> void:
	play_ui("ui_click", -8.0, 0.02)
	print("[gangup] sfx ui_click")

func play_ui(sound_id: String, volume_db: float = -8.0, pitch_variance: float = 0.02) -> void:
	var stream = Catalog.stream_for(sound_id)
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
