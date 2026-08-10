extends Node2D

const WS_PORT := 9103
const WORLD_R := 2000.0
const SEG_SPACING := 7.0
const START_LEN := 14
const FOOD_COUNT := 280
const AI_COUNT := 5
const BASE_SPEED := 170.0
const BOOST_SPEED := 300.0
const TURN_RATE := 4.0
const TICK := 0.05
const MAX_SEND_SEGS := 80

var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()

class Snake:
	var trail: Array[Vector2] = []
	var segs: Array[Vector2] = []
	var dir := 0.0
	var target_dir := 0.0
	var lenf := float(START_LEN)
	var hue := 0.0
	var boost := false
	var is_ai := false
	var think := 0.0

	func head() -> Vector2:
		return trail[0]

	func radius() -> float:
		return 5.0 + sqrt(lenf) * 0.6

# server state
var snakes := {}  # id -> Snake (negative ids = AI)
var foods: Array[Vector2] = []
var accum := 0.0
var next_ai_id := -1

# client state
var snap := {}  # id -> [PackedVector2Array segs, r, hue, boost]
var hud: Label

func _ready() -> void:
	rng.randomize()
	is_server = DisplayServer.get_name() == "headless"
	if is_server:
		peer.create_server(WS_PORT)
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_on_join)
		multiplayer.peer_disconnected.connect(func(id): snakes.erase(id))
		for i in FOOD_COUNT:
			foods.append(_rand_point())
		for i in AI_COUNT:
			_spawn_ai()
		print("slither server on ws://localhost:%d" % WS_PORT)
	else:
		hud = Label.new()
		hud.position = Vector2(16, 10)
		hud.add_theme_font_size_override("font_size", 22)
		add_child(hud)
		hud.text = "connecting..."
		peer.create_client("ws://localhost:%d" % WS_PORT)
		multiplayer.multiplayer_peer = peer

func _rand_point() -> Vector2:
	return Vector2.from_angle(rng.randf_range(-PI, PI)) * sqrt(rng.randf()) * (WORLD_R - 80.0)

func _make_snake(pos: Vector2) -> Snake:
	var s := Snake.new()
	s.hue = rng.randf()
	s.dir = rng.randf_range(-PI, PI)
	s.target_dir = s.dir
	for i in START_LEN * 4:
		s.trail.append(pos - Vector2.from_angle(s.dir) * SEG_SPACING * 0.5 * i)
	return s

func _on_join(id: int) -> void:
	snakes[id] = _make_snake(_rand_point() * 0.4)

func _spawn_ai() -> void:
	var s := _make_snake(_rand_point() * 0.8)
	s.is_ai = true
	s.lenf = rng.randf_range(10.0, 40.0)
	snakes[next_ai_id] = s
	next_ai_id -= 1

func _ai_think(s: Snake, delta: float) -> void:
	s.think -= delta
	if s.head().length() > WORLD_R - 300.0:
		s.target_dir = (-s.head()).angle() + rng.randf_range(-0.4, 0.4)
		s.think = 0.6
		return
	if s.think <= 0.0:
		s.think = rng.randf_range(0.4, 1.2)
		var best := Vector2.INF
		var best_d := 400.0
		for f in foods:
			var d := s.head().distance_to(f)
			if d < best_d:
				best_d = d
				best = f
		if best != Vector2.INF:
			s.target_dir = (best - s.head()).angle()
		else:
			s.target_dir = s.dir + rng.randf_range(-1.2, 1.2)
		s.boost = rng.randf() < 0.05 and s.lenf > START_LEN + 4.0

func _move(s: Snake, delta: float) -> bool:
	var diff := wrapf(s.target_dir - s.dir, -PI, PI)
	s.dir += clampf(diff, -TURN_RATE * delta, TURN_RATE * delta)
	var speed := BOOST_SPEED if s.boost else BASE_SPEED
	if s.boost:
		s.lenf = maxf(float(START_LEN), s.lenf - 5.0 * delta)
		if rng.randf() < 8.0 * delta:
			foods.append(s.trail[s.trail.size() - 1])
	var new_head := s.head() + Vector2.from_angle(s.dir) * speed * delta
	if new_head.length() > WORLD_R:
		if s.is_ai:
			new_head = new_head.limit_length(WORLD_R)
			s.target_dir = (-new_head).angle()
		else:
			return false
	s.trail.push_front(new_head)
	var need := s.lenf * SEG_SPACING + 60.0
	var acc := 0.0
	for i in range(1, s.trail.size()):
		acc += s.trail[i - 1].distance_to(s.trail[i])
		if acc > need:
			s.trail.resize(i + 1)
			break
	s.segs.clear()
	var want := int(s.lenf)
	var dist := 0.0
	s.segs.append(s.head())
	var i := 1
	while i < s.trail.size() and s.segs.size() < want:
		dist += s.trail[i - 1].distance_to(s.trail[i])
		if dist >= s.segs.size() * SEG_SPACING:
			s.segs.append(s.trail[i])
		else:
			i += 1
	return true

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	var dead: Array = []
	for id in snakes:
		var s: Snake = snakes[id]
		if s.is_ai:
			_ai_think(s, delta)
		if not _move(s, delta):
			dead.append(id)
			continue
		# eat
		var r := s.radius() + 9.0
		var i := 0
		while i < foods.size():
			if s.head().distance_to(foods[i]) < r:
				foods.remove_at(i)
				s.lenf += 1.2
			else:
				i += 1
	while foods.size() < FOOD_COUNT:
		foods.append(_rand_point())
	# collisions
	for a in snakes:
		if dead.has(a):
			continue
		var sa: Snake = snakes[a]
		for b in snakes:
			if a == b or dead.has(b):
				continue
			var sb: Snake = snakes[b]
			var rr := sa.radius() + sb.radius() * 0.8
			for seg in sb.segs:
				if sa.head().distance_to(seg) < rr:
					dead.append(a)
					break
			if dead.has(a):
				break
	for id in dead:
		var s: Snake = snakes[id]
		for j in s.segs.size():
			if j % 2 == 0:
				foods.append(s.segs[j])
		snakes.erase(id)
		if id < 0:
			_spawn_ai()
		else:
			_on_join(id)  # instant respawn for players
	accum += delta
	if accum >= TICK:
		accum = 0.0
		var out := {}
		for id in snakes:
			var s: Snake = snakes[id]
			var segs := PackedVector2Array()
			var step := maxi(1, int(ceil(float(s.segs.size()) / MAX_SEND_SEGS)))
			var j := 0
			while j < s.segs.size():
				segs.append(s.segs[j])
				j += step
			out[id] = [segs, s.radius(), s.hue, s.boost, int(s.lenf)]
		cl_state.rpc(out)
		cl_foods.rpc(PackedVector2Array(foods))

