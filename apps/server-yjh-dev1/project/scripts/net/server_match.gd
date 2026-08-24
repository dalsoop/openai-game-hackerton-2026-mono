class_name ServerMatch
extends RefCounted

const WorldScript = preload("res://scripts/sim/game_world.gd")
const NetworkHostScript = preload("res://scripts/net/network_host.gd")
const ReplayRecorderScript = preload("res://scripts/net/replay_recorder.gd")
const LagCompensatorScript = preload("res://scripts/net/lag_compensator.gd")
const FIXED_DT := 1.0 / 60.0
const SNAP_HZ := 20.0

var server: Node
var world: GangGameWorld
var snap_builder: NetworkHost
var recorder: ReplayRecorder
var lag_comp: LagCompensator
var finished := false

var _peer_slot: Dictionary = {}
var _slot_peer: Dictionary = {}
var _token_slot: Dictionary = {}
var _disconnected_at: Dictionary = {}
var _spectators: Array[int] = []
var _snap_timer := 0.0
var _input_buffer: Dictionary = {}
var _prev_snap: Dictionary = {}
var _needs_full_snap: Dictionary = {}

func _init(server_node: Node, players: Array, mode: String, seed_val: int) -> void:
	server = server_node
	world = WorldScript.new(seed_val)
	world.set_mode(mode)
	world.is_net = true
	world.reset()
	snap_builder = NetworkHostScript.new(null, world)
	recorder = ReplayRecorderScript.new()
	lag_comp = LagCompensatorScript.new()
	recorder.start(seed_val, mode, players)
	for p in players:
		var slot := int(p.get("slot", -1))
		var peer_id := int(p.get("peer_id", -1))
		var token := str(p.get("resume_token", ""))
		if slot < 0:
			continue
		world.human_slots[slot] = true
		if slot < world.heroes.size():
			world.heroes[slot]["display_name"] = str(p.get("name", ""))
		if peer_id > 0:
			_peer_slot[peer_id] = slot
			_slot_peer[slot] = peer_id
		if token.length() == 32:
			_token_slot[token] = slot

func tick() -> void:
	if finished:
		return
	_apply_inputs()
	var command := {}
	world.step_tick(command, FIXED_DT)
	lag_comp.record_tick(world.tick, world.heroes)
	_check_disconnection_timeouts()
	if world.result != &"playing":
		finished = true
		recorder.stop()
		recorder.save_to_file()
	_snap_timer += FIXED_DT
	if _snap_timer >= 1.0 / SNAP_HZ:
		_snap_timer -= 1.0 / SNAP_HZ
		_broadcast_snapshot()

func _apply_inputs() -> void:
	for slot in _input_buffer:
		var input_data: Dictionary = _input_buffer[slot]
		recorder.record_input(world.tick, slot, input_data)
		world.peer_commands[slot] = input_data
	_input_buffer.clear()

func on_peer_input(peer_id: int, input_data: Dictionary) -> void:
	var slot = _peer_slot.get(peer_id, -1)
	if slot < 0:
		return
	if not _validate_input(slot, input_data):
		return
	_input_buffer[slot] = input_data

func on_peer_disconnected(peer_id: int) -> void:
	_spectators.erase(peer_id)
	var slot = _peer_slot.get(peer_id, -1)
	if slot < 0:
		return
	_peer_slot.erase(peer_id)
	_slot_peer.erase(slot)
	world.human_slots.erase(slot)
	_disconnected_at[slot] = Time.get_ticks_msec()

func add_spectator(peer_id: int) -> void:
	if peer_id not in _spectators:
		_spectators.append(peer_id)
		_send_snapshot_to(peer_id, _build_full_snapshot())

func try_resume(peer_id: int, token: String) -> bool:
	var slot = _token_slot.get(token, -1)
	if slot < 0:
		return false
	_peer_slot[peer_id] = slot
	_slot_peer[slot] = peer_id
	world.human_slots[slot] = true
	_disconnected_at.erase(slot)
	_needs_full_snap[peer_id] = true
	return true

func final_standings() -> Array:
	if world == null:
		return []
	return world.final_standings()

func _broadcast_snapshot() -> void:
	var full_snap := snap_builder.build_snapshot()
	for peer_id in _peer_slot:
		if _needs_full_snap.has(peer_id):
			_send_snapshot_to(peer_id, full_snap)
			_needs_full_snap.erase(peer_id)
		else:
			var delta = _build_delta(full_snap)
			_send_snapshot_to(peer_id, delta)
	for peer_id in _spectators:
		_send_snapshot_to(peer_id, full_snap)
	_prev_snap = full_snap

func _build_full_snapshot() -> Dictionary:
	return snap_builder.build_snapshot()

func _build_delta(current: Dictionary) -> Dictionary:
	if _prev_snap.is_empty():
		return current
	var delta := {"tick": current.get("tick", 0), "delta": true}
	for key in current:
		if key == "tick":
			continue
		if not _prev_snap.has(key) or str(current[key]) != str(_prev_snap[key]):
			delta[key] = current[key]
	return delta

func _send_snapshot_to(peer_id: int, snap: Dictionary) -> void:
	if server == null:
		return
	var mp = server.multiplayer
	if mp == null or mp.multiplayer_peer == null:
		return
	if mp.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	server.rpc_id(peer_id, &"_receive_snapshot", snap)

func _check_disconnection_timeouts() -> void:
	var now := Time.get_ticks_msec()
	for slot in _disconnected_at.keys():
		if now - _disconnected_at[slot] > 30000:
			_disconnected_at.erase(slot)
			for token in _token_slot:
				if _token_slot[token] == slot:
					_token_slot.erase(token)
					break

func _validate_input(_slot: int, input_data: Dictionary) -> bool:
	var mx := float(input_data.get("mx", 0.0))
	var my := float(input_data.get("my", 0.0))
	var move := Vector2(mx, my)
	if move.length() > 1.5:
		return false
	return true
