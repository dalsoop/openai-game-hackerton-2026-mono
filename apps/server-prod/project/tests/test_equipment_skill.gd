extends RefCounted
## 우클릭 장비 스킬 — 원본 gang-up 차지/발사가 시뮬에 다시 붙었는지.

const WorldScript := preload("res://games/dagul/sim/game_world.gd")
const SkillScript := preload("res://games/dagul/sim/equipment_skill.gd")

func run(t) -> void:
	var world = WorldScript.new(7)
	world.start_countdown = 0.0
	world.local_slot = 0
	world.human_slots[0] = true
	t.check("히어로가 있다", world.heroes.size() > 0)
	if world.heroes.is_empty():
		return
	var eq: Dictionary = world.equip.make_equipment("rail")
	t.check("스킬 쿨이 99이 아니다", float(eq["cooldown"]) < 10.0)
	t.check("스킬 피해가 총탄과 다르다", float(eq["damage"]) != float(eq["normal_damage"]))
	t.check("스킬 이름이 있다", str(eq["skill_name"]) == "ANCHOR BREAK")

	var idle := _cmd(false, false, false)
	world.step_tick(idle, 1.0 / 60.0)
	var before: int = world.projectiles.size() + world.zones.size() + world.deployables.size()
	world.step_tick(_cmd(true, true, false), 1.0 / 60.0)
	t.check("누름에서 차지 시작", bool(world.heroes[0]["charging_skill"]))
	world.step_tick(_cmd(true, false, false), 1.0 / 60.0)
	t.check("홀드 중 차지 유지", bool(world.heroes[0]["charging_skill"]))
	t.check("차지 시간이 오른다", float(world.heroes[0]["charge_time"]) > 0.0)
	world.step_tick(_cmd(false, false, true), 1.0 / 60.0)
	t.check("떼면 차지 끝", not bool(world.heroes[0]["charging_skill"]))
	t.check("쿨이 돈다", float(world.heroes[0]["equipment_cd"]) > 0.0)
	var after: int = world.projectiles.size() + world.zones.size() + world.deployables.size()
	t.check("발사체가 생긴다", after > before)

	var guest = WorldScript.new(11)
	guest.start_countdown = 0.0
	guest.local_slot = 0
	guest.human_slots[1] = true
	var gpos: Vector2 = guest.heroes[1]["pos"]
	guest.peer_commands[1] = {
		"mx": 0.0, "my": 0.0, "aimX": gpos.x + 80.0,
		"aimY": gpos.y, "fire": false, "dash": false,
		"equipment": true, "equipmentPressed": true, "equipmentReleased": false,
	}
	guest.step_tick(idle, 1.0 / 60.0)
	t.check("게스트 우클릭도 차지", bool(guest.heroes[1]["charging_skill"]))
	var unk = WorldScript.new(3)
	unk.start_countdown = 0.0
	unk.local_slot = 0
	unk.heroes[0]["equipment"]["id"] = "nope"
	var cd_before := float(unk.heroes[0]["equipment_cd"])
	SkillScript.fire(unk, 0, Vector2.RIGHT, 1.0)
	t.check("모르는 장비는 발사하지 않는다", is_equal_approx(float(unk.heroes[0]["equipment_cd"]), cd_before))

func _cmd(held: bool, pressed: bool, released: bool) -> Dictionary:
	return {
		"move": Vector2.ZERO, "aim": Vector2(4100, 2380),
		"primary": false, "primary_pressed": false,
		"equipment": held, "equipment_pressed": pressed, "equipment_released": released,
		"ultimate": false, "mobility": false, "hop": false, "medkit": false,
		"reload": false, "finish": false,
	}
