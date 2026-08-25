class_name SfxManager
extends RefCounted

var _players: Array[AudioStreamPlayer] = []
var _cursor: int = 0
var _dash_last: int = -1
var _wall_last: int = -1
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

func play(stream: AudioStreamWAV, volume_db: float = -5.0) -> void:
	if _players.is_empty():
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
		var event_type := StringName(event["type"])
		var actor := int(event["actor_id"])
		var target := int(event["target_id"])
		var involves := actor == local_slot or target == local_slot
		if event_type == &"gun_fire":
			var eq := str(event["data"].get("equipment", ""))
			var fire_id := SfxCatalog.fire_id_for(eq)
			if actor == local_slot:
				Audio.play_sfx(fire_id, -5.0, 0.03)
				print("[gangup] sfx %s eq=%s" % [fire_id, eq])
			else:
				Audio.play_sfx_at(fire_id, _hero_pos(world, actor), -6.0, 0.03)
		elif event_type == &"reload_started":
			var req := str(event["data"].get("equipment", ""))
			Audio.play_sfx(SfxCatalog.reload_id_for(req), 1.0, 0.02) if actor == local_slot else Audio.play_sfx_at(SfxCatalog.reload_id_for(req), _hero_pos(world, actor), -1.0, 0.02)
			if actor == local_slot:
				print("[gangup] sfx reload eq=%s" % req)
		elif event_type == &"shot_blocked":
			var block_pos: Vector2 = event["data"].get("pos", _hero_pos(world, actor))
			Audio.play_sfx_at("stone_hit", block_pos, -3.0, 0.04)
			Audio.play_sfx_at("gun_ricochet", block_pos, -6.0, 0.06)
			if actor == local_slot:
				print("[gangup] sfx stone_hit")
		elif event_type == &"crate_hit":
			var crate_pos: Vector2 = event["data"].get("pos", Vector2.ZERO)
			Audio.play_sfx_at("stone_tick", crate_pos, -6.0, 0.05)
		if event_type == &"tower_fire":
			Audio.play_sfx_at("gun_fire_launcher", event["data"].get("pos", _hero_pos(world, actor)), -4.0, 0.03)
			print("[gangup] sfx tower_fire")
		if event_type == &"hero_hit" and involves:
			var source := StringName(event["data"].get("source", &"normal"))
			if source == &"safe_zone":
				Audio.play_sfx("zone_tick", -8.0, 0.02)
				print("[gangup] sfx zone_tick")
			elif source == &"normal" or source == &"equipment":
				Audio.play_sfx("gun_hit", -3.0, 0.04)
				print("[gangup] sfx gun_hit source=%s" % source)
			if source == &"ultimate":
				Audio.play_sfx("gun_hit", -1.0, 0.03)
				print("[gangup] sfx ult_hit")
				hit_pause = maxi(hit_pause, 3)
				Input.start_joy_vibration(0, 0.55, 0.90, 0.28)
			elif source == &"equipment":
				hit_pause = maxi(hit_pause, 2)
				Input.start_joy_vibration(0, 0.36, 0.66, 0.18)
			elif source == &"normal":
				hit_pause = maxi(hit_pause, 1)
				Input.start_joy_vibration(0, 0.18, 0.34, 0.10)
			elif source != &"safe_zone":
				Audio.play_sfx("gun_hit", -5.0, 0.04)
				hit_pause = maxi(hit_pause, 1)
		elif event_type == &"mobility_used" and involves:
			var pick := 1
			if _dash_last < 0:
				pick = 1 + randi() % 2
			elif randf() < 0.72:
				pick = 3 - _dash_last
			else:
				pick = _dash_last
			_dash_last = pick
			Audio.play_sfx("dash_%s" % pick, 3.0, 0.03)
			print("[gangup] sfx dash_%s" % pick)
		elif event_type == &"finish_hit":
			Audio.play_impact("finisher", 4.0)
			Audio.play_sfx("finisher", 2.0, 0.0)
			Audio.muffle(0.90)
			print("[gangup] sfx finish_hit actor=%s target=%s" % [actor, target])
		elif event_type == &"combo_finisher" and involves:
			Audio.play_impact("finisher", 4.0)
			Audio.muffle(0.90)
			print("[gangup] sfx finisher")
			hit_pause = maxi(hit_pause, 4)
			Input.start_joy_vibration(0, 0.78, 1.0, 0.30)
		elif event_type == &"hero_launched" and involves:
			Audio.play_impact("finisher", 3.0)
			print("[gangup] sfx launch")
		elif event_type == &"ultimate_used" and (involves or actor == world.ultimate_focus_slot):
			var animal := 0
			if actor >= 0 and actor < world.heroes.size():
				animal = int(world.heroes[actor].get("animal", 0))
			var ult_id := SfxCatalog.ult_id_for(animal)
			Audio.play_sfx(ult_id, -1.0, 0.0) if actor == local_slot else Audio.play_sfx_at(ult_id, _hero_pos(world, actor), -1.0, 0.0)
			print("[gangup] sfx %s animal=%s slot=%s" % [ult_id, animal, actor])
			hit_pause = maxi(hit_pause, 1)
			if actor == local_slot:
				Input.start_joy_vibration(0, 0.30, 0.58, 0.18)
		elif event_type == &"attack_evaded" and involves:
			Audio.play_sfx("gun_ricochet", -6.0, 0.05)
			print("[gangup] sfx evade")
		elif event_type == &"wall_bounce":
			var wpick := 1
			if _wall_last < 0:
				wpick = 1 + randi() % 3
			elif randf() < 0.72:
				wpick = 1 + randi() % 2
				if wpick >= _wall_last:
					wpick += 1
			else:
				wpick = _wall_last
			_wall_last = wpick
			var wid := "wall_bounce_%s" % wpick
			if involves:
				Audio.play_sfx(wid, -2.0, 0.02)
				hit_pause = maxi(hit_pause, 3)
				Input.start_joy_vibration(0, 0.72, 1.0, 0.34)
			else:
				Audio.play_sfx_at(wid, _hero_pos(world, target), -4.0, 0.02)
			print("[gangup] sfx %s actor=%s target=%s" % [wid, actor, target])
		elif event_type == &"hero_respawned" and involves:
			Audio.play_sfx("respawn", -3.0, 0.0)
			print("[gangup] sfx respawn")
		elif event_type == &"hero_stood" and involves:
			Audio.play_sfx("respawn", -3.0, 0.0)
			print("[gangup] sfx stand_up")
		elif event_type == &"hero_downed":
			if bool(event["data"].get("executed", false)):
				if involves:
					Audio.play_sfx("down_kill", -2.0, 0.0)
				else:
					Audio.play_sfx_at("down_kill", _hero_pos(world, target), -4.0, 0.0)
				print("[gangup] sfx down_kill actor=%s target=%s" % [actor, target])
			else:
				Audio.play_sfx("down_kill", -6.0, 0.0) if involves else Audio.play_sfx_at("down_kill", _hero_pos(world, target), -8.0, 0.0)
				print("[gangup] sfx down")
			if involves:
				hit_pause = maxi(hit_pause, 5)
				Input.start_joy_vibration(0, 1.0, 1.0, 0.52)
		elif event_type == &"kill_streak":
			Audio.play_sfx("kill_fanfare", -3.0, 0.0)
			print("[gangup] sfx kill_streak")
			if involves:
				Input.start_joy_vibration(0, 0.42, 0.72, 0.22)
		elif event_type == &"streak_shutdown":
			Audio.play_sfx("finisher", 0.0, 0.0)
			print("[gangup] sfx shutdown")
			hit_pause = maxi(hit_pause, 3)
			if involves:
				Input.start_joy_vibration(0, 0.78, 1.0, 0.38)
		elif event_type == &"core_hit" and involves:
			Audio.play_sfx("stone_hit", -4.0, 0.03)
			print("[gangup] sfx core_hit")
		elif event_type == &"gun_upgraded" and involves:
			Audio.play_sfx("power_up", -1.0, 0.0)
			print("[gangup] sfx gun_upgraded")
		elif event_type == &"medkit_used" and involves:
			Audio.play_sfx("potion", -3.0, 0.0)
			print("[gangup] sfx potion used")
		elif event_type == &"health_pickup_collected" and involves:
			Audio.play_sfx("potion", -3.0, 0.0)
			print("[gangup] sfx potion pickup")
		elif event_type == &"rabbit_emerge":
			var epos: Vector2 = event["data"].get("pos", _hero_pos(world, actor))
			Audio.play_sfx("ult_rabbit_out", -2.0, 0.03)
			print("[gangup] sfx rabbit_out slot=%s" % actor)
		elif event_type == &"dmg_orb":
			if actor == local_slot:
				Audio.play_sfx("power_up", -1.0, 0.0)
				print("[gangup] sfx power_up atk")
			else:
				Audio.play_sfx_at("power_up", _hero_pos(world, actor), -3.0, 0.0)
		elif event_type == &"ult_orb":
			if actor == local_slot:
				Audio.play_sfx("power_up", -1.0, 0.0)
				print("[gangup] sfx power_up ult")
			else:
				Audio.play_sfx_at("power_up", _hero_pos(world, actor), -3.0, 0.0)
		elif event_type == &"roulette_spin" and actor == local_slot:
			Audio.play_sfx("roulette", 2.0, 0.0)
			print("[gangup] sfx roulette")
		elif event_type == &"safe_zone_shrink":
			Audio.play_sfx("zone_shrink", -14.0, 0.0)
			print("[gangup] sfx zone_shrink phase=%s" % event["data"].get("phase", -1))
		elif event_type == &"fight_countdown":
			Audio.play_sfx("countdown", -3.0, 0.0)
			Audio.hurry_music(1.3)
			print("[gangup] sfx countdown remain=60")
		elif event_type == &"fight_surge":
			Audio.play_sfx("ready_to_fight", -2.0, 0.0)
			print("[gangup] sfx ready_to_fight")
		elif event_type == &"match_won":
			Audio.stop_music(0.35)
			print("[gangup] music stop match_won")
			var place := _local_place(world, local_slot)
			if place >= 1 and place <= 3:
				Audio.play_sfx("victory", -2.0, 0.0)
				print("[gangup] sfx victory place=%s" % place)
			else:
				Audio.play_sfx("lose", -2.0, 0.0)
				print("[gangup] sfx lose place=%s" % place)
			hit_pause = maxi(hit_pause, 6)
			Input.start_joy_vibration(0, 0.88, 1.0, 0.62)
	return {"last_event_id": new_last, "hit_pause": hit_pause}



func _hero_pos(world, slot: int) -> Vector2:
	if world != null and slot >= 0 and slot < world.heroes.size():
		return Vector2(world.heroes[slot].get("pos", Vector2.ZERO))
	return Vector2.ZERO
func _local_place(world, local_slot: int) -> int:
	if world != null and world.has_method("final_standings"):
		var rows = world.final_standings()
		for i in range(rows.size()):
			if int(rows[i].get("slot", -1)) == local_slot:
				return i + 1
	if world != null and int(world.winner_slot) == local_slot:
		return 1
	return 99

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
