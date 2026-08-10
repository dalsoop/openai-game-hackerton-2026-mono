extends Node2D

# 총알 생존 멀티 — 서버 권위. 총알이 하나씩 늘어나고, 제일 오래 버티는 사람이 이긴다.
# headless 실행 = 서버(ws :9104), 그 외 = 클라이언트.

const WS_PORT := 9104
const ARENA := Vector2(1120.0, 640.0)
const PLAYER_R := 10.0
const BULLET_R := 7.0
const PLAYER_SPEED := 280.0
const BULLET_SPEED_MIN := 160.0
const BULLET_SPEED_MAX := 300.0
const BULLET_EVERY := 2.0   # 이 주기마다 총알 +1
const INTERMISSION := 4.0
const TICK := 0.05

var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()

class Player:
	var pos := Vector2.ZERO
	var move := Vector2.ZERO   # 클라 입력 (정규화 방향)
	var alive := false
	var survived := 0.0        # 이번 라운드 생존 시간
	var best := 0.0            # 접속 후 최고 기록
	var hue := 0.0

# --- server state ---
var players := {}              # peer id -> Player
var bullets: Array = []        # [pos, vel]
var round_time := 0.0
var spawn_timer := 0.0
var intermission_left := 0.0   # >0 이면 라운드 사이 대기
var accum := 0.0

# --- client state ---
var snap := {}                 # 서버 스냅샷 (players/bullets/round/inter)
var hud: Label

func _ready() -> void:
	rng.randomize()
	is_server = DisplayServer.get_name() == "headless"
	if is_server:
		_start_server()
	else:
		_start_client()

func _start_server() -> void:
	peer.create_server(WS_PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_join)
	multiplayer.peer_disconnected.connect(func(id): players.erase(id))
	_start_round()
	print("dodge server on ws://localhost:%d" % WS_PORT)

func _start_client() -> void:
	hud = Label.new()
	hud.position = Vector2(16, 10)
	hud.add_theme_font_size_override("font_size", 22)
	add_child(hud)
	hud.text = "connecting..."
	peer.create_client("ws://localhost:%d" % WS_PORT)
	multiplayer.multiplayer_peer = peer

func _on_join(id: int) -> void:
	var p := Player.new()
	p.hue = rng.randf()
	players[id] = p
	# 라운드 중간 난입은 관전 — 다음 라운드에 참가

func _start_round() -> void:
	round_time = 0.0
	spawn_timer = 0.0
	intermission_left = 0.0
	bullets.clear()
	for id in players:
		var p: Player = players[id]
		p.alive = true
		p.survived = 0.0
		p.pos = ARENA / 2.0 + Vector2(rng.randf_range(-120, 120), rng.randf_range(-120, 120))

func _spawn_bullet() -> void:
	# 가장자리에서 안쪽으로 발사, 이후 벽 반사로 계속 남는다
	var side := rng.randi_range(0, 3)
	var pos := Vector2.ZERO
	match side:
		0: pos = Vector2(rng.randf() * ARENA.x, 0.0)
		1: pos = Vector2(rng.randf() * ARENA.x, ARENA.y)
		2: pos = Vector2(0.0, rng.randf() * ARENA.y)
		3: pos = Vector2(ARENA.x, rng.randf() * ARENA.y)
	var to_center := (ARENA / 2.0 - pos).angle()
	var vel := Vector2.from_angle(to_center + rng.randf_range(-0.7, 0.7)) \
		* rng.randf_range(BULLET_SPEED_MIN, BULLET_SPEED_MAX)
	bullets.append([pos, vel])

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	if intermission_left > 0.0:
		intermission_left -= delta
		if intermission_left <= 0.0:
			_start_round()
	else:
		_step_round(delta)
	accum += delta
	if accum >= TICK:
		accum = 0.0
		_broadcast()

