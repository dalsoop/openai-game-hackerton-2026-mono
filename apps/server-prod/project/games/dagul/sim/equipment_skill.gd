class_name EquipmentSkill
extends RefCounted
## 우클릭 차지 스킬 — 원본 game-pjh-gang-up 의 발사 표.

const CHARGE_MAX := 1.15

static func apply_command(w, slot: int, command: Dictionary, facing: Vector2, dt: float) -> void:
	if slot < 0 or slot >= w.heroes.size():
		return
	var held := bool(command.get("equipment", false))
	var pressed := bool(command.get("equipment_pressed", false)) or bool(command.get("equipmentPressed", false))
	var released := bool(command.get("equipment_released", false)) or bool(command.get("equipmentReleased", false))
	if pressed or (held and not bool(w.heroes[slot].get("charging_skill", false))):
		begin_charge(w, slot, facing)
	if held and bool(w.heroes[slot].get("charging_skill", false)):
		continue_charge(w, slot, dt, facing)
	if released:
		release_charge(w, slot, facing)


static func begin_charge(w, slot: int, direction: Vector2) -> void:
	var h: Dictionary = w.heroes[slot]
	if not bool(h["alive"]) or bool(h.get("charging_skill", false)):
		return
	if float(h["equipment_cd"]) > 0.0 or float(h["launch_time"]) > 0.0:
		return
	if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
		return
	if w.roul.hero_has_timed(h, "turtle"):
		return
	w.act_item.cancel_attack_recovery(slot)
	h = w.heroes[slot]
	h["charging_skill"] = true
	h["charge_time"] = 0.0
	h["charge_dir"] = w.dmg.attack_direction(direction)
	h["action"] = &"CHARGING_SKILL"
	w.heroes[slot] = h
	w.event_log.emit(w.tick, &"skill_charge_started", slot, -1, {"equipment": h["equipment"]["id"]})


