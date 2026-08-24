extends Node

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _ready() -> void:
	print("[test_game_world] running...")
	test_reset()
	test_step_tick()
	test_mode_full()
	print("[test_game_world] ALL PASSED")

func test_reset() -> void:
	var w = WorldScript.new(1234)
	w.set_mode("full")
	w.reset()
	assert(w.heroes.size() == 8, "heroes count should be 8, got %d" % w.heroes.size())
	assert(w.result == &"playing", "result should be playing, got %s" % str(w.result))
	assert(w.tick == 0, "tick should be 0 after reset")
	for i in 8:
		var h: Dictionary = w.heroes[i]
		assert(float(h.get("hp", 0)) > 0.0, "hero %d should have hp > 0" % i)
		assert(h.has("pos"), "hero %d should have pos" % i)
	print("  test_reset PASSED")

func test_step_tick() -> void:
	var w = WorldScript.new(5678)
	w.set_mode("full")
	w.reset()
	var cmd := {"mx":0.0, "my":0.0, "fire":false, "dash":false, "use":false, "aimX":1.0, "aimY":0.0}
	for i in 100:
		w.step_tick(cmd)
	assert(w.tick == 100, "tick should be 100, got %d" % w.tick)
	assert(w.heroes.size() == 8, "heroes should still be 8")
	print("  test_step_tick PASSED (100 ticks, no crash)")

func test_mode_full() -> void:
	var w = WorldScript.new(9999)
	w.set_mode("full")
	w.reset()
	assert(w.mode == "full", "mode should be full")
	var has_medkit := false
	for h in w.heroes:
		if int(h.get("medkits", 0)) >= 0:
			has_medkit = true
			break
	assert(has_medkit, "full mode should have medkit support")
	print("  test_mode_full PASSED")
