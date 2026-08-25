class_name MatchLifecycle
extends RefCounted

var w

func _init(world) -> void:
	w = world

func _decay_ui_ticks(dt: float) -> void:
	w.callout_ticks = maxi(0, w.callout_ticks - 1)
	w.impact_ticks = maxi(0, w.impact_ticks - 1)
	w.local_hit_shake = maxi(0, w.local_hit_shake - 1)
	w.local_fire_shake = maxi(0, w.local_fire_shake - 1)
	w.last_down_ticks = maxi(0, w.last_down_ticks - 1)
	w.streak_callout_ticks = maxi(0, w.streak_callout_ticks - 1)
	w.ultimate_focus_time = maxf(0.0, w.ultimate_focus_time - dt)
	if w.ultimate_focus_time <= 0.0:
		w.ultimate_focus_slot = -1

func update_post_match_visuals(dt: float) -> void:
	w.tick += 1
	_decay_ui_ticks(dt)
	for index in range(w.heroes.size()):
		var hero: Dictionary = w.heroes[index]
		hero["launch_time"] = 0.0
		hero["launch_vel"] = Vector2.ZERO
		hero["launch_trail_fade"] = maxf(0.0, float(hero.get("launch_trail_fade", 0.0)) - dt)
		if float(hero["launch_trail_fade"]) <= 0.0:
			hero["launch_trail"] = []
		w.heroes[index] = hero
	w.mov.update_knockouts(dt)
	w.proj.update_effects(dt)

func update_timers(dt: float) -> void:
	_decay_ui_ticks(dt)
	for i in range(w.heroes.size()):
		var h: Dictionary = w.heroes[i]
		h["fire_cd"] = maxf(0.0, float(h["fire_cd"]) - dt)
		h["spray_idle"] = float(h.get("spray_idle", 0.0)) + dt
		if float(h["spray_idle"]) > 0.14:
			var eqd: Dictionary = h["equipment"]
			var eq_id = str(eqd.get("id", "burst"))
			h["spray_index"] = maxf(0.0, float(h.get("spray_index", 0.0)) - dt * w.GunSig.spray_recover_rate(eq_id))
		h["equipment_cd"] = maxf(0.0, float(h["equipment_cd"]) - dt)
		h["mobility_cd"] = maxf(0.0, float(h["mobility_cd"]) - dt)
		var previous_hop: float = float(h.get("hop_time", 0.0))
		h["hop_time"] = maxf(0.0, previous_hop - dt)
		if previous_hop > 0.0 and float(h["hop_time"]) <= 0.0:
			h["hop_lock"] = w.HOP_LOCK
		else:
			h["hop_lock"] = maxf(0.0, float(h.get("hop_lock", 0.0)) - dt)
		h["guard_time"] = maxf(0.0, float(h["guard_time"]) - dt)
		h["super_armor_time"] = maxf(0.0, float(h["super_armor_time"]) - dt)
		if float(h["super_armor_time"]) <= 0.0:
			h["super_armor_strength"] = 0.0
		h["evade_time"] = maxf(0.0, float(h["evade_time"]) - dt)
		h["slide_time"] = maxf(0.0, float(h.get("slide_time", 0.0)) - dt)
		h["pull_time"] = maxf(0.0, float(h.get("pull_time", 0.0)) - dt)
		h["pocket_time"] = maxf(0.0, float(h.get("pocket_time", 0.0)) - dt)
		h["spring_time"] = maxf(0.0, float(h.get("spring_time", 0.0)) - dt)
		h["hitstun_time"] = maxf(0.0, float(h["hitstun_time"]) - dt)
		if float(h["launch_time"]) > 0.0:
			h["launch_trail_fade"] = 0.34
		else:
			h["launch_trail_fade"] = maxf(0.0, float(h.get("launch_trail_fade", 0.0)) - dt)
			if float(h["launch_trail_fade"]) <= 0.0:
				h["launch_trail"] = []
		h["combo_capture_time"] = maxf(0.0, float(h["combo_capture_time"]) - dt)
		h["attack_lock_time"] = maxf(0.0, float(h["attack_lock_time"]) - dt)
		var previous_normal_chain = float(h["normal_chain_time"])
		h["normal_chain_time"] = maxf(0.0, previous_normal_chain - dt)
		if previous_normal_chain > 0.0 and float(h["normal_chain_time"]) <= 0.0:
			h["normal_step"] = 0
			h["combo_target"] = -1
		h["combo_immunity"] = maxf(0.0, float(h["combo_immunity"]) - dt)
		var previous_combo_time = float(h["combo_time"])
		h["combo_time"] = maxf(0.0, previous_combo_time - dt)
		if previous_combo_time > 0.0 and float(h["combo_time"]) <= 0.0:
			h["combo_hits"] = 0
			h["combo_damage"] = 0.0
			h["combo_owner"] = -1
			h["combo_immunity"] = maxf(float(h["combo_immunity"]), 0.58)
		h["target_hold"] = maxf(0.0, float(h["target_hold"]) - dt)
		h["cc_time"] = maxf(0.0, float(h["cc_time"]) - dt)
		h["root_time"] = maxf(0.0, float(h["root_time"]) - dt)
		h["stun_time"] = maxf(0.0, float(h["stun_time"]) - dt)
		h["flee_time"] = maxf(0.0, float(h.get("flee_time", 0.0)) - dt)
		h["wall_hit_cd"] = maxf(0.0, float(h["wall_hit_cd"]) - dt)
		if not bool(h["alive"]) or float(h["stun_time"]) > 0.0 or float(h["launch_time"]) > 0.0:
			h["reload_left"] = 0.0
		elif float(h.get("reload_left", 0.0)) > 0.0:
			h["reload_left"] = maxf(0.0, float(h["reload_left"]) - dt)
			if float(h["reload_left"]) <= 0.0:
				var mag_cap = int(h["equipment"].get("mag_size", 1))
				h["mag"] = mag_cap
				h["reload_flash"] = 0.55
				h["action"] = &"RELOADED"
		h["reload_flash"] = maxf(0.0, float(h.get("reload_flash", 0.0)) - dt)
		h["hit_flash"] = maxf(0.0, float(h.get("hit_flash", 0.0)) - dt)
		h["muzzle_time"] = maxf(0.0, float(h.get("muzzle_time", 0.0)) - dt)
		h["dmg_orb_time"] = maxf(0.0, float(h.get("dmg_orb_time", 0.0)) - dt)
		h["spawn_protect_time"] = maxf(0.0, float(h.get("spawn_protect_time", 0.0)) - dt)
		w.heroes[i] = h
		w.roul.tick_roulette(i, dt)
		h = w.heroes[i]