func _process(_delta: float) -> void:
	if is_server:
		return
	if multiplayer.multiplayer_peer and multiplayer.get_unique_id() != 1 \
			and snap.size() > 0:
		var center := get_viewport_rect().size / 2.0
		var mouse := get_viewport().get_mouse_position() - center
		var boost := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			or Input.is_key_pressed(KEY_SPACE)
		if mouse.length() > 8.0:
			srv_input.rpc_id(1, mouse.angle(), boost)
		var my_id := multiplayer.get_unique_id()
		if snap.has(my_id):
			hud.text = "LENGTH %d   SNAKES %d" % [snap[my_id][4], snap.size()]
	queue_redraw()

@rpc("any_peer", "call_remote", "unreliable")
func srv_input(angle: float, boost: bool) -> void:
	if not is_server:
		return
	var id := multiplayer.get_remote_sender_id()
	if snakes.has(id):
		var s: Snake = snakes[id]
		s.target_dir = angle
		s.boost = boost and s.lenf > START_LEN + 2.0

@rpc("authority", "call_remote", "unreliable")
func cl_state(p: Dictionary) -> void:
	snap = p

func _draw() -> void:
	if is_server:
		return
	var vp := get_viewport_rect().size
	var my_id := multiplayer.get_unique_id()
	var cam := Vector2.ZERO
	if snap.has(my_id) and snap[my_id][0].size() > 0:
		cam = snap[my_id][0][0]
	var off := vp / 2.0 - cam
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.07, 0.08, 0.1))
	var grid := 120.0
	var gc := Color(1, 1, 1, 0.05)
	var x := floorf((cam.x - vp.x / 2.0) / grid) * grid
	while x < cam.x + vp.x / 2.0 + grid:
		draw_line(Vector2(x + off.x, 0), Vector2(x + off.x, vp.y), gc)
		x += grid
	var y := floorf((cam.y - vp.y / 2.0) / grid) * grid
	while y < cam.y + vp.y / 2.0 + grid:
		draw_line(Vector2(0, y + off.y), Vector2(vp.x, y + off.y), gc)
		y += grid
	draw_arc(off, WORLD_R, 0.0, TAU, 128, Color(0.9, 0.3, 0.3, 0.9), 6.0)
	for f in foods_client():
		var p := f + off
		if p.x > -10 and p.x < vp.x + 10 and p.y > -10 and p.y < vp.y + 10:
			draw_circle(p, 4.0, Color.from_hsv(fmod(f.x * 0.011 + f.y * 0.017, 1.0), 0.8, 1.0))
	for id in snap:
		var s: Array = snap[id]
		var segs: PackedVector2Array = s[0]
		var r: float = s[1]
		var col := Color.from_hsv(s[2], 0.7, 0.95)
		if s[3]:
			col = col.lightened(0.3)
		for j in range(segs.size() - 1, -1, -1):
			var c := col.darkened(0.25) if j % 2 == 0 else col
			draw_circle(segs[j] + off, r, c)
		if segs.size() >= 2:
			var fwd := (segs[0] - segs[1]).normalized()
			var side := fwd.orthogonal()
			for k in [-1.0, 1.0]:
				var ep: Vector2 = segs[0] + off + fwd * r * 0.45 + side * r * 0.5 * k
				draw_circle(ep, r * 0.34, Color.WHITE)
				draw_circle(ep + fwd * r * 0.12, r * 0.17, Color.BLACK)

var _client_foods := PackedVector2Array()

func foods_client() -> PackedVector2Array:
	return _client_foods

@rpc("authority", "call_remote", "unreliable")
func cl_foods(f: PackedVector2Array) -> void:
	_client_foods = f
