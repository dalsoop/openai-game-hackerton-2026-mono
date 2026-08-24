class_name CpuBehavior
extends RefCounted

var w

func _init(world) -> void:
	w = world

func update_cpus(dt: float) -> void:
	for slot in range(w.heroes.size()):
		if slot == w.local_slot or w.human_slots.has(slot):
			continue
		var h: Dictionary = w.heroes[slot]
		if bool(h["eliminated"]):
			continue
		if not bool(h["alive"]):
			continue
		if bool(h.get("downed", false)):
			h["vel"] = Vector2.ZERO
			h["action"] = &"DOWN"
			w.heroes[slot] = h
			continue
		if float(h["stun_time"]) > 0.0:
			h["vel"] = Vector2.ZERO
			h["charging_skill"] = false
			h["charge_time"] = 0.0
			h["action"] = &"STUNNED"
			w.heroes[slot] = h
			continue
		if float(h["combo_capture_time"]) > 0.0:
			h["vel"] = Vector2.ZERO
			w.heroes[slot] = h
			if float(h["hitstun_time"]) <= 0.0:
				if float(h["mobility_cd"]) <= 0.0 and w.rng.chance(0.055):
					w.act_item.try_mobility(slot, -Vector2(h["facing"]))
					h = w.heroes[slot]
		if w.mode == w.ITEM_POOL_MODE:
			cpu_consider_held_item(slot)
			h = w.heroes[slot]
		elif int(h.get("medkits", 0)) > 0 and float(h["hp"]) < float(h["max_hp"]) * 0.5 and w.rng.chance(0.30):
			w.act_item.try_use_medkit(slot)
			h = w.heroes[slot]
		if float(h.get("slide_time", 0.0)) > 0.0:
			var slide_wish: Vector2 = h.get("slide_wish", Vector2.ZERO)
			if slide_wish.length_squared() < 0.01:
				slide_wish = Vector2(h["facing"])
			var slide_scale = 0.42 if float(h["cc_time"]) > 0.0 else 1.0
			if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 or float(h["root_time"]) > 0.0:
				slide_scale = 0.0
			w.act_item.steer_slide(slot, h, slide_wish, slide_scale, dt)
			w.heroes[slot] = h
		h["think"] = float(h["think"]) - dt
		if float(h["think"]) <= 0.0:
			h["think"] = 0.16 + w.rng.rangef(0.0, 0.10)
			var old_target = int(h["target"])
			var target = choose_target(slot)
			if float(h["target_hold"]) <= 0.0 or old_target < 0 or not target_valid(old_target):
				h["target"] = target
				h["target_hold"] = 0.42 + w.rng.rangef(0.0, 0.30)
				if old_target >= 0 and old_target != target:
					w.event_log.emit(w.tick, &"target_changed", slot, target, {"from":old_target})
					if old_target == int(w.heroes[target]["target"]):
						w.event_log.emit(w.tick, &"betrayal", slot, target, {"previous_target":old_target})
			var heal_index = best_health_pickup(slot)
			var tslot = int(h["target"])
			var orb_index = w.crate.best_crate_orb(slot)
			var crate_index = w.crate.best_crate(slot)
			var fight_dist = 99999.0
			if tslot >= 0:
				fight_dist = Vector2(h["pos"]).distance_to(target_position(tslot))
			if heal_index >= 0:
				var heal_pos: Vector2 = w.health_pickups[heal_index]["pos"]
				var to_heal = Vector2(h["pos"]).direction_to(heal_pos)
				var heal_strafe = to_heal.orthogonal() * (-1.0 if slot % 2 == 0 else 1.0)
				var heal_move = to_heal
				if w.arena.line_blocked(Vector2(h["pos"]), heal_pos):
					heal_move = (to_heal * 0.38 + heal_strafe).normalized()
				var heal_cc_speed = 0.42 if float(h["cc_time"]) > 0.0 else 1.0
				var heal_hitstun_speed = 0.35 if float(h["root_time"]) > 0.0 else (0.72 if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 else 1.0)
				apply_cpu_move(slot, h, heal_move, heal_cc_speed * heal_hitstun_speed)
				h["action"] = &"SEEK_HEAL"
				if tslot >= 0:
					h["aim"] = Vector2(h["pos"]).direction_to(target_position(tslot)).rotated(w.rng.rangef(-0.085, 0.085))
					h["facing"] = h["aim"]
			elif orb_index >= 0 and Vector2(h["pos"]).distance_to(Vector2(w.crate_orbs[orb_index]["pos"])) < minf(fight_dist, 520.0) and w.rng.chance(0.55):
				var orb_pos: Vector2 = w.crate_orbs[orb_index]["pos"]
				var to_orb: Vector2 = Vector2(h["pos"]).direction_to(orb_pos)
				var orb_move: Vector2 = to_orb
				if w.arena.line_blocked(Vector2(h["pos"]), orb_pos):
					orb_move = (to_orb * 0.40 + to_orb.orthogonal()).normalized()
				apply_cpu_move(slot, h, orb_move, 1.0)
				h["action"] = &"SEEK_ORB"
			elif bool(w.mid_tower.get("alive", false)) and Vector2(h["pos"]).distance_to(Vector2(w.mid_tower["pos"])) < minf(fight_dist, 780.0) and w.rng.chance(0.42):
				var tower_pos: Vector2 = w.mid_tower["pos"]
				var to_tower: Vector2 = Vector2(h["pos"]).direction_to(tower_pos)
				h["aim"] = to_tower
				h["facing"] = to_tower
				var tower_move: Vector2 = to_tower
				if Vector2(h["pos"]).distance_to(tower_pos) < float(h["equipment"]["preferred_range"]) * 0.62:
					tower_move = to_tower.orthogonal()
				apply_cpu_move(slot, h, tower_move, 1.0)
				h["action"] = &"SEEK_TOWER"
			elif crate_index >= 0 and Vector2(h["pos"]).distance_to(Vector2(w.crates[crate_index]["pos"])) < minf(fight_dist, 460.0) and w.rng.chance(0.28):
				var crate_pos: Vector2 = w.crates[crate_index]["pos"]
				var to_crate: Vector2 = Vector2(h["pos"]).direction_to(crate_pos)
				h["crate_target"] = crate_index
				h["aim"] = to_crate
				h["facing"] = to_crate
				var crate_move: Vector2 = to_crate
				if w.arena.line_blocked(Vector2(h["pos"]), crate_pos):
					crate_move = (to_crate * 0.36 + to_crate.orthogonal()).normalized()
				elif Vector2(h["pos"]).distance_to(crate_pos) < float(h["equipment"]["preferred_range"]) * 0.55:
					crate_move = to_crate.orthogonal()
				apply_cpu_move(slot, h, crate_move, 1.0)
				h["action"] = &"SEEK_CRATE"
			elif tslot >= 0:
				var t_pos = target_position(tslot)
				var to_target = Vector2(h["pos"]).direction_to(t_pos)
				var dist = Vector2(h["pos"]).distance_to(t_pos)
				var strafe = to_target.orthogonal() * (-1.0 if slot % 2 == 0 else 1.0)
				var preferred_range = float(h["equipment"]["preferred_range"])
				if str(h["equipment"]["id"]) not in ["scatter", "rail", "burst", "mortar", "bomb"]:
					preferred_range = minf(preferred_range, w.dmg.normal_reach(slot) * 0.62)
				var desired = to_target
				if w.arena.line_blocked(Vector2(h["pos"]), t_pos):
					desired = (to_target * 0.35 + strafe).normalized()
					h["action"] = &"FLANK"
				elif dist < preferred_range * 0.72:
					desired = (strafe * 0.75 - to_target * 0.25).normalized()
					h["action"] = &"DISENGAGE"
				elif dist <= preferred_range * 1.15:
					desired = (strafe * 0.88 + to_target * 0.12).normalized()
					h["action"] = &"HOLD_RANGE"
				else:
					desired = (to_target + strafe * 0.20).normalized()
					h["action"] = &"CLOSE_RANGE"
				var cc_speed = 0.42 if float(h["cc_time"]) > 0.0 else 1.0
				var hitstun_speed = 0.35 if float(h["root_time"]) > 0.0 else (0.72 if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 else 1.0)
				var action_speed = 0.76 if float(h["attack_lock_time"]) > 0.0 else 1.0
				if bool(h["charging_skill"]):
					action_speed *= 0.62
				apply_cpu_move(slot, h, desired, cc_speed * hitstun_speed * action_speed * w.rng.rangef(0.93, 1.02))
				var aim_error: float = w.rng.rangef(-0.085, 0.085)
				h["aim"] = to_target.rotated(aim_error)
				h["facing"] = h["aim"]
			var hazard_escape = hazard_escape_vector(slot)
			if hazard_escape.length_squared() > 0.1:
				var hazard_cc_speed = 0.42 if float(h["cc_time"]) > 0.0 else 1.0
				var hazard_lock_speed = 0.35 if float(h["root_time"]) > 0.0 else (0.72 if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 else 1.0)
				apply_cpu_move(slot, h, hazard_escape, hazard_cc_speed * hazard_lock_speed)
				h["action"] = &"DODGE_WARNING"
		w.heroes[slot] = h
		if float(h.get("ultimate_charge", 0.0)) >= w.ULTIMATE_MAX - 0.5 and not w.roul.hero_has_timed(h, "turtle"):
			if cpu_try_ultimate(slot):
				h = w.heroes[slot]
		var current_target = int(h["target"])
		if current_target >= 0 and target_valid(current_target):
			var t_pos = target_position(current_target)
			var dist = Vector2(h["pos"]).distance_to(t_pos)
			var clear_shot = not w.arena.line_blocked(Vector2(h["pos"]), t_pos)
			if h["action"] != &"SEEK_HEAL" and float(h["mobility_cd"]) <= 0.0 and float(h["launch_time"]) <= 0.0 and (dist > float(h["equipment"]["preferred_range"]) * 1.35 or dist < float(h["equipment"]["preferred_range"]) * 0.48) and w.rng.chance(0.025):
				var mobility_dir = Vector2(h["vel"]).normalized()
				if mobility_dir.length_squared() < 0.1:
					mobility_dir = Vector2(h["pos"]).direction_to(t_pos)
				w.act_item.try_mobility(slot, mobility_dir)
				h = w.heroes[slot]
			if dist < w.dmg.normal_reach(slot) and clear_shot and float(h["fire_cd"]) <= 0.0:
				w.dmg.try_normal_attack(slot, Vector2(h["aim"]))
			h = w.heroes[slot]
		if h["action"] == &"SEEK_TOWER" and float(h["fire_cd"]) <= 0.0 and bool(w.mid_tower.get("alive", false)):
			var tpos: Vector2 = w.mid_tower["pos"]
			if Vector2(h["pos"]).distance_to(tpos) < w.dmg.normal_reach(slot):
				w.dmg.try_normal_attack(slot, Vector2(h["pos"]).direction_to(tpos))
		if h["action"] == &"SEEK_CRATE" and float(h["fire_cd"]) <= 0.0:
			var aim_crate = int(h.get("crate_target", -1))
			if aim_crate >= 0 and aim_crate < w.crates.size() and bool(w.crates[aim_crate]["alive"]):
				var crate_aim_pos: Vector2 = w.crates[aim_crate]["pos"]
				if Vector2(h["pos"]).distance_to(crate_aim_pos) < w.dmg.normal_reach(slot) and not w.arena.line_blocked(Vector2(h["pos"]), crate_aim_pos):
					w.dmg.try_normal_attack(slot, Vector2(h["pos"]).direction_to(crate_aim_pos))
					h = w.heroes[slot]

