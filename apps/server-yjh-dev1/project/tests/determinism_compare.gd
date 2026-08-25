extends SceneTree

func _init():
	var OrigWorld = load("res://tests/original_game_world.gd")
	var ModWorld = load("res://scripts/sim/game_world.gd")

	var orig = OrigWorld.new(1234)
	orig.set_mode("full")
	orig.reset()

	var mod = ModWorld.new(1234)
	mod.set_mode("full")
	mod.reset()

	var empty_cmd := {"mx":0.0, "my":0.0, "fire":false, "dash":false, "use":false, "aimX":1.0, "aimY":0.0}
	var mismatches: Array[String] = []
	var first_fail_tick := -1

	for t in 300:
		orig.step_tick(empty_cmd)
		mod.step_tick(empty_cmd)

		for i in 8:
			var oh: Dictionary = orig.heroes[i]
			var mh: Dictionary = mod.heroes[i]
			var op: Vector2 = Vector2(oh["pos"])
			var mp: Vector2 = Vector2(mh["pos"])
			if op.distance_to(mp) > 0.01:
				mismatches.append("tick %d hero %d pos: orig(%.2f,%.2f) mod(%.2f,%.2f)" % [t, i, op.x, op.y, mp.x, mp.y])
			if abs(float(oh["hp"]) - float(mh["hp"])) > 0.01:
				mismatches.append("tick %d hero %d HP: orig %.1f mod %.1f" % [t, i, float(oh["hp"]), float(mh["hp"])])
			if bool(oh["alive"]) != bool(mh["alive"]):
				mismatches.append("tick %d hero %d alive: orig %s mod %s" % [t, i, oh["alive"], mh["alive"]])
			if bool(oh.get("eliminated", false)) != bool(mh.get("eliminated", false)):
				mismatches.append("tick %d hero %d eliminated: orig %s mod %s" % [t, i, oh.get("eliminated"), mh.get("eliminated")])

		if not mismatches.is_empty() and first_fail_tick < 0:
			first_fail_tick = t

		if mismatches.size() > 20:
			break

	if str(orig.result) != str(mod.result):
		mismatches.append("result: orig %s mod %s" % [orig.result, mod.result])
	if orig.winner_slot != mod.winner_slot:
		mismatches.append("winner: orig %d mod %d" % [orig.winner_slot, mod.winner_slot])

	print("")
	print("===== DETERMINISM COMPARE =====")
	print("Ticks run: %d" % mini(300, 300))
	if mismatches.is_empty():
		print("RESULT: OK — 300 ticks, 8 heroes, all match")
	else:
		print("RESULT: FAIL — %d mismatches, first at tick %d" % [mismatches.size(), first_fail_tick])
		for m in mismatches:
			print("  %s" % m)
	print("===============================")
	print("")

	quit()
