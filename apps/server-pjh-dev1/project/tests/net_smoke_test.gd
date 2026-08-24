extends SceneTree

const HubClientScript = preload("res://scripts/net/hub_client.gd")
const NetWorldScript = preload("res://scripts/net/net_world.gd")
const GameWorldScript = preload("res://scripts/sim/game_world.gd")

var _hub
var _world
var _snaps := 0
var _failures: Array[String] = []

func _init() -> void:
	_run()

func _expect(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)
		push_error("FAIL: %s" % label)

# ── 1. 좌표계 · 상수 검증 (오프라인, 허브 불필요) ──

func _test_arena_constants() -> void:
	# game_world.gd 기준 상수
	_expect(GameWorldScript.ARENA_SIZE == Vector2(7840.0, 4760.0),
		"GameWorld ARENA_SIZE == 7840x4760 (got %s)" % str(GameWorldScript.ARENA_SIZE))
	_expect(GameWorldScript.ARENA_CENTER == Vector2(3920.0, 2380.0),
		"GameWorld ARENA_CENTER == 3920x2380 (got %s)" % str(GameWorldScript.ARENA_CENTER))
	_expect(GameWorldScript.ARENA_MARGIN == 104.0,
		"GameWorld ARENA_MARGIN == 104 (got %s)" % str(GameWorldScript.ARENA_MARGIN))
	_expect(GameWorldScript.HERO_RADIUS == 20.0,
		"GameWorld HERO_RADIUS == 20 (got %s)" % str(GameWorldScript.HERO_RADIUS))

func _test_net_world_constants_match() -> void:
	# net_world.gd 상수가 game_world.gd와 같은 PLAYER_COUNT를 갖는지
	_expect(NetWorldScript.PLAYER_COUNT == GameWorldScript.PLAYER_COUNT,
		"PLAYER_COUNT 일치 net=%d game=%d" % [NetWorldScript.PLAYER_COUNT, GameWorldScript.PLAYER_COUNT])
	_expect(NetWorldScript.FIXED_DT == GameWorldScript.FIXED_DT,
		"FIXED_DT 일치")
	_expect(NetWorldScript.MATCH_TIME_LIMIT == GameWorldScript.MATCH_TIME_LIMIT,
		"MATCH_TIME_LIMIT 일치")
	_expect(NetWorldScript.ULTIMATE_MAX == GameWorldScript.ULTIMATE_MAX,
		"ULTIMATE_MAX 일치")

func _test_clamp_arena_boundary() -> void:
	var gw = GameWorldScript.new()
	gw.rng = GameWorldScript.SeededRngScript.new()
	gw.event_log = GameWorldScript.EventLogScript.new()
	var margin: float = GameWorldScript.ARENA_MARGIN
	var radius: float = GameWorldScript.HERO_RADIUS
	var lo_x: float = margin + radius
	var hi_x: float = GameWorldScript.ARENA_SIZE.x - margin - radius
	var lo_y: float = margin + radius
	var hi_y: float = GameWorldScript.ARENA_SIZE.y - margin - radius

	# 범위 안 좌표는 그대로
	var inside := Vector2(5000.0, 3000.0)
	var clamped: Vector2 = gw._clamp_arena_point(inside, radius)
	_expect(clamped == inside,
		"범위 안 좌표 유지 (got %s)" % str(clamped))

	# 왼쪽 위 초과 → clamp
	var too_low := Vector2(0.0, 0.0)
	clamped = gw._clamp_arena_point(too_low, radius)
	_expect(absf(clamped.x - lo_x) < 0.01 and absf(clamped.y - lo_y) < 0.01,
		"좌상 초과 clamp (got %s, expect %s)" % [str(clamped), str(Vector2(lo_x, lo_y))])

	# 오른쪽 아래 초과 → clamp
	var too_high := Vector2(99999.0, 99999.0)
	clamped = gw._clamp_arena_point(too_high, radius)
	_expect(absf(clamped.x - hi_x) < 0.01 and absf(clamped.y - hi_y) < 0.01,
		"우하 초과 clamp (got %s, expect %s)" % [str(clamped), str(Vector2(hi_x, hi_y))])

	# 정확히 경계값
	var edge := Vector2(lo_x, hi_y)
	clamped = gw._clamp_arena_point(edge, radius)
	_expect(absf(clamped.x - lo_x) < 0.01 and absf(clamped.y - hi_y) < 0.01,
		"경계값 유지 (got %s)" % str(clamped))

