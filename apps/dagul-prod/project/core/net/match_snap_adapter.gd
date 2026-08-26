class_name MatchSnapAdapter
extends RefCounted
## MatchStateSchema(딕셔너리/스키마) → SnapContract 키의 상주 스냅.
## 매 패치마다 새 Dictionary 를 만들지 않는다. tick 이 바뀔 때만 flush 한다.

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

const PLAYER_COPY := [
	"slot", "name", "cpu", "parked", "x", "y", "aimX", "aimY",
	"hp", "maxHp", "alive", "weapon", "mag", "magMax", "reloadLeft",
	"ult", "animal", "characterId", "item", "kills", "emote", "emoteTime", "ack",
	"downed", "downLeft", "deaths", "score", "streak",
]
const BULLET_COPY := ["id", "x", "y", "vx", "vy", "owner", "kind"]
const COVER_COPY := ["x", "y", "w", "h"]
const LOOT_COPY := ["id", "kind", "x", "y", "n"]
const CRATE_ORB_COPY := ["x", "y", "red", "active"]

var _snap: Dictionary = {}
var _emitted_tick: int = -1
var _last_event_seq: int = 0

func _init() -> void:
	_snap = {
		TICK: 0, TIME: 0.0, RESULT: "playing", WINNER: -1,
		ZONE_R: 0.0, SHRINKING: false, ZONE_CX: 0.0, ZONE_CY: 0.0,
		ZONE_PHASE: 0, START_COUNTDOWN: 0.0, WANTED_SLOT: -1, MODE: "",
		PLAYERS: [], EFFECTS: [], EVENTS: [], BULLETS: [], LOOT: [],
		ZONES: [], DEPLOYABLES: [], CORES: [], COVERS: [], KNOCKOUTS: [],
		CRATES: [], CRATE_ORBS: [], MID_TOWER: {}, FINISH_CINE: {},
		CALLOUT: "", CALLOUT_TICKS: 0,
	}

func snap() -> Dictionary:
	return _snap

func reset() -> void:
	_emitted_tick = -1
	_last_event_seq = 0

func ingest(match: Variant) -> bool:
	var src := _as_dict(match)
	if src.is_empty():
		return false
	_write_header(src)
	if int(_snap.get(TICK, 0)) < _emitted_tick:
		_last_event_seq = 0
	_refill(_snap[PLAYERS], _rows_from_map(src.get("heroes", {}), PLAYER_COPY, "slot"))
	_refill(_snap[BULLETS], _rows_from_map(src.get("bullets", {}), BULLET_COPY, "id"))
	_refill(_snap[COVERS], _rows_from_list(src.get("covers", []), COVER_COPY))
	_refill(_snap[CRATES], _mapped_list(src.get("crates", []), [["maxHp", "max_hp"]], ["id", "x", "y", "hp", "alive"]))
	_refill(_snap[CRATE_ORBS], _rows_from_list(src.get("crateOrbs", []), CRATE_ORB_COPY))
	_refill(_snap[LOOT], _rows_from_list(src.get("loot", []), LOOT_COPY))
	_refill(_snap[DEPLOYABLES], _deployables(src.get("deployables", [])))
	_refill(_snap[ZONES], _zones(src.get("zones", [])))
	_refill(_snap[KNOCKOUTS], _mapped_list(src.get("knockouts", []), [["maxTime", "max_time"]], ["slot", "animal", "x", "y", "time"]))
	_refill(_snap[CORES], _mapped_list(src.get("cores", []), [["maxHp", "max_hp"]], ["slot", "x", "y", "hp", "alive"]))
	_snap[MID_TOWER] = _mid_tower(src.get("midTower", {}))
	_snap[FINISH_CINE] = _finish_cine(src.get("finishCine", {}))
	return _flush_events_and_tick(src)

func _flush_events_and_tick(src: Dictionary) -> bool:
	var tick := int(_snap.get(TICK, -1))
	var fresh := _new_event_rows(src.get("events", []))
	if tick == _emitted_tick and fresh.is_empty():
		return false
	_refill(_snap[EVENTS], fresh)
	_emitted_tick = tick
	return true

func _new_event_rows(raw: Variant) -> Array:
	var rows: Array = []
	if not raw is Array:
		return rows
	for item in raw:
		var src := _as_dict(item)
		var seq := int(src.get("seq", 0))
		if seq <= _last_event_seq:
			continue
		_last_event_seq = seq
		rows.append(_event_row(src))
	return rows

func _event_row(src: Dictionary) -> Dictionary:
	return {
		"t": int(src.get("t", 0)),
		"k": str(src.get("k", "")),
		"a": int(src.get("a", -1)),
		"b": int(src.get("b", -1)),
		"d": _event_data(src.get("d", {})),
	}

func _event_data(raw: Variant) -> Dictionary:
	if raw is Dictionary:
		return raw
	if raw is String:
		var parsed: Variant = JSON.parse_string(raw)
		if parsed is Dictionary:
			return parsed
	return {}

