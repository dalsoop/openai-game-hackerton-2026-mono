class_name SnapContract
extends RefCounted
## 호스트 패킹과 게스트 언팩이 같은 키만 쓴다. 필드 추가는 여기 한곳.

const NetSnapParser := preload("res://games/dagul/net/net_snap_parser.gd")
const Catalog := preload("res://core/contract/character_catalog.gd")
const View := preload("res://core/contract/character_view.gd")

const TICK := "tick"
const TIME := "time"
const RESULT := "result"
const WINNER := "winner"
const ZONE_R := "zoneR"
const SHRINKING := "shrinking"
const ZONE_CX := "zoneCX"
const ZONE_CY := "zoneCY"
const ZONE_PHASE := "zonePhase"
const START_COUNTDOWN := "startCountdown"
const WANTED_SLOT := "wantedSlot"
const MODE := "mode"
const PLAYERS := "players"
const BULLETS := "bullets"
const B_ID := "id"
const B_X := "x"
const B_Y := "y"
const B_VX := "vx"
const B_VY := "vy"
const B_OWNER := "owner"
const LOOT := "loot"
const ZONES := "zones"
const DEPLOYABLES := "deployables"
const CORES := "cores"
const COVERS := "covers"
const KNOCKOUTS := "knockouts"
const CRATES := "crates"
const CRATE_ORBS := "crate_orbs"
const MID_TOWER := "mid_tower"
const FINISH_CINE := "finish_cine"
const CALLOUT := "callout"
const CALLOUT_TICKS := "calloutTicks"
const STREAK_CALLOUT := "streakCallout"
const STREAK_SUBTITLE := "streakSubtitle"
const STREAK_CALLOUT_TICKS := "streakCalloutTicks"
const STREAK_CALLOUT_SHUTDOWN := "streakCalloutShutdown"

const P_SLOT := "slot"
const P_NAME := "name"
const P_CPU := "cpu"
const P_PARKED := "parked"
const P_X := "x"
const P_Y := "y"
const P_AIM_X := "aimX"
const P_AIM_Y := "aimY"
const P_HP := "hp"
const P_MAX_HP := "maxHp"
const P_ALIVE := "alive"
const P_WEAPON := "weapon"
const P_MAG := "mag"
const P_MAG_MAX := "magMax"
const P_RELOAD := "reloadLeft"
const P_ULT := "ult"
const P_ANIMAL := "animal"
const P_CHARACTER_ID := "characterId"
const P_ITEM := "item"
const P_KILLS := "kills"
const P_EMOTE := "emote"
const P_EMOTE_TIME := "emoteTime"
const P_ACK := "ack"
const P_DOWNED := "downed"
const P_DOWN_LEFT := "downLeft"
const P_DEATHS := "deaths"
const P_SCORE := "score"
const P_STREAK := "streak"

const PLAYER_KEYS: Array[String] = [
	P_SLOT, P_NAME, P_CPU, P_PARKED, P_X, P_Y, P_AIM_X, P_AIM_Y,
	P_HP, P_MAX_HP, P_ALIVE, P_WEAPON, P_MAG, P_MAG_MAX, P_RELOAD,
	P_ULT, P_ANIMAL, P_CHARACTER_ID, P_ITEM, P_KILLS, P_EMOTE, P_EMOTE_TIME, P_ACK,
	P_DOWNED, P_DOWN_LEFT, P_DEATHS, P_SCORE, P_STREAK,
]

static func pack_header(world) -> Dictionary:
	var center: Vector2 = world.safe_zone_center
	var header := {
		TICK: world.tick,
		TIME: world.match_time,
		RESULT: str(world.result),
		WINNER: world.winner_slot,
		ZONE_R: world.safe_zone_radius,
		SHRINKING: world.safe_zone_shrinking,
		ZONE_CX: center.x,
		ZONE_CY: center.y,
		ZONE_PHASE: world.safe_zone_phase,
		START_COUNTDOWN: world.start_countdown,
		WANTED_SLOT: world.wanted_slot,
		MODE: world.mode,
	}
	header.merge(_pack_fx(world))
	return header

static func pack_world(world) -> Dictionary:
	return {
		ZONES: pack_zones(world.zones),
		DEPLOYABLES: pack_deployables(world.deployables),
		CORES: pack_cores(world.cores),
		COVERS: pack_covers(world.covers),
		KNOCKOUTS: pack_knockouts(world.knockouts),
		CRATES: pack_crates(world.crates),
		CRATE_ORBS: pack_orbs(world.crate_orbs),
		MID_TOWER: pack_mid_tower(world.mid_tower),
	}

