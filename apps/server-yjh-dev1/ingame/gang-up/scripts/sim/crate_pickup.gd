class_name CratePickup
extends RefCounted

var w

func _init(world) -> void:
	w = world

func spawn_breakable_crates() -> void:
	w.crates.clear()
	place_crate_ring(8, w.SPAWN_HERO_RADIUS_X * w.CRATE_RING_A_SCALE, w.SPAWN_HERO_RADIUS_Y * w.CRATE_RING_A_SCALE, 0.0, 0, true)
	place_crate_ring(8, w.SPAWN_HERO_RADIUS_X * w.CRATE_RING_B_SCALE, w.SPAWN_HERO_RADIUS_Y * w.CRATE_RING_B_SCALE, PI * 0.125, 1, false)
	place_crate_ring(4, w.SPAWN_HERO_RADIUS_X * w.CRATE_RING_C_SCALE, w.SPAWN_HERO_RADIUS_Y * w.CRATE_RING_C_SCALE, PI * 0.25, 2, true)

func place_crate_ring(count: int, radius_x: float, radius_y: float, rot: float, ring_id: int, red_first: bool) -> void:
	var radial_scale := 1.0
	var scales: Array[float] = []
	for i in range(16):
		scales.append(1.0 + float(i) * 0.028)
	for i in range(1, 12):
		scales.append(1.0 - float(i) * 0.028)
	for scale_try in scales:
		var blocked := false
		for n in range(count):
			var ang := -PI * 0.5 + rot + TAU * float(n) / float(count)
			var dir: Vector2 = Vector2.RIGHT.rotated(ang)
			var pos: Vector2 = w.ARENA_CENTER + Vector2(dir.x * radius_x * scale_try, dir.y * radius_y * scale_try)
			pos = w.arena.clamp_arena_point(pos, w.CRATE_RADIUS)
			if w.arena.point_in_cover(pos, w.CRATE_RADIUS):
				blocked = true
				break
		if not blocked:
			radial_scale = scale_try
			break
	for n in range(count):
		var ang := -PI * 0.5 + rot + TAU * float(n) / float(count)
		var dir: Vector2 = Vector2.RIGHT.rotated(ang)
		var pos: Vector2 = w.ARENA_CENTER + Vector2(dir.x * radius_x * radial_scale, dir.y * radius_y * radial_scale)
		pos = w.arena.clamp_arena_point(pos, w.CRATE_RADIUS)
		var is_red := (n % 2 == 0) if red_first else (n % 2 == 1)
		w.crates.append({
			"id":w.crates.size(),
			"pos":pos,
			"hp":w.CRATE_MAX_HP,
			"max_hp":w.CRATE_MAX_HP,
			"alive":true,
			"ring":ring_id,
			"orb_red":is_red
		})

func hurt_crate(index: int, damage: float, show_number: bool = true) -> void:
	if index < 0 or index >= w.crates.size():
		return
	var crate: Dictionary = w.crates[index]
	if not bool(crate["alive"]) or damage <= 0.0:
		return
	crate["hp"] = float(crate["hp"]) - damage
	if show_number and damage > 0.4:
		w.event_log.emit(w.tick, &"crate_hit", -1, -1, {"crate":index, "damage":damage, "pos":Vector2(crate["pos"])})
	if float(crate["hp"]) <= 0.0:
		crate["hp"] = 0.0
		crate["alive"] = false
		w.crates[index] = crate
		spawn_crate_orb(Vector2(crate["pos"]), bool(crate["orb_red"]))
		w.proj.add_effect(&"explosion", Vector2(crate["pos"]), 42.0, 0.28, Color("#c48a4a"), "CRATE")
		w.event_log.emit(w.tick, &"crate_broke", -1, -1, {"crate":index, "red":bool(crate["orb_red"])})
		return
	w.crates[index] = crate

func damage_crates_at(center: Vector2, radius: float, damage: float) -> void:
	for crate_i in range(w.crates.size()):
		var crate: Dictionary = w.crates[crate_i]
		if not bool(crate["alive"]):
			continue
		if center.distance_to(Vector2(crate["pos"])) <= radius + w.CRATE_RADIUS:
			hurt_crate(crate_i, damage)

func spawn_crate_orb(pos: Vector2, is_red: bool) -> void:
	w.crate_orbs.append({
		"pos":pos,
		"home":pos,
		"red":is_red,
		"arm":w.CRATE_ORB_ARM,
		"magnet_slot":-1,
		"active":true
	})

