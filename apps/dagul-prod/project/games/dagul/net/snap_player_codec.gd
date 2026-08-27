class_name SnapPlayerCodec
extends RefCounted
## 플레이어 pack/unpack 코덱. 키 정의와 wire↔sim 매핑 표는 SnapContract(정본)에 있다.

const NetSnapParser := preload("res://games/dagul/net/net_snap_parser.gd")
const Catalog := preload("res://core/contract/character_catalog.gd")
const View := preload("res://core/contract/character_view.gd")
const K := preload("res://games/dagul/net/snap_contract.gd")

static func pack_player(h: Dictionary, cpu: bool, ack: int) -> Dictionary:
	var pos := Vector2(h["pos"])
	var aim := Vector2(h.get("aim", Vector2.RIGHT))
	var slot := int(h["slot"])
	var eq: Dictionary = h.get("equipment", {})
	var name := str(h.get("display_name", str(eq.get("character_name", "P%d" % (slot + 1)))))
	var packed := {
		K.P_SLOT: slot,
		K.P_NAME: name,
		K.P_CPU: cpu,
		K.P_PARKED: bool(h.get("parked", false)),
		K.P_X: pos.x, K.P_Y: pos.y,
		K.P_AIM_X: pos.x + aim.x * 100.0,
		K.P_AIM_Y: pos.y + aim.y * 100.0,
		K.P_HP: float(h["hp"]),
		K.P_MAX_HP: float(h.get("max_hp", 100.0)),
		K.P_ALIVE: bool(h["alive"]),
		K.P_WEAPON: str(eq.get("name", "")),
		K.P_WEAPON_ID: str(eq.get("id", "net")),
		K.P_MAG: int(h.get("mag", 0)),
		K.P_MAG_MAX: int(eq.get("mag_size", 0)),
		K.P_RELOAD: float(h.get("reload_left", 0.0)),
		K.P_ULT: float(h.get("ultimate_charge", 0.0)),
		K.P_ANIMAL: int(h.get("animal", slot)),
		K.P_CHARACTER_ID: str(h.get("character_id", "")),
		K.P_ITEM: "medkit" if int(h.get("medkits", 0)) > 0 else "",
		K.P_KILLS: int(h["kills"]),
		K.P_EMOTE: int(h.get("emote", -1)),
		K.P_EMOTE_TIME: float(h.get("emote_time", 0.0)),
		K.P_ACK: ack,
		K.P_DOWNED: bool(h.get("downed", false)),
		K.P_DOWN_LEFT: float(h.get("down_left", 0.0)),
		K.P_DEATHS: int(h.get("deaths", 0)),
		K.P_SCORE: float(h.get("score", 0.0)),
		K.P_STREAK: int(h.get("kill_streak", 0)),
	}
	packed.merge(_pack_player_v2(h))
	return packed

static func _pack_player_v2(h: Dictionary) -> Dictionary:
	var out := {}
	_pack_v2_floats(out, h)
	_pack_v2_ints(out, h)
	_pack_v2_strs(out, h)
	_put_true(out, K.P_CHARGING, bool(h.get("charging_skill", false)))
	_put_true(out, K.P_ELIM, bool(h.get("eliminated", false)))
	var eq: Variant = h.get("equipment", {})
	if eq is Dictionary:
		_put_nonzero_f(out, K.P_MV_SPD, float(eq.get("move_speed", 0.0)))
	var launch := Vector2(h.get("launch_vel", Vector2.ZERO))
	_put_nonzero_f(out, K.P_LAUNCH_VX, launch.x)
	_put_nonzero_f(out, K.P_LAUNCH_VY, launch.y)
	_put_nonempty_a(out, K.P_RL_TIMED, _as_array(h.get("rl_timed", [])))
	_put_nonempty_a(out, K.P_ULT_CLONES, _pack_ult_clones(h.get("ult_clones", [])))
	return out

static func _pack_v2_floats(out: Dictionary, h: Dictionary) -> void:
	for i in K.V2_FLOAT_WIRE.size():
		_put_nonzero_f(out, K.V2_FLOAT_WIRE[i], float(h.get(K.V2_FLOAT_SIM[i], 0.0)))