func note_life_hitter(target: int, owner: int) -> void:
	note_life_damage(target, owner, 1.0)

func note_life_damage(target: int, owner: int, amount: float) -> void:
	if owner < 0 or owner == target or target < 0 or target >= w.heroes.size():
		return
	if amount <= 0.5:
		return
	var h: Dictionary = w.heroes[target]
	var hits: Dictionary = h.get("life_hits", {})
	var key = str(owner)
	var rec: Dictionary = hits.get(key, {"dmg": 0.0, "tick": 0})
	rec["dmg"] = float(rec.get("dmg", 0.0)) + amount
	rec["tick"] = w.tick
	hits[key] = rec
	h["life_hits"] = hits
	w.heroes[target] = h

func assist_slots(owner: int, target: int, hits: Dictionary) -> Array:
	var need = 28.0
	if target >= 0 and target < w.heroes.size():
		need = maxf(28.0, float(w.heroes[target]["max_hp"]) * 0.25)
	elif target < 0 and bool(w.mid_tower.get("spawned", false)):
		need = maxf(28.0, float(w.mid_tower.get("max_hp", w.TOWER_MAX_HP)) * 0.18)
	var window = int(8.0 / w.FIXED_DT)
	var out: Array = []
	for key in hits.keys():
		var slot = int(key)
		if slot == owner or slot == target:
			continue
		if slot < 0 or slot >= w.heroes.size() or not bool(w.heroes[slot]["alive"]):
			continue
		var rec: Dictionary = hits[key]
		if float(rec.get("dmg", 0.0)) + 0.001 < need:
			continue
		if w.tick - int(rec.get("tick", 0)) > window:
			continue
		out.append(slot)
	return out

func respawn_delay_for(slot: int) -> float:
	var rows: Array[Dictionary] = []
	for i in range(w.heroes.size()):
		if i == slot or not bool(w.heroes[i]["eliminated"]):
			rows.append({"slot":i, "score":float(w.heroes[i]["score"]), "kills":int(w.heroes[i]["kills"])})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if absf(float(a["score"]) - float(b["score"])) > 0.01:
			return float(a["score"]) > float(b["score"])
		if int(a["kills"]) != int(b["kills"]):
			return int(a["kills"]) > int(b["kills"])
		return int(a["slot"]) < int(b["slot"])
	)
	var rank_from_top = 0
	for i in range(rows.size()):
		if int(rows[i]["slot"]) == slot:
			rank_from_top = i
			break
	var from_last = maxi(0, rows.size() - 1 - rank_from_top)
	return minf(w.RESPAWN_MAX, w.RESPAWN_BASE + w.RESPAWN_RANK_STEP * float(from_last))

