class_name MidTower
extends RefCounted

const TOWER_SPAWN_TIME := 75.0
const TOWER_RADIUS := 86.0
const TOWER_MAX_HP := 2400.0
const TOWER_RANGE := 820.0
const TOWER_INTERVAL := 1.85
const TOWER_DAMAGE := 22.0

var w

func _init(world) -> void:
	w = world

func reset_mid_tower() -> void:
	w.mid_tower = {
		"alive": false,
		"spawned": false,
		"pos": w.ARENA_CENTER,
		"hp": TOWER_MAX_HP,
		"max_hp": TOWER_MAX_HP,
		"fire_cd": 0.8,
		"pattern": 0,
		"boing": 0.0,
		"hits": {},
		"last_hit": -1
	}

func update_mid_tower(dt: float) -> void:
	if w.result != &"playing":
		return
	if not bool(w.mid_tower.get("spawned", false)) and w.match_time >= TOWER_SPAWN_TIME:
		w.mid_tower["spawned"] = true
		w.mid_tower["alive"] = true
		w.mid_tower["hp"] = TOWER_MAX_HP
		w.mid_tower["max_hp"] = TOWER_MAX_HP
		w.mid_tower["hits"] = {}
		w.mid_tower["last_hit"] = -1
		w.mid_tower["fire_cd"] = 1.2
		w.mid_tower["pattern"] = 0
		w.mid_tower["boing"] = 0.0
		w._announce("BOUNTY TOWER", 90)
		w.proj.add_effect(&"explosion", w.ARENA_CENTER, 90.0, 0.45, Color("#ffb347"), "TOWER")
		w.event_log.emit(w.tick, &"tower_spawned", -1, -1, {"hp":TOWER_MAX_HP})
		return
	if not bool(w.mid_tower.get("alive", false)):
		return
	w.mid_tower["boing"] = maxf(0.0, float(w.mid_tower.get("boing", 0.0)) - dt)
	w.mid_tower["fire_cd"] = maxf(0.0, float(w.mid_tower.get("fire_cd", 0.0)) - dt)
	tower_point_blank(dt)
	if float(w.mid_tower["fire_cd"]) > 0.0:
		return
	var best := -1
	var best_d := TOWER_RANGE
	var tpos: Vector2 = w.mid_tower["pos"]
	for slot in range(w.heroes.size()):
		if not bool(w.heroes[slot]["alive"]) or bool(w.heroes[slot].get("eliminated", false)):
			continue
		var d := tpos.distance_to(Vector2(w.heroes[slot]["pos"]))
		if d < best_d:
			best_d = d
			best = slot
	if best < 0:
		return
	var aim := tpos.direction_to(Vector2(w.heroes[best]["pos"]))
	if aim.length_squared() < 0.0001:
		aim = Vector2.RIGHT
	var pattern := int(w.mid_tower.get("pattern", 0)) % 3
	w.mid_tower["boing"] = 0.22
	if pattern == 0:
		tower_ring_shot(tpos, 10, 0.0)
		w.mid_tower["fire_cd"] = TOWER_INTERVAL
	elif pattern == 1:
		tower_fan_shot(tpos, aim, 7)
		w.mid_tower["fire_cd"] = TOWER_INTERVAL * 0.82
	else:
		tower_carpet(tpos, aim)
		w.mid_tower["fire_cd"] = TOWER_INTERVAL * 1.15
	w.mid_tower["pattern"] = pattern + 1
	w.event_log.emit(w.tick, &"tower_fire", -1, best, {"pattern":pattern})

func hurt_tower(owner: int, damage: float) -> void:
	if not bool(w.mid_tower.get("alive", false)) or damage <= 0.0:
		return
	w.mid_tower["hp"] = float(w.mid_tower["hp"]) - damage
	if owner >= 0:
		w.mid_tower["last_hit"] = owner
		var hits: Dictionary = w.mid_tower.get("hits", {})
		var key := str(owner)
		var rec: Dictionary = hits.get(key, {"dmg": 0.0, "tick": 0})
		rec["dmg"] = float(rec.get("dmg", 0.0)) + damage
		rec["tick"] = w.tick
		hits[key] = rec
		w.mid_tower["hits"] = hits
	w.event_log.emit(w.tick, &"tower_hit", owner, -1, {"damage": damage, "hp": float(w.mid_tower["hp"])})
	if float(w.mid_tower["hp"]) > 0.0:
		return
	w.mid_tower["hp"] = 0.0
	w.mid_tower["alive"] = false
	var killer := int(w.mid_tower.get("last_hit", -1))
	var hits2: Dictionary = w.mid_tower.get("hits", {})
	if killer >= 0 and killer < w.heroes.size() and bool(w.heroes[killer]["alive"]):
		for _i in range(3):
			w.roul.queue_roulette(killer, "wanted")
	for assist_slot in w.lifecycle.assist_slots(killer, -1, hits2):
		if int(assist_slot) == killer:
			continue
		w.roul.queue_roulette(int(assist_slot), "wanted")
	w._announce("TOWER DOWN", 80)
	w.proj.add_effect(&"explosion", Vector2(w.mid_tower["pos"]), 110.0, 0.55, Color("#ff5a4a"), "BOUNTY")
	w.event_log.emit(w.tick, &"tower_down", killer, -1, {"killer": killer})