static func pack(world) -> Dictionary:
	var snap := pack_header(world)
	snap.merge(pack_world(world))
	return snap

static func _pack_fx(world) -> Dictionary:
	return {
		FINISH_CINE: pack_finish_cine(_opt_dict(world, "finish_cine")),
		CALLOUT: _opt_str(world, "callout"),
		CALLOUT_TICKS: _opt_int(world, "callout_ticks"),
		STREAK_CALLOUT: _opt_str(world, "streak_callout"),
		STREAK_SUBTITLE: _opt_str(world, "streak_subtitle"),
		STREAK_CALLOUT_TICKS: _opt_int(world, "streak_callout_ticks"),
		STREAK_CALLOUT_SHUTDOWN: _opt_bool(world, "streak_callout_shutdown"),
	}

static func pack_player(h: Dictionary, cpu: bool, ack: int) -> Dictionary:
	var pos := Vector2(h["pos"])
	var aim := Vector2(h.get("aim", Vector2.RIGHT))
	var slot := int(h["slot"])
	var eq: Dictionary = h.get("equipment", {})
	var name := str(h.get("display_name", str(eq.get("character_name", "P%d" % (slot + 1)))))
	return {
		P_SLOT: slot,
		P_NAME: name,
		P_CPU: cpu,
		P_PARKED: bool(h.get("parked", false)),
		P_X: pos.x, P_Y: pos.y,
		P_AIM_X: pos.x + aim.x * 100.0,
		P_AIM_Y: pos.y + aim.y * 100.0,
		P_HP: float(h["hp"]),
		P_MAX_HP: float(h.get("max_hp", 100.0)),
		P_ALIVE: bool(h["alive"]),
		P_WEAPON: str(eq.get("name", "")),
		P_MAG: int(h.get("mag", 0)),
		P_MAG_MAX: int(eq.get("mag_size", 0)),
		P_RELOAD: float(h.get("reload_left", 0.0)),
		P_ULT: float(h.get("ultimate_charge", 0.0)),
		P_ANIMAL: int(h.get("animal", slot)),
		P_CHARACTER_ID: str(h.get("character_id", "")),
		P_ITEM: "medkit" if int(h.get("medkits", 0)) > 0 else "",
		P_KILLS: int(h["kills"]),
		P_EMOTE: int(h.get("emote", -1)),
		P_EMOTE_TIME: float(h.get("emote_time", 0.0)),
		P_ACK: ack,
		P_DOWNED: bool(h.get("downed", false)),
		P_DOWN_LEFT: float(h.get("down_left", 0.0)),
		P_DEATHS: int(h.get("deaths", 0)),
		P_SCORE: float(h.get("score", 0.0)),
		P_STREAK: int(h.get("kill_streak", 0)),
	}

## snap_hz 는 스냅 간격의 역수(초당 스냅 수). 상수 Hz가 아니라 틱 차이에서 유도한다.
static func unpack_player(p: Dictionary, old: Dictionary, slot: int, snap_hz: float) -> Dictionary:
	var pos := Vector2(_f(p, P_X, 0.0), _f(p, P_Y, 0.0))
	var old_pos: Vector2 = old.get("pos", pos)
	var aim_point := Vector2(_f(p, P_AIM_X, pos.x + 1.0), _f(p, P_AIM_Y, pos.y))
	var aim: Vector2 = old.get("aim", Vector2.RIGHT)
	if pos.distance_squared_to(aim_point) > 1.0:
		aim = pos.direction_to(aim_point)
	var player_name := str(p.get(P_NAME, "P%d" % (slot + 1)))
	var hero := _player_view_defaults()
	hero["slot"] = int(p.get(P_SLOT, slot))
	hero["alive"] = bool(p.get(P_ALIVE, true))
	hero["eliminated"] = not bool(hero["alive"])
	hero["pos"] = pos
	hero["vel"] = (pos - old_pos) * snap_hz
	hero["aim"] = aim
	_apply_player_vitals(hero, p, player_name, slot)
	return hero

