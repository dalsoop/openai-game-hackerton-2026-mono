extends RefCounted
## 스냅샷 키는 SnapContract 한곳. 패킹/언팩이 PLAYER_KEYS 를 그대로 쓴다.

const SnapContract := preload("res://games/dagul/net/snap_contract.gd")
const Parser := preload("res://games/dagul/net/net_snap_parser.gd")

func run(t) -> void:
	_pack_emits_every_player_key(t)
	_player_roundtrip(t)
	_item_field_roundtrip(t)
	_header_keys(t)
	_v2_roundtrip(t)
	_v2_omit_default(t)
	_v2_legacy_defaults(t)
	_parse_v2_wire(t)

func _pack_emits_every_player_key(t) -> void:
	var packed := SnapContract.pack_player(_sample_hero(), false, 7)
	t.check("플레이어 키 개수가 계약과 같다", packed.size() == SnapContract.PLAYER_KEYS.size())
	for key in SnapContract.PLAYER_KEYS:
		t.check("pack 에 %s" % key, packed.has(key))

func _player_roundtrip(t) -> void:
	var packed := SnapContract.pack_player(_sample_hero(), true, 4)
	var hero := SnapContract.unpack_player(packed, {}, 2, 60.0)
	t.check("hp 왕복", is_equal_approx(float(hero["hp"]), 204.0))
	t.check("max_hp 왕복", is_equal_approx(float(hero["max_hp"]), 176.0))
	t.check("mag 왕복", int(hero["mag"]) == 7)
	t.check("magMax → equipment.mag_size", int(hero["equipment"].get("mag_size", 0)) == 18)
	t.check("ult 왕복", is_equal_approx(float(hero["ultimate_charge"]), 55.0))
	t.check("animal 왕복", int(hero["animal"]) == 2)
	t.check("animal 만 있어도 id 를 복원한다", str(hero.get("character_id", "")) != "")
	var picked := SnapContract.unpack_player({
		SnapContract.P_SLOT: 3,
		SnapContract.P_NAME: "고른이",
		SnapContract.P_X: 10.0,
		SnapContract.P_Y: 20.0,
		SnapContract.P_HP: 80.0,
		SnapContract.P_MAX_HP: 176.0,
		SnapContract.P_ALIVE: true,
		SnapContract.P_CHARACTER_ID: "a5",
		SnapContract.P_ANIMAL: 0,
		SnapContract.P_MAG: 4,
		SnapContract.P_MAG_MAX: 18,
	}, {}, 3, 60.0)
	t.check("characterId 가 animal 보다 우선", str(picked.get("character_id", "")) == "a5")
	t.check("bind 는 id 에서 읽는다", int(picked.get("animal", -1)) == 5)
	t.check("슬롯을 캐릭터로 쓰지 않는다", int(picked.get("animal", -1)) != 3)
	var unknown := SnapContract.unpack_player(
		SnapContract.pack_player(_unknown_hero(), false, 0), {}, 0, 60.0)
	t.check("animal -1 왕복", int(unknown["animal"]) == -1)
	t.check("emote 왕복", int(hero["emote"]) == 2)
	t.check("emoteTime 왕복", is_equal_approx(float(hero["emote_time"]), 1.5))
	t.check("cpu 왕복", bool(hero["cpu"]) == true)
	t.check("ack 는 와이어에만 있다", int(packed[SnapContract.P_ACK]) == 4)