func choose_target(slot: int) -> int:
	var best := -1
	var best_score := -999.0
	var attacker_counts := PackedInt32Array()
	attacker_counts.resize(w.PLAYER_COUNT)
	for other in w.heroes:
		var t = int(other["target"])
		if t >= 0 and t < w.PLAYER_COUNT:
			attacker_counts[t] += 1
	var valid_target_count := 0
	for candidate in range(w.PLAYER_COUNT):
		if candidate != slot and target_valid(candidate):
			valid_target_count += 1
	for target in range(w.PLAYER_COUNT):
		if target == slot or not target_valid(target):
			continue
		if valid_target_count >= 3 and attacker_counts[target] >= 2:
			continue
		var target_h: Dictionary = w.heroes[target]
		var distance = Vector2(w.heroes[slot]["pos"]).distance_to(target_position(target))
		var leader_value = clampf(float(target_h["threat"]) / 180.0, 0.0, 1.0)
		var finishability = clampf((float(target_h["max_hp"]) - float(target_h["hp"])) / maxf(1.0, float(target_h["max_hp"])), 0.0, 1.0)
		var dogpile = 1.0 if attacker_counts[target] == 1 else 0.0
		var crowd_penalty = maxf(0.0, float(attacker_counts[target] - 1)) * 0.42
		var retaliation = clampf(float(target_h["threat"]) / 150.0, 0.0, 1.0)
		var grudge = 1.0 if int(w.heroes[slot]["recent_attacker"]) == target else 0.0
		var score = 0.26 * leader_value + 0.28 * finishability
		score += 0.13 * clampf(float(target_h["threat"]) / 120.0, 0.0, 1.0)
		score += 0.11 * grudge + 0.10 * dogpile + 0.06 * clampf(float(target_h["bounty"]) / 80.0, 0.0, 1.0)
		score -= crowd_penalty + 0.18 * retaliation + 0.15 * clampf(distance / 1260.0, 0.0, 1.0)
		score += w.rng.rangef(-0.025, 0.025)
		if score > best_score:
			best_score = score
			best = target
	return best

