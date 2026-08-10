extends Node2D

# 폭탄 돌리기 — 서버 권위 실시간 핫포테이토. 심지 길이는 비밀(랜덤).
# 폭탄 든 사람이 다른 사람을 클릭해 넘긴다. 터질 때 들고 있으면 패배.
# headless = 서버(ws :9107), 그 외 = 클라이언트.

const WS_PORT := 9107
const FUSE_MIN := 8.0
const FUSE_MAX := 22.0
const PASS_TIME := 0.45     # 폭탄 날아가는 시간 (이동 중엔 안전)
const BOOM_PAUSE := 3.5
const TICK := 0.05

var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()

# --- server ---
var players := {}        # id -> [losses, hue]
var holder := 0
var fuse := 0.0          # 남은 심지 (비밀)
var fuse_total := 1.0
var fly_from := 0
var fly_to := 0
var fly_t := -1.0        # >=0 이면 비행 중
var boom_left := 0.0
var victim := 0
var accum := 0.0

# --- client ---
var snap := {}
var hud: Label
var spark_t := 0.0
var shake := 0.0
var flash := 0.0

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
	multiplayer.peer_disconnected.connect(_on_leave)
	print("bomb-pass server on ws://localhost:%d" % WS_PORT)

func _on_join(id: int) -> void:
	players[id] = [0, rng.randf()]
	if players.size() == 2:
		_new_round()

func _on_leave(id: int) -> void:
	players.erase(id)
	if holder == id and players.size() >= 2:
		_new_round()

func _new_round() -> void:
	var ids := players.keys()
	holder = ids[rng.randi_range(0, ids.size() - 1)]
	fuse_total = rng.randf_range(FUSE_MIN, FUSE_MAX)
	fuse = fuse_total
	fly_t = -1.0
	boom_left = 0.0

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	if players.size() >= 2 and boom_left <= 0.0:
		if fly_t >= 0.0:
			fly_t += delta
			if fly_t >= PASS_TIME:
				holder = fly_to
				fly_t = -1.0
		else:
			fuse -= delta
			if fuse <= 0.0:
				victim = holder
				players[holder][0] += 1
				boom_left = BOOM_PAUSE
	elif boom_left > 0.0:
		boom_left -= delta
		if boom_left <= 0.0 and players.size() >= 2:
			_new_round()
	accum += delta
	if accum >= TICK:
		accum = 0.0
		# fuse 잔량은 비밀 — 대신 심지 스파크 속도 힌트만 (0~1 노이즈성)
		cl_state.rpc(players.duplicate(true), holder, fly_from, fly_to,
			fly_t / PASS_TIME if fly_t >= 0.0 else -1.0, boom_left, victim,
			clampf(1.0 - fuse / fuse_total, 0.0, 1.0))

@rpc("any_peer", "call_remote", "reliable")
func srv_pass(target: int) -> void:
	if not is_server or boom_left > 0.0 or fly_t >= 0.0 or players.size() < 2:
		return
	var id := multiplayer.get_remote_sender_id()
	if id != holder or not players.has(target) or target == id:
		return
	fly_from = id
	fly_to = target
	fly_t = 0.0

@rpc("authority", "call_remote", "unreliable")
func cl_state(p: Dictionary, h: int, ff: int, ft: int, fly: float,
		boom: float, vic: int, burn: float) -> void:
	snap = {"players": p, "holder": h, "fly_from": ff, "fly_to": ft,
		"fly": fly, "boom": boom, "victim": vic, "burn": burn}

# ---------- client ----------

func _start_client() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(20, 14)
	hud.add_theme_font_size_override("font_size", 23)
	canvas.add_child(hud)
	hud.text = "connecting..."
	peer.create_client("ws://localhost:%d" % WS_PORT)
	multiplayer.multiplayer_peer = peer

func _seat_positions() -> Dictionary:
	# id 정렬 순서로 원탁 배치 — 모든 클라가 같은 배치를 계산
	var ids: Array = snap["players"].keys()
	ids.sort()
	var vp := get_viewport_rect().size
	var center := vp / 2.0 + Vector2(0, 30)
	var r := minf(vp.x, vp.y) * 0.33
	var out := {}
	for i in ids.size():
		var a := TAU * float(i) / float(ids.size()) - PI / 2.0
		out[ids[i]] = center + Vector2.from_angle(a) * r
	return out

