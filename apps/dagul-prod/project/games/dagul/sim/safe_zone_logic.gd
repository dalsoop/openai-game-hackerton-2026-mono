class_name SafeZoneLogic
extends RefCounted

var w

func _init(world) -> void:
	w = world

func settle_match_visuals() -> void:
	w.projectiles.clear()
	w.zones.clear()
	w.deployables.clear()
	w.ultimate_focus_slot = -1
	w.ultimate_focus_time = 0.0
	for index in range(w.heroes.size()):
		var hero: Dictionary = w.heroes[index]
		hero["vel"] = Vector2.ZERO
		hero["charging_skill"] = false
		hero["charge_time"] = 0.0
		w.heroes[index] = hero

func hero_in_safe_zone(slot: int) -> bool:
	if slot < 0 or slot >= w.heroes.size():
		return true
	return Vector2(w.heroes[slot]["pos"]).distance_to(w.safe_zone_center) <= w.safe_zone_radius

func update_safe_zone(dt: float) -> void:
	if not w.safe_zone_complete:
		w.safe_zone_phase_time += dt
		if w.safe_zone_shrinking:
			_advance_shrink_phase()
		else:
			_advance_wait_phase()
	apply_safe_zone_damage(dt)

func _advance_shrink_phase() -> void:
	var shrink_time = maxf(0.01, float(w.SAFE_ZONE_PHASES[w.safe_zone_phase]["shrink"]))
	var ratio = clampf(w.safe_zone_phase_time / shrink_time, 0.0, 1.0)
	var eased = ratio * ratio * (3.0 - 2.0 * ratio)
	w.safe_zone_radius = lerpf(w.safe_zone_from_radius, w.safe_zone_target_radius, eased)
	if ratio >= 1.0:
		_complete_shrink_phase()

# 수축 완료 — 반지름을 목표값에 맞추고, 다음 대기 단계 또는 최종 고정을 확정한다.
func _complete_shrink_phase() -> void:
	w.safe_zone_radius = w.safe_zone_target_radius
	w.safe_zone_shrinking = false
	w.safe_zone_phase_time = 0.0
	w.safe_zone_phase += 1
	if w.safe_zone_phase >= w.SAFE_ZONE_PHASES.size():
		w.safe_zone_complete = true
		w.safe_zone_phase = w.SAFE_ZONE_PHASES.size() - 1
	else:
		w.safe_zone_target_radius = float(w.SAFE_ZONE_PHASES[w.safe_zone_phase]["radius"])
		w._announce("SAFE ZONE HOLD  %d" % roundi(w.safe_zone_radius), 70)

func _advance_wait_phase() -> void:
	var wait_time = float(w.SAFE_ZONE_PHASES[w.safe_zone_phase]["wait"])
	if w.safe_zone_phase_time >= wait_time:
		w.safe_zone_shrinking = true
		w.safe_zone_phase_time = 0.0
		w.safe_zone_from_radius = w.safe_zone_radius
		w.safe_zone_target_radius = float(w.SAFE_ZONE_PHASES[w.safe_zone_phase]["radius"])
		w._announce("SAFE ZONE SHRINKING", 80)
		w.event_log.emit(w.tick, &"safe_zone_shrink", -1, -1, {"phase":w.safe_zone_phase, "from":w.safe_zone_from_radius, "to":w.safe_zone_target_radius})

func apply_safe_zone_damage(dt: float) -> void:
	w.safe_zone_damage_clock += dt
	var show_tick = false
	if w.safe_zone_damage_clock >= w.SAFE_ZONE_TICK_INTERVAL:
		w.safe_zone_damage_clock -= w.SAFE_ZONE_TICK_INTERVAL
		show_tick = true
	var amount = w.SAFE_ZONE_DAMAGE_PER_SEC * dt
	for slot in range(w.heroes.size()):
		if not bool(w.heroes[slot]["alive"]) or bool(w.heroes[slot]["eliminated"]):
			continue
		if hero_in_safe_zone(slot):
			continue
		if w._hero_in_own_pocket(slot):
			continue
		w._damage_hero_environment(slot, amount, show_tick)
	for crate_i in range(w.crates.size()):
		var cr: Dictionary = w.crates[crate_i]
		if not bool(cr.get("alive", false)):
			continue
		if Vector2(cr["pos"]).distance_to(w.safe_zone_center) <= w.safe_zone_radius:
			continue
		var shown = w.SAFE_ZONE_DAMAGE_PER_SEC * w.SAFE_ZONE_TICK_INTERVAL if show_tick else 0.0
		w._hurt_crate(crate_i, amount, show_tick and shown > 0.4)
		if show_tick:
			w._add_effect(&"hit_spark", Vector2(cr["pos"]), 28.0, 0.16, Color("#ff4f68"), "ZONE")