static func _pack_v2_ints(out: Dictionary, h: Dictionary) -> void:
	for i in K.V2_INT_WIRE.size():
		if K.V2_INT_WIRE[i] == K.P_ROU_SPIN:
			continue
		_put_nonzero_i(out, K.V2_INT_WIRE[i], int(h.get(K.V2_INT_SIM[i], 0)))
	_put_nonempty_s(out, K.P_ROU_SPIN, str(h.get("roulette_spin_id", "")))

static func _pack_v2_strs(out: Dictionary, h: Dictionary) -> void:
	for i in K.V2_STR_WIRE.size():
		_put_nonempty_s(out, K.V2_STR_WIRE[i], str(h.get(K.V2_STR_SIM[i], "")))

## snap_hz 는 스냅 간격의 역수(초당 스냅 수). 상수 Hz가 아니라 틱 차이에서 유도한다.
static func unpack_player(p: Dictionary, old: Dictionary, slot: int, snap_hz: float) -> Dictionary:
	var pos := Vector2(_f(p, K.P_X, 0.0), _f(p, K.P_Y, 0.0))
	var old_pos: Vector2 = old.get("pos", pos)
	var aim_point := Vector2(_f(p, K.P_AIM_X, pos.x + 1.0), _f(p, K.P_AIM_Y, pos.y))
	var aim: Vector2 = old.get("aim", Vector2.RIGHT)
	if pos.distance_squared_to(aim_point) > 1.0:
		aim = pos.direction_to(aim_point)
	var player_name := str(p.get(K.P_NAME, "P%d" % (slot + 1)))
	var hero := _player_view_defaults()
	hero["slot"] = int(p.get(K.P_SLOT, slot))
	hero["alive"] = bool(p.get(K.P_ALIVE, true))
	hero["pos"] = pos
	hero["vel"] = (pos - old_pos) * snap_hz
	hero["aim"] = aim
	_apply_player_vitals(hero, p, player_name, slot)
	return hero

static func _apply_player_vitals(hero: Dictionary, p: Dictionary, player_name: String, slot: int) -> void:
	hero["hp"] = _f(p, K.P_HP, 0.0)
	hero["max_hp"] = _f(p, K.P_MAX_HP, 100.0)
	hero["mag"] = int(p.get(K.P_MAG, 0))
	hero["reload_left"] = _f(p, K.P_RELOAD, 0.0)
	hero["ultimate_charge"] = _f(p, K.P_ULT, 0.0)
	hero["animal"] = int(p.get(K.P_ANIMAL, -1))
	var character_id := str(p.get(K.P_CHARACTER_ID, ""))
	if character_id == "":
		character_id = Catalog.id_for_bind(Catalog.bind_key(), int(hero["animal"]))
	if character_id != "":
		View.apply_id(hero, character_id)
	hero["kills"] = int(p.get(K.P_KILLS, 0))
	hero["equipment"] = NetSnapParser.make_equipment(str(p.get(K.P_WEAPON, "")), player_name, int(p.get(K.P_MAG_MAX, 0)), str(p.get(K.P_WEAPON_ID, "net")))
	hero["display_name"] = player_name
	hero["cpu"] = bool(p.get(K.P_CPU, false))
	hero["parked"] = bool(p.get(K.P_PARKED, false))
	hero["medkits"] = 1 if str(p.get(K.P_ITEM, "")) != "" else 0
	hero["emote"] = int(p.get(K.P_EMOTE, -1))
	hero["emote_time"] = _f(p, K.P_EMOTE_TIME, 0.0)
	hero["downed"] = bool(p.get(K.P_DOWNED, false))
	hero["down_left"] = _f(p, K.P_DOWN_LEFT, 0.0)
	hero["deaths"] = int(p.get(K.P_DEATHS, 0))
	hero["score"] = _f(p, K.P_SCORE, 0.0)
	hero["kill_streak"] = int(p.get(K.P_STREAK, 0))
	_apply_player_v2(hero, p)

