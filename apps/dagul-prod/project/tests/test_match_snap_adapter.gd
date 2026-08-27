extends RefCounted
## 스키마형 딕셔너리가 SnapContract 키 스냅이 되는지 확인한다.

const SnapContract := preload("res://games/dagul/net/snap_contract.gd")
const AdapterScript := preload("res://core/net/match_snap_adapter.gd")

func run(t) -> void:
	_builds_contract_snap(t)
	_tick_flush_and_resident(t)
	_schema_rename(t)
	_events_new_seq_only(t)
	_events_map_new_seq_only(t)
	_v2_effects_callout(t)
	_json_string_array_fallback(t)

func _builds_contract_snap(t) -> void:
	var adapter = AdapterScript.new()
	var ok: bool = adapter.ingest(_sample_match(3))
	t.check("첫 tick 은 flush 한다", ok)
	var snap: Dictionary = adapter.snap()
	t.check("tick", int(snap.get(SnapContract.TICK, -1)) == 3)
	t.check("time", is_equal_approx(float(snap.get(SnapContract.TIME, -1)), 1.5))
	t.check("zoneR", is_equal_approx(float(snap.get(SnapContract.ZONE_R, -1)), 400.0))
	t.check("players", snap.has(SnapContract.PLAYERS) and (snap[SnapContract.PLAYERS] as Array).size() == 2)
	var p0: Dictionary = snap[SnapContract.PLAYERS][0]
	t.check("player slot 정렬", int(p0.get(SnapContract.P_SLOT, -1)) == 0)
	t.check("player hp", is_equal_approx(float(p0.get(SnapContract.P_HP, 0)), 120.0))
	t.check("player characterId", str(p0.get(SnapContract.P_CHARACTER_ID, "")) == "a0")
	t.check("bullets", (snap[SnapContract.BULLETS] as Array).size() == 1)
	var b: Dictionary = snap[SnapContract.BULLETS][0]
	t.check("bullet id", int(b.get(SnapContract.B_ID, -1)) == 9)
	t.check("covers", snap.has(SnapContract.COVERS))
	t.check("effects 상주", snap.has(SnapContract.EFFECTS))

func _tick_flush_and_resident(t) -> void:
	var adapter = AdapterScript.new()
	adapter.ingest(_sample_match(1))
	var resident: Dictionary = adapter.snap()
	t.check("같은 tick 은 넘기지 않는다", adapter.ingest(_sample_match(1)) == false)
	t.check("tick 변경만 flush", adapter.ingest(_sample_match(2)) == true)
	resident[SnapContract.ZONE_R] = 1.0
	adapter.ingest(_sample_match(4))
	t.check("상주 Dictionary 부분 갱신", is_equal_approx(float(adapter.snap().get(SnapContract.ZONE_R, 0)), 400.0))
	t.check("상주 동일 참조", adapter.snap() == resident)

func _schema_rename(t) -> void:
	var adapter = AdapterScript.new()
	adapter.ingest(_sample_match(5))
	var snap: Dictionary = adapter.snap()
	var crate: Dictionary = snap[SnapContract.CRATES][0]
	t.check("crates max_hp", is_equal_approx(float(crate.get("max_hp", 0)), 48.0))
	t.check("crate_orbs 키", snap.has(SnapContract.CRATE_ORBS))
	var tower: Dictionary = snap[SnapContract.MID_TOWER]
	t.check("mid_tower max_hp", is_equal_approx(float(tower.get("max_hp", 0)), 200.0))
	var zone: Dictionary = snap[SnapContract.ZONES][0]
	t.check("warning_duration", is_equal_approx(float(zone.get("warning_duration", 0)), 0.8))
	var dep: Dictionary = snap[SnapContract.DEPLOYABLES][0]
	t.check("half_length", is_equal_approx(float(dep.get("half_length", 0)), 12.0))
	var cine: Dictionary = snap[SnapContract.FINISH_CINE]
	t.check("finish_cine hit_age", is_equal_approx(float(cine.get("hit_age", 0)), 0.2))
	t.check("finish_cine mid", cine.has("mid"))
	var ko: Dictionary = snap[SnapContract.KNOCKOUTS][0]
	t.check("knockout max_time", is_equal_approx(float(ko.get("max_time", 0)), 2.15))
	var core: Dictionary = snap[SnapContract.CORES][0]
	t.check("core max_hp", is_equal_approx(float(core.get("max_hp", 0)), 80.0))

