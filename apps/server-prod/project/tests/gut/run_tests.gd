extends SceneTree

const TestGameWorld = preload("res://tests/gut/test_game_world.gd")
const TestEquipment = preload("res://tests/gut/test_equipment.gd")
const TestDeterminism = preload("res://tests/gut/test_determinism.gd")

func _init() -> void:
	print("=== GUT Test Suite ===")
	var tests := [TestGameWorld, TestEquipment, TestDeterminism]
	for t_script in tests:
		var t = t_script.new()
		root.add_child(t)
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	print("=== Tests Complete ===")
	quit(0)