func respawn_point(slot: int) -> Vector2:
	var home: Vector2 = w.heroes[slot].get("spawn_pos", w.ARENA_CENTER)
	if home.distance_to(w.safe_zone_center) <= maxf(40.0, w.safe_zone_radius - w.HERO_RADIUS - 12.0):
		return w.arena.nudge_out_of_cover(w.arena.clamp_arena_point(home, w.HERO_RADIUS), w.HERO_RADIUS)
	var outward: Vector2 = w.safe_zone_center.direction_to(home)
	if outward.length_squared() < 0.01:
		outward = Vector2.RIGHT
	var safe_pos: Vector2 = w.safe_zone_center + outward * maxf(36.0, w.safe_zone_radius - 80.0)
	return w.arena.nudge_out_of_cover(w.arena.clamp_arena_point(safe_pos, w.HERO_RADIUS), w.HERO_RADIUS)

func update_respawns(dt: float) -> void:
	for slot in range(w.heroes.size()):
		var h: Dictionary = w.heroes[slot]
		if bool(h["eliminated"]) or bool(h["alive"]):
			continue
		h["respawn_left"] = maxf(0.0, float(h.get("respawn_left", 0.0)) - dt)
		h["respawn"] = float(h["respawn_left"])
		if float(h["respawn_left"]) > 0.0:
			w.heroes[slot] = h
			continue
		var spawn_pos: Vector2 = respawn_point(slot)
		h["pos"] = spawn_pos
		h["alive"] = true
		h["hp"] = float(h["max_hp"])
		h["mag"] = int(h["equipment"].get("mag_size", 1))
		h["reload_left"] = 0.0
		h["stun_time"] = 0.0
		h["cc_time"] = 0.0
		h["root_time"] = 0.0
		h["hitstun_time"] = 0.0
		h["launch_time"] = 0.0
		h["launch_vel"] = Vector2.ZERO
		h["launch_trail"] = []
		h["vel"] = Vector2.ZERO
		h["spawn_protect_time"] = 3.0
		h["downed"] = false
		h["down_left"] = 0.0
		h["down_taken"] = 0.0
		h["life_hitters"] = []
		h["life_hits"] = {}
		h["action"] = &"RESPAWN"
		w.heroes[slot] = h
		w.proj.add_effect(&"respawn", spawn_pos, 70.0, 0.45, Color("#b9f3ff"), "RESPAWN")
		w.event_log.emit(w.tick, &"hero_respawned", slot, -1, {"revives_used":int(h.get("revives_used", 0))})

func standing_leader() -> int:
	var best = -1
	var best_score = -999999.0
	var best_kills = -1
	for slot in range(w.heroes.size()):
		if bool(w.heroes[slot]["eliminated"]):
			continue
		var score = float(w.heroes[slot]["score"])
		var kills = int(w.heroes[slot]["kills"])
		var better = false
		if best < 0:
			better = true
		elif score > best_score + 0.01:
			better = true
		elif absf(score - best_score) <= 0.01 and kills > best_kills:
			better = true
		elif absf(score - best_score) <= 0.01 and kills == best_kills and slot < best:
			better = true
		if better:
			best = slot
			best_score = score
			best_kills = kills
	return best

func show_streak_callout(title: String, subtitle: String, shutdown: bool) -> void:
	w.streak_callout = title
	w.streak_subtitle = subtitle
	w.streak_callout_shutdown = shutdown
	w.streak_callout_ticks = 150

func streak_title(streak: int) -> String:
	if streak >= 6:
		return tr("STREAK_UNSTOPPABLE")
	if streak == 5:
		return tr("STREAK_RAMPAGE")
	if streak == 4:
		return tr("STREAK_MASSACRE")
	if streak == 3:
		return tr("STREAK_KILLING_SPREE")
	return tr("STREAK_DOUBLE_KILL")

