class_name NetworkHost
extends RefCounted

const SNAP_SEND_HZ := 20.0

var hub  # HubClient reference
var world  # GameWorld reference
var _snap_timer := 0.0
var _peer_seq: Dictionary = {}
var _event_sent_id := 0
var _parked_slots: Dictionary = {}

func _init(hub_ref, world_ref) -> void:
	hub = hub_ref
	world = world_ref

func set_world(w) -> void:
	world = w
	_event_sent_id = 0

func clear() -> void:
	_peer_seq.clear()
	_snap_timer = 0.0
	_event_sent_id = 0
	_parked_slots.clear()

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
	_parked_slots[slot] = true
	if world == null:
		return
	world.human_slots.erase(slot)
	if slot < 0 or slot >= world.heroes.size():
		return
	world.heroes[slot]["parked"] = true

func on_peer_reclaimed(slot: int, _player_name: String) -> void:
	_parked_slots.erase(slot)
	if world == null:
		return
	world.human_slots[slot] = true
	if slot < 0 or slot >= world.heroes.size():
		return
	world.heroes[slot]["parked"] = false

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

func build_snapshot(full_events: bool = false) -> Dictionary:
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
		"mid_tower": _snap_tower(),
		"effects": _snap_effects(),
		"events": _snap_events(full_events)
	}

func _snap_players() -> Array:
	var arr: Array = []
	for h in world.heroes:
		arr.append(_snap_one_player(h))
	return arr

func _snap_one_player(h: Dictionary) -> Dictionary:
	var d := _player_core(h)
	_player_fill_stats(d, h)
	_player_fill_v2(d, h)
	return d

func _player_core(h: Dictionary) -> Dictionary:
	var slot := int(h["slot"])
	var eq: Dictionary = h.get("equipment", {})
	var pos := Vector2(h["pos"])
	var aim := Vector2(h["aim"])
	var parked: bool = bool(h.get("parked", false)) or _parked_slots.has(slot)
	var name := str(h.get("display_name", str(eq.get("character_name", "P%d" % (slot + 1)))))
	var cpu: bool = (not world.human_slots.has(slot)) and slot != world.local_slot and not parked
	return {
		"slot": slot,
		"name": name,
		"cpu": cpu,
		"parked": parked,
		"x": pos.x, "y": pos.y,
		"aimX": pos.x + aim.x * 100.0,
		"aimY": pos.y + aim.y * 100.0,
		"hp": float(h["hp"]),
		"alive": bool(h["alive"]),
		"weapon": str(eq.get("name", "")),
		"weaponId": str(eq.get("id", "net")),
		"item": "medkit" if int(h.get("medkits", 0)) > 0 else "",
		"kills": int(h["kills"]),
		"animal": int(h.get("animal", slot)),
		"emote": int(h.get("emote", -1)),
		"emoteTime": float(h.get("emote_time", 0.0)),
		"ack": _peer_seq.get(slot, 0),
	}

func _player_fill_stats(d: Dictionary, h: Dictionary) -> void:
	var eq: Dictionary = h.get("equipment", {})
	d["maxHp"] = float(h.get("max_hp", 0.0))
	d["mag"] = int(h.get("mag", 0))
	d["magMax"] = int(eq.get("mag_size", 0))
	d["reloadLeft"] = float(h.get("reload_left", 0.0))
	d["ult"] = float(h.get("ultimate_charge", 0.0))
	d["characterId"] = str(h.get("character_id", ""))
	d["downed"] = bool(h.get("downed", false))
	d["downLeft"] = float(h.get("down_left", 0.0))
	d["deaths"] = int(h.get("deaths", 0))
	d["score"] = float(h.get("score", 0.0))
	d["streak"] = int(h.get("kill_streak", 0))

