class_name GangGameWorld
extends RefCounted
const GunSig = preload("res://scripts/sim/gun_signature.gd")
const SeededRngScript = preload("res://scripts/sim/seeded_rng.gd")
const EventLogScript = preload("res://scripts/sim/event_log.gd")
const EquipReg = preload("res://scripts/sim/equipment_registry.gd")
const ArenaGeo = preload("res://scripts/sim/arena_geometry.gd")
const RoulBuf = preload("res://scripts/sim/roulette_buff.gd")
const CratePk = preload("res://scripts/sim/crate_pickup.gd")
const HeroMov = preload("res://scripts/sim/hero_movement.gd")
const ProjHit = preload("res://scripts/sim/projectile_hit.gd")
const DmgSys = preload("res://scripts/sim/damage_system.gd")
const UltAnimal = preload("res://scripts/sim/ultimate_animal.gd")
const UltEffect = preload("res://scripts/sim/ultimate_effect.gd")
const ActItem = preload("res://scripts/sim/active_item.gd")
const MatchLife = preload("res://scripts/sim/match_lifecycle.gd")
const MidTowerMod = preload("res://scripts/sim/mid_tower.gd")
const CpuBeh = preload("res://scripts/sim/cpu_behavior.gd")
const DeploySys = preload("res://scripts/sim/deployable_system.gd")

const PLAYER_COUNT := 8
const HERO_RADIUS := 20.0
const HERO_SPEED := 419.0
const SOURCE_ARENA_SIZE := Vector2(2800.0, 1700.0)
const ARENA_TILE_SCALE := 1.4
const ARENA_SIZE := Vector2(7840.0, 4760.0)
const ARENA_CENTER := Vector2(3920.0, 2380.0)
const ARENA_MARGIN := 104.0
const SPAWN_HERO_RADIUS_X := 3360.0
const SPAWN_HERO_RADIUS_Y := 1940.0
const SPAWN_CORE_RADIUS_X := 3600.0
const SPAWN_CORE_RADIUS_Y := 2120.0
const CORE_RADIUS := 34.0
const CORE_MAX_HP := 210.0
const FIXED_DT := 1.0 / 60.0
const START_COUNTDOWN := 3.0
const MATCH_TIME_LIMIT := 210.0
const TOWER_SPAWN_TIME := 75.0
const TOWER_RADIUS := 86.0
const TOWER_MAX_HP := 2400.0
const TOWER_RANGE := 820.0
const TOWER_INTERVAL := 1.85
const TOWER_DAMAGE := 22.0
const ULTIMATE_MAX := 100.0
const HEALTH_PICKUP_RADIUS := 27.0
const HEALTH_PICKUP_RESPAWN := 16.0
const HEALTH_PICKUP_HEAL_RATIO := 0.30
const HEALTH_PICKUP_MAGNET_RADIUS := 217.0
const HEALTH_PICKUP_MAGNET_SPEED := 760.0
const HEALTH_PICKUP_RETURN_SPEED := 280.0
const CRATE_RADIUS := 28.0
const CRATE_MAX_HP := 48.0
const CRATE_ORB_RADIUS := 16.0
const CRATE_ORB_ARM := 0.25
const CRATE_ORB_DMG_TIME := 12.0
const CRATE_ORB_DMG_MUL := 1.25
const CRATE_ORB_ULT_RATIO := 0.34
const CRATE_RING_A_SCALE := 0.82
const CRATE_RING_B_SCALE := 0.52
const CRATE_RING_C_SCALE := 0.30
const MAX_REVIVES := 3
const RESPAWN_BASE := 3.0
const RESPAWN_RANK_STEP := 0.5
const RESPAWN_MAX := 5.5
const DOWN_BLEED_TIME := 5.0
const DOWN_FINISH_HP := 48.0
const HOP_AIR := 0.30
const HOP_LOCK := 0.08
const SOURCE_HEALTH_PICKUP_POINTS := [Vector2(1400.0, 430.0), Vector2(1400.0, 1270.0), Vector2(760.0, 850.0), Vector2(2040.0, 850.0)]
const SAFE_ZONE_INITIAL_RADIUS := 3304.0
const SAFE_ZONE_DAMAGE_PER_SEC := 16.0
const SAFE_ZONE_TICK_INTERVAL := 0.50
const SAFE_ZONE_EDGE_BUFFER := 252.0
const SAFE_ZONE_PHASES := [{"wait":20.0,"shrink":22.0,"radius":2750.0},{"wait":16.0,"shrink":20.0,"radius":2200.0},{"wait":14.0,"shrink":18.0,"radius":1700.0},{"wait":12.0,"shrink":16.0,"radius":1280.0},{"wait":12.0,"shrink":16.0,"radius":900.0}]
const MEDKIT_MAX := 3
const MEDKIT_HEAL_RATIO := 0.30
const GUN_LOOT_MODES := ["gun-semi", "gun-auto", "full"]
const MEDKIT_MODES := ["item", "full"]
const NO_LOOT_MODES := ["gun-semi", "gun-auto"]
const ITEM_POOL_MODE := "item"
const SPRING_AIR := 0.45
const SPRING_LIFT := 36.0
const SPRING_EVADE := 0.22
const SPRING_BOOST := 220.0
const SLIDE_DURATION := 2.2
const SLIDE_ACCEL := 520.0
const SLIDE_FRICTION := 180.0
const PULL_DURATION := 0.55
const PULL_RADIUS := 300.0
const PULL_LAUNCH := 380.0
const DECOY_DAMAGE := 18.0
const DECOY_KNOCK := 90.0
const POCKET_DURATION := 5.0
const POCKET_RADIUS := 150.0
const HOP_LIFT_DEFAULT := 19.0
const ITEM_DROP_IGNORE := 0.45
const MODE_START_EQUIPMENT := {"gun-semi":"rail","gun-auto":"burst","item":"scatter"}
const GUN_LOOT_CHAIN := ["rail","burst","scatter","mortar","breaker","bomb","leech","blade","spear","chain","shield","brawler"]

