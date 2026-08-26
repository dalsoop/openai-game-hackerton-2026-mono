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
	if _human_locked_state(ls, h, command):
		return
	var move: Vector2 = command.get("move", Vector2.ZERO)
	if move.length_squared() > 1.0:
		move = move.normalized()
	var aim_pos: Vector2 = command.get("aim", Vector2(h["pos"]) + Vector2(h["facing"]))
	if Vector2(h["pos"]).distance_squared_to(aim_pos) > 4.0:
		h["facing"] = Vector2(h["pos"]).direction_to(aim_pos)
		h["aim"] = h["facing"]
	_apply_human_motion(ls, h, move, command)
	w.heroes[ls] = h
	_apply_human_actions(ls, command, move)

func _human_locked_state(ls: int, h: Dictionary, command: Dictionary) -> bool:
	if bool(h["eliminated"]):
		w.heroes[ls] = h
		return true
	if not bool(h["alive"]):
		w.heroes[ls] = h
		return true
	if bool(h.get("burrowed", false)):
		h["vel"] = Vector2.ZERO
		w.heroes[ls] = h
		return true
	if bool(h.get("dog_rush", false)):
		w.heroes[ls] = h
		if bool(command.get("ultimate", false)):
			w.ult_animal.try_ultimate(ls, Vector2(command.get("aim", Vector2(h["pos"]) + Vector2(h["facing"]))))
		return true
	if bool(h.get("downed", false)):
		var crawl: Vector2 = command.get("move", Vector2.ZERO)
		if crawl.length_squared() > 1.0:
			crawl = crawl.normalized()
		h["vel"] = crawl * hero_move_speed(ls) * 0.16
		w.heroes[ls] = h
		return true
	if float(h["launch_time"]) > 0.0:
		h["vel"] = Vector2.ZERO
		w.heroes[ls] = h
		return true
	if float(h["stun_time"]) > 0.0:
		h["vel"] = Vector2.ZERO
		h["charging_skill"] = false
		h["charge_time"] = 0.0
		w.heroes[ls] = h
		return true
	return false

func _apply_human_motion(ls: int, h: Dictionary, move: Vector2, command: Dictionary) -> void:
	var control_speed := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
	if float(h["root_time"]) > 0.0:
		control_speed = 0.0
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
	else:
		h["vel"] = move * hero_move_speed(ls) * control_speed * w.dmg.streak_move_multiplier(ls)
		_apply_spring_boost(h, move)
	if bool(command.get("hop", false)) and not w.roul.hero_has_timed(h, "turtle"):
		var hop_ready: bool = float(h.get("hop_time", 0.0)) <= 0.0 and float(h.get("hop_lock", 0.0)) <= 0.0
		if hop_ready and float(h["root_time"]) <= 0.0:
			h["hop_time"] = w.HOP_AIR
			h["hop_max"] = w.HOP_AIR
			h["hop_height"] = w.HOP_LIFT_DEFAULT

func _apply_spring_boost(h: Dictionary, move: Vector2) -> void:
	if float(h.get("spring_time", 0.0)) > 0.0:
		var boost_dir: Vector2 = move
		if boost_dir.length_squared() < 0.1:
			boost_dir = Vector2(h["facing"])
		if boost_dir.length_squared() > 0.1:
			h["vel"] = Vector2(h["vel"]) + boost_dir.normalized() * w.SPRING_BOOST

func _apply_human_actions(ls: int, command: Dictionary, move: Vector2) -> void:
	var h: Dictionary = w.heroes[ls]
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

func apply_peer_humans() -> void:
	var consumed: Array = []
	for slot_key in w.peer_commands:
		var slot := int(slot_key)
		if slot == w.local_slot or slot < 0 or slot >= w.heroes.size():
			continue
		if not w.human_slots.has(slot):
			continue
		consumed.append(slot_key)
		_apply_peer_command(slot, w.peer_commands[slot_key])
	_stop_missing_peers(consumed)
	for key in consumed:
		w.peer_commands.erase(key)