func tower_shell(tpos: Vector2, dir: Vector2, speed: float, splash: float, dmg: float, ttl: float) -> void:
	var d = dir
	if d.length_squared() < 0.0001:
		d = Vector2.RIGHT
	d = d.normalized()
	w.projectiles.append({
		"id": w.next_entity_id,
		"owner": -1,
		"pos": tpos + d * (TOWER_RADIUS + 10.0),
		"vel": d * speed,
		"damage": dmg,
		"radius": 11.0,
		"ttl": ttl,
		"splash": splash,
		"leech": false,
		"pierce": 0,
		"cc_time": 0.0,
		"knockback": 22.0,
		"kind": &"shell",
		"homing": 0.0,
		"label": "TOWER",
		"combo_finisher": false,
		"control_kind": &"slow",
		"hit_targets": [],
		"trail": [tpos],
		"source": &"tower"
	})
	w.next_entity_id += 1

func tower_point_blank(dt: float) -> void:
	if not bool(w.mid_tower.get("alive", false)):
		return
	w.mid_tower["crush_cd"] = maxf(0.0, float(w.mid_tower.get("crush_cd", 0.0)) - dt)
	if float(w.mid_tower.get("crush_cd", 0.0)) > 0.0:
		return
	var tpos: Vector2 = w.mid_tower["pos"]
	var reach = TOWER_RADIUS + w.HERO_RADIUS + 26.0
	var hit_any := false
	for slot in range(w.heroes.size()):
		var h: Dictionary = w.heroes[slot]
		if not bool(h.get("alive", false)) or bool(h.get("eliminated", false)):
			continue
		if Vector2(h["pos"]).distance_to(tpos) > reach:
			continue
		hit_any = true
		w.dmg.damage_hero_environment(slot, TOWER_DAMAGE * 0.85, true)
		var push := tpos.direction_to(Vector2(h["pos"]))
		if push.length_squared() < 0.05:
			push = Vector2.RIGHT.rotated(float(slot))
		h = w.heroes[slot]
		h["pos"] = w.arena.resolve_cover_motion(Vector2(h["pos"]), push * 34.0)
		w.heroes[slot] = h
		w.proj.add_effect(&"explosion", Vector2(h["pos"]), 42.0, 0.18, Color("#ff7a3a"), "TOWER")
	if hit_any:
		w.mid_tower["crush_cd"] = 0.32
		w.mid_tower["boing"] = 0.16

func tower_ring_shot(tpos: Vector2, count: int, rot: float) -> void:
	for i in range(count):
		var d := Vector2.RIGHT.rotated(rot + TAU * float(i) / float(count))
		tower_shell(tpos, d, 620.0, 46.0, TOWER_DAMAGE, 1.15)

func tower_fan_shot(tpos: Vector2, aim: Vector2, count: int) -> void:
	var mid := (count - 1) * 0.5
	for i in range(count):
		var ang := (float(i) - mid) * 0.18
		tower_shell(tpos, aim.rotated(ang), 860.0, 58.0, TOWER_DAMAGE + 4.0, 0.95)

func tower_carpet(tpos: Vector2, aim: Vector2) -> void:
	for i in range(6):
		var side := -1.0 if i % 2 == 0 else 1.0
		var dist := 170.0 + float(i) * 95.0
		var land := tpos + aim * dist + aim.orthogonal() * side * (40.0 + float(i) * 18.0)
		w.proj.add_zone(-1, land, 78.0, 0.42 + float(i) * 0.08, TOWER_DAMAGE + 8.0, &"tower", 0.0, 26.0, "BOOM", Color("#ff7a3a"), false, &"explosion")
	tower_fan_shot(tpos, aim, 3)