var rng
var event_log
var tick: int = 0
var heroes: Array[Dictionary] = []
var cores: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var deployables: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var knockouts: Array[Dictionary] = []
var covers: Array[Dictionary] = []
var health_pickups: Array[Dictionary] = []
var crates: Array[Dictionary] = []
var rat_tides: Array[Dictionary] = []
var snake_skins: Array[Dictionary] = []
var dragon_smokes: Array[Dictionary] = []
var tiger_roars: Array[Dictionary] = []
var rabbit_holes: Array[Dictionary] = []
var horse_kicks: Array[Dictionary] = []
var rooster_eggs: Array[Dictionary] = []
var pig_muds: Array[Dictionary] = []
var dog_bones: Array[Dictionary] = []
var finish_cine: Dictionary = {}
var crate_orbs: Array[Dictionary] = []
var mid_tower: Dictionary = {}
var next_entity_id: int = 100
var result: StringName = &"playing"
var winner_slot: int = -1
var result_reason: StringName = &""
var decision_hp_ratio: float = 0.0
var decision_core_ratio: float = 0.0
var match_time: float = 0.0
var wanted_slot: int = -1
var callout: String = ""
var callout_ticks: int = 0
var impact_ticks: int = 0
var impact_pos: Vector2 = ARENA_CENTER
var local_hit_shake: int = 0
var local_fire_shake: int = 0
var local_mouse_kick: Vector2 = Vector2.ZERO
var last_down_slot: int = -1
var last_down_ticks: int = 0
var start_countdown: float = START_COUNTDOWN
var time_limit_warning_emitted: bool = false
var ultimate_focus_slot: int = -1
var ultimate_focus_time: float = 0.0
var ultimate_focus_max: float = 0.48
var streak_callout: String = ""
var streak_subtitle: String = ""
var streak_callout_ticks: int = 0
var streak_callout_shutdown: bool = false
var safe_zone_center: Vector2 = ARENA_CENTER
var safe_zone_radius: float = SAFE_ZONE_INITIAL_RADIUS
var safe_zone_from_radius: float = SAFE_ZONE_INITIAL_RADIUS
var safe_zone_target_radius: float = SAFE_ZONE_INITIAL_RADIUS
var safe_zone_phase: int = 0
var safe_zone_phase_time: float = 0.0
var safe_zone_shrinking: bool = false
var safe_zone_complete: bool = false
var safe_zone_damage_clock: float = 0.0
var mode: String = "classic"
var is_net := false
var local_slot: int = 0
var human_slots: Dictionary = {}
var peer_commands: Dictionary = {}
var equip: EquipReg
var arena: ArenaGeo
var roul: RoulBuf
var crate: CratePk
var mov: HeroMov
var proj: ProjHit
var dmg: DmgSys
var ult_animal
var ult_effect
var act_item
var lifecycle
var tower
var cpu
var deploy
var equipment_defs: Array:
    get: return equip.defs