static func continue_charge(w, slot: int, dt: float, direction: Vector2) -> void:
	var h: Dictionary = w.heroes[slot]
	if not bool(h.get("charging_skill", false)):
		return
	if not bool(h["alive"]) or float(h["launch_time"]) > 0.0 or float(h["hitstun_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
		w.act_item.cancel_skill_charge(slot)
		return
	h["charge_time"] = minf(CHARGE_MAX, float(h["charge_time"]) + dt)
	h["charge_dir"] = w.dmg.attack_direction(direction)
	w.heroes[slot] = h


static func release_charge(w, slot: int, direction: Vector2) -> void:
	var h: Dictionary = w.heroes[slot]
	if not bool(h.get("charging_skill", false)):
		return
	var charge_ratio := clampf(float(h["charge_time"]) / CHARGE_MAX, 0.0, 1.0)
	var charge_dir: Vector2 = w.dmg.attack_direction(direction) if direction.length_squared() > 0.1 else Vector2(h.get("charge_dir", Vector2.RIGHT))
	h["charging_skill"] = false
	h["charge_time"] = 0.0
	w.heroes[slot] = h
	fire(w, slot, charge_dir, charge_ratio)


static func fire(w, slot: int, direction: Vector2, charge_ratio: float = 1.0) -> void:
	var h: Dictionary = w.heroes[slot]
	if not bool(h["alive"]) or float(h["equipment_cd"]) > 0.0:
		return
	if float(h["launch_time"]) > 0.0 or float(h["hitstun_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
		return
	var equipment: Dictionary = h["equipment"]
	var dir: Vector2 = w.dmg.attack_direction(direction)
	charge_ratio = clampf(charge_ratio, 0.0, 1.0)
	var power := lerpf(0.65, 1.25, charge_ratio)
	var reach := lerpf(0.80, 1.18, charge_ratio)
	var radius := lerpf(0.84, 1.22, charge_ratio)
	if not _fire_kind(w, slot, str(equipment["id"]), equipment, dir, power, reach, radius, charge_ratio):
		return
	h = w.heroes[slot]
	h["action"] = &"CHARGED_SKILL"
	w.proj.add_effect(&"charge_release", Vector2(h["pos"]), 54.0 + charge_ratio * 28.0, 0.22, Color("#dff8ff"), "", dir)
	h["equipment_cd"] = float(equipment.get("cooldown", 3.4))
	w.heroes[slot] = h
	if slot == w.local_slot:
		w.impact_ticks = maxi(w.impact_ticks, 8)
	w.event_log.emit(w.tick, &"equipment_used", slot, -1, {"equipment": equipment["id"], "charge": charge_ratio})


static func _fire_kind(w, slot: int, eid: String, eq: Dictionary, dir: Vector2, power: float, reach: float, radius: float, charge: float) -> bool:
	var dmg := float(eq.get("damage", 16.0)) * power
	var spd := float(eq.get("speed", 800.0))
	var rng := float(eq.get("range", 0.7)) * reach
	match eid:
		"scatter":
			_scatter(w, slot, dir, dmg, spd, rng, charge)
		"rail":
			w.proj.spawn_projectile(slot, dir, dmg, spd * reach, 7.0, rng, &"equipment", 0.0, false, 1 + roundi(charge * 3.0), 0.55 + 0.65 * charge, 90.0 + 70.0 * charge, &"beam", 0.0, "ANCHOR BREAK", true)
			w.proj.add_effect(&"line", Vector2(w.heroes[slot]["pos"]), 620.0 + 220.0 * charge, 0.30, Color("#71e7ff"), "", dir)
		"mortar":
			w.proj.add_zone(slot, Vector2(w.heroes[slot]["pos"]) + dir * 430.0 * reach, 120.0 * radius, lerpf(0.90, 0.62, charge), dmg, &"equipment", 0.80 + 0.70 * charge, 95.0 + 80.0 * charge, "SKYFALL", Color("#ff795c"), false, &"explosion", true)
		"leech":
			w.proj.add_zone(slot, Vector2(w.heroes[slot]["pos"]) + dir * 190.0 * reach, 68.0 * radius, 0.05, dmg, &"equipment", 0.45 + 0.45 * charge, -105.0 - 80.0 * charge, "BLOOD HARPOON", Color("#dc72ff"), true, &"drain", true)
			w.proj.add_effect(&"line", Vector2(w.heroes[slot]["pos"]), 360.0 + 240.0 * charge, 0.24, Color("#dc72ff"), "", dir)
		"breaker":
			_breaker(w, slot, dir, dmg, reach, radius, charge)
		"burst":
			_burst(w, slot, dir, dmg, spd, rng, charge)
		"blade":
			_blade(w, slot, dir, dmg, reach, radius, charge)
		"brawler":
			_displace(w, slot, dir * 130.0 * reach)
			w.proj.add_zone(slot, Vector2(w.heroes[slot]["pos"]), 88.0 * radius, 0.02, dmg, &"equipment", 0.38 + 0.42 * charge, 65.0 + 75.0 * charge, "LIVER SHOT", Color("#ff9466"), false, &"fist_burst", true)
		"bomb":
			w.deploy.place_mine(slot, Vector2(w.heroes[slot]["pos"]) + dir * 320.0 * reach, dmg, 118.0 * radius, lerpf(0.72, 0.52, charge), 8.0, 0.38, false)
		"spear":
			_displace(w, slot, dir * 150.0 * reach)
			w.proj.add_zone(slot, Vector2(w.heroes[slot]["pos"]) + dir * 120.0 * reach, 58.0 * radius, 0.03, dmg, &"equipment", 0.38 + 0.42 * charge, 95.0 + 85.0 * charge, "VAULT IMPALE", Color("#ffe27a"), false, &"spear_line", true)
			w.proj.add_effect(&"spear_line", Vector2(w.heroes[slot]["pos"]), 440.0 + 230.0 * charge, 0.26, Color("#ffe27a"), "", dir)
		"chain":
			w.proj.add_zone(slot, Vector2(w.heroes[slot]["pos"]) + dir * 175.0 * reach, 76.0 * radius, 0.18, dmg, &"equipment", 0.75 + 0.80 * charge, -105.0 - 75.0 * charge, "CHAIN LOCK", Color("#b78cff"), false, &"chain_arc", true, &"root")
			w.proj.add_effect(&"chain_arc", Vector2(w.heroes[slot]["pos"]), 390.0 + 250.0 * charge, 0.28, Color("#b78cff"), "", dir)
		"shield":
			_shield(w, slot, dir, charge)
		_:
			return false
	return true


static func _scatter(w, slot: int, dir: Vector2, dmg: float, spd: float, rng: float, charge: float) -> void:
	_displace(w, slot, -dir * lerpf(65.0, 120.0, charge))
	var n := 3 + roundi(charge * 4.0)
	for i in range(n):
		var off := (float(i) - float(n - 1) * 0.5) * 0.085
		w.proj.spawn_projectile(slot, dir.rotated(off), dmg, spd, 7.0, rng, &"equipment", 0.0, false, 0, 0.0, 28.0 + 34.0 * charge, &"pellet", 0.0, "BACKBLAST", i == 0)
	w.proj.add_effect(&"cast", Vector2(w.heroes[slot]["pos"]), 92.0 + 34.0 * charge, 0.26, Color("#ffb45c"), "", dir)


static func _breaker(w, slot: int, dir: Vector2, dmg: float, reach: float, radius: float, charge: float) -> void:
	var h: Dictionary = w.heroes[slot]
	h["super_armor_time"] = maxf(float(h["super_armor_time"]), 0.38 + 0.30 * charge)
	h["super_armor_strength"] = maxf(float(h["super_armor_strength"]), 0.58)
	w.heroes[slot] = h
	_displace(w, slot, dir * 175.0 * reach)
	w.proj.add_zone(slot, Vector2(w.heroes[slot]["pos"]), 112.0 * radius, 0.08, dmg, &"equipment", 0.85 + 0.75 * charge, 125.0 + 100.0 * charge, "CRASH ENTRY", Color("#ffd166"), false, &"shockwave", true)


static func _burst(w, slot: int, dir: Vector2, dmg: float, spd: float, rng: float, charge: float) -> void:
	var n := 2 + roundi(charge * 4.0)
	for i in range(n):
		var off := (float(i) - float(n - 1) * 0.5) * 0.055
		w.proj.spawn_projectile(slot, dir.rotated(off), dmg, spd, 8.0, rng, &"equipment", 18.0 + 16.0 * charge, false, 0, 0.0, 28.0 + 30.0 * charge, &"seeker", 2.4 + 2.0 * charge, "SEEKER SALVO", i == 0)
	w.proj.add_effect(&"cast", Vector2(w.heroes[slot]["pos"]), 78.0 + 24.0 * charge, 0.26, Color("#ff5da2"), "", dir)


static func _blade(w, slot: int, dir: Vector2, dmg: float, reach: float, radius: float, charge: float) -> void:
	var h: Dictionary = w.heroes[slot]
	h["evade_time"] = maxf(float(h["evade_time"]), 0.24 + 0.20 * charge)
	w.heroes[slot] = h
	_displace(w, slot, dir * 190.0 * reach)
	w.proj.add_zone(slot, Vector2(w.heroes[slot]["pos"]), 92.0 * radius, 0.03, dmg, &"equipment", 0.22 + 0.28 * charge, 78.0 + 70.0 * charge, "CROSS STEP", Color("#b9f3ff"), false, &"slashwave", true)


static func _shield(w, slot: int, dir: Vector2, charge: float) -> void:
	var h: Dictionary = w.heroes[slot]
	h["guard_time"] = 0.42 + 0.48 * charge
	w.heroes[slot] = h
	var wall_pos := Vector2(h["pos"]) + dir * (84.0 + 20.0 * charge)
	w.deploy.place_bounce_wall(slot, wall_pos, dir, lerpf(96.0, 142.0, charge), lerpf(0.92, 1.24, charge), lerpf(520.0, 720.0, charge), lerpf(10.0, 16.0, charge), lerpf(185.0, 255.0, charge))


static func _displace(w, slot: int, motion: Vector2) -> void:
	var h: Dictionary = w.heroes[slot]
	h["pos"] = w.arena.resolve_cover_motion(Vector2(h["pos"]), motion)
	w.heroes[slot] = h
