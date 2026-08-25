class_name UltimateAnimal
extends RefCounted

var w

func _init(world) -> void:
	w = world

func set_ultimate_focus(slot: int, time: float) -> void:
	if slot != w.local_slot:
		return
	w.ultimate_focus_slot = slot
	w.ultimate_focus_time = time
	w.ultimate_focus_max = maxf(0.16, time)

func try_ultimate(slot: int, _direction: Vector2) -> void:
	if slot < 0 or slot >= w.heroes.size():
		return
	var h: Dictionary = w.heroes[slot]
	if not bool(h.get("alive", false)):
		return
	if float(h.get("ultimate_charge", 0.0)) < w.ULTIMATE_MAX - 0.5:
		return
	var animal := posmod(int(h.get("animal", slot)), 12)
	if animal < 0 or animal > 11:
		return
	h["ultimate_charge"] = 0.0
	h["ultimates"] = int(h.get("ultimates", 0)) + 1
	w.heroes[slot] = h
	match animal:
		0: w.ult_summon.begin_rat_tide(slot, _direction)
		1: begin_ox_gore(slot, _direction)
		2: begin_tiger_roar(slot)
		3: begin_rabbit_burrow(slot, _direction)
		4: w.ult_summon.begin_dragon_smoke(slot)
		5: w.ult_summon.begin_snake_shed(slot)
		6: begin_horse_kick(slot, _direction)
		7: w._begin_wool_shield(slot)
		9: w.ult_summon.begin_rooster_egg(slot)
		10: begin_dog_fetch(slot, _direction)
		11: w.ult_summon.begin_pig_mud(slot)
		_: _spawn_mirage_clones(slot, h)

func _spawn_mirage_clones(slot: int, h: Dictionary) -> void:
	h["ult_clone_time"] = 8.0
	var origin: Vector2 = h["pos"]
	var clones: Array = []
	for i in range(1, 8):
		var ang := TAU * 0.125 * float(i)
		clones.append({
			"alive": true, "ang": ang, "pos": origin,
			"facing": Vector2(h.get("facing", Vector2.RIGHT)).rotated(ang),
			"aim": Vector2(h.get("aim", Vector2.RIGHT)).rotated(ang),
			"hop_time": float(h.get("hop_time", 0.0)),
			"hop_height": float(h.get("hop_height", w.HOP_LIFT_DEFAULT)),
			"animal": int(h.get("animal", slot)), "owner": slot
		})
	h["ult_clones"] = clones
	w.heroes[slot] = h
	set_ultimate_focus(slot, 0.28)
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "mirage", "clones": 7})

func begin_ox_gore(slot: int, aim_pos: Vector2) -> void:
	var h: Dictionary = w.heroes[slot]
	var dir: Vector2 = Vector2(h["pos"]).direction_to(aim_pos)
	if dir.length_squared() < 0.05:
		dir = Vector2(h.get("facing", Vector2.RIGHT))
	if dir.length_squared() < 0.05:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	h["ox_phase"] = "back"
	h["ox_time"] = 0.18
	h["ox_dir"] = dir
	h["ox_hit"] = []
	h["facing"] = dir
	w.heroes[slot] = h
	set_ultimate_focus(slot, 0.40)
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "ox_gore"})

func tick_ox_charges(dt: float) -> void:
	for slot in range(w.heroes.size()):
		var h: Dictionary = w.heroes[slot]
		var phase := str(h.get("ox_phase", ""))
		if phase == "":
			continue
		if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
			h["ox_phase"] = ""
			w.heroes[slot] = h
			continue
		var dir: Vector2 = h.get("ox_dir", Vector2.RIGHT)
		if dir.length_squared() < 0.05:
			dir = Vector2.RIGHT
		dir = dir.normalized()
		h["ox_time"] = float(h.get("ox_time", 0.0)) - dt
		if phase == "back":
			_tick_ox_back(h, dir)
		elif phase == "rush":
			_tick_ox_rush(slot, h, dir)
		w.heroes[slot] = h

