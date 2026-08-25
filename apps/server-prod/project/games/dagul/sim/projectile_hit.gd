class_name ProjectileHit
extends RefCounted

var w

func _init(world) -> void:
	w = world

func spawn_projectile(slot: int, direction: Vector2, damage: float, speed: float, radius: float, ttl: float, source: StringName, splash: float = 0.0, leech: bool = false, pierce: int = 0, cc_time: float = 0.0, knockback: float = 0.0, kind: StringName = &"bolt", homing: float = 0.0, label: String = "", combo_finisher: bool = false, control_kind: StringName = &"slow") -> void:
	var dir = w.dmg.attack_direction(direction)
	w.projectiles.append({
		"id":w.next_entity_id,
		"owner":slot,
		"pos":w.dmg.muzzle_spawn_pos(slot, dir),
		"vel":dir * speed,
		"damage":damage,
		"radius":radius,
		"ttl":ttl,
		"splash":splash,
		"leech":leech,
		"pierce":pierce,
		"cc_time":cc_time,
		"knockback":knockback,
		"kind":kind,
		"homing":homing,
		"label":label,
		"combo_finisher":combo_finisher,
		"control_kind":control_kind,
		"hit_targets":[],
		"trail":[w.dmg.muzzle_spawn_pos(slot, dir)],
		"source":source
	})
	w.next_entity_id += 1

func spawn_arc_bomb(slot: int, direction: Vector2, distance: float, flight_time: float, damage: float, blast_radius: float, cc_time: float, knockback: float, combo_finisher: bool) -> void:
	var dir = w.dmg.attack_direction(direction)
	var start = w.dmg.muzzle_spawn_pos(slot, dir)
	var landing = Vector2(w.heroes[slot]["pos"]) + dir * distance
	w.projectiles.append({
		"id":w.next_entity_id, "owner":slot, "pos":start,
		"vel":start.direction_to(landing) * start.distance_to(landing) / maxf(0.01, flight_time),
		"landing_pos":landing, "arc":true, "max_ttl":flight_time,
		"damage":damage, "radius":11.0, "ttl":flight_time,
		"splash":blast_radius, "leech":false, "pierce":0,
		"cc_time":cc_time, "knockback":knockback, "kind":&"shell",
		"homing":0.0, "label":"", "combo_finisher":combo_finisher,
		"hit_targets":[], "trail":[start], "source":&"normal"
	})
	w.next_entity_id += 1

func add_effect(kind: StringName, pos: Vector2, radius: float, duration: float, color: Color, label: String = "", direction: Vector2 = Vector2.RIGHT, follow_slot: int = -1) -> void:
	w.effects.append({"kind":kind, "pos":pos, "radius":radius, "time":duration, "max_time":duration, "color":color, "label":label, "direction":direction, "follow_slot":follow_slot})

func add_mobility_effect(slot: int, kind: StringName, start_pos: Vector2, end_pos: Vector2, radius: float, duration: float, color: Color, label: String, direction: Vector2, draw_departure: bool = true) -> void:
	var shortened_duration := duration * 0.80
	w.effects.append({
		"kind":kind,
		"pos":end_pos,
		"start_pos":start_pos,
		"follow_slot":slot,
		"radius":radius,
		"time":shortened_duration,
		"max_time":shortened_duration,
		"color":color,
		"label":label,
		"direction":direction,
		"draw_departure":draw_departure,
	})

func add_zone(owner: int, pos: Vector2, radius: float, delay: float, damage: float, source: StringName, cc_time: float, knockback: float, label: String, color: Color, leech: bool = false, effect_kind: StringName = &"explosion", combo_finisher: bool = false, control_kind: StringName = &"slow") -> void:
	w.zones.append({"id":w.next_entity_id, "owner":owner, "pos":pos, "radius":radius, "delay":delay, "warning_duration":delay, "time":delay + 0.28, "damage":damage, "applied":false, "source":source, "cc_time":cc_time, "knockback":knockback, "label":label, "color":color, "leech":leech, "effect_kind":effect_kind, "combo_finisher":combo_finisher, "control_kind":control_kind, "telegraphed":delay > 0.06})
	w.next_entity_id += 1