func _apply_peer_command(slot: int, cmd: Dictionary) -> void:
	var h: Dictionary = w.heroes[slot]
	if bool(h["eliminated"]) or not bool(h["alive"]):
		return
	if bool(cmd.get("finish", false)):
		w.ult_effect.try_begin_finish(slot)
		return
	if bool(h.get("downed", false)):
		_apply_peer_downed(slot, h, cmd)
		return
	if float(h["stun_time"]) > 0.0 or float(h["launch_time"]) > 0.0:
		return
	if bool(h.get("burrowed", false)) or bool(h.get("dog_rush", false)):
		if bool(cmd.get("ultimate", false)):
			w.ult_animal.try_ultimate(slot, _peer_aim(cmd, h))
		return
	_apply_peer_motion(slot, h, cmd)
	_apply_peer_actions(slot, cmd)

func _apply_peer_downed(slot: int, h: Dictionary, cmd: Dictionary) -> void:
	var crawl := Vector2(float(cmd.get("mx", 0)), float(cmd.get("my", 0)))
	if crawl.length_squared() > 1.0:
		crawl = crawl.normalized()
	h["vel"] = crawl * hero_move_speed(slot) * 0.16
	w.heroes[slot] = h

func _peer_aim(cmd: Dictionary, h: Dictionary) -> Vector2:
	return Vector2(float(cmd.get("aimX", h["pos"].x + 1.0)), float(cmd.get("aimY", h["pos"].y)))

func _apply_peer_motion(slot: int, h: Dictionary, cmd: Dictionary) -> void:
	var move := Vector2(float(cmd.get("mx", 0)), float(cmd.get("my", 0)))
	if move.length_squared() > 1.0:
		move = move.normalized()
	var aim_pos := _peer_aim(cmd, h)
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
	h["vel"] = move * hero_move_speed(slot) * control_speed
	w.heroes[slot] = h

func _apply_peer_actions(slot: int, cmd: Dictionary) -> void:
	var h: Dictionary = w.heroes[slot]
	if bool(cmd.get("dash", false)) and float(h["mobility_cd"]) <= 0.0:
		w.act_item.try_mobility(slot, Vector2(h["facing"]))
		return
	if bool(cmd.get("use", false)) and int(h.get("medkits", 0)) > 0:
		w.act_item.try_use_medkit(slot)
		h = w.heroes[slot]
	if bool(cmd.get("reload", false)) and not w.roul.hero_has_timed(h, "turtle"):
		w.dmg.try_start_reload(slot)
		h = w.heroes[slot]
	if bool(cmd.get("ultimate", false)) and not w.roul.hero_has_timed(h, "turtle"):
		w.ult_animal.try_ultimate(slot, _peer_aim(cmd, h))
		h = w.heroes[slot]
	_apply_peer_hop(slot, h, cmd)
	_apply_peer_fire(slot, cmd)

func _apply_peer_hop(slot: int, h: Dictionary, cmd: Dictionary) -> void:
	if not bool(cmd.get("hop", false)) or w.roul.hero_has_timed(h, "turtle"):
		return
	var hop_ready: bool = float(h.get("hop_time", 0.0)) <= 0.0 and float(h.get("hop_lock", 0.0)) <= 0.0
	if not hop_ready or float(h["root_time"]) > 0.0:
		return
	h["hop_time"] = w.HOP_AIR
	h["hop_max"] = w.HOP_AIR
	h["hop_height"] = w.HOP_LIFT_DEFAULT
	w.heroes[slot] = h

func _apply_peer_fire(slot: int, cmd: Dictionary) -> void:
	var h: Dictionary = w.heroes[slot]
	var fire_mode := str(h["equipment"].get("fire_mode", "auto"))
	var want_fire := bool(cmd.get("fire", false))
	if fire_mode != "auto":
		want_fire = bool(cmd.get("firePressed", false))
	if want_fire:
		w.dmg.try_normal_attack(slot, Vector2(h["facing"]))

