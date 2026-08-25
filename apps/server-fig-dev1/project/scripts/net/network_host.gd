class_name NetworkHost
extends RefCounted

const SNAP_SEND_HZ := 20.0

var hub  # HubClient reference
var world  # GameWorld reference
var _snap_timer := 0.0
var _peer_seq: Dictionary = {}

func _init(hub_ref, world_ref) -> void:
	hub = hub_ref
	world = world_ref

func set_world(w) -> void:
	world = w

func clear() -> void:
	_peer_seq.clear()
	_snap_timer = 0.0

func tick(dt: float) -> void:
	if world == null or hub == null:
		return
	_snap_timer += dt
	if _snap_timer >= 1.0 / SNAP_SEND_HZ:
		_snap_timer -= 1.0 / SNAP_SEND_HZ
		hub.send_snap(build_snapshot())

func on_peer_input(slot: int, input_data: Dictionary) -> void:
	if world != null:
		world.peer_commands[slot] = input_data
		var seq := int(input_data.get("seq", 0))
		if seq > _peer_seq.get(slot, 0):
			_peer_seq[slot] = seq

func on_peer_parked(slot: int) -> void:
	if world != null and world.human_slots.has(slot):
		world.human_slots.erase(slot)

func on_peer_reclaimed(slot: int, _player_name: String) -> void:
	if world != null:
		world.human_slots[slot] = true

func connect_signals() -> void:
	if hub == null:
		return
	if not hub.peer_input_received.is_connected(on_peer_input):
		hub.peer_input_received.connect(on_peer_input)
	if not hub.peer_parked_received.is_connected(on_peer_parked):
		hub.peer_parked_received.connect(on_peer_parked)
	if not hub.peer_reclaimed_received.is_connected(on_peer_reclaimed):
		hub.peer_reclaimed_received.connect(on_peer_reclaimed)

func disconnect_signals() -> void:
	_peer_seq.clear()
	if hub == null:
		return
	if hub.peer_input_received.is_connected(on_peer_input):
		hub.peer_input_received.disconnect(on_peer_input)
	if hub.peer_parked_received.is_connected(on_peer_parked):
		hub.peer_parked_received.disconnect(on_peer_parked)
	if hub.peer_reclaimed_received.is_connected(on_peer_reclaimed):
		hub.peer_reclaimed_received.disconnect(on_peer_reclaimed)

func get_ack(slot: int) -> int:
	return _peer_seq.get(slot, 0)

# --- Snapshot serialization ---

func _snap_hex(c: Variant) -> String:
	if c is Color:
		return "#" + (c as Color).to_html(false)
	var s := str(c)
	return s if s.begins_with("#") else "#ffffff"

func build_snapshot() -> Dictionary:
	return {
		"tick": world.tick,
		"time": world.match_time,
		"result": str(world.result),
		"winner": world.winner_slot,
		"zoneR": world.safe_zone_radius,
		"shrinking": world.safe_zone_shrinking,
		"zoneCX": Vector2(world.safe_zone_center).x,
		"zoneCY": Vector2(world.safe_zone_center).y,
		"zonePhase": world.safe_zone_phase,
		"startCountdown": world.start_countdown,
		"wantedSlot": world.wanted_slot,
		"mode": world.mode,
		"players": _snap_players(),
		"bullets": _snap_bullets(),
		"loot": _snap_loot(),
		"zones": _snap_zones(),
		"deployables": _snap_deployables(),
		"cores": _snap_cores(),
		"covers": _snap_covers(),
		"knockouts": _snap_knockouts(),
		"crates": _snap_crates(),
		"crate_orbs": _snap_orbs(),
		"mid_tower": _snap_tower()
	}

func _snap_players() -> Array:
	var arr: Array = []
	for h in world.heroes:
		arr.append({
			"slot": int(h["slot"]),
			"name": str(h.get("display_name", str(h.get("equipment", {}).get("character_name", "P%d" % (int(h["slot"]) + 1))))),
			"cpu": not world.human_slots.has(int(h["slot"])) and int(h["slot"]) != world.local_slot,
			"parked": false,
			"x": Vector2(h["pos"]).x, "y": Vector2(h["pos"]).y,
			"aimX": Vector2(h["pos"]).x + Vector2(h["aim"]).x * 100.0,
			"aimY": Vector2(h["pos"]).y + Vector2(h["aim"]).y * 100.0,
			"hp": float(h["hp"]), "alive": bool(h["alive"]),
			"weapon": str(h.get("equipment", {}).get("name", "")),
			"item": "medkit" if int(h.get("medkits", 0)) > 0 else "",
			"kills": int(h["kills"]),
			"ack": _peer_seq.get(int(h["slot"]), 0)
		})
	return arr

