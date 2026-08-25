extends Node2D
class_name KillFanfare

const TEST_EVERY_SEC := 3.0
const PAPER_PER_SIDE := 42
const STREAM_PER_SIDE := 7
const STREAM_LEN := 5
const STREAM_REST := 8.0
const PAPER_ALPHA := 0.96
const STREAM_ALPHA := 0.92
const STREAM_FALL_FADE := 0.35
const PAPER_FALL_FADE := 0.35

var _papers: Array = []
var _streams: Array = []
var _spawn_q: Array = []
var _burst_n := 0
var _test_on := false
var _rng := RandomNumberGenerator.new()
var _drew := 0
var _view := Vector2(1600, 900)

const PALETTE := [
	Color(1.00, 0.12, 0.18),
	Color(1.00, 0.84, 0.08),
	Color(0.12, 0.92, 0.38),
	Color(0.18, 0.55, 1.00),
	Color(0.92, 0.18, 1.00),
	Color(1.00, 0.48, 0.08),
	Color(1.00, 1.00, 1.00),
	Color(1.00, 0.28, 0.62),
]


func _blog(msg: String) -> void:
	print(msg)
	var path := "E:/OpenAIProj/openai-game-hackerton-2026-mono/apps/server-pjh-dev1/fanfare_runtime.log"
	var f: FileAccess
	if FileAccess.file_exists(path):
		f = FileAccess.open(path, FileAccess.READ_WRITE)
		if f:
			f.seek_end()
	else:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_line(msg)
		f.close()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 80
	_rng.randomize()
	set_process(true)
	_blog("[gangup] fanfare ready stream_short=1 rest=8 len=5")


func _process(dt: float) -> void:
	_flush_spawn(dt)
	_step_papers(dt)
	_step_streams(dt)
	queue_redraw()


func burst() -> void:
	_burst_n += 1
	_papers.clear()
	_streams.clear()
	_spawn_q.clear()
	_view = get_viewport().get_visible_rect().size
	var left := Vector2(28.0, _view.y - 22.0)
	var right := Vector2(_view.x - 28.0, _view.y - 22.0)
	_queue_side(left, Vector2(0.08, -1.0), 1.0)
	_queue_side(left, Vector2(0.32, -1.0), 1.0)
	_queue_side(left, Vector2(0.48, -0.98), 1.0)
	_queue_side(right, Vector2(-0.08, -1.0), -1.0)
	_queue_side(right, Vector2(-0.32, -1.0), -1.0)
	_queue_side(right, Vector2(-0.48, -0.98), -1.0)
	_flush_spawn(0.24)
	_blog("[gangup] fanfare burst n=" + str(_burst_n) + " q=" + str(_spawn_q.size()) + " paper=" + str(_papers.size()) + " stream=" + str(_streams.size()) + " size=" + str(_view) + " side_fill=1")


func _queue_side(origin: Vector2, dir: Vector2, face: float) -> void:
	var i := 0
	while i < STREAM_PER_SIDE:
		_spawn_q.append({"kind": "stream", "t": 0.004 * float(i), "origin": origin, "dir": dir, "face": face})
		i += 1
	i = 0
	while i < PAPER_PER_SIDE:
		_spawn_q.append({"kind": "paper", "t": 0.0012 * float(i), "origin": origin, "dir": dir, "face": face})
		i += 1


func _flush_spawn(dt: float) -> void:
	var keep: Array = []
	for item in _spawn_q:
		var left_t: float = float(item["t"]) - dt
		item["t"] = left_t
		if left_t > 0.0:
			keep.append(item)
			continue
		var kind := str(item["kind"])
		var origin: Vector2 = item["origin"]
		var dir: Vector2 = item["dir"]
		var face: float = float(item["face"])
		if kind == "paper":
			_spawn_paper(origin, dir, face)
		else:
			_spawn_stream(origin, dir, face)
	_spawn_q = keep


func _pick() -> Color:
	return PALETTE[_rng.randi_range(0, PALETTE.size() - 1)]