func _init(seed: int = 2222) -> void:
    rng = SeededRngScript.new(seed)
    event_log = EventLogScript.new()
    equip = EquipReg.new()
    arena = ArenaGeo.new(self)
    roul = RoulBuf.new(self)
    crate = CratePk.new(self)
    mov = HeroMov.new(self)
    proj = ProjHit.new(self)
    dmg = DmgSys.new(self)
    ult_animal = UltAnimal.new(self)
    ult_effect = UltEffect.new(self)
    act_item = ActItem.new(self)
    lifecycle = MatchLife.new(self)
    tower = MidTowerMod.new(self)
    cpu = CpuBeh.new(self)
    deploy = DeploySys.new(self)
    reset()

func set_mode(next_mode: String) -> void:
    mode = next_mode

func _make_equipment(equipment_id: String) -> Dictionary:
    return equip.make_equipment(equipment_id)

func reset() -> void:
    tick = 0; match_time = 0.0; tower.reset_mid_tower()
    result = &"playing"; winner_slot = -1; result_reason = &""
    decision_hp_ratio = 0.0; decision_core_ratio = 0.0; wanted_slot = -1
    callout = "NO TEAMS. ONLY TEMPORARY CONVENIENCE."; callout_ticks = 210
    impact_ticks = 0; local_hit_shake = 0; local_fire_shake = 0
    local_mouse_kick = Vector2.ZERO; impact_pos = ARENA_CENTER
    last_down_slot = -1; last_down_ticks = 0
    ultimate_focus_slot = -1; ultimate_focus_time = 0.0
    streak_callout = ""; streak_subtitle = ""; streak_callout_ticks = 0; streak_callout_shutdown = false
    start_countdown = START_COUNTDOWN; time_limit_warning_emitted = false
    safe_zone_center = ARENA_CENTER; safe_zone_radius = SAFE_ZONE_INITIAL_RADIUS
    safe_zone_from_radius = SAFE_ZONE_INITIAL_RADIUS
    safe_zone_target_radius = float(SAFE_ZONE_PHASES[0]["radius"])
    safe_zone_phase = 0; safe_zone_phase_time = 0.0; safe_zone_shrinking = false
    safe_zone_complete = false; safe_zone_damage_clock = 0.0
    for arr in [heroes, cores, projectiles, zones, deployables, effects, knockouts, health_pickups, crates, rat_tides, snake_skins, dragon_smokes, tiger_roars, rabbit_holes, horse_kicks, rooster_eggs, pig_muds, dog_bones, crate_orbs]:
        arr.clear()
    covers = arena.build_tiled_covers()
    crate.spawn_breakable_crates()
    var pickup_points := arena.tiled_points(SOURCE_HEALTH_PICKUP_POINTS)
    for i in range(pickup_points.size()):
        var p := {"id":i, "pos":pickup_points[i], "home":pickup_points[i], "magnet_slot":-1, "active":true, "respawn":0.0}
        if mode == ITEM_POOL_MODE: act_item.roll_pickup_kind(p)
        health_pickups.append(p)
    next_entity_id = 100; event_log.clear()
    if mode in NO_LOOT_MODES:
        for i in range(health_pickups.size()):
            health_pickups[i]["active"] = false; health_pickups[i]["respawn"] = 99999.0
    _reset_heroes()