func _tick_ox_back(h: Dictionary, dir: Vector2) -> void:
	h["vel"] = -dir * 380.0
	h["facing"] = dir
	if float(h["ox_time"]) <= 0.0:
		h["ox_phase"] = "rush"
		h["ox_time"] = 0.38
		h["ox_hit"] = []

func _tick_ox_rush(slot: int, h: Dictionary, dir: Vector2) -> void:
	h["vel"] = dir * 1100.0
	h["facing"] = dir
	var hit: Array = h.get("ox_hit", [])
	_ox_rush_hits(slot, h, dir, hit)
	h["ox_hit"] = hit
	if float(h["ox_time"]) <= 0.0:
		h["ox_phase"] = ""
		h["vel"] = Vector2.ZERO

func _ox_rush_hits(slot: int, h: Dictionary, dir: Vector2, hit: Array) -> void:
	for other in range(w.heroes.size()):
		if other == slot or other in hit:
			continue
		var t: Dictionary = w.heroes[other]
		if not bool(t.get("alive", false)) or bool(t.get("downed", false)):
			continue
		if Vector2(h["pos"]).distance_to(Vector2(t["pos"])) > 62.0:
			continue
		hit.append(other)
		t["stun_time"] = maxf(float(t.get("stun_time", 0.0)), 1.35)
		t["vel"] = dir * 260.0
		t["pos"] = w._resolve_cover_motion(Vector2(t["pos"]), dir * 70.0)
		w.heroes[other] = t

func begin_dog_fetch(slot: int, aim_pos: Vector2) -> void:
	var h: Dictionary = w.heroes[slot]
	var dest: Vector2 = w._clamp_arena_point(aim_pos, w.HERO_RADIUS)
	dest = w._nudge_out_of_cover(dest, w.HERO_RADIUS)
	w.dog_bones.append({"pos": dest, "owner": slot, "ttl": 5.0})
	h["dog_rush"] = false
	h["dog_windup"] = 1.0
	h["dog_bone"] = dest
	h["dog_hit"] = []
	w.heroes[slot] = h
	set_ultimate_focus(slot, 0.18)
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "dog_fetch"})

func tick_dog_rush(dt: float) -> void:
	for slot in range(w.heroes.size()):
		var h: Dictionary = w.heroes[slot]
		if _tick_dog_windup(slot, h, dt):
			continue
		if not bool(h.get("dog_rush", false)):
			continue
		if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
			h["dog_rush"] = false
			h["dog_windup"] = 0.0
			w.heroes[slot] = h
			continue
		_tick_dog_rush_hero(slot, h)
	_decay_dog_bones(dt)

func _tick_dog_windup(slot: int, h: Dictionary, dt: float) -> bool:
	var wind := float(h.get("dog_windup", 0.0))
	if wind <= 0.0:
		return false
	wind = maxf(0.0, wind - dt)
	h["dog_windup"] = wind
	if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
		h["dog_windup"] = 0.0
		h["dog_rush"] = false
		w.heroes[slot] = h
		return true
	if wind <= 0.0:
		h["dog_rush"] = true
		h["dog_hit"] = []
		h["super_armor_time"] = 2.2
		h["super_armor_strength"] = 1.0
	w.heroes[slot] = h
	if not bool(h.get("dog_rush", false)):
		return true
	return false