func _spawn_paper(origin: Vector2, dir: Vector2, face: float) -> void:
	var spread := _rng.randf_range(-0.22, 0.30)
	var aim := dir.rotated(spread * face).normalized()
	var spd := _rng.randf_range(1320.0, 2100.0)
	var shape := _rng.randi_range(0, 2)
	var w := 11.0
	var h := 8.0
	if shape == 1:
		w = _rng.randf_range(22.0, 34.0)
		h = _rng.randf_range(8.0, 12.0)
	elif shape == 2:
		w = _rng.randf_range(13.0, 18.0)
		h = w
	else:
		w = _rng.randf_range(16.0, 26.0)
		h = _rng.randf_range(11.0, 18.0)
	_papers.append({
		"p": origin + Vector2(face * _rng.randf_range(0.0, 8.0), _rng.randf_range(-6.0, 4.0)),
		"v": aim * spd,
		"a": _rng.randf_range(0.0, TAU),
		"av": _rng.randf_range(-14.0, 14.0),
		"spin": _rng.randf_range(0.0, TAU),
		"spinv": _rng.randf_range(7.0, 14.0) * (1.0 if _rng.randf() > 0.5 else -1.0),
		"w": w,
		"h": h,
		"col": _pick(),
		"age": 0.0,
		"life": _rng.randf_range(1.45, 2.05),
		"face": face,
		"fall_t": -1.0,
	})


func _spawn_stream(origin: Vector2, dir: Vector2, face: float) -> void:
	var spread := _rng.randf_range(-0.14, 0.20)
	var aim := dir.rotated(spread * face).normalized()
	var spd := _rng.randf_range(880.0, 1280.0)
	var pts := PackedVector2Array()
	var vel := PackedVector2Array()
	var seed_p := origin + Vector2(face * 4.0, _rng.randf_range(-4.0, 4.0))
	var i := 0
	while i < STREAM_LEN:
		var along := float(i) * STREAM_REST * 0.35
		pts.append(seed_p + aim * along)
		var falloff := 1.0 - float(i) / float(STREAM_LEN) * 0.62
		vel.append(aim * spd * falloff)
		i += 1
	_streams.append({
		"pts": pts,
		"vel": vel,
		"col": _pick(),
		"width": _rng.randf_range(9.0, 14.0),
		"age": 0.0,
		"life": _rng.randf_range(1.5, 2.1),
		"face": face,
		"fall_t": -1.0,
	})



func _center_cover(x: float) -> float:
	if _view.x <= 1.0:
		return 0.0
	var nx := x / _view.x
	if nx < 0.28 or nx > 0.72:
		return 0.0
	if nx > 0.5:
		nx = 1.0 - nx
	return clampf((0.40 - nx) / 0.12, 0.0, 1.0)


func _center_push(x: float, face: float) -> float:
	return face * 2200.0 * _center_cover(x)


func _step_papers(dt: float) -> void:
	var live: Array = []
	for p in _papers:
		var age: float = float(p["age"]) + dt
		p["age"] = age
		if age >= float(p["life"]):
			continue
		var vel: Vector2 = p["v"]
		var pos: Vector2 = p["p"]
		var face: float = float(p["face"])
		vel = vel + Vector2(_center_push(pos.x, face), 1680.0) * dt
		vel = vel * (1.0 - 1.05 * dt)
		p["v"] = vel
		p["p"] = pos + vel * dt
		p["a"] = float(p["a"]) + float(p["av"]) * dt
		p["spin"] = float(p["spin"]) + float(p["spinv"]) * dt
		var fall_t: float = float(p["fall_t"])
		if fall_t < 0.0:
			if vel.y > 10.0:
				fall_t = 0.0
		else:
			fall_t += dt
		p["fall_t"] = fall_t
		if fall_t >= PAPER_FALL_FADE:
			continue
		live.append(p)
	_papers = live


