extends SceneTree

const HubClientScript = preload("res://autoload/network_manager.gd")
const NetWorldScript = preload("res://scripts/net/net_world.gd")

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

func _run() -> void:
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
        _hub.send_input(Vector2.RIGHT.rotated(float(frames) * 0.05), true, frames % 40 == 0, false, Vector2(3920, 2380))
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
