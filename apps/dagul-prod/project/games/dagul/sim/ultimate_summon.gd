class_name UltimateSummon
extends RefCounted

var w

func _init(world) -> void:
	w = world

func begin_rat_tide(slot: int, aim_pos: Vector2) -> void:
	var h: Dictionary = w.heroes[slot]
	var dir: Vector2 = Vector2(h["pos"]).direction_to(aim_pos)
	if dir.length_squared() < 0.05:
		dir = Vector2(h.get("facing", Vector2.RIGHT))
	if dir.length_squared() < 0.05:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	w.rat_tides.append({
		"owner": slot,
		"pos": Vector2(h["pos"]) + dir * 70.0,
		"dir": dir,
		"life": 1.70,
		"travel": 720.0,
		"half_w": 118.0,
		"length": 360.0
	})
	w.ult_animal.set_ultimate_focus(slot, 0.28)
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "rat_tide"})

func hero_in_rat_tide(hpos: Vector2, tide: Dictionary) -> bool:
	var dir: Vector2 = tide["dir"]
	var rel: Vector2 = hpos - Vector2(tide["pos"])
	var along := rel.dot(dir)
	var side := absf(rel.dot(dir.rotated(PI * 0.5)))
	var leng := float(tide.get("length", 360.0))
	return along > -leng * 0.28 and along < leng * 0.72 and side <= float(tide.get("half_w", 118.0))

func apply_rat_tides(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for tide0 in w.rat_tides:
		var tide: Dictionary = tide0
		tide["life"] = float(tide.get("life", 0.0)) - dt
		if float(tide["life"]) <= 0.0:
			continue
		var dir: Vector2 = Vector2(tide["dir"])
		tide["pos"] = Vector2(tide["pos"]) + dir * float(tide.get("travel", 720.0)) * dt
		_push_rat_tide_heroes(tide, dir)
		kept.append(tide)
	w.rat_tides = kept

func _push_rat_tide_heroes(tide: Dictionary, dir: Vector2) -> void:
	for slot in range(w.heroes.size()):
		if slot == int(tide.get("owner", -1)):
			continue
		var h: Dictionary = w.heroes[slot]
		if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
			continue
		if not hero_in_rat_tide(Vector2(h["pos"]), tide):
			continue
		var wish: Vector2 = h.get("vel", Vector2.ZERO)
		var along := wish.dot(dir)
		var resist := 1.0
		if along < -20.0:
			resist = 0.40
		var lateral: Vector2 = wish - dir * along
		h["vel"] = lateral * 0.50 + dir * (860.0 * resist)
		w.heroes[slot] = h

func begin_dragon_smoke(slot: int) -> void:
	var h: Dictionary = w.heroes[slot]
	w.dragon_smokes.append({
		"owner": slot,
		"pos": Vector2(h["pos"]),
		"radius": 300.0,
		"ttl": 15.0
	})
	w.ult_animal.set_ultimate_focus(slot, 0.22)
	w._add_effect(&"afterimage", Vector2(h["pos"]), 90.0, 0.28, Color("#c8c8c8"), "SMOKE")
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "dragon_smoke"})