func _reset_heroes() -> void:
    var order: Array[int] = []
    for i in range(equipment_defs.size()): order.append(i)
    for i in range(order.size() - 1):
        var j: int = rng.rangei(i, order.size() - 1)
        var t := order[i]; order[i] = order[j]; order[j] = t
    for slot in range(PLAYER_COUNT):
        var ang := -PI * 0.5 + TAU * float(slot) / PLAYER_COUNT
        var sd := Vector2.RIGHT.rotated(ang)
        var cp := ARENA_CENTER + Vector2(sd.x * SPAWN_CORE_RADIUS_X, sd.y * SPAWN_CORE_RADIUS_Y)
        var hp2 := ARENA_CENTER + Vector2(sd.x * SPAWN_HERO_RADIUS_X, sd.y * SPAWN_HERO_RADIUS_Y)
        cp = arena.nudge_out_of_cover(arena.clamp_arena_point(cp, CORE_RADIUS), CORE_RADIUS)
        hp2 = arena.nudge_out_of_cover(arena.clamp_arena_point(hp2, HERO_RADIUS), HERO_RADIUS)
        var eid := GunSig.equipment_for_animal(slot)
        if MODE_START_EQUIPMENT.has(mode): eid = str(MODE_START_EQUIPMENT[mode])
        var eq := _make_equipment(eid)
        var mhp := float(eq["max_hp"])
        cores.append({"slot":slot,"pos":cp,"hp":CORE_MAX_HP,"max_hp":CORE_MAX_HP,"alive":true})
        var face := hp2.direction_to(ARENA_CENTER)
        heroes.append({"slot":slot,"animal":slot,"muzzle_time":0.0,"muzzle_row":0,"pos":hp2,"vel":Vector2.ZERO,"aim":face,"facing":face,"hp":mhp,"max_hp":mhp,"alive":true,"eliminated":false,"respawn":0.0,"respawn_left":0.0,"revives_used":0,"spawn_pos":hp2,"fire_cd":rng.rangef(0.0,0.2),"equipment_cd":0.0,"mobility_cd":0.0,"ultimate_charge":0.0,"normal_hits":0,"equipment_hits":0,"ultimates":0,"threat":0.0,"bounty":0.0,"target":-1,"target_hold":0.0,"think":0.12+slot*0.025,"action":&"HARASS","equipment":eq,"recent_attacker":-1,"grudge":0.0,"kills":0,"deaths":0,"medkits":0,"held_item":"","slide_time":0.0,"pull_time":0.0,"pocket_time":0.0,"spring_time":0.0,"hop_height":HOP_LIFT_DEFAULT,"slide_wish":Vector2.ZERO,"kill_streak":0,"best_kill_streak":0,"eliminations":0,"damage_dealt":0.0,"core_damage":0.0,"score":0.0,"cc_time":0.0,"root_time":0.0,"stun_time":0.0,"wall_hit_cd":0.0,"guard_time":0.0,"super_armor_time":0.0,"super_armor_strength":0.0,"launch_vel":Vector2.ZERO,"launch_time":0.0,"wall_bounces":0,"launch_owner":-1,"launch_trail":[],"launch_trail_fade":0.0,"launch_wall_damage":0.0,"hitstun_time":0.0,"combo_hits":0,"combo_time":0.0,"combo_damage":0.0,"combo_owner":-1,"combo_immunity":0.0,"combo_capture_time":0.0,"combo_target":-1,"evade_time":0.0,"normal_step":0,"burst_left":2,"mag":int(eq.get("mag_size",1)),"reload_left":0.0,"reload_flash":0.0,"spray_index":0.0,"spray_idle":0.0,"hit_flash":0.0,"normal_chain_time":0.0,"normal_interval":0.0,"attack_lock_time":0.0,"charging_skill":false,"charge_time":0.0,"charge_dir":hp2.direction_to(ARENA_CENTER),"cpu_charge_target":0.0,"hop_time":0.0,"hop_lock":0.0,"hop_max":HOP_AIR,"dmg_orb_time":0.0,"crate_target":-1,"spawn_protect_time":0.0,"life_hitters":[],"life_hits":{},"rl_until":{"atk":0.0,"spd":0.0,"def":0.0,"hp":0.0,"rate":0.0,"range":0.0},"rl_timed":[],"roulette_time":0.0,"roulette_label":"","roulette_rank":"","roulette_phase":"","roulette_pending":{},"roulette_queue":[],"roulette_faces":[],"ult_clones":[],"ult_clone_time":0.0,"downed":false,"down_left":0.0,"down_taken":0.0,"ox_phase":"","ox_time":0.0,"ox_dir":Vector2.RIGHT,"ox_hit":[],"flee_time":0.0,"flee_from":Vector2.ZERO,"burrowed":false,"burrow_left":0.0,"burrow_exit":Vector2.ZERO,"dog_rush":false,"dog_windup":0.0,"dog_bone":Vector2.ZERO,"dog_hit":[],"wool_time":0.0,"wool_hp":0,"wool_max":5})
        event_log.emit(tick, &"equipment_revealed", slot, -1, {"equipment":eq["id"]})
    event_log.emit(tick, &"match_started", -1, -1, {})

