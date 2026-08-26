class_name NetSnapParser
extends RefCounted

static func _f(d: Dictionary, key: String, fallback: float) -> float:
	var v = d.get(key, fallback)
	if typeof(v) == TYPE_STRING:
		return float(v) if v != "" else fallback
	return float(v)

static func _snap_vec(d: Dictionary) -> Vector2:
	return Vector2(_f(d, "x", 0.0), _f(d, "y", 0.0))

static func _snap_color(v: Variant, fallback: Color = Color.WHITE) -> Color:
	if typeof(v) == TYPE_STRING and str(v) != "":
		return Color(str(v))
	if typeof(v) == TYPE_COLOR:
		return v
	return fallback

static func parse_zones(snap: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw in snap.get("zones", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var z: Dictionary = raw
		result.append({
			"pos": _snap_vec(z),
			"radius": _f(z, "radius", 40.0),
			"owner": int(z.get("owner", 0)),
			"delay": _f(z, "delay", 0.0),
			"warning_duration": _f(z, "warning_duration", 0.0),
			"color": _snap_color(z.get("color", "")),
			"effect_kind": StringName(str(z.get("effect_kind", "explosion"))),
			"label": str(z.get("label", ""))
		})
	return result

static func parse_deployables(snap: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw in snap.get("deployables", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = raw
		result.append({
			"type": StringName(str(d.get("type", "mine"))),
			"owner": int(d.get("owner", 0)),
			"pos": _snap_vec(d),
			"direction": Vector2(_f(d, "dx", 1.0), _f(d, "dy", 0.0)),
			"travel_direction": Vector2(_f(d, "tdx", 1.0), _f(d, "tdy", 0.0)),
			"half_length": _f(d, "half_length", 0.0),
			"lifetime": _f(d, "lifetime", 0.0),
			"max_lifetime": _f(d, "max_lifetime", 1.0),
			"arm_time": _f(d, "arm_time", 0.0),
			"arm_duration": _f(d, "arm_duration", 0.0),
			"triggered": bool(d.get("triggered", false)),
			"trigger_radius": _f(d, "trigger_radius", 0.0),
			"blast_radius": _f(d, "blast_radius", 0.0),
			"fuse_time": _f(d, "fuse_time", 0.0),
			"fuse_duration": _f(d, "fuse_duration", 0.0)
		})
	return result

static func parse_cores(snap: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw in snap.get("cores", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var c: Dictionary = raw
		result.append({
			"slot": int(c.get("slot", result.size())),
			"pos": _snap_vec(c),
			"hp": _f(c, "hp", 0.0),
			"max_hp": _f(c, "max_hp", 1.0),
			"alive": bool(c.get("alive", true))
		})
	return result

static func parse_covers(snap: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw in snap.get("covers", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var cv: Dictionary = raw
		result.append({
			"rect": Rect2(_f(cv, "x", 0.0), _f(cv, "y", 0.0), _f(cv, "w", 0.0), _f(cv, "h", 0.0))
		})
	return result

static func parse_knockouts(snap: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw in snap.get("knockouts", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var ko: Dictionary = raw
		result.append({
			"slot": int(ko.get("slot", -1)),
			"pos": _snap_vec(ko),
			"time": _f(ko, "time", 0.0),
			"max_time": _f(ko, "max_time", 2.15),
			"trail": []
		})
	return result

static func parse_crates(snap: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw in snap.get("crates", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var cr: Dictionary = raw
		result.append({
			"id": int(cr.get("id", result.size())),
			"pos": _snap_vec(cr),
			"hp": _f(cr, "hp", 0.0),
			"max_hp": _f(cr, "max_hp", 48.0),
			"alive": bool(cr.get("alive", false))
		})
	return result

static func parse_crate_orbs(snap: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw in snap.get("crate_orbs", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var orb: Dictionary = raw
		result.append({
			"pos": _snap_vec(orb),
			"red": bool(orb.get("red", true)),
			"active": bool(orb.get("active", true))
		})
	return result

static func make_equipment(weapon_name: String, player_name: String, mag_size: int = 0) -> Dictionary:
	return {
		"id":"net",
		"name":weapon_name if weapon_name != "" else "권총",
		"character_name":player_name,
		"role":"",
		"special_name":"",
		"ultimate_name":"",
		"badge":"",
		"normal_name":"",
		"skill_name":"",
		"skill_desc":"",
		"ultimate_desc":"",
		"mag_size":mag_size
	}

static func _vel_by_id(bullet_id: int, pos: Vector2, prev_bullets: Array, snap_hz: float) -> Vector2:
	for prev_b in prev_bullets:
		if int(prev_b.get("id", -1)) != bullet_id:
			continue
		return (pos - Vector2(prev_b["pos"])) * snap_hz
	return Vector2.ZERO

static func parse_bullets(list: Array, prev_bullets: Array, snap_hz: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw in list:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var b: Dictionary = raw
		var pos := Vector2(_f(b, "x", 0.0), _f(b, "y", 0.0))
		var packed_vel := Vector2(_f(b, "vx", 0.0), _f(b, "vy", 0.0))
		var bullet_id := int(b.get("id", result.size()))
		var vel := packed_vel
		if vel.length_squared() < 0.01:
			vel = _vel_by_id(bullet_id, pos, prev_bullets, snap_hz)
		result.append({
			"id": bullet_id,
			"pos": pos,
			"vel": vel,
			"owner": int(b.get("owner", 0)),
			"kind": "bolt",
			"source": &"normal",
			"arc": false,
			"radius": 5.0
		})
	return result

static func parse_loot(list: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw in list:
		var drop: Dictionary = raw
		var entry := {
			"active":true,
			"pos":Vector2(_f(drop, "x", 0.0), _f(drop, "y", 0.0)),
			"id":abs(hash(str(drop.get("id", "")))) % 1000,
			"magnet_slot":-1
		}
		if str(drop.get("kind", "")) == "gun":
			entry["gun_name"] = _resolve_loot_gun_name(drop)
		result.append(entry)
	return result

static func _resolve_loot_gun_name(drop: Dictionary) -> String:
	var compact_name := str(drop.get("n", ""))
	if compact_name != "":
		return compact_name
	var weapon: Dictionary = drop.get("weapon", {})
	return str(weapon.get("name", "총"))

static func parse_mid_tower(snap: Dictionary) -> Dictionary:
	if snap.has("mid_tower") and typeof(snap["mid_tower"]) == TYPE_DICTIONARY:
		var tw: Dictionary = snap["mid_tower"]
		return {
			"alive": bool(tw.get("alive", false)),
			"pos": _snap_vec(tw),
			"hp": _f(tw, "hp", 0.0),
			"max_hp": _f(tw, "max_hp", 1.0),
			"boing": _f(tw, "boing", 0.0)
		}
	return {}