func projectile_impact_kind(kind: String) -> StringName:
	match kind:
		"beam": return &"beam_hit"
		"shell", "seeker": return &"explosion"
		"tether": return &"drain"
		"hammer": return &"hammer_slam"
		"slash": return &"slashwave"
		"fist": return &"fist_burst"
		"bomb": return &"explosion"
		"spear": return &"spear_line"
		"chain": return &"chain_arc"
		"shield": return &"shield_bash"
		_: return &"hit_spark"

func update_projectiles(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for p0 in w.projectiles:
		var p: Dictionary = p0
		if bool(p.get("arc", false)):
			_keep_arc_projectile(p, dt, kept)
			continue
		_apply_homing(p, dt)
		p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * dt
		var trail: Array = p.get("trail", [])
		_push_trail_point(trail, Vector2(p["pos"]))
		p["trail"] = trail
		p["ttl"] = float(p["ttl"]) - dt
		if _hit_cover(p):
			continue
		var owner := int(p["owner"])
		var hit := _hit_any_target(p, owner)
		if not hit:
			hit = _hit_world(p, owner)
		var projectile_pos: Vector2 = p["pos"]
		if not hit and float(p["ttl"]) > 0.0 and projectile_pos.x >= 0.0 and projectile_pos.x <= w.ARENA_SIZE.x and projectile_pos.y >= 0.0 and projectile_pos.y <= w.ARENA_SIZE.y:
			kept.append(p)
	w.projectiles = kept

func _keep_arc_projectile(p: Dictionary, dt: float, kept: Array[Dictionary]) -> void:
	if not _update_arc_projectile(p, dt).is_empty():
		kept.append(p)

func _push_trail_point(trail: Array, pos: Vector2) -> void:
	if w.tick % 2 == 0:
		trail.append(pos)
		if trail.size() > 14:
			trail.pop_front()

func _update_arc_projectile(p: Dictionary, dt: float) -> Dictionary:
	p["ttl"] = float(p["ttl"]) - dt
	p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * dt
	var arc_trail: Array = p.get("trail", [])
	if w.tick % 2 == 0:
		arc_trail.append(Vector2(p["pos"]))
		if arc_trail.size() > 14:
			arc_trail.pop_front()
	p["trail"] = arc_trail
	if float(p["ttl"]) <= 0.0:
		var landing: Vector2 = p["landing_pos"]
		add_zone(int(p["owner"]), landing, float(p["splash"]), 0.01, float(p["damage"]), &"normal", float(p["cc_time"]), float(p["knockback"]), "", Color("#ff554a"), false, &"explosion", bool(p["combo_finisher"]))
		var boom_t = 34.0 / 60.0 if str(w.heroes[int(p["owner"])]["equipment"].get("id", "")) == "mortar" else 0.32
		add_effect(&"explosion", landing, float(p["splash"]), boom_t, Color("#ff554a"), "")
		return {}
	return p

func _apply_homing(p: Dictionary, dt: float) -> void:
	if float(p.get("homing", 0.0)) <= 0.0:
		return
	var owner_slot := int(p["owner"])
	var nearest := -1
	var nearest_distance := 999999.0
	for candidate in range(w.PLAYER_COUNT):
		if candidate == owner_slot or not bool(w.heroes[candidate]["alive"]):
			continue
		var distance := Vector2(p["pos"]).distance_to(Vector2(w.heroes[candidate]["pos"]))
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	if nearest >= 0:
		var current_speed := Vector2(p["vel"]).length()
		var desired := Vector2(p["pos"]).direction_to(Vector2(w.heroes[nearest]["pos"]))
		var turn := clampf(float(p["homing"]) * dt, 0.0, 1.0)
		p["vel"] = Vector2(p["vel"]).normalized().lerp(desired, turn).normalized() * current_speed

func _hit_cover(p: Dictionary) -> bool:
	if not w.arena.point_in_cover(Vector2(p["pos"])):
		return false
	if float(p.get("splash", 0.0)) > 0.0:
		splash_damage(int(p["owner"]), Vector2(p["pos"]), float(p["splash"]), float(p["damage"]) * 0.55, -1, StringName(p["source"]), float(p.get("cc_time", 0.0)) * 0.65, float(p.get("knockback", 0.0)) * 0.65)
		add_effect(&"explosion", Vector2(p["pos"]), float(p["splash"]), 0.32, Color("#ff554a"), "")
	else:
		var impact_direction := -Vector2(p["vel"]).normalized()
		add_effect(&"hit_spark", Vector2(p["pos"]), 34.0, 0.24, Color("#c4d0df"), "", impact_direction)
	w.event_log.emit(w.tick, &"shot_blocked", int(p["owner"]), -1, {"source":p["source"], "pos":Vector2(p["pos"])})
	return true

func _hit_any_target(p: Dictionary, owner: int) -> bool:
	for target in range(w.PLAYER_COUNT):
		if target == owner or not bool(w.cores[target]["alive"]):
			continue
		if target in p["hit_targets"]:
			continue
		if w.ult_effect.absorb_wool_shield(owner, target, Vector2(p["pos"]), float(p["radius"])):
			return true
		if _hit_hero_with_projectile(p, owner, target):
			return true
		if owner >= 0 and Vector2(p["pos"]).distance_to(Vector2(w.cores[target]["pos"])) < float(p["radius"]) + w.CORE_RADIUS:
			w.dmg.damage_core(owner, target, float(p["damage"]) * 0.78, StringName(p["source"]))
			return true
	return false

func _hit_hero_with_projectile(p: Dictionary, owner: int, target: int) -> bool:
	if not bool(w.heroes[target]["alive"]) or bool(w.heroes[target].get("burrowed", false)) or Vector2(p["pos"]).distance_to(Vector2(w.heroes[target]["pos"])) >= float(p["radius"]) + w.HERO_RADIUS:
		return false
	var from_pos: Vector2 = Vector2(p["pos"])
	if owner >= 0 and owner < w.heroes.size():
		from_pos = Vector2(w.heroes[owner]["pos"])
	w.dmg.damage_hero(owner, target, float(p["damage"]), StringName(p["source"]), float(p["cc_time"]), float(p.get("knockback", 0.0)), from_pos, str(p.get("label", "")), projectile_impact_kind(str(p.get("kind", "bolt"))), bool(p.get("combo_finisher", false)), StringName(p.get("control_kind", &"slow")))
	if float(p["splash"]) > 0.0:
		splash_damage(owner, Vector2(p["pos"]), float(p["splash"]), float(p["damage"]) * 0.55, target, StringName(p["source"]), float(p["cc_time"]) * 0.65, float(p.get("knockback", 0.0)) * 0.65)
	if bool(p["leech"]):
		w.dmg.heal_hero(owner, float(p["damage"]) * 0.13)
	var hit_targets: Array = p["hit_targets"]
	hit_targets.append(target)
	p["hit_targets"] = hit_targets
	if int(p["pierce"]) > 0:
		p["pierce"] = int(p["pierce"]) - 1
		return false
	return true

func _hit_world(p: Dictionary, owner: int) -> bool:
	if w.ult_summon.hit_snake_skin(owner, Vector2(p["pos"]), float(p["radius"]), float(p["damage"])):
		return true
	if w.ult_effect.hit_ult_clone(owner, Vector2(p["pos"]), float(p["radius"])):
		return true
	for crate_i in range(w.crates.size()):
		var crate_hit: Dictionary = w.crates[crate_i]
		if not bool(crate_hit["alive"]):
			continue
		if Vector2(p["pos"]).distance_to(Vector2(crate_hit["pos"])) < float(p["radius"]) + w.CRATE_RADIUS:
			return _hit_crate(p, crate_i)
	if owner >= 0 and bool(w.mid_tower.get("alive", false)):
		if Vector2(p["pos"]).distance_to(Vector2(w.mid_tower["pos"])) < float(p["radius"]) + w.TOWER_RADIUS:
			return _hit_mid_tower(p, owner)
	return false

func _hit_crate(p: Dictionary, crate_i: int) -> bool:
	w.crate.hurt_crate(crate_i, float(p["damage"]))
	if float(p["splash"]) > 0.0:
		w.crate.damage_crates_at(Vector2(p["pos"]), float(p["splash"]), float(p["damage"]))
	return true

func _hit_mid_tower(p: Dictionary, owner: int) -> bool:
	w.tower.hurt_tower(owner, float(p["damage"]))
	if float(p["splash"]) > 0.0:
		w.tower.hurt_tower(owner, float(p["damage"]) * 0.35)
	return true

func splash_damage(owner: int, center: Vector2, radius: float, damage: float, primary: int, source: StringName, cc_time: float = 0.0, knockback: float = 0.0) -> void:
	for target in range(w.PLAYER_COUNT):
		if target == owner or target == primary or not bool(w.heroes[target]["alive"]):
			continue
		if center.distance_to(Vector2(w.heroes[target]["pos"])) <= radius:
			w.dmg.damage_hero(owner, target, damage, source, cc_time, knockback, center, "SPLASH", &"explosion")
	w.crate.damage_crates_at(center, radius, damage)
	for si in range(w.snake_skins.size()):
		var sk: Dictionary = w.snake_skins[si]
		if not bool(sk.get("alive", true)):
			continue
		if int(sk.get("owner", -1)) == owner:
			continue
		if center.distance_to(Vector2(sk.get("pos", Vector2.ZERO))) <= radius + w.HERO_RADIUS * float(sk.get("scale", 1.5)):
			w.ult_summon.hurt_snake_skin(si, damage)

func update_zones(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for z0 in w.zones:
		var z: Dictionary = z0
		z["delay"] = maxf(0.0, float(z.get("delay", 0.0)) - dt)
		if not bool(z["applied"]) and float(z["delay"]) <= 0.0:
			_apply_zone_damage(z)
		z["time"] = float(z["time"]) - dt
		if float(z["time"]) > 0.0:
			kept.append(z)
	w.zones = kept

func _apply_zone_damage(z: Dictionary) -> void:
	z["applied"] = true
	var owner := int(z["owner"])
	var total_damage := 0.0
	for target in range(w.PLAYER_COUNT):
		if target == owner or not bool(w.heroes[target]["alive"]):
			continue
		if Vector2(z["pos"]).distance_to(Vector2(w.heroes[target]["pos"])) <= float(z["radius"]) + w.HERO_RADIUS:
			w.dmg.damage_hero(owner, target, float(z["damage"]), StringName(z.get("source", &"equipment")), float(z.get("cc_time", 0.0)), float(z.get("knockback", 52.0)), Vector2(z["pos"]), "", &"hit_spark", bool(z.get("combo_finisher", false)), StringName(z.get("control_kind", &"slow")))
			total_damage += float(z["damage"])
	for target in range(w.PLAYER_COUNT):
		if target == owner or not bool(w.cores[target]["alive"]):
			continue
		if Vector2(z["pos"]).distance_to(Vector2(w.cores[target]["pos"])) <= float(z["radius"]) + w.CORE_RADIUS:
			w.dmg.damage_core(owner, target, float(z["damage"]) * 0.72, StringName(z.get("source", &"equipment")))
	if bool(z.get("leech", false)) and total_damage > 0.0:
		w.dmg.heal_hero(owner, total_damage * 0.32)
	var zone_direction = Vector2(w.heroes[owner]["pos"]).direction_to(Vector2(z["pos"]))
	if zone_direction.length_squared() < 0.1:
		zone_direction = Vector2(w.heroes[owner]["aim"])
	if StringName(z.get("source", &"equipment")) != &"normal" or bool(z.get("telegraphed", false)):
		add_effect(StringName(z.get("effect_kind", &"explosion")), Vector2(z["pos"]), float(z["radius"]), 0.34, Color(z.get("color", Color.WHITE)), "", zone_direction)
	w.crate.damage_crates_at(Vector2(z["pos"]), float(z["radius"]), float(z["damage"]))

func update_effects(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for effect0 in w.effects:
		var effect: Dictionary = effect0
		effect["time"] = float(effect["time"]) - dt
		if float(effect["time"]) > 0.0:
			kept.append(effect)
	w.effects = kept
