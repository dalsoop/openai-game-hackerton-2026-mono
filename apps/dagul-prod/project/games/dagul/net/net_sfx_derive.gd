class_name NetSfxDerive
extends RefCounted
## 스냅 차분 → SFX event_log 파생. net_world 는 호출부만 갖는다.
## 이벤트 이름·payload 는 sfx_events.gd 가 listen 하는 형식과 일치해야 한다.

const SnapContract = preload("res://games/dagul/net/snap_contract.gd")

const FIGHT_COUNTDOWN_LEFT := 60.0

static func _f(d: Dictionary, key: String, fallback: float) -> float:
	var v: Variant = d.get(key)
	if v is float or v is int:
		return float(v)
	return fallback

## start_countdown 양수→0 = combat_started, shrinking false→true = safe_zone_shrink.
static func header_events(w, prev_countdown: float, prev_shrinking: bool) -> void:
	if prev_countdown > 0.0 and w.start_countdown <= 0.0:
		w.event_log.emit(w.tick, &"combat_started", -1, -1, {})
	if not prev_shrinking and w.safe_zone_shrinking:
		w.event_log.emit(w.tick, &"safe_zone_shrink", -1, -1, {})

## 잔여 60초 최초 도달 1회 — countdown SFX + 음악 가속. 발동 여부를 되돌려준다.
static func countdown_event(w, fired: bool) -> bool:
	if fired or w.result != &"playing" or w.start_countdown > 0.0:
		return fired
	if w.MATCH_TIME_LIMIT - w.match_time > FIGHT_COUNTDOWN_LEFT:
		return false
	w.event_log.emit(w.tick, &"fight_countdown", -1, -1, {})
	return true

static func player_events(w, p: Dictionary, old: Dictionary, slot: int) -> void:
	if old.is_empty():
		return
	_reload_event(w, p, old, slot)
	_hit_event(w, p, old, slot)
	_respawn_event(w, p, old, slot)
	_medkit_event(w, p, old, slot)

## reloadLeft 0→양수 = reload_started. equipment 는 무기 이름(SfxCatalog.reload_id_for).
static func _reload_event(w, p: Dictionary, old: Dictionary, slot: int) -> void:
	if float(old.get("reload_left", 0.0)) > 0.0:
		return
	if _f(p, SnapContract.P_RELOAD, 0.0) <= 0.0:
		return
	var weapon := str(p.get(SnapContract.P_WEAPON, ""))
	w.event_log.emit(w.tick, &"reload_started", slot, -1, {"equipment": weapon})

## hp 감소 = hero_hit. 장외면 source safe_zone, 아니면 normal.
static func _hit_event(w, p: Dictionary, old: Dictionary, slot: int) -> void:
	var new_hp := _f(p, SnapContract.P_HP, 0.0)
	if new_hp >= float(old.get("hp", new_hp)):
		return
	var pos := Vector2(_f(p, SnapContract.P_X, 0.0), _f(p, SnapContract.P_Y, 0.0))
	var outside := pos.distance_to(Vector2(w.safe_zone_center)) > float(w.safe_zone_radius)
	var source: StringName = &"safe_zone" if outside else &"normal"
	w.event_log.emit(w.tick, &"hero_hit", -1, slot, {"source": source})

## alive false→true 이고 deaths>0 = hero_respawned (첫 스폰 제외).
static func _respawn_event(w, p: Dictionary, old: Dictionary, slot: int) -> void:
	if bool(old.get("alive", true)):
		return
	if not bool(p.get(SnapContract.P_ALIVE, true)):
		return
	if int(p.get(SnapContract.P_DEATHS, 0)) <= 0:
		return
	w.event_log.emit(w.tick, &"hero_respawned", slot, -1, {})

## item "medkit"→"" 전이 = medkit_used.
static func _medkit_event(w, p: Dictionary, old: Dictionary, slot: int) -> void:
	if int(old.get("medkits", 0)) <= 0:
		return
	if str(p.get(SnapContract.P_ITEM, "")) != "":
		return
	w.event_log.emit(w.tick, &"medkit_used", slot, -1, {})

## loot 항목 소멸 = health_pickup_collected. 수집자는 가장 가까운 생존 슬롯으로 근사.
static func loot_events(w, prev_loot: Array, next_loot: Array) -> void:
	if prev_loot.is_empty():
		return
	var next_ids := {}
	for item in next_loot:
		next_ids[int(item.get("id", -1))] = true
	for item in prev_loot:
		if next_ids.has(int(item.get("id", -1))):
			continue
		var actor := _nearest_alive_slot(w, Vector2(item.get("pos", Vector2.ZERO)))
		w.event_log.emit(w.tick, &"health_pickup_collected", actor, -1, {})

static func _nearest_alive_slot(w, pos: Vector2) -> int:
	var best := -1
	var best_d := INF
	for i in range(w.heroes.size()):
		var hero: Dictionary = w.heroes[i]
		if not bool(hero.get("alive", false)):
			continue
		var d := pos.distance_squared_to(Vector2(hero.get("pos", pos)))
		if d < best_d:
			best_d = d
			best = i
	return best