func _step_round(delta: float) -> void:
	round_time += delta
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = BULLET_EVERY
		_spawn_bullet()
	for b in bullets:
		b[0] += b[1] * delta
		if b[0].x < BULLET_R or b[0].x > ARENA.x - BULLET_R:
			b[1].x = -b[1].x
		if b[0].y < BULLET_R or b[0].y > ARENA.y - BULLET_R:
			b[1].y = -b[1].y
		b[0] = b[0].clamp(Vector2.ONE * BULLET_R, ARENA - Vector2.ONE * BULLET_R)
	var alive_count := 0
	for id in players:
		var p: Player = players[id]
		if not p.alive:
			continue
		p.pos = (p.pos + p.move * PLAYER_SPEED * delta) \
			.clamp(Vector2.ONE * PLAYER_R, ARENA - Vector2.ONE * PLAYER_R)
		p.survived = round_time
		for b in bullets:
			if p.pos.distance_to(b[0]) < PLAYER_R + BULLET_R:
				p.alive = false
				p.best = maxf(p.best, p.survived)
				break
		if p.alive:
			alive_count += 1
	# 전멸하면 정산 후 다음 라운드
	if alive_count == 0 and round_time > 0.5 and players.size() > 0:
		intermission_left = INTERMISSION

func _broadcast() -> void:
	var out := {}
	for id in players:
		var p: Player = players[id]
		out[id] = [p.pos, p.alive, p.hue, p.survived, p.best]
	var pb := PackedVector2Array()
	for b in bullets:
		pb.append(b[0])
	cl_state.rpc(out, pb, round_time, intermission_left)

@rpc("any_peer", "call_remote", "unreliable")
func srv_input(move: Vector2) -> void:
	if not is_server:
		return
	var id := multiplayer.get_remote_sender_id()
	if players.has(id):
		players[id].move = move.limit_length(1.0)

@rpc("authority", "call_remote", "unreliable")
func cl_state(p: Dictionary, b: PackedVector2Array, t: float, inter: float) -> void:
	snap = {"players": p, "bullets": b, "time": t, "inter": inter}

func _process(_delta: float) -> void:
	if is_server:
		return
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		srv_input.rpc_id(1, move)
		_update_hud()
	queue_redraw()

func _update_hud() -> void:
	if snap.is_empty():
		return
	var my_id := multiplayer.get_unique_id()
	var ps: Dictionary = snap["players"]
	var lines := "TIME %.1f   BULLETS %d" % [snap["time"], snap["bullets"].size()]
	if ps.has(my_id):
		var me: Array = ps[my_id]
		if not me[1]:
			lines += "   [죽음 — 다음 라운드 대기]"
		lines += "   BEST %.1f" % me[4]
	if snap["inter"] > 0.0:
		lines += "\n라운드 종료! 생존 시간 순위:"
		var ranked := ps.keys()
		ranked.sort_custom(func(a, b): return ps[a][3] > ps[b][3])
		for i in ranked.size():
			lines += "\n  %d위  %.1fs%s" % [i + 1, ps[ranked[i]][3],
				"  ← 나" if ranked[i] == my_id else ""]
	hud.text = lines

func _arena_offset() -> Vector2:
	return (get_viewport_rect().size - ARENA) / 2.0

func _draw() -> void:
	if is_server or snap.is_empty():
		return
	var off := _arena_offset()
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.07, 0.08, 0.1))
	draw_rect(Rect2(off, ARENA), Color(0.11, 0.12, 0.16))
	draw_rect(Rect2(off, ARENA), Color(0.9, 0.3, 0.3, 0.9), false, 4.0)
	var my_id := multiplayer.get_unique_id()
	var ps: Dictionary = snap["players"]
	for id in ps:
		var p: Array = ps[id]
		var col := Color.from_hsv(p[2], 0.7, 0.95)
		if not p[1]:
			col.a = 0.25
		draw_circle(p[0] + off, PLAYER_R, col)
		if id == my_id:
			draw_arc(p[0] + off, PLAYER_R + 4.0, 0.0, TAU, 24, Color.WHITE, 2.0)
	for b in snap["bullets"]:
		draw_circle(b + off, BULLET_R, Color(1.0, 0.85, 0.3))
