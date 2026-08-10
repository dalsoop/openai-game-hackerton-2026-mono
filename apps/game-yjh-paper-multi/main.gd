extends Node2D

const WS_PORT := 9102
const GRID := 64
const CELL := 18.0
const TICK := 0.05
const SPEED := 7.0  # cells per second

var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()

# server state
var owner_grid := PackedInt32Array()  # GRID*GRID, 0 = free, else player id
var players := {}  # id -> {pos:Vector2(cell float), dir:Vector2i, want:Vector2i, trail:Array[Vector2i], hue:float}
var accum := 0.0

# client state
var snap_grid := PackedInt32Array()
var snap_players := {}  # id -> [x, y, hue, trail:PackedVector2Array]
var hud: Label

func _ready() -> void:
	rng.randomize()
	is_server = DisplayServer.get_name() == "headless"
	if is_server:
		owner_grid.resize(GRID * GRID)
		peer.create_server(WS_PORT)
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_on_join)
		multiplayer.peer_disconnected.connect(_on_leave)
		print("paper server on ws://localhost:%d" % WS_PORT)
	else:
		hud = Label.new()
		hud.position = Vector2(16, 10)
		hud.add_theme_font_size_override("font_size", 22)
		add_child(hud)
		hud.text = "connecting... (방향키/WASD)"
		peer.create_client("ws://localhost:%d" % WS_PORT)
		multiplayer.multiplayer_peer = peer

func _idx(c: Vector2i) -> int:
	return c.y * GRID + c.x

func _in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < GRID and c.y < GRID

func _on_join(id: int) -> void:
	var c := Vector2i(rng.randi_range(6, GRID - 7), rng.randi_range(6, GRID - 7))
	players[id] = {"pos": Vector2(c), "dir": Vector2i.RIGHT, "want": Vector2i.RIGHT,
		"trail": [] as Array[Vector2i], "hue": rng.randf()}
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			owner_grid[_idx(c + Vector2i(dx, dy))] = id
	_send_grid()

func _on_leave(id: int) -> void:
	players.erase(id)
	for i in owner_grid.size():
		if owner_grid[i] == id:
			owner_grid[i] = 0
	_send_grid()

func _kill(id: int) -> void:
	if not players.has(id):
		return
	var hue: float = players[id].hue
	players.erase(id)
	for i in owner_grid.size():
		if owner_grid[i] == id:
			owner_grid[i] = 0
	# respawn immediately
	_on_join(id)
	players[id].hue = hue

func _capture(id: int) -> void:
	var p: Dictionary = players[id]
	for c in p.trail:
		owner_grid[_idx(c)] = id
	p.trail = [] as Array[Vector2i]
	# flood fill from borders through non-owned cells; unreachable -> owned
	var blocked := PackedByteArray()
	blocked.resize(GRID * GRID)
	var queue: Array[Vector2i] = []
	for i in GRID:
		for c in [Vector2i(i, 0), Vector2i(i, GRID - 1), Vector2i(0, i), Vector2i(GRID - 1, i)]:
			if owner_grid[_idx(c)] != id and blocked[_idx(c)] == 0:
				blocked[_idx(c)] = 1
				queue.append(c)
	while queue.size() > 0:
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if _in_grid(n) and blocked[_idx(n)] == 0 and owner_grid[_idx(n)] != id:
				blocked[_idx(n)] = 1
				queue.append(n)
	for i in owner_grid.size():
		if owner_grid[i] != id and blocked[i] == 0:
			owner_grid[i] = id
	_send_grid()

func _send_grid() -> void:
	cl_grid.rpc(snap_pack_grid())