func tick_dragon_smokes(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for smoke0 in w.dragon_smokes:
		var smoke: Dictionary = smoke0
		smoke["ttl"] = float(smoke.get("ttl", 0.0)) - dt
		if float(smoke["ttl"]) > 0.0:
			kept.append(smoke)
	w.dragon_smokes = kept

func pos_in_dragon_smoke(pos: Vector2) -> bool:
	for smoke in w.dragon_smokes:
		if pos.distance_to(Vector2(smoke.get("pos", Vector2.ZERO))) <= float(smoke.get("radius", 560.0)):
			return true
	return false

func hero_hidden_in_smoke(slot: int) -> bool:
	if slot < 0 or slot >= w.heroes.size():
		return false
	var h: Dictionary = w.heroes[slot]
	if not bool(h.get("alive", false)):
		return false
	if not pos_in_dragon_smoke(Vector2(h["pos"])):
		return false
	var local_animal := 0
	if w.local_slot >= 0 and w.local_slot < w.heroes.size():
		local_animal = posmod(int(w.heroes[w.local_slot].get("animal", w.local_slot)), 12)
	if slot == w.local_slot and local_animal == 4:
		return false
	return true

func local_is_dragon() -> bool:
	if w.local_slot < 0 or w.local_slot >= w.heroes.size():
		return false
	return posmod(int(w.heroes[w.local_slot].get("animal", w.local_slot)), 12) == 4

func begin_snake_shed(slot: int) -> void:
	var h: Dictionary = w.heroes[slot]
	var max_hp := float(h.get("max_hp", 164.0))
	w.snake_skins.append({
		"owner": slot,
		"pos": Vector2(h["pos"]),
		"facing": Vector2(h.get("facing", Vector2.RIGHT)),
		"aim": Vector2(h.get("aim", Vector2.RIGHT)),
		"animal": 5,
		"hp": max_hp,
		"max_hp": max_hp,
		"scale": 1.5,
		"ttl": 18.0,
		"flash": 0.0,
		"alive": true
	})
	w._apply_roulette_face(slot, {"id":"giant", "name":"GIANT", "kind":"timed", "atk":3.0, "spd":5.0, "def":0.0, "hp":3.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":12.0})
	w.ult_animal.set_ultimate_focus(slot, 0.28)
	w._add_effect(&"afterimage", Vector2(h["pos"]), 64.0, 0.32, Color("#9ad47a"), "SHED")
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "snake_shed"})

func tick_snake_skins(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for skin0 in w.snake_skins:
		var skin: Dictionary = skin0
		if not bool(skin.get("alive", true)):
			continue
		skin["ttl"] = float(skin.get("ttl", 0.0)) - dt
		skin["flash"] = maxf(0.0, float(skin.get("flash", 0.0)) - dt)
		if float(skin["ttl"]) <= 0.0 or float(skin.get("hp", 0.0)) <= 0.0:
			w._add_effect(&"hit_spark", Vector2(skin["pos"]), 48.0, 0.24, Color("#b7d59a"), "")
			continue
		kept.append(skin)
	w.snake_skins = kept

func hurt_snake_skin(index: int, damage: float) -> bool:
	if index < 0 or index >= w.snake_skins.size():
		return false
	var skin: Dictionary = w.snake_skins[index]
	if not bool(skin.get("alive", true)) or damage <= 0.0:
		return false
	skin["hp"] = float(skin.get("hp", 0.0)) - damage
	skin["flash"] = 0.11
	w.event_log.emit(w.tick, &"snake_shed_hit", -1, -1, {"damage": damage, "pos": Vector2(skin["pos"])})
	if float(skin["hp"]) <= 0.0:
		skin["hp"] = 0.0
		skin["alive"] = false
		w.snake_skins[index] = skin
		w._add_effect(&"hit_spark", Vector2(skin["pos"]), 52.0, 0.28, Color("#c8e8a8"), "SHED")
		w.event_log.emit(w.tick, &"snake_shed_break", -1, -1, {})
		return true
	w.snake_skins[index] = skin
	return true

func hit_snake_skin(owner: int, ppos: Vector2, radius: float, damage: float) -> bool:
	var best := -1
	var best_d := 99999.0
	for i in range(w.snake_skins.size()):
		var skin: Dictionary = w.snake_skins[i]
		if not bool(skin.get("alive", true)):
			continue
		if int(skin.get("owner", -1)) == owner:
			continue
		var d := ppos.distance_to(Vector2(skin.get("pos", Vector2.ZERO)))
		var skin_r = w.HERO_RADIUS * float(skin.get("scale", 1.5))
		if d < radius + skin_r and d < best_d:
			best_d = d
			best = i
	if best < 0:
		return false
	return hurt_snake_skin(best, damage)

func begin_pig_mud(slot: int) -> void:
	var h: Dictionary = w.heroes[slot]
	w.pig_muds.append({
		"owner": slot,
		"pos": Vector2(h["pos"]),
		"radius": 200.0,
		"ttl": 6.0
	})
	w.ult_animal.set_ultimate_focus(slot, 0.18)
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "pig_mud"})

