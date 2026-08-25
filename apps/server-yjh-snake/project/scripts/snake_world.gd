class_name SnakeWorld
extends RefCounted

const MAP_SIZE := 4000.0
const FOOD_COUNT := 300
const SEGMENT_GAP := 14.0
const BASE_SPEED := 160.0
const BOOST_SPEED := 280.0
const HEAD_RADIUS := 12.0
const FOOD_RADIUS := 8.0
const FOOD_VALUE := 1
const BOOST_COST_PER_SEC := 2.0
const INITIAL_LENGTH := 8
const AI_COUNT := 20
const FIXED_DT := 1.0 / 60.0
const TURN_SPEED := 4.2

var snakes: Array[Dictionary] = []
var foods: Array[Dictionary] = []
var tick: int = 0
var next_id: int = 1
var _rng_seed: int
var _rng_state: int

func _init(seed_val: int = 1234) -> void:
	_rng_seed = seed_val
	_rng_state = seed_val
	reset()

func _rand() -> float:
	_rng_state = (_rng_state * 1103515245 + 12345) & 0x7FFFFFFF
	return float(_rng_state) / float(0x7FFFFFFF)

func _rand_range(lo: float, hi: float) -> float:
	return lo + _rand() * (hi - lo)

func reset() -> void:
	snakes.clear()
	foods.clear()
	tick = 0
	_rng_state = _rng_seed
	next_id = 1
	_spawn_player(Vector2(_rand_range(400, MAP_SIZE - 400), _rand_range(400, MAP_SIZE - 400)), "Player")
	for i in AI_COUNT:
		var pos := Vector2(_rand_range(200, MAP_SIZE - 200), _rand_range(200, MAP_SIZE - 200))
		_spawn_ai(pos, "AI-%02d" % (i + 1))
	for i in FOOD_COUNT:
		_spawn_food()

func _spawn_player(pos: Vector2, sname: String) -> int:
	return _spawn_snake(pos, sname, false)

func _spawn_ai(pos: Vector2, sname: String) -> int:
	return _spawn_snake(pos, sname, true)

func _spawn_snake(pos: Vector2, sname: String, is_ai: bool) -> int:
	var id := next_id
	next_id += 1
	var angle := _rand() * TAU
	var segments: Array[Dictionary] = []
	for i in INITIAL_LENGTH:
		var offset := Vector2(-cos(angle), -sin(angle)) * SEGMENT_GAP * float(i)
		segments.append({"x": pos.x + offset.x, "y": pos.y + offset.y})
	var snake := {
		"id": id,
		"name": sname,
		"segments": segments,
		"angle": angle,
		"speed": BASE_SPEED,
		"score": 0,
		"alive": true,
		"boost": false,
		"is_ai": is_ai,
		"color_index": (id - 1) % 12,
		"respawn_timer": 0.0,
		"ai_target": Vector2.ZERO,
		"ai_timer": 0.0,
	}
	snakes.append(snake)
	return id

func _spawn_food() -> void:
	foods.append({
		"x": _rand_range(50, MAP_SIZE - 50),
		"y": _rand_range(50, MAP_SIZE - 50),
		"value": FOOD_VALUE,
		"hue": _rand(),
	})

func _spawn_food_at(pos: Vector2, count: int) -> void:
	for i in count:
		var offset := Vector2(_rand_range(-40, 40), _rand_range(-40, 40))
		var p := pos + offset
		p.x = clampf(p.x, 50, MAP_SIZE - 50)
		p.y = clampf(p.y, 50, MAP_SIZE - 50)
		foods.append({"x": p.x, "y": p.y, "value": FOOD_VALUE, "hue": _rand()})

func step_tick(player_input: Dictionary, dt: float = FIXED_DT) -> void:
	tick += 1
	_apply_player_input(player_input)
	_update_ai()
	_move_snakes(dt)
	_check_food_collision()
	_check_snake_collision()
	_respawn_dead(dt)
	_refill_food()

func _apply_player_input(input: Dictionary) -> void:
	if snakes.is_empty():
		return
	var s: Dictionary = snakes[0]
	if not bool(s["alive"]):
		if bool(input.get("restart", false)):
			_respawn_snake(0)
		return
	var target_angle: float = s["angle"]
	if input.has("aim_x") and input.has("aim_y"):
		var aim := Vector2(float(input["aim_x"]), float(input["aim_y"]))
		var head := Vector2(s["segments"][0]["x"], s["segments"][0]["y"])
		var diff := aim - head
		if diff.length_squared() > 4.0:
			target_angle = diff.angle()
	elif input.has("mx") or input.has("my"):
		var mx := float(input.get("mx", 0))
		var my := float(input.get("my", 0))
		if mx * mx + my * my > 0.01:
			target_angle = Vector2(mx, my).angle()
	s["angle"] = _lerp_angle(float(s["angle"]), target_angle, TURN_SPEED * FIXED_DT)
	s["boost"] = bool(input.get("boost", false))

func _update_ai() -> void:
	for i in snakes.size():
		var s: Dictionary = snakes[i]
		if not bool(s["is_ai"]) or not bool(s["alive"]):
			continue
		s["ai_timer"] = float(s["ai_timer"]) - FIXED_DT
		if float(s["ai_timer"]) <= 0:
			s["ai_timer"] = _rand_range(0.5, 2.0)
			var head := Vector2(s["segments"][0]["x"], s["segments"][0]["y"])
			var best_dist := 999999.0
			var best_pos := head + Vector2(cos(float(s["angle"])), sin(float(s["angle"]))) * 200.0
			for food in foods:
				var fp := Vector2(food["x"], food["y"])
				var d := head.distance_squared_to(fp)
				if d < best_dist:
					best_dist = d
					best_pos = fp
			s["ai_target"] = best_pos
		var head := Vector2(s["segments"][0]["x"], s["segments"][0]["y"])
		var target: Vector2 = s["ai_target"]
		var desired := (target - head).angle()
		s["angle"] = _lerp_angle(float(s["angle"]), desired, TURN_SPEED * FIXED_DT * 0.7)
		s["boost"] = head.distance_to(target) > 300.0 and s["segments"].size() > 12 and _rand() < 0.02