static func _apply_player_vitals(hero: Dictionary, p: Dictionary, player_name: String, slot: int) -> void:
	hero["hp"] = _f(p, P_HP, 0.0)
	hero["max_hp"] = _f(p, P_MAX_HP, 100.0)
	hero["mag"] = int(p.get(P_MAG, 0))
	hero["reload_left"] = _f(p, P_RELOAD, 0.0)
	hero["ultimate_charge"] = _f(p, P_ULT, 0.0)
	hero["animal"] = int(p.get(P_ANIMAL, -1))
	var character_id := str(p.get(P_CHARACTER_ID, ""))
	if character_id == "":
		character_id = Catalog.id_for_bind(Catalog.bind_key(), int(hero["animal"]))
	if character_id != "":
		View.apply_id(hero, character_id)
	hero["kills"] = int(p.get(P_KILLS, 0))
	hero["equipment"] = NetSnapParser.make_equipment(str(p.get(P_WEAPON, "")), player_name, int(p.get(P_MAG_MAX, 0)))
	hero["display_name"] = player_name
	hero["cpu"] = bool(p.get(P_CPU, false))
	hero["parked"] = bool(p.get(P_PARKED, false))
	hero["medkits"] = 1 if str(p.get(P_ITEM, "")) != "" else 0
	hero["emote"] = int(p.get(P_EMOTE, -1))
	hero["emote_time"] = _f(p, P_EMOTE_TIME, 0.0)
	hero["downed"] = bool(p.get(P_DOWNED, false))
	hero["down_left"] = _f(p, P_DOWN_LEFT, 0.0)
	hero["deaths"] = int(p.get(P_DEATHS, 0))
	hero["score"] = _f(p, P_SCORE, 0.0)
	hero["kill_streak"] = int(p.get(P_STREAK, 0))

static func _player_view_defaults() -> Dictionary:
	return {
		"deaths": 0, "score": 0.0, "eliminations": 0,
		"damage_dealt": 0.0, "core_damage": 0.0,
		"ultimates": 0, "equipment_hits": 0,
		"mobility_cd": 0.0,
		"cc_time": 0.0, "stun_time": 0.0, "root_time": 0.0,
		"guard_time": 0.0, "super_armor_time": 0.0,
		"charging_skill": false, "charge_time": 0.0,
		"emote": -1, "emote_time": 0.0,
		"kill_streak": 0, "best_kill_streak": 0,
		"launch_trail": [], "launch_trail_fade": 0.0,
		"launch_time": 0.0, "launch_vel": Vector2.ZERO,
		"action": &"READY",
	}

static func apply_header(dst, snap: Dictionary) -> void:
	dst.tick = int(snap.get(TICK, dst.tick))
	dst.match_time = _f(snap, TIME, dst.match_time)
	dst.winner_slot = int(snap.get(WINNER, dst.winner_slot))
	dst.safe_zone_radius = _f(snap, ZONE_R, dst.safe_zone_radius)
	dst.safe_zone_shrinking = bool(snap.get(SHRINKING, dst.safe_zone_shrinking))
	if snap.has(ZONE_CX) and snap.has(ZONE_CY):
		dst.safe_zone_center = Vector2(_f(snap, ZONE_CX, 0.0), _f(snap, ZONE_CY, 0.0))
	if snap.has(ZONE_PHASE):
		dst.safe_zone_phase = int(snap[ZONE_PHASE])
	if snap.has(START_COUNTDOWN):
		dst.start_countdown = _f(snap, START_COUNTDOWN, 0.0)
	if snap.has(WANTED_SLOT):
		dst.wanted_slot = int(snap[WANTED_SLOT])
	if snap.has(MODE):
		dst.mode = str(snap[MODE])
	if snap.has(FINISH_CINE):
		dst.finish_cine = unpack_finish_cine(snap.get(FINISH_CINE))
	_apply_callouts(dst, snap)

static func apply_world(dst, snap: Dictionary) -> void:
	dst.zones = NetSnapParser.parse_zones(snap)
	dst.deployables = NetSnapParser.parse_deployables(snap)
	dst.cores = NetSnapParser.parse_cores(snap)
	dst.covers = NetSnapParser.parse_covers(snap)
	dst.knockouts = NetSnapParser.parse_knockouts(snap)
	dst.crates = NetSnapParser.parse_crates(snap)
	dst.crate_orbs = NetSnapParser.parse_crate_orbs(snap)
	_apply_mid_tower(dst, snap)

