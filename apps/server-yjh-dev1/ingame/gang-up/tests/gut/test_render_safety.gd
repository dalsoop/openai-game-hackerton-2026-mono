extends Node

const WorldScript = preload("res://scripts/sim/game_world.gd")

func _ready() -> void:
	print("[test_render_safety] running...")
	test_world_fields_for_renderer()
	test_hero_render_fields()
	test_world_public_api()
	print("[test_render_safety] ALL PASSED")

func test_world_fields_for_renderer() -> void:
	var w = WorldScript.new(1234)
	w.set_mode("full")
	w.reset()
	assert(w.heroes is Array, "heroes should be Array")
	assert(w.projectiles is Array, "projectiles should be Array")
	assert(w.zones is Array, "zones should be Array")
	assert(w.effects is Array, "effects should be Array")
	assert(w.deployables is Array, "deployables should be Array")
	assert(w.knockouts is Array, "knockouts should be Array")
	assert(w.covers is Array, "covers should be Array")
	assert(w.health_pickups is Array, "health_pickups should be Array")
	assert(w.crates is Array, "crates should be Array")
	assert(w.cores is Array, "cores should be Array")
	assert(w.crate_orbs is Array, "crate_orbs should be Array")
	assert(w.mid_tower is Dictionary, "mid_tower should be Dictionary")
	assert(w.finish_cine is Dictionary, "finish_cine should be Dictionary")
	assert(typeof(w.tick) == TYPE_INT, "tick should be int")
	assert(typeof(w.safe_zone_center) == TYPE_VECTOR2, "safe_zone_center should be Vector2")
	assert(typeof(w.safe_zone_radius) == TYPE_FLOAT, "safe_zone_radius should be float")
	print("  test_world_fields_for_renderer PASSED")

func test_hero_render_fields() -> void:
	var w = WorldScript.new(5678)
	w.set_mode("full")
	w.reset()
	for i in 8:
		var h: Dictionary = w.heroes[i]
		assert(h.has("pos"), "hero %d missing pos" % i)
		assert(h.has("hp"), "hero %d missing hp" % i)
		assert(h.has("max_hp"), "hero %d missing max_hp" % i)
		assert(h.has("alive"), "hero %d missing alive" % i)
		assert(h.has("equipment"), "hero %d missing equipment" % i)
		assert(h.has("facing"), "hero %d missing facing" % i)
		assert(h.has("display_name") or h.has("name"), "hero %d missing display_name or name" % i)
	print("  test_hero_render_fields PASSED (all 8 heroes have render fields)")

func test_world_public_api() -> void:
	var w = WorldScript.new(9999)
	w.set_mode("full")
	w.reset()
	assert(w.has_method("step_tick"), "world should have step_tick")
	assert(w.has_method("reset"), "world should have reset")
	assert(w.has_method("set_mode"), "world should have set_mode")
	assert(w.has_method("hero_hidden_in_smoke"), "world should have hero_hidden_in_smoke")
	assert(w.has_method("final_standings"), "world should have final_standings")
	print("  test_world_public_api PASSED")