func _write_header(src: Dictionary) -> void:
	_snap[TICK] = int(src.get("tick", 0))
	_snap[TIME] = float(src.get("time", 0.0))
	_snap[RESULT] = str(src.get("result", "playing"))
	_snap[WINNER] = int(src.get("winner", -1))
	_snap[ZONE_R] = float(src.get("zoneR", 0.0))
	_snap[SHRINKING] = bool(src.get("shrinking", false))
	_snap[ZONE_CX] = float(src.get("zoneCX", 0.0))
	_snap[ZONE_CY] = float(src.get("zoneCY", 0.0))
	_snap[ZONE_PHASE] = int(src.get("zonePhase", 0))
	_snap[START_COUNTDOWN] = float(src.get("startCountdown", 0.0))
	_snap[WANTED_SLOT] = int(src.get("wantedSlot", -1))
	_snap[MODE] = str(src.get("mode", ""))
	_snap[CALLOUT] = str(src.get("callout", ""))
	_snap[CALLOUT_TICKS] = int(src.get("calloutTicks", 0))

func _as_dict(v: Variant) -> Dictionary:
	if v is Dictionary:
		return v
	if v != null and typeof(v) == TYPE_OBJECT and v.has_method("to_dictionary"):
		return v.to_dictionary()
	return {}

func _refill(dst: Array, rows: Array) -> void:
	dst.clear()
	for row in rows:
		dst.append(row)

func _rows_from_map(raw: Variant, keys: Array, sort_key: String) -> Array:
	var rows: Array = []
	if raw is Dictionary:
		for k in raw.keys():
			rows.append(_copy_keys(_as_dict(raw[k]), keys))
	elif raw is Array:
		for item in raw:
			rows.append(_copy_keys(_as_dict(item), keys))
	rows.sort_custom(func(a, b): return int(a.get(sort_key, 0)) < int(b.get(sort_key, 0)))
	return rows

func _rows_from_list(raw: Variant, keys: Array) -> Array:
	var rows: Array = []
	if not raw is Array:
		return rows
	for item in raw:
		rows.append(_copy_keys(_as_dict(item), keys))
	return rows

func _copy_keys(src: Dictionary, keys: Array) -> Dictionary:
	var out := {}
	for key in keys:
		if src.has(key):
			out[key] = src[key]
	return out

func _mapped_list(raw: Variant, renames: Array, keep: Array) -> Array:
	var rows: Array = []
	if not raw is Array:
		return rows
	for item in raw:
		rows.append(_rename(_as_dict(item), renames, keep))
	return rows

func _rename(src: Dictionary, renames: Array, keep: Array) -> Dictionary:
	var out := _copy_keys(src, keep)
	for pair in renames:
		var from_key: String = pair[0]
		if src.has(from_key):
			out[pair[1]] = src[from_key]
	return out

func _deployables(raw: Variant) -> Array:
	var renames := [
		["halfLength", "half_length"], ["maxLifetime", "max_lifetime"],
		["armTime", "arm_time"], ["armDuration", "arm_duration"],
		["triggerRadius", "trigger_radius"], ["blastRadius", "blast_radius"],
		["fuseTime", "fuse_time"], ["fuseDuration", "fuse_duration"],
	]
	var keep := ["type", "owner", "x", "y", "dx", "dy", "tdx", "tdy", "lifetime", "triggered"]
	return _mapped_list(raw, renames, keep)

func _zones(raw: Variant) -> Array:
	var renames := [["warningDuration", "warning_duration"], ["effectKind", "effect_kind"]]
	var keep := ["x", "y", "radius", "owner", "delay", "color", "label"]
	return _mapped_list(raw, renames, keep)

func _mid_tower(raw: Variant) -> Dictionary:
	var src := _as_dict(raw)
	if src.is_empty():
		return {}
	return _rename(src, [["maxHp", "max_hp"]], ["alive", "x", "y", "hp", "boing"])

func _finish_cine(raw: Variant) -> Dictionary:
	var src := _as_dict(raw)
	if src.is_empty() or not bool(src.get("on", false)):
		return {}
	var cine := {
		"on": true,
		"atk": int(src.get("atk", -1)),
		"vic": int(src.get("vic", -1)),
		"t": float(src.get("t", 0.0)),
		"hit": bool(src.get("hit", false)),
		"hit_age": float(src.get("hitAge", src.get("hit_age", 0.0))),
		"fly": src.get("fly", 0.0),
		"vic_x": float(src.get("vicX", src.get("vic_x", 0.0))),
		"vic_y": float(src.get("vicY", src.get("vic_y", 0.0))),
		"vic_spin": float(src.get("vicSpin", src.get("vic_spin", 0.0))),
		"atk_x": float(src.get("atkX", src.get("atk_x", 0.0))),
		"rush": bool(src.get("rush", false)),
		"mid": {
			"x": float(src.get("midX", src.get("mx", 0.0))),
			"y": float(src.get("midY", src.get("my", 0.0))),
		},
	}
	return cine