static func apply(dst, snap: Dictionary) -> void:
	apply_header(dst, snap)
	apply_world(dst, snap)

static func _apply_mid_tower(dst, snap: Dictionary) -> void:
	if not snap.has(MID_TOWER):
		return
	var raw: Variant = snap[MID_TOWER]
	if typeof(raw) == TYPE_DICTIONARY and (raw as Dictionary).is_empty():
		dst.mid_tower = {}
		return
	dst.mid_tower = NetSnapParser.parse_mid_tower(snap)

static func pack_finish_cine(cine: Dictionary) -> Dictionary:
	if cine.is_empty() or not bool(cine.get("on", false)):
		return {}
	var mid := _cine_mid(cine)
	return {
		"on": true,
		"atk": int(cine.get("atk", 0)),
		"vic": int(cine.get("vic", -1)),
		"t": _f(cine, "t", 0.0),
		"hit": bool(cine.get("hit", false)),
		"hit_age": _f(cine, "hit_age", 0.0),
		"fly": _f(cine, "fly", 0.0),
		"vic_x": _f(cine, "vic_x", 0.0),
		"vic_y": _f(cine, "vic_y", 0.0),
		"vic_spin": _f(cine, "vic_spin", 0.0),
		"atk_x": _f(cine, "atk_x", 0.0),
		"rush": bool(cine.get("rush", false)),
		"mid": {"x": mid.x, "y": mid.y},
	}