func best_health_pickup(slot: int) -> int:
	var h: Dictionary = w.heroes[slot]
	var health_ratio = float(h["hp"]) / maxf(1.0, float(h["max_hp"]))
	var empty_hand = w.mode == w.ITEM_POOL_MODE and str(h.get("held_item", "")) == ""
	if health_ratio > 0.65 and not empty_hand:
		return -1
	var search_radius = 700.0
	if empty_hand:
		search_radius = 980.0
	if health_ratio <= 0.48:
		search_radius = 1190.0
	if health_ratio <= 0.30:
		search_radius = 1750.0
	var best_index := -1
	var best_distance = search_radius
	for pickup_index in range(w.health_pickups.size()):
		var pickup: Dictionary = w.health_pickups[pickup_index]
		if not bool(pickup["active"]):
			continue
		var distance = Vector2(h["pos"]).distance_to(Vector2(pickup["pos"]))
		if distance >= search_radius:
			continue
		var score_distance = distance
		if is_signature_floor_gun(slot, pickup):
			score_distance = maxf(0.0, distance - 140.0)
		if score_distance < best_distance:
			best_distance = score_distance
			best_index = pickup_index
	return best_index

func is_signature_floor_gun(slot: int, pickup: Dictionary) -> bool:
	var equip_id = str(pickup.get("equipment", pickup.get("gun_id", "")))
	if equip_id == "":
		return false
	return GangGameWorld.GunSig.is_signature(slot, equip_id)

