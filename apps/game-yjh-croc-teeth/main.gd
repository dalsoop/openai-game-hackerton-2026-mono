extends Node3D

# 악어 이빨 룰렛 3D — 서버 권위. 돌아가며 이빨을 하나씩 누르고,
# 지뢰 이빨을 누르면 악어가 물어서 그 사람이 패배. 라운드 반복, 물린 횟수가 적을수록 승.
# headless 실행 = 서버(ws :9105), 그 외 = 클라이언트.

const WS_PORT := 9105
const TOOTH_COUNT := 12
const BITE_PAUSE := 3.0
const TICK := 0.1

var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()

# --- server state ---
var players := {}          # peer id -> [bites:int, hue:float]
var turn_order: Array = [] # peer id 순서
var turn_idx := 0
var pressed: Array = []    # 눌린 이빨 idx
var doom := -1             # 지뢰 이빨
var bite_left := 0.0       # >0 이면 물기 연출·정지 구간
var victim := 0
var accum := 0.0

# --- client state ---
var snap := {}
var hud: Label
var camera: Camera3D
var upper_jaw: Node3D
var teeth: Array = []      # tooth idx -> MeshInstance3D
var jaw_open := deg_to_rad(-38.0)

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
	_start_round()
	print("croc-teeth server on ws://localhost:%d" % WS_PORT)

func _on_join(id: int) -> void:
	players[id] = [0, rng.randf()]
	turn_order.append(id)

func _on_leave(id: int) -> void:
	players.erase(id)
	var i := turn_order.find(id)
	if i < 0:
		return
	turn_order.remove_at(i)
	if turn_order.is_empty():
		turn_idx = 0
	elif i < turn_idx or turn_idx >= turn_order.size():
		turn_idx = turn_idx % turn_order.size()

func _start_round() -> void:
	pressed.clear()
	doom = rng.randi_range(0, TOOTH_COUNT - 1)
	bite_left = 0.0
	victim = 0

func _current_turn() -> int:
	if turn_order.is_empty():
		return 0
	return turn_order[turn_idx % turn_order.size()]

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	if bite_left > 0.0:
		bite_left -= delta
		if bite_left <= 0.0:
			_start_round()
	accum += delta
	if accum >= TICK:
		accum = 0.0
		var out := {}
		for id in players:
			out[id] = players[id]
		cl_state.rpc(out, PackedInt32Array(pressed), _current_turn(),
			bite_left, victim, doom if bite_left > 0.0 else -1)

@rpc("any_peer", "call_remote", "reliable")
func srv_press(tooth: int) -> void:
	if not is_server or bite_left > 0.0:
		return
	var id := multiplayer.get_remote_sender_id()
	if id != _current_turn() or turn_order.size() < 2:
		return  # 자기 차례가 아니거나 혼자면 무시 (파티게임)
	if tooth < 0 or tooth >= TOOTH_COUNT or pressed.has(tooth):
		return
	pressed.append(tooth)
	if tooth == doom:
		players[id][0] += 1
		victim = id
		bite_left = BITE_PAUSE
		# 물린 사람이 다음 라운드 선공
		turn_idx = turn_order.find(id)
	else:
		turn_idx = (turn_idx + 1) % turn_order.size()

@rpc("authority", "call_remote", "unreliable")
func cl_state(p: Dictionary, pr: PackedInt32Array, turn: int,
		bite: float, vic: int, doom_idx: int) -> void:
	snap = {"players": p, "pressed": pr, "turn": turn,
		"bite": bite, "victim": vic, "doom": doom_idx}

# ---------- client ----------

func _start_client() -> void:
	_build_scene()
	peer.create_client("ws://localhost:%d" % WS_PORT)
	multiplayer.multiplayer_peer = peer

var croc: Node3D          # 전체 악어 (물에 뜬 채로 둥실거림)
var cam_base := Vector3(0, 4.0, 6.6)
var shake := 0.0
var bob_t := 0.0

func _mat(color: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

func _blob(parent: Node3D, pos: Vector3, size: Vector3, color: Color,
		rough := 0.9, rot := Vector3.ZERO) -> MeshInstance3D:
	# 타원체 — 유기적 형태의 기본 블록
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 32
	sphere.rings = 16
	mi.mesh = sphere
	mi.material_override = _mat(color, rough)
	mi.position = pos
	mi.scale = size
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

func _cone(parent: Node3D, pos: Vector3, r: float, h: float, color: Color,
		rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.01
	cyl.bottom_radius = r
	cyl.height = h
	cyl.radial_segments = 16
	mi.mesh = cyl
	mi.material_override = _mat(color, 0.55)
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

func _tooth_positions() -> Array:
	# 아랫턱 가장자리 U자 배열 (앞쪽이 +Z, 카메라 방향)
	var pts: Array = []
	for i in TOOTH_COUNT:
		var t := float(i) / float(TOOTH_COUNT - 1)
		var ang := lerpf(PI * 0.12, PI * 0.88, t)
		pts.append(Vector3(cos(ang) * -1.25, 0.62, sin(ang) * 2.0 - 0.35))
	return pts

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.5, 0.8)
	sky_mat.sky_horizon_color = Color(0.75, 0.85, 0.9)
	sky_mat.ground_bottom_color = Color(0.2, 0.35, 0.4)
	sky_mat.ground_horizon_color = Color(0.7, 0.82, 0.88)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color(0.7, 0.82, 0.88)
	e.fog_density = 0.008
	var env := WorldEnvironment.new()
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 140, 0)
	fill.light_energy = 0.35
	fill.light_color = Color(0.6, 0.75, 0.9)
	add_child(fill)