func _step_streams(dt: float) -> void:
	var live: Array = []
	for s in _streams:
		var age: float = float(s["age"]) + dt
		s["age"] = age
		if age >= float(s["life"]):
			continue
		var pts: PackedVector2Array = s["pts"]
		var vel: PackedVector2Array = s["vel"]
		var i := 0
		while i < pts.size():
			var drag := 0.55 + float(i) / float(pts.size()) * 1.35
			var v: Vector2 = vel[i] + Vector2(0.0, 1280.0) * dt
			v = v * (1.0 - drag * dt)
			vel[i] = v
			pts[i] = pts[i] + v * dt
			i += 1
		var pass_i := 0
		while pass_i < 5:
			i = 1
			while i < pts.size():
				var delta: Vector2 = pts[i] - pts[i - 1]
				var dist := delta.length()
				if dist >= 0.001:
					var extra := dist - STREAM_REST
					var corr: Vector2 = delta.normalized() * extra * 0.88
					pts[i] = pts[i] - corr
					vel[i] = vel[i] - corr * 8.0 * dt
					if i > 1:
						pts[i - 1] = pts[i - 1] + corr * 0.18
				i += 1
			pass_i += 1
		s["pts"] = pts
		s["vel"] = vel
		var fall_t: float = float(s["fall_t"])
		if fall_t < 0.0:
			if vel.size() > 0 and vel[0].y > 10.0:
				fall_t = 0.0
		else:
			fall_t += dt
		s["fall_t"] = fall_t
		if fall_t >= STREAM_FALL_FADE:
			continue
		live.append(s)
	_streams = live


func _life_fade(age: float, life: float, tail: float) -> float:
	if life - age < tail:
		return maxf(0.0, (life - age) / tail)
	if age < 0.06:
		return age / 0.06
	return 1.0


func _fall_fade(item: Dictionary, dur: float) -> float:
	var fall_t := float(item["fall_t"])
	if fall_t < 0.0:
		return 1.0
	return maxf(0.0, 1.0 - fall_t / dur)


func _draw() -> void:
	_drew += 1
	if _drew <= 3 or _drew % 60 == 0:
		_blog("[gangup] fanfare draw n=" + str(_drew) + " paper=" + str(_papers.size()) + " stream=" + str(_streams.size()))
	for s in _streams:
		_draw_ribbon(s)
	for p in _papers:
		_draw_paper(p)



func _draw_paper(p: Dictionary) -> void:
	var age := float(p["age"])
	var life := float(p["life"])
	var pos: Vector2 = p["p"]
	var fade := _life_fade(age, life, 0.22) * _fall_fade(p, PAPER_FALL_FADE) * (1.0 - _center_cover(pos.x) * 0.92)
	if fade <= 0.02:
		return
	var squash := maxf(0.16, abs(cos(float(p["spin"]))))
	var col: Color = p["col"]
	col.a = fade * PAPER_ALPHA
	var xf := Transform2D(float(p["a"]), Vector2(squash, 1.0), 0.0, pos)
	draw_set_transform_matrix(xf)
	var w := float(p["w"])
	var h := float(p["h"])
	if cos(float(p["spin"])) < 0.0:
		var back := col.darkened(0.28)
		back.a = col.a
		draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), back, true)
	else:
		draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), col, true)
		draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h * 0.28), Color(1, 1, 1, 0.16 * col.a), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ribbon(s: Dictionary) -> void:
	var pts: PackedVector2Array = s["pts"]
	if pts.size() < 2:
		return
	var fade := _life_fade(float(s["age"]), float(s["life"]), 0.2) * _fall_fade(s, STREAM_FALL_FADE)
	var width := float(s["width"])
	var col: Color = s["col"]
	var i := 0
	while i < pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		if a.distance_to(b) >= 0.8:
			var mid_x := (a.x + b.x) * 0.5
			var local_a := fade * STREAM_ALPHA * (1.0 - _center_cover(mid_x) * 0.92)
			if local_a > 0.03:
				col.a = local_a
				var w := width * (1.0 - float(i) / float(pts.size() - 1) * 0.72)
				draw_line(a, b, col, maxf(1.8, w), true)
		i += 1


func _on_test_tick() -> void:
	if not _test_on:
		_blog("[gangup] fanfare tick skip test_off")
		return
	_blog("[gangup] fanfare tick fire edge_up=1")
	burst()