func _player_fill_v2(d: Dictionary, h: Dictionary) -> void:
	var launch := Vector2(h.get("launch_vel", Vector2.ZERO))
	_put_if(d, "action", str(h.get("action", "")))
	_put_if(d, "stunT", float(h.get("stun_time", 0.0)))
	_put_if(d, "rootT", float(h.get("root_time", 0.0)))
	_put_if(d, "ccT", float(h.get("cc_time", 0.0)))
	_put_if(d, "guardT", float(h.get("guard_time", 0.0)))
	_put_if(d, "armorT", float(h.get("super_armor_time", 0.0)))
	_put_if(d, "spawnT", float(h.get("spawn_protect_time", 0.0)))
	_put_if(d, "launchT", float(h.get("launch_time", 0.0)))
	_put_if(d, "launchVX", launch.x)
	_put_if(d, "launchVY", launch.y)
	_put_if(d, "charging", bool(h.get("charging_skill", false)))
	_put_if(d, "chargeT", float(h.get("charge_time", 0.0)))
	_put_if(d, "heldItem", str(h.get("held_item", "")))
	_put_if(d, "springT", float(h.get("spring_time", 0.0)))
	_put_if(d, "slideT", float(h.get("slide_time", 0.0)))
	_put_if(d, "pullT", float(h.get("pull_time", 0.0)))
	_put_if(d, "pocketT", float(h.get("pocket_time", 0.0)))
	_put_if(d, "dmgOrbT", float(h.get("dmg_orb_time", 0.0)))
	_put_if(d, "downTaken", float(h.get("down_taken", 0.0)))
	_put_if(d, "woolT", float(h.get("wool_time", 0.0)))
	_put_if(d, "woolHp", int(h.get("wool_hp", 0)))
	_put_if(d, "woolMax", int(h.get("wool_max", 0)))
	_put_if(d, "rouT", float(h.get("roulette_time", 0.0)))
	_put_if(d, "rouRank", str(h.get("roulette_rank", "")))
	_put_if(d, "rouPhase", str(h.get("roulette_phase", "")))
	_put_if(d, "rouSpin", _rou_spin(h))
	_put_if(d, "rouLabel", str(h.get("roulette_label", "")))
	_put_if(d, "rlTimed", _snap_rl_timed(h.get("rl_timed", [])))
	_put_if(d, "ultClones", _snap_ult_clones(h.get("ult_clones", [])))

func _rou_spin(h: Dictionary) -> Variant:
	var raw: Variant = h.get("roulette_spin_id", 0)
	if raw is int or raw is float:
		return int(raw)
	var s := str(raw)
	if s.is_valid_int():
		return int(s)
	return s

func _put_if(d: Dictionary, key: String, value: Variant) -> void:
	if _omit_default(value):
		return
	d[key] = value

func _omit_default(value: Variant) -> bool:
	if value is bool:
		return not value
	if value is String:
		return value == ""
	if value is Array:
		return (value as Array).is_empty()
	if value is int:
		return value == 0
	if value is float:
		return is_zero_approx(value)
	return false

func _snap_rl_timed(raw: Variant) -> Array:
	if not raw is Array:
		return []
	var out: Array = []
	for item in raw:
		var entry := _rl_entry(item)
		if entry.is_empty():
			continue
		out.append(entry)
	return out

func _rl_entry(item: Variant) -> Dictionary:
	if not item is Dictionary:
		return {}
	var d := {}
	for key in item:
		_put_num_str(d, str(key), item[key])
	return d

func _put_num_str(d: Dictionary, key: String, v: Variant) -> void:
	if v is String or v is StringName:
		d[key] = str(v)
		return
	if v is int or v is float:
		d[key] = v

func _snap_ult_clones(raw: Variant) -> Array:
	if not raw is Array:
		return []
	var out: Array = []
	for c in raw:
		# 죽은 클론은 싣지 않는다 — 게스트 화면 잔상 방지.
		if c is Dictionary and not bool(c.get("alive", true)):
			continue
		out.append(_clone_xy(c))
	return out