func _v2_roundtrip(t) -> void:
	var packed := SnapContract.pack_player(_v2_hero(), false, 1)
	var hero := SnapContract.unpack_player(packed, {}, 2, 60.0)
	t.check("action 왕복", str(hero["action"]) == "SKILL")
	t.check("stunT 왕복", is_equal_approx(float(hero["stun_time"]), 1.25))
	t.check("rootT 왕복", is_equal_approx(float(hero["root_time"]), 0.4))
	t.check("armorT 왕복", is_equal_approx(float(hero["super_armor_time"]), 0.8))
	t.check("launchVX 왕복", is_equal_approx(Vector2(hero["launch_vel"]).x, 120.0))
	t.check("charging 왕복", bool(hero["charging_skill"]) == true)
	t.check("heldItem 왕복", str(hero["held_item"]) == "spring")
	t.check("woolHp 왕복", int(hero["wool_hp"]) == 5)
	t.check("rouPhase 왕복", str(hero["roulette_phase"]) == "spin")
	t.check("rouSpin 문자열 왕복", str(hero["roulette_spin_id"]) == "atk")
	t.check("rouSpin 와이어가 문자열이다", typeof(packed.get(SnapContract.P_ROU_SPIN, 0)) == TYPE_STRING)
	t.check("rlTimed 왕복", (hero["rl_timed"] as Array).size() == 1)
	t.check("ultClones 왕복", (hero["ult_clones"] as Array).size() == 1)
	var clone: Dictionary = hero["ult_clones"][0]
	t.check("ultClones pos", is_equal_approx(Vector2(clone["pos"]).x, 10.0))
	t.check("mobCd 왕복", is_equal_approx(float(hero["mobility_cd"]), 4.5))
	t.check("hopT 왕복", is_equal_approx(float(hero["hop_time"]), 0.12))
	t.check("elim 왕복", bool(hero["eliminated"]) == true)
	t.check("mvSpd 왕복", is_equal_approx(float(hero["equipment"].get("move_speed", 0.0)), 420.0))

func _v2_omit_default(t) -> void:
	var packed := SnapContract.pack_player(_sample_hero(), false, 7)
	t.check("v1 키 개수는 유지", packed.size() == SnapContract.PLAYER_KEYS.size())
	for key in SnapContract.PLAYER_KEYS_V2:
		t.check("omit %s" % key, not packed.has(key))

func _v2_legacy_defaults(t) -> void:
	var old_snap := {
		SnapContract.P_SLOT: 2,
		SnapContract.P_NAME: "옛서버",
		SnapContract.P_X: 10.0, SnapContract.P_Y: 20.0,
		SnapContract.P_HP: 80.0, SnapContract.P_MAX_HP: 176.0,
		SnapContract.P_ALIVE: true, SnapContract.P_MAG: 4, SnapContract.P_MAG_MAX: 18,
	}
	var hero := SnapContract.unpack_player(old_snap, {}, 2, 60.0)
	t.check("구 스냅 action 기본", str(hero.get("action", "")) == "READY")
	t.check("구 스냅 stun 기본", is_equal_approx(float(hero.get("stun_time", -1.0)), 0.0))
	t.check("구 스냅 charging 기본", bool(hero.get("charging_skill", true)) == false)
	t.check("구 스냅 heldItem 기본", str(hero.get("held_item", "x")) == "")
	t.check("구 스냅 ultClones 기본", (hero.get("ult_clones", [1]) as Array).is_empty())
	t.check("구 스냅 elim 은 not alive", bool(hero.get("eliminated", true)) == false)
	t.check("구 스냅 hop 기본", is_equal_approx(float(hero.get("hop_time", -1.0)), 0.0))
	t.check("구 스냅 mobCd 기본", is_equal_approx(float(hero.get("mobility_cd", -1.0)), 0.0))

