extends Node2D

const WS_PORT := 9101
const WORLD_R := 1600.0
const FOOD_COUNT := 260
const TICK := 0.05
const START_MASS := 20.0

var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()

# server state
var players := {}      # id -> {pos:Vector2, mass:float, hue:float}
var inputs := {}       # id -> Vector2 dir
var foods: Array[Vector2] = []
var accum := 0.0

# client state
var snap_players := {} # id -> [x, y, mass, hue]
var snap_foods := PackedVector2Array()
var hud: Label

func _ready() -> void:
	rng.randomize()
	is_server = DisplayServer.get_name() == "headless"
	if is_server:
		peer.create_server(WS_PORT)
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_on_join)
		multiplayer.peer_disconnected.connect(_on_leave)
		for i in FOOD_COUNT:
			foods.append(_rand_point())
		print("agar server on ws://localhost:%d" % WS_PORT)
	else:
		hud = Label.new()
		hud.position = Vector2(16, 10)
		hud.add_theme_font_size_override("font_size", 22)
		add_child(hud)
		hud.text = "connecting..."
		peer.create_client("ws://localhost:%d" % WS_PORT)
		multiplayer.multiplayer_peer = peer

func _rand_point() -> Vector2:
	return Vector2.from_angle(rng.randf_range(-PI, PI)) * sqrt(rng.randf()) * (WORLD_R - 60.0)

func _on_join(id: int) -> void:
	players[id] = {"pos": _rand_point() * 0.5, "mass": START_MASS, "hue": rng.randf()}
	inputs[id] = Vector2.ZERO

func _on_leave(id: int) -> void:
	players.erase(id)
	inputs.erase(id)

func _radius(mass: float) -> float:
	return 4.0 * sqrt(mass)

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	for id in players:
		var p: Dictionary = players[id]
		var dir: Vector2 = inputs.get(id, Vector2.ZERO)
		var speed := 320.0 / (1.0 + pow(p.mass / 60.0, 0.5))
		p.pos = (p.pos + dir * speed * delta).limit_length(WORLD_R - _radius(p.mass))
	# eat food
	for id in players:
		var p: Dictionary = players[id]
		var r := _radius(p.mass) + 5.0
		var i := 0
		while i < foods.size():
			if p.pos.distance_to(foods[i]) < r:
				foods[i] = _rand_point()
				p.mass += 1.5
			else:
				i += 1
	# eat players
	var ids := players.keys()
	for a in ids:
		for b in ids:
			if a == b or not players.has(a) or not players.has(b):
				continue
			var pa: Dictionary = players[a]
			var pb: Dictionary = players[b]
			if pa.mass > pb.mass * 1.25 \
					and pa.pos.distance_to(pb.pos) < _radius(pa.mass) * 0.8:
				pa.mass += pb.mass * 0.8
				pb.mass = START_MASS
				pb.pos = _rand_point() * 0.5
	accum += delta
	if accum >= TICK:
		accum = 0.0
		var snap := {}
		for id in players:
			var p: Dictionary = players[id]
			snap[id] = [p.pos.x, p.pos.y, p.mass, p.hue]
		var fp := PackedVector2Array(foods)
		cl_state.rpc(snap, fp)

func _process(_delta: float) -> void:
	if is_server:
		return
	if multiplayer.multiplayer_peer and multiplayer.get_unique_id() != 1 \
			and snap_players.size() > 0:
		var center := get_viewport_rect().size / 2.0
		var dir := (get_viewport().get_mouse_position() - center)
		if dir.length() > 10.0:
			srv_input.rpc_id(1, dir.normalized())
		else:
			srv_input.rpc_id(1, Vector2.ZERO)
		var me: Array = snap_players.get(multiplayer.get_unique_id(), [0, 0, START_MASS, 0.0])
		hud.text = "MASS %d   PLAYERS %d" % [int(me[2]), snap_players.size()]
	queue_redraw()

@rpc("any_peer", "call_remote", "unreliable")
func srv_input(dir: Vector2) -> void:
	if not is_server:
		return
	inputs[multiplayer.get_remote_sender_id()] = dir.limit_length(1.0)

@rpc("authority", "call_remote", "unreliable")
func cl_state(p: Dictionary, f: PackedVector2Array) -> void:
	snap_players = p
	snap_foods = f

func _draw() -> void:
	if is_server:
		return
	var vp := get_viewport_rect().size
	var my_id := multiplayer.get_unique_id()
	var me: Array = snap_players.get(my_id, [0.0, 0.0, START_MASS, 0.3])
	var cam := Vector2(me[0], me[1])
	var off := vp / 2.0 - cam
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.08, 0.09, 0.11))
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
	for f in snap_foods:
		var p := f + off
		if p.x > -10 and p.x < vp.x + 10 and p.y > -10 and p.y < vp.y + 10:
			draw_circle(p, 4.0, Color.from_hsv(fmod(f.x * 0.01 + f.y * 0.013, 1.0), 0.8, 1.0))
	var order := snap_players.keys()
	order.sort_custom(func(a, b): return snap_players[a][2] < snap_players[b][2])
	for id in order:
		var s: Array = snap_players[id]
		var pos := Vector2(s[0], s[1]) + off
		var r := _radius(s[2])
		var col := Color.from_hsv(s[3], 0.7, 0.95)
		draw_circle(pos, r, col)
		draw_arc(pos, r, 0.0, TAU, 48, col.darkened(0.35), maxf(2.0, r * 0.08))
		if id == my_id:
			draw_arc(pos, r + 4.0, 0.0, TAU, 48, Color.WHITE, 2.0)