func _clone_xy(c: Variant) -> Dictionary:
	if not c is Dictionary:
		return {"x": 0.0, "y": 0.0}
	var pos := Vector2(c.get("pos", Vector2.ZERO))
	return {"x": pos.x, "y": pos.y}

func _snap_bullets() -> Array:
	var arr: Array = []
	for proj in world.projectiles:
		arr.append(_snap_one_bullet(proj))
	return arr

func _snap_one_bullet(proj: Dictionary) -> Dictionary:
	var pos := Vector2(proj["pos"])
	var vel := Vector2(proj.get("vel", Vector2.ZERO))
	var d := {
		"id": int(proj.get("id", 0)),
		"x": pos.x, "y": pos.y,
		"vx": vel.x, "vy": vel.y,
		"owner": int(proj["owner"]),
		"kind": str(proj.get("kind", "")),
		"radius": float(proj.get("radius", 0.0)),
	}
	if bool(proj.get("arc", false)):
		d["arc"] = true
	if bool(proj.get("heavy", false)):
		d["heavy"] = true
	_put_bullet_src(d, proj)
	return d

func _put_bullet_src(d: Dictionary, proj: Dictionary) -> void:
	var src := str(proj.get("source", "normal"))
	if src == "normal" or src == "":
		return
	d["src"] = src

func _snap_effects() -> Array:
	var arr: Array = []
	var n := mini(world.effects.size(), 48)
	for i in n:
		arr.append(_snap_one_effect(world.effects[i]))
	return arr

func _snap_one_effect(e: Dictionary) -> Dictionary:
	var pos := Vector2(e.get("pos", Vector2.ZERO))
	var dir := Vector2(e.get("direction", Vector2.RIGHT))
	return {
		"k": str(e.get("kind", "")),
		"x": pos.x, "y": pos.y,
		"r": float(e.get("radius", 0.0)),
		"t": float(e.get("time", 0.0)),
		"maxT": float(e.get("max_time", 0.0)),
		"color": _snap_hex(e.get("color", Color.WHITE)),
		"label": str(e.get("label", "")),
		"dx": dir.x, "dy": dir.y,
		"follow": int(e.get("follow_slot", -1)),
	}

func _snap_events(full: bool) -> Array:
	if world.event_log == null:
		return []
	var src: Array = world.event_log.events
	if full:
		return _pack_events(_recent_events(src, 32))
	var pending := _cap_array(_events_after(src, _event_sent_id), 32)
	_note_events_sent(pending)
	return _pack_events(pending)

func _recent_events(src: Array, count: int) -> Array:
	var start := maxi(0, src.size() - count)
	return src.slice(start)

func _events_after(src: Array, after_id: int) -> Array:
	var out: Array = []
	for e in src:
		if int(e.get("event_id", 0)) <= after_id:
			continue
		out.append(e)
	return out

func _cap_array(arr: Array, cap: int) -> Array:
	if arr.size() <= cap:
		return arr
	return arr.slice(0, cap)

func _note_events_sent(pending: Array) -> void:
	if pending.is_empty():
		return
	_event_sent_id = int(pending[pending.size() - 1].get("event_id", _event_sent_id))

func _pack_events(src: Array) -> Array:
	var arr: Array = []
	for e in src:
		arr.append(_pack_one_event(e))
	return arr

func _pack_one_event(e: Dictionary) -> Dictionary:
	return {
		"t": int(e.get("tick", 0)),
		"k": str(e.get("type", "")),
		"a": int(e.get("actor_id", -1)),
		"b": int(e.get("target_id", -1)),
		"d": _snap_event_data(e.get("data", {})),
	}

func _snap_event_data(data: Variant) -> Dictionary:
	if not data is Dictionary:
		return {}
	var out := {}
	for key in data:
		_put_event_val(out, str(key), data[key])
	return out

func _put_event_val(d: Dictionary, key: String, v: Variant) -> void:
	if v is StringName:
		d[key] = str(v)
		return
	if v is String or v is int or v is float or v is bool:
		d[key] = v

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
