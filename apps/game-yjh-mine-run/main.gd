extends Node2D

# 지뢰밭 달리기 — 서버 권위. 격자를 한 줄씩 올라가는데 줄마다 지뢰가 숨어 있다.
# 밟으면 시작점으로 리셋 + 그 지뢰는 전원에게 공개(뒤에 가는 사람이 유리한 유즈맵 문법).
# 먼저 꼭대기에 닿는 사람이 라운드 승리. headless = 서버(ws :9108).

const WS_PORT := 9108
const COLS := 7
const ROWS := 9
const MINES_PER_ROW := 2
const WIN_PAUSE := 4.0
const DEAD_FLASH := 1.0
const TICK := 0.05

var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()

# --- server ---
var players := {}          # id -> [row(-1=시작), col, hue, wins, dead_t]
var mines: Array = []      # row -> Array[col]
var revealed: Array = []   # [row, col] 공개된 지뢰
var win_left := 0.0
var winner := 0
var accum := 0.0

# --- client ---
var snap := {}
var hud: Label
var shake := 0.0

func _ready() -> void:
	rng.randomize()
	is_server = DisplayServer.get_name() == "headless"
	if is_server:
		_start_server()
	else:
		_start_client()

# ---------- server ----------

func _start_server() -> void:
	peer.create_server(WS_PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_join)
	multiplayer.peer_disconnected.connect(func(id): players.erase(id))
	_new_field()
	print("mine-run server on ws://localhost:%d" % WS_PORT)

func _on_join(id: int) -> void:
	players[id] = [-1, COLS / 2, rng.randf(), 0, 0.0]

func _new_field() -> void:
	mines.clear()
	revealed.clear()
	for r in ROWS:
		var row: Array = []
		var pool := range(COLS)
		pool.shuffle()
		for m in MINES_PER_ROW:
			row.append(pool[m])
		mines.append(row)
	win_left = 0.0
	for id in players:
		players[id][0] = -1
		players[id][4] = 0.0

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	if win_left > 0.0:
		win_left -= delta
		if win_left <= 0.0:
			_new_field()
	for id in players:
		players[id][4] = maxf(0.0, players[id][4] - delta)
	accum += delta
	if accum >= TICK:
		accum = 0.0
		cl_state.rpc(players.duplicate(true), revealed.duplicate(true), win_left, winner)

@rpc("any_peer", "call_remote", "reliable")
func srv_step(col: int) -> void:
	if not is_server or win_left > 0.0 or players.size() < 2:
		return
	var id := multiplayer.get_remote_sender_id()
	if not players.has(id):
		return
	var p: Array = players[id]
	if p[4] > 0.0:
		return  # 죽음 연출 중
	var next_row: int = p[0] + 1
	if next_row >= ROWS or col < 0 or col >= COLS:
		return
	if p[0] >= 0 and absi(col - p[1]) > 1:
		return  # 대각 1칸까지만 (시작줄 진입은 자유)
	if mines[next_row].has(col):
		if not revealed.has([next_row, col]):
			revealed.append([next_row, col])
		p[0] = -1
		p[1] = COLS / 2
		p[4] = DEAD_FLASH
		return
	p[0] = next_row
	p[1] = col
	if next_row == ROWS - 1:
		winner = id
		p[3] += 1
		win_left = WIN_PAUSE

@rpc("authority", "call_remote", "unreliable")
func cl_state(p: Dictionary, rev: Array, win: float, w: int) -> void:
	snap = {"players": p, "revealed": rev, "win": win, "winner": w}

# ---------- client ----------

func _start_client() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(20, 12)
	hud.add_theme_font_size_override("font_size", 22)
	canvas.add_child(hud)
	hud.text = "connecting..."
	peer.create_client("ws://localhost:%d" % WS_PORT)
	multiplayer.multiplayer_peer = peer

func _cell_size() -> float:
	return minf(get_viewport_rect().size.x / (COLS + 2.0),
		(get_viewport_rect().size.y - 130.0) / (ROWS + 2.0))

func _grid_origin() -> Vector2:
	var vp := get_viewport_rect().size
	var cs := _cell_size()
	return Vector2((vp.x - cs * COLS) / 2.0, vp.y - 60.0 - cs)

func _cell_rect(row: int, col: int) -> Rect2:
	# row 0 이 아래(시작 쪽), 위로 올라감
	var o := _grid_origin()
	var cs := _cell_size()
	return Rect2(o + Vector2(col * cs, -row * cs), Vector2(cs - 4, cs - 4))

func _unhandled_input(event: InputEvent) -> void:
	if is_server or snap.is_empty() or float(snap["win"]) > 0.0:
		return
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var my_id := multiplayer.get_unique_id()
	if not snap["players"].has(my_id):
		return
	var me: Array = snap["players"][my_id]
	var next_row: int = me[0] + 1
	if next_row >= ROWS:
		return
	for c in COLS:
		if _cell_rect(next_row, c).has_point(event.position):
			srv_step.rpc_id(1, c)
			return

