class_name HeroMovement
extends RefCounted

var w

func _init(world) -> void:
	w = world

func apply_human(command: Dictionary) -> void:
	if w.heroes.is_empty():
		return
	var ls: int = clampi(w.local_slot, 0, w.heroes.size() - 1)
	if bool(command.get("finish", false)):
		if bool(w.finish_cine.get("on", false)):
			w.ult_effect.cancel_finish_cine()
			return
		w.ult_effect.try_begin_finish(ls)
	if bool(w.finish_cine.get("on", false)):
		return
	var h: Dictionary = w.heroes[ls]
	var emote := int(command.get("emote", -1))
	if emote >= 0 and emote < 4:
		h["emote"] = emote; h["emote_time"] = 2.0; w.heroes[ls] = h
	if bool(h["eliminated"]):
		w.heroes[ls] = h
		return
	if not bool(h["alive"]):
		w.heroes[ls] = h
		return
	if bool(h.get("burrowed", false)):
		lock_locomotion(h)
		w.heroes[ls] = h
		return
	if bool(h.get("dog_rush", false)):
		w.heroes[ls] = h
		if bool(command.get("ultimate", false)):
			w.ult_animal.try_ultimate(ls, Vector2(command.get("aim", Vector2(h["pos"]) + Vector2(h["facing"]))))
		return
	if bool(h.get("downed", false)):
		var crawl: Vector2 = command.get("move", Vector2.ZERO)
		if crawl.length_squared() > 1.0:
			crawl = crawl.normalized()
		apply_locomotion(h, crawl, hero_move_speed(ls) * 0.16, w.FIXED_DT, &"down")
		w.heroes[ls] = h
		return
	if float(h["launch_time"]) > 0.0:
		lock_locomotion(h)
		w.heroes[ls] = h
		return
	var move: Vector2 = command.get("move", Vector2.ZERO)
	if move.length_squared() > 1.0:
		move = move.normalized()
	var aim_pos: Vector2 = command.get("aim", Vector2(h["pos"]) + Vector2(h["facing"]))
	if Vector2(h["pos"]).distance_squared_to(aim_pos) > 4.0:
		h["facing"] = Vector2(h["pos"]).direction_to(aim_pos)
		h["aim"] = h["facing"]
	var control_speed := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
	if float(h["root_time"]) > 0.0:
		control_speed = 0.0
	if float(h["stun_time"]) > 0.0:
		lock_locomotion(h)
		h["charging_skill"] = false
		h["charge_time"] = 0.0
		w.heroes[ls] = h
		return
	if float(h["hitstun_time"]) > 0.0:
		control_speed *= 0.72
	elif float(h["combo_capture_time"]) > 0.0:
		control_speed *= 0.72
	if float(h["attack_lock_time"]) > 0.0:
		control_speed *= 0.76
	if bool(h["charging_skill"]):
		control_speed *= 0.62
	if float(h.get("slide_time", 0.0)) > 0.0:
		w.act_item.steer_slide(ls, h, move, control_speed, w.FIXED_DT)
		mark_slide_locomotion(h)
	else:
		var max_spd: float = hero_move_speed(ls) * control_speed * w.dmg.streak_move_multiplier(ls)
		apply_locomotion(h, move, max_spd, w.FIXED_DT, &"run")
		if float(h.get("spring_time", 0.0)) > 0.0:
			var boost_dir: Vector2 = move
			if boost_dir.length_squared() < 0.1:
				boost_dir = Vector2(h["facing"])
			if boost_dir.length_squared() > 0.1:
				h["vel"] = Vector2(h["vel"]) + boost_dir.normalized() * w.SPRING_BOOST
	if bool(command.get("hop", false)) and not w.roul.hero_has_timed(h, "turtle"):
		var hop_ready: bool = float(h.get("hop_time", 0.0)) <= 0.0 and float(h.get("hop_lock", 0.0)) <= 0.0
		if hop_ready and float(h["root_time"]) <= 0.0:
			h["hop_time"] = w.HOP_AIR
			h["hop_max"] = w.HOP_AIR
			h["hop_height"] = w.HOP_LIFT_DEFAULT
	w.heroes[ls] = h
	if bool(command.get("medkit", false)) and not w.roul.hero_has_timed(h, "turtle"):
		w.act_item.try_use_active_item(ls)
	if bool(command.get("ultimate", false)) and not w.roul.hero_has_timed(h, "turtle"):
		w.ult_animal.try_ultimate(ls, Vector2(command.get("aim", Vector2(h["pos"]) + Vector2(h["facing"]))))
		h = w.heroes[ls]
	if bool(command.get("mobility", false)) and not w.roul.hero_has_timed(h, "turtle"):
		w.act_item.cancel_skill_charge(ls)
		w.act_item.try_mobility(ls, move if move.length_squared() > 0.1 else Vector2(h["facing"]))
		return
	if bool(command.get("reload", false)) and not w.roul.hero_has_timed(h, "turtle"):
		w.dmg.try_start_reload(ls)
		h = w.heroes[ls]
	var fire_mode := str(h["equipment"].get("fire_mode", "auto"))
	var want_fire := bool(command.get("primary", false))
	if fire_mode != "auto":
		want_fire = bool(command.get("primary_pressed", false))
	if want_fire:
		w.act_item.cancel_skill_charge(ls)
		w.dmg.try_normal_attack(ls, Vector2(h["facing"]))
		return

