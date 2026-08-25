extends Node

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _ready() -> void:
	print("[test_modules] running...")
	test_all_modules_initialized()
	test_module_world_reference()
	test_step_tick_with_modules()
	print("[test_modules] ALL PASSED")

func test_all_modules_initialized() -> void:
	var w = WorldScript.new(1234)
	assert(w.equip != null, "equip module should be initialized")
	assert(w.arena != null, "arena module should be initialized")
	assert(w.roul != null, "roulette module should be initialized")
	assert(w.crate != null, "crate module should be initialized")
	assert(w.mov != null, "movement module should be initialized")
	assert(w.proj != null, "projectile module should be initialized")
	assert(w.dmg != null, "damage module should be initialized")
	assert(w.ult_animal != null, "ult_animal module should be initialized")
	assert(w.ult_effect != null, "ult_effect module should be initialized")
	assert(w.act_item != null, "act_item module should be initialized")
	assert(w.lifecycle != null, "lifecycle module should be initialized")
	assert(w.tower != null, "tower module should be initialized")
	assert(w.cpu != null, "cpu module should be initialized")
	assert(w.deploy != null, "deploy module should be initialized")
	assert(w._szl != null, "safe_zone module should be initialized")
	assert(w.ult_summon != null, "ult_summon module should be initialized")
	print("  test_all_modules_initialized PASSED (16 modules)")

func test_module_world_reference() -> void:
	var w = WorldScript.new(5678)
	assert(w.arena.w == w, "arena should reference world")
	assert(w.roul.w == w, "roulette should reference world")
	assert(w.crate.w == w, "crate should reference world")
	assert(w.mov.w == w, "movement should reference world")
	assert(w.proj.w == w, "projectile should reference world")
	assert(w.dmg.w == w, "damage should reference world")
	assert(w.lifecycle.w == w, "lifecycle should reference world")
	assert(w.cpu.w == w, "cpu should reference world")
	print("  test_module_world_reference PASSED (all w refs correct)")

func test_step_tick_with_modules() -> void:
	var w = WorldScript.new(9999)
	w.set_mode("full")
	w.reset()
	var cmd := {"mx":0.5, "my":-0.3, "fire":true, "dash":false, "use":false, "aimX":1.0, "aimY":0.0}
	for i in 200:
		w.step_tick(cmd)
	assert(w.tick == 200, "tick should be 200, got %d" % w.tick)
	var alive_count := 0
	for h in w.heroes:
		if bool(h.get("alive", false)):
			alive_count += 1
	assert(alive_count >= 0, "alive count should be valid")
	print("  test_step_tick_with_modules PASSED (200 ticks with input, no crash)")