func snap_pack_grid() -> PackedInt32Array:
	return owner_grid

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	var dead: Array[int] = []
	for id in players:
		var p: Dictionary = players[id]
		var cell := Vector2i(p.pos.round())
		# only turn at (near) cell centers; forbid reversing
		if p.want != -p.dir and p.pos.distance_to(Vector2(cell)) < 0.15:
			if p.want != p.dir:
				p.pos = Vector2(cell)
				p.dir = p.want
		p.pos += Vector2(p.dir) * SPEED * delta
		var ncell := Vector2i(p.pos.round())
		if not _in_grid(ncell):
			dead.append(id)
			continue
		if ncell != cell:
			# stepping onto a new cell
			for oid in players:
				var op: Dictionary = players[oid]
				if op.trail.has(ncell):
					dead.append(oid)  # trail owner dies (self-cross included)
			var own := owner_grid[_idx(ncell)]
			var pt: Array = p.trail
			if own == id and pt.size() > 0:
				_capture(id)
			elif own != id:
				if not pt.has(ncell):
					pt.append(ncell)
	for id in dead:
		_kill(id)
	accum += delta
	if accum >= TICK:
		accum = 0.0
		var snap := {}
		for id in players:
			var p: Dictionary = players[id]
			var tr := PackedVector2Array()
			for c in p.trail:
				tr.append(Vector2(c))
			snap[id] = [p.pos.x, p.pos.y, p.hue, tr]
		cl_state.rpc(snap)

func _process(_delta: float) -> void:
	if is_server:
		return
	var want := Vector2i.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		want = Vector2i.LEFT
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		want = Vector2i.RIGHT
	elif Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		want = Vector2i.UP
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		want = Vector2i.DOWN
	if want != Vector2i.ZERO and multiplayer.multiplayer_peer \
			and multiplayer.get_unique_id() != 1:
		srv_input.rpc_id(1, want)
	if snap_players.size() > 0 and snap_grid.size() > 0:
		var mine := 0
		var my_id := multiplayer.get_unique_id()
		for v in snap_grid:
			if v == my_id:
				mine += 1
		hud.text = "영토 %.1f%%   PLAYERS %d" % [100.0 * mine / (GRID * GRID), snap_players.size()]
	queue_redraw()

@rpc("any_peer", "call_remote", "unreliable")
func srv_input(want: Vector2i) -> void:
	if not is_server:
		return
	var id := multiplayer.get_remote_sender_id()
	if players.has(id) and abs(want.x) + abs(want.y) == 1:
		players[id].want = want

@rpc("authority", "call_remote", "unreliable")
func cl_state(p: Dictionary) -> void:
	snap_players = p

@rpc("authority", "call_remote", "reliable")
func cl_grid(g: PackedInt32Array) -> void:
	snap_grid = g

func _hue_for(id: int) -> float:
	if snap_players.has(id):
		return snap_players[id][2]
	return fmod(id * 0.618, 1.0)

func _draw() -> void:
	if is_server:
		return
	var vp := get_viewport_rect().size
	var my_id := multiplayer.get_unique_id()
	var cam := Vector2(GRID, GRID) * CELL / 2.0
	if snap_players.has(my_id):
		var me: Array = snap_players[my_id]
		cam = Vector2(me[0], me[1]) * CELL
	var off := vp / 2.0 - cam
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.09, 0.1, 0.12))
	draw_rect(Rect2(off - Vector2(CELL, CELL) / 2.0, Vector2(GRID, GRID) * CELL),
		Color(0.13, 0.14, 0.17))
	if snap_grid.size() == GRID * GRID:
		for gy in GRID:
			for gx in GRID:
				var o := snap_grid[gy * GRID + gx]
				if o != 0:
					var col := Color.from_hsv(_hue_for(o), 0.55, 0.8, 0.9)
					draw_rect(Rect2(Vector2(gx, gy) * CELL + off - Vector2(CELL, CELL) / 2.0,
						Vector2(CELL, CELL)), col)
	for id in snap_players:
		var s: Array = snap_players[id]
		var col := Color.from_hsv(s[2], 0.8, 1.0)
		var tr: PackedVector2Array = s[3]
		for c in tr:
			draw_rect(Rect2(c * CELL + off - Vector2(CELL, CELL) / 2.0,
				Vector2(CELL, CELL)), Color(col.r, col.g, col.b, 0.5))
		var pos := Vector2(s[0], s[1]) * CELL + off
		draw_rect(Rect2(pos - Vector2(CELL, CELL) * 0.55, Vector2(CELL, CELL) * 1.1), col)
		if id == my_id:
			draw_rect(Rect2(pos - Vector2(CELL, CELL) * 0.55, Vector2(CELL, CELL) * 1.1),
				Color.WHITE, false, 2.0)
