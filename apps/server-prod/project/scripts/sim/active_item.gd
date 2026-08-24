class_name ActiveItem
extends RefCounted

var w

func _init(world) -> void:
	w = world

const SPRING_AIR := 0.45
const SPRING_LIFT := 36.0
const SPRING_EVADE := 0.22
const SPRING_BOOST := 220.0
const SLIDE_DURATION := 2.2
const SLIDE_ACCEL := 520.0
const SLIDE_FRICTION := 180.0
const PULL_DURATION := 0.55
const PULL_RADIUS := 300.0
const PULL_LAUNCH := 380.0
const DECOY_DAMAGE := 18.0
const DECOY_KNOCK := 90.0
const POCKET_DURATION := 5.0
const POCKET_RADIUS := 150.0
const HOP_LIFT_DEFAULT := 19.0
const ITEM_DROP_IGNORE := 0.45

func place_mine(owner: int, desired_pos: Vector2, damage: float, blast_radius: float, arm_time: float = 0.62, lifetime: float = 8.0, fuse_time: float = 0.38, ultimate_mine: bool = false, auto_detonate: float = -1.0) -> void:
	w.deploy.place_mine(owner, desired_pos, damage, blast_radius, arm_time, lifetime, fuse_time, ultimate_mine, auto_detonate)

func place_bounce_wall(owner: int, desired_pos: Vector2, facing: Vector2, half_length: float, lifetime: float, speed: float, damage: float, knockback: float) -> void:
	w.deploy.place_bounce_wall(owner, desired_pos, facing, half_length, lifetime, speed, damage, knockback)

func moving_wall_sweep(wall: Dictionary, old_pos: Vector2, new_pos: Vector2) -> Dictionary:
	return w.deploy.moving_wall_sweep(wall, old_pos, new_pos)

func mine_has_target(mine: Dictionary) -> bool:
	return w.deploy.mine_has_target(mine)

func update_deployables(dt: float) -> void:
	w.deploy.update_deployables(dt)

func deployable_wall_hit(slot: int, old_pos: Vector2, new_pos: Vector2) -> Dictionary:
	return w.deploy.deployable_wall_hit(slot, old_pos, new_pos)

func mark_wall_hit(wall_id: int, slot: int) -> void:
	w.deploy.mark_wall_hit(wall_id, slot)

