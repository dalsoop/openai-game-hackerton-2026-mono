extends Node2D

# 풍선 펌프 룰렛 — 서버 권위 턴제. 자기 턴에 최소 1번 펌프, 욕심내면 더 누를 수 있다.
# 펌프 1번 = 1점. 랜덤 한계에서 빵 터지면 그 사람 -5점. 눈치와 복불복.
# headless = 서버(ws :9106), 그 외 = 클라이언트.

const WS_PORT := 9106
const BURST_MIN := 8
const BURST_MAX := 26
const BURST_PAUSE := 3.0
const BURST_PENALTY := 5
const TICK := 0.1

var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()

# --- server ---
var players := {}          # id -> [score, hue]
var turn_order: Array = []
var turn_idx := 0
var pumps := 0             # 현재 풍선 누적 펌프
var pumped_this_turn := 0
var threshold := 0         # 비밀 한계
var burst_left := 0.0
var victim := 0
var accum := 0.0

# --- client ---
var snap := {}
var hud: Label
var balloon_r := 46.0      # 표시 반지름 (부드럽게 따라감)
var wobble := 0.0
var shake := 0.0
var burst_flash := 0.0

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
	_new_balloon()
	print("balloon-pump server on ws://localhost:%d" % WS_PORT)

func _on_join(id: int) -> void:
	players[id] = [0, rng.randf()]
	turn_order.append(id)

func _on_leave(id: int) -> void:
	players.erase(id)
	var i := turn_order.find(id)
	if i < 0:
		return
	turn_order.remove_at(i)
	if not turn_order.is_empty():
		turn_idx = turn_idx % turn_order.size()

func _new_balloon() -> void:
	pumps = 0
	pumped_this_turn = 0
	threshold = rng.randi_range(BURST_MIN, BURST_MAX)
	burst_left = 0.0

func _current_turn() -> int:
	if turn_order.is_empty():
		return 0
	return turn_order[turn_idx % turn_order.size()]

func _next_turn() -> void:
	pumped_this_turn = 0
	if not turn_order.is_empty():
		turn_idx = (turn_idx + 1) % turn_order.size()

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	if burst_left > 0.0:
		burst_left -= delta
		if burst_left <= 0.0:
			_new_balloon()
	accum += delta
	if accum >= TICK:
		accum = 0.0
		cl_state.rpc(players.duplicate(true), pumps, _current_turn(),
			pumped_this_turn, burst_left, victim)

@rpc("any_peer", "call_remote", "reliable")
func srv_pump() -> void:
	if not is_server or burst_left > 0.0 or turn_order.size() < 2:
		return
	var id := multiplayer.get_remote_sender_id()
	if id != _current_turn():
		return
	pumps += 1
	pumped_this_turn += 1
	if pumps >= threshold:
		victim = id
		players[id][0] = maxi(0, players[id][0] - BURST_PENALTY)
		burst_left = BURST_PAUSE
		_next_turn()
	else:
		players[id][0] += 1

@rpc("any_peer", "call_remote", "reliable")
func srv_pass() -> void:
	if not is_server or burst_left > 0.0:
		return
	var id := multiplayer.get_remote_sender_id()
	if id == _current_turn() and pumped_this_turn >= 1:
		_next_turn()

@rpc("authority", "call_remote", "unreliable")
func cl_state(p: Dictionary, pm: int, turn: int, ptt: int, burst: float, vic: int) -> void:
	snap = {"players": p, "pumps": pm, "turn": turn, "ptt": ptt,
		"burst": burst, "victim": vic}

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

func _my_turn() -> bool:
	return snap["turn"] == multiplayer.get_unique_id()

func _unhandled_input(event: InputEvent) -> void:
	if is_server or snap.is_empty() or snap["burst"] > 0.0 or not _my_turn():
		return
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if _pass_rect().has_point(event.position):
			srv_pass.rpc_id(1)
		else:
			srv_pump.rpc_id(1)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			srv_pump.rpc_id(1)
		elif event.keycode == KEY_ENTER:
			srv_pass.rpc_id(1)