func hazard_escape_vector(slot: int) -> Vector2:
	if slot < 0 or slot >= w.heroes.size() or not bool(w.heroes[slot]["alive"]):
		return Vector2.ZERO
	var hero_pos: Vector2 = w.heroes[slot]["pos"]
	var escape := Vector2.ZERO
	for zone in w.zones:
		if int(zone["owner"]) == slot or bool(zone.get("applied", false)) or float(zone.get("delay", 0.0)) <= 0.0:
			continue
		var danger_pos: Vector2 = zone["pos"]
		var danger_radius = float(zone["radius"]) + w.HERO_RADIUS + 65.0
		var distance = hero_pos.distance_to(danger_pos)
		if distance >= danger_radius:
			continue
		var away = danger_pos.direction_to(hero_pos)
		if away.length_squared() < 0.1:
			away = Vector2(w.heroes[int(zone["owner"])]["pos"]).direction_to(hero_pos)
		if away.length_squared() < 0.1:
			away = Vector2.RIGHT.rotated(float(slot) * 1.7)
		var warning_duration = maxf(0.01, float(zone.get("warning_duration", zone.get("delay", 0.01))))
		var urgency = 1.0 - clampf(float(zone["delay"]) / warning_duration, 0.0, 1.0)
		escape += away * (1.0 - distance / danger_radius + urgency * 1.25)
	for projectile in w.projectiles:
		if int(projectile["owner"]) == slot or not bool(projectile.get("arc", false)):
			continue
		var danger_pos: Vector2 = projectile["landing_pos"]
		var danger_radius = float(projectile["splash"]) + w.HERO_RADIUS + 65.0
		var distance = hero_pos.distance_to(danger_pos)
		if distance >= danger_radius:
			continue
		var away = danger_pos.direction_to(hero_pos)
		if away.length_squared() < 0.1:
			away = Vector2(w.heroes[int(projectile["owner"])]["pos"]).direction_to(hero_pos)
		if away.length_squared() < 0.1:
			away = Vector2.DOWN.rotated(float(slot) * 1.3)
		var flight_duration = maxf(0.01, float(projectile.get("max_ttl", projectile.get("ttl", 0.01))))
		var urgency = 1.0 - clampf(float(projectile["ttl"]) / flight_duration, 0.0, 1.0)
		escape += away * (1.0 - distance / danger_radius + urgency * 1.25)
	for mine in w.deployables:
		if int(mine["owner"]) == slot:
			continue
		if StringName(mine.get("type", &"mine")) == &"wall":
			var wall_forward = Vector2(mine.get("travel_direction", Vector2.RIGHT)).normalized()
			var wall_side = Vector2(mine["direction"]).normalized()
			var relative = hero_pos - Vector2(mine["pos"])
			var forward_distance = relative.dot(wall_forward)
			var side_distance = absf(relative.dot(wall_side))
			var remaining_sweep = float(mine.get("speed", 0.0)) * float(mine.get("lifetime", 0.0))
			if forward_distance >= -w.HERO_RADIUS and forward_distance <= minf(remaining_sweep, 480.0) + w.HERO_RADIUS and side_distance <= float(mine["half_length"]) + w.HERO_RADIUS + 45.0:
				var dodge_side = wall_side * (1.0 if relative.dot(wall_side) >= 0.0 else -1.0)
				if absf(relative.dot(wall_side)) < 8.0:
					dodge_side = wall_side * (1.0 if slot % 2 == 0 else -1.0)
				escape += dodge_side * (1.15 if float(mine.get("arm_time", 0.0)) > 0.0 else 1.75)
			continue
		if float(mine.get("arm_time", 0.0)) > 0.0:
			continue
		var danger_pos: Vector2 = mine["pos"]
		var danger_radius = (float(mine["blast_radius"]) if bool(mine.get("triggered", false)) else float(mine["trigger_radius"])) + w.HERO_RADIUS + 45.0
		var distance = hero_pos.distance_to(danger_pos)
		if distance >= danger_radius:
			continue
		var away = danger_pos.direction_to(hero_pos)
		if away.length_squared() < 0.1:
			away = Vector2(w.heroes[int(mine["owner"])]["pos"]).direction_to(hero_pos)
		if away.length_squared() < 0.1:
			away = Vector2.LEFT.rotated(float(slot) * 1.1)
		var urgency = 1.3 if bool(mine.get("triggered", false)) else 0.55
		escape += away * (1.0 - distance / danger_radius + urgency)
	var zone_distance = hero_pos.distance_to(w.safe_zone_center)
	var retreat_radius = maxf(40.0, w.safe_zone_radius - w.SAFE_ZONE_EDGE_BUFFER)
	if zone_distance > retreat_radius:
		var inward = hero_pos.direction_to(w.safe_zone_center)
		if inward.length_squared() < 0.1:
			inward = Vector2.LEFT.rotated(float(slot) * 0.7)
		var overrun = zone_distance - w.safe_zone_radius
		var urgency = 1.85 if overrun > 0.0 else clampf((zone_distance - retreat_radius) / maxf(1.0, w.SAFE_ZONE_EDGE_BUFFER), 0.0, 1.0)
		escape += inward * (1.15 + urgency)
	return escape.normalized() if escape.length_squared() > 0.1 else Vector2.ZERO