func tick_pig_muds(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for mud0 in w.pig_muds:
		var mud: Dictionary = mud0
		mud["ttl"] = float(mud.get("ttl", 0.0)) - dt
		if float(mud["ttl"]) > 0.0:
			kept.append(mud)
	w.pig_muds = kept

func pos_in_enemy_mud(slot: int) -> bool:
	if slot < 0 or slot >= w.heroes.size():
		return false
	var pos: Vector2 = w.heroes[slot]["pos"]
	for mud in w.pig_muds:
		if int(mud.get("owner", -1)) == slot:
			continue
		if pos.distance_to(Vector2(mud.get("pos", Vector2.ZERO))) <= float(mud.get("radius", 200.0)):
			return true
	return false

func begin_rooster_egg(slot: int) -> void:
	var h: Dictionary = w.heroes[slot]
	w.rooster_eggs.append({
		"owner": slot,
		"pos": Vector2(h["pos"]),
		"ttl": 8.0,
		"arm": 0.55,
		"trigger": 150.0,
		"alive": true
	})
	w.ult_animal.set_ultimate_focus(slot, 0.18)
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "rooster_egg"})

func tick_rooster_eggs(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for egg0 in w.rooster_eggs:
		var egg: Dictionary = egg0
		if not bool(egg.get("alive", true)):
			continue
		egg["ttl"] = float(egg.get("ttl", 0.0)) - dt
		egg["arm"] = maxf(0.0, float(egg.get("arm", 0.0)) - dt)
		if float(egg["ttl"]) <= 0.0:
			continue
		var origin: Vector2 = egg.get("pos", Vector2.ZERO)
		var trig = float(egg.get("trigger", 150.0)) + w.HERO_RADIUS
		var owner := int(egg.get("owner", -1))
		var boom: bool = float(egg.get("arm", 0.0)) <= 0.0 and _rooster_egg_triggered(origin, trig, owner)
		if boom:
			explode_rooster_egg(egg)
			continue
		kept.append(egg)
	w.rooster_eggs = kept

# 알 폭발 트리거 — 소유자가 아닌 살아 있는 영웅이 감지 반경에 들어왔는지 판정한다.
func _rooster_egg_triggered(origin: Vector2, trigger: float, owner: int) -> bool:
	for t in range(w.heroes.size()):
		if t == owner:
			continue
		var hero: Dictionary = w.heroes[t]
		if not bool(hero.get("alive", false)) or bool(hero.get("eliminated", false)):
			continue
		if Vector2(hero["pos"]).distance_to(origin) <= trigger:
			return true
	return false

func explode_rooster_egg(egg: Dictionary) -> void:
	var origin: Vector2 = egg.get("pos", Vector2.ZERO)
	var owner := int(egg.get("owner", -1))
	var blast := 170.0
	for t in range(w.heroes.size()):
		if t == owner:
			continue
		var vic: Dictionary = w.heroes[t]
		if not bool(vic.get("alive", false)) or bool(vic.get("eliminated", false)):
			continue
		if bool(vic.get("burrowed", false)):
			continue
		if Vector2(vic["pos"]).distance_to(origin) > blast:
			continue
		var away: Vector2 = Vector2(vic["pos"]) - origin
		if away.length_squared() < 0.01:
			away = Vector2.RIGHT
		away = away.normalized()
		vic["stun_time"] = maxf(float(vic.get("stun_time", 0.0)), 1.20)
		vic["vel"] = away * 220.0
		w.heroes[t] = vic
	w._add_effect(&"stun_burst", origin, 70.0, 0.36, Color("#ffe27a"), "EGG")
	w.event_log.emit(w.tick, &"rooster_egg_boom", owner, -1, {})