func try_mobility(slot: int, direction: Vector2) -> void:
	var h: Dictionary = w.heroes[slot]
	if not bool(h["alive"]) or float(h["mobility_cd"]) > 0.0 or float(h["launch_time"]) > 0.0 or float(h["root_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
		return
	if w.roul.hero_has_timed(h, "turtle"):
		return
	var escaped_combo := float(h["combo_capture_time"]) > 0.0
	if escaped_combo:
		w.dmg.break_incoming_combo(slot)
		h = w.heroes[slot]
	w.act_item.cancel_skill_charge(slot)
	w.act_item.cancel_attack_recovery(slot)
	h = w.heroes[slot]
	var equipment: Dictionary = h["equipment"]
	var equipment_id := str(equipment["id"])
	var dir = w.dmg.attack_direction(direction)
	var distance := float(equipment["mobility_distance"])
	var old_pos: Vector2 = h["pos"]
	h["pos"] = w.arena.resolve_cover_motion(old_pos, dir * distance)
	h["pos"] = Vector2(
		clampf(Vector2(h["pos"]).x, w.ARENA_MARGIN + w.HERO_RADIUS, w.ARENA_SIZE.x - w.ARENA_MARGIN - w.HERO_RADIUS),
		clampf(Vector2(h["pos"]).y, w.ARENA_MARGIN + w.HERO_RADIUS, w.ARENA_SIZE.y - w.ARENA_MARGIN - w.HERO_RADIUS)
	)
	h["mobility_cd"] = float(equipment["mobility_cooldown"])
	h["action"] = &"MOBILITY"
	h["evade_time"] = maxf(float(h["evade_time"]), 0.20)
	if int(h["combo_hits"]) > 0:
		h["combo_hits"] = 0
		h["combo_time"] = 0.0
		h["combo_damage"] = 0.0
		h["combo_owner"] = -1
		h["combo_immunity"] = 0.72
		h["hitstun_time"] = 0.0
		w.proj.add_effect(&"combo_break", old_pos, 72.0, 0.34, Color("#6ef3a5"), "COMBO BREAK", dir)
	elif escaped_combo:
		w.proj.add_effect(&"combo_break", old_pos, 72.0, 0.34, Color("#6ef3a5"), "ESCAPE", dir)
	match equipment_id:
		"scatter":
			w.proj.add_effect(&"speed_streak", Vector2(h["pos"]), distance, 0.30, Color("#ffb45c"), "SKIRMISH HOP", -dir)
		"rail":
			w.proj.add_effect(&"beam_step", Vector2(h["pos"]), distance, 0.26, Color("#71e7ff"), "SIGHTLINE STEP", -dir)
		"mortar":
			w.proj.add_effect(&"explosion", old_pos, 105.0, 0.36, Color("#ff604f"), "BLAST HOP")
			w.heroes[slot] = h
			for target in range(w.PLAYER_COUNT):
				if target != slot and bool(w.heroes[target]["alive"]) and old_pos.distance_to(Vector2(w.heroes[target]["pos"])) <= 120.0:
					w.dmg.damage_hero(slot, target, 2.0, &"mobility", 0.12, 72.0, old_pos, "BLAST HOP", &"explosion")
			h = w.heroes[slot]
		"leech":
			h["hp"] = minf(float(h["max_hp"]), float(h["hp"]) + 8.0)
			w.proj.add_effect(&"drain", Vector2(h["pos"]), 88.0, 0.42, Color("#d45cff"), "+8 SHADOW PULL", -dir)
		"breaker":
			h["guard_time"] = 0.80
			w.proj.add_effect(&"guard", Vector2(h["pos"]), 68.0, 0.80, Color("#ffe066"), "IRON MARCH", dir)
		"burst":
			w.proj.add_effect(&"speed_streak", Vector2(h["pos"]), distance, 0.28, Color("#ff5ca8"), "FLASH CUT", -dir)
		"blade":
			h["evade_time"] = 0.48
			w.proj.add_effect(&"slash_dash", Vector2(h["pos"]), distance, 0.34, Color("#b9f3ff"), "SHADOW SHEATH", -dir)
		"brawler":
			h["combo_immunity"] = 0.95
			w.proj.add_effect(&"speed_streak", Vector2(h["pos"]), distance, 0.28, Color("#ff9466"), "WEAVE", -dir)
		"bomb":
			w.proj.add_effect(&"fuse", old_pos, 75.0, 0.50, Color("#ff5d4f"), "BLAST ROLL")
		"spear":
			w.proj.add_effect(&"spear_line", Vector2(h["pos"]), distance, 0.32, Color("#ffe27a"), "POLE VAULT", -dir)
		"chain":
			w.proj.add_effect(&"chain_arc", Vector2(h["pos"]), distance, 0.34, Color("#b78cff"), "SWING STEP", -dir)
		_:
			h["guard_time"] = 1.20
			w.proj.add_effect(&"guard", Vector2(h["pos"]), 78.0, 1.20, Color("#8de1ff"), "BRACE STEP", dir)
	w.heroes[slot] = h
	w.event_log.emit(w.tick, &"mobility_used", slot, -1, {"equipment":equipment_id, "name":equipment["mobility_name"]})

func cancel_attack_recovery(slot: int) -> void:
	var h: Dictionary = w.heroes[slot]
	h["attack_lock_time"] = 0.0
	h["fire_cd"] = minf(float(h["fire_cd"]), 0.04)
	w.heroes[slot] = h

func cancel_skill_charge(slot: int) -> void:
	if slot < 0 or slot >= w.heroes.size():
		return
	var h: Dictionary = w.heroes[slot]
	h["charging_skill"] = false
	h["charge_time"] = 0.0
	w.heroes[slot] = h

func begin_skill_charge(_slot: int, _direction: Vector2) -> void:
	return

func continue_skill_charge(_slot: int, _dt: float, _direction: Vector2) -> void:
	return

func release_skill_charge(_slot: int, _direction: Vector2) -> void:
	return

func try_equipment_attack(_slot: int, _direction: Vector2, _charge_ratio: float = 1.0) -> void:
	return

func item_kind_color(kind: String) -> Color:
	match kind:
		"spring":
			return Color("#ffe066")
		"slide":
			return Color("#70e7ff")
		"pull":
			return Color("#b78cff")
		"pocket":
			return Color("#f4e2ff")
		_:
			return Color("#6ef3a5")

func roll_pickup_kind(pickup: Dictionary) -> void:
	var roll: float = w.rng.rangef(0.0, 1.0)
	var kind := "medkit"
	if roll < 0.30:
		kind = "medkit"
	elif roll < 0.48:
		kind = "spring"
	elif roll < 0.66:
		kind = "slide"
	elif roll < 0.80:
		kind = "pull"
	elif roll < 0.90:
		kind = "pocket"
	else:
		kind = "decoy"
	pickup["kind"] = kind
	if kind == "decoy":
		var faces := ["medkit", "spring", "slide", "pull", "pocket"]
		pickup["disguise"] = str(faces[w.rng.rangei(0, faces.size() - 1)])
	else:
		pickup["disguise"] = kind

func spawn_dropped_pickup(pos: Vector2, kind: String, ignore_slot: int = -1) -> void:
	if kind == "" or kind == "decoy":
		return
	var drop_pos: Vector2 = w.arena.clamp_arena_point(pos, w.HEALTH_PICKUP_RADIUS)
	for pickup_index in range(w.health_pickups.size()):
		var old_pickup: Dictionary = w.health_pickups[pickup_index]
		if bool(old_pickup.get("ephemeral", false)) and not bool(old_pickup["active"]):
			old_pickup["pos"] = drop_pos
			old_pickup["home"] = drop_pos
			old_pickup["kind"] = kind
			old_pickup["disguise"] = kind
			old_pickup["active"] = true
			old_pickup["respawn"] = 0.0
			old_pickup["magnet_slot"] = -1
			old_pickup["ignore_slot"] = ignore_slot
			old_pickup["ignore_time"] = ITEM_DROP_IGNORE if ignore_slot >= 0 else 0.0
			w.health_pickups[pickup_index] = old_pickup
			return
	w.health_pickups.append({
		"id":w.health_pickups.size(),
		"pos":drop_pos,
		"home":drop_pos,
		"magnet_slot":-1,
		"active":true,
		"respawn":0.0,
		"kind":kind,
		"disguise":kind,
		"ephemeral":true,
		"ignore_slot":ignore_slot,
		"ignore_time":ITEM_DROP_IGNORE if ignore_slot >= 0 else 0.0
	})

func explode_decoy(slot: int, origin: Vector2) -> void:
	if slot < 0 or slot >= w.heroes.size():
		return
	var h: Dictionary = w.heroes[slot]
	if not bool(h["alive"]):
		return
	if float(h.get("spawn_protect_time", 0.0)) > 0.0:
		return
	if float(h.get("evade_time", 0.0)) > 0.0:
		h["evade_time"] = 0.0
		w.heroes[slot] = h
		w.proj.add_effect(&"afterimage", Vector2(h["pos"]), 105.0, 0.38, Color("#b9f3ff"), "EVADE")
		w.event_log.emit(w.tick, &"attack_evaded", -1, slot, {"source":&"decoy"})
		return
	h["hp"] = float(h["hp"]) - DECOY_DAMAGE
	var push: Vector2 = origin.direction_to(Vector2(h["pos"]))
	if push.length_squared() < 0.1:
		push = Vector2(h.get("facing", Vector2.RIGHT))
	var launch_speed: float = (900.0 + DECOY_KNOCK * 9.8) / maxf(0.35, float(h["equipment"]["weight"]))
	h["launch_vel"] = push * launch_speed
	h["launch_time"] = 0.28
	h["vel"] = Vector2.ZERO
	h["launch_owner"] = -1
	w.heroes[slot] = h
	w.proj.add_effect(&"explosion", origin, 78.0, 0.40, Color("#ff665a"), "DECOY")
	w.event_log.emit(w.tick, &"decoy_exploded", -1, slot, {"damage":DECOY_DAMAGE})
	w.lifecycle.apply_lethal_or_down(-1, slot, DECOY_DAMAGE)

func collect_item_pickup(slot: int, pickup: Dictionary) -> Dictionary:
	var kind := str(pickup.get("kind", "medkit"))
	var target_pos: Vector2 = w.heroes[slot]["pos"]
	if kind == "decoy":
		explode_decoy(slot, Vector2(pickup["pos"]))
		pickup["active"] = false
		pickup["respawn"] = 99999.0 if bool(pickup.get("ephemeral", false)) else w.HEALTH_PICKUP_RESPAWN
		pickup["magnet_slot"] = -1
		pickup["pos"] = Vector2(pickup["home"])
		return pickup
	var h: Dictionary = w.heroes[slot]
	var old_item := str(h.get("held_item", ""))
	if old_item != "":
		var drop_pos: Vector2 = target_pos - Vector2(h.get("facing", Vector2.RIGHT)) * 36.0
		spawn_dropped_pickup(drop_pos, old_item, slot)
	h["held_item"] = kind
	w.heroes[slot] = h
	pickup["active"] = false
	pickup["respawn"] = 99999.0 if bool(pickup.get("ephemeral", false)) else w.HEALTH_PICKUP_RESPAWN
	pickup["magnet_slot"] = -1
	pickup["pos"] = Vector2(pickup["home"])
	w.proj.add_effect(&"heal_pickup", target_pos, 64.0, 0.38, item_kind_color(kind), kind.to_upper())
	w.event_log.emit(w.tick, &"item_collected", slot, -1, {"kind":kind, "dropped":old_item})
	return pickup

func steer_slide(slot: int, h: Dictionary, wish: Vector2, control_speed: float, dt: float) -> void:
	var vel: Vector2 = h["vel"]
	var max_speed: float = w.mov.hero_move_speed(slot) * control_speed * w.dmg.streak_move_multiplier(slot)
	if wish.length_squared() > 0.04:
		var wish_dir: Vector2 = wish.normalized()
		vel = vel + wish_dir * SLIDE_ACCEL * dt
		var cap: float = maxf(40.0, max_speed * 1.15)
		if vel.length() > cap:
			vel = vel.normalized() * cap
	else:
		vel = vel.move_toward(Vector2.ZERO, SLIDE_FRICTION * dt)
	h["vel"] = vel
	h["slide_wish"] = wish

func pull_target_toward(target: int, user_pos: Vector2) -> void:
	var h: Dictionary = w.heroes[target]
	var to_user: Vector2 = Vector2(h["pos"]).direction_to(user_pos)
	if to_user.length_squared() < 0.01:
		return
	h["launch_vel"] = to_user * PULL_LAUNCH
	h["launch_time"] = maxf(float(h["launch_time"]), 0.20)
	h["vel"] = Vector2.ZERO
	w.heroes[target] = h

func apply_pull_pulse(slot: int, dt: float) -> void:
	var user_pos: Vector2 = w.heroes[slot]["pos"]
	for target in range(w.heroes.size()):
		if target == slot:
			continue
		if not bool(w.heroes[target]["alive"]) or bool(w.heroes[target]["eliminated"]):
			continue
		if Vector2(w.heroes[target]["pos"]).distance_to(user_pos) > PULL_RADIUS:
			continue
		pull_target_toward(target, user_pos)
	for pickup_index in range(w.health_pickups.size()):
		var pickup: Dictionary = w.health_pickups[pickup_index]
		if not bool(pickup["active"]):
			continue
		var pickup_pos: Vector2 = pickup["pos"]
		if pickup_pos.distance_to(user_pos) > PULL_RADIUS:
			continue
		var pulled: Vector2 = pickup_pos.move_toward(user_pos, 520.0 * dt)
		pickup["pos"] = pulled
		w.health_pickups[pickup_index] = pickup

func update_item_pulses(dt: float) -> void:
	if w.mode != w.ITEM_POOL_MODE:
		return
	for slot in range(w.heroes.size()):
		if not bool(w.heroes[slot]["alive"]) or bool(w.heroes[slot]["eliminated"]):
			continue
		if float(w.heroes[slot].get("pull_time", 0.0)) > 0.0:
			apply_pull_pulse(slot, dt)

func hero_in_own_pocket(slot: int) -> bool:
	if slot < 0 or slot >= w.heroes.size():
		return false
	if float(w.heroes[slot].get("pocket_time", 0.0)) <= 0.0:
		return false
	var hero_pos: Vector2 = w.heroes[slot]["pos"]
	return hero_pos.distance_to(Vector2(w.heroes[slot]["pos"])) <= POCKET_RADIUS

func try_use_active_item(slot: int) -> void:
	if w.mode != w.ITEM_POOL_MODE:
		try_use_medkit(slot)
		return
	if slot < 0 or slot >= w.heroes.size():
		return
	var h: Dictionary = w.heroes[slot]
	if not bool(h["alive"]) or bool(h["eliminated"]):
		return
	if w.roul.hero_has_timed(h, "turtle"):
		return
	var kind := str(h.get("held_item", ""))
	if kind == "":
		return
	match kind:
		"medkit":
			if float(h["hp"]) >= float(h["max_hp"]) - 0.5:
				return
			h["held_item"] = ""
			w.heroes[slot] = h
			var heal_amount = float(h["max_hp"]) * w.MEDKIT_HEAL_RATIO
			w.dmg.heal_hero(slot, heal_amount)
			w.proj.add_effect(&"heal_pickup", Vector2(h["pos"]), 72.0, 0.45, Color("#6ef3a5"), "MEDKIT")
			w.event_log.emit(w.tick, &"medkit_used", slot, -1, {"amount":heal_amount, "left":0})
		"spring":
			h["held_item"] = ""
			h["hop_time"] = SPRING_AIR
			h["hop_max"] = SPRING_AIR
			h["hop_height"] = SPRING_LIFT
			h["evade_time"] = maxf(float(h["evade_time"]), SPRING_EVADE)
			h["spring_time"] = SPRING_AIR
			var boost_dir: Vector2 = Vector2(h["vel"])
			if boost_dir.length_squared() < 0.1:
				boost_dir = Vector2(h["facing"])
			if boost_dir.length_squared() > 0.1:
				var boosted: Vector2 = Vector2(h["vel"]) + boost_dir.normalized() * SPRING_BOOST
				h["vel"] = boosted
			w.heroes[slot] = h
			w.proj.add_effect(&"speed_streak", Vector2(h["pos"]), 90.0, 0.34, Color("#ffe066"), "SPRING", boost_dir)
			w.event_log.emit(w.tick, &"item_used", slot, -1, {"kind":"spring"})
		"slide":
			h["held_item"] = ""
			h["slide_time"] = SLIDE_DURATION
			w.heroes[slot] = h
			w.proj.add_effect(&"speed_streak", Vector2(h["pos"]), 70.0, 0.28, Color("#70e7ff"), "SLIDE")
			w.event_log.emit(w.tick, &"item_used", slot, -1, {"kind":"slide"})
		"pull":
			h["held_item"] = ""
			h["pull_time"] = PULL_DURATION
			w.heroes[slot] = h
			apply_pull_pulse(slot, w.FIXED_DT)
			w.proj.add_effect(&"chain_vortex", Vector2(h["pos"]), PULL_RADIUS, 0.55, Color("#b78cff"), "PULL")
			w.event_log.emit(w.tick, &"item_used", slot, -1, {"kind":"pull"})
		"pocket":
			h["held_item"] = ""
			h["pocket_time"] = POCKET_DURATION
			w.heroes[slot] = h
			w.proj.add_effect(&"guard", Vector2(h["pos"]), POCKET_RADIUS, 0.45, Color("#f4e2ff"), "POCKET")
			w.event_log.emit(w.tick, &"item_used", slot, -1, {"kind":"pocket"})

func try_use_medkit(slot: int) -> void:
	if slot < 0 or slot >= w.heroes.size():
		return
	var h: Dictionary = w.heroes[slot]
	if not bool(h["alive"]) or bool(h["eliminated"]):
		return
	if int(h.get("medkits", 0)) <= 0:
		return
	if float(h["hp"]) >= float(h["max_hp"]) - 0.5:
		return
	h["medkits"] = int(h["medkits"]) - 1
	var heal_amount = float(h["max_hp"]) * w.MEDKIT_HEAL_RATIO
	w.heroes[slot] = h
	w.dmg.heal_hero(slot, heal_amount)
	w.proj.add_effect(&"heal_pickup", Vector2(h["pos"]), 72.0, 0.45, Color("#6ef3a5"), "메드킷 +%d" % roundi(heal_amount))
	w.event_log.emit(w.tick, &"medkit_used", slot, -1, {"amount":heal_amount, "left":int(h["medkits"])})

func try_gun_loot(owner: int, attacker: Dictionary) -> Dictionary:
	if w.mode not in w.GUN_LOOT_MODES or not bool(attacker["alive"]):
		return attacker
	var current_id := str(attacker["equipment"]["id"])
	var chain_index = w.equip.GUN_LOOT_CHAIN.find(current_id)
	var next_id := ""
	if chain_index >= 0 and chain_index < w.equip.GUN_LOOT_CHAIN.size() - 1:
		next_id = str(w.equip.GUN_LOOT_CHAIN[chain_index + 1])
	elif chain_index < 0:
		next_id = str(w.equip.GUN_LOOT_CHAIN[0])
	if next_id.is_empty() or next_id == current_id:
		return attacker
	attacker["equipment"] = w.equip.make_equipment(next_id)
	attacker["burst_left"] = int(attacker["equipment"].get("burst_shots", 0))
	if int(attacker["burst_left"]) <= 0:
		attacker["burst_left"] = 2
	attacker["mag"] = int(attacker["equipment"].get("mag_size", 1))
	attacker["reload_left"] = 0.0
	attacker["reload_flash"] = 0.0
	w.event_log.emit(w.tick, &"gun_upgraded", owner, -1, {"equipment":next_id})
	w._announce("P%d %s 획득!" % [owner + 1, str(attacker["equipment"]["name"])], 90)
	return attacker