func apply_peer_humans() -> void:
	var consumed: Array = []
	for slot_key in w.peer_commands:
		var slot := int(slot_key)
		if slot == w.local_slot or slot < 0 or slot >= w.heroes.size():
			continue
		if not w.human_slots.has(slot):
			continue
		consumed.append(slot_key)
		var cmd: Dictionary = w.peer_commands[slot_key]
		var h: Dictionary = w.heroes[slot]
		var emote := int(cmd.get("emote", -1))
		if emote >= 0 and emote < 4:
			h["emote"] = emote; h["emote_time"] = 2.0; w.heroes[slot] = h
		if bool(h["eliminated"]) or not bool(h["alive"]):
			continue
		if bool(h.get("downed", false)):
			var crawl := Vector2(float(cmd.get("mx", 0)), float(cmd.get("my", 0)))
			if crawl.length_squared() > 1.0:
				crawl = crawl.normalized()
			apply_locomotion(h, crawl, hero_move_speed(slot) * 0.16, w.FIXED_DT, &"down")
			w.heroes[slot] = h
			continue
		if float(h["stun_time"]) > 0.0 or float(h["launch_time"]) > 0.0:
			continue
		if bool(h.get("burrowed", false)) or bool(h.get("dog_rush", false)):
			continue
		var move := Vector2(float(cmd.get("mx", 0)), float(cmd.get("my", 0)))
		if move.length_squared() > 1.0:
			move = move.normalized()
		var aim_pos := Vector2(float(cmd.get("aimX", h["pos"].x + 1.0)), float(cmd.get("aimY", h["pos"].y)))
		if Vector2(h["pos"]).distance_squared_to(aim_pos) > 4.0:
			h["facing"] = Vector2(h["pos"]).direction_to(aim_pos)
			h["aim"] = h["facing"]
		var control_speed := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
		if float(h["root_time"]) > 0.0:
			control_speed = 0.0
		if float(h["hitstun_time"]) > 0.0:
			control_speed *= 0.72
		if float(h["attack_lock_time"]) > 0.0:
			control_speed *= 0.76
		apply_locomotion(h, move, hero_move_speed(slot) * control_speed, w.FIXED_DT, &"run")
		w.heroes[slot] = h
		if bool(cmd.get("dash", false)) and float(h["mobility_cd"]) <= 0.0:
			w.act_item.try_mobility(slot, Vector2(h["facing"]))
		if bool(cmd.get("use", false)) and int(h.get("medkits", 0)) > 0:
			w.act_item.try_use_medkit(slot)
		if bool(cmd.get("fire", false)):
			w.dmg.try_normal_attack(slot, Vector2(h["facing"]))
	for slot in w.human_slots:
		if slot == w.local_slot or slot < 0 or slot >= w.heroes.size():
			continue
		if not consumed.has(slot) and not w.peer_commands.has(slot):
			var h: Dictionary = w.heroes[slot]
			if bool(h["alive"]) and not bool(h["eliminated"]):
				lock_locomotion(h)
				w.heroes[slot] = h
	for key in consumed:
		w.peer_commands.erase(key)