func apply_lethal_or_down(owner: int, target: int, extra: float) -> void:
	if target < 0 or target >= w.heroes.size():
		return
	var h: Dictionary = w.heroes[target]
	if not bool(h.get("alive", false)):
		return
	if bool(h.get("downed", false)):
		h["hp"] = 0.0
		h["down_taken"] = float(h.get("down_taken", 0.0)) + maxf(0.0, extra)
		w.heroes[target] = h
		if float(h["down_taken"]) >= w.DOWN_FINISH_HP:
			down_hero(owner, target)
		return
	if float(h.get("hp", 0.0)) <= 0.0:
		enter_down(owner, target)

func enter_down(owner: int, target: int) -> void:
	var h: Dictionary = w.heroes[target]
	if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
		return
	h["downed"] = true
	h["down_left"] = w.DOWN_BLEED_TIME
	h["down_taken"] = 0.0
	h["combo_damage"] = 0.0
	h["combo_time"] = 0.0
	h["hp"] = 0.0
	h["vel"] = Vector2.ZERO
	h["launch_time"] = 0.0
	h["launch_vel"] = Vector2.ZERO
	h["ult_clones"] = []
	h["ult_clone_time"] = 0.0
	h["charging_skill"] = false
	w.heroes[target] = h
	w.last_down_slot = target
	w.last_down_ticks = 90
	w.proj.add_effect(&"hit_spark", Vector2(h["pos"]), 70.0, 0.35, Color("#ff8d93"), "DOWN")
	if owner >= 0:
		w._announce("P%d DOWNED P%d" % [owner + 1, target + 1], 70)
		w.event_log.emit(w.tick, &"hero_bled", owner, target, {})
	else:
		w._announce("P%d DOWNED" % [target + 1], 70)
		w.event_log.emit(w.tick, &"hero_bled", -1, target, {})

func stand_up(slot: int) -> void:
	var h: Dictionary = w.heroes[slot]
	if not bool(h.get("downed", false)):
		return
	h["downed"] = false
	h["down_left"] = 0.0
	h["down_taken"] = 0.0
	h["alive"] = true
	h["hp"] = maxf(1.0, float(h["max_hp"]) * 0.5)
	h["spawn_protect_time"] = 1.2
	h["vel"] = Vector2.ZERO
	w.heroes[slot] = h
	w.proj.add_effect(&"respawn", Vector2(h["pos"]), 56.0, 0.40, Color("#6ef3a5"), "UP")
	w.event_log.emit(w.tick, &"hero_stood", slot, -1, {})

func tick_downs(dt: float) -> void:
	for slot in range(w.heroes.size()):
		var h: Dictionary = w.heroes[slot]
		if not bool(h.get("downed", false)):
			continue
		if not bool(h.get("alive", false)):
			h["downed"] = false
			w.heroes[slot] = h
			continue
		var cine_vic = bool(w.finish_cine.get("on", false)) and slot == int(w.finish_cine.get("vic", -1))
		if cine_vic:
			h["down_left"] = maxf(0.12, float(h.get("down_left", 0.0)))
			w.heroes[slot] = h
			continue
		h["down_left"] = maxf(0.0, float(h.get("down_left", 0.0)) - dt)
		w.heroes[slot] = h
		if float(h["down_left"]) <= 0.0:
			if not w._szl.hero_in_safe_zone(slot):
				down_hero(-1, slot)
			else:
				stand_up(slot)