func _process(delta: float) -> void:
	if is_server or snap.is_empty():
		return
	var my_id := multiplayer.get_unique_id()
	if snap["players"].has(my_id) and float(snap["players"][my_id][4]) > DEAD_FLASH - 0.1:
		shake = 1.0
	shake = maxf(0.0, shake - 2.2 * delta)
	_update_hud()
	queue_redraw()


func _pname(id: int) -> String:
	# 피어 id 를 좌석 순번(P1..Pn)으로 — 전 클라 동일 계산
	var ids: Array = snap["players"].keys()
	ids.sort()
	return "P%d" % (ids.find(id) + 1)

func _update_hud() -> void:
	var my_id := multiplayer.get_unique_id()
	var ps: Dictionary = snap["players"]
	var lines := ""
	if ps.size() < 2:
		lines = "친구 접속 대기중... (%d/2, 파티게임)" % ps.size()
	elif float(snap["win"]) > 0.0:
		lines = "%s 완주!! 새 지뢰밭 준비중..." % ("내가" if snap["winner"] == my_id else _pname(snap["winner"]))
	else:
		lines = "다음 줄 칸을 클릭해 전진 (대각 1칸까지) — 지뢰 밟으면 처음부터, 밟힌 지뢰는 전원 공개"
	lines += "\n완주 —"
	for id in ps:
		lines += "  %s: %d%s" % [_pname(id), ps[id][3], " (나)" if id == my_id else ""]
	hud.text = lines

func _draw() -> void:
	if is_server or snap.is_empty():
		return
	var vp := get_viewport_rect().size
	var off := Vector2.ZERO
	if shake > 0.01:
		off = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake * 12.0
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.1, 0.12, 0.1))
	var my_id := multiplayer.get_unique_id()
	var ps: Dictionary = snap["players"]
	var me: Array = ps.get(my_id, [-1, 0, 0.0, 0, 0.0])
	var cs := _cell_size()
	# 결승선
	var top := _cell_rect(ROWS - 1, 0)
	draw_rect(Rect2(top.position + off - Vector2(0, cs * 0.5), Vector2(cs * COLS, 10)), Color(1.0, 0.85, 0.2))
	# 격자
	for r in ROWS:
		for c in COLS:
			var rect := _cell_rect(r, c)
			rect.position += off
			var col := Color(0.2, 0.3, 0.2) if (r + c) % 2 == 0 else Color(0.17, 0.26, 0.17)
			if r == me[0] + 1 and float(snap["win"]) <= 0.0 \
					and (me[0] < 0 or absi(c - me[1]) <= 1):
				col = col.lightened(0.13)   # 내가 갈 수 있는 칸
			draw_rect(rect, col)
			if snap["revealed"].has([r, c]):
				# 공개된 지뢰
				var cc := rect.get_center()
				draw_circle(cc, cs * 0.26, Color(0.75, 0.2, 0.15))
				draw_circle(cc, cs * 0.13, Color(0.3, 0.05, 0.05))
				for i in 6:
					var a := TAU * float(i) / 6.0
					draw_line(cc + Vector2.from_angle(a) * cs * 0.26,
						cc + Vector2.from_angle(a) * cs * 0.36, Color(0.75, 0.2, 0.15), 3.0)
	# 시작 존
	var o := _grid_origin() + off
	draw_string(ThemeDB.fallback_font, o + Vector2(cs * COLS / 2.0 - 30, cs + 34), "START",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.8, 0.8, 0.8, 0.7))
	# 플레이어 토큰 (같은 칸이면 살짝 어긋나게)
	var seen := {}
	for id in ps:
		var p: Array = ps[id]
		var key := [p[0], p[1]]
		var n: int = seen.get(key, 0)
		seen[key] = n + 1
		var pos: Vector2
		if p[0] < 0:
			pos = o + Vector2(cs * COLS / 2.0 + float(n) * 30.0 - 15.0 * (ps.size() - 1), cs * 0.9)
		else:
			pos = _cell_rect(p[0], p[1]).get_center() + off + Vector2(float(n) * 10.0 - 5.0, 0)
		var col := Color.from_hsv(p[2], 0.7, 0.95)
		if float(p[4]) > 0.0:
			col = Color(1.0, 0.3, 0.2)   # 사망 플래시
		draw_circle(pos + Vector2(2, 3), cs * 0.24, Color(0, 0, 0, 0.3))
		draw_circle(pos, cs * 0.24, col)
		draw_circle(pos - Vector2(cs * 0.07, cs * 0.09), cs * 0.07, col.lightened(0.35))
		if id == my_id:
			draw_arc(pos, cs * 0.3, 0.0, TAU, 24, Color.WHITE, 2.0)