func _pass_rect() -> Rect2:
	var vp := get_viewport_rect().size
	return Rect2(vp.x - 240, vp.y - 90, 210, 62)

func _process(delta: float) -> void:
	if is_server or snap.is_empty():
		return
	wobble += delta * 5.0
	var target_r := 46.0 + float(snap["pumps"]) * 7.0
	if snap["burst"] > BURST_PAUSE - 0.15:
		burst_flash = 1.0
		shake = 1.0
	balloon_r = lerpf(balloon_r, 46.0 if snap["burst"] > 0.0 else target_r, 10.0 * delta)
	burst_flash = maxf(0.0, burst_flash - 2.2 * delta)
	shake = maxf(0.0, shake - 2.0 * delta)
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
	elif snap["burst"] > 0.0:
		var who := "내" if snap["victim"] == my_id else _pname(snap["victim"])
		lines = "빵!! %s 풍선 폭발 (-%d점)" % [who, BURST_PENALTY]
	elif _my_turn():
		lines = "내 차례 — 클릭/스페이스=펌프(+1점)"
		if snap["ptt"] >= 1:
			lines += " · 엔터/버튼=패스"
		else:
			lines += " · 최소 1번은 눌러야 함"
	else:
		lines = "%s 가 펌프 중... 몇 번이나 누를까" % _pname(snap["turn"])
	lines += "\n점수 —"
	for id in ps:
		lines += "  %s: %d%s" % [_pname(id), ps[id][0], " (나)" if id == my_id else ""]
	hud.text = lines

func _draw() -> void:
	if is_server or snap.is_empty():
		return
	var vp := get_viewport_rect().size
	var center := vp / 2.0 + Vector2(0, 40)
	if shake > 0.01:
		center += Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake * 14.0
	# 배경 그라데이션 (하늘)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.13, 0.15, 0.22))
	draw_rect(Rect2(0, 0, vp.x, vp.y * 0.5), Color(0.16, 0.19, 0.28))
	# 위험도: 펌프 수에 따라 노랑→빨강
	var risk := clampf(float(snap["pumps"]) / float(BURST_MAX), 0.0, 1.0)
	var col := Color(1.0, 0.85 - risk * 0.6, 0.35 - risk * 0.25)
	if snap["burst"] > 0.0:
		# 터진 조각 연출
		for i in 10:
			var a := TAU * float(i) / 10.0 + wobble * 0.3
			var d: float = (1.0 - float(snap["burst"]) / BURST_PAUSE) * 260.0 + 40.0
			draw_circle(center + Vector2.from_angle(a) * d, 14.0, col.darkened(0.1))
	else:
		var w := sin(wobble) * (2.0 + risk * 6.0)
		# 끈
		draw_line(center + Vector2(0, balloon_r), center + Vector2(sin(wobble * 0.7) * 10.0, balloon_r + 90.0), Color(0.8, 0.8, 0.8), 2.0)
		# 풍선 본체 (레이어드 셰이딩)
		draw_circle(center + Vector2(4, 6), balloon_r + w, Color(0, 0, 0, 0.25))
		draw_circle(center, balloon_r + w, col)
		draw_circle(center - Vector2(balloon_r * 0.3, balloon_r * 0.35), balloon_r * 0.35, col.lightened(0.35))
		draw_circle(center + Vector2(0, balloon_r + w - 2.0), 7.0, col.darkened(0.2))
		# 펌프 카운트
		draw_string(ThemeDB.fallback_font, center - Vector2(22, -8), "%d" % snap["pumps"],
			HORIZONTAL_ALIGNMENT_CENTER, 44, 40, Color(0.1, 0.1, 0.1, 0.8))
	if burst_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(1, 1, 1, burst_flash * 0.55))
	# 패스 버튼
	if not snap["burst"] > 0.0 and _my_turn() and snap["ptt"] >= 1:
		var r := _pass_rect()
		draw_rect(r, Color(0.25, 0.55, 0.35))
		draw_rect(r, Color.WHITE, false, 2.0)
		draw_string(ThemeDB.fallback_font, r.position + Vector2(52, 40), "패스 →",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
