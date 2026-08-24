extends SceneTree

func _init():
	var OrigWorld = load("res://tests/original_game_world.gd")
	var ModWorld = load("res://scripts/sim/game_world.gd")
	var seeds := [1234, 5678, 9999, 42, 2222]
	var empty_cmd := {"mx":0.0, "my":0.0, "fire":false, "dash":false, "use":false, "aimX":1.0, "aimY":0.0}
	var all_ok := true
	print("")
	print("===== MULTI-SEED DETERMINISM =====")
	for s in seeds:
		var orig = OrigWorld.new(s)
		orig.set_mode("full")
		orig.reset()
		var mod = ModWorld.new(s)
		mod.set_mode("full")
		mod.reset()
		var fail := ""
		for t in 600:
			orig.step_tick(empty_cmd)
			mod.step_tick(empty_cmd)
			for i in 8:
				var oh = orig.heroes[i]
				var mh = mod.heroes[i]
				if Vector2(oh["pos"]).distance_to(Vector2(mh["pos"])) > 0.01:
					fail = "tick %d hero %d pos diverged" % [t, i]
					break
				if abs(float(oh["hp"]) - float(mh["hp"])) > 0.01:
					fail = "tick %d hero %d HP diverged" % [t, i]
					break
			if fail != "":
				break
		if fail == "":
			print("  seed %d: OK (600 ticks)" % s)
		else:
			print("  seed %d: FAIL — %s" % [s, fail])
			all_ok = false
	print("OVERALL: %s" % ("ALL PASS" if all_ok else "SOME FAILED"))
	print("==================================")
	print("")
	quit()
