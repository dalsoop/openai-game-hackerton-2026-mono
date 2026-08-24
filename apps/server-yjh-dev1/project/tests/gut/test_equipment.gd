extends Node

const EquipReg = preload("res://scripts/sim/equipment_registry.gd")

const ALL_IDS := ["scatter", "rail", "mortar", "leech", "breaker", "burst", "blade", "brawler", "bomb", "spear", "chain", "shield"]

func _ready() -> void:
	print("[test_equipment] running...")
	test_all_equipment_ids()
	test_equipment_stats()
	test_identity_for_all()
	test_mobility_for_all()
	print("[test_equipment] ALL PASSED")

func test_all_equipment_ids() -> void:
	var reg := EquipReg.new()
	for id in ALL_IDS:
		var equip := reg.make_equipment(id)
		assert(str(equip.get("id", "")) == id, "make_equipment(%s) should return id=%s" % [id, id])
	print("  test_all_equipment_ids PASSED (12 weapons)")

func test_equipment_stats() -> void:
	var reg := EquipReg.new()
	for id in ALL_IDS:
		var equip := reg.make_equipment(id)
		assert(float(equip.get("damage", 0)) > 0.0, "%s damage should be > 0" % id)
		assert(float(equip.get("speed", 0)) > 0.0, "%s speed should be > 0" % id)
		assert(float(equip.get("max_hp", 0)) > 0.0, "%s max_hp should be > 0" % id)
		assert(float(equip.get("move_speed", 0)) > 0.0, "%s move_speed should be > 0" % id)
		assert(float(equip.get("normal_interval", 0)) > 0.0, "%s interval should be > 0" % id)
	print("  test_equipment_stats PASSED (all stats positive)")

func test_identity_for_all() -> void:
	var reg := EquipReg.new()
	for id in ALL_IDS:
		var identity := reg.identity_for(id)
		assert(str(identity.get("character_name", "")) != "", "%s should have character_name" % id)
		assert(str(identity.get("role", "")) != "", "%s should have role" % id)
	print("  test_identity_for_all PASSED")

func test_mobility_for_all() -> void:
	var reg := EquipReg.new()
	for id in ALL_IDS:
		var mob := reg.mobility_for(id)
		assert(float(mob.get("mobility_cooldown", 0)) > 0.0, "%s should have cooldown > 0" % id)
		assert(float(mob.get("mobility_distance", 0)) > 0.0, "%s should have distance > 0" % id)
	print("  test_mobility_for_all PASSED")