func _events_new_seq_only(t) -> void:
	var adapter = AdapterScript.new()
	var first := _sample_match(3)
	first["events"] = [_schema_event(1, 3, 0, "{\"equipment\":\"glock\"}")]
	t.check("첫 seq 는 넘긴다", adapter.ingest(first) == true)
	var evs: Array = adapter.snap()[SnapContract.EVENTS]
	t.check("events 1건", evs.size() == 1)
	var d: Dictionary = (evs[0] as Dictionary).get("data", {})
	t.check("data JSON 파싱", str(d.get("equipment", "")) == "glock")
	t.check("같은 seq 는 넘기지 않는다", adapter.ingest(first) == false)
	t.check("no-op 후 기존 events 유지", (adapter.snap()[SnapContract.EVENTS] as Array).size() == 1)
	var same_tick := _sample_match(3)
	same_tick["events"] = [
		_schema_event(1, 3, 0, "{\"equipment\":\"glock\"}"),
		_schema_event(2, 3, 1, {"equipment": "rifle"}),
	]
	t.check("새 seq 만 넘긴다", adapter.ingest(same_tick) == true)
	var fresh: Array = adapter.snap()[SnapContract.EVENTS]
	t.check("새 seq 1건", fresh.size() == 1)
	t.check("새 seq actor", int((fresh[0] as Dictionary).get("actor", -1)) == 1)
	adapter.reset()
	t.check("reset 후 같은 seq 다시 전달", adapter.ingest(first) == true)
	t.check("reset 전달 1건", (adapter.snap()[SnapContract.EVENTS] as Array).size() == 1)

func _events_map_new_seq_only(t) -> void:
	var adapter = AdapterScript.new()
	var first := _sample_match(3)
	first["events"] = {"1": _schema_event(1, 3, 0, "{\"equipment\":\"glock\"}")}
	t.check("맵 첫 seq 는 넘긴다", adapter.ingest(first) == true)
	t.check("맵 events 1건", (adapter.snap()[SnapContract.EVENTS] as Array).size() == 1)
	var next := _sample_match(4)
	next["events"] = {
		"1": _schema_event(1, 3, 0, "{\"equipment\":\"glock\"}"),
		"2": _schema_event(2, 4, 1, {"equipment": "rifle"}),
	}
	t.check("맵 새 seq 만 넘긴다", adapter.ingest(next) == true)
	var fresh: Array = adapter.snap()[SnapContract.EVENTS]
	t.check("맵 새 seq 1건", fresh.size() == 1)
	t.check("맵 새 seq actor", int((fresh[0] as Dictionary).get("actor", -1)) == 1)

