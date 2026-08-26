class_name SnapContract
extends RefCounted
## 호스트 패킹과 게스트 언팩이 같은 키만 쓴다. 필드 추가는 여기 한곳.

const NetSnapParser := preload("res://games/dagul/net/net_snap_parser.gd")

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
const EFFECTS := "effects"
const EVENTS := "events"
const BULLETS := "bullets"
const B_ID := "id"
const B_X := "x"
const B_Y := "y"
const B_VX := "vx"
const B_VY := "vy"
const B_OWNER := "owner"
const B_KIND := "kind"
const B_RADIUS := "radius"
const B_ARC := "arc"
const B_HEAVY := "heavy"
const B_SRC := "src"
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
const P_WEAPON_ID := "weaponId"
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
const P_ACTION := "action"
const P_STUN_T := "stunT"
const P_ROOT_T := "rootT"
const P_CC_T := "ccT"
const P_GUARD_T := "guardT"
const P_ARMOR_T := "armorT"
const P_SPAWN_T := "spawnT"
const P_LAUNCH_T := "launchT"
const P_LAUNCH_VX := "launchVX"
const P_LAUNCH_VY := "launchVY"
const P_CHARGING := "charging"
const P_CHARGE_T := "chargeT"
const P_HELD_ITEM := "heldItem"
const P_SPRING_T := "springT"
const P_SLIDE_T := "slideT"
const P_PULL_T := "pullT"
const P_POCKET_T := "pocketT"
const P_DMG_ORB_T := "dmgOrbT"
const P_DOWN_TAKEN := "downTaken"
const P_WOOL_T := "woolT"
const P_WOOL_HP := "woolHp"
const P_WOOL_MAX := "woolMax"
const P_ROU_T := "rouT"
const P_ROU_RANK := "rouRank"
const P_ROU_PHASE := "rouPhase"
const P_ROU_SPIN := "rouSpin"
const P_ROU_LABEL := "rouLabel"
const P_RL_TIMED := "rlTimed"
const P_ULT_CLONES := "ultClones"

const PLAYER_KEYS: Array[String] = [
	P_SLOT, P_NAME, P_CPU, P_PARKED, P_X, P_Y, P_AIM_X, P_AIM_Y,
	P_HP, P_MAX_HP, P_ALIVE, P_WEAPON, P_WEAPON_ID, P_MAG, P_MAG_MAX, P_RELOAD,
	P_ULT, P_ANIMAL, P_CHARACTER_ID, P_ITEM, P_KILLS, P_EMOTE, P_EMOTE_TIME, P_ACK,
	P_DOWNED, P_DOWN_LEFT, P_DEATHS, P_SCORE, P_STREAK,
]
## omit-default. 0/false/""/빈 배열이면 키를 생략한다.
const PLAYER_KEYS_V2: Array[String] = [
	P_ACTION, P_STUN_T, P_ROOT_T, P_CC_T, P_GUARD_T, P_ARMOR_T, P_SPAWN_T,
	P_LAUNCH_T, P_LAUNCH_VX, P_LAUNCH_VY, P_CHARGING, P_CHARGE_T,
	P_HELD_ITEM, P_SPRING_T, P_SLIDE_T, P_PULL_T, P_POCKET_T,
	P_DMG_ORB_T, P_DOWN_TAKEN, P_WOOL_T, P_WOOL_HP, P_WOOL_MAX,
	P_ROU_T, P_ROU_RANK, P_ROU_PHASE, P_ROU_SPIN, P_ROU_LABEL,
	P_RL_TIMED, P_ULT_CLONES,
]
const V2_FLOAT_WIRE: Array[String] = [
	P_STUN_T, P_ROOT_T, P_CC_T, P_GUARD_T, P_ARMOR_T, P_SPAWN_T,
	P_LAUNCH_T, P_CHARGE_T, P_SPRING_T, P_SLIDE_T, P_PULL_T, P_POCKET_T,
	P_DMG_ORB_T, P_DOWN_TAKEN, P_WOOL_T, P_ROU_T,
]
const V2_FLOAT_SIM: Array[String] = [
	"stun_time", "root_time", "cc_time", "guard_time", "super_armor_time", "spawn_protect_time",
	"launch_time", "charge_time", "spring_time", "slide_time", "pull_time", "pocket_time",
	"dmg_orb_time", "down_taken", "wool_time", "roulette_time",
]
const V2_INT_WIRE: Array[String] = [P_WOOL_HP, P_WOOL_MAX, P_ROU_SPIN]
const V2_INT_SIM: Array[String] = ["wool_hp", "wool_max", "roulette_spin_id"]
const V2_STR_WIRE: Array[String] = [P_ACTION, P_HELD_ITEM, P_ROU_RANK, P_ROU_PHASE, P_ROU_LABEL]
const V2_STR_SIM: Array[String] = ["action", "held_item", "roulette_rank", "roulette_phase", "roulette_label"]

static func pack_player(h: Dictionary, cpu: bool, ack: int) -> Dictionary:
	return _codec().pack_player(h, cpu, ack)

## snap_hz 는 스냅 간격의 역수(초당 스냅 수). 상수 Hz가 아니라 틱 차이에서 유도한다.
static func unpack_player(p: Dictionary, old: Dictionary, slot: int, snap_hz: float) -> Dictionary:
	return _codec().unpack_player(p, old, slot, snap_hz)

## 코덱은 지연 load — preload 순환(코덱→계약 키 참조)을 피한다.
static func _codec() -> GDScript:
	return load("res://games/dagul/net/snap_player_codec.gd")

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