func _move_snakes(dt: float) -> void:
	for s in snakes:
		if not bool(s["alive"]):
			continue
		var speed := BOOST_SPEED if bool(s["boost"]) else BASE_SPEED
		if bool(s["boost"]):
			var segs: Array = s["segments"]
			if segs.size() <= 4:
				s["boost"] = false
				speed = BASE_SPEED
			else:
				if tick % 6 == 0:
					segs.pop_back()
		var angle := float(s["angle"])
		var vel := Vector2(cos(angle), sin(angle)) * speed * dt
		var head: Dictionary = s["segments"][0]
		var new_x := clampf(float(head["x"]) + vel.x, HEAD_RADIUS, MAP_SIZE - HEAD_RADIUS)
		var new_y := clampf(float(head["y"]) + vel.y, HEAD_RADIUS, MAP_SIZE - HEAD_RADIUS)
		var segs: Array = s["segments"]
		var i := segs.size() - 1
		while i > 0:
			segs[i]["x"] = segs[i - 1]["x"]
			segs[i]["y"] = segs[i - 1]["y"]
			i -= 1
		segs[0]["x"] = new_x
		segs[0]["y"] = new_y

func _check_food_collision() -> void:
	for s in snakes:
		if not bool(s["alive"]):
			continue
		var head := Vector2(s["segments"][0]["x"], s["segments"][0]["y"])
		var eat_radius := HEAD_RADIUS + FOOD_RADIUS
		var eaten := []
		for fi in foods.size():
			var f: Dictionary = foods[fi]
			if head.distance_to(Vector2(f["x"], f["y"])) < eat_radius:
				eaten.append(fi)
				s["score"] = int(s["score"]) + int(f["value"])
				var tail: Dictionary = s["segments"].back()
				s["segments"].append({"x": tail["x"], "y": tail["y"]})
		eaten.reverse()
		for fi in eaten:
			foods.remove_at(fi)

func _check_snake_collision() -> void:
	for i in snakes.size():
		var s: Dictionary = snakes[i]
		if not bool(s["alive"]):
			continue
		var head := Vector2(s["segments"][0]["x"], s["segments"][0]["y"])
		for j in snakes.size():
			if i == j:
				continue
			var other: Dictionary = snakes[j]
			if not bool(other["alive"]):
				continue
			var other_segs: Array = other["segments"]
			for k in range(2, other_segs.size()):
				var seg := Vector2(other_segs[k]["x"], other_segs[k]["y"])
				if head.distance_to(seg) < HEAD_RADIUS * 2.0:
					_kill_snake(i)
					other["score"] = int(other["score"]) + int(s["score"]) / 2
					break
			if not bool(s["alive"]):
				break
		if bool(s["alive"]):
			if head.x <= HEAD_RADIUS or head.x >= MAP_SIZE - HEAD_RADIUS or head.y <= HEAD_RADIUS or head.y >= MAP_SIZE - HEAD_RADIUS:
				_kill_snake(i)

func _kill_snake(index: int) -> void:
	var s: Dictionary = snakes[index]
	s["alive"] = false
	s["respawn_timer"] = 3.0
	var segs: Array = s["segments"]
	_spawn_food_at(Vector2(segs[0]["x"], segs[0]["y"]), mini(segs.size() / 2, 30))

func _respawn_dead(dt: float) -> void:
	for i in snakes.size():
		var s: Dictionary = snakes[i]
		if bool(s["alive"]):
			continue
		s["respawn_timer"] = float(s["respawn_timer"]) - dt
		if float(s["respawn_timer"]) <= 0 and bool(s["is_ai"]):
			_respawn_snake(i)

func _respawn_snake(index: int) -> void:
	var s: Dictionary = snakes[index]
	var pos := Vector2(_rand_range(200, MAP_SIZE - 200), _rand_range(200, MAP_SIZE - 200))
	var angle := _rand() * TAU
	var segs: Array[Dictionary] = []
	for i in INITIAL_LENGTH:
		var offset := Vector2(-cos(angle), -sin(angle)) * SEGMENT_GAP * float(i)
		segs.append({"x": pos.x + offset.x, "y": pos.y + offset.y})
	s["segments"] = segs
	s["angle"] = angle
	s["score"] = 0
	s["alive"] = true
	s["boost"] = false
	s["respawn_timer"] = 0.0

func _refill_food() -> void:
	while foods.size() < FOOD_COUNT:
		_spawn_food()

func _lerp_angle(from: float, to: float, weight: float) -> float:
	var diff := fmod(to - from + PI, TAU) - PI
	return from + diff * minf(weight, 1.0)

func player_snake() -> Dictionary:
	if snakes.is_empty():
		return {}
	return snakes[0]

func leaderboard(count: int = 5) -> Array[Dictionary]:
	var sorted: Array[Dictionary] = []
	for s in snakes:
		if bool(s["alive"]):
			sorted.append({"name": s["name"], "score": s["score"], "length": s["segments"].size()})
	sorted.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	return sorted.slice(0, count)
