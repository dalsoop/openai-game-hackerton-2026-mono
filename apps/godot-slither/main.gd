extends Node2D

const WORLD_R := 2200.0
const SEG_SPACING := 7.0
const START_LEN := 14
const FOOD_COUNT := 320
const AI_COUNT := 9
const BASE_SPEED := 170.0
const BOOST_SPEED := 300.0
const TURN_RATE := 4.0

var rng := RandomNumberGenerator.new()

class Snake:
	var trail: Array[Vector2] = []
	var segs: Array[Vector2] = []
	var dir := 0.0
	var lenf := float(START_LEN)
	var color := Color.WHITE
	var alive := true
	var boost := false
	var is_ai := true
	var think := 0.0
	var target_dir := 0.0

	func head() -> Vector2:
		return trail[0]

	func radius() -> float:
		return 5.0 + sqrt(lenf) * 0.6

var player: Snake
var ais: Array[Snake] = []
var foods: Array[Vector2] = []
var food_colors: Array[Color] = []
var score_label: Label
var over_label: Label
var game_over := false

func _ready() -> void:
	rng.randomize()
	score_label = Label.new()
	score_label.position = Vector2(16, 10)
	score_label.add_theme_font_size_override("font_size", 22)
	add_child(score_label)
	over_label = Label.new()
	over_label.add_theme_font_size_override("font_size", 30)
	over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_label.visible = false
	add_child(over_label)
	_start()

func _start() -> void:
	game_over = false
	over_label.visible = false
	player = _make_snake(Vector2.ZERO, Color(0.35, 0.9, 0.5))
	player.is_ai = false
	ais.clear()
	for i in AI_COUNT:
		ais.append(_spawn_ai())
	foods.clear()
	food_colors.clear()
	for i in FOOD_COUNT:
		_add_food(_rand_point(WORLD_R - 100.0))

func _make_snake(pos: Vector2, col: Color) -> Snake:
	var s := Snake.new()
	s.color = col
	s.dir = rng.randf_range(-PI, PI)
	s.target_dir = s.dir
	for i in START_LEN * 4:
		s.trail.append(pos - Vector2.from_angle(s.dir) * SEG_SPACING * 0.5 * i)
	return s

func _spawn_ai() -> Snake:
	var col := Color.from_hsv(rng.randf(), 0.7, 0.95)
	var s := _make_snake(_rand_point(WORLD_R - 400.0), col)
	s.lenf = rng.randf_range(10.0, 40.0)
	return s

func _rand_point(r: float) -> Vector2:
	return Vector2.from_angle(rng.randf_range(-PI, PI)) * sqrt(rng.randf()) * r

func _add_food(pos: Vector2) -> void:
	foods.append(pos)
	food_colors.append(Color.from_hsv(rng.randf(), 0.8, 1.0))

func _process(delta: float) -> void:
	if game_over:
		if Input.is_key_pressed(KEY_ENTER):
			_start()
		queue_redraw()
		return

	# player steering: toward mouse
	var center := get_viewport_rect().size / 2.0
	var mouse := get_viewport().get_mouse_position() - center
	if mouse.length() > 8.0:
		player.target_dir = mouse.angle()
	player.boost = (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
		or Input.is_key_pressed(KEY_SPACE)) and player.lenf > START_LEN + 2.0

	for s in _all_snakes():
		if s.is_ai:
			_ai_think(s, delta)
		_move(s, delta)
		_eat(s)

	_collide()
	_respawn_dead()

	score_label.text = "LENGTH %d" % int(player.lenf)
	queue_redraw()

func _all_snakes() -> Array[Snake]:
	var arr: Array[Snake] = [player]
	arr.append_array(ais)
	return arr

func _ai_think(s: Snake, delta: float) -> void:
	s.think -= delta
	if s.head().length() > WORLD_R - 320.0:
		s.target_dir = (-s.head()).angle() + rng.randf_range(-0.4, 0.4)
		s.think = 0.6
		return
	# avoid player body ahead
	var probe := s.head() + Vector2.from_angle(s.dir) * 120.0
	for seg in player.segs:
		if probe.distance_to(seg) < 60.0:
			s.target_dir = s.dir + PI * 0.5
			s.think = 0.4
			return
	if s.think <= 0.0:
		s.think = rng.randf_range(0.4, 1.2)
		var best := -1
		var best_d := 400.0
		for i in foods.size():
			var d := s.head().distance_to(foods[i])
			if d < best_d:
				best_d = d
				best = i
		if best >= 0:
			s.target_dir = (foods[best] - s.head()).angle()
		else:
			s.target_dir = s.dir + rng.randf_range(-1.2, 1.2)
		s.boost = rng.randf() < 0.06 and s.lenf > START_LEN + 4.0

