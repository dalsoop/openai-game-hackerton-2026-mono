class_name DamageSystem
extends RefCounted

var w

func _init(world) -> void:
	w = world

func streak_damage_multiplier(slot: int) -> float:
	if slot < 0 or slot >= w.heroes.size():
		return 1.0
	return 1.0 + minf(0.10, float(int(w.heroes[slot].get("kill_streak", 0))) * 0.025)

func streak_move_multiplier(slot: int) -> float:
	if slot < 0 or slot >= w.heroes.size():
		return 1.0
	return 1.0 + minf(0.06, float(int(w.heroes[slot].get("kill_streak", 0))) * 0.015)

func attack_direction(direction: Vector2) -> Vector2:
	var dir = direction.normalized()
	return Vector2.RIGHT if dir.length_squared() < 0.1 else dir

func muzzle_spawn_pos(slot: int, _direction: Vector2) -> Vector2:
	var h: Dictionary = w.heroes[slot]
	var pos: Vector2 = h["pos"]
	var hop_lift = 0.0
	var hop_time = float(h.get("hop_time", 0.0))
	if hop_time > 0.0:
		var hop_max = maxf(0.001, float(h.get("hop_max", 0.30)))
		var hop_t = clampf(1.0 - hop_time / hop_max, 0.0, 1.0)
		hop_lift = float(h.get("hop_height", 19.0)) * sin(PI * hop_t)
	var body_pos = pos + Vector2(0.0, -hop_lift)
	var equip_id = "burst"
	var held = h.get("equipment", {})
	if typeof(held) == TYPE_DICTIONARY:
		equip_id = str(held.get("id", "burst"))
	var look: Vector2 = h["aim"]
	if look.length_squared() < 0.0001:
		look = h["facing"]
	if look.length_squared() < 0.0001:
		look = Vector2.RIGHT
	return w.GunSig.muzzle_world_pos(body_pos, look, equip_id)

func normal_combo_pattern(_equipment_id: String) -> Array:
	return []

func normal_step_reach(slot: int, _step: Dictionary) -> float:
	return normal_reach(slot)

func normal_auto_target(_slot: int, _facing: Vector2, _reach: float) -> int:
	return -1

func try_start_reload(slot: int) -> void:
	var h: Dictionary = w.heroes[slot]
	if not bool(h["alive"]):
		return
	if float(h.get("reload_left", 0.0)) > 0.0:
		return
	if float(h["stun_time"]) > 0.0 or float(h["launch_time"]) > 0.0:
		return
	var cap = int(h["equipment"].get("mag_size", 1))
	if int(h.get("mag", cap)) >= cap:
		return
	var reload_dur = float(h["equipment"].get("reload_time", 1.2))
	h["reload_left"] = maxf(0.20, reload_dur)
	h["reload_flash"] = 0.0
	h["spray_index"] = 0.0
	h["spray_idle"] = 1.0
	h["action"] = &"RELOAD"
	w.heroes[slot] = h

func stamp_gun_fire(h: Dictionary, slot: int, equipment_id: String) -> void:
	var fx: Dictionary = w.GunSig.fx_for_equipment(equipment_id)
	var frames = maxi(1, int(fx.get("frames", 2)))
	h["muzzle_row"] = int(fx.get("row", 0))
	h["muzzle_time"] = float(frames) * 0.055
	h["muzzle_scale"] = float(fx.get("scale", 1.0))
	if slot == w.local_slot:
		var shake = int(fx.get("shake", 3))
		if bool(h.get("heavy_shot", false)):
			shake = maxi(shake * 3, 10)
		w.local_fire_shake = shake