func _v2_effects_callout(t) -> void:
	var adapter = AdapterScript.new()
	var src := _sample_match(8)
	src["streakCallout"] = "TRIPLE"
	src["streakSubtitle"] = "3"
	src["streakCalloutTicks"] = 12
	src["streakCalloutShutdown"] = true
	src["effects"] = [{
		"k": "afterimage", "x": 1.0, "y": 2.0, "r": 105.0, "t": 0.38, "maxT": 0.38,
		"color": "#b9f3ff", "label": "EVADE", "dx": 1.0, "dy": 0.0, "follow": 0,
	}]
	var hero: Dictionary = src["heroes"]["0"]
	hero["weaponId"] = "burst"
	hero["stunTime"] = 0.4
	hero["action"] = "STUNNED"
	hero["pullTime"] = 0.2
	hero["pocketTime"] = 0.3
	hero["mobilityCd"] = 4.2
	hero["equipmentCd"] = 3.1
	hero["hopTime"] = 0.1
	hero["moveSpeed"] = 419.0
	hero["eliminated"] = true
	hero["hud"] = {
		"reloadFlash": 0.55,
		"respawnLeft": 2.4,
		"sprayIndex": 3.2,
		"rouletteDesc": "이번 목숨 동안 공격력이 올라갑니다",
		"hitstunTime": 0.18,
		"comboCaptureTime": 0.4,
	}
	hero["rouletteSpin"] = "tiger"
	hero["timedBuffs"] = [{"id": "turtle", "time": 1}]
	hero["clones"] = [{"x": 3, "y": 4}]
	var bullet: Dictionary = src["bullets"]["9"]
	bullet["radius"] = 6.0
	bullet["arc"] = false
	bullet["heavy"] = true
	bullet["src"] = "equipment"
	t.check("v2 ingest", adapter.ingest(src) == true)
	var snap: Dictionary = adapter.snap()
	var p0: Dictionary = snap[SnapContract.PLAYERS][0]
	t.check("weaponId", str(p0.get(SnapContract.P_WEAPON_ID, "")) == "burst")
	t.check("stunTime", is_equal_approx(float(p0.get(SnapContract.P_STUN_T, 0)), 0.4))
	t.check("action", str(p0.get(SnapContract.P_ACTION, "")) == "STUNNED")
	t.check("pullTime", is_equal_approx(float(p0.get(SnapContract.P_PULL_T, 0)), 0.2))
	t.check("mobilityCd", is_equal_approx(float(p0.get(SnapContract.P_MOB_CD, 0)), 4.2))
	t.check("equipmentCd", is_equal_approx(float(p0.get(SnapContract.P_EQUIP_CD, 0)), 3.1))
	t.check("eliminated", bool(p0.get(SnapContract.P_ELIM, false)) == true)
	t.check("moveSpeed", is_equal_approx(float(p0.get(SnapContract.P_MV_SPD, 0)), 419.0))
	t.check("reloadFlash", is_equal_approx(float(p0.get(SnapContract.P_RELOAD_FLASH, 0)), 0.55))
	t.check("respawnLeft", is_equal_approx(float(p0.get(SnapContract.P_RESPAWN_LEFT, 0)), 2.4))
	t.check("sprayIndex", is_equal_approx(float(p0.get(SnapContract.P_SPRAY_INDEX, 0)), 3.2))
	t.check("rouletteDesc", str(p0.get(SnapContract.P_ROU_DESC, "")) == "이번 목숨 동안 공격력이 올라갑니다")
	t.check("hitstunTime", is_equal_approx(float(p0.get(SnapContract.P_HITSTUN_T, 0)), 0.18))
	t.check("comboCaptureTime", is_equal_approx(float(p0.get(SnapContract.P_COMBO_CAPTURE_T, 0)), 0.4))
	t.check("rouletteSpin 문자열", str(p0.get(SnapContract.P_ROU_SPIN, "")) == "tiger")
	var timed: Variant = p0.get(SnapContract.P_TIMED_BUFFS, [])
	t.check("timedBuffs 배열", timed is Array and (timed as Array).size() == 1)
	var clones: Variant = p0.get(SnapContract.P_CLONES, [])
	t.check("clones 배열", clones is Array and int((clones as Array)[0].get("x", 0)) == 3)
	var fx: Dictionary = (snap[SnapContract.EFFECTS] as Array)[0]
	t.check("effect k", str(fx.get("k", "")) == "afterimage")
	t.check("streakCallout", str(snap.get(SnapContract.STREAK_CALLOUT, "")) == "TRIPLE")
	t.check("streakSubtitle", str(snap.get(SnapContract.STREAK_SUBTITLE, "")) == "3")
	var row: Dictionary = snap[SnapContract.BULLETS][0]
	t.check("bullet radius", is_equal_approx(float(row.get(SnapContract.B_RADIUS, 0)), 6.0))
	t.check("bullet src", str(row.get(SnapContract.B_SRC, "")) == "equipment")
	src["effects"] = []
	src["tick"] = 9
	adapter.ingest(src)
	t.check("빈 effects 로 잔여 정리", (adapter.snap()[SnapContract.EFFECTS] as Array).size() == 0)