func _stop_missing_peers(consumed: Array) -> void:
	for slot in w.human_slots:
		if slot == w.local_slot or slot < 0 or slot >= w.heroes.size():
			continue
		if not consumed.has(slot) and not w.peer_commands.has(slot):
			_stop_peer_if_alive(slot)

func _stop_peer_if_alive(slot: int) -> void:
	var h: Dictionary = w.heroes[slot]
	if bool(h["alive"]) and not bool(h["eliminated"]):
		h["vel"] = Vector2.ZERO
		w.heroes[slot] = h

func move_heroes(dt: float) -> void:
	for i in range(w.heroes.size()):
		var h: Dictionary = w.heroes[i]
		if not bool(h["alive"]):
			continue
		if float(h["launch_time"]) > 0.0:
			move_launched_hero(i, dt)
			continue
		_move_grounded_hero(i, h, dt)
	_separate_heroes()

func _move_grounded_hero(i: int, h: Dictionary, dt: float) -> void:
	var old_pos: Vector2 = h["pos"]
	var motion: Vector2 = Vector2(h["vel"]) * dt
	var pos = w.arena.resolve_cover_motion(old_pos, motion)
	var wall_hit = w.deploy.deployable_wall_hit(i, old_pos, pos)
	if not wall_hit.is_empty():
		_apply_wall_slam(i, h, old_pos, wall_hit)
		return
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

func _apply_wall_slam(i: int, h: Dictionary, old_pos: Vector2, wall_hit: Dictionary) -> void:
	h["pos"] = old_pos
	w.heroes[i] = h
	var wall_normal: Vector2 = wall_hit["normal"]
	w.dmg.damage_hero(int(wall_hit["owner"]), i, float(wall_hit["damage"]), &"equipment", 0.32, float(wall_hit["knockback"]), old_pos - wall_normal * 32.0, "WALL SLAM", &"shield_bash", true)
	var bounced: Dictionary = w.heroes[i]
	bounced["wall_hit_cd"] = 0.78
	w.heroes[i] = bounced
	w.deploy.mark_wall_hit(int(wall_hit["id"]), i)
	w.proj.add_effect(&"wall_impact", Vector2(wall_hit["pos"]), 102.0, 0.30, Color("#8de1ff"), "SLAM", wall_normal)

func _separate_heroes() -> void:
	for _pass in range(1):
		_separate_all_pairs()

func _separate_all_pairs() -> void:
	for a in range(w.heroes.size()):
		if not bool(w.heroes[a]["alive"]):
			continue
		_separate_hero_against(a)

func _separate_hero_against(a: int) -> void:
	for b in range(a + 1, w.heroes.size()):
		if not bool(w.heroes[b]["alive"]):
			continue
		_separate_pair(a, b)

func _separate_pair(a: int, b: int) -> void:
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
		var bounced_launch := _launch_wall_bounce(slot, h, pos, velocity, hit_x, hit_y)
		pos = bounced_launch["pos"]
		velocity = bounced_launch["vel"]
		if bool(bounced_launch["lethal"]):
			return
	h["launch_time"] = maxf(0.0, float(h["launch_time"]) - dt)
	velocity *= exp(-0.62 * dt)
	h["launch_vel"] = velocity
	h["pos"] = pos
	_append_trail(h, pos, "launch_trail", 14)
	if float(h["launch_time"]) <= 0.0 or velocity.length() < 80.0:
		h["launch_time"] = 0.0
		h["launch_vel"] = Vector2.ZERO
	w.heroes[slot] = h