func move_heroes(dt: float) -> void:
	for i in range(w.heroes.size()):
		var h: Dictionary = w.heroes[i]
		if not bool(h["alive"]):
			continue
		if float(h["launch_time"]) > 0.0:
			move_launched_hero(i, dt)
			continue
		var old_pos: Vector2 = h["pos"]
		var motion: Vector2 = Vector2(h["vel"]) * dt
		var pos = w.arena.resolve_cover_motion(old_pos, motion)
		var wall_hit = w.deploy.deployable_wall_hit(i, old_pos, pos)
		if not wall_hit.is_empty():
			h["pos"] = old_pos
			w.heroes[i] = h
			var wall_normal: Vector2 = wall_hit["normal"]
			w.dmg.damage_hero(int(wall_hit["owner"]), i, float(wall_hit["damage"]), &"equipment", 0.32, float(wall_hit["knockback"]), old_pos - wall_normal * 32.0, "WALL SLAM", &"shield_bash", true)
			var bounced: Dictionary = w.heroes[i]
			bounced["wall_hit_cd"] = 0.78
			w.heroes[i] = bounced
			w.deploy.mark_wall_hit(int(wall_hit["id"]), i)
			w.proj.add_effect(&"wall_impact", Vector2(wall_hit["pos"]), 102.0, 0.30, Color("#8de1ff"), "SLAM", wall_normal)
			continue
		pos.x = clampf(pos.x, w.ARENA_MARGIN + w.HERO_RADIUS, w.ARENA_SIZE.x - w.ARENA_MARGIN - w.HERO_RADIUS)
		pos.y = clampf(pos.y, w.ARENA_MARGIN + w.HERO_RADIUS, w.ARENA_SIZE.y - w.ARENA_MARGIN - w.HERO_RADIUS)
		for core in w.cores:
			if not bool(core["alive"]) or int(core["slot"]) == i:
				continue
			var delta = pos - Vector2(core["pos"])
			var min_dist = w.HERO_RADIUS + w.CORE_RADIUS
			if delta.length_squared() < min_dist * min_dist:
				pos = Vector2(core["pos"]) + delta.normalized() * min_dist
		h["pos"] = pos
		w.heroes[i] = h
	for _pass in range(1):
		for a in range(w.heroes.size()):
			if not bool(w.heroes[a]["alive"]):
				continue
			for b in range(a + 1, w.heroes.size()):
				if not bool(w.heroes[b]["alive"]):
					continue
				var ha: Dictionary = w.heroes[a]
				var hb: Dictionary = w.heroes[b]
				var delta := Vector2(hb["pos"]) - Vector2(ha["pos"])
				var min_dist = w.HERO_RADIUS * 1.4
				if delta.length_squared() < min_dist * min_dist:
					var n := delta.normalized() if delta.length_squared() > 0.001 else Vector2.RIGHT
					var push := minf(2.0, (min_dist - delta.length()) * 0.4)
					ha["pos"] = Vector2(ha["pos"]) - n * push
					hb["pos"] = Vector2(hb["pos"]) + n * push
					w.heroes[a] = ha
				w.heroes[b] = hb

