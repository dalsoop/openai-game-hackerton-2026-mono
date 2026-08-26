class_name SnapContract
extends RefCounted
## 호스트 패킹과 게스트 언팩이 같은 키만 쓴다. 필드 추가는 여기 한곳.

const NetSnapParser := preload("res://games/dagul/net/net_snap_parser.gd")
const PlayMapScript := preload("res://games/dagul/sim/play_map.gd")

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
const LOOT := "loot"
const ZONES := "zones"
const DEPLOYABLES := "deployables"
const CORES := "cores"
const COVERS := "covers"
const KNOCKOUTS := "knockouts"
const CRATES := "crates"
const CRATE_ORBS := "crate_orbs"
const MID_TOWER := "mid_tower"

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
const P_ITEM := "item"
const P_KILLS := "kills"
const P_EMOTE := "emote"
const P_EMOTE_TIME := "emoteTime"
const P_ACK := "ack"

const PLAYER_KEYS: Array[String] = [
	P_SLOT, P_NAME, P_CPU, P_PARKED, P_X, P_Y, P_AIM_X, P_AIM_Y,
	P_HP, P_MAX_HP, P_ALIVE, P_WEAPON, P_MAG, P_MAG_MAX, P_RELOAD,
	P_ULT, P_ANIMAL, P_ITEM, P_KILLS, P_EMOTE, P_EMOTE_TIME, P_ACK,
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
	header.merge(_pack_map(world))
	return header

static func _pack_map(world) -> Dictionary:
	if "play_map" in world and world.play_map != null:
		return world.play_map.to_wire()
	return PlayMapScript.island_2x2().to_wire()

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
		P_ITEM: "medkit" if int(h.get("medkits", 0)) > 0 else "",
		P_KILLS: int(h["kills"]),
		P_EMOTE: int(h.get("emote", -1)),
		P_EMOTE_TIME: float(h.get("emote_time", 0.0)),
		P_ACK: ack,
	}

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
	hero["animal"] = int(p.get(P_ANIMAL, slot))
	hero["kills"] = int(p.get(P_KILLS, 0))
	hero["equipment"] = NetSnapParser.make_equipment(str(p.get(P_WEAPON, "")), player_name, int(p.get(P_MAG_MAX, 0)))
	hero["display_name"] = player_name
	hero["cpu"] = bool(p.get(P_CPU, false))
	hero["parked"] = bool(p.get(P_PARKED, false))
	hero["medkits"] = 1 if str(p.get(P_ITEM, "")) != "" else 0
	hero["emote"] = int(p.get(P_EMOTE, -1))
	hero["emote_time"] = _f(p, P_EMOTE_TIME, 0.0)

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
	if PlayMapScript.has_wire(snap) and "play_map" in dst:
		dst.play_map = PlayMapScript.from_wire(snap)

static func _f(d: Dictionary, key: String, fallback: float) -> float:
	return NetSnapParser._f(d, key, fallback)