func down_hero(owner: int, target: int) -> void:
	var h: Dictionary = w.heroes[target]
	var defeated_streak = int(h.get("kill_streak", 0))
	var death_velocity: Vector2 = h["launch_vel"]
	if death_velocity.length() < 450.0:
		var death_direction = Vector2.RIGHT.rotated(float(target) * TAU / float(w.PLAYER_COUNT))
		if owner >= 0 and owner < w.heroes.size():
			death_direction = Vector2(w.heroes[owner]["pos"]).direction_to(Vector2(h["pos"]))
			if death_direction.length_squared() < 0.1:
				death_direction = Vector2.RIGHT.rotated(float(target) * TAU / float(w.PLAYER_COUNT))
		elif Vector2(h["pos"]).distance_squared_to(w.safe_zone_center) > 1.0:
			death_direction = w.safe_zone_center.direction_to(Vector2(h["pos"]))
		death_velocity = death_direction * 1550.0
	else:
		death_velocity = death_velocity.normalized() * maxf(1550.0, death_velocity.length() * 1.35)
	w.knockouts.append({"slot":target, "pos":Vector2(h["pos"]), "vel":death_velocity, "time":2.15, "max_time":2.15, "bounces":0, "finished":false, "trail":[Vector2(h["pos"])], "equipment":str(h["equipment"]["id"])})
	var death_drop = str(h.get("held_item", ""))
	var death_pos: Vector2 = h["pos"]
	h["alive"] = false
	h["hp"] = 0.0
	h["downed"] = false
	h["down_left"] = 0.0
	h["down_taken"] = 0.0
	h["spawn_protect_time"] = 0.0
	var bounty_victim = (target == w.wanted_slot)
	var life_hits: Dictionary = h.get("life_hits", {})
	w.roul.clear_roulette_buffs(h)
	h["life_hitters"] = []
	h["life_hits"] = {}
	var used = int(h.get("revives_used", 0))
	var final_out = used >= w.MAX_REVIVES
	if final_out:
		h["eliminated"] = true
		h["respawn"] = 0.0
		h["respawn_left"] = 0.0
	else:
		h["eliminated"] = false
		h["revives_used"] = used + 1
		var wait = respawn_delay_for(target)
		h["respawn"] = wait
		h["respawn_left"] = wait
	h["vel"] = Vector2.ZERO
	h["launch_vel"] = Vector2.ZERO
	h["launch_time"] = 0.0
	h["launch_trail"] = []
	h["launch_trail_fade"] = 0.0
	h["hitstun_time"] = 0.0
	h["combo_capture_time"] = 0.0
	h["combo_hits"] = 0
	h["combo_time"] = 0.0
	h["combo_damage"] = 0.0
	h["normal_step"] = 0
	h["normal_chain_time"] = 0.0
	h["combo_target"] = -1
	h["attack_lock_time"] = 0.0
	h["charging_skill"] = false
	h["charge_time"] = 0.0
	h["reload_left"] = 0.0
	h["reload_flash"] = 0.0
	h["deaths"] = int(h["deaths"]) + 1
	h["kill_streak"] = 0
	h["held_item"] = ""
	h["slide_time"] = 0.0
	h["pull_time"] = 0.0
	h["pocket_time"] = 0.0
	h["spring_time"] = 0.0
	w.heroes[target] = h
	if w.mode == w.ITEM_POOL_MODE and death_drop != "" and death_drop != "decoy":
		w.act_item.spawn_dropped_pickup(death_pos, death_drop, -1)
	w.proj.add_effect(&"death_burst", Vector2(h["pos"]), 260.0, 0.80, Color("#ff3349"), "", death_velocity.normalized())
	w.impact_ticks = maxi(w.impact_ticks, 32)
	w.last_down_slot = target
	w.last_down_ticks = 105
	var reward = _reward_attacker(owner, target, defeated_streak, bounty_victim, life_hits, h)
	var streak_after = int(reward["streak_after"])
	var shutdown_bonus = float(reward["shutdown_bonus"])
	w.impact_pos = Vector2(h["pos"])
	w.event_log.emit(w.tick, &"hero_downed", owner, target, {"streak":streak_after, "ended_streak":defeated_streak, "shutdown_bonus":shutdown_bonus, "revives_used":int(h.get("revives_used", 0)), "eliminated":bool(h["eliminated"])})
	if bool(h["eliminated"]):
		w.event_log.emit(w.tick, &"player_eliminated", owner, target, {"source":&"death"})
		if owner >= 0:
			w._announce("P%d ELIMINATED P%d!" % [owner + 1, target + 1], 140)
		else:
			w._announce("P%d ELIMINATED BY ZONE!" % [target + 1], 140)
	else:
		if owner >= 0:
			w._announce("P%d DOWNED P%d" % [owner + 1, target + 1], 90)
		else:
			w._announce("P%d DOWNED BY ZONE" % [target + 1], 90)
	w.impact_ticks = maxi(w.impact_ticks, 32)

func eliminate(owner: int, target: int) -> void:
	var core: Dictionary = w.cores[target]
	core["alive"] = false
	core["hp"] = 0.0
	w.cores[target] = core
	var h: Dictionary = w.heroes[target]
	h["alive"] = false
	h["eliminated"] = true
	h["vel"] = Vector2.ZERO
	h["target"] = -1
	w.heroes[target] = h
	var attacker: Dictionary = w.heroes[owner]
	attacker["bounty"] = maxf(0.0, float(attacker["bounty"]) - 15.0)
	attacker["eliminations"] = int(attacker["eliminations"]) + 1
	attacker["score"] = float(attacker["score"]) + 300.0
	w.heroes[owner] = attacker
	w.event_log.emit(w.tick, &"player_eliminated", owner, target, {})
	w.impact_ticks = 16
	w._announce("P%d ELIMINATED P%d!" % [owner + 1, target + 1], 140)

