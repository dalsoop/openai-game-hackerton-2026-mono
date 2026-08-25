extends RefCounted
## 시드 결정론 시금석 — 같은 시드면 같은 시퀀스, 다른 시드면 다른 값.
## 첫 next_u32 는 LCG 수식 손계산 값으로 고정(42*1664525+1013904223).

const SeededRngScript := preload("res://games/dagul/sim/seeded_rng.gd")

func run(t) -> void:
	var rng = SeededRngScript.new(42)
	t.check("seed42 first next_u32", rng.next_u32() == 1083814273)

	var a = SeededRngScript.new(7)
	var b = SeededRngScript.new(7)
	var same := true
	for i in range(10):
		if a.next_u32() != b.next_u32():
			same = false
	t.check("same seed same sequence", same)

	var c = SeededRngScript.new(8)
	t.check("different seed different value", a.next_u32() != c.next_u32())

	var in_unit := true
	var r = SeededRngScript.new(99)
	for i in range(200):
		var v: float = r.randf_value()
		if v < 0.0 or v >= 1.0:
			in_unit = false
	t.check("randf_value in [0,1)", in_unit)

	var r2 = SeededRngScript.new(5)
	var in_range := true
	for i in range(200):
		var n: int = r2.rangei(3, 9)
		if n < 3 or n > 9:
			in_range = false
	t.check("rangei within bounds", in_range)

	var r3 = SeededRngScript.new(11)
	# 계약: max<=min 이면 첫 인자(min_value)를 그대로 돌려준다
	t.check("rangei reversed returns first arg", r3.rangei(9, 3) == 9)

	var r4 = SeededRngScript.new(13)
	t.check("chance(0) always false", r4.chance(0.0) == false and r4.chance(0.0) == false)
	t.check("chance(1) always true", r4.chance(1.0) == true)

	var r5 = SeededRngScript.new(17)
	t.check("choose empty is null", r5.choose([]) == null)
	t.check("choose picks member", [1, 2, 3].has(r5.choose([1, 2, 3])))

	var zero = SeededRngScript.new(0)
	t.check("seed 0 coerced to 1 produces values", zero.next_u32() == SeededRngScript.new(1).next_u32())
