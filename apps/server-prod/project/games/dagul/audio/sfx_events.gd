class_name SfxEvents
extends RefCounted

var _dash_last: int = -1
var _wall_last: int = -1

func audio_node() -> Node:
	var tree := Engine.get_main_loop()
	if not (tree is SceneTree):
		return null
	return (tree as SceneTree).root.get_node_or_null("/root/Audio")

func play(sound_id: String, volume_db: float, pitch: float = 0.0) -> void:
	var audio := audio_node()
	if audio != null and audio.has_method("play_sfx"):
		audio.play_sfx(sound_id, volume_db, pitch)

func play_at(sound_id: String, pos: Vector2, volume_db: float, pitch: float = 0.0) -> void:
	var audio := audio_node()
	if audio != null and audio.has_method("play_sfx_at"):
		audio.play_sfx_at(sound_id, pos, volume_db, pitch)
		return
	play(sound_id, volume_db, pitch)

func impact(sound_id: String, volume_db: float) -> void:
	var audio := audio_node()
	if audio != null and audio.has_method("play_impact"):
		audio.play_impact(sound_id, volume_db)
		return
	play(sound_id, volume_db, 0.0)

func muffle(seconds: float) -> void:
	var audio := audio_node()
	if audio != null and audio.has_method("muffle"):
		audio.muffle(seconds)

func hurry(scale: float) -> void:
	var audio := audio_node()
	if audio != null and audio.has_method("hurry_music"):
		audio.hurry_music(scale)

func stop_music(fade: float) -> void:
	var audio := audio_node()
	if audio != null and audio.has_method("stop_music"):
		audio.stop_music(fade)

func hero_pos(world, slot: int) -> Vector2:
	if world != null and slot >= 0 and slot < world.heroes.size():
		return Vector2(world.heroes[slot].get("pos", Vector2.ZERO))
	return Vector2.ZERO

func local_place(world, local_slot: int) -> int:
	if world == null:
		return 99
	if world.has_method("final_standings"):
		var place := _place_in_rows(world.final_standings(), local_slot)
		if place > 0:
			return place
	if int(world.winner_slot) == local_slot:
		return 1
	return 99

func _place_in_rows(rows, local_slot: int) -> int:
	for i in range(rows.size()):
		if int(rows[i].get("slot", -1)) == local_slot:
			return i + 1
	return 0

func handle(world, event: Dictionary, local_slot: int, hit_pause: int) -> int:
	var event_type := StringName(event["type"])
	var actor := int(event["actor_id"])
	var target := int(event["target_id"])
	var involves := actor == local_slot or target == local_slot
	hit_pause = _handle_shots(world, event, event_type, actor, local_slot, hit_pause)
	hit_pause = _handle_hits(world, event, event_type, actor, target, local_slot, involves, hit_pause)
	hit_pause = _handle_life(world, event, event_type, actor, target, local_slot, involves, hit_pause)
	return _handle_match(world, event_type, local_slot, hit_pause)

func _handle_shots(world, event: Dictionary, event_type: StringName, actor: int, local_slot: int, hit_pause: int) -> int:
	if event_type == &"gun_fire":
		var eq := str(event["data"].get("equipment", ""))
		var fire_id := SfxCatalog.fire_id_for(eq)
		if actor == local_slot:
			play(fire_id, -5.0, 0.03)
		else:
			play_at(fire_id, hero_pos(world, actor), -6.0, 0.03)
	elif event_type == &"reload_started":
		var req := str(event["data"].get("equipment", ""))
		var rid := SfxCatalog.reload_id_for(req)
		if actor == local_slot:
			play(rid, 1.0, 0.02)
		else:
			play_at(rid, hero_pos(world, actor), -1.0, 0.02)
	elif event_type == &"shot_blocked":
		var block_pos: Vector2 = event["data"].get("pos", hero_pos(world, actor))
		play_at("stone_hit", block_pos, -3.0, 0.04)
		play_at("gun_ricochet", block_pos, -3.0, 0.06)
	elif event_type == &"crate_hit":
		play_at("stone_tick", event["data"].get("pos", Vector2.ZERO), -3.0, 0.05)
	elif event_type == &"tower_fire":
		play_at("gun_fire_launcher", event["data"].get("pos", hero_pos(world, actor)), -4.0, 0.03)
	return hit_pause

func _handle_hits(world, event: Dictionary, event_type: StringName, actor: int, target: int, local_slot: int, involves: bool, hit_pause: int) -> int:
	if event_type == &"hero_hit" and involves:
		return _hero_hit(event, hit_pause)
	if event_type == &"mobility_used" and involves:
		_play_dash()
		return hit_pause
	if event_type == &"finish_hit":
		impact("finisher", 4.0)
		play("finisher", 2.0, 0.0)
		muffle(0.90)
		return hit_pause
	if event_type == &"combo_finisher" and involves:
		impact("finisher", 4.0)
		muffle(0.90)
		Input.start_joy_vibration(0, 0.78, 1.0, 0.30)
		return maxi(hit_pause, 4)
	if event_type == &"hero_launched" and involves:
		impact("finisher", 3.0)
		return hit_pause
	if event_type == &"ultimate_used" and (involves or actor == world.ultimate_focus_slot):
		return _play_ult(world, actor, local_slot, hit_pause)
	if event_type == &"attack_evaded" and involves:
		play("gun_ricochet", -3.0, 0.05)
	if event_type == &"wall_bounce":
		return _play_wall(world, target, involves, hit_pause)
	return hit_pause