func _tick_dog_rush_hero(slot: int, h: Dictionary) -> void:
	var dest: Vector2 = h.get("dog_bone", Vector2(h["pos"]))
	var pos: Vector2 = Vector2(h["pos"])
	var to: Vector2 = dest - pos
	if to.length() <= 36.0:
		h["dog_rush"] = false
		h["vel"] = Vector2.ZERO
		h["super_armor_time"] = 0.0
		w.heroes[slot] = h
		return
	var dir := to.normalized()
	h["facing"] = dir
	h["vel"] = dir * 1020.0
	h["super_armor_time"] = maxf(float(h.get("super_armor_time", 0.0)), 0.2)
	h["super_armor_strength"] = 1.0
	var hit: Array = h.get("dog_hit", [])
	for t in range(w.heroes.size()):
		if t == slot or t in hit:
			continue
		var vic: Dictionary = w.heroes[t]
		if not bool(vic.get("alive", false)) or bool(vic.get("eliminated", false)):
			continue
		if bool(vic.get("burrowed", false)):
			continue
		if pos.distance_to(Vector2(vic["pos"])) > 52.0:
			continue
		hit.append(t)
		var push := dir * 780.0
		vic["launch_vel"] = push
		vic["launch_time"] = maxf(float(vic.get("launch_time", 0.0)), 0.48)
		vic["stun_time"] = maxf(float(vic.get("stun_time", 0.0)), 1.25)
		vic["vel"] = push
		vic["pos"] = w._resolve_cover_motion(Vector2(vic["pos"]), dir * 90.0)
		w.heroes[t] = vic
	h["dog_hit"] = hit
	w.heroes[slot] = h

func _decay_dog_bones(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for bone0 in w.dog_bones:
		var bone: Dictionary = bone0
		bone["ttl"] = float(bone.get("ttl", 0.0)) - dt
		var owner := int(bone.get("owner", -1))
		if owner >= 0 and owner < w.heroes.size() and (bool(w.heroes[owner].get("dog_rush", false)) or float(w.heroes[owner].get("dog_windup", 0.0)) > 0.0):
			bone["ttl"] = maxf(float(bone["ttl"]), 0.05)
		if float(bone["ttl"]) > 0.0:
			kept.append(bone)
	w.dog_bones = kept

func begin_horse_kick(slot: int, aim_pos: Vector2 = Vector2.ZERO) -> void:
	var h: Dictionary = w.heroes[slot]
	var face: Vector2 = Vector2(h["pos"]).direction_to(aim_pos)
	if face.length_squared() < 0.05:
		face = Vector2(h.get("facing", Vector2.RIGHT))
	if face.length_squared() < 0.05:
		face = Vector2.RIGHT
	face = face.normalized()
	var back := -face
	var origin: Vector2 = Vector2(h["pos"])
	var reach := 400.0
	var half := 1.15
	w.horse_kicks.append({"pos": origin, "dir": back, "age": 0.0, "life": 0.42, "reach": reach})
	for t in range(w.heroes.size()):
		if t == slot:
			continue
		var vic: Dictionary = w.heroes[t]
		if not bool(vic.get("alive", false)) or bool(vic.get("eliminated", false)):
			continue
		if bool(vic.get("downed", false)) or bool(vic.get("burrowed", false)):
			continue
		var delta: Vector2 = Vector2(vic["pos"]) - origin
		var dist := delta.length()
		if dist > reach or dist < 1.0:
			continue
		if absf(back.angle_to(delta.normalized())) > half:
			continue
		var push := back * 380.0
		vic["launch_vel"] = push
		vic["launch_time"] = maxf(float(vic.get("launch_time", 0.0)), 0.26)
		vic["stun_time"] = maxf(float(vic.get("stun_time", 0.0)), 1.15)
		vic["vel"] = push
		vic["pos"] = w._resolve_cover_motion(Vector2(vic["pos"]), back * 72.0)
		w.heroes[t] = vic
	set_ultimate_focus(slot, 0.22)
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "horse_kick"})

