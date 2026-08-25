class_name SfxManager
extends RefCounted

var _players: Array[AudioStreamPlayer] = []
var _cursor: int = 0
var hit_sfx: AudioStreamWAV
var heavy_sfx: AudioStreamWAV
var ultimate_sfx: AudioStreamWAV
var down_sfx: AudioStreamWAV
var core_sfx: AudioStreamWAV
var tower_sfx: AudioStreamWAV

func setup(parent: Node) -> void:
	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "ImpactSfx%d" % index
		parent.add_child(player)
		_players.append(player)
	hit_sfx = _make_stream(185.0, 0.075, 0.22)
	heavy_sfx = _make_stream(105.0, 0.14, 0.52)
	ultimate_sfx = _make_stream(72.0, 0.24, 0.38)
	down_sfx = _make_stream(48.0, 0.34, 0.60)
	core_sfx = _make_stream(255.0, 0.10, 0.12)
	tower_sfx = _make_stream(92.0, 0.16, 0.18)

func play_id(sound_id: String, volume_db: float = -5.0) -> void:
	var tree := Engine.get_main_loop()
	if not (tree is SceneTree):
		play(hit_sfx, volume_db)
		return
	var audio = (tree as SceneTree).root.get_node_or_null("/root/Audio")
	if audio == null or audio.Catalog == null:
		play(hit_sfx, volume_db)
		return
	var stream = audio.Catalog.stream_for(sound_id)
	if stream == null:
		play(hit_sfx, volume_db)
		return
	audio.play_sfx(sound_id, volume_db)

func play(stream: AudioStreamWAV, volume_db: float = -5.0) -> void:
	if stream == null or _players.is_empty():
		return
	var player := _players[_cursor]
	_cursor = (_cursor + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 0.96 + 0.025 * float(_cursor % 4)
	player.play()

func process_events(world, local_slot: int, last_event_id: int) -> Dictionary:
	var new_last := last_event_id
	var hit_pause := 0
	for event in world.event_log.events:
		var event_id := int(event["event_id"])
		if event_id <= last_event_id:
			continue
		new_last = event_id
		hit_pause = _process_event(world, event, local_slot, hit_pause)
	return {"last_event_id": new_last, "hit_pause": hit_pause}

func _process_event(world, event: Dictionary, local_slot: int, hit_pause: int) -> int:
	var event_type := StringName(event["type"])
	var actor := int(event["actor_id"])
	var target := int(event["target_id"])
	var involves := actor == local_slot or target == local_slot
	if event_type == &"tower_fire":
		play_id("gun_fire", -3.0)
	if event_type == &"hero_hit" and involves:
		hit_pause = _hero_hit_impact(event, hit_pause)
		return hit_pause
	elif event_type == &"combo_finisher" and involves:
		play_id("finisher", 0.0)
		hit_pause = maxi(hit_pause, 4)
		Input.start_joy_vibration(0, 0.78, 1.0, 0.30)
		return hit_pause
	elif event_type == &"ultimate_used" and (involves or actor == world.ultimate_focus_slot):
		play_id("ultimate", -1.0)
		hit_pause = maxi(hit_pause, 1)
		if actor == local_slot:
			Input.start_joy_vibration(0, 0.30, 0.58, 0.18)
		return hit_pause
	elif event_type == &"attack_evaded" and involves:
		play_id("gun_ricochet", -10.0)
		return hit_pause
	elif event_type == &"wall_bounce" and involves:
		play_id("wall_bounce", -1.0)
		hit_pause = maxi(hit_pause, 3)
		Input.start_joy_vibration(0, 0.72, 1.0, 0.34)
		return hit_pause
	return _process_event_late(event, event_type, actor, local_slot, involves, hit_pause)

func _hero_hit_impact(event: Dictionary, hit_pause: int) -> int:
	var source := StringName(event["data"].get("source", &"normal"))
	if source == &"ultimate":
		play_id("ultimate", -2.0)
		hit_pause = maxi(hit_pause, 3)
		Input.start_joy_vibration(0, 0.55, 0.90, 0.28)
	elif source == &"equipment":
		play_id("gun_hit", -3.0)
		hit_pause = maxi(hit_pause, 2)
		Input.start_joy_vibration(0, 0.36, 0.66, 0.18)
	else:
		play_id("hit_marker", -8.0)
		hit_pause = maxi(hit_pause, 1)
		Input.start_joy_vibration(0, 0.18, 0.34, 0.10)
	return hit_pause

func _process_event_late(event: Dictionary, event_type: StringName, actor: int, local_slot: int, involves: bool, hit_pause: int) -> int:
	if event_type == &"hero_downed":
		play_id("down", -1.0)
		if involves:
			hit_pause = maxi(hit_pause, 5)
			Input.start_joy_vibration(0, 1.0, 1.0, 0.52)
	elif event_type == &"kill_streak":
		play_id("kill_fanfare", -2.0)
		if involves:
			Input.start_joy_vibration(0, 0.42, 0.72, 0.22)
	elif event_type == &"streak_shutdown":
		play_id("eliminate", 0.0)
		hit_pause = maxi(hit_pause, 3)
		if involves:
			Input.start_joy_vibration(0, 0.78, 1.0, 0.38)
	elif event_type == &"core_hit" and involves:
		play_id("core_hit", -5.0)
	elif event_type == &"gun_upgraded" and involves:
		play_id("gun_upgrade", -2.0)
	elif event_type == &"medkit_used" and involves:
		play_id("medkit", -7.0)
	elif event_type == &"safe_zone_shrink":
		play_id("zone_shrink", -4.0)
	elif event_type == &"match_won":
		play_id("victory" if actor == local_slot else "lose", 1.0 if actor == local_slot else -1.0)
		hit_pause = maxi(hit_pause, 6)
		Input.start_joy_vibration(0, 0.88, 1.0, 0.62)
	return hit_pause

func _make_stream(frequency: float, duration: float, noise_mix: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := maxi(1, roundi(duration * mix_rate))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for sample in range(sample_count):
		var t := float(sample) / float(mix_rate)
		var progress := float(sample) / float(sample_count)
		var envelope := pow(1.0 - progress, 2.4)
		var pitch_drop := frequency * (1.0 - progress * 0.42)
		var tone := sin(TAU * pitch_drop * t)
		var grit := sin(TAU * (frequency * 7.13) * t + sin(t * 913.0))
		var value := clampf((tone * (1.0 - noise_mix) + grit * noise_mix) * envelope * 0.72, -1.0, 1.0)
		pcm.encode_s16(sample * 2, roundi(value * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = pcm
	return stream