func _build_water() -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	water.mesh = plane
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.1, 0.4, 0.45, 0.95)
	wm.roughness = 0.4
	wm.metallic = 0.0
	water.material_override = wm
	water.position = Vector3(0, -0.25, 0)
	add_child(water)
	# 수련잎 몇 장
	for lp in [Vector3(-4.5, -0.23, -1.5), Vector3(4.2, -0.23, -3.0), Vector3(-3.2, -0.23, 3.2)]:
		var pad := _blob(self, lp, Vector3(1.6, 0.06, 1.6), Color(0.2, 0.5, 0.25), 0.8)
		pad.rotation_degrees.y = lp.x * 40.0

func _build_croc() -> void:
	croc = Node3D.new()
	add_child(croc)
	var green := Color(0.3, 0.52, 0.22)
	var belly := Color(0.75, 0.78, 0.55)
	var mouth_red := Color(0.55, 0.18, 0.18)
	# 아랫턱 (긴 주둥이) + 턱 밑 살
	_blob(croc, Vector3(0, 0.35, 0.2), Vector3(2.9, 0.55, 4.6), green)
	_blob(croc, Vector3(0, 0.12, 0.3), Vector3(2.6, 0.38, 4.1), belly)
	# 입 안 바닥 + 혀
	_blob(croc, Vector3(0, 0.5, 0.1), Vector3(2.45, 0.22, 3.9), mouth_red)
	_blob(croc, Vector3(0, 0.56, 0.4), Vector3(1.2, 0.16, 2.0), Color(0.8, 0.3, 0.35), 0.95)
	# 머리 뒤통수·몸통·꼬리 (뒤로 갈수록 낮게 물에 잠김)
	_blob(croc, Vector3(0, 0.55, -2.9), Vector3(3.1, 1.3, 2.6), green)
	# 눈 (머리 위 돌출 — 카메라에서 보이게)
	for sx in [-1.0, 1.0]:
		_blob(croc, Vector3(sx, 1.5, -3.2), Vector3(0.75, 0.75, 0.75), green.darkened(0.1))
		var eye := _blob(croc, Vector3(sx, 1.75, -3.1), Vector3(0.48, 0.48, 0.42), Color(0.95, 0.9, 0.6), 0.3)
		_blob(eye, Vector3(0, 0.15, 0.38), Vector3(0.5, 0.6, 0.35), Color.BLACK, 0.2)
	_blob(croc, Vector3(0, 0.35, -5.2), Vector3(2.7, 1.1, 3.2), green.darkened(0.08))
	_blob(croc, Vector3(0, 0.15, -7.6), Vector3(1.6, 0.7, 2.8), green.darkened(0.15))
	_blob(croc, Vector3(0, 0.05, -9.4), Vector3(0.8, 0.4, 1.8), green.darkened(0.2))
	# 등 비늘 (지그재그 콘)
	for i in 9:
		var z := -2.2 - float(i) * 0.75
		var s := 0.32 - float(i) * 0.02
		_cone(croc, Vector3(0, 1.0 - float(i) * 0.09, z), s, s * 2.2, green.darkened(0.3))
		if i % 2 == 0:
			_cone(croc, Vector3(-0.7, 0.85 - float(i) * 0.09, z), s * 0.6, s * 1.4, green.darkened(0.25))
			_cone(croc, Vector3(0.7, 0.85 - float(i) * 0.09, z), s * 0.6, s * 1.4, green.darkened(0.25))
	# 앞다리
	for sx in [-1.5, 1.5]:
		_blob(croc, Vector3(sx, 0.1, -3.6), Vector3(0.7, 0.5, 1.2), green.darkened(0.1))
	# 윗턱 (뒤쪽 피벗, 열린 채 시작)
	upper_jaw = Node3D.new()
	upper_jaw.position = Vector3(0, 0.62, -1.6)
	upper_jaw.rotation.x = jaw_open
	croc.add_child(upper_jaw)
	_blob(upper_jaw, Vector3(0, 0.15, 2.1), Vector3(2.7, 0.55, 4.4), green.lightened(0.06))
	_blob(upper_jaw, Vector3(0, -0.02, 2.0), Vector3(2.35, 0.3, 3.9), mouth_red)
	# 콧구멍
	for sx in [-0.45, 0.45]:
		_blob(upper_jaw, Vector3(sx, 0.38, 4.0), Vector3(0.3, 0.22, 0.3), green.darkened(0.2))
	# 윗니 (아래로 향한 콘, 장식용)
	for i in TOOTH_COUNT:
		var t := float(i) / float(TOOTH_COUNT - 1)
		var ang := lerpf(PI * 0.12, PI * 0.88, t)
		var pos := Vector3(cos(ang) * -1.15, -0.12, sin(ang) * 1.95 + 0.15)
		_cone(upper_jaw, pos, 0.13, 0.5, Color(0.95, 0.93, 0.85), Vector3(180, 0, 0))