func _launch_wall_bounce(slot: int, h: Dictionary, pos: Vector2, velocity: Vector2, hit_x: bool, hit_y: bool) -> Dictionary:
	if hit_x:
		velocity.x *= -0.84
	if hit_y:
		velocity.y *= -0.84
	if hit_x:
		velocity.x *= -0.84
	if hit_y:
		velocity.y *= -0.84
	h["wall_bounces"] = int(h["wall_bounces"]) + 1
	var wall_damage := clampf(9.0 + velocity.length() / 78.0, 15.0, 36.0)
	if float(h["guard_time"]) > 0.0:
		wall_damage *= 0.55
	var wall_damage_cap := float(h["max_hp"]) * float(h["equipment"]["combo_cap_ratio"])
	wall_damage = minf(wall_damage, maxf(0.0, wall_damage_cap - float(h["launch_wall_damage"])))
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
		return {"pos":pos, "vel":velocity, "lethal":true}
	if int(h["wall_bounces"]) >= 3:
		h["launch_time"] = 0.0
		velocity = Vector2.ZERO
	return {"pos":pos, "vel":velocity, "lethal":false}

func _append_trail(h: Dictionary, pos: Vector2, key: String, max_points: int) -> void:
	var trail: Array = h[key]
	if w.tick % 2 == 0:
		trail.append(pos)
		if trail.size() > max_points:
			trail.pop_front()
	h[key] = trail

func update_knockouts(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for knockout0 in w.knockouts:
		var knockout: Dictionary = knockout0
		knockout["time"] = float(knockout["time"]) - dt
		if bool(knockout.get("finished", false)):
			_keep_live_knockout(knockout, kept)
			continue
		var pos: Vector2 = knockout["pos"]
		var velocity: Vector2 = knockout["vel"]
		var motion := velocity * dt
		var next := pos + motion
		var hit_x = next.x < w.ARENA_MARGIN or next.x > w.ARENA_SIZE.x - w.ARENA_MARGIN or w.arena.point_in_cover(pos + Vector2(motion.x, 0.0), w.HERO_RADIUS)
		var hit_y = next.y < w.ARENA_MARGIN or next.y > w.ARENA_SIZE.y - w.ARENA_MARGIN or w.arena.point_in_cover(pos + Vector2(0.0, motion.y), w.HERO_RADIUS)
		if hit_x or hit_y:
			var ko_state := _knockout_bounce(knockout, pos, velocity, next, hit_x, hit_y)
			pos = ko_state["pos"]
			velocity = ko_state["vel"]
		else:
			pos = next
		velocity *= exp(-0.48 * dt)
		knockout["pos"] = pos
		knockout["vel"] = velocity
		_append_trail(knockout, pos, "trail", 20)
		if int(knockout["bounces"]) >= 3:
			knockout["finished"] = true
			knockout["vel"] = Vector2.ZERO
			knockout["time"] = minf(float(knockout["time"]), 0.42)
		if float(knockout["time"]) > 0.0:
			kept.append(knockout)
	w.knockouts = kept

func _keep_live_knockout(knockout: Dictionary, kept: Array[Dictionary]) -> void:
	if float(knockout["time"]) > 0.0:
		kept.append(knockout)

func _knockout_bounce(knockout: Dictionary, pos: Vector2, velocity: Vector2, next: Vector2, hit_x: bool, hit_y: bool) -> Dictionary:
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
	return {"pos":pos, "vel":velocity}

func hero_move_speed(slot: int) -> float:
	if slot < 0 or slot >= w.heroes.size():
		return w.HERO_SPEED
	var speed = float(w.heroes[slot]["equipment"]["move_speed"]) + w.roul.roulette_stat(slot, "spd")
	if posmod(int(w.heroes[slot].get("animal", slot)), 12) == 4 and w.ult_summon.pos_in_dragon_smoke(Vector2(w.heroes[slot]["pos"])):
		speed *= 1.30
	if w.ult_summon.pos_in_enemy_mud(slot):
		speed *= 0.48
	return speed