func hero_hp_ratio(slot: int) -> float:
	if slot < 0 or slot >= w.heroes.size() or bool(w.heroes[slot]["eliminated"]):
		return 0.0
	return clampf(float(w.heroes[slot]["hp"]) / maxf(1.0, float(w.heroes[slot]["max_hp"])), 0.0, 1.0) if bool(w.heroes[slot]["alive"]) else 0.0

func core_hp_ratio(slot: int) -> float:
	if slot < 0 or slot >= w.cores.size() or not bool(w.cores[slot]["alive"]):
		return 0.0
	return clampf(float(w.cores[slot]["hp"]) / maxf(1.0, float(w.cores[slot]["max_hp"])), 0.0, 1.0)

func time_limit_better(candidate: int, current: int) -> bool:
	if current < 0:
		return true
	var candidate_hp = hero_hp_ratio(candidate)
	var current_hp = hero_hp_ratio(current)
	if not is_equal_approx(candidate_hp, current_hp):
		return candidate_hp > current_hp
	if not is_equal_approx(float(w.heroes[candidate]["score"]), float(w.heroes[current]["score"])):
		return float(w.heroes[candidate]["score"]) > float(w.heroes[current]["score"])
	return candidate < current

func declare_winner(slot: int, reason: StringName) -> void:
	w.winner_slot = slot
	w.result_reason = reason
	w.result = &"won" if slot == 0 else &"lost"
	w.decision_hp_ratio = hero_hp_ratio(slot)
	w.decision_core_ratio = core_hp_ratio(slot)
	var winner: Dictionary = w.heroes[slot]
	winner["score"] = float(winner["score"]) + 500.0
	w.heroes[slot] = winner
	w.impact_pos = Vector2(winner["pos"])
	w.impact_ticks = maxi(w.impact_ticks, 26)
	w._add_effect(&"victory", Vector2(winner["pos"]), 210.0, 2.20, Color("#ffd166"), "", Vector2.UP)
	w.event_log.emit(w.tick, &"match_won", slot, -1, {"reason":reason, "hp_ratio":w.decision_hp_ratio, "core_ratio":w.decision_core_ratio, "score":float(winner["score"])})
	settle_match_visuals()

func resolve_time_limit() -> void:
	var best = -1
	for slot in range(w.heroes.size()):
		if bool(w.heroes[slot]["alive"]) and not bool(w.heroes[slot]["eliminated"]) and time_limit_better(slot, best):
			best = slot
	if best < 0:
		w.result = &"draw"
		w.result_reason = &"time_limit_draw"
		w.winner_slot = -1
		settle_match_visuals()
		return
	declare_winner(best, &"time_limit")
	w.event_log.emit(w.tick, &"time_limit_decided", best, -1, {"hp_ratio":w.decision_hp_ratio, "core_ratio":w.decision_core_ratio})

func standing_better(a: Dictionary, b: Dictionary) -> bool:
	var a_slot = int(a["slot"])
	var b_slot = int(b["slot"])
	if a_slot == w.winner_slot:
		return true
	if b_slot == w.winner_slot:
		return false
	if w.result_reason == &"time_limit":
		return time_limit_better(a_slot, b_slot)
	var a_alive = bool(a.get("hero_alive", false))
	var b_alive = bool(b.get("hero_alive", false))
	if a_alive != b_alive:
		return a_alive
	return float(a["score"]) > float(b["score"])

func final_standings() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for slot in range(w.heroes.size()):
		rows.append({
			"slot":slot,
			"hp_ratio":hero_hp_ratio(slot),
			"core_ratio":core_hp_ratio(slot),
			"score":float(w.heroes[slot]["score"]),
			"core_alive":bool(w.cores[slot]["alive"]),
			"hero_alive":bool(w.heroes[slot]["alive"]) and not bool(w.heroes[slot]["eliminated"])
		})
	rows.sort_custom(standing_better)
	return rows

func check_end() -> void:
	var alive_slots: Array[int] = []
	for hero in w.heroes:
		if not bool(hero["eliminated"]):
			alive_slots.append(int(hero["slot"]))
	if alive_slots.size() == 1:
		declare_winner(alive_slots[0], &"last_survivor")
	elif alive_slots.is_empty():
		w.result = &"draw"
		w.result_reason = &"no_survivors"
		w.winner_slot = -1
		settle_match_visuals()