func move_launched_hero(slot: int, dt: float) -> void:
	var h: Dictionary = w.heroes[slot]
	var pos: Vector2 = h["pos"]
	var velocity: Vector2 = h["launch_vel"]
	var motion := velocity * dt
	var min_x = w.ARENA_MARGIN + w.HERO_RADIUS
	var max_x = w.ARENA_SIZE.x - w.ARENA_MARGIN - w.HERO_RADIUS
	var min_y = w.ARENA_MARGIN + w.HERO_RADIUS
	var max_y = w.ARENA_SIZE.y - w.ARENA_MARGIN - w.HERO_RADIUS
	var hit_x = false
	var hit_y = false
	var x_candidate := pos + Vector2(motion.x, 0.0)
	if x_candidate.x < min_x or x_candidate.x > max_x or w.arena.point_in_cover(x_candidate, w.HERO_RADIUS):
		hit_x = true
	else:
		pos.x = x_candidate.x
	var y_candidate := pos + Vector2(0.0, motion.y)
	if y_candidate.y < min_y or y_candidate.y > max_y or w.arena.point_in_cover(y_candidate, w.HERO_RADIUS):
		hit_y = true
	else:
		pos.y = y_candidate.y
	if hit_x or hit_y:
		if hit_x:
			velocity.x *= -0.84
		if hit_y:
			velocity.y *= -0.84
		h["wall_bounces"] = int(h["wall_bounces"]) + 1
		var wall_damage := clampf(9.0 + velocity.length() / 78.0, 15.0, 36.0)
		if float(h["guard_time"]) > 0.0:
			wall_damage *= 0.55
		h["launch_wall_damage"] = float(h["launch_wall_damage"]) + wall_damage
		h["hp"] = float(h["hp"]) - wall_damage
		var launch_owner := int(h["launch_owner"])
		if launch_owner >= 0 and launch_owner != slot:
			var attacker: Dictionary = w.heroes[launch_owner]
			attacker["damage_dealt"] = float(attacker["damage_dealt"]) + wall_damage
			attacker["score"] = float(attacker["score"]) + wall_damage * 1.25
			attacker["threat"] = float(attacker["threat"]) + wall_damage * 0.45
			w.heroes[launch_owner] = attacker
		w.proj.add_effect(&"wall_impact", pos, 78.0, 0.32, Color("#ff774f"), "WALL CRASH -%d" % roundi(wall_damage), -velocity.normalized())
		w.event_log.emit(w.tick, &"wall_bounce", launch_owner, slot, {"damage":wall_damage, "bounce":int(h["wall_bounces"])})
		w.impact_ticks = maxi(w.impact_ticks, 14)
		w.impact_pos = pos
		if float(h["hp"]) <= 0.0:
			h["pos"] = pos
			h["launch_vel"] = velocity
			w.heroes[slot] = h
			w.lifecycle.apply_lethal_or_down(launch_owner if launch_owner >= 0 else slot, slot, 0.0)
			return
		if int(h["wall_bounces"]) >= 3:
			h["launch_time"] = 0.0
			velocity = Vector2.ZERO
	h["launch_time"] = maxf(0.0, float(h["launch_time"]) - dt)
	velocity *= exp(-0.62 * dt)
	h["launch_vel"] = velocity
	h["pos"] = pos
	var trail: Array = h["launch_trail"]
	if w.tick % 2 == 0:
		trail.append(pos)
		if trail.size() > 14:
			trail.pop_front()
	h["launch_trail"] = trail
	if float(h["launch_time"]) <= 0.0 or velocity.length() < 80.0:
		h["launch_time"] = 0.0
		h["launch_vel"] = Vector2.ZERO
	w.heroes[slot] = h

