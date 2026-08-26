extends RefCounted
## 세이프존 단계 전이 시금석 — 수축 완료(_complete_shrink_phase)가
## 정의에 맞게 다음 대기 단계로 넘기고 마지막 단계를 확정 종료하는지.
## 2026-08-25 결함 방어: 함수 구현이 사라져 파스 에러 → 매치 합류 실패했었다.

const SafeZoneLogicScript := preload("res://games/dagul/sim/safe_zone_logic.gd")

class MockWorld extends RefCounted:
	var SAFE_ZONE_PHASES := [
		{"wait": 1.0, "shrink": 1.0, "radius": 100.0},
		{"wait": 1.0, "shrink": 1.0, "radius": 50.0},
	]
	var safe_zone_complete := false
	var safe_zone_shrinking := true
	var safe_zone_phase := 0
	var safe_zone_phase_time := 0.0
	var safe_zone_from_radius := 200.0
	var safe_zone_target_radius := 100.0
	var safe_zone_radius := 200.0
	var heroes: Array = []
	var last_announce := ""

	func _announce(text: String, _ticks: int) -> void:
		last_announce = text

func run(t) -> void:
	var w0 := MockWorld.new()
	var logic = SafeZoneLogicScript.new(w0)

	logic._complete_shrink_phase()
	t.check("완료 직후 대기 상태 진입", not w0.safe_zone_shrinking)
	t.check("단계 카운터 진행", w0.safe_zone_phase == 1)
	t.check("마지막 아니면 미완료", not w0.safe_zone_complete)

	w0.safe_zone_shrinking = true
	logic._complete_shrink_phase()
	t.check("마지막 단계 완료 확정", w0.safe_zone_complete)

	var w1 := MockWorld.new()
	w1.safe_zone_from_radius = 200.0
	w1.safe_zone_target_radius = 100.0
	w1.safe_zone_phase_time = 0.5
	var l1 = SafeZoneLogicScript.new(w1)
	l1._advance_shrink_phase()
	t.check("수축 진행(완화 보간 적용)", is_equal_approx(w1.safe_zone_radius, 150.0))
	t.check("진행 중 미전이", w1.safe_zone_shrinking and w1.safe_zone_phase == 0)

	w1.safe_zone_phase_time = 1.0
	l1._advance_shrink_phase()
	t.check("수축 완료 시 자동 전이", not w1.safe_zone_shrinking and w1.safe_zone_phase == 1)