func update_crate_orbs(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for orb0 in w.crate_orbs:
		var orb: Dictionary = orb0
		if not bool(orb.get("active", true)):
			continue
		orb["arm"] = maxf(0.0, float(orb.get("arm", 0.0)) - dt)
		if float(orb["arm"]) <= 0.0:
			var magnet_slot := int(orb.get("magnet_slot", -1))
			if magnet_slot < 0 or magnet_slot >= w.heroes.size() or not bool(w.heroes[magnet_slot]["alive"]) or bool(w.heroes[magnet_slot]["eliminated"]):
				magnet_slot = nearest_orb_target(orb)
				orb["magnet_slot"] = magnet_slot
			if magnet_slot >= 0:
				var target_pos: Vector2 = w.heroes[magnet_slot]["pos"]
				orb["pos"] = Vector2(orb["pos"]).move_toward(target_pos, w.HEALTH_PICKUP_MAGNET_SPEED * dt)
				if Vector2(orb["pos"]).distance_to(target_pos) <= w.HERO_RADIUS + w.CRATE_ORB_RADIUS:
					collect_crate_orb(magnet_slot, orb)
					continue
		kept.append(orb)
	w.crate_orbs = kept

func nearest_orb_target(orb: Dictionary) -> int:
	var best := -1
	var best_distance: float = w.HEALTH_PICKUP_MAGNET_RADIUS
	for slot in range(w.heroes.size()):
		if not bool(w.heroes[slot]["alive"]) or bool(w.heroes[slot]["eliminated"]):
			continue
		var distance := Vector2(w.heroes[slot]["pos"]).distance_to(Vector2(orb["pos"]))
		if distance < best_distance:
			best_distance = distance
			best = slot
	return best

func collect_crate_orb(slot: int, orb: Dictionary) -> void:
	var h: Dictionary = w.heroes[slot]
	if bool(orb.get("red", true)):
		h["dmg_orb_time"] = w.CRATE_ORB_DMG_TIME
		w.heroes[slot] = h
		w.proj.add_effect(&"heal_pickup", Vector2(h["pos"]), 58.0, 0.40, Color("#ff4f4f"), "DMG UP")
		w.event_log.emit(w.tick, &"dmg_orb", slot, -1, {})
	else:
		h["ultimate_charge"] = minf(w.ULTIMATE_MAX, float(h.get("ultimate_charge", 0.0)) + w.ULTIMATE_MAX * w.CRATE_ORB_ULT_RATIO)
		w.heroes[slot] = h
		w.proj.add_effect(&"heal_pickup", Vector2(h["pos"]), 58.0, 0.40, Color("#4f8cff"), "POWER")
		w.event_log.emit(w.tick, &"ult_orb", slot, -1, {"charge":float(h["ultimate_charge"])})

func best_crate(slot: int) -> int:
	var h: Dictionary = w.heroes[slot]
	var best := -1
	var best_distance := 480.0
	for crate_i in range(w.crates.size()):
		var crate: Dictionary = w.crates[crate_i]
		if not bool(crate["alive"]):
			continue
		var distance := Vector2(h["pos"]).distance_to(Vector2(crate["pos"]))
		if distance < best_distance:
			best_distance = distance
			best = crate_i
	return best

func best_crate_orb(slot: int) -> int:
	var h: Dictionary = w.heroes[slot]
	var best := -1
	var best_distance := 420.0
	for orb_i in range(w.crate_orbs.size()):
		var orb: Dictionary = w.crate_orbs[orb_i]
		if not bool(orb.get("active", true)):
			continue
		if float(orb.get("arm", 0.0)) > 0.0:
			continue
		var distance := Vector2(h["pos"]).distance_to(Vector2(orb["pos"]))
		if distance < best_distance:
			best_distance = distance
			best = orb_i
	return best

func update_health_pickups(dt: float) -> void:
	for pickup_index in range(w.health_pickups.size()):
		var pickup: Dictionary = w.health_pickups[pickup_index]
		if not bool(pickup["active"]):
			pickup["respawn"] = maxf(0.0, float(pickup["respawn"]) - dt)
			if float(pickup["respawn"]) <= 0.0:
				if bool(pickup.get("ephemeral", false)):
					pickup["active"] = false
					pickup["respawn"] = 99999.0
				else:
					pickup["active"] = true
					pickup["pos"] = Vector2(pickup["home"])
					pickup["magnet_slot"] = -1
					pickup["ignore_slot"] = -1
					pickup["ignore_time"] = 0.0
					if w.mode == w.ITEM_POOL_MODE:
						w.act_item.roll_pickup_kind(pickup)
					w.proj.add_effect(&"heal_ready", Vector2(pickup["pos"]), 62.0, 0.55, Color("#6ef3a5"), "HEAL READY")
		pickup["ignore_time"] = maxf(0.0, float(pickup.get("ignore_time", 0.0)) - dt)
		if bool(pickup["active"]):
			var magnet_slot := int(pickup.get("magnet_slot", -1))
			if not pickup_target_valid(magnet_slot, pickup, w.HEALTH_PICKUP_MAGNET_RADIUS * 1.65):
				magnet_slot = nearest_pickup_target(pickup)
				pickup["magnet_slot"] = magnet_slot
			if magnet_slot >= 0:
				var target_pos := Vector2(w.heroes[magnet_slot]["pos"])
				pickup["pos"] = Vector2(pickup["pos"]).move_toward(target_pos, w.HEALTH_PICKUP_MAGNET_SPEED * dt)
				if Vector2(pickup["pos"]).distance_to(target_pos) <= w.HERO_RADIUS + w.HEALTH_PICKUP_RADIUS:
					var h: Dictionary = w.heroes[magnet_slot]
					var carried := int(h.get("medkits", 0))
					if w.mode == w.ITEM_POOL_MODE:
						pickup = w.act_item.collect_item_pickup(magnet_slot, pickup)
					elif w.mode in w.MEDKIT_MODES and carried < w.MEDKIT_MAX:
						h["medkits"] = carried + 1
						w.heroes[magnet_slot] = h
						pickup["active"] = false
						pickup["respawn"] = w.HEALTH_PICKUP_RESPAWN
						pickup["magnet_slot"] = -1
						pickup["pos"] = Vector2(pickup["home"])
						w.proj.add_effect(&"heal_pickup", target_pos, 64.0, 0.38, Color("#6ef3a5"), tr("MEDKIT_PICKUP"))
						w.event_log.emit(w.tick, &"medkit_collected", magnet_slot, -1, {"pickup":pickup_index, "carried":carried + 1})
					else:
						var missing_health := float(h["max_hp"]) - float(h["hp"])
						var heal_amount := minf(missing_health, float(h["max_hp"]) * w.HEALTH_PICKUP_HEAL_RATIO)
						w.dmg.heal_hero(magnet_slot, heal_amount)
						pickup["active"] = false
						pickup["respawn"] = w.HEALTH_PICKUP_RESPAWN
						pickup["magnet_slot"] = -1
						pickup["pos"] = Vector2(pickup["home"])
						var pickup_label := "+%d HP" % roundi(heal_amount) if heal_amount > 0.01 else "POTION TAKEN"
						w.proj.add_effect(&"heal_pickup", target_pos, 64.0, 0.38, Color("#6ef3a5"), pickup_label)
						w.event_log.emit(w.tick, &"health_pickup_collected", magnet_slot, -1, {"pickup":pickup_index, "amount":heal_amount})
			else:
				pickup["pos"] = Vector2(pickup["pos"]).move_toward(Vector2(pickup["home"]), w.HEALTH_PICKUP_RETURN_SPEED * dt)
		w.health_pickups[pickup_index] = pickup

func pickup_target_valid(slot: int, pickup: Dictionary, max_distance: float) -> bool:
	if slot < 0 or slot >= w.heroes.size():
		return false
	var h: Dictionary = w.heroes[slot]
	if not bool(h["alive"]) or bool(h["eliminated"]) or float(h["launch_time"]) > 0.0:
		return false
	if int(pickup.get("ignore_slot", -1)) == slot and float(pickup.get("ignore_time", 0.0)) > 0.0:
		return false
	return Vector2(h["pos"]).distance_to(Vector2(pickup["pos"])) <= max_distance

func nearest_pickup_target(pickup: Dictionary) -> int:
	var best_slot := -1
	var best_distance: float = w.HEALTH_PICKUP_MAGNET_RADIUS
	for slot in range(w.heroes.size()):
		if not pickup_target_valid(slot, pickup, w.HEALTH_PICKUP_MAGNET_RADIUS):
			continue
		var distance := Vector2(w.heroes[slot]["pos"]).distance_to(Vector2(pickup["pos"]))
		if distance < best_distance:
			best_distance = distance
			best_slot = slot
	return best_slot
