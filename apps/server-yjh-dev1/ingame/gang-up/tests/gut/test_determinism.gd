extends Node

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _ready() -> void:
	print("[test_determinism] running...")
	test_same_seed_same_result()
	test_different_seed_different_result()
	print("[test_determinism] ALL PASSED")

func test_same_seed_same_result() -> void:
	var positions_a := _run_sim(42, 100)
	var positions_b := _run_sim(42, 100)
	for i in positions_a.size():
		var pa: Vector2 = positions_a[i]
		var pb: Vector2 = positions_b[i]
		assert(pa == pb, "hero %d position mismatch: %s vs %s" % [i, str(pa), str(pb)])
	print("  test_same_seed_same_result PASSED (100 ticks, 8 heroes identical)")

func test_different_seed_different_result() -> void:
	var positions_a := _run_sim(100, 100)
	var positions_b := _run_sim(200, 100)
	var any_different := false
	for i in positions_a.size():
		if positions_a[i] != positions_b[i]:
			any_different = true
			break
	assert(any_different, "different seeds should produce different positions")
	print("  test_different_seed_different_result PASSED")

func _run_sim(seed_val: int, ticks: int) -> Array[Vector2]:
	var w = WorldScript.new(seed_val)
	w.set_mode("full")
	w.reset()
	var cmd := {"mx":0.0, "my":0.0, "fire":false, "dash":false, "use":false, "aimX":1.0, "aimY":0.0}
	for _t in ticks:
		w.step_tick(cmd)
	var positions: Array[Vector2] = []
	for h in w.heroes:
		positions.append(Vector2(h["pos"]))
	return positions