func step_tick(command: Dictionary, dt: float = FIXED_DT) -> void:
    if result != &"playing":
        lifecycle.update_post_match_visuals(dt); return
    tick += 1
    if start_countdown > 0.0:
        start_countdown = maxf(0.0, start_countdown - dt)
        for i in range(heroes.size()): heroes[i]["vel"] = Vector2.ZERO; heroes[i]["action"] = &"READY"
        if start_countdown > 0.0001: return
        start_countdown = 0.0; _announce("GO!", 45)
        event_log.emit(tick, &"combat_started", -1, -1, {})
    match_time += dt
    if not time_limit_warning_emitted and MATCH_TIME_LIMIT - match_time <= 10.0:
        time_limit_warning_emitted = true; _announce("10 SECONDS TO HP DECISION", 90)
        event_log.emit(tick, &"time_limit_warning", -1, -1, {"remaining":10.0})
    if match_time >= MATCH_TIME_LIMIT:
        match_time = MATCH_TIME_LIMIT; lifecycle.resolve_time_limit(); return
    lifecycle.update_timers(dt); act_item.update_item_pulses(dt); lifecycle.update_safe_zone(dt)
    mov.apply_human(command); mov.apply_peer_humans()
    ult_effect.tick_finish_cine(command, dt); cpu.update_cpus(dt)
    ult_animal.tick_ox_charges(dt); ult_animal.apply_rat_tides(dt); ult_animal.tick_snake_skins(dt)
    ult_animal.tick_dragon_smokes(dt); ult_animal.tick_tiger_roars(dt); ult_animal.tick_rabbit_burrows(dt)
    ult_animal.tick_horse_kicks(dt); ult_animal.tick_dog_rush(dt)
    mov.move_heroes(dt)
    ult_animal.tick_rooster_eggs(dt); ult_animal.tick_pig_muds(dt); ult_effect.tick_wool_shields(dt)
    lifecycle.tick_downs(dt); ult_effect.sync_ult_clones(dt)
    crate.update_health_pickups(dt); crate.update_crate_orbs(dt)
    lifecycle.update_respawns(dt); mov.update_knockouts(dt); act_item.update_deployables(dt)
    tower.update_mid_tower(dt)
    proj.update_projectiles(dt); proj.update_zones(dt); proj.update_effects(dt)
    lifecycle.update_threat(dt); lifecycle.check_end()

func _target_valid(slot: int) -> bool:
    return slot >= 0 and slot < PLAYER_COUNT and bool(heroes[slot]["alive"]) and not bool(heroes[slot]["eliminated"])
func _target_position(slot: int) -> Vector2:
    return Vector2(heroes[slot]["pos"])
func _core_hp(slot: int) -> float:
    return float(cores[slot]["hp"])