func update_knockouts(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for knockout0 in w.knockouts:
		var knockout: Dictionary = knockout0
		knockout["time"] = float(knockout["time"]) - dt
		if bool(knockout.get("finished", false)):
			if float(knockout["time"]) > 0.0:
				kept.append(knockout)
			continue
		var pos: Vector2 = knockout["pos"]
		var velocity: Vector2 = knockout["vel"]
		var motion := velocity * dt
		var next := pos + motion
		var hit_x = next.x < w.ARENA_MARGIN or next.x > w.ARENA_SIZE.x - w.ARENA_MARGIN or w.arena.point_in_cover(pos + Vector2(motion.x, 0.0), w.HERO_RADIUS)
		var hit_y = next.y < w.ARENA_MARGIN or next.y > w.ARENA_SIZE.y - w.ARENA_MARGIN or w.arena.point_in_cover(pos + Vector2(0.0, motion.y), w.HERO_RADIUS)
		if hit_x or hit_y:
			if hit_x:
				velocity.x *= -0.82
			else:
				pos.x = next.x
			if hit_y:
				velocity.y *= -0.82
			else:
				pos.y = next.y
			knockout["bounces"] = int(knockout["bounces"]) + 1
			w.proj.add_effect(&"wall_impact", pos, 58.0, 0.24, Color("#ff4f5e"), "", -velocity.normalized())
		else:
			pos = next
		velocity *= exp(-0.48 * dt)
		knockout["pos"] = pos
		knockout["vel"] = velocity
		var trail: Array = knockout["trail"]
		if w.tick % 2 == 0:
			trail.append(pos)
			if trail.size() > 20:
				trail.pop_front()
		knockout["trail"] = trail
		if int(knockout["bounces"]) >= 3:
			knockout["finished"] = true
			knockout["vel"] = Vector2.ZERO
			knockout["time"] = minf(float(knockout["time"]), 0.42)
		if float(knockout["time"]) > 0.0:
			kept.append(knockout)
	w.knockouts = kept


func lock_locomotion(h: Dictionary) -> void:
	h["vel"] = Vector2.ZERO
	var prev := str(h.get("move_state", "idle"))
	h["move_state"] = &"locked"
	h["move_lean"] = 0.0
	h["move_plant"] = 0.0
	if prev != "locked" and int(h.get("slot", -1)) == w.local_slot:
		print("[gangup] move_state " + prev + "->locked")


func mark_slide_locomotion(h: Dictionary) -> void:
	h["move_state"] = &"slide"
	h["move_plant"] = 0.0
	_refresh_lean(h, Vector2(h["vel"]), maxf(80.0, Vector2(h["vel"]).length()), &"slide", w.FIXED_DT)


func apply_locomotion(h: Dictionary, wish: Vector2, max_speed: float, dt: float, mode: StringName) -> void:
	if wish.length_squared() > 1.0:
		wish = wish.normalized()
	var vel: Vector2 = h.get("vel", Vector2.ZERO)
	var hopping := float(h.get("hop_time", 0.0)) > 0.0
	if hopping:
		mode = &"hop"
	var has_wish := wish.length_squared() > 0.04 and max_speed > 8.0
	var target := (wish * max_speed) if has_wish else Vector2.ZERO
	var spd := vel.length()
	var accel := 2200.0
	var brake := 3000.0
	if mode == &"down":
		accel = 900.0
		brake = 1400.0
	elif hopping:
		accel = 1400.0
		brake = 700.0
	var reversing := false
	if has_wish and spd > 46.0:
		reversing = vel.normalized().dot(wish) < 0.12
	var state: StringName = &"idle"
	if reversing:
		vel = vel.move_toward(Vector2.ZERO, brake * 1.2 * dt)
		if vel.length() < 48.0:
			vel = vel.move_toward(target, accel * dt)
			state = &"accel"
		else:
			state = &"brake"
	elif not has_wish:
		vel = vel.move_toward(Vector2.ZERO, brake * dt)
		state = &"brake" if spd > 30.0 else &"idle"
	else:
		vel = vel.move_toward(target, accel * dt)
		if vel.length() >= max_speed * 0.86:
			state = &"cruise"
		else:
			state = &"accel"
	if hopping:
		h["move_plant"] = 0.0
	else:
		var prev := str(h.get("move_state", "idle"))
		var plant := float(h.get("move_plant", 0.0))
		if prev == "brake" and state == &"idle":
			plant = 1.0
		elif prev == "idle" and state == &"accel":
			plant = -0.7
		elif plant > 0.0:
			plant = maxf(0.0, plant - dt * 4.8)
		elif plant < 0.0:
			plant = minf(0.0, plant + dt * 5.2)
		h["move_plant"] = plant
	h["vel"] = vel
	var prev_state := str(h.get("move_state", "idle"))
	h["move_state"] = state
	_refresh_lean(h, vel, maxf(max_speed, 80.0), state, dt)
	if mode == &"down":
		h["move_lean"] = float(h.get("move_lean", 0.0)) * 0.4
	if prev_state != str(state) and int(h.get("slot", -1)) == w.local_slot:
		print("[gangup] move_state " + prev_state + "->" + str(state) + " spd=" + str(snapped(vel.length(), 1)) + " mode=" + str(mode))


func _refresh_lean(h: Dictionary, vel: Vector2, ref_speed: float, state: StringName, dt: float) -> void:
	var lean_tgt := 0.0
	if vel.length() > 28.0 and state != &"locked":
		lean_tgt = clampf(vel.x / maxf(ref_speed, 1.0), -1.0, 1.0) * 0.20
		if state == &"accel":
			lean_tgt *= 1.35
		elif state == &"brake":
			lean_tgt *= -0.6
		elif state == &"cruise":
			lean_tgt *= 0.72
		elif state == &"down":
			lean_tgt *= 0.35
	h["move_lean"] = lerpf(float(h.get("move_lean", 0.0)), lean_tgt, 1.0 - exp(-14.0 * dt))


func hero_move_speed(slot: int) -> float:
	if slot < 0 or slot >= w.heroes.size():
		return w.HERO_SPEED
	var speed = float(w.heroes[slot]["equipment"]["move_speed"]) + w.roul.roulette_stat(slot, "spd")
	if posmod(int(w.heroes[slot].get("animal", slot)), 12) == 4 and w.ult_summon.pos_in_dragon_smoke(Vector2(w.heroes[slot]["pos"])):
		speed *= 1.30
	if w.ult_summon.pos_in_enemy_mud(slot):
		speed *= 0.48
	return speed