func _move(s: Snake, delta: float) -> void:
	var diff := wrapf(s.target_dir - s.dir, -PI, PI)
	s.dir += clampf(diff, -TURN_RATE * delta, TURN_RATE * delta)
	var speed := BOOST_SPEED if s.boost else BASE_SPEED
	if s.boost:
		s.lenf = maxf(float(START_LEN), s.lenf - 5.0 * delta)
		if rng.randf() < 8.0 * delta:
			_add_food(s.trail[s.trail.size() - 1])
	var new_head := s.head() + Vector2.from_angle(s.dir) * speed * delta
	if new_head.length() > WORLD_R:
		if s.is_ai:
			new_head = new_head.limit_length(WORLD_R)
			s.target_dir = (-new_head).angle()
		else:
			s.alive = false
			return
	s.trail.push_front(new_head)
	# trim trail to needed path length
	var need := s.lenf * SEG_SPACING + 60.0
	var acc := 0.0
	for i in range(1, s.trail.size()):
		acc += s.trail[i - 1].distance_to(s.trail[i])
		if acc > need:
			s.trail.resize(i + 1)
			break
	# compute segment positions along trail
	s.segs.clear()
	var want := int(s.lenf)
	var dist := 0.0
	var next_at := 0.0
	s.segs.append(s.head())
	var i := 1
	while i < s.trail.size() and s.segs.size() < want:
		var step := s.trail[i - 1].distance_to(s.trail[i])
		dist += step
		next_at = s.segs.size() * SEG_SPACING
		if dist >= next_at:
			s.segs.append(s.trail[i])
		else:
			i += 1

func _eat(s: Snake) -> void:
	var r := s.radius() + 9.0
	var i := 0
	while i < foods.size():
		if s.head().distance_to(foods[i]) < r:
			foods.remove_at(i)
			food_colors.remove_at(i)
			s.lenf += 1.2
		else:
			i += 1
	while foods.size() < FOOD_COUNT:
		_add_food(_rand_point(WORLD_R - 100.0))

func _collide() -> void:
	var all := _all_snakes()
	for s in all:
		if not s.alive:
			continue
		for o in all:
			if o == s or not o.alive:
				continue
			var rr := s.radius() + o.radius() * 0.8
			for seg in o.segs:
				if s.head().distance_to(seg) < rr:
					s.alive = false
					break
			if not s.alive:
				break

func _respawn_dead() -> void:
	for s in _all_snakes():
		if s.alive:
			continue
		for j in s.segs.size():
			if j % 2 == 0:
				_add_food(s.segs[j])
		if s.is_ai:
			ais.erase(s)
			ais.append(_spawn_ai())
	if not player.alive:
		game_over = true
		var center := get_viewport_rect().size / 2.0
		over_label.text = "죽었다! LENGTH %d\nEnter 로 재시작" % int(player.lenf)
		over_label.position = center - Vector2(140, 40)
		over_label.visible = true

func _draw() -> void:
	var vp := get_viewport_rect().size
	var cam := player.head()
	var off := vp / 2.0 - cam

	# background
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.07, 0.08, 0.1))
	# grid
	var grid := 120.0
	var x0 := floorf((cam.x - vp.x / 2.0) / grid) * grid
	var y0 := floorf((cam.y - vp.y / 2.0) / grid) * grid
	var gc := Color(1, 1, 1, 0.05)
	var x := x0
	while x < cam.x + vp.x / 2.0 + grid:
		draw_line(Vector2(x + off.x, 0), Vector2(x + off.x, vp.y), gc)
		x += grid
	var y := y0
	while y < cam.y + vp.y / 2.0 + grid:
		draw_line(Vector2(0, y + off.y), Vector2(vp.x, y + off.y), gc)
		y += grid
	# world boundary
	draw_arc(off, WORLD_R, 0.0, TAU, 128, Color(0.9, 0.3, 0.3, 0.9), 6.0)

	# food
	for i in foods.size():
		var p := foods[i] + off
		if p.x > -20 and p.x < vp.x + 20 and p.y > -20 and p.y < vp.y + 20:
			draw_circle(p, 4.5, food_colors[i])

	# snakes (body back→front, then head with eyes)
	for s in _all_snakes():
		var r := s.radius()
		for j in range(s.segs.size() - 1, -1, -1):
			var c := s.color.darkened(0.25) if j % 2 == 0 else s.color
			if s.boost:
				c = c.lightened(0.3)
			draw_circle(s.segs[j] + off, r, c)
		var hp := s.head() + off
		var fwd := Vector2.from_angle(s.dir)
		var side := fwd.orthogonal()
		for k in [-1.0, 1.0]:
			var ep: Vector2 = hp + fwd * r * 0.45 + side * r * 0.5 * k
			draw_circle(ep, r * 0.34, Color.WHITE)
			draw_circle(ep + fwd * r * 0.12, r * 0.17, Color.BLACK)