func _hero_hit(event: Dictionary, hit_pause: int) -> int:
	var source := StringName(event["data"].get("source", &"normal"))
	if source == &"safe_zone":
		play("zone_tick", -2.0, 0.02)
		return hit_pause
	if source == &"ultimate":
		play("gun_hit", -1.0, 0.03)
		Input.start_joy_vibration(0, 0.55, 0.90, 0.28)
		return maxi(hit_pause, 3)
	if source == &"equipment":
		play("gun_hit", -3.0, 0.04)
		Input.start_joy_vibration(0, 0.36, 0.66, 0.18)
		return maxi(hit_pause, 2)
	if source == &"normal":
		play("gun_hit", -3.0, 0.04)
		Input.start_joy_vibration(0, 0.18, 0.34, 0.10)
		return maxi(hit_pause, 1)
	play("gun_hit", -3.0, 0.04)
	return maxi(hit_pause, 1)

func _play_dash() -> void:
	var pick := 1
	if _dash_last < 0:
		pick = 1 + randi() % 2
	elif randf() < 0.72:
		pick = 3 - _dash_last
	else:
		pick = _dash_last
	_dash_last = pick
	play("dash_%s" % pick, 3.0, 0.03)

func _play_ult(world, actor: int, local_slot: int, hit_pause: int) -> int:
	var animal := 0
	if actor >= 0 and actor < world.heroes.size():
		animal = int(world.heroes[actor].get("animal", 0))
	var ult_id := SfxCatalog.ult_id_for(animal)
	if actor == local_slot:
		play(ult_id, -1.0, 0.0)
		Input.start_joy_vibration(0, 0.30, 0.58, 0.18)
	else:
		play_at(ult_id, hero_pos(world, actor), -1.0, 0.0)
	return maxi(hit_pause, 1)

func _play_wall(world, target: int, involves: bool, hit_pause: int) -> int:
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
		play(wid, -2.0, 0.02)
		Input.start_joy_vibration(0, 0.72, 1.0, 0.34)
		return maxi(hit_pause, 3)
	play_at(wid, hero_pos(world, target), -4.0, 0.02)
	return hit_pause

func _handle_life(world, event: Dictionary, event_type: StringName, actor: int, target: int, local_slot: int, involves: bool, hit_pause: int) -> int:
	if event_type == &"hero_respawned" and involves:
		play("respawn", -3.0, 0.0)
	elif event_type == &"hero_stood" and involves:
		play("respawn", -3.0, 0.0)
	elif event_type == &"hero_downed":
		_play_down(world, event, actor, target, involves)
		if involves:
			Input.start_joy_vibration(0, 1.0, 1.0, 0.52)
			hit_pause = maxi(hit_pause, 5)
	elif event_type == &"kill_streak":
		play("kill_fanfare", -3.0, 0.0)
		if involves:
			Input.start_joy_vibration(0, 0.42, 0.72, 0.22)
	elif event_type == &"streak_shutdown":
		play("finisher", 0.0, 0.0)
		if involves:
			Input.start_joy_vibration(0, 0.78, 1.0, 0.38)
		hit_pause = maxi(hit_pause, 3)
	elif event_type == &"core_hit" and involves:
		play("stone_hit", -4.0, 0.03)
	elif event_type == &"gun_upgraded" and involves:
		play("power_up", -1.0, 0.0)
	elif event_type == &"medkit_used" and involves:
		play("potion", -3.0, 0.0)
	elif event_type == &"health_pickup_collected" and involves:
		play("potion", -3.0, 0.0)
	elif event_type == &"rabbit_emerge":
		play("ult_rabbit_out", -2.0, 0.03)
	elif event_type == &"dmg_orb" or event_type == &"ult_orb":
		_play_orb(world, actor, local_slot)
	elif event_type == &"roulette_spin" and actor == local_slot:
		play("roulette", 2.0, 0.0)
	return hit_pause

func _play_down(world, event: Dictionary, _actor: int, target: int, involves: bool) -> void:
	if involves:
		play("down_kill", -2.0 if bool(event["data"].get("executed", false)) else -3.0, 0.0)
	else:
		play_at("down_kill", hero_pos(world, target), -4.0 if bool(event["data"].get("executed", false)) else -5.0, 0.0)

func _play_orb(world, actor: int, local_slot: int) -> void:
	if actor == local_slot:
		play("power_up", -1.0, 0.0)
	else:
		play_at("power_up", hero_pos(world, actor), -3.0, 0.0)

func _handle_match(world, event_type: StringName, local_slot: int, hit_pause: int) -> int:
	if event_type == &"match_started":
		var audio := audio_node()
		if audio != null and audio.has_method("play_music"):
			audio.play_music("match")
		play("match_start", -1.0, 0.0)
	elif event_type == &"safe_zone_shrink":
		play("zone_shrink", -2.0, 0.0)
	elif event_type == &"combat_started":
		play("ready_to_fight", -2.0, 0.0)
	elif event_type == &"fight_countdown":
		play("countdown", -3.0, 0.0)
		hurry(1.3)
	elif event_type == &"fight_surge":
		play("ready_to_fight", -2.0, 0.0)
	elif event_type == &"match_won":
		stop_music(0.35)
		var place := local_place(world, local_slot)
		if place >= 1 and place <= 3:
			play("victory", -2.0, 0.0)
		else:
			play("lose", -2.0, 0.0)
		Input.start_joy_vibration(0, 0.88, 1.0, 0.62)
		return maxi(hit_pause, 6)
	return hit_pause