func _json_string_array_fallback(t) -> void:
	var adapter = AdapterScript.new()
	var src := _sample_match(4)
	var hero: Dictionary = src["heroes"]["0"]
	hero["timedBuffs"] = "[{\"id\":\"turtle\",\"time\":1}]"
	hero["clones"] = "[{\"x\":9,\"y\":8}]"
	t.check("옛 JSON 문자열도 ingest", adapter.ingest(src) == true)
	var p0: Dictionary = adapter.snap()[SnapContract.PLAYERS][0]
	var timed: Variant = p0.get(SnapContract.P_TIMED_BUFFS, [])
	t.check("문자열 timedBuffs 도 배열", timed is Array and str((timed as Array)[0].get("id", "")) == "turtle")
	var clones: Variant = p0.get(SnapContract.P_CLONES, [])
	t.check("문자열 clones 도 배열", clones is Array and int((clones as Array)[0].get("x", 0)) == 9)

func _schema_event(seq: int, tick: int, actor: int, data: Variant) -> Dictionary:
	return {"seq": seq, "tick": tick, "kind": "gun_fire", "actor": actor, "target": -1, "data": data}

func _sample_match(tick: int) -> Dictionary:
	return {
		"tick": tick,
		"time": 1.5,
		"result": "playing",
		"winner": -1,
		"zoneR": 400.0,
		"shrinking": false,
		"zoneCX": 0.0,
		"zoneCY": 0.0,
		"zonePhase": 1,
		"startCountdown": 0.0,
		"wantedSlot": 0,
		"mode": "full",
		"callout": "",
		"calloutTicks": 0,
		"heroes": {
			"1": _hero(1, "B", 10.0),
			"0": _hero(0, "A", 120.0),
		},
		"bullets": {"9": {"id": 9, "x": 1.0, "y": 2.0, "vx": 3.0, "vy": 4.0, "owner": 0, "kind": "bolt"}},
		"covers": [{"x": 0.0, "y": 0.0, "w": 8.0, "h": 8.0}],
		"crates": [{"id": 1, "x": 2.0, "y": 3.0, "hp": 10.0, "maxHp": 48.0, "alive": true}],
		"crateOrbs": [{"x": 1.0, "y": 1.0, "red": true, "active": true}],
		"loot": [{"id": "l1", "kind": "item", "x": 0.0, "y": 0.0, "n": "킷"}],
		"deployables": [{
			"type": "mine", "owner": 0, "x": 1.0, "y": 2.0, "dx": 1.0, "dy": 0.0,
			"tdx": 1.0, "tdy": 0.0, "halfLength": 12.0, "lifetime": 1.0,
			"maxLifetime": 4.0, "armTime": 0.1, "armDuration": 0.2, "triggered": false,
			"triggerRadius": 16.0, "blastRadius": 32.0, "fuseTime": 0.0, "fuseDuration": 0.4,
		}],
		"zones": [{
			"x": 0.0, "y": 0.0, "radius": 40.0, "owner": 0, "delay": 0.0,
			"warningDuration": 0.8, "color": "#ffffff", "effectKind": "explosion", "label": "",
		}],
		"knockouts": [{"slot": 2, "animal": 2, "x": 5.0, "y": 6.0, "time": 0.5, "maxTime": 2.15}],
		"midTower": {"alive": true, "x": 0.0, "y": 0.0, "hp": 50.0, "maxHp": 200.0, "boing": 0.0},
		"finishCine": {
			"on": true, "atk": 0, "vic": 1, "t": 0.1, "hit": true, "hitAge": 0.2,
			"fly": false, "vicX": 1.0, "vicY": 2.0, "vicSpin": 0.0, "atkX": 3.0,
			"rush": false, "midX": 4.0, "midY": 5.0,
		},
		"cores": [{"slot": 0, "x": 0.0, "y": 0.0, "hp": 40.0, "maxHp": 80.0, "alive": true}],
	}

func _hero(slot: int, pname: String, hp: float) -> Dictionary:
	return {
		"slot": slot, "name": pname, "x": 8.0, "y": 9.0, "aimX": 1.0, "aimY": 0.0,
		"hp": hp, "maxHp": 176.0, "alive": true, "weapon": "권총", "mag": 6, "magMax": 18,
		"reloadLeft": 0.0, "ult": 0.0, "ack": 1, "animal": slot, "characterId": "a%d" % slot,
		"cpu": false, "item": "", "kills": 0, "downed": false, "downLeft": 0.0,
		"deaths": 0, "score": 0.0, "streak": 0, "emote": -1, "emoteTime": 0.0,
	}