func _core_exposed(slot: int) -> bool:
    if slot < 0 or slot >= heroes.size() or not bool(cores[slot]["alive"]): return false
    var o: Dictionary = heroes[slot]
    return not bool(o["alive"]) or float(o["cc_time"]) > 0.0 or float(o["root_time"]) > 0.0 or float(o["stun_time"]) > 0.0
func _announce(text: String, ticks: int) -> void:
    callout = text; callout_ticks = ticks
func _begin_skill_charge(_s: int, _d: Vector2) -> void: return
func _continue_skill_charge(_s: int, _d: float, _v: Vector2) -> void: return
func _release_skill_charge(_s: int, _d: Vector2) -> void: return
func _cancel_finish_cine() -> void: finish_cine = {}
func _wool_shield_pos(h: Dictionary) -> Vector2: return Vector2(h["pos"])
func _ultimate_armor(_e: String) -> Dictionary: return {"duration":0.0,"strength":0.0}
func _note_life_hitter(target: int, owner: int) -> void: lifecycle.note_life_damage(target, owner, 1.0)
func hero_hidden_in_smoke(slot: int) -> bool: return ult_animal.hero_hidden_in_smoke(slot)
func local_is_dragon() -> bool: return ult_animal.local_is_dragon()
func _pos_in_dragon_smoke(pos: Vector2) -> bool: return ult_animal.pos_in_dragon_smoke(pos)
func final_standings() -> Array[Dictionary]: return lifecycle.final_standings()

func summary() -> Dictionary:
    var alive := 0; var core_hps: Array[float] = []; var ult_uses := 0; var eq_hits := 0
    for h in heroes:
        if not bool(h["eliminated"]): alive += 1
        ult_uses += int(h["ultimates"]); eq_hits += int(h["equipment_hits"])
    for c in cores: core_hps.append(maxf(0.0, float(c["hp"])))
    return {"tick":tick,"time":match_time,"time_limit":MATCH_TIME_LIMIT,"alive":alive,"winner":winner_slot,"result":result,"result_reason":result_reason,"decision_hp_ratio":decision_hp_ratio,"decision_core_ratio":decision_core_ratio,"projectiles":projectiles.size(),"start_countdown":start_countdown,"core_hps":core_hps,"ultimate_uses":ult_uses,"equipment_hits":eq_hits,"safe_zone_radius":safe_zone_radius,"safe_zone_target":safe_zone_target_radius,"safe_zone_shrinking":safe_zone_shrinking,"mode":mode}

func leaderboard() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for slot in range(heroes.size()):
        var h: Dictionary = heroes[slot]
        rows.append({"slot":slot,"score":float(h["score"]),"kills":int(h["kills"]),"deaths":int(h["deaths"]),"streak":int(h.get("kill_streak",0)),"best_streak":int(h.get("best_kill_streak",0)),"eliminations":int(h["eliminations"]),"damage":float(h["damage_dealt"]),"core_damage":float(h["core_damage"])})
    rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
    return rows

func has_invalid_numbers() -> bool:
    for h in heroes:
        var p: Vector2 = h["pos"]
        if not is_finite(p.x) or not is_finite(p.y): return true
    return false

func cycle_local_animal(delta: int) -> void:
    if local_slot < 0 or local_slot >= heroes.size() or result != &"playing": return
    var h: Dictionary = heroes[local_slot]
    if not bool(h.get("alive", false)): return
    set_hero_animal(local_slot, posmod(int(h.get("animal", local_slot)) + delta, 12))

func set_hero_animal(slot: int, animal: int) -> void:
    if slot < 0 or slot >= heroes.size(): return
    var h: Dictionary = heroes[slot]; animal = posmod(animal, 12); h["animal"] = animal
    var eid := GunSig.equipment_for_animal(animal); var eq := _make_equipment(eid)
    h["equipment"] = eq; h["max_hp"] = float(eq["max_hp"]); h["hp"] = float(eq["max_hp"])
    h["mag"] = int(eq.get("mag_size", 1)); h["reload_left"] = 0.0; h["fire_cd"] = 0.0
    heroes[slot] = h; _announce("P%d %s" % [slot + 1, str(eq.get("name", eid))], 70)