static func _apply_player_v2(hero: Dictionary, p: Dictionary) -> void:
	for i in K.V2_FLOAT_WIRE.size():
		hero[K.V2_FLOAT_SIM[i]] = _f(p, K.V2_FLOAT_WIRE[i], 0.0)
	for i in K.V2_INT_WIRE.size():
		if K.V2_INT_WIRE[i] == K.P_ROU_SPIN:
			continue
		hero[K.V2_INT_SIM[i]] = int(p.get(K.V2_INT_WIRE[i], 0))
	for i in K.V2_STR_WIRE.size():
		hero[K.V2_STR_SIM[i]] = str(p.get(K.V2_STR_WIRE[i], ""))
	hero["roulette_spin_id"] = str(p.get(K.P_ROU_SPIN, ""))
	hero["action"] = StringName(str(p.get(K.P_ACTION, "READY")))
	hero["charging_skill"] = bool(p.get(K.P_CHARGING, false))
	hero["launch_vel"] = Vector2(_f(p, K.P_LAUNCH_VX, 0.0), _f(p, K.P_LAUNCH_VY, 0.0))
	hero["rl_timed"] = _as_array(p.get(K.P_RL_TIMED, [])).duplicate(true)
	hero["ult_clones"] = _unpack_ult_clones(p.get(K.P_ULT_CLONES, []))
	_apply_elim_and_speed(hero, p)

static func _player_view_defaults() -> Dictionary:
	return {
		"deaths": 0, "score": 0.0, "eliminations": 0,
		"damage_dealt": 0.0, "core_damage": 0.0,
		"ultimates": 0, "equipment_hits": 0,
		"mobility_cd": 0.0,
		"hop_time": 0.0, "hop_max": 0.0, "hop_height": 0.0,
		"cc_time": 0.0, "stun_time": 0.0, "root_time": 0.0,
		"guard_time": 0.0, "super_armor_time": 0.0,
		"charging_skill": false, "charge_time": 0.0,
		"emote": -1, "emote_time": 0.0,
		"kill_streak": 0, "best_kill_streak": 0,
		"launch_trail": [], "launch_trail_fade": 0.0,
		"launch_time": 0.0, "launch_vel": Vector2.ZERO,
		"action": &"READY",
		"spawn_protect_time": 0.0, "held_item": "",
		"spring_time": 0.0, "slide_time": 0.0, "pull_time": 0.0, "pocket_time": 0.0,
		"dmg_orb_time": 0.0, "down_taken": 0.0,
		"wool_time": 0.0, "wool_hp": 0, "wool_max": 0,
		"roulette_time": 0.0, "roulette_rank": "", "roulette_phase": "",
		"roulette_spin_id": "", "roulette_label": "",
		"rl_timed": [], "ult_clones": [],
	}

static func _apply_elim_and_speed(hero: Dictionary, p: Dictionary) -> void:
	if p.has(K.P_ELIM):
		hero["eliminated"] = bool(p[K.P_ELIM])
	else:
		hero["eliminated"] = not bool(hero.get("alive", true))
	if not p.has(K.P_MV_SPD):
		return
	var spd := _f(p, K.P_MV_SPD, 0.0)
	hero["move_speed"] = spd
	var eq: Variant = hero.get("equipment", {})
	if eq is Dictionary:
		eq["move_speed"] = spd

static func _f(d: Dictionary, key: String, fallback: float) -> float:
	return NetSnapParser._f(d, key, fallback)

static func _as_array(v: Variant) -> Array:
	return v if typeof(v) == TYPE_ARRAY else []

static func _put_nonzero_f(d: Dictionary, key: String, value: float) -> void:
	if is_zero_approx(value):
		return
	d[key] = value

static func _put_nonzero_i(d: Dictionary, key: String, value: int) -> void:
	if value == 0:
		return
	d[key] = value

static func _put_true(d: Dictionary, key: String, value: bool) -> void:
	if not value:
		return
	d[key] = true

static func _put_nonempty_s(d: Dictionary, key: String, value: String) -> void:
	if value == "":
		return
	d[key] = value

static func _put_nonempty_a(d: Dictionary, key: String, value: Array) -> void:
	if value.is_empty():
		return
	d[key] = value.duplicate(true)

static func _pack_ult_clones(raw: Variant) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var c: Dictionary = item
		var pos := Vector2(c.get("pos", Vector2.ZERO))
		out.append({"x": pos.x, "y": pos.y})
	return out

static func _unpack_ult_clones(raw: Variant) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item in raw:
		out.append(_unpack_ult_clone(item))
	return out

static func _unpack_ult_clone(item: Variant) -> Dictionary:
	if typeof(item) != TYPE_DICTIONARY:
		return {"pos": Vector2.ZERO}
	var c: Dictionary = item
	return {"pos": Vector2(_f(c, "x", 0.0), _f(c, "y", 0.0))}