func _snap_bullets() -> Array:
	var arr: Array = []
	for proj in world.projectiles:
		arr.append({"x": Vector2(proj["pos"]).x, "y": Vector2(proj["pos"]).y, "owner": int(proj["owner"])})
	return arr

func _snap_loot() -> Array:
	var arr: Array = []
	for pickup in world.health_pickups:
		if not bool(pickup.get("active", false)):
			continue
		arr.append({"id": str(pickup.get("id", "")), "kind": "gun" if pickup.has("gun_name") else "item", "x": Vector2(pickup["pos"]).x, "y": Vector2(pickup["pos"]).y, "n": str(pickup.get("gun_name", ""))})
	return arr

func _snap_zones() -> Array:
	var arr: Array = []
	for z in world.zones:
		var zp := Vector2(z["pos"])
		arr.append({"x": zp.x, "y": zp.y, "radius": float(z["radius"]), "owner": int(z["owner"]), "delay": float(z.get("delay", 0)), "warning_duration": float(z.get("warning_duration", 0)), "color": _snap_hex(z.get("color", Color.WHITE)), "effect_kind": str(z.get("effect_kind", "explosion")), "label": str(z.get("label", ""))})
	return arr

func _snap_deployables() -> Array:
	var arr: Array = []
	for d in world.deployables:
		var dp := Vector2(d["pos"])
		var dd := Vector2(d.get("direction", Vector2.RIGHT))
		var td := Vector2(d.get("travel_direction", Vector2.RIGHT))
		arr.append({"type": str(d.get("type", "mine")), "owner": int(d["owner"]), "x": dp.x, "y": dp.y, "dx": dd.x, "dy": dd.y, "tdx": td.x, "tdy": td.y, "half_length": float(d.get("half_length", 0)), "lifetime": float(d.get("lifetime", 0)), "max_lifetime": float(d.get("max_lifetime", 0)), "arm_time": float(d.get("arm_time", 0)), "arm_duration": float(d.get("arm_duration", 0)), "triggered": bool(d.get("triggered", false)), "trigger_radius": float(d.get("trigger_radius", 0)), "blast_radius": float(d.get("blast_radius", 0)), "fuse_time": float(d.get("fuse_time", 0)), "fuse_duration": float(d.get("fuse_duration", 0))})
	return arr

func _snap_cores() -> Array:
	var arr: Array = []
	for c in world.cores:
		var cp := Vector2(c["pos"])
		arr.append({"slot": int(c["slot"]), "x": cp.x, "y": cp.y, "hp": float(c.get("hp", 0)), "max_hp": float(c.get("max_hp", 1)), "alive": bool(c.get("alive", true))})
	return arr

func _snap_covers() -> Array:
	var arr: Array = []
	for cv in world.covers:
		var rect: Rect2 = cv["rect"]
		arr.append({"x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y})
	return arr

func _snap_knockouts() -> Array:
	var arr: Array = []
	for ko in world.knockouts:
		var kp := Vector2(ko["pos"])
		arr.append({"slot": int(ko["slot"]), "x": kp.x, "y": kp.y, "time": float(ko["time"]), "max_time": float(ko.get("max_time", 2.15))})
	return arr

func _snap_crates() -> Array:
	var arr: Array = []
	for cr in world.crates:
		var crp := Vector2(cr["pos"])
		arr.append({"id": int(cr.get("id", 0)), "x": crp.x, "y": crp.y, "hp": float(cr.get("hp", 0)), "max_hp": float(cr.get("max_hp", 48)), "alive": bool(cr.get("alive", false))})
	return arr

func _snap_orbs() -> Array:
	var arr: Array = []
	for orb in world.crate_orbs:
		var op := Vector2(orb["pos"])
		arr.append({"x": op.x, "y": op.y, "red": bool(orb.get("red", true)), "active": bool(orb.get("active", true))})
	return arr

func _snap_tower() -> Dictionary:
	if world.mid_tower.is_empty():
		return {}
	var tp := Vector2(world.mid_tower.get("pos", Vector2.ZERO))
	return {"alive": bool(world.mid_tower.get("alive", false)), "x": tp.x, "y": tp.y, "hp": float(world.mid_tower.get("hp", 0)), "max_hp": float(world.mid_tower.get("max_hp", 1)), "boing": float(world.mid_tower.get("boing", 0))}
