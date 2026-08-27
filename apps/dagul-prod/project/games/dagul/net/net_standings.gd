extends RefCounted
## 순위표 — net_world.heroes 사전 배열에서 리더보드·최종 순위를 뽑는다.
## 정렬 규칙은 net_world 에 있던 원본 그대로: 점수 내림차순, 최종은 승자 최우선.


static func leaderboard(heroes: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for hero in heroes:
		var slot := int(hero.get("slot", -1))
		rows.append({"slot":slot, "score":float(hero["score"]), "kills":int(hero["kills"]), "deaths":int(hero["deaths"]), "streak":int(hero.get("kill_streak", 0)), "best_streak":int(hero.get("best_kill_streak", 0)), "eliminations":int(hero["eliminations"]), "damage":0.0, "core_damage":0.0})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	return rows


static func final_standings(heroes: Array, winner_slot: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for hero in heroes:
		rows.append({
			"slot":int(hero.get("slot", -1)),
			"hp_ratio":clampf(float(hero["hp"]) / 100.0, 0.0, 1.0),
			"core_ratio":0.0,
			"score":float(hero["score"]),
			"core_alive":false,
			"hero_alive":bool(hero["alive"]) and not bool(hero["eliminated"])
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["slot"]) == winner_slot:
			return true
		if int(b["slot"]) == winner_slot:
			return false
		return float(a["score"]) > float(b["score"])
	)
	return rows