func _build_teeth() -> void:
	# 아랫니 12개 — 클릭 대상 (StaticBody3D 픽킹)
	var positions := _tooth_positions()
	for i in TOOTH_COUNT:
		var body := StaticBody3D.new()
		body.position = positions[i]
		body.set_meta("tooth", i)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.5, 0.9, 0.5)
		shape.shape = box
		body.add_child(shape)
		var tooth := _cone(body, Vector3.ZERO, 0.2, 0.75, Color(0.95, 0.93, 0.85))
		croc.add_child(body)
		teeth.append(tooth)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.45)
	panel.position = Vector2(10, 8)
	panel.size = Vector2(560, 86)
	canvas.add_child(panel)
	hud = Label.new()
	hud.position = Vector2(24, 14)
	hud.add_theme_font_size_override("font_size", 23)
	hud.add_theme_color_override("font_color", Color(1, 1, 0.9))
	canvas.add_child(hud)
	hud.text = "connecting..."

func _build_scene() -> void:
	_build_environment()
	camera = Camera3D.new()
	camera.position = cam_base
	camera.rotation_degrees = Vector3(-29, 0, 0)
	camera.fov = 55.0
	add_child(camera)
	_build_water()
	_build_croc()
	_build_teeth()
	_build_hud()

func _unhandled_input(event: InputEvent) -> void:
	if is_server or snap.is_empty():
		return
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var tooth := _pick_tooth(event.position)
	if tooth >= 0:
		srv_press.rpc_id(1, tooth)

func _pick_tooth(screen_pos: Vector2) -> int:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 50.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit.collider.has_meta("tooth"):
		return -1
	return hit.collider.get_meta("tooth")

func _process(delta: float) -> void:
	if is_server or snap.is_empty():
		return
	bob_t += delta
	croc.position.y = sin(bob_t * 1.3) * 0.05
	_update_teeth()
	_update_jaw(delta)
	_update_camera(delta)
	_update_hud()

func _update_teeth() -> void:
	var pr: PackedInt32Array = snap["pressed"]
	var doom_idx: int = snap["doom"]
	for i in teeth.size():
		var tooth: MeshInstance3D = teeth[i]
		tooth.position.y = -0.45 if pr.has(i) else 0.0
		var mat: StandardMaterial3D = tooth.material_override
		if i == doom_idx:
			mat.albedo_color = Color(0.9, 0.15, 0.15)     # 물릴 때 지뢰 공개
		elif pr.has(i):
			mat.albedo_color = Color(0.55, 0.5, 0.45)
		else:
			mat.albedo_color = Color(0.95, 0.93, 0.85)

func _update_jaw(delta: float) -> void:
	var biting: bool = snap["bite"] > BITE_PAUSE - 0.9    # 물기 직후 0.9초 닫음
	var target := 0.0 if biting else jaw_open
	upper_jaw.rotation.x = lerp_angle(upper_jaw.rotation.x, target, 14.0 * delta)
	shake = 0.35 if biting else maxf(0.0, shake - 2.5 * delta)

func _update_camera(_delta: float) -> void:
	var off := Vector3.ZERO
	if shake > 0.01:
		off = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), 0) * shake * 0.25
	camera.position = cam_base + off


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
	elif snap["bite"] > 0.0:
		var who := "내가" if snap["victim"] == my_id else "%s 가" % _pname(snap["victim"])
		lines = "덥썩! %s 물렸다!  잠시 후 다음 라운드" % who
	elif snap["turn"] == my_id:
		lines = "내 차례! 이빨을 눌러라"
	else:
		lines = "%s 차례 대기중" % _pname(snap["turn"])
	lines += "\n물린 횟수 —"
	for id in ps:
		lines += "  %s: %d%s" % [_pname(id), ps[id][0], " (나)" if id == my_id else ""]
	hud.text = lines