func update_threat(dt: float) -> void:
	for i in range(w.heroes.size()):
		var h: Dictionary = w.heroes[i]
		h["threat"] = maxf(0.0, float(h["threat"]) - dt * 2.3)
		h["bounty"] = maxf(0.0, float(h["bounty"]) - dt * 0.22)
		h["grudge"] = maxf(0.0, float(h["grudge"]) - dt * 0.05)
		w.heroes[i] = h
	var new_wanted = standing_leader()
	if new_wanted != w.wanted_slot and new_wanted >= 0:
		w.wanted_slot = new_wanted
		w._announce("WANTED P%d" % (w.wanted_slot + 1), 90)
		w.event_log.emit(w.tick, &"bounty_moved", w.wanted_slot, -1, {"score":float(w.heroes[w.wanted_slot]["score"])})

func _reward_attacker(owner: int, target: int, defeated_streak: int, bounty_victim: bool, life_hits: Dictionary, victim: Dictionary) -> Dictionary:
	if owner < 0 or owner >= w.heroes.size() or owner == target:
		return {"streak_after":0, "shutdown_bonus":0.0}
	var streak_after = 0
	var shutdown_bonus = 0.0
	var attacker: Dictionary = w.heroes[owner]
	attacker["kills"] = int(attacker["kills"]) + 1
	attacker["eliminations"] = int(attacker["eliminations"]) + 1
	attacker["score"] = float(attacker["score"]) + 120.0
	attacker["bounty"] = float(attacker["bounty"]) + 12.0
	attacker["threat"] = float(attacker["threat"]) + 18.0
	if bool(attacker["alive"]):
		streak_after = int(attacker.get("kill_streak", 0)) + 1
		attacker["kill_streak"] = streak_after
		attacker["best_kill_streak"] = maxi(int(attacker.get("best_kill_streak", 0)), streak_after)
		var momentum_heal = float(attacker["max_hp"]) * minf(0.10, 0.055 + float(streak_after) * 0.01)
		attacker["hp"] = minf(float(attacker["max_hp"]), float(attacker["hp"]) + momentum_heal)
		attacker["equipment_cd"] = maxf(0.0, float(attacker["equipment_cd"]) - (0.50 + float(streak_after) * 0.10))
		attacker["mobility_cd"] = maxf(0.0, float(attacker["mobility_cd"]) - (0.35 + float(streak_after) * 0.08))
		attacker["ultimate_charge"] = minf(w.ULTIMATE_MAX, float(attacker.get("ultimate_charge", 0.0)) + 35.0)
		attacker["score"] = float(attacker["score"]) + maxf(0.0, float(streak_after - 1) * 15.0)
	if defeated_streak >= 3:
		shutdown_bonus = minf(230.0, 90.0 + float(defeated_streak - 3) * 35.0)
		attacker["score"] = float(attacker["score"]) + shutdown_bonus
		attacker["bounty"] = maxf(0.0, float(attacker["bounty"]) - 20.0)
		if bool(attacker["alive"]):
			attacker["hp"] = minf(float(attacker["max_hp"]), float(attacker["hp"]) + float(attacker["max_hp"]) * 0.14)
			attacker["equipment_cd"] *= 0.50
			attacker["mobility_cd"] *= 0.50
			attacker["ultimate_charge"] = minf(w.ULTIMATE_MAX, float(attacker.get("ultimate_charge", 0.0)) + 20.0)
		var attacker_name = str(attacker["equipment"]["character_name"])
		var defeated_name = str(victim["equipment"]["character_name"])
		show_streak_callout(tr("STREAK_ENDED"), tr("STREAK_ENDED_MSG") % [owner + 1, attacker_name, target + 1, defeated_name, defeated_streak], true)
		w.event_log.emit(w.tick, &"streak_shutdown", owner, target, {"streak":defeated_streak, "bonus":shutdown_bonus})
	elif streak_after >= 2:
		var streak_attacker_name = str(attacker["equipment"]["character_name"])
		show_streak_callout(streak_title(streak_after), tr("STREAK_ONGOING") % [owner + 1, streak_attacker_name, streak_after], false)
		w.event_log.emit(w.tick, &"kill_streak", owner, target, {"streak":streak_after})
	attacker = w.act_item.try_gun_loot(owner, attacker)
	w.heroes[owner] = attacker
	w.roul.grant_kill_roulettes(owner, target, bounty_victim, life_hits)
	return {"streak_after":streak_after, "shutdown_bonus":shutdown_bonus}