func _parse_v2_wire(t) -> void:
	var bullets: Array = Parser.parse_bullets([{
		"id": 3, "x": 1.0, "y": 2.0, "vx": 8.0, "vy": 0.0, "owner": 1,
		"kind": "shell", "radius": 11.0, "arc": true, "heavy": true, "src": "ultimate",
	}, {"x": 0.0, "y": 0.0, "owner": 0}], [], 20.0)
	t.check("탄 v2 kind", str(bullets[0]["kind"]) == "shell")
	t.check("탄 v2 radius", is_equal_approx(float(bullets[0]["radius"]), 11.0))
	t.check("탄 v2 src", StringName(bullets[0]["source"]) == &"ultimate")
	t.check("탄 기본 kind", str(bullets[1]["kind"]) == "bolt")
	t.check("탄 기본 radius", is_equal_approx(float(bullets[1]["radius"]), 5.0))
	var fx: Array = Parser.parse_effects([{
		"k": "hit", "x": 3.0, "y": 4.0, "r": 12.0, "t": 0.2, "maxT": 0.4,
		"label": "BANG", "dx": 0.0, "dy": -1.0, "follow": 2,
		"sx": 8.0, "sy": 9.0, "dep": false,
	}])
	t.check("이펙트 kind", str(fx[0]["kind"]) == "hit")
	t.check("이펙트 follow", int(fx[0]["follow_slot"]) == 2)
	t.check("이펙트 start_pos sx/sy", Vector2(fx[0]["start_pos"]).is_equal_approx(Vector2(8.0, 9.0)))
	t.check("이펙트 draw_departure dep", bool(fx[0]["draw_departure"]) == false)
	var fx_legacy: Array = Parser.parse_effects([{
		"k": "hit", "x": 3.0, "y": 4.0, "r": 12.0, "t": 0.2,
	}])
	t.check("구 이펙트 start_pos 는 pos", Vector2(fx_legacy[0]["start_pos"]).is_equal_approx(Vector2(3.0, 4.0)))
	t.check("구 이펙트 draw_departure 기본 true", bool(fx_legacy[0]["draw_departure"]) == true)
	var evs: Array = Parser.parse_events([{"t": 9, "k": "gun_fire", "a": 1, "b": -1, "d": {"eq": "glock"}}])
	t.check("이벤트 tick", int(evs[0]["tick"]) == 9)
	t.check("이벤트 kind", str(evs[0]["kind"]) == "gun_fire")
	t.check("이벤트 data", str(evs[0]["data"].get("eq", "")) == "glock")
	var loot: Array = Parser.parse_loot([
		{"id": "g1", "kind": "gun", "itemKind": "gun", "n": "샷건", "x": 1.0, "y": 2.0},
		{"id": "d1", "itemKind": "decoy", "disguise": "spring", "x": 3.0, "y": 4.0},
		"bad",
	])
	t.check("loot 2건 Dictionary만", loot.size() == 2)
	t.check("loot n 총이름", str(loot[0].get("gun_name", "")) == "샷건")
	t.check("loot disguise", str(loot[1].get("disguise", "")) == "spring")
	t.check("loot itemKind", str(loot[1].get("kind", "")) == "decoy")

func _v2_hero() -> Dictionary:
	var h := _sample_hero()
	h["action"] = &"SKILL"
	h["stun_time"] = 1.25
	h["root_time"] = 0.4
	h["cc_time"] = 0.2
	h["guard_time"] = 0.3
	h["super_armor_time"] = 0.8
	h["spawn_protect_time"] = 1.0
	h["launch_time"] = 0.15
	h["launch_vel"] = Vector2(120.0, -40.0)
	h["charging_skill"] = true
	h["charge_time"] = 0.6
	h["held_item"] = "spring"
	h["spring_time"] = 0.5
	h["slide_time"] = 0.1
	h["pull_time"] = 0.2
	h["pocket_time"] = 0.3
	h["mobility_cd"] = 4.5
	h["hop_time"] = 0.12
	h["hop_max"] = 0.30
	h["hop_height"] = 19.0
	h["eliminated"] = true
	h["equipment"]["move_speed"] = 420.0
	h["dmg_orb_time"] = 0.7
	h["down_taken"] = 12.0
	h["wool_time"] = 2.0
	h["wool_hp"] = 5
	h["wool_max"] = 5
	h["roulette_time"] = 1.1
	h["roulette_rank"] = "A"
	h["roulette_phase"] = "spin"
	h["roulette_spin_id"] = "atk"
	h["roulette_label"] = "BER"
	h["rl_timed"] = [{"id": "berserk", "time": 2.5, "name": "BER"}]
	h["ult_clones"] = [{"pos": Vector2(10.0, 20.0)}]
	return h