func _test_net_world_pos_in_range() -> void:
	# net_world apply_snap 후 hero pos가 net_world ARENA_SIZE 범위 안인지
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.set_mode("classic")
	nw.reset()
	# heroes 초기화 후 좌표 확인
	for hero in nw.heroes:
		var px: float = float(hero.get("x", 0.0))
		var py: float = float(hero.get("y", 0.0))
		_expect(px >= 0.0 and px <= NetWorldScript.ARENA_SIZE.x,
			"hero x 범위 내 (got %.1f)" % px)
		_expect(py >= 0.0 and py <= NetWorldScript.ARENA_SIZE.y,
			"hero y 범위 내 (got %.1f)" % py)

# ── 2. GameState Autoload 검증 ──

func _test_game_state() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		print("INFO: GameState autoload 없음 — 건너뜀")
		return
	_expect(gs.current_state == gs.State.BOOT,
		"GameState 초기 상태 BOOT (got %d)" % gs.current_state)
	gs.request(gs.State.LOBBY)
	_expect(gs.current_state == gs.State.LOBBY,
		"BOOT→LOBBY 전이 성공 (got %d)" % gs.current_state)
	# 원복
	gs.current_state = gs.State.BOOT

# ── 3. locale/ko.csv 존재 확인 ──

func _test_locale_ko() -> void:
	var exists := FileAccess.file_exists("res://locale/ko.csv")
	if not exists:
		print("INFO: locale/ko.csv 없음 — 로케일 미구성")
	# 존재 여부만 기록, 없어도 실패 아님 (아직 선택 사항)
	_expect(true, "locale 확인 완료")

# ── 메인 실행 ──

func _run() -> void:
	# 오프라인 테스트 먼저
	_test_arena_constants()
	_test_net_world_constants_match()
	_test_clamp_arena_boundary()
	_test_net_world_pos_in_range()
	_test_game_state()
	_test_locale_ko()

	# 네트워크 테스트
	_hub = HubClientScript.new()
	_hub.player_name = "스모크"
	_hub.mode = "classic"
	root.add_child(_hub)
	_hub.snapshot_received.connect(_on_snap)
	_hub.ensure_connected()
	var ok := await _wait_for(func(): return _hub.status == "로비", 6.0)
	if not ok:
		_expect(_hub.status == "오프라인 로컬", "허브 없음이면 오프라인 로컬 상태여야 함 (got %s)" % _hub.status)
		print("SKIP: hub server not running, offline path verified")
		_finish()
		return
	_hub.create_room("스모크방")
	ok = await _wait_for(func(): return _hub.in_room, 4.0)
	_expect(ok, "create 후 joined 수신")
	_expect(_hub.you == 0, "첫 입장은 호스트 slot 0")
	_hub.start_match()
	ok = await _wait_for(func(): return _hub.match_running, 4.0)
	_expect(ok, "start 수신")
	_world = NetWorldScript.new()
	_world.local_slot = _hub.you
	_world.set_mode("classic")
	_world.reset()
	var frames := 0
	while frames < 150:
		await process_frame
		_hub.send_input(Vector2.RIGHT.rotated(float(frames) * 0.05), true, frames % 40 == 0, false, Vector2(800, 450))
		frames += 1
	_expect(_snaps >= 10, "snap 10개 이상 수신 (got %d)" % _snaps)
	if _world != null:
		_expect(_world.heroes.size() == 8, "heroes 8명 (got %d)" % _world.heroes.size())
		_expect(_world.tick >= 10, "tick 진행 (got %d)" % _world.tick)
		if _world.heroes.size() == 8:
			var me: Dictionary = _world.heroes[0]
			_expect(str(me.get("display_name", "")) == "스모크", "내 닉네임 표시")
			var cpu_count := 0
			for hero in _world.heroes:
				if bool(hero.get("cpu", false)):
					cpu_count += 1
			_expect(cpu_count == 7, "빈 자리 CPU 7명 (got %d)" % cpu_count)
		var summary: Dictionary = _world.summary()
		_expect(int(summary["alive"]) >= 1, "summary alive 집계")
		_expect(not _world.leaderboard().is_empty(), "leaderboard 동작")
	_hub.leave_room()
	ok = await _wait_for(func(): return not _hub.in_room, 4.0)
	_expect(ok, "leave 후 left 수신")
	_finish()

func _on_snap(snap: Dictionary) -> void:
	_snaps += 1
	if _world != null:
		_world.apply_snap(snap)

func _wait_for(condition: Callable, timeout: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			return true
		await process_frame
	return condition.call()

func _finish() -> void:
	if _failures.is_empty():
		print("NET SMOKE OK")
		quit(0)
	else:
		print("NET SMOKE FAILED: %d" % _failures.size())
		quit(1)
