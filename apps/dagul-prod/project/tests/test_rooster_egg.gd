extends RefCounted
## 수탉 알 폭발 트리거 시금석 — 소유자 제외·사망자 무시·감지 반경 판정.
## 2026-08-25 결함 방어: _rooster_egg_triggered 구현이 사라져 파스 에러를 냈다.

const UltimateSummonScript := preload("res://games/dagul/sim/ultimate_summon.gd")

class MockWorld extends RefCounted:
	var HERO_RADIUS := 20.0
	var heroes: Array = []

static func _hero(pos: Vector2, alive: bool) -> Dictionary:
	return {"pos": pos, "alive": alive, "eliminated": false}

func run(t) -> void:
	var w := MockWorld.new()
	var sum := UltimateSummonScript.new(w)
	var origin := Vector2.ZERO

	w.heroes = [_hero(Vector2(10.0, 0.0), true)]
	t.check("근접 적 트리거", sum._rooster_egg_triggered(origin, 150.0, 1))

	w.heroes = [_hero(Vector2(10.0, 0.0), true)]
	t.check("소유자 자신 미트리거", not sum._rooster_egg_triggered(origin, 150.0, 0))

	w.heroes = [_hero(Vector2(10.0, 0.0), false)]
	t.check("사망자 미트리거", not sum._rooster_egg_triggered(origin, 150.0, 1))

	w.heroes = [_hero(Vector2(10.0, 0.0), true), _hero(Vector2(500.0, 0.0), true)]
	t.check("반경 밖 미트리거", sum._rooster_egg_triggered(origin, 150.0, 1))

	w.heroes = []
	t.check("빈 필드 미트리거", not sum._rooster_egg_triggered(origin, 150.0, 1))