func target_valid(slot: int) -> bool:
	return slot >= 0 and slot < w.PLAYER_COUNT and bool(w.heroes[slot]["alive"]) and not bool(w.heroes[slot]["eliminated"])

func target_position(slot: int) -> Vector2:
	return Vector2(w.heroes[slot]["pos"])

func cpu_try_ultimate(slot: int) -> bool:
	var h: Dictionary = w.heroes[slot]
	if not bool(h.get("alive", false)) or bool(h.get("downed", false)) or bool(h.get("eliminated", false)):
		return false
	if float(h.get("stun_time", 0.0)) > 0.0 or bool(h.get("burrowed", false)):
		return false
	var animal = posmod(int(h.get("animal", slot)), 12)
	var tslot = int(h.get("target", -1))
	var dist = 99999.0
	var aim: Vector2 = Vector2(h["pos"]) + Vector2(h.get("facing", Vector2.RIGHT)) * 240.0
	if tslot >= 0 and target_valid(tslot):
		var tpos = target_position(tslot)
		dist = Vector2(h["pos"]).distance_to(tpos)
		aim = tpos
	var hp_ratio = 1.0
	if float(h.get("max_hp", 1.0)) > 1.0:
		hp_ratio = float(h.get("hp", 0.0)) / float(h["max_hp"])
	var want := false
	match animal:
		0:
			want = dist < 520.0
		1:
			want = dist < 300.0
		2:
			want = dist < 340.0
		3:
			want = dist < 640.0 or hp_ratio < 0.42
		4:
			want = dist < 420.0
		5:
			want = hp_ratio < 0.55 or dist < 220.0
		6:
			want = dist < 210.0
		7:
			want = dist < 380.0 or hp_ratio < 0.50
		8:
			want = dist < 480.0
		9:
			want = dist < 360.0
		10:
			want = dist > 80.0 and dist < 520.0
		11:
			want = dist < 300.0
		_:
			want = dist < 420.0
	if tslot < 0 and animal != 5 and animal != 7:
		want = false
	if not want:
		return false
	if not w.rng.chance(0.38):
		return false
	w.ult_animal.try_ultimate(slot, aim)
	return true