func _item_field_roundtrip(t) -> void:
	var packed1 := SnapContract.pack_player(_sample_hero(), false, 0)
	t.check("1개는 접미사 없는 medkit", str(packed1[SnapContract.P_ITEM]) == "medkit")
	var one := SnapContract.unpack_player(packed1, {}, 2, 60.0)
	t.check("1개 왕복", int(one["medkits"]) == 1)
	var h3 := _sample_hero()
	h3["medkits"] = 3
	var packed3 := SnapContract.pack_player(h3, false, 0)
	t.check("3개는 medkit:3", str(packed3[SnapContract.P_ITEM]) == "medkit:3")
	var three := SnapContract.unpack_player(packed3, {}, 2, 60.0)
	t.check("3개 왕복", int(three["medkits"]) == 3)
	var legacy := SnapContract.unpack_player({
		SnapContract.P_SLOT: 2,
		SnapContract.P_X: 0.0, SnapContract.P_Y: 0.0,
		SnapContract.P_HP: 80.0, SnapContract.P_ALIVE: true,
		SnapContract.P_ITEM: "medkit",
	}, {}, 2, 60.0)
	t.check("구 스냅 medkit 은 1개", int(legacy["medkits"]) == 1)
	var empty := SnapContract.unpack_player({
		SnapContract.P_SLOT: 2,
		SnapContract.P_X: 0.0, SnapContract.P_Y: 0.0,
		SnapContract.P_HP: 80.0, SnapContract.P_ALIVE: true,
		SnapContract.P_ITEM: "",
	}, {}, 2, 60.0)
	t.check("빈 item 은 0개", int(empty["medkits"]) == 0)

func _header_keys(t) -> void:
	var world := _header_world()
	var header := SnapContract.pack_header(world)
	t.check("header tick", int(header[SnapContract.TICK]) == 12)
	t.check("header zoneR", is_equal_approx(float(header[SnapContract.ZONE_R]), 3304.0))
	t.check("header zoneCX", is_equal_approx(float(header[SnapContract.ZONE_CX]), 3920.0))
	t.check("header wantedSlot", int(header[SnapContract.WANTED_SLOT]) == 3)

func _sample_hero() -> Dictionary:
	return {
		"slot": 2,
		"pos": Vector2(3920.0, 2380.0),
		"aim": Vector2.RIGHT,
		"hp": 204.0,
		"max_hp": 176.0,
		"alive": true,
		"display_name": "게스트",
		"equipment": {"name": "GLOCK 18", "character_name": "게스트", "mag_size": 18},
		"mag": 7,
		"reload_left": 0.0,
		"ultimate_charge": 55.0,
		"animal": 2,
		"medkits": 1,
		"kills": 1,
		"emote": 2,
		"emote_time": 1.5,
		"parked": false,
	}

func _unknown_hero() -> Dictionary:
	var h := _sample_hero()
	h["slot"] = 0
	h["animal"] = -1
	return h

func _header_world() -> RefCounted:
	var w := HeaderWorld.new()
	w.tick = 12
	w.match_time = 1.0
	w.result = &"playing"
	w.winner_slot = -1
	w.safe_zone_radius = 3304.0
	w.safe_zone_shrinking = false
	w.safe_zone_center = Vector2(3920.0, 2380.0)
	w.safe_zone_phase = 0
	w.start_countdown = 0.0
	w.wanted_slot = 3
	w.mode = "full"
	return w

class HeaderWorld extends RefCounted:
	var tick: int = 0
	var match_time: float = 0.0
	var result: StringName = &"playing"
	var winner_slot: int = -1
	var safe_zone_radius: float = 0.0
	var safe_zone_shrinking: bool = false
	var safe_zone_center: Vector2 = Vector2.ZERO
	var safe_zone_phase: int = 0
	var start_countdown: float = 0.0
	var wanted_slot: int = -1
	var mode: String = "classic"