func tick_horse_kicks(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for kick0 in w.horse_kicks:
		var kick: Dictionary = kick0
		kick["age"] = float(kick.get("age", 0.0)) + dt
		if float(kick["age"]) < float(kick.get("life", 0.42)):
			kept.append(kick)
	w.horse_kicks = kept

func begin_rabbit_burrow(slot: int, aim_pos: Vector2) -> void:
	var h: Dictionary = w.heroes[slot]
	if bool(h.get("burrowed", false)) or bool(h.get("downed", false)):
		h["ultimate_charge"] = w.ULTIMATE_MAX
		w.heroes[slot] = h
		return
	var enter: Vector2 = Vector2(h["pos"])
	var exit_pos: Vector2 = w._clamp_arena_point(aim_pos, w.HERO_RADIUS)
	exit_pos = w._nudge_out_of_cover(exit_pos, w.HERO_RADIUS)
	w.rabbit_holes.append({"pos": enter, "ttl": 4.5, "kind": "in"})
	h["burrowed"] = true
	h["burrow_left"] = 2.0
	h["burrow_exit"] = exit_pos
	h["vel"] = Vector2.ZERO
	w.heroes[slot] = h
	set_ultimate_focus(slot, 0.20)
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "rabbit_burrow"})

func tick_rabbit_burrows(dt: float) -> void:
	for slot in range(w.heroes.size()):
		var h: Dictionary = w.heroes[slot]
		if not bool(h.get("burrowed", false)):
			continue
		h["burrow_left"] = float(h.get("burrow_left", 0.0)) - dt
		h["vel"] = Vector2.ZERO
		if float(h["burrow_left"]) <= 0.0:
			var exit_pos: Vector2 = w._clamp_arena_point(Vector2(h.get("burrow_exit", h["pos"])), w.HERO_RADIUS)
			exit_pos = w._nudge_out_of_cover(exit_pos, w.HERO_RADIUS)
			w.rabbit_holes.append({"pos": exit_pos, "ttl": 3.5, "kind": "out"})
			h["pos"] = exit_pos
			h["burrowed"] = false
			h["burrow_left"] = 0.0
			h["spawn_protect_time"] = maxf(float(h.get("spawn_protect_time", 0.0)), 0.25)
		w.heroes[slot] = h
	var kept: Array[Dictionary] = []
	for hole0 in w.rabbit_holes:
		var hole: Dictionary = hole0
		hole["ttl"] = float(hole.get("ttl", 0.0)) - dt
		if float(hole["ttl"]) > 0.0:
			kept.append(hole)
	w.rabbit_holes = kept

func begin_tiger_roar(slot: int) -> void:
	var origin: Vector2 = w.heroes[slot]["pos"]
	w.tiger_roars.append({"pos": origin, "age": 0.0, "life": 1.15, "radius": 300.0, "owner": slot})
	for t in range(w.heroes.size()):
		if t == slot:
			continue
		var vic: Dictionary = w.heroes[t]
		if not bool(vic.get("alive", false)) or bool(vic.get("eliminated", false)):
			continue
		if bool(vic.get("downed", false)):
			continue
		if Vector2(vic["pos"]).distance_to(origin) > 300.0:
			continue
		vic["flee_time"] = 1.5
		vic["flee_from"] = origin
		w.heroes[t] = vic
	set_ultimate_focus(slot, 0.24)
	w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "tiger_roar"})

func tick_tiger_roars(dt: float) -> void:
	var kept: Array[Dictionary] = []
	for roar0 in w.tiger_roars:
		var roar: Dictionary = roar0
		roar["age"] = float(roar.get("age", 0.0)) + dt
		if float(roar["age"]) < float(roar.get("life", 1.15)):
			kept.append(roar)
	w.tiger_roars = kept

func apply_flee_vel(slot: int) -> void:
	var h: Dictionary = w.heroes[slot]
	if float(h.get("flee_time", 0.0)) <= 0.0:
		return
	if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
		return
	if float(h.get("launch_time", 0.0)) > 0.0 or float(h.get("stun_time", 0.0)) > 0.0:
		return
	var away: Vector2 = Vector2(h["pos"]) - Vector2(h.get("flee_from", Vector2.ZERO))
	if away.length_squared() < 0.01:
		away = Vector2(h.get("facing", Vector2.RIGHT))
	h["vel"] = away.normalized() * w._hero_move_speed(slot) * 1.12
	w.heroes[slot] = h