func apply_cpu_move(slot: int, h: Dictionary, wish_dir: Vector2, speed_scale: float) -> void:
	if bool(h.get("dog_rush", false)):
		return
	h["slide_wish"] = wish_dir
	if float(h.get("slide_time", 0.0)) > 0.0:
		return
	var cruise: Vector2 = wish_dir * w.mov.hero_move_speed(slot) * speed_scale * w.dmg.streak_move_multiplier(slot)
	h["vel"] = cruise
	w.heroes[slot] = h
	w.ult_animal.apply_flee_vel(slot)
	h = w.heroes[slot]
	if float(h.get("spring_time", 0.0)) > 0.0 and wish_dir.length_squared() > 0.1:
		var boosted: Vector2 = Vector2(h["vel"]) + wish_dir.normalized() * w.SPRING_BOOST
		h["vel"] = boosted

func highest_threat_except(excluded: int) -> int:
	var best := -1
	var best_value := -1.0
	for slot in range(w.PLAYER_COUNT):
		if slot == excluded or not bool(w.cores[slot]["alive"]):
			continue
		var value = float(w.heroes[slot]["threat"]) + float(w.heroes[slot]["bounty"])
		if value > best_value:
			best_value = value
			best = slot
	return best

func cpu_consider_held_item(slot: int) -> void:
	var h: Dictionary = w.heroes[slot]
	var kind := str(h.get("held_item", ""))
	if kind == "":
		return
	var hp_ratio := float(h["hp"]) / maxf(1.0, float(h["max_hp"]))
	var should_use := false
	match kind:
		"medkit":
			should_use = hp_ratio < 0.5 and w.rng.chance(0.30)
		"pocket":
			should_use = (not w._szl.hero_in_safe_zone(slot)) and w.rng.chance(0.22)
		"pull":
			var near := 0
			for other in range(w.heroes.size()):
				if other == slot or not bool(w.heroes[other]["alive"]):
					continue
				if Vector2(h["pos"]).distance_to(Vector2(w.heroes[other]["pos"])) <= w.PULL_RADIUS:
					near += 1
			should_use = near > 0 and w.rng.chance(0.12)
		"spring":
			should_use = w.rng.chance(0.06) and (hp_ratio < 0.42 or float(h["mobility_cd"]) > 0.8)
		"slide":
			should_use = w.rng.chance(0.08) and (h["action"] == &"CLOSE_RANGE" or h["action"] == &"SEEK_HEAL")
	if should_use:
		w.act_item.try_use_active_item(slot)
