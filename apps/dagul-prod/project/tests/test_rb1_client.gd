extends RefCounted
## RB1: 히트 포즈 중 입력 유지, playing 재입장 카운트다운 0, 브리지 입력 스킵.

const GameScript := preload("res://games/dagul/game.gd")
const NetWorldScript := preload("res://games/dagul/net/net_world.gd")
const SnapContract := preload("res://games/dagul/net/snap_contract.gd")

func run(t) -> void:
	_guest_countdown_starts_zero(t)
	_hit_pose_keeps_input(t)
	_bridge_skips_same_input(t)

func _guest_countdown_starts_zero(t) -> void:
	var g = GameScript.new()
	g._start_as_guest(0, "full")
	t.check("재입장 기본 카운트다운 0", is_equal_approx(float(g.world.start_countdown), 0.0))
	t.check("히어로 없으면 예측 seq 고정", g.world.predict_local(Vector2.RIGHT, false, Vector2.ONE, 1.0 / 60.0) == 0)

func _hit_pose_keeps_input(t) -> void:
	var hub := FakeHub.new()
	t.root.add_child(hub)
	var hud := FakeHud.new()
	t.root.add_child(hud)
	var world_view := Node2D.new()
	t.root.add_child(world_view)
	var camera := Camera2D.new()
	world_view.add_child(camera)
	var layer := CanvasLayer.new()
	t.root.add_child(layer)
	var g = GameScript.new()
	g.world = _playing_world()
	g.hit_pause_frames = 3
	var cam0 := camera.position
	g.tick(1.0 / 60.0, {
		"hub": hub, "hud": hud, "world_view": world_view, "camera": camera,
		"hud_layer": layer, "touch": null, "settings_open": false,
	})
	t.check("히트 포즈가 줄어든다", g.hit_pause_frames == 2)
	t.check("히트 포즈 중 입력 송신", hub.packets.size() == 1)
	t.check("히트 포즈 중 예측 seq 증가", int(g.world._input_seq) == 1)
	t.check("히트 포즈 중 카메라 정지", camera.position == cam0)
	hub.queue_free()
	hud.queue_free()
	world_view.queue_free()
	layer.queue_free()

func _bridge_skips_same_input(t) -> void:
	var nm: Node = load("res://core/autoload/network_manager.gd").new()
	nm.send_input({"mx": 1.0, "my": 0.0, "seq": 1})
	var first := str(nm.get("_last_input_fp"))
	nm.send_input({"mx": 1.0, "my": 0.0, "seq": 2})
	t.check("내용 같으면 seq 만 바뀌어도 스킵", str(nm.get("_last_input_fp")) == first)
	nm.send_input({"mx": 0.0, "my": 0.0, "seq": 3})
	t.check("내용이 바뀌면 지문 갱신", str(nm.get("_last_input_fp")) != first)
	nm.free()

func _playing_world():
	var nw = NetWorldScript.new()
	nw.local_slot = 0
	nw.start_countdown = 0.0
	nw.push_snap({
		SnapContract.TICK: 12,
		SnapContract.TIME: 1.0,
		SnapContract.RESULT: "playing",
		SnapContract.ZONE_R: 3304.0,
		SnapContract.PLAYERS: [{
			SnapContract.P_SLOT: 0, SnapContract.P_NAME: "나",
			SnapContract.P_X: 3920.0, SnapContract.P_Y: 2380.0,
			SnapContract.P_AIM_X: 4020.0, SnapContract.P_AIM_Y: 2380.0,
			SnapContract.P_HP: 100.0, SnapContract.P_MAX_HP: 100.0,
			SnapContract.P_ALIVE: true, SnapContract.P_MAG: 7, SnapContract.P_MAG_MAX: 18,
			SnapContract.P_KILLS: 0, SnapContract.P_ACK: 0,
		}],
	})
	nw.present(1.0 / 60.0)
	return nw

class FakeHud extends Control:
	var net_rtt_ms: int = 0
	var net_connected: bool = false
	var spectate_slot: int = 0
	var hud_mode: int = 0
	var touch_hints: bool = false

class FakeHub extends Node:
	var rtt_ms: int = 0
	var packets: Array = []

	func is_open() -> bool:
		return true

	func send_input(msg: Dictionary) -> void:
		packets.append(msg)