static func unpack_finish_cine(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var cine: Dictionary = raw
	if cine.is_empty() or not bool(cine.get("on", false)):
		return {}
	return {
		"on": true,
		"atk": int(cine.get("atk", 0)),
		"vic": int(cine.get("vic", -1)),
		"t": _f(cine, "t", 0.0),
		"hit": bool(cine.get("hit", false)),
		"hit_age": _f(cine, "hit_age", 0.0),
		"fly": _f(cine, "fly", 0.0),
		"vic_x": _f(cine, "vic_x", 0.0),
		"vic_y": _f(cine, "vic_y", 0.0),
		"vic_spin": _f(cine, "vic_spin", 0.0),
		"atk_x": _f(cine, "atk_x", 0.0),
		"rush": bool(cine.get("rush", false)),
		"mid": _cine_mid(cine),
	}

static func _apply_callouts(dst, snap: Dictionary) -> void:
	if snap.has(CALLOUT):
		dst.callout = str(snap.get(CALLOUT, ""))
	if snap.has(CALLOUT_TICKS) or snap.has("callout_ticks"):
		dst.callout_ticks = int(snap.get(CALLOUT_TICKS, snap.get("callout_ticks", 0)))
	if snap.has(STREAK_CALLOUT) or snap.has("streak_callout"):
		dst.streak_callout = str(snap.get(STREAK_CALLOUT, snap.get("streak_callout", "")))
	if snap.has(STREAK_SUBTITLE) or snap.has("streak_subtitle"):
		dst.streak_subtitle = str(snap.get(STREAK_SUBTITLE, snap.get("streak_subtitle", "")))
	if snap.has(STREAK_CALLOUT_TICKS) or snap.has("streak_callout_ticks"):
		dst.streak_callout_ticks = int(snap.get(STREAK_CALLOUT_TICKS, snap.get("streak_callout_ticks", 0)))
	if snap.has(STREAK_CALLOUT_SHUTDOWN) or snap.has("streak_callout_shutdown"):
		dst.streak_callout_shutdown = bool(snap.get(STREAK_CALLOUT_SHUTDOWN, snap.get("streak_callout_shutdown", false)))

static func _cine_mid(cine: Dictionary) -> Vector2:
	if cine.has("mid"):
		var mid: Variant = cine["mid"]
		if mid is Vector2:
			return mid
		if mid is Dictionary:
			return Vector2(_f(mid, "x", 0.0), _f(mid, "y", 0.0))
	return Vector2(_f(cine, "mx", 0.0), _f(cine, "my", 0.0))

static func _opt_dict(world, name: String) -> Dictionary:
	var v: Variant = world.get(name)
	return v if v is Dictionary else {}

static func _opt_str(world, name: String) -> String:
	var v: Variant = world.get(name)
	return str(v) if typeof(v) == TYPE_STRING else ""

static func _opt_int(world, name: String) -> int:
	var v: Variant = world.get(name)
	return int(v) if v is int or v is float else 0

static func _opt_bool(world, name: String) -> bool:
	var v: Variant = world.get(name)
	return v if v is bool else false

static func _f(d: Dictionary, key: String, fallback: float) -> float:
	return NetSnapParser._f(d, key, fallback)

static func pack_zones(zones: Array) -> Array:
	var arr: Array = []
	for z in zones:
		var zp := Vector2(z["pos"])
		arr.append({
			"x": zp.x, "y": zp.y, "radius": float(z["radius"]), "owner": int(z["owner"]),
			"delay": float(z.get("delay", 0)), "warning_duration": float(z.get("warning_duration", 0)),
			"color": _snap_hex(z.get("color", Color.WHITE)),
			"effect_kind": str(z.get("effect_kind", "explosion")), "label": str(z.get("label", "")),
		})
	return arr

static func pack_deployables(items: Array) -> Array:
	var arr: Array = []
	for d in items:
		arr.append(_pack_deployable(d))
	return arr

static func _pack_deployable(d: Dictionary) -> Dictionary:
	var dp := Vector2(d["pos"])
	var dd := Vector2(d.get("direction", Vector2.RIGHT))
	var td := Vector2(d.get("travel_direction", Vector2.RIGHT))
	return {
		"type": str(d.get("type", "mine")), "owner": int(d["owner"]),
		"x": dp.x, "y": dp.y, "dx": dd.x, "dy": dd.y, "tdx": td.x, "tdy": td.y,
		"half_length": float(d.get("half_length", 0)),
		"lifetime": float(d.get("lifetime", 0)), "max_lifetime": float(d.get("max_lifetime", 0)),
		"arm_time": float(d.get("arm_time", 0)), "arm_duration": float(d.get("arm_duration", 0)),
		"triggered": bool(d.get("triggered", false)),
		"trigger_radius": float(d.get("trigger_radius", 0)),
		"blast_radius": float(d.get("blast_radius", 0)),
		"fuse_time": float(d.get("fuse_time", 0)), "fuse_duration": float(d.get("fuse_duration", 0)),
	}

static func pack_cores(cores: Array) -> Array:
	var arr: Array = []
	for c in cores:
		var cp := Vector2(c["pos"])
		arr.append({
			"slot": int(c["slot"]), "x": cp.x, "y": cp.y,
			"hp": float(c.get("hp", 0)), "max_hp": float(c.get("max_hp", 1)),
			"alive": bool(c.get("alive", true)),
		})
	return arr

static func pack_covers(covers: Array) -> Array:
	var arr: Array = []
	for cv in covers:
		var rect: Rect2 = cv["rect"]
		arr.append({"x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y})
	return arr

static func pack_knockouts(knockouts: Array) -> Array:
	var arr: Array = []
	for ko in knockouts:
		var kp := Vector2(ko["pos"])
		arr.append({
			"slot": int(ko["slot"]), "x": kp.x, "y": kp.y,
			"time": float(ko["time"]), "max_time": float(ko.get("max_time", 2.15)),
		})
	return arr

static func pack_crates(crates: Array) -> Array:
	var arr: Array = []
	for cr in crates:
		var crp := Vector2(cr["pos"])
		arr.append({
			"id": int(cr.get("id", 0)), "x": crp.x, "y": crp.y,
			"hp": float(cr.get("hp", 0)), "max_hp": float(cr.get("max_hp", 48)),
			"alive": bool(cr.get("alive", false)),
		})
	return arr

static func pack_orbs(orbs: Array) -> Array:
	var arr: Array = []
	for orb in orbs:
		var op := Vector2(orb["pos"])
		arr.append({
			"x": op.x, "y": op.y,
			"red": bool(orb.get("red", true)), "active": bool(orb.get("active", true)),
		})
	return arr

static func pack_mid_tower(tower: Dictionary) -> Dictionary:
	if tower.is_empty():
		return {}
	var tp := Vector2(tower.get("pos", Vector2.ZERO))
	return {
		"alive": bool(tower.get("alive", false)),
		"x": tp.x, "y": tp.y,
		"hp": float(tower.get("hp", 0)),
		"max_hp": float(tower.get("max_hp", 1)),
		"boing": float(tower.get("boing", 0)),
	}

static func _snap_hex(c: Variant) -> String:
	if c is Color:
		return "#" + (c as Color).to_html(false)
	var s := str(c)
	return s if s.begins_with("#") else "#ffffff"