func _unhandled_input(event: InputEvent) -> void:
	if is_server or snap.is_empty() or snap["boom"] > 0.0 or snap["fly"] >= 0.0:
		return
	if snap["holder"] != multiplayer.get_unique_id():
		return
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var seats := _seat_positions()
	for id in seats:
		if id != multiplayer.get_unique_id() and seats[id].distance_to(event.position) < 46.0:
			srv_pass.rpc_id(1, id)
			return

func _process(delta: float) -> void:
	if is_server or snap.is_empty():
		return
	spark_t += delta * (4.0 + float(snap["burn"]) * 14.0)   # 탈수록 스파크 빨라짐 (힌트)
	if snap["boom"] > BOOM_PAUSE - 0.15:
		shake = 1.0
		flash = 1.0
	shake = maxf(0.0, shake - 1.8 * delta)
	flash = maxf(0.0, flash - 2.0 * delta)
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
	elif snap["boom"] > 0.0:
		lines = "쾅!!! %s 폭사!" % ("내가" if snap["victim"] == my_id else _pname(snap["victim"]))
	elif snap["holder"] == my_id:
		lines = "내 손에 폭탄!! 아무나 클릭해서 넘겨!!"
	else:
		lines = "%s 가 폭탄을 들고 있다... 나한테 오지 마라" % _pname(snap["holder"])
	lines += "\n폭사 횟수 —"
	for id in ps:
		lines += "  %s: %d%s" % [_pname(id), ps[id][0], " (나)" if id == my_id else ""]
	hud.text = lines

func _draw() -> void:
	if is_server or snap.is_empty():
		return
	var vp := get_viewport_rect().size
	var off := Vector2.ZERO
	if shake > 0.01:
		off = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake * 16.0
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.12, 0.13, 0.18))
	var center := vp / 2.0 + Vector2(0, 30) + off
	draw_circle(center, minf(vp.x, vp.y) * 0.33 + 60.0, Color(0.16, 0.17, 0.23))
	var seats := _seat_positions()
	var my_id := multiplayer.get_unique_id()
	var ps: Dictionary = snap["players"]
	for id in seats:
		var pos: Vector2 = seats[id] + off
		var col := Color.from_hsv(ps[id][1], 0.65, 0.95)
		draw_circle(pos + Vector2(3, 4), 40.0, Color(0, 0, 0, 0.3))
		draw_circle(pos, 40.0, col)
		draw_circle(pos - Vector2(10, 12), 12.0, col.lightened(0.3))
		if id == my_id:
			draw_arc(pos, 47.0, 0.0, TAU, 32, Color.WHITE, 2.5)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-16, 8), _pname(id),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0, 0, 0, 0.75))
	# 폭탄 위치 (2인 미만 대기 중엔 숨김)
	if ps.size() < 2:
		return
	var bomb_pos: Vector2
	if snap["boom"] > 0.0:
		bomb_pos = seats.get(snap["victim"], center)
		var t: float = 1.0 - float(snap["boom"]) / BOOM_PAUSE
		for i in 12:
			var a := TAU * float(i) / 12.0
			draw_circle(bomb_pos + off + Vector2.from_angle(a) * t * 300.0, 16.0 * (1.0 - t) + 4.0,
				Color(1.0, 0.5 + rng.randf() * 0.3, 0.1, 1.0 - t))
	else:
		if float(snap["fly"]) >= 0.0:
			var a: Vector2 = seats.get(snap["fly_from"], center)
			var b: Vector2 = seats.get(snap["fly_to"], center)
			var t2: float = float(snap["fly"])
			bomb_pos = a.lerp(b, t2) - Vector2(0, sin(t2 * PI) * 90.0)
		else:
			bomb_pos = seats.get(snap["holder"], center) - Vector2(0, 62.0)
		bomb_pos += off
		# 폭탄 본체 + 심지 + 스파크
		draw_circle(bomb_pos + Vector2(2, 3), 22.0, Color(0, 0, 0, 0.35))
		draw_circle(bomb_pos, 22.0, Color(0.16, 0.16, 0.18))
		draw_circle(bomb_pos - Vector2(7, 8), 6.0, Color(0.45, 0.45, 0.5))
		var fuse_top := bomb_pos + Vector2(10, -24)
		draw_line(bomb_pos + Vector2(4, -18), fuse_top, Color(0.75, 0.6, 0.4), 3.0)
		var sp := fuse_top + Vector2(sin(spark_t * 3.0), cos(spark_t * 2.3)) * 3.0
		draw_circle(sp, 5.0 + sin(spark_t) * 2.0, Color(1.0, 0.8, 0.2))
		draw_circle(sp, 2.5, Color(1.0, 1.0, 0.7))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(1, 1, 1, flash * 0.6))