func try_normal_attack(slot: int, direction: Vector2) -> void:
	var h: Dictionary = w.heroes[slot]
	if not bool(h["alive"]) or float(h["fire_cd"]) > 0.0 or float(h["launch_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
		return
	if w.roul.hero_has_timed(h, "turtle"):
		return
	if float(h.get("reload_left", 0.0)) > 0.0:
		return
	if int(h.get("mag", 1)) <= 0:
		try_start_reload(slot)
		return
	var equipment: Dictionary = h["equipment"]
	var equipment_id = str(equipment["id"])
	var base_dir = attack_direction(direction)
	h["facing"] = base_dir
	h["aim"] = base_dir
	var pellet_count = maxi(1, int(equipment.get("normal_projectiles", 1)))
	var spread = float(equipment.get("normal_spread", 0.0))
	var damage = float(equipment.get("normal_damage", 6.0))
	var knockback = float(equipment.get("normal_knockback", 6.0))
	var kind = StringName(equipment.get("normal_kind", "bolt"))
	if equipment_id == "rail":
		kind = &"tracer"
	elif kind != &"pellet" and kind != &"bolt" and kind != &"shell":
		kind = &"bolt"
	var speed = float(equipment.get("normal_speed", 980.0))
	var ttl = float(equipment.get("normal_range", 0.6))
	var pierce = int(equipment.get("normal_pierce", 0))
	var splash = float(equipment.get("normal_splash", 0.0))
	var radius = float(equipment.get("normal_radius", 5.0)) * 3.0
	var heavy = false
	if equipment_id == "brawler":
		var n = int(h.get("brawler_shot", 0)) + 1
		h["brawler_shot"] = n
		if n % 3 == 0:
			damage *= 2.0
			radius *= 2.5
			heavy = true
	var interval = float(equipment.get("normal_interval", 0.2))
	interval *= maxf(0.35, 1.0 - w.roul.roulette_stat(slot, "rate"))
	ttl *= 1.0 + w.roul.roulette_stat(slot, "range")
	var spray_i = int(floor(float(h.get("spray_index", 0.0))))
	var kick: Vector2 = w.GunSig.spray_kick(equipment_id, spray_i)
	h["spray_index"] = float(spray_i + 1)
	h["spray_idle"] = 0.0
	h["heavy_shot"] = heavy
	if heavy:
		kick *= 2.7
		kick += Vector2(0.0, -7.0)
		h["spray_index"] = float(spray_i + 3)
	if slot == w.local_slot:
		w.local_mouse_kick = kick
	if equipment_id == "mortar":
		w.proj.spawn_projectile(slot, base_dir, damage, speed, maxf(radius, 12.0), ttl, &"normal", splash if splash > 1.0 else 120.0, false, 0, 0.0, knockback, &"shell", 0.0, "", false)
	else:
		for index in range(pellet_count):
			var offset: float = 0.0
			if pellet_count > 1:
				offset = (float(index) - float(pellet_count - 1) * 0.5) * spread
			w.proj.spawn_projectile(slot, base_dir.rotated(offset), damage, speed, radius, ttl, &"normal", splash, false, pierce, 0.0, knockback, kind, 0.0, "", false)
			if heavy:
				w.projectiles[w.projectiles.size() - 1]["heavy"] = true
	var burst_cap = int(equipment.get("burst_shots", 0))
	var mag_cap = int(equipment.get("mag_size", 0))
	if burst_cap > 0 and mag_cap <= 0:
		var left = int(h.get("burst_left", burst_cap)) - 1
		if left <= 0:
			interval = float(equipment.get("reload_time", 1.1))
			left = burst_cap
		h["burst_left"] = left
	h["mag"] = maxi(0, int(h.get("mag", mag_cap)) - 1)
	if int(h["mag"]) <= 0:
		h["fire_cd"] = interval
		h["attack_lock_time"] = minf(0.12, interval * 0.45)
		h["normal_step"] = 0
		h["normal_chain_time"] = 0.0
		h["normal_interval"] = interval
		h["combo_target"] = -1
		h["action"] = &"GUN_FIRE"
		stamp_gun_fire(h, slot, equipment_id)
		w.heroes[slot] = h
		w.event_log.emit(w.tick, &"gun_fire", slot, -1, {"equipment":equipment_id, "gun":equipment.get("name", ""), "mode":equipment.get("fire_mode", "auto")})
		try_start_reload(slot)
		return
	h["fire_cd"] = interval
	h["attack_lock_time"] = minf(0.12, interval * 0.45)
	h["normal_step"] = 0
	h["normal_chain_time"] = 0.0
	h["normal_interval"] = interval
	h["combo_target"] = -1
	h["action"] = &"GUN_FIRE"
	stamp_gun_fire(h, slot, equipment_id)
	w.heroes[slot] = h
	w.event_log.emit(w.tick, &"gun_fire", slot, -1, {"equipment":equipment_id, "gun":equipment.get("name", ""), "mode":equipment.get("fire_mode", "auto")})

func normal_reach(slot: int) -> float:
	var equipment: Dictionary = w.heroes[slot]["equipment"]
	return float(equipment["normal_speed"]) * float(equipment["normal_range"]) * 0.92 * (1.0 + w.roul.roulette_stat(slot, "range"))

func normal_combo_length(_slot: int) -> int:
	return 1

func equipment_reach(slot: int) -> float:
	return normal_reach(slot)

func break_incoming_combo(slot: int) -> void:
	if slot < 0 or slot >= w.heroes.size():
		return
	var victim: Dictionary = w.heroes[slot]
	var owner = int(victim.get("combo_owner", -1))
	victim["combo_capture_time"] = 0.0
	victim["combo_hits"] = 0
	victim["combo_time"] = 0.0
	victim["combo_damage"] = 0.0
	victim["combo_owner"] = -1
	victim["combo_immunity"] = maxf(float(victim["combo_immunity"]), 0.52)
	w.heroes[slot] = victim
	if owner >= 0 and owner < w.heroes.size():
		var attacker: Dictionary = w.heroes[owner]
		if int(attacker.get("combo_target", -1)) == slot:
			attacker["combo_target"] = -1
			attacker["normal_step"] = 0
			attacker["normal_chain_time"] = 0.0
			w.heroes[owner] = attacker


func damage_hero(owner: int, target: int, amount: float, source: StringName = &"normal", cc_time: float = 0.0, knockback: float = 0.0, impact_origin: Vector2 = Vector2.ZERO, effect_label: String = "", effect_kind: StringName = &"hit_spark", attack_finisher: bool = false, control_kind: StringName = &"slow") -> void:
	var h: Dictionary = w.heroes[target]
	if not bool(h["alive"]):
		return
	if bool(h.get("burrowed", false)):
		return
	if float(h.get("spawn_protect_time", 0.0)) > 0.0:
		return
	if float(h["evade_time"]) > 0.0:
		h["evade_time"] = 0.0
		w.heroes[target] = h
		w.proj.add_effect(&"afterimage", Vector2(h["pos"]), 105.0, 0.38, Color("#b9f3ff"), "EVADE")
		w.event_log.emit(w.tick, &"attack_evaded", owner, target, {"source":source})
		return
	var attacker: Dictionary = w.heroes[owner]
	var attacker_id = str(attacker["equipment"]["id"])
	amount *= streak_damage_multiplier(owner)
	if float(attacker.get("dmg_orb_time", 0.0)) > 0.0:
		amount *= w.CRATE_ORB_DMG_MUL
	if attacker_id == "brawler" and float(attacker["hp"]) <= float(attacker["max_hp"]) * 0.5:
		amount *= 1.12
	elif attacker_id == "rail" and Vector2(attacker["pos"]).distance_to(Vector2(h["pos"])) >= 430.0:
		amount *= 1.12
	elif attacker_id == "spear" and Vector2(attacker["pos"]).distance_to(Vector2(h["pos"])) >= 280.0:
		amount *= 1.12
	amount *= 1.0 + clampf((w.match_time - 65.0) / 35.0, 0.0, 1.25)
	var combo_hit = 0
	if bool(h["charging_skill"]):
		h["charging_skill"] = false
		h["charge_time"] = 0.0
		w.proj.add_effect(&"charge_break", Vector2(h["pos"]), 54.0, 0.22, Color("#8ca0b8"), "")
	if source != &"mobility":
		if float(h["combo_time"]) <= 0.0 or float(h["combo_immunity"]) > 0.0 or int(h["combo_owner"]) != owner:
			h["combo_hits"] = 1
			h["combo_damage"] = 0.0
		else:
			h["combo_hits"] = int(h["combo_hits"]) + 1
		combo_hit = int(h["combo_hits"])
		h["combo_owner"] = owner
		h["combo_time"] = 0.38 if attack_finisher else 1.05
		amount *= 1.0 + minf(0.12, float(combo_hit - 1) * 0.06)
	amount += w.roul.roulette_stat(owner, "atk")
	amount *= maxf(0.05, 1.0 - w.roul.roulette_stat(target, "def"))
	amount = w.roul.absorb_roulette_shield(h, amount)
	if float(h["guard_time"]) > 0.0:
		amount *= 0.55
		knockback *= 0.52
	var armor_active = float(h["super_armor_time"]) > 0.0
	var armor_strength = clampf(float(h["super_armor_strength"]), 0.0, 1.0) if armor_active else 0.0
	if armor_active:
		h["combo_capture_time"] = 0.0
	if source != &"mobility" and not bool(h.get("downed", false)):
		var combo_cap = float(h["max_hp"]) * float(h["equipment"]["combo_cap_ratio"])
		var combo_remaining = maxf(0.0, combo_cap - float(h["combo_damage"]))
		amount = minf(amount, combo_remaining)
		h["combo_damage"] = float(h["combo_damage"]) + amount
	h["hp"] = float(h["hp"]) - amount
	h["recent_attacker"] = owner
	h["grudge"] = minf(1.0, float(h["grudge"]) + amount / 100.0)
	if owner >= 0:
		var hits: Dictionary = h.get("life_hits", {})
		var key = str(owner)
		var rec: Dictionary = hits.get(key, {"dmg": 0.0, "tick": 0})
		rec["dmg"] = float(rec.get("dmg", 0.0)) + amount
		rec["tick"] = w.tick
		hits[key] = rec
		h["life_hits"] = hits
	if not armor_active and cc_time > 0.0:
		h["cc_time"] = maxf(float(h["cc_time"]), cc_time)
		match control_kind:
			&"root":
				h["root_time"] = maxf(float(h["root_time"]), cc_time)
				h["vel"] = Vector2.ZERO
				w.proj.add_effect(&"chain_bind", Vector2(h["pos"]), 48.0, minf(0.48, cc_time), Color("#b78cff"), "ROOTED")
			&"stun":
				h["stun_time"] = maxf(float(h["stun_time"]), cc_time)
				h["vel"] = Vector2.ZERO
				h["charging_skill"] = false
				h["charge_time"] = 0.0
				w.proj.add_effect(&"stun_burst", Vector2(h["pos"]), 58.0, minf(0.52, cc_time), Color("#ffe27a"), "STUNNED")
	var gun_combat = source == &"normal"
	var heavy_blast = effect_kind == &"explosion" or effect_label == "SPLASH"
	if combo_hit > 0 and not gun_combat:
		var hitstun = 0.04 if float(h["combo_immunity"]) > 0.0 else minf(0.28, 0.07 + combo_hit * 0.055)
		if attacker_id == "chain":
			hitstun += 0.05
		if not armor_active:
			h["hitstun_time"] = maxf(float(h["hitstun_time"]), hitstun)
	var launch_knockback = knockback
	if gun_combat and not heavy_blast and not attack_finisher:
		launch_knockback = 0.0
		if absf(knockback) > 0.01 and not armor_active:
			var shove_dir = impact_origin.direction_to(Vector2(h["pos"])) if impact_origin != Vector2.ZERO else Vector2(w.heroes[owner]["pos"]).direction_to(Vector2(h["pos"]))
			if shove_dir.length_squared() < 0.1:
				shove_dir = Vector2(w.heroes[owner]["aim"])
			var shove = clampf(5.0 + absf(knockback) * 0.35, 5.0, 16.0)
			h["pos"] = w.arena.resolve_cover_motion(Vector2(h["pos"]), shove_dir * shove)
		if attacker_id == "chain" and not armor_active:
			var tug_distance = Vector2(h["pos"]).distance_to(Vector2(attacker["pos"]))
			var tug_direction = Vector2(h["pos"]).direction_to(Vector2(attacker["pos"]))
			var tug = minf(20.0, maxf(0.0, tug_distance - 55.0))
			h["pos"] = w.arena.resolve_cover_motion(Vector2(h["pos"]), tug_direction * tug)
	elif source == &"normal" and attack_finisher:
		var launch_sign = -1.0 if launch_knockback < 0.0 else 1.0
		launch_knockback = launch_sign * (absf(launch_knockback) + 104.0)
		h["combo_capture_time"] = 0.0
		w.proj.add_effect(&"combo_finisher", Vector2(h["pos"]), 118.0, 0.34, Color("#fff2b2"), "", Vector2(attacker["pos"]).direction_to(Vector2(h["pos"])))
		w.event_log.emit(w.tick, &"combo_finisher", owner, target, {"damage":float(h["combo_damage"]), "hits":combo_hit})
		w.impact_ticks = maxi(w.impact_ticks, 18)
	if armor_active:
		launch_knockback *= 1.0 - armor_strength
		if absf(launch_knockback) < 55.0:
			launch_knockback = 0.0
	if absf(launch_knockback) > 0.01:
		h["combo_capture_time"] = 0.0
		var origin = impact_origin if impact_origin != Vector2.ZERO else Vector2(w.heroes[owner]["pos"])
		var push_direction = origin.direction_to(Vector2(h["pos"]))
		if push_direction.length_squared() < 0.1:
			push_direction = Vector2(w.heroes[owner]["aim"])
		var launch_direction = push_direction if launch_knockback > 0.0 else -push_direction
		var launch_speed = (900.0 + absf(launch_knockback) * 9.8) / float(h["equipment"]["weight"])
		h["launch_vel"] = launch_direction * launch_speed
		h["launch_time"] = clampf(0.22 + absf(launch_knockback) * 0.0022, 0.26, 0.72)
		h["wall_bounces"] = 0
		h["launch_owner"] = owner
		h["launch_trail"] = [Vector2(h["pos"])]
		h["launch_trail_fade"] = 0.34
		h["launch_wall_damage"] = float(h["combo_damage"]) if source != &"mobility" else 0.0
		h["vel"] = Vector2.ZERO
	w.heroes[target] = h
	attacker = w.heroes[owner]
	attacker["threat"] = float(attacker["threat"]) + amount * 0.38
	attacker["damage_dealt"] = float(attacker["damage_dealt"]) + amount
	attacker["score"] = float(attacker["score"]) + amount
	w.heroes[owner] = attacker
	if amount > 0.01:
		award_charge(owner, amount, source)
	var impact_radius = clampf(24.0 + amount * 1.4 + absf(knockback) * 0.12, 32.0, 125.0)
	var effect_direction = Vector2(h["launch_vel"]).normalized() if Vector2(h["launch_vel"]).length_squared() > 0.1 else Vector2(w.heroes[owner]["pos"]).direction_to(Vector2(h["pos"]))
	w.proj.add_effect(effect_kind, Vector2(h["pos"]), impact_radius, 0.22 if source == &"normal" else 0.42, Color("#ffffff"), effect_label, effect_direction)
	if amount > 0.01 and source != &"safe_zone":
		h["hit_flash"] = 0.11
		w.heroes[target] = h
		if target == w.local_slot:
			w.local_hit_shake = 10
		if owner == w.local_slot:
			w.local_hit_shake = maxi(w.local_hit_shake, 8)
	w.event_log.emit(w.tick, &"hero_hit", owner, target, {"damage":amount, "knockback":launch_knockback, "label":effect_label, "source":source, "combo":combo_hit})
	if owner == 0 or target == 0:
		w.impact_ticks = maxi(w.impact_ticks, 4 if source == &"normal" else (11 if source == &"equipment" else 18))
		w.impact_pos = Vector2(h["pos"])
	if bool(h.get("downed", false)):
		h["hp"] = 0.0
		h["down_taken"] = float(h.get("down_taken", 0.0)) + amount
		w.heroes[target] = h
		if float(h["down_taken"]) >= w.DOWN_FINISH_HP:
			w.lifecycle.down_hero(owner, target)
	elif float(h["hp"]) <= 0.0:
		w.lifecycle.enter_down(owner, target)

func damage_core(owner: int, target: int, amount: float, source: StringName = &"normal") -> void:
	var core: Dictionary = w.cores[target]
	if not bool(core["alive"]):
		return
	if not w._core_exposed(target):
		w.impact_ticks = maxi(w.impact_ticks, 2)
		w.event_log.emit(w.tick, &"core_shield_blocked", owner, target, {"source":source})
		return
	amount *= streak_damage_multiplier(owner)
	amount *= 1.15
	core["hp"] = float(core["hp"]) - amount
	w.cores[target] = core
	award_charge(owner, amount * 0.55, source)
	var attacker: Dictionary = w.heroes[owner]
	attacker["threat"] = float(attacker["threat"]) + amount * 0.52
	attacker["core_damage"] = float(attacker["core_damage"]) + amount
	attacker["score"] = float(attacker["score"]) + amount * 1.5
	w.heroes[owner] = attacker
	w.impact_pos = Vector2(core["pos"])
	w.event_log.emit(w.tick, &"core_hit", owner, target, {"damage":amount, "remaining":maxf(0.0, float(core["hp"]))})
	if float(core["hp"]) <= 0.0:
		core["hp"] = 0.0
		core["alive"] = false
		w.cores[target] = core
		w.event_log.emit(w.tick, &"core_destroyed", owner, target, {})

func award_charge(slot: int, amount: float, source: StringName) -> void:
	if source == &"ultimate" or source == &"mobility" or slot < 0 or slot >= w.heroes.size():
		return
	var h: Dictionary = w.heroes[slot]
	if source == &"equipment":
		h["equipment_hits"] = int(h["equipment_hits"]) + 1
	else:
		h["normal_hits"] = int(h["normal_hits"]) + 1
	h["ultimate_charge"] = minf(w.ULTIMATE_MAX, float(h.get("ultimate_charge", 0.0)) + maxf(4.0, amount * 0.12))
	w.heroes[slot] = h

func heal_hero(slot: int, amount: float) -> void:
	var h: Dictionary = w.heroes[slot]
	if not bool(h["alive"]):
		return
	var before = float(h["hp"])
	h["hp"] = minf(float(h["max_hp"]), before + amount)
	w.heroes[slot] = h
	var gained = float(h["hp"]) - before
	if gained > 0.4:
		w.event_log.emit(w.tick, &"hero_heal", slot, -1, {"amount": gained})

func damage_hero_environment(target: int, amount: float, show_tick: bool, source: StringName = &"environment") -> void:
	var h: Dictionary = w.heroes[target]
	if not bool(h["alive"]) or amount <= 0.0:
		return
	var zone_amt = amount
	if bool(h.get("downed", false)):
		zone_amt *= 3.0
	h["hp"] = float(h["hp"]) - zone_amt
	w.heroes[target] = h
	if show_tick:
		if source == &"safe_zone":
			w.proj.add_effect(&"zone_impact", Vector2(h["pos"]), 68.0, 0.28, Color("#c65cff"), "ZONE", Vector2.RIGHT, target)
		else:
			w.proj.add_effect(&"hit_spark", Vector2(h["pos"]), 36.0, 0.18, Color("#ff4f68"), "")
		w.event_log.emit(w.tick, &"hero_hit", -1, target, {"damage":w.SAFE_ZONE_DAMAGE_PER_SEC * w.SAFE_ZONE_TICK_INTERVAL, "source":source})
	w.lifecycle.apply_lethal_or_down(-1, target, zone_amt)
