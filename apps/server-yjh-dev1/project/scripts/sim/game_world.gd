class_name GangGameWorld
extends RefCounted
const GunSig = preload("res://scripts/sim/gun_signature.gd")

const SeededRngScript = preload("res://scripts/sim/seeded_rng.gd")
const EventLogScript = preload("res://scripts/sim/event_log.gd")

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
const SOURCE_HEALTH_PICKUP_POINTS := [
    Vector2(1400.0, 430.0),
    Vector2(1400.0, 1270.0),
    Vector2(760.0, 850.0),
    Vector2(2040.0, 850.0)
]
const SAFE_ZONE_INITIAL_RADIUS := 3304.0
const SAFE_ZONE_DAMAGE_PER_SEC := 8.0
const SAFE_ZONE_TICK_INTERVAL := 0.50
const SAFE_ZONE_EDGE_BUFFER := 252.0
const SAFE_ZONE_PHASES := [
    {"wait":20.0, "shrink":22.0, "radius":2750.0},
    {"wait":16.0, "shrink":20.0, "radius":2200.0},
    {"wait":14.0, "shrink":18.0, "radius":1700.0},
    {"wait":12.0, "shrink":16.0, "radius":1280.0},
    {"wait":12.0, "shrink":16.0, "radius":900.0}
]

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
const MODE_START_EQUIPMENT := {"gun-semi":"rail", "gun-auto":"burst", "item":"scatter"}
const GUN_LOOT_CHAIN := ["rail", "burst", "scatter", "mortar", "breaker", "bomb", "leech", "blade", "spear", "chain", "shield", "brawler"]

var equipment_defs := [
    {"id":"scatter", "name":"SPAS-12", "normal_name":"PUMP BLAST", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"semi", "normal_damage":33.6, "normal_interval":0.50, "normal_speed":800.0, "normal_range":0.48, "normal_spread":0.12, "normal_projectiles":5, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":24.0, "normal_kind":"pellet", "normal_radius":6.0, "normal_pierce":0, "burst_shots":0, "mag_size":7, "reload_time":1.80, "preferred_range":260.0, "cooldown":99.0, "damage":33.6, "speed":800.0, "range":0.48},
    {"id":"rail", "name":"AWM", "normal_name":"BOLT SHOT", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"bolt", "normal_damage":142.0, "normal_interval":1.22, "normal_speed":1520.0, "normal_range":1.12, "normal_spread":0.006, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":14.0, "normal_kind":"bolt", "normal_radius":5.0, "normal_pierce":3, "burst_shots":0, "mag_size":5, "reload_time":2.40, "preferred_range":560.0, "cooldown":99.0, "damage":142.0, "speed":1520.0, "range":1.12},
    {"id":"mortar", "name":"M79", "normal_name":"RPG", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"gl", "normal_damage":88.0, "normal_interval":1.05, "normal_speed":620.0, "normal_range":0.95, "normal_spread":0.012, "normal_projectiles":1, "normal_splash":120.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":42.0, "normal_kind":"shell", "normal_radius":9.0, "normal_pierce":0, "burst_shots":0, "mag_size":1, "reload_time":1.40, "preferred_range":430.0, "cooldown":99.0, "damage":88.0, "speed":620.0, "range":0.95},
    {"id":"leech", "name":"MP5", "normal_name":"SMG BURST", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"auto", "normal_damage":11.4, "normal_interval":0.095, "normal_speed":980.0, "normal_range":0.42, "normal_spread":0.038, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":5.0, "normal_kind":"bolt", "normal_radius":5.0, "normal_pierce":0, "burst_shots":0, "mag_size":25, "reload_time":1.25, "preferred_range":240.0, "cooldown":99.0, "damage":11.4, "speed":980.0, "range":0.42},
    {"id":"breaker", "name":"RPK", "normal_name":"LMG FIRE", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"auto", "normal_damage":12.2, "normal_interval":0.155, "normal_speed":1020.0, "normal_range":0.82, "normal_spread":0.028, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":8.0, "normal_kind":"bolt", "normal_radius":6.0, "normal_pierce":0, "burst_shots":0, "mag_size":40, "reload_time":2.20, "preferred_range":380.0, "cooldown":99.0, "damage":12.2, "speed":1020.0, "range":0.82},
    {"id":"burst", "name":"GLOCK 18", "normal_name":"AUTO PISTOL", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"auto", "normal_damage":13.26, "normal_interval":0.105, "normal_speed":1000.0, "normal_range":0.44, "normal_spread":0.040, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":5.0, "normal_kind":"bolt", "normal_radius":5.0, "normal_pierce":0, "burst_shots":0, "mag_size":18, "reload_time":1.15, "preferred_range":250.0, "cooldown":99.0, "damage":13.26, "speed":1000.0, "range":0.44},
    {"id":"blade", "name":"THOMPSON", "normal_name":"DRUM FIRE", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"auto", "normal_damage":12.2, "normal_interval":0.125, "normal_speed":910.0, "normal_range":0.58, "normal_spread":0.055, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":6.0, "normal_kind":"bolt", "normal_radius":5.0, "normal_pierce":0, "burst_shots":0, "mag_size":32, "reload_time":1.70, "preferred_range":300.0, "cooldown":99.0, "damage":12.2, "speed":910.0, "range":0.58},
    {"id":"brawler", "name":"M1911", "normal_name":"SEMI PISTOL", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"semi", "normal_damage":46.8, "normal_interval":0.40, "normal_speed":1080.0, "normal_range":0.55, "normal_spread":0.018, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":8.0, "normal_kind":"bolt", "normal_radius":5.0, "normal_pierce":0, "burst_shots":0, "mag_size":7, "reload_time":1.05, "preferred_range":230.0, "cooldown":99.0, "damage":46.8, "speed":1080.0, "range":0.55},
    {"id":"bomb", "name":"DOUBLE BARREL", "normal_name":"TWIN BLAST", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"semi", "normal_damage":27.4, "normal_interval":0.22, "normal_speed":760.0, "normal_range":0.40, "normal_spread":0.16, "normal_projectiles":6, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":28.0, "normal_kind":"pellet", "normal_radius":6.0, "normal_pierce":0, "burst_shots":2, "mag_size":2, "reload_time":1.10, "preferred_range":220.0, "cooldown":99.0, "damage":27.4, "speed":760.0, "range":0.40},
    {"id":"spear", "name":"AK-47", "normal_name":"RIFLE FIRE", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"auto", "normal_damage":13.2, "normal_interval":0.135, "normal_speed":1060.0, "normal_range":0.86, "normal_spread":0.030, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":8.0, "normal_kind":"bolt", "normal_radius":5.0, "normal_pierce":0, "burst_shots":0, "mag_size":30, "reload_time":1.55, "preferred_range":390.0, "cooldown":99.0, "damage":13.2, "speed":1060.0, "range":0.86},
    {"id":"chain", "name":"M4A1", "normal_name":"RIFLE FIRE", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"auto", "normal_damage":11.6, "normal_interval":0.115, "normal_speed":1100.0, "normal_range":0.88, "normal_spread":0.022, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":7.0, "normal_kind":"bolt", "normal_radius":5.0, "normal_pierce":0, "burst_shots":0, "mag_size":30, "reload_time":1.35, "preferred_range":400.0, "cooldown":99.0, "damage":11.6, "speed":1100.0, "range":0.88},
{"id":"shield", "name":"WINCHESTER", "normal_name":"LEVER SHOT", "skill_name":"", "skill_desc":"", "ultimate_name":"", "ultimate_desc":"", "fire_mode":"lever", "normal_damage":70.2, "normal_interval":0.62, "normal_speed":1200.0, "normal_range":0.78, "normal_spread":0.014, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":12.0, "normal_kind":"bolt", "normal_radius":5.0, "normal_pierce":0, "burst_shots":0, "mag_size":8, "reload_time":1.60, "preferred_range":360.0, "cooldown":99.0, "damage":70.2, "speed":1200.0, "range":0.78}
]

func _identity_for_equipment(equipment_id: String) -> Dictionary:
    match equipment_id:
        "scatter": return {"character_name":"REX", "role":"BRAWLER", "badge":"SG"}
        "rail": return {"character_name":"SCOPE", "role":"SNIPER", "badge":"RL"}
        "mortar": return {"character_name":"BOMBI", "role":"CONTROLLER", "badge":"CM"}
        "leech": return {"character_name":"NYX", "role":"DRAINER", "badge":"LC"}
        "breaker": return {"character_name":"BRICK", "role":"VANGUARD", "badge":"BH"}
        "burst": return {"character_name":"ZIP", "role":"HUNTER", "badge":"BR"}
        "blade": return {"character_name":"AKARI", "role":"ASSASSIN", "badge":"KT"}
        "brawler": return {"character_name":"MACK", "role":"STRIKER", "badge":"FK"}
        "bomb": return {"character_name":"MIMI", "role":"SABOTEUR", "badge":"MN"}
        "spear": return {"character_name":"ORIN", "role":"LANCER", "badge":"SP"}
        "chain": return {"character_name":"RIVA", "role":"CONTROLLER", "badge":"CH"}
        _: return {"character_name":"WARD", "role":"FORTIFIER", "badge":"BW"}

func _combat_stats_for_equipment(equipment_id: String) -> Dictionary:
    match equipment_id:
        "scatter": return {"move_speed":432.0, "max_hp":155.0, "weight":1.00, "combo_cap_ratio":0.26, "special_name":"LIGHT FRAME", "special_desc":"fast close-range body"}
        "rail": return {"move_speed":394.0, "max_hp":141.0, "weight":0.88, "combo_cap_ratio":0.27, "special_name":"LIGHT FRAME", "special_desc":"low HP long-range body"}
        "mortar": return {"move_speed":365.0, "max_hp":140.0, "weight":0.92, "combo_cap_ratio":0.26, "special_name":"GLASS FRAME", "special_desc":"slow glass cannon body"}
        "leech": return {"move_speed":419.0, "max_hp":149.0, "weight":0.98, "combo_cap_ratio":0.26, "special_name":"MID FRAME", "special_desc":"average SMG body"}
        "breaker": return {"move_speed":359.0, "max_hp":195.0, "weight":1.34, "combo_cap_ratio":0.24, "special_name":"HEAVY FRAME", "special_desc":"high launch resistance"}
        "burst": return {"move_speed":454.0, "max_hp":137.0, "weight":0.90, "combo_cap_ratio":0.27, "special_name":"LIGHT FRAME", "special_desc":"fast low HP body"}
        "blade": return {"move_speed":478.0, "max_hp":157.0, "weight":0.86, "combo_cap_ratio":0.27, "special_name":"SWIFT FRAME", "special_desc":"fastest body"}
        "brawler": return {"move_speed":440.0, "max_hp":176.0, "weight":1.12, "combo_cap_ratio":0.24, "special_name":"COMEBACK", "special_desc":"12% more damage below half health"}
        "bomb": return {"move_speed":389.0, "max_hp":158.0, "weight":1.04, "combo_cap_ratio":0.26, "special_name":"MID FRAME", "special_desc":"average shotgun body"}
        "spear": return {"move_speed":427.0, "max_hp":204.0, "weight":1.02, "combo_cap_ratio":0.26, "special_name":"TANK FRAME", "special_desc":"high HP rifle body"}
        "chain": return {"move_speed":402.0, "max_hp":164.0, "weight":1.08, "combo_cap_ratio":0.24, "special_name":"MID FRAME", "special_desc":"average rifle body"}
        _: return {"move_speed":340.0, "max_hp":213.0, "weight":1.55, "combo_cap_ratio":0.24, "special_name":"HEAVY FRAME", "special_desc":"slowest high HP body"}

func _mobility_for_equipment(equipment_id: String) -> Dictionary:
    match equipment_id:
        "scatter": return {"mobility_name":"SKIRMISH HOP", "mobility_desc":"fast lateral recoil", "mobility_cooldown":4.2, "mobility_distance":219.0}
        "rail": return {"mobility_name":"SIGHTLINE STEP", "mobility_desc":"short precise sidestep", "mobility_cooldown":4.8, "mobility_distance":190.0}
        "mortar": return {"mobility_name":"BLAST HOP", "mobility_desc":"jump and repel nearby enemies", "mobility_cooldown":5.2, "mobility_distance":201.0}
        "leech": return {"mobility_name":"SHADOW PULL", "mobility_desc":"long slide with a small heal", "mobility_cooldown":5.0, "mobility_distance":247.0}
        "breaker": return {"mobility_name":"IRON MARCH", "mobility_desc":"short armored advance", "mobility_cooldown":4.6, "mobility_distance":167.0}
        "burst": return {"mobility_name":"FLASH CUT", "mobility_desc":"long blink with no attack", "mobility_cooldown":5.5, "mobility_distance":288.0}
        "blade": return {"mobility_name":"SHADOW SHEATH", "mobility_desc":"blink and evade one hit", "mobility_cooldown":3.8, "mobility_distance":305.0}
        "brawler": return {"mobility_name":"WEAVE", "mobility_desc":"short dodge that breaks a combo", "mobility_cooldown":3.6, "mobility_distance":178.0}
        "bomb": return {"mobility_name":"BLAST ROLL", "mobility_desc":"roll away from the live fuse", "mobility_cooldown":4.8, "mobility_distance":219.0}
        "spear": return {"mobility_name":"POLE VAULT", "mobility_desc":"long committed vault", "mobility_cooldown":4.3, "mobility_distance":265.0}
        "chain": return {"mobility_name":"SWING STEP", "mobility_desc":"curve around the captured target", "mobility_cooldown":4.5, "mobility_distance":236.0}
        _: return {"mobility_name":"BRACE STEP", "mobility_desc":"small step with a long guard", "mobility_cooldown":5.0, "mobility_distance":138.0}

func _init(seed: int = 2222) -> void:
    rng = SeededRngScript.new(seed)
    event_log = EventLogScript.new()
    reset()

func set_mode(next_mode: String) -> void:
    mode = next_mode

func _make_equipment(equipment_id: String) -> Dictionary:
    var base: Dictionary = equipment_defs[0]
    for def in equipment_defs:
        if str(def["id"]) == equipment_id:
            base = def
            break
    var equipment: Dictionary = base.duplicate(true)
    var identity := _identity_for_equipment(str(equipment["id"]))
    for key in identity:
        equipment[key] = identity[key]
    var mobility := _mobility_for_equipment(str(equipment["id"]))
    for key in mobility:
        equipment[key] = mobility[key]
    var combat_stats := _combat_stats_for_equipment(str(equipment["id"]))
    for key in combat_stats:
        equipment[key] = combat_stats[key]
    return equipment

func reset() -> void:
    tick = 0
    match_time = 0.0
    _reset_mid_tower()
    result = &"playing"
    winner_slot = -1
    result_reason = &""
    decision_hp_ratio = 0.0
    decision_core_ratio = 0.0
    wanted_slot = -1
    callout = "NO TEAMS. ONLY TEMPORARY CONVENIENCE."
    callout_ticks = 210
    impact_ticks = 0
    local_hit_shake = 0
    local_fire_shake = 0
    local_mouse_kick = Vector2.ZERO
    impact_pos = ARENA_CENTER
    last_down_slot = -1
    last_down_ticks = 0
    ultimate_focus_slot = -1
    ultimate_focus_time = 0.0
    streak_callout = ""
    streak_subtitle = ""
    streak_callout_ticks = 0
    streak_callout_shutdown = false
    start_countdown = START_COUNTDOWN
    time_limit_warning_emitted = false
    safe_zone_center = ARENA_CENTER
    safe_zone_radius = SAFE_ZONE_INITIAL_RADIUS
    safe_zone_from_radius = SAFE_ZONE_INITIAL_RADIUS
    safe_zone_target_radius = float(SAFE_ZONE_PHASES[0]["radius"])
    safe_zone_phase = 0
    safe_zone_phase_time = 0.0
    safe_zone_shrinking = false
    safe_zone_complete = false
    safe_zone_damage_clock = 0.0
    heroes.clear()
    cores.clear()
    projectiles.clear()
    zones.clear()
    deployables.clear()
    effects.clear()
    knockouts.clear()
    health_pickups.clear()
    crates.clear()
    rat_tides.clear()
    snake_skins.clear()
    dragon_smokes.clear()
    tiger_roars.clear()
    rabbit_holes.clear()
    horse_kicks.clear()
    rooster_eggs.clear()
    pig_muds.clear()
    dog_bones.clear()
    crate_orbs.clear()
    covers = _build_tiled_covers()
    _spawn_breakable_crates()
    var pickup_points := _tiled_points(SOURCE_HEALTH_PICKUP_POINTS)
    for pickup_index in range(pickup_points.size()):
        var pickup: Dictionary = {
            "id":pickup_index,
            "pos":pickup_points[pickup_index],
            "home":pickup_points[pickup_index],
            "magnet_slot":-1,
            "active":true,
            "respawn":0.0
        }
        if mode == ITEM_POOL_MODE:
            _roll_pickup_kind(pickup)
        health_pickups.append(pickup)
    next_entity_id = 100
    event_log.clear()
    if mode in NO_LOOT_MODES:
        for pickup_index in range(health_pickups.size()):
            health_pickups[pickup_index]["active"] = false
            health_pickups[pickup_index]["respawn"] = 99999.0
    var equipment_order: Array[int] = []
    for equipment_index in range(equipment_defs.size()):
        equipment_order.append(equipment_index)
    for index in range(equipment_order.size() - 1):
        var swap_index: int = rng.rangei(index, equipment_order.size() - 1)
        var held := equipment_order[index]
        equipment_order[index] = equipment_order[swap_index]
        equipment_order[swap_index] = held
    for slot in range(PLAYER_COUNT):
        var angle := -PI * 0.5 + TAU * float(slot) / PLAYER_COUNT
        var spawn_dir := Vector2.RIGHT.rotated(angle)
        var core_pos := ARENA_CENTER + Vector2(spawn_dir.x * SPAWN_CORE_RADIUS_X, spawn_dir.y * SPAWN_CORE_RADIUS_Y)
        var hero_pos := ARENA_CENTER + Vector2(spawn_dir.x * SPAWN_HERO_RADIUS_X, spawn_dir.y * SPAWN_HERO_RADIUS_Y)
        core_pos = _clamp_arena_point(core_pos, CORE_RADIUS)
        hero_pos = _clamp_arena_point(hero_pos, HERO_RADIUS)
        core_pos = _nudge_out_of_cover(core_pos, CORE_RADIUS)
        hero_pos = _nudge_out_of_cover(hero_pos, HERO_RADIUS)
        var equipment_id := GunSig.equipment_for_animal(slot)
        if MODE_START_EQUIPMENT.has(mode):
            equipment_id = str(MODE_START_EQUIPMENT[mode])
        var equipment := _make_equipment(equipment_id)
        var hero_max_hp := float(equipment["max_hp"])
        cores.append({"slot":slot, "pos":core_pos, "hp":CORE_MAX_HP, "max_hp":CORE_MAX_HP, "alive":true})
        var initial_facing := hero_pos.direction_to(ARENA_CENTER)
        heroes.append({
            "slot":slot,
            "animal":slot,
            "muzzle_time":0.0,
            "muzzle_row":0,
            "pos":hero_pos,
            "vel":Vector2.ZERO,
            "aim":initial_facing,
            "facing":initial_facing,
            "hp":hero_max_hp,
            "max_hp":hero_max_hp,
            "alive":true,
            "eliminated":false,
            "respawn":0.0,
            "respawn_left":0.0,
            "revives_used":0,
            "spawn_pos":hero_pos,
            "fire_cd":rng.rangef(0.0, 0.2),
            "equipment_cd":0.0,
            "mobility_cd":0.0,
            "ultimate_charge":0.0,
            "normal_hits":0,
            "equipment_hits":0,
            "ultimates":0,
            "threat":0.0,
            "bounty":0.0,
            "target":-1,
            "target_hold":0.0,
            "think":0.12 + slot * 0.025,
            "action":&"HARASS",
            "equipment":equipment,
            "recent_attacker":-1,
            "grudge":0.0,
            "kills":0,
            "deaths":0,
            "medkits":0,
            "held_item":"",
            "slide_time":0.0,
            "pull_time":0.0,
            "pocket_time":0.0,
            "spring_time":0.0,
            "hop_height":HOP_LIFT_DEFAULT,
            "slide_wish":Vector2.ZERO,
            "kill_streak":0,
            "best_kill_streak":0,
            "eliminations":0,
            "damage_dealt":0.0,
            "core_damage":0.0,
            "score":0.0,
            "cc_time":0.0,
            "root_time":0.0,
            "stun_time":0.0,
            "wall_hit_cd":0.0,
            "guard_time":0.0,
            "super_armor_time":0.0,
            "super_armor_strength":0.0,
            "launch_vel":Vector2.ZERO,
            "launch_time":0.0,
            "wall_bounces":0,
            "launch_owner":-1,
            "launch_trail":[],
            "launch_trail_fade":0.0,
            "launch_wall_damage":0.0,
            "hitstun_time":0.0,
            "combo_hits":0,
            "combo_time":0.0,
            "combo_damage":0.0,
            "combo_owner":-1,
            "combo_immunity":0.0,
            "combo_capture_time":0.0,
            "combo_target":-1,
            "evade_time":0.0,
            "normal_step":0,
            "burst_left":2,
            "mag":int(equipment.get("mag_size", 1)),
            "reload_left":0.0,
            "reload_flash":0.0,
            "spray_index":0.0,
            "spray_idle":0.0,
            "hit_flash":0.0,
            "normal_chain_time":0.0,
            "normal_interval":0.0,
            "attack_lock_time":0.0,
            "charging_skill":false,
            "charge_time":0.0,
            "charge_dir":hero_pos.direction_to(ARENA_CENTER),
            "cpu_charge_target":0.0,
            "hop_time":0.0,
            "hop_lock":0.0,
            "hop_max":HOP_AIR,
            "dmg_orb_time":0.0,
            "crate_target":-1,
            "spawn_protect_time":0.0,
            "life_hitters":[],
            "life_hits":{},
            "rl_until":{"atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0},
            "rl_timed":[],
            "roulette_time":0.0,
            "roulette_label":"",
            "roulette_rank":"",
            "roulette_phase":"",
            "roulette_pending":{},
            "roulette_queue":[],
            "roulette_faces":[],
            "ult_clones":[],
            "ult_clone_time":0.0,
            "downed":false,
            "down_left":0.0,
            "down_taken":0.0,
            "ox_phase":"",
            "ox_time":0.0,
            "ox_dir":Vector2.RIGHT,
            "ox_hit":[],
            "flee_time":0.0,
            "flee_from":Vector2.ZERO,
            "burrowed":false,
            "burrow_left":0.0,
            "burrow_exit":Vector2.ZERO,
            "dog_rush":false,
            "dog_windup":0.0,
            "dog_bone":Vector2.ZERO,
            "dog_hit":[],
            "wool_time":0.0,
            "wool_hp":0,
            "wool_max":5
        })
        event_log.emit(tick, &"equipment_revealed", slot, -1, {"equipment":equipment["id"]})
    event_log.emit(tick, &"match_started", -1, -1, {})

func step_tick(command: Dictionary, dt: float = FIXED_DT) -> void:
    if result != &"playing":
        _update_post_match_visuals(dt)
        return
    tick += 1
    if start_countdown > 0.0:
        start_countdown = maxf(0.0, start_countdown - dt)
        for index in range(heroes.size()):
            var waiting_hero: Dictionary = heroes[index]
            waiting_hero["vel"] = Vector2.ZERO
            waiting_hero["action"] = &"READY"
            heroes[index] = waiting_hero
        if start_countdown > 0.0001:
            return
        start_countdown = 0.0
        _announce("GO!", 45)
        event_log.emit(tick, &"combat_started", -1, -1, {})
    match_time += dt
    if not time_limit_warning_emitted and MATCH_TIME_LIMIT - match_time <= 10.0:
        time_limit_warning_emitted = true
        _announce("10 SECONDS TO HP DECISION", 90)
        event_log.emit(tick, &"time_limit_warning", -1, -1, {"remaining":10.0})
    if match_time >= MATCH_TIME_LIMIT:
        match_time = MATCH_TIME_LIMIT
        _resolve_time_limit()
        return
    _update_timers(dt)
    _update_item_pulses(dt)
    _update_safe_zone(dt)
    _apply_human(command)
    _update_cpus(dt)
    _tick_ox_charges(dt)
    _apply_rat_tides(dt)
    _tick_snake_skins(dt)
    _tick_dragon_smokes(dt)
    _tick_tiger_roars(dt)
    _tick_rabbit_burrows(dt)
    _tick_horse_kicks(dt)
    _tick_dog_rush(dt)
    _move_heroes(dt)
    _tick_rooster_eggs(dt)
    _tick_pig_muds(dt)
    _tick_wool_shields(dt)
    _tick_downs(dt)
    _sync_ult_clones(dt)
    _update_health_pickups(dt)
    _update_crate_orbs(dt)
    _update_respawns(dt)
    _update_knockouts(dt)
    _update_deployables(dt)
    _update_mid_tower(dt)
    _update_projectiles(dt)
    _update_zones(dt)
    _update_effects(dt)
    _update_threat(dt)
    _check_end()

func _update_post_match_visuals(dt: float) -> void:
    tick += 1
    callout_ticks = maxi(0, callout_ticks - 1)
    impact_ticks = maxi(0, impact_ticks - 1)
    local_hit_shake = maxi(0, local_hit_shake - 1)
    local_fire_shake = maxi(0, local_fire_shake - 1)
    last_down_ticks = maxi(0, last_down_ticks - 1)
    streak_callout_ticks = maxi(0, streak_callout_ticks - 1)
    ultimate_focus_time = maxf(0.0, ultimate_focus_time - dt)
    if ultimate_focus_time <= 0.0:
        ultimate_focus_slot = -1
    for index in range(heroes.size()):
        var hero: Dictionary = heroes[index]
        hero["launch_time"] = 0.0
        hero["launch_vel"] = Vector2.ZERO
        hero["launch_trail_fade"] = maxf(0.0, float(hero.get("launch_trail_fade", 0.0)) - dt)
        if float(hero["launch_trail_fade"]) <= 0.0:
            hero["launch_trail"] = []
        heroes[index] = hero
    _update_knockouts(dt)
    _update_effects(dt)

func _settle_match_visuals() -> void:
    projectiles.clear()
    zones.clear()
    deployables.clear()
    ultimate_focus_slot = -1
    ultimate_focus_time = 0.0
    for index in range(heroes.size()):
        var hero: Dictionary = heroes[index]
        hero["vel"] = Vector2.ZERO
        hero["charging_skill"] = false
        hero["charge_time"] = 0.0
        heroes[index] = hero

func _update_timers(dt: float) -> void:
    callout_ticks = maxi(0, callout_ticks - 1)
    impact_ticks = maxi(0, impact_ticks - 1)
    local_hit_shake = maxi(0, local_hit_shake - 1)
    local_fire_shake = maxi(0, local_fire_shake - 1)
    last_down_ticks = maxi(0, last_down_ticks - 1)
    streak_callout_ticks = maxi(0, streak_callout_ticks - 1)
    ultimate_focus_time = maxf(0.0, ultimate_focus_time - dt)
    if ultimate_focus_time <= 0.0:
        ultimate_focus_slot = -1
    for i in range(heroes.size()):
        var h: Dictionary = heroes[i]
        h["fire_cd"] = maxf(0.0, float(h["fire_cd"]) - dt)
        h["spray_idle"] = float(h.get("spray_idle", 0.0)) + dt
        if float(h["spray_idle"]) > 0.14:
            var eqd: Dictionary = h["equipment"]
            var eq_id := str(eqd.get("id", "burst"))
            h["spray_index"] = maxf(0.0, float(h.get("spray_index", 0.0)) - dt * GunSig.spray_recover_rate(eq_id))
        h["equipment_cd"] = maxf(0.0, float(h["equipment_cd"]) - dt)
        h["mobility_cd"] = maxf(0.0, float(h["mobility_cd"]) - dt)
        var previous_hop: float = float(h.get("hop_time", 0.0))
        h["hop_time"] = maxf(0.0, previous_hop - dt)
        if previous_hop > 0.0 and float(h["hop_time"]) <= 0.0:
            h["hop_lock"] = HOP_LOCK
        else:
            h["hop_lock"] = maxf(0.0, float(h.get("hop_lock", 0.0)) - dt)
        h["guard_time"] = maxf(0.0, float(h["guard_time"]) - dt)
        h["super_armor_time"] = maxf(0.0, float(h["super_armor_time"]) - dt)
        if float(h["super_armor_time"]) <= 0.0:
            h["super_armor_strength"] = 0.0
        h["evade_time"] = maxf(0.0, float(h["evade_time"]) - dt)
        h["slide_time"] = maxf(0.0, float(h.get("slide_time", 0.0)) - dt)
        h["pull_time"] = maxf(0.0, float(h.get("pull_time", 0.0)) - dt)
        h["pocket_time"] = maxf(0.0, float(h.get("pocket_time", 0.0)) - dt)
        h["spring_time"] = maxf(0.0, float(h.get("spring_time", 0.0)) - dt)
        h["hitstun_time"] = maxf(0.0, float(h["hitstun_time"]) - dt)
        if float(h["launch_time"]) > 0.0:
            h["launch_trail_fade"] = 0.34
        else:
            h["launch_trail_fade"] = maxf(0.0, float(h.get("launch_trail_fade", 0.0)) - dt)
            if float(h["launch_trail_fade"]) <= 0.0:
                h["launch_trail"] = []
        h["combo_capture_time"] = maxf(0.0, float(h["combo_capture_time"]) - dt)
        h["attack_lock_time"] = maxf(0.0, float(h["attack_lock_time"]) - dt)
        var previous_normal_chain := float(h["normal_chain_time"])
        h["normal_chain_time"] = maxf(0.0, previous_normal_chain - dt)
        if previous_normal_chain > 0.0 and float(h["normal_chain_time"]) <= 0.0:
            h["normal_step"] = 0
            h["combo_target"] = -1
        h["combo_immunity"] = maxf(0.0, float(h["combo_immunity"]) - dt)
        var previous_combo_time := float(h["combo_time"])
        h["combo_time"] = maxf(0.0, previous_combo_time - dt)
        if previous_combo_time > 0.0 and float(h["combo_time"]) <= 0.0:
            h["combo_hits"] = 0
            h["combo_damage"] = 0.0
            h["combo_owner"] = -1
            h["combo_immunity"] = maxf(float(h["combo_immunity"]), 0.58)
        h["target_hold"] = maxf(0.0, float(h["target_hold"]) - dt)
        h["cc_time"] = maxf(0.0, float(h["cc_time"]) - dt)
        h["root_time"] = maxf(0.0, float(h["root_time"]) - dt)
        h["stun_time"] = maxf(0.0, float(h["stun_time"]) - dt)
        h["flee_time"] = maxf(0.0, float(h.get("flee_time", 0.0)) - dt)
        h["wall_hit_cd"] = maxf(0.0, float(h["wall_hit_cd"]) - dt)
        if not bool(h["alive"]) or float(h["stun_time"]) > 0.0 or float(h["launch_time"]) > 0.0:
            h["reload_left"] = 0.0
        elif float(h.get("reload_left", 0.0)) > 0.0:
            h["reload_left"] = maxf(0.0, float(h["reload_left"]) - dt)
            if float(h["reload_left"]) <= 0.0:
                var mag_cap := int(h["equipment"].get("mag_size", 1))
                h["mag"] = mag_cap
                h["reload_flash"] = 0.55
                h["action"] = &"RELOADED"
        h["reload_flash"] = maxf(0.0, float(h.get("reload_flash", 0.0)) - dt)
        h["hit_flash"] = maxf(0.0, float(h.get("hit_flash", 0.0)) - dt)
        h["muzzle_time"] = maxf(0.0, float(h.get("muzzle_time", 0.0)) - dt)
        h["dmg_orb_time"] = maxf(0.0, float(h.get("dmg_orb_time", 0.0)) - dt)
        h["spawn_protect_time"] = maxf(0.0, float(h.get("spawn_protect_time", 0.0)) - dt)
        heroes[i] = h
        _tick_roulette(i, dt)
        h = heroes[i]

func _apply_human(command: Dictionary) -> void:
    if heroes.is_empty():
        return
    var h: Dictionary = heroes[0]
    if bool(h["eliminated"]):
        heroes[0] = h
        return
    if not bool(h["alive"]):
        heroes[0] = h
        return
    if bool(h.get("burrowed", false)):
        h["vel"] = Vector2.ZERO
        heroes[0] = h
        return
    if bool(h.get("dog_rush", false)):
        heroes[0] = h
        if bool(command.get("ultimate", false)):
            _try_ultimate(0, Vector2(command.get("aim", Vector2(h["pos"]) + Vector2(h["facing"]))))
        return
    if bool(h.get("downed", false)):
        var crawl: Vector2 = command.get("move", Vector2.ZERO)
        if crawl.length_squared() > 1.0:
            crawl = crawl.normalized()
        h["vel"] = crawl * _hero_move_speed(0) * 0.16
        heroes[0] = h
        return
    if float(h["launch_time"]) > 0.0:
        h["vel"] = Vector2.ZERO
        heroes[0] = h
        return
    var move: Vector2 = command.get("move", Vector2.ZERO)
    if move.length_squared() > 1.0:
        move = move.normalized()
    var aim_pos: Vector2 = command.get("aim", Vector2(h["pos"]) + Vector2(h["facing"]))
    if Vector2(h["pos"]).distance_squared_to(aim_pos) > 4.0:
        h["facing"] = Vector2(h["pos"]).direction_to(aim_pos)
        h["aim"] = h["facing"]
    var control_speed := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
    if float(h["root_time"]) > 0.0:
        control_speed = 0.0
    if float(h["stun_time"]) > 0.0:
        h["vel"] = Vector2.ZERO
        h["charging_skill"] = false
        h["charge_time"] = 0.0
        heroes[0] = h
        return
    if float(h["hitstun_time"]) > 0.0:
        control_speed *= 0.72
    elif float(h["combo_capture_time"]) > 0.0:
        control_speed *= 0.72
    if float(h["attack_lock_time"]) > 0.0:
        control_speed *= 0.76
    if bool(h["charging_skill"]):
        control_speed *= 0.62
    if float(h.get("slide_time", 0.0)) > 0.0:
        _steer_slide(0, h, move, control_speed, FIXED_DT)
    else:
        var cruise: Vector2 = move * _hero_move_speed(0) * control_speed * _streak_move_multiplier(0)
        h["vel"] = cruise
        if float(h.get("spring_time", 0.0)) > 0.0:
            var boost_dir: Vector2 = move
            if boost_dir.length_squared() < 0.1:
                boost_dir = Vector2(h["facing"])
            if boost_dir.length_squared() > 0.1:
                var boosted: Vector2 = Vector2(h["vel"]) + boost_dir.normalized() * SPRING_BOOST
                h["vel"] = boosted
    if bool(command.get("hop", false)) and not _hero_has_timed(h, "turtle"):
        var hop_ready: bool = float(h.get("hop_time", 0.0)) <= 0.0 and float(h.get("hop_lock", 0.0)) <= 0.0
        if hop_ready and float(h["root_time"]) <= 0.0:
            h["hop_time"] = HOP_AIR
            h["hop_max"] = HOP_AIR
            h["hop_height"] = HOP_LIFT_DEFAULT
    heroes[0] = h
    if bool(command.get("medkit", false)) and not _hero_has_timed(h, "turtle"):
        _try_use_active_item(0)
    if bool(command.get("ultimate", false)) and not _hero_has_timed(h, "turtle"):
        _try_ultimate(0, Vector2(command.get("aim", Vector2(h["pos"]) + Vector2(h["facing"]))))
        h = heroes[0]
    if bool(command.get("mobility", false)) and not _hero_has_timed(h, "turtle"):
        _cancel_skill_charge(0)
        _try_mobility(0, move if move.length_squared() > 0.1 else Vector2(h["facing"]))
        return
    if bool(command.get("reload", false)) and not _hero_has_timed(h, "turtle"):
        _try_start_reload(0)
        h = heroes[0]
    var fire_mode := str(h["equipment"].get("fire_mode", "auto"))
    var want_fire := bool(command.get("primary", false))
    if fire_mode != "auto":
        want_fire = bool(command.get("primary_pressed", false))
    if want_fire:
        _cancel_skill_charge(0)
        _try_normal_attack(0, Vector2(h["facing"]))
        return

func _update_cpus(dt: float) -> void:
    for slot in range(1, heroes.size()):
        var h: Dictionary = heroes[slot]
        if bool(h["eliminated"]):
            continue
        if not bool(h["alive"]):
            continue
        if bool(h.get("downed", false)):
            h["vel"] = Vector2.ZERO
            h["action"] = &"DOWN"
            heroes[slot] = h
            continue
        if float(h["stun_time"]) > 0.0:
            h["vel"] = Vector2.ZERO
            h["charging_skill"] = false
            h["charge_time"] = 0.0
            h["action"] = &"STUNNED"
            heroes[slot] = h
            continue
        if float(h["combo_capture_time"]) > 0.0:
            h["vel"] = Vector2.ZERO
            heroes[slot] = h
            if float(h["hitstun_time"]) <= 0.0:
                if float(h["mobility_cd"]) <= 0.0 and rng.chance(0.055):
                    _try_mobility(slot, -Vector2(h["facing"]))
                    h = heroes[slot]
        if mode == ITEM_POOL_MODE:
            _cpu_consider_held_item(slot)
            h = heroes[slot]
        elif int(h.get("medkits", 0)) > 0 and float(h["hp"]) < float(h["max_hp"]) * 0.5 and rng.chance(0.30):
            _try_use_medkit(slot)
            h = heroes[slot]
        if float(h.get("slide_time", 0.0)) > 0.0:
            var slide_wish: Vector2 = h.get("slide_wish", Vector2.ZERO)
            if slide_wish.length_squared() < 0.01:
                slide_wish = Vector2(h["facing"])
            var slide_scale := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
            if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 or float(h["root_time"]) > 0.0:
                slide_scale = 0.0
            _steer_slide(slot, h, slide_wish, slide_scale, dt)
            heroes[slot] = h
        h["think"] = float(h["think"]) - dt
        if float(h["think"]) <= 0.0:
            h["think"] = 0.16 + rng.rangef(0.0, 0.10)
            var old_target := int(h["target"])
            var target := _choose_target(slot)
            if float(h["target_hold"]) <= 0.0 or old_target < 0 or not _target_valid(old_target):
                h["target"] = target
                h["target_hold"] = 0.42 + rng.rangef(0.0, 0.30)
                if old_target >= 0 and old_target != target:
                    event_log.emit(tick, &"target_changed", slot, target, {"from":old_target})
                    if old_target == int(heroes[target]["target"]):
                        event_log.emit(tick, &"betrayal", slot, target, {"previous_target":old_target})
            var heal_index := _best_health_pickup(slot)
            var tslot := int(h["target"])
            var orb_index := _best_crate_orb(slot)
            var crate_index := _best_crate(slot)
            var fight_dist := 99999.0
            if tslot >= 0:
                fight_dist = Vector2(h["pos"]).distance_to(_target_position(tslot))
            if heal_index >= 0:
                var heal_pos: Vector2 = health_pickups[heal_index]["pos"]
                var to_heal := Vector2(h["pos"]).direction_to(heal_pos)
                var heal_strafe := to_heal.orthogonal() * (-1.0 if slot % 2 == 0 else 1.0)
                var heal_move := to_heal
                if _line_blocked(Vector2(h["pos"]), heal_pos):
                    heal_move = (to_heal * 0.38 + heal_strafe).normalized()
                var heal_cc_speed := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
                var heal_hitstun_speed := 0.35 if float(h["root_time"]) > 0.0 else (0.72 if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 else 1.0)
                _apply_cpu_move(slot, h, heal_move, heal_cc_speed * heal_hitstun_speed)
                h["action"] = &"SEEK_HEAL"
                if tslot >= 0:
                    h["aim"] = Vector2(h["pos"]).direction_to(_target_position(tslot)).rotated(rng.rangef(-0.085, 0.085))
                    h["facing"] = h["aim"]
            elif orb_index >= 0 and Vector2(h["pos"]).distance_to(Vector2(crate_orbs[orb_index]["pos"])) < minf(fight_dist, 520.0) and rng.chance(0.55):
                var orb_pos: Vector2 = crate_orbs[orb_index]["pos"]
                var to_orb: Vector2 = Vector2(h["pos"]).direction_to(orb_pos)
                var orb_move: Vector2 = to_orb
                if _line_blocked(Vector2(h["pos"]), orb_pos):
                    orb_move = (to_orb * 0.40 + to_orb.orthogonal()).normalized()
                _apply_cpu_move(slot, h, orb_move, 1.0)
                h["action"] = &"SEEK_ORB"
            elif bool(mid_tower.get("alive", false)) and Vector2(h["pos"]).distance_to(Vector2(mid_tower["pos"])) < minf(fight_dist, 780.0) and rng.chance(0.42):
                var tower_pos: Vector2 = mid_tower["pos"]
                var to_tower: Vector2 = Vector2(h["pos"]).direction_to(tower_pos)
                h["aim"] = to_tower
                h["facing"] = to_tower
                var tower_move: Vector2 = to_tower
                if Vector2(h["pos"]).distance_to(tower_pos) < float(h["equipment"]["preferred_range"]) * 0.62:
                    tower_move = to_tower.orthogonal()
                _apply_cpu_move(slot, h, tower_move, 1.0)
                h["action"] = &"SEEK_TOWER"
            elif crate_index >= 0 and Vector2(h["pos"]).distance_to(Vector2(crates[crate_index]["pos"])) < minf(fight_dist, 460.0) and rng.chance(0.28):
                var crate_pos: Vector2 = crates[crate_index]["pos"]
                var to_crate: Vector2 = Vector2(h["pos"]).direction_to(crate_pos)
                h["crate_target"] = crate_index
                h["aim"] = to_crate
                h["facing"] = to_crate
                var crate_move: Vector2 = to_crate
                if _line_blocked(Vector2(h["pos"]), crate_pos):
                    crate_move = (to_crate * 0.36 + to_crate.orthogonal()).normalized()
                elif Vector2(h["pos"]).distance_to(crate_pos) < float(h["equipment"]["preferred_range"]) * 0.55:
                    crate_move = to_crate.orthogonal()
                _apply_cpu_move(slot, h, crate_move, 1.0)
                h["action"] = &"SEEK_CRATE"
            elif tslot >= 0:
                var target_pos := _target_position(tslot)
                var to_target := Vector2(h["pos"]).direction_to(target_pos)
                var dist := Vector2(h["pos"]).distance_to(target_pos)
                var strafe := to_target.orthogonal() * (-1.0 if slot % 2 == 0 else 1.0)
                var preferred_range := float(h["equipment"]["preferred_range"])
                if str(h["equipment"]["id"]) not in ["scatter", "rail", "burst", "mortar", "bomb"]:
                    preferred_range = minf(preferred_range, _normal_reach(slot) * 0.62)
                var desired := to_target
                if _line_blocked(Vector2(h["pos"]), target_pos):
                    desired = (to_target * 0.35 + strafe).normalized()
                    h["action"] = &"FLANK"
                elif dist < preferred_range * 0.72:
                    desired = (strafe * 0.75 - to_target * 0.25).normalized()
                    h["action"] = &"DISENGAGE"
                elif dist <= preferred_range * 1.15:
                    desired = (strafe * 0.88 + to_target * 0.12).normalized()
                    h["action"] = &"HOLD_RANGE"
                else:
                    desired = (to_target + strafe * 0.20).normalized()
                    h["action"] = &"CLOSE_RANGE"
                var cc_speed := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
                var hitstun_speed := 0.35 if float(h["root_time"]) > 0.0 else (0.72 if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 else 1.0)
                var action_speed := 0.76 if float(h["attack_lock_time"]) > 0.0 else 1.0
                if bool(h["charging_skill"]):
                    action_speed *= 0.62
                _apply_cpu_move(slot, h, desired, cc_speed * hitstun_speed * action_speed * rng.rangef(0.93, 1.02))
                var aim_error: float = rng.rangef(-0.085, 0.085)
                h["aim"] = to_target.rotated(aim_error)
                h["facing"] = h["aim"]
            var hazard_escape := _hazard_escape_vector(slot)
            if hazard_escape.length_squared() > 0.1:
                var hazard_cc_speed := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
                var hazard_lock_speed := 0.35 if float(h["root_time"]) > 0.0 else (0.72 if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 else 1.0)
                _apply_cpu_move(slot, h, hazard_escape, hazard_cc_speed * hazard_lock_speed)
                h["action"] = &"DODGE_WARNING"
        heroes[slot] = h
        var current_target := int(h["target"])
        if current_target >= 0 and _target_valid(current_target):
            var target_pos := _target_position(current_target)
            var dist := Vector2(h["pos"]).distance_to(target_pos)
            var clear_shot := not _line_blocked(Vector2(h["pos"]), target_pos)
            if h["action"] != &"SEEK_HEAL" and float(h["mobility_cd"]) <= 0.0 and float(h["launch_time"]) <= 0.0 and (dist > float(h["equipment"]["preferred_range"]) * 1.35 or dist < float(h["equipment"]["preferred_range"]) * 0.48) and rng.chance(0.025):
                var mobility_dir := Vector2(h["vel"]).normalized()
                if mobility_dir.length_squared() < 0.1:
                    mobility_dir = Vector2(h["pos"]).direction_to(target_pos)
                _try_mobility(slot, mobility_dir)
                h = heroes[slot]
            if dist < _normal_reach(slot) and clear_shot and float(h["fire_cd"]) <= 0.0:
                _try_normal_attack(slot, Vector2(h["aim"]))
            h = heroes[slot]
        if h["action"] == &"SEEK_TOWER" and float(h["fire_cd"]) <= 0.0 and bool(mid_tower.get("alive", false)):
            var tpos: Vector2 = mid_tower["pos"]
            if Vector2(h["pos"]).distance_to(tpos) < _normal_reach(slot):
                _try_normal_attack(slot, Vector2(h["pos"]).direction_to(tpos))
        if h["action"] == &"SEEK_CRATE" and float(h["fire_cd"]) <= 0.0:
            var aim_crate := int(h.get("crate_target", -1))
            if aim_crate >= 0 and aim_crate < crates.size() and bool(crates[aim_crate]["alive"]):
                var crate_aim_pos: Vector2 = crates[aim_crate]["pos"]
                if Vector2(h["pos"]).distance_to(crate_aim_pos) < _normal_reach(slot) and not _line_blocked(Vector2(h["pos"]), crate_aim_pos):
                    _try_normal_attack(slot, Vector2(h["pos"]).direction_to(crate_aim_pos))
                    h = heroes[slot]

func _choose_target(slot: int) -> int:
    var best := -1
    var best_score := -999.0
    var attacker_counts := PackedInt32Array()
    attacker_counts.resize(PLAYER_COUNT)
    for other in heroes:
        var t := int(other["target"])
        if t >= 0 and t < PLAYER_COUNT:
            attacker_counts[t] += 1
    var valid_target_count := 0
    for candidate in range(PLAYER_COUNT):
        if candidate != slot and _target_valid(candidate):
            valid_target_count += 1
    for target in range(PLAYER_COUNT):
        if target == slot or not _target_valid(target):
            continue
        if valid_target_count >= 3 and attacker_counts[target] >= 2:
            continue
        var target_h: Dictionary = heroes[target]
        var distance := Vector2(heroes[slot]["pos"]).distance_to(_target_position(target))
        var leader_value := clampf(float(target_h["threat"]) / 180.0, 0.0, 1.0)
        var finishability := clampf((float(target_h["max_hp"]) - float(target_h["hp"])) / maxf(1.0, float(target_h["max_hp"])), 0.0, 1.0)
        var dogpile := 1.0 if attacker_counts[target] == 1 else 0.0
        var crowd_penalty := maxf(0.0, float(attacker_counts[target] - 1)) * 0.42
        var retaliation := clampf(float(target_h["threat"]) / 150.0, 0.0, 1.0)
        var grudge := 1.0 if int(heroes[slot]["recent_attacker"]) == target else 0.0
        var score := 0.26 * leader_value + 0.28 * finishability
        score += 0.13 * clampf(float(target_h["threat"]) / 120.0, 0.0, 1.0)
        score += 0.11 * grudge + 0.10 * dogpile + 0.06 * clampf(float(target_h["bounty"]) / 80.0, 0.0, 1.0)
        score -= crowd_penalty + 0.18 * retaliation + 0.15 * clampf(distance / 1260.0, 0.0, 1.0)
        score += rng.rangef(-0.025, 0.025)
        if score > best_score:
            best_score = score
            best = target
    return best

func _best_health_pickup(slot: int) -> int:
    var h: Dictionary = heroes[slot]
    var health_ratio := float(h["hp"]) / maxf(1.0, float(h["max_hp"]))
    var empty_hand := mode == ITEM_POOL_MODE and str(h.get("held_item", "")) == ""
    if health_ratio > 0.65 and not empty_hand:
        return -1
    var search_radius := 700.0
    if empty_hand:
        search_radius = 980.0
    if health_ratio <= 0.48:
        search_radius = 1190.0
    if health_ratio <= 0.30:
        search_radius = 1750.0
    var best_index := -1
    var best_distance := search_radius
    for pickup_index in range(health_pickups.size()):
        var pickup: Dictionary = health_pickups[pickup_index]
        if not bool(pickup["active"]):
            continue
        var distance := Vector2(h["pos"]).distance_to(Vector2(pickup["pos"]))
        if distance >= search_radius:
            continue
        var score_distance := distance
        if _is_signature_floor_gun(slot, pickup):
            score_distance = maxf(0.0, distance - 140.0)
        if score_distance < best_distance:
            best_distance = score_distance
            best_index = pickup_index
    return best_index

func _is_signature_floor_gun(slot: int, pickup: Dictionary) -> bool:
    var equip_id := str(pickup.get("equipment", pickup.get("gun_id", "")))
    if equip_id == "":
        return false
    return GunSig.is_signature(slot, equip_id)

func _hazard_escape_vector(slot: int) -> Vector2:
    if slot < 0 or slot >= heroes.size() or not bool(heroes[slot]["alive"]):
        return Vector2.ZERO
    var hero_pos: Vector2 = heroes[slot]["pos"]
    var escape := Vector2.ZERO
    for zone in zones:
        if int(zone["owner"]) == slot or bool(zone.get("applied", false)) or float(zone.get("delay", 0.0)) <= 0.0:
            continue
        var danger_pos: Vector2 = zone["pos"]
        var danger_radius := float(zone["radius"]) + HERO_RADIUS + 65.0
        var distance := hero_pos.distance_to(danger_pos)
        if distance >= danger_radius:
            continue
        var away := danger_pos.direction_to(hero_pos)
        if away.length_squared() < 0.1:
            away = Vector2(heroes[int(zone["owner"])]["pos"]).direction_to(hero_pos)
        if away.length_squared() < 0.1:
            away = Vector2.RIGHT.rotated(float(slot) * 1.7)
        var warning_duration := maxf(0.01, float(zone.get("warning_duration", zone.get("delay", 0.01))))
        var urgency := 1.0 - clampf(float(zone["delay"]) / warning_duration, 0.0, 1.0)
        escape += away * (1.0 - distance / danger_radius + urgency * 1.25)
    for projectile in projectiles:
        if int(projectile["owner"]) == slot or not bool(projectile.get("arc", false)):
            continue
        var danger_pos: Vector2 = projectile["landing_pos"]
        var danger_radius := float(projectile["splash"]) + HERO_RADIUS + 65.0
        var distance := hero_pos.distance_to(danger_pos)
        if distance >= danger_radius:
            continue
        var away := danger_pos.direction_to(hero_pos)
        if away.length_squared() < 0.1:
            away = Vector2(heroes[int(projectile["owner"])]["pos"]).direction_to(hero_pos)
        if away.length_squared() < 0.1:
            away = Vector2.DOWN.rotated(float(slot) * 1.3)
        var flight_duration := maxf(0.01, float(projectile.get("max_ttl", projectile.get("ttl", 0.01))))
        var urgency := 1.0 - clampf(float(projectile["ttl"]) / flight_duration, 0.0, 1.0)
        escape += away * (1.0 - distance / danger_radius + urgency * 1.25)
    for mine in deployables:
        if int(mine["owner"]) == slot:
            continue
        if StringName(mine.get("type", &"mine")) == &"wall":
            var wall_forward := Vector2(mine.get("travel_direction", Vector2.RIGHT)).normalized()
            var wall_side := Vector2(mine["direction"]).normalized()
            var relative := hero_pos - Vector2(mine["pos"])
            var forward_distance := relative.dot(wall_forward)
            var side_distance := absf(relative.dot(wall_side))
            var remaining_sweep := float(mine.get("speed", 0.0)) * float(mine.get("lifetime", 0.0))
            if forward_distance >= -HERO_RADIUS and forward_distance <= minf(remaining_sweep, 480.0) + HERO_RADIUS and side_distance <= float(mine["half_length"]) + HERO_RADIUS + 45.0:
                var dodge_side := wall_side * (1.0 if relative.dot(wall_side) >= 0.0 else -1.0)
                if absf(relative.dot(wall_side)) < 8.0:
                    dodge_side = wall_side * (1.0 if slot % 2 == 0 else -1.0)
                escape += dodge_side * (1.15 if float(mine.get("arm_time", 0.0)) > 0.0 else 1.75)
            continue
        if float(mine.get("arm_time", 0.0)) > 0.0:
            continue
        var danger_pos: Vector2 = mine["pos"]
        var danger_radius := (float(mine["blast_radius"]) if bool(mine.get("triggered", false)) else float(mine["trigger_radius"])) + HERO_RADIUS + 45.0
        var distance := hero_pos.distance_to(danger_pos)
        if distance >= danger_radius:
            continue
        var away := danger_pos.direction_to(hero_pos)
        if away.length_squared() < 0.1:
            away = Vector2(heroes[int(mine["owner"])]["pos"]).direction_to(hero_pos)
        if away.length_squared() < 0.1:
            away = Vector2.LEFT.rotated(float(slot) * 1.1)
        var urgency := 1.3 if bool(mine.get("triggered", false)) else 0.55
        escape += away * (1.0 - distance / danger_radius + urgency)
    var zone_distance := hero_pos.distance_to(safe_zone_center)
    var retreat_radius := maxf(40.0, safe_zone_radius - SAFE_ZONE_EDGE_BUFFER)
    if zone_distance > retreat_radius:
        var inward := hero_pos.direction_to(safe_zone_center)
        if inward.length_squared() < 0.1:
            inward = Vector2.LEFT.rotated(float(slot) * 0.7)
        var overrun := zone_distance - safe_zone_radius
        var urgency := 1.85 if overrun > 0.0 else clampf((zone_distance - retreat_radius) / maxf(1.0, SAFE_ZONE_EDGE_BUFFER), 0.0, 1.0)
        escape += inward * (1.15 + urgency)
    return escape.normalized() if escape.length_squared() > 0.1 else Vector2.ZERO

func _target_valid(slot: int) -> bool:
    return slot >= 0 and slot < PLAYER_COUNT and bool(heroes[slot]["alive"]) and not bool(heroes[slot]["eliminated"])

func _target_position(slot: int) -> Vector2:
    return Vector2(heroes[slot]["pos"])

func _core_hp(slot: int) -> float:
    return float(cores[slot]["hp"])

func _core_exposed(slot: int) -> bool:
    if slot < 0 or slot >= heroes.size() or not bool(cores[slot]["alive"]):
        return false
    var owner: Dictionary = heroes[slot]
    return not bool(owner["alive"]) or float(owner["cc_time"]) > 0.0 or float(owner["root_time"]) > 0.0 or float(owner["stun_time"]) > 0.0

func _streak_damage_multiplier(slot: int) -> float:
    if slot < 0 or slot >= heroes.size():
        return 1.0
    return 1.0 + minf(0.10, float(int(heroes[slot].get("kill_streak", 0))) * 0.025)

func _streak_move_multiplier(slot: int) -> float:
    if slot < 0 or slot >= heroes.size():
        return 1.0
    return 1.0 + minf(0.06, float(int(heroes[slot].get("kill_streak", 0))) * 0.015)

func _move_heroes(dt: float) -> void:
    for i in range(heroes.size()):
        var h: Dictionary = heroes[i]
        if not bool(h["alive"]):
            continue
        if float(h["launch_time"]) > 0.0:
            _move_launched_hero(i, dt)
            continue
        var old_pos: Vector2 = h["pos"]
        var motion: Vector2 = Vector2(h["vel"]) * dt
        var pos := _resolve_cover_motion(old_pos, motion)
        var wall_hit := _deployable_wall_hit(i, old_pos, pos)
        if not wall_hit.is_empty():
            h["pos"] = old_pos
            heroes[i] = h
            var wall_normal: Vector2 = wall_hit["normal"]
            _damage_hero(int(wall_hit["owner"]), i, float(wall_hit["damage"]), &"equipment", 0.32, float(wall_hit["knockback"]), old_pos - wall_normal * 32.0, "WALL SLAM", &"shield_bash", true)
            var bounced: Dictionary = heroes[i]
            bounced["wall_hit_cd"] = 0.78
            heroes[i] = bounced
            _mark_wall_hit(int(wall_hit["id"]), i)
            _add_effect(&"wall_impact", Vector2(wall_hit["pos"]), 102.0, 0.30, Color("#8de1ff"), "SLAM", wall_normal)
            continue
        pos.x = clampf(pos.x, ARENA_MARGIN + HERO_RADIUS, ARENA_SIZE.x - ARENA_MARGIN - HERO_RADIUS)
        pos.y = clampf(pos.y, ARENA_MARGIN + HERO_RADIUS, ARENA_SIZE.y - ARENA_MARGIN - HERO_RADIUS)
        for core in cores:
            if not bool(core["alive"]) or int(core["slot"]) == i:
                continue
            var delta := pos - Vector2(core["pos"])
            var min_dist := HERO_RADIUS + CORE_RADIUS
            if delta.length_squared() < min_dist * min_dist:
                pos = Vector2(core["pos"]) + delta.normalized() * min_dist
        h["pos"] = pos
        heroes[i] = h
    for _pass in range(1):
        for a in range(heroes.size()):
            if not bool(heroes[a]["alive"]):
                continue
            for b in range(a + 1, heroes.size()):
                if not bool(heroes[b]["alive"]):
                    continue
                var ha: Dictionary = heroes[a]
                var hb: Dictionary = heroes[b]
                var delta := Vector2(hb["pos"]) - Vector2(ha["pos"])
                var min_dist := HERO_RADIUS * 1.4
                if delta.length_squared() < min_dist * min_dist:
                    var n := delta.normalized() if delta.length_squared() > 0.001 else Vector2.RIGHT
                    var push := minf(2.0, (min_dist - delta.length()) * 0.4)
                    ha["pos"] = Vector2(ha["pos"]) - n * push
                    hb["pos"] = Vector2(hb["pos"]) + n * push
                    heroes[a] = ha
                heroes[b] = hb

func _update_health_pickups(dt: float) -> void:
    for pickup_index in range(health_pickups.size()):
        var pickup: Dictionary = health_pickups[pickup_index]
        if not bool(pickup["active"]):
            pickup["respawn"] = maxf(0.0, float(pickup["respawn"]) - dt)
            if float(pickup["respawn"]) <= 0.0:
                if bool(pickup.get("ephemeral", false)):
                    pickup["active"] = false
                    pickup["respawn"] = 99999.0
                else:
                    pickup["active"] = true
                    pickup["pos"] = Vector2(pickup["home"])
                    pickup["magnet_slot"] = -1
                    pickup["ignore_slot"] = -1
                    pickup["ignore_time"] = 0.0
                    if mode == ITEM_POOL_MODE:
                        _roll_pickup_kind(pickup)
                    _add_effect(&"heal_ready", Vector2(pickup["pos"]), 62.0, 0.55, Color("#6ef3a5"), "HEAL READY")
        pickup["ignore_time"] = maxf(0.0, float(pickup.get("ignore_time", 0.0)) - dt)
        if bool(pickup["active"]):
            var magnet_slot := int(pickup.get("magnet_slot", -1))
            if not _pickup_target_valid(magnet_slot, pickup, HEALTH_PICKUP_MAGNET_RADIUS * 1.65):
                magnet_slot = _nearest_pickup_target(pickup)
                pickup["magnet_slot"] = magnet_slot
            if magnet_slot >= 0:
                var target_pos := Vector2(heroes[magnet_slot]["pos"])
                pickup["pos"] = Vector2(pickup["pos"]).move_toward(target_pos, HEALTH_PICKUP_MAGNET_SPEED * dt)
                if Vector2(pickup["pos"]).distance_to(target_pos) <= HERO_RADIUS + HEALTH_PICKUP_RADIUS:
                    var h: Dictionary = heroes[magnet_slot]
                    var carried := int(h.get("medkits", 0))
                    if mode == ITEM_POOL_MODE:
                        pickup = _collect_item_pickup(magnet_slot, pickup)
                    elif mode in MEDKIT_MODES and carried < MEDKIT_MAX:
                        h["medkits"] = carried + 1
                        heroes[magnet_slot] = h
                        pickup["active"] = false
                        pickup["respawn"] = HEALTH_PICKUP_RESPAWN
                        pickup["magnet_slot"] = -1
                        pickup["pos"] = Vector2(pickup["home"])
                        _add_effect(&"heal_pickup", target_pos, 64.0, 0.38, Color("#6ef3a5"), "메드킷 +1")
                        event_log.emit(tick, &"medkit_collected", magnet_slot, -1, {"pickup":pickup_index, "carried":carried + 1})
                    else:
                        var missing_health := float(h["max_hp"]) - float(h["hp"])
                        var heal_amount := minf(missing_health, float(h["max_hp"]) * HEALTH_PICKUP_HEAL_RATIO)
                        _heal_hero(magnet_slot, heal_amount)
                        pickup["active"] = false
                        pickup["respawn"] = HEALTH_PICKUP_RESPAWN
                        pickup["magnet_slot"] = -1
                        pickup["pos"] = Vector2(pickup["home"])
                        var pickup_label := "+%d HP" % roundi(heal_amount) if heal_amount > 0.01 else "POTION TAKEN"
                        _add_effect(&"heal_pickup", target_pos, 64.0, 0.38, Color("#6ef3a5"), pickup_label)
                        event_log.emit(tick, &"health_pickup_collected", magnet_slot, -1, {"pickup":pickup_index, "amount":heal_amount})
            else:
                pickup["pos"] = Vector2(pickup["pos"]).move_toward(Vector2(pickup["home"]), HEALTH_PICKUP_RETURN_SPEED * dt)
        health_pickups[pickup_index] = pickup

func _pickup_target_valid(slot: int, pickup: Dictionary, max_distance: float) -> bool:
    if slot < 0 or slot >= heroes.size():
        return false
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]) or bool(h["eliminated"]) or float(h["launch_time"]) > 0.0:
        return false
    if int(pickup.get("ignore_slot", -1)) == slot and float(pickup.get("ignore_time", 0.0)) > 0.0:
        return false
    return Vector2(h["pos"]).distance_to(Vector2(pickup["pos"])) <= max_distance

func _nearest_pickup_target(pickup: Dictionary) -> int:
    var best_slot := -1
    var best_distance := HEALTH_PICKUP_MAGNET_RADIUS
    for slot in range(heroes.size()):
        if not _pickup_target_valid(slot, pickup, HEALTH_PICKUP_MAGNET_RADIUS):
            continue
        var distance := Vector2(heroes[slot]["pos"]).distance_to(Vector2(pickup["pos"]))
        if distance < best_distance:
            best_distance = distance
            best_slot = slot
    return best_slot

func _move_launched_hero(slot: int, dt: float) -> void:
    var h: Dictionary = heroes[slot]
    var pos: Vector2 = h["pos"]
    var velocity: Vector2 = h["launch_vel"]
    var motion := velocity * dt
    var min_x := ARENA_MARGIN + HERO_RADIUS
    var max_x := ARENA_SIZE.x - ARENA_MARGIN - HERO_RADIUS
    var min_y := ARENA_MARGIN + HERO_RADIUS
    var max_y := ARENA_SIZE.y - ARENA_MARGIN - HERO_RADIUS
    var hit_x := false
    var hit_y := false
    var x_candidate := pos + Vector2(motion.x, 0.0)
    if x_candidate.x < min_x or x_candidate.x > max_x or _point_in_cover(x_candidate, HERO_RADIUS):
        hit_x = true
    else:
        pos.x = x_candidate.x
    var y_candidate := pos + Vector2(0.0, motion.y)
    if y_candidate.y < min_y or y_candidate.y > max_y or _point_in_cover(y_candidate, HERO_RADIUS):
        hit_y = true
    else:
        pos.y = y_candidate.y
    if hit_x or hit_y:
        if hit_x:
            velocity.x *= -0.84
        if hit_y:
            velocity.y *= -0.84
        h["wall_bounces"] = int(h["wall_bounces"]) + 1
        var wall_damage := clampf(9.0 + velocity.length() / 78.0, 15.0, 36.0)
        if float(h["guard_time"]) > 0.0:
            wall_damage *= 0.55
        var wall_damage_cap := float(h["max_hp"]) * float(h["equipment"]["combo_cap_ratio"])
        wall_damage = minf(wall_damage, maxf(0.0, wall_damage_cap - float(h["launch_wall_damage"])))
        h["launch_wall_damage"] = float(h["launch_wall_damage"]) + wall_damage
        h["hp"] = float(h["hp"]) - wall_damage
        var launch_owner := int(h["launch_owner"])
        if launch_owner >= 0 and launch_owner != slot:
            var attacker: Dictionary = heroes[launch_owner]
            attacker["damage_dealt"] = float(attacker["damage_dealt"]) + wall_damage
            attacker["score"] = float(attacker["score"]) + wall_damage * 1.25
            attacker["threat"] = float(attacker["threat"]) + wall_damage * 0.45
            heroes[launch_owner] = attacker
        _add_effect(&"wall_impact", pos, 78.0, 0.32, Color("#ff774f"), "WALL CRASH -%d" % roundi(wall_damage), -velocity.normalized())
        event_log.emit(tick, &"wall_bounce", launch_owner, slot, {"damage":wall_damage, "bounce":int(h["wall_bounces"])})
        impact_ticks = maxi(impact_ticks, 14)
        impact_pos = pos
        if float(h["hp"]) <= 0.0:
            h["pos"] = pos
            h["launch_vel"] = velocity
            heroes[slot] = h
            _apply_lethal_or_down(launch_owner if launch_owner >= 0 else slot, slot, 0.0)
            return
        if int(h["wall_bounces"]) >= 3:
            h["launch_time"] = 0.0
            velocity = Vector2.ZERO
    h["launch_time"] = maxf(0.0, float(h["launch_time"]) - dt)
    velocity *= exp(-0.62 * dt)
    h["launch_vel"] = velocity
    h["pos"] = pos
    var trail: Array = h["launch_trail"]
    if tick % 2 == 0:
        trail.append(pos)
        if trail.size() > 14:
            trail.pop_front()
    h["launch_trail"] = trail
    if float(h["launch_time"]) <= 0.0 or velocity.length() < 80.0:
        h["launch_time"] = 0.0
        h["launch_vel"] = Vector2.ZERO
    heroes[slot] = h

func _update_knockouts(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for knockout0 in knockouts:
        var knockout: Dictionary = knockout0
        knockout["time"] = float(knockout["time"]) - dt
        if bool(knockout.get("finished", false)):
            if float(knockout["time"]) > 0.0:
                kept.append(knockout)
            continue
        var pos: Vector2 = knockout["pos"]
        var velocity: Vector2 = knockout["vel"]
        var motion := velocity * dt
        var next := pos + motion
        var hit_x := next.x < ARENA_MARGIN or next.x > ARENA_SIZE.x - ARENA_MARGIN or _point_in_cover(pos + Vector2(motion.x, 0.0), HERO_RADIUS)
        var hit_y := next.y < ARENA_MARGIN or next.y > ARENA_SIZE.y - ARENA_MARGIN or _point_in_cover(pos + Vector2(0.0, motion.y), HERO_RADIUS)
        if hit_x or hit_y:
            if hit_x:
                velocity.x *= -0.82
            else:
                pos.x = next.x
            if hit_y:
                velocity.y *= -0.82
            else:
                pos.y = next.y
            knockout["bounces"] = int(knockout["bounces"]) + 1
            _add_effect(&"wall_impact", pos, 58.0, 0.24, Color("#ff4f5e"), "", -velocity.normalized())
        else:
            pos = next
        velocity *= exp(-0.48 * dt)
        knockout["pos"] = pos
        knockout["vel"] = velocity
        var trail: Array = knockout["trail"]
        if tick % 2 == 0:
            trail.append(pos)
            if trail.size() > 20:
                trail.pop_front()
        knockout["trail"] = trail
        if int(knockout["bounces"]) >= 3:
            knockout["finished"] = true
            knockout["vel"] = Vector2.ZERO
            knockout["time"] = minf(float(knockout["time"]), 0.42)
        if float(knockout["time"]) > 0.0:
            kept.append(knockout)
    knockouts = kept

func _resolve_cover_motion(old_pos: Vector2, motion: Vector2) -> Vector2:
    var resolved := old_pos
    var x_candidate := resolved + Vector2(motion.x, 0.0)
    if not _point_in_cover(x_candidate, HERO_RADIUS):
        resolved.x = x_candidate.x
    var y_candidate := resolved + Vector2(0.0, motion.y)
    if not _point_in_cover(y_candidate, HERO_RADIUS):
        resolved.y = y_candidate.y
    return resolved


func _tiled_points(source_points: Array) -> Array:
    var points: Array = []
    for tile_x in range(2):
        for tile_y in range(2):
            var origin := Vector2(float(tile_x) * SOURCE_ARENA_SIZE.x, float(tile_y) * SOURCE_ARENA_SIZE.y) * ARENA_TILE_SCALE
            for source in source_points:
                points.append(origin + Vector2(source) * ARENA_TILE_SCALE)
    return points

func _build_tiled_covers() -> Array[Dictionary]:
    var source_rects: Array[Rect2] = [
        Rect2(1330.0, 590.0, 140.0, 520.0),
        Rect2(930.0, 810.0, 300.0, 70.0),
        Rect2(1570.0, 810.0, 300.0, 70.0),
        Rect2(590.0, 350.0, 230.0, 82.0),
        Rect2(1980.0, 350.0, 230.0, 82.0),
        Rect2(590.0, 1268.0, 230.0, 82.0),
        Rect2(1980.0, 1268.0, 230.0, 82.0),
        Rect2(340.0, 715.0, 82.0, 270.0),
        Rect2(2378.0, 715.0, 82.0, 270.0),
        Rect2(1030.0, 260.0, 120.0, 120.0),
        Rect2(1650.0, 1320.0, 120.0, 120.0)
    ]
    var result: Array[Dictionary] = []
    for tile_x in range(2):
        for tile_y in range(2):
            var origin := Vector2(float(tile_x) * SOURCE_ARENA_SIZE.x, float(tile_y) * SOURCE_ARENA_SIZE.y) * ARENA_TILE_SCALE
            for source_rect in source_rects:
                result.append({"rect":Rect2(origin + source_rect.position * ARENA_TILE_SCALE, source_rect.size * ARENA_TILE_SCALE)})
    return result

func _clamp_arena_point(point: Vector2, radius: float) -> Vector2:
    return Vector2(
        clampf(point.x, ARENA_MARGIN + radius, ARENA_SIZE.x - ARENA_MARGIN - radius),
        clampf(point.y, ARENA_MARGIN + radius, ARENA_SIZE.y - ARENA_MARGIN - radius)
    )

func _nudge_out_of_cover(point: Vector2, radius: float) -> Vector2:
    if not _point_in_cover(point, radius):
        return point
    var nudged: Vector2 = point
    for step_index in range(24):
        nudged = nudged.move_toward(ARENA_CENTER, 28.0)
        nudged = _clamp_arena_point(nudged, radius)
        if not _point_in_cover(nudged, radius):
            return nudged
    return _clamp_arena_point(ARENA_CENTER, radius)

func _cover_radius(cover: Dictionary) -> float:
    var rect: Rect2 = cover["rect"]
    return minf(rect.size.x, rect.size.y) * 0.5

func _point_in_cover(point: Vector2, padding: float = 0.0) -> bool:
    for cover in covers:
        var rect: Rect2 = cover["rect"]
        if point.distance_to(rect.get_center()) <= _cover_radius(cover) + padding:
            return true
    return false

func _line_blocked(from: Vector2, to: Vector2) -> bool:
    for cover in covers:
        var c: Vector2 = Rect2(cover["rect"]).get_center()
        var r := _cover_radius(cover) + 3.0
        var closest: Vector2 = Geometry2D.get_closest_point_to_segment(c, from, to)
        if closest.distance_to(c) <= r:
            return true
    return false

func _spawn_breakable_crates() -> void:
    crates.clear()
    _place_crate_ring(8, SPAWN_HERO_RADIUS_X * CRATE_RING_A_SCALE, SPAWN_HERO_RADIUS_Y * CRATE_RING_A_SCALE, 0.0, 0, true)
    _place_crate_ring(8, SPAWN_HERO_RADIUS_X * CRATE_RING_B_SCALE, SPAWN_HERO_RADIUS_Y * CRATE_RING_B_SCALE, PI * 0.125, 1, false)
    _place_crate_ring(4, SPAWN_HERO_RADIUS_X * CRATE_RING_C_SCALE, SPAWN_HERO_RADIUS_Y * CRATE_RING_C_SCALE, PI * 0.25, 2, true)

func _place_crate_ring(count: int, radius_x: float, radius_y: float, rot: float, ring_id: int, red_first: bool) -> void:
    var radial_scale := 1.0
    var scales: Array[float] = []
    for i in range(16):
        scales.append(1.0 + float(i) * 0.028)
    for i in range(1, 12):
        scales.append(1.0 - float(i) * 0.028)
    for scale_try in scales:
        var blocked := false
        for n in range(count):
            var ang := -PI * 0.5 + rot + TAU * float(n) / float(count)
            var dir: Vector2 = Vector2.RIGHT.rotated(ang)
            var pos: Vector2 = ARENA_CENTER + Vector2(dir.x * radius_x * scale_try, dir.y * radius_y * scale_try)
            pos = _clamp_arena_point(pos, CRATE_RADIUS)
            if _point_in_cover(pos, CRATE_RADIUS):
                blocked = true
                break
        if not blocked:
            radial_scale = scale_try
            break
    for n in range(count):
        var ang := -PI * 0.5 + rot + TAU * float(n) / float(count)
        var dir: Vector2 = Vector2.RIGHT.rotated(ang)
        var pos: Vector2 = ARENA_CENTER + Vector2(dir.x * radius_x * radial_scale, dir.y * radius_y * radial_scale)
        pos = _clamp_arena_point(pos, CRATE_RADIUS)
        var is_red := (n % 2 == 0) if red_first else (n % 2 == 1)
        crates.append({
            "id":crates.size(),
            "pos":pos,
            "hp":CRATE_MAX_HP,
            "max_hp":CRATE_MAX_HP,
            "alive":true,
            "ring":ring_id,
            "orb_red":is_red
        })

func _hurt_crate(index: int, damage: float, show_number: bool = true) -> void:
    if index < 0 or index >= crates.size():
        return
    var crate: Dictionary = crates[index]
    if not bool(crate["alive"]) or damage <= 0.0:
        return
    crate["hp"] = float(crate["hp"]) - damage
    if show_number and damage > 0.4:
        event_log.emit(tick, &"crate_hit", -1, -1, {"crate":index, "damage":damage, "pos":Vector2(crate["pos"])})
    if float(crate["hp"]) <= 0.0:
        crate["hp"] = 0.0
        crate["alive"] = false
        crates[index] = crate
        _spawn_crate_orb(Vector2(crate["pos"]), bool(crate["orb_red"]))
        _add_effect(&"explosion", Vector2(crate["pos"]), 42.0, 0.28, Color("#c48a4a"), "CRATE")
        event_log.emit(tick, &"crate_broke", -1, -1, {"crate":index, "red":bool(crate["orb_red"])})
        return
    crates[index] = crate

func _damage_crates_at(center: Vector2, radius: float, damage: float) -> void:
    for crate_i in range(crates.size()):
        var crate: Dictionary = crates[crate_i]
        if not bool(crate["alive"]):
            continue
        if center.distance_to(Vector2(crate["pos"])) <= radius + CRATE_RADIUS:
            _hurt_crate(crate_i, damage)

func _spawn_crate_orb(pos: Vector2, is_red: bool) -> void:
    crate_orbs.append({
        "pos":pos,
        "home":pos,
        "red":is_red,
        "arm":CRATE_ORB_ARM,
        "magnet_slot":-1,
        "active":true
    })

func _update_crate_orbs(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for orb0 in crate_orbs:
        var orb: Dictionary = orb0
        if not bool(orb.get("active", true)):
            continue
        orb["arm"] = maxf(0.0, float(orb.get("arm", 0.0)) - dt)
        if float(orb["arm"]) <= 0.0:
            var magnet_slot := int(orb.get("magnet_slot", -1))
            if magnet_slot < 0 or magnet_slot >= heroes.size() or not bool(heroes[magnet_slot]["alive"]) or bool(heroes[magnet_slot]["eliminated"]):
                magnet_slot = _nearest_orb_target(orb)
                orb["magnet_slot"] = magnet_slot
            if magnet_slot >= 0:
                var target_pos: Vector2 = heroes[magnet_slot]["pos"]
                orb["pos"] = Vector2(orb["pos"]).move_toward(target_pos, HEALTH_PICKUP_MAGNET_SPEED * dt)
                if Vector2(orb["pos"]).distance_to(target_pos) <= HERO_RADIUS + CRATE_ORB_RADIUS:
                    _collect_crate_orb(magnet_slot, orb)
                    continue
        kept.append(orb)
    crate_orbs = kept

func _nearest_orb_target(orb: Dictionary) -> int:
    var best := -1
    var best_distance := HEALTH_PICKUP_MAGNET_RADIUS
    for slot in range(heroes.size()):
        if not bool(heroes[slot]["alive"]) or bool(heroes[slot]["eliminated"]):
            continue
        var distance := Vector2(heroes[slot]["pos"]).distance_to(Vector2(orb["pos"]))
        if distance < best_distance:
            best_distance = distance
            best = slot
    return best

func _collect_crate_orb(slot: int, orb: Dictionary) -> void:
    var h: Dictionary = heroes[slot]
    if bool(orb.get("red", true)):
        h["dmg_orb_time"] = CRATE_ORB_DMG_TIME
        heroes[slot] = h
        _add_effect(&"heal_pickup", Vector2(h["pos"]), 58.0, 0.40, Color("#ff4f4f"), "DMG UP")
        event_log.emit(tick, &"dmg_orb", slot, -1, {})
    else:
        h["ultimate_charge"] = minf(ULTIMATE_MAX, float(h.get("ultimate_charge", 0.0)) + ULTIMATE_MAX * CRATE_ORB_ULT_RATIO)
        heroes[slot] = h
        _add_effect(&"heal_pickup", Vector2(h["pos"]), 58.0, 0.40, Color("#4f8cff"), "POWER")
        event_log.emit(tick, &"ult_orb", slot, -1, {"charge":float(h["ultimate_charge"])})

func _best_crate(slot: int) -> int:
    var h: Dictionary = heroes[slot]
    var best := -1
    var best_distance := 480.0
    for crate_i in range(crates.size()):
        var crate: Dictionary = crates[crate_i]
        if not bool(crate["alive"]):
            continue
        var distance := Vector2(h["pos"]).distance_to(Vector2(crate["pos"]))
        if distance < best_distance:
            best_distance = distance
            best = crate_i
    return best

func _best_crate_orb(slot: int) -> int:
    var h: Dictionary = heroes[slot]
    var best := -1
    var best_distance := 420.0
    for orb_i in range(crate_orbs.size()):
        var orb: Dictionary = crate_orbs[orb_i]
        if not bool(orb.get("active", true)):
            continue
        if float(orb.get("arm", 0.0)) > 0.0:
            continue
        var distance := Vector2(h["pos"]).distance_to(Vector2(orb["pos"]))
        if distance < best_distance:
            best_distance = distance
            best = orb_i
    return best

func _respawn_delay_for(slot: int) -> float:
    var rows: Array[Dictionary] = []
    for i in range(heroes.size()):
        if i == slot or not bool(heroes[i]["eliminated"]):
            rows.append({"slot":i, "score":float(heroes[i]["score"]), "kills":int(heroes[i]["kills"])})
    rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if absf(float(a["score"]) - float(b["score"])) > 0.01:
            return float(a["score"]) > float(b["score"])
        if int(a["kills"]) != int(b["kills"]):
            return int(a["kills"]) > int(b["kills"])
        return int(a["slot"]) < int(b["slot"])
    )
    var rank_from_top := 0
    for i in range(rows.size()):
        if int(rows[i]["slot"]) == slot:
            rank_from_top = i
            break
    var from_last := maxi(0, rows.size() - 1 - rank_from_top)
    return minf(RESPAWN_MAX, RESPAWN_BASE + RESPAWN_RANK_STEP * float(from_last))

func _respawn_point(slot: int) -> Vector2:
    var home: Vector2 = heroes[slot].get("spawn_pos", ARENA_CENTER)
    if home.distance_to(safe_zone_center) <= maxf(40.0, safe_zone_radius - HERO_RADIUS - 12.0):
        return _nudge_out_of_cover(_clamp_arena_point(home, HERO_RADIUS), HERO_RADIUS)
    var outward: Vector2 = safe_zone_center.direction_to(home)
    if outward.length_squared() < 0.01:
        outward = Vector2.RIGHT
    var safe_pos: Vector2 = safe_zone_center + outward * maxf(36.0, safe_zone_radius - 80.0)
    return _nudge_out_of_cover(_clamp_arena_point(safe_pos, HERO_RADIUS), HERO_RADIUS)

func _update_respawns(dt: float) -> void:
    for slot in range(heroes.size()):
        var h: Dictionary = heroes[slot]
        if bool(h["eliminated"]) or bool(h["alive"]):
            continue
        h["respawn_left"] = maxf(0.0, float(h.get("respawn_left", 0.0)) - dt)
        h["respawn"] = float(h["respawn_left"])
        if float(h["respawn_left"]) > 0.0:
            heroes[slot] = h
            continue
        var spawn_pos: Vector2 = _respawn_point(slot)
        h["pos"] = spawn_pos
        h["alive"] = true
        h["hp"] = float(h["max_hp"])
        h["mag"] = int(h["equipment"].get("mag_size", 1))
        h["reload_left"] = 0.0
        h["stun_time"] = 0.0
        h["cc_time"] = 0.0
        h["root_time"] = 0.0
        h["hitstun_time"] = 0.0
        h["launch_time"] = 0.0
        h["launch_vel"] = Vector2.ZERO
        h["launch_trail"] = []
        h["vel"] = Vector2.ZERO
        h["spawn_protect_time"] = 3.0
        h["downed"] = false
        h["down_left"] = 0.0
        h["down_taken"] = 0.0
        h["life_hitters"] = []
        h["life_hits"] = {}
        h["action"] = &"RESPAWN"
        heroes[slot] = h
        _add_effect(&"respawn", spawn_pos, 70.0, 0.45, Color("#b9f3ff"), "RESPAWN")
        event_log.emit(tick, &"hero_respawned", slot, -1, {"revives_used":int(h.get("revives_used", 0))})

func _standing_leader() -> int:
    var best := -1
    var best_score := -999999.0
    var best_kills := -1
    for slot in range(heroes.size()):
        if bool(heroes[slot]["eliminated"]):
            continue
        var score := float(heroes[slot]["score"])
        var kills := int(heroes[slot]["kills"])
        var better := false
        if best < 0:
            better = true
        elif score > best_score + 0.01:
            better = true
        elif absf(score - best_score) <= 0.01 and kills > best_kills:
            better = true
        elif absf(score - best_score) <= 0.01 and kills == best_kills and slot < best:
            better = true
        if better:
            best = slot
            best_score = score
            best_kills = kills
    return best

func _hero_move_speed(slot: int) -> float:
    if slot < 0 or slot >= heroes.size():
        return HERO_SPEED
    var speed := float(heroes[slot]["equipment"]["move_speed"]) + _roulette_stat(slot, "spd")
    if posmod(int(heroes[slot].get("animal", slot)), 12) == 4 and _pos_in_dragon_smoke(Vector2(heroes[slot]["pos"])):
        speed *= 1.30
    if _pos_in_enemy_mud(slot):
        speed *= 0.48
    return speed

func _hero_has_timed(h: Dictionary, buff_id: String) -> bool:
    for buff in h.get("rl_timed", []):
        if str(buff.get("id", "")) == buff_id:
            return true
    return false

func _roulette_stat(slot: int, key: String) -> float:
    if slot < 0 or slot >= heroes.size():
        return 0.0
    var h: Dictionary = heroes[slot]
    var total := float(h.get("rl_until", {}).get(key, 0.0))
    for buff in h.get("rl_timed", []):
        total += float(buff.get(key, 0.0))
    return total

func _roulette_faces(rank: String, timed_group: bool) -> Array:
    if rank == "assist":
        if timed_group:
            return [
                {"id":"giant", "name":"GIANT", "kind":"timed", "atk":2.0, "spd":3.0, "def":0.0, "hp":2.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":8.0},
                {"id":"shield", "name":"SHIELD", "kind":"timed", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":24.0, "dur":2.0},
                {"id":"berserk", "name":"BERSERK", "kind":"timed", "atk":2.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.04, "range":0.0, "shield":0.0, "dur":5.0}
            ]
        return [
            {"id":"atk", "name":"ATK +2", "kind":"until", "atk":2.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
            {"id":"spd", "name":"SPD +2", "kind":"until", "atk":0.0, "spd":2.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
            {"id":"def", "name":"DEF +4%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.04, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
            {"id":"hp", "name":"HP +8", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":8.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
            {"id":"rate", "name":"RATE +4%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.04, "range":0.0, "shield":0.0, "dur":0.0},
            {"id":"range", "name":"RANGE +5%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.05, "shield":0.0, "dur":0.0}
        ]
    if rank == "wanted":
        if timed_group:
            return [
                {"id":"giant", "name":"GIANT", "kind":"timed", "atk":4.5, "spd":7.5, "def":0.0, "hp":4.5, "rate":0.0, "range":0.0, "shield":0.0, "dur":12.0},
                {"id":"shield", "name":"SHIELD", "kind":"timed", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":60.0, "dur":3.0},
                {"id":"berserk", "name":"BERSERK", "kind":"timed", "atk":4.5, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.105, "range":0.0, "shield":0.0, "dur":8.0},
                {"id":"sniper", "name":"SNIPER", "kind":"timed", "atk":4.5, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.12, "shield":0.0, "dur":9.0},
                {"id":"double_giant", "name":"DOUBLE GIANT", "kind":"timed", "atk":6.0, "spd":10.0, "def":0.0, "hp":6.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":12.0}
            ]
        return [
            {"id":"atk", "name":"ATK +5", "kind":"until", "atk":4.5, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
            {"id":"spd", "name":"SPD +6", "kind":"until", "atk":0.0, "spd":6.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
            {"id":"def", "name":"DEF +9%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.09, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
            {"id":"hp", "name":"HP +21", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":21.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
            {"id":"rate", "name":"RATE +11%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.105, "range":0.0, "shield":0.0, "dur":0.0},
            {"id":"range", "name":"RANGE +12%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.12, "shield":0.0, "dur":0.0}
        ]
    if timed_group:
        return [
            {"id":"giant", "name":"GIANT", "kind":"timed", "atk":3.0, "spd":5.0, "def":0.0, "hp":3.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":12.0},
            {"id":"shield", "name":"SHIELD", "kind":"timed", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":40.0, "dur":3.0},
            {"id":"berserk", "name":"BERSERK", "kind":"timed", "atk":3.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.07, "range":0.0, "shield":0.0, "dur":8.0},
            {"id":"sniper", "name":"SNIPER", "kind":"timed", "atk":3.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.08, "shield":0.0, "dur":9.0}
        ]
    return [
        {"id":"atk", "name":"ATK +3", "kind":"until", "atk":3.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
        {"id":"spd", "name":"SPD +4", "kind":"until", "atk":0.0, "spd":4.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
        {"id":"def", "name":"DEF +6%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.06, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
        {"id":"hp", "name":"HP +14", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":14.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
        {"id":"rate", "name":"RATE +7%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.07, "range":0.0, "shield":0.0, "dur":0.0},
        {"id":"range", "name":"RANGE +8%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.08, "shield":0.0, "dur":0.0}
    ]

func _roulette_b_chance(rank: String) -> float:
    if rank == "assist":
        return 0.25
    if rank == "wanted":
        return 0.55
    return 0.40

func _pick_roulette_face(rank: String) -> Dictionary:
    if rng.rangef(0.0, 1.0) < 0.03:
        return {"id":"turtle", "name":"TURTLE", "kind":"timed", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":2.0}
    var timed_group: bool = rng.rangef(0.0, 1.0) < _roulette_b_chance(rank)
    var faces: Array = _roulette_faces(rank, timed_group)
    return faces[rng.rangei(0, faces.size() - 1)]

func _roulette_face_list(rank: String) -> Array:
    var faces: Array = []
    for face in _roulette_faces(rank, false):
        faces.append({"id":str(face["id"]), "name":str(face["name"])})
    for face in _roulette_faces(rank, true):
        faces.append({"id":str(face["id"]), "name":str(face["name"])})
    faces.append({"id":"turtle", "name":"TURTLE"})
    return faces

func _clear_roulette_buffs(h: Dictionary) -> void:
    var base_hp := float(h["equipment"]["max_hp"])
    h["max_hp"] = base_hp
    if float(h["hp"]) > base_hp:
        h["hp"] = base_hp
    h["rl_until"] = {"atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0}
    h["rl_timed"] = []
    h["roulette_time"] = 0.0
    h["roulette_label"] = ""
    h["roulette_rank"] = ""
    h["roulette_phase"] = ""
    h["roulette_pending"] = {}
    h["roulette_queue"] = []
    h["roulette_faces"] = []

func _apply_roulette_face(slot: int, face: Dictionary) -> void:
    if slot < 0 or slot >= heroes.size() or not bool(heroes[slot]["alive"]):
        return
    var h: Dictionary = heroes[slot]
    var hp_add := float(face.get("hp", 0.0))
    if str(face.get("kind", "until")) == "until":
        var until_stats: Dictionary = h.get("rl_until", {"atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0})
        until_stats["atk"] = float(until_stats.get("atk", 0.0)) + float(face.get("atk", 0.0))
        until_stats["spd"] = float(until_stats.get("spd", 0.0)) + float(face.get("spd", 0.0))
        until_stats["def"] = float(until_stats.get("def", 0.0)) + float(face.get("def", 0.0))
        until_stats["hp"] = float(until_stats.get("hp", 0.0)) + hp_add
        until_stats["rate"] = float(until_stats.get("rate", 0.0)) + float(face.get("rate", 0.0))
        until_stats["range"] = float(until_stats.get("range", 0.0)) + float(face.get("range", 0.0))
        h["rl_until"] = until_stats
        if hp_add > 0.0:
            h["max_hp"] = float(h["max_hp"]) + hp_add
            h["hp"] = minf(float(h["max_hp"]), float(h["hp"]) + hp_add)
    else:
        var timed: Dictionary = {
            "id":str(face.get("id", "")),
            "name":str(face.get("name", "")),
            "time":float(face.get("dur", 0.0)),
            "atk":float(face.get("atk", 0.0)),
            "spd":float(face.get("spd", 0.0)),
            "def":float(face.get("def", 0.0)),
            "hp":hp_add,
            "rate":float(face.get("rate", 0.0)),
            "range":float(face.get("range", 0.0)),
            "shield":float(face.get("shield", 0.0))
        }
        var timed_list: Array = h.get("rl_timed", [])
        timed_list.append(timed)
        h["rl_timed"] = timed_list
        if hp_add > 0.0:
            h["max_hp"] = float(h["max_hp"]) + hp_add
            h["hp"] = minf(float(h["max_hp"]), float(h["hp"]) + hp_add)
    heroes[slot] = h
    _add_effect(&"heal_pickup", Vector2(h["pos"]), 72.0, 0.50, _roulette_rank_color(str(h.get("roulette_rank", "kill"))), str(face.get("name", "")))
    event_log.emit(tick, &"kill_roulette", slot, -1, {"label":str(face.get("name", "")), "rank":str(h.get("roulette_rank", "")), "kind":str(face.get("kind", ""))})

func _roulette_face_desc(face: Dictionary) -> String:
    var bid := str(face.get("id", ""))
    match bid:
        "atk":
            return "이번 목숨 동안 공격력이 올라갑니다"
        "spd":
            return "이번 목숨 동안 이동속도가 빨라집니다"
        "def":
            return "받는 피해가 줄어듭니다"
        "hp":
            return "최대 체력과 현재 체력이 늘어납니다"
        "rate":
            return "연사 속도가 빨라집니다"
        "range":
            return "총알이 더 멀리 나갑니다"
        "giant":
            return "몸이 커지고 공격과 이동이 세집니다"
        "double_giant":
            return "더 크게 변하고 능력치가 크게 오릅니다"
        "shield":
            return "잠시 보호막이 생깁니다"
        "berserk":
            return "공격과 연사가 잠깐 폭주합니다"
        "sniper":
            return "사거리가 늘어나고 한 방이 세집니다"
        "turtle":
            return "2초 동안 공격과 대시를 쓸 수 없습니다"
        _:
            return str(face.get("name", ""))

func _roulette_rank_color(rank: String) -> Color:
    if rank == "assist":
        return Color("#4da3ff")
    if rank == "wanted":
        return Color("#ff3349")
    return Color("#b84dff")

func _begin_next_roulette(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    var queue: Array = h.get("roulette_queue", [])
    if queue.is_empty() or not bool(h["alive"]):
        h["roulette_phase"] = ""
        h["roulette_time"] = 0.0
        h["roulette_pending"] = {}
        heroes[slot] = h
        return
    var item: Dictionary = queue.pop_front()
    h["roulette_queue"] = queue
    var face: Dictionary = item.get("face", {})
    var rank := str(item.get("rank", "kill"))
    h["roulette_pending"] = face
    h["roulette_rank"] = rank
    h["roulette_phase"] = "bonus"
    h["roulette_time"] = 0.25
    h["roulette_label"] = "KILL BONUS!"
    h["roulette_faces"] = _roulette_face_list(rank)
    h["roulette_spin_id"] = ""
    heroes[slot] = h
    _announce("KILL BONUS!", 50)

func _queue_roulette(slot: int, rank: String) -> void:
    if slot < 0 or slot >= heroes.size() or not bool(heroes[slot]["alive"]):
        return
    var h: Dictionary = heroes[slot]
    var queue: Array = h.get("roulette_queue", [])
    queue.append({"rank":rank, "face":_pick_roulette_face(rank)})
    h["roulette_queue"] = queue
    heroes[slot] = h
    if str(h.get("roulette_phase", "")) == "":
        _begin_next_roulette(slot)

func _grant_kill_roulettes(owner: int, target: int, bounty_kill: bool, hits: Dictionary) -> void:
    if owner >= 0 and owner < heroes.size() and owner != target and bool(heroes[owner]["alive"]):
        _queue_roulette(owner, "wanted" if bounty_kill else "kill")
    for assist_slot in _assist_slots(owner, target, hits):
        _queue_roulette(int(assist_slot), "assist")

func _expire_timed_buff(h: Dictionary, buff: Dictionary) -> void:
    var hp_drop := float(buff.get("hp", 0.0))
    if hp_drop > 0.0:
        h["max_hp"] = maxf(float(h["equipment"]["max_hp"]), float(h["max_hp"]) - hp_drop)
        h["hp"] = minf(float(h["hp"]), float(h["max_hp"]))

func _tick_roulette(slot: int, dt: float) -> void:
    var h: Dictionary = heroes[slot]
    var timed_keep: Array = []
    for buff in h.get("rl_timed", []):
        var left := maxf(0.0, float(buff.get("time", 0.0)) - dt)
        if left <= 0.0:
            _expire_timed_buff(h, buff)
            continue
        buff["time"] = left
        timed_keep.append(buff)
    h["rl_timed"] = timed_keep
    var phase := str(h.get("roulette_phase", ""))
    if phase == "":
        heroes[slot] = h
        return
    h["roulette_time"] = maxf(0.0, float(h.get("roulette_time", 0.0)) - dt)
    if phase == "bonus":
        h["roulette_label"] = "KILL BONUS!"
        if float(h["roulette_time"]) <= 0.0:
            h["roulette_phase"] = "spin"
            h["roulette_time"] = 0.9
            h["roulette_spin_dur"] = 0.9
    elif phase == "spin":
        var faces: Array = h.get("roulette_faces", [])
        if faces.size() > 0:
            var dur := maxf(0.001, float(h.get("roulette_spin_dur", 0.9)))
            var u := clampf(1.0 - float(h["roulette_time"]) / dur, 0.0, 1.0)
            var eased := 1.0 - (1.0 - u) * (1.0 - u)
            var flicker := int(floor(eased * 1.65 * float(faces.size()))) % faces.size()
            var spin_face: Dictionary = faces[flicker] if typeof(faces[flicker]) == TYPE_DICTIONARY else {"id":str(faces[flicker]), "name":str(faces[flicker])}
            h["roulette_spin_id"] = str(spin_face.get("id", ""))
            h["roulette_label"] = str(spin_face.get("name", ""))
        if float(h["roulette_time"]) <= 0.0:
            var face: Dictionary = h.get("roulette_pending", {})
            heroes[slot] = h
            _apply_roulette_face(slot, face)
            h = heroes[slot]
            h["roulette_phase"] = "land"
            h["roulette_time"] = 2.40
            h["roulette_label"] = str(face.get("name", ""))
            h["roulette_spin_id"] = str(face.get("id", ""))
            h["roulette_desc"] = _roulette_face_desc(face)
            h["roulette_pending"] = {}
    elif phase == "land":
        if float(h["roulette_time"]) <= 0.0:
            heroes[slot] = h
            _begin_next_roulette(slot)
            return
    heroes[slot] = h

func _absorb_roulette_shield(h: Dictionary, amount: float) -> float:
    var left := amount
    var timed_list: Array = h.get("rl_timed", [])
    for i in range(timed_list.size()):
        var buff: Dictionary = timed_list[i]
        var shield_left := float(buff.get("shield", 0.0))
        if shield_left <= 0.0 or left <= 0.0:
            continue
        var take := minf(shield_left, left)
        buff["shield"] = shield_left - take
        timed_list[i] = buff
        left -= take
    h["rl_timed"] = timed_list
    return left

func _note_life_hitter(target: int, owner: int) -> void:
    _note_life_damage(target, owner, 1.0)

func _note_life_damage(target: int, owner: int, amount: float) -> void:
    if owner < 0 or owner == target or target < 0 or target >= heroes.size():
        return
    if amount <= 0.5:
        return
    var h: Dictionary = heroes[target]
    var hits: Dictionary = h.get("life_hits", {})
    var key := str(owner)
    var rec: Dictionary = hits.get(key, {"dmg": 0.0, "tick": 0})
    rec["dmg"] = float(rec.get("dmg", 0.0)) + amount
    rec["tick"] = tick
    hits[key] = rec
    h["life_hits"] = hits
    heroes[target] = h

func _assist_slots(owner: int, target: int, hits: Dictionary) -> Array:
    var need := 28.0
    if target >= 0 and target < heroes.size():
        need = maxf(28.0, float(heroes[target]["max_hp"]) * 0.25)
    elif target < 0 and bool(mid_tower.get("spawned", false)):
        need = maxf(28.0, float(mid_tower.get("max_hp", TOWER_MAX_HP)) * 0.18)
    var window := int(8.0 / FIXED_DT)
    var out: Array = []
    for key in hits.keys():
        var slot := int(key)
        if slot == owner or slot == target:
            continue
        if slot < 0 or slot >= heroes.size() or not bool(heroes[slot]["alive"]):
            continue
        var rec: Dictionary = hits[key]
        if float(rec.get("dmg", 0.0)) + 0.001 < need:
            continue
        if tick - int(rec.get("tick", 0)) > window:
            continue
        out.append(slot)
    return out


func _attack_direction(direction: Vector2) -> Vector2:
    var dir := direction.normalized()
    return Vector2.RIGHT if dir.length_squared() < 0.1 else dir


func _muzzle_spawn_pos(slot: int, _direction: Vector2) -> Vector2:
    var h: Dictionary = heroes[slot]
    var pos: Vector2 = h["pos"]
    var hop_lift := 0.0
    var hop_time := float(h.get("hop_time", 0.0))
    if hop_time > 0.0:
        var hop_max := maxf(0.001, float(h.get("hop_max", 0.30)))
        var hop_t := clampf(1.0 - hop_time / hop_max, 0.0, 1.0)
        hop_lift = float(h.get("hop_height", 19.0)) * sin(PI * hop_t)
    var body_pos := pos + Vector2(0.0, -hop_lift)
    var equip_id := "burst"
    var held = h.get("equipment", {})
    if typeof(held) == TYPE_DICTIONARY:
        equip_id = str(held.get("id", "burst"))
    var look: Vector2 = h["aim"]
    if look.length_squared() < 0.0001:
        look = h["facing"]
    if look.length_squared() < 0.0001:
        look = Vector2.RIGHT
    return GunSig.muzzle_world_pos(body_pos, look, equip_id)

func _spawn_projectile(slot: int, direction: Vector2, damage: float, speed: float, radius: float, ttl: float, source: StringName, splash: float = 0.0, leech: bool = false, pierce: int = 0, cc_time: float = 0.0, knockback: float = 0.0, kind: StringName = &"bolt", homing: float = 0.0, label: String = "", combo_finisher: bool = false, control_kind: StringName = &"slow") -> void:
    var dir := _attack_direction(direction)
    projectiles.append({
        "id":next_entity_id,
        "owner":slot,
        "pos":_muzzle_spawn_pos(slot, dir),
        "vel":dir * speed,
        "damage":damage,
        "radius":radius,
        "ttl":ttl,
        "splash":splash,
        "leech":leech,
        "pierce":pierce,
        "cc_time":cc_time,
        "knockback":knockback,
        "kind":kind,
        "homing":homing,
        "label":label,
        "combo_finisher":combo_finisher,
        "control_kind":control_kind,
        "hit_targets":[],
        "trail":[_muzzle_spawn_pos(slot, dir)],
        "source":source
    })
    next_entity_id += 1

func _spawn_arc_bomb(slot: int, direction: Vector2, distance: float, flight_time: float, damage: float, blast_radius: float, cc_time: float, knockback: float, combo_finisher: bool) -> void:
    var dir := _attack_direction(direction)
    var start := _muzzle_spawn_pos(slot, dir)
    var landing := Vector2(heroes[slot]["pos"]) + dir * distance
    projectiles.append({
        "id":next_entity_id, "owner":slot, "pos":start,
        "vel":start.direction_to(landing) * start.distance_to(landing) / maxf(0.01, flight_time),
        "landing_pos":landing, "arc":true, "max_ttl":flight_time,
        "damage":damage, "radius":11.0, "ttl":flight_time,
        "splash":blast_radius, "leech":false, "pierce":0,
        "cc_time":cc_time, "knockback":knockback, "kind":&"shell",
        "homing":0.0, "label":"", "combo_finisher":combo_finisher,
        "hit_targets":[], "trail":[start], "source":&"normal"
    })
    next_entity_id += 1

func _normal_combo_pattern(_equipment_id: String) -> Array:
    return []

func _normal_step_reach(slot: int, _step: Dictionary) -> float:
    return _normal_reach(slot)

func _normal_auto_target(slot: int, facing: Vector2, reach: float) -> int:
    return -1
    var h: Dictionary = heroes[slot]
    var origin: Vector2 = h["pos"]
    var best := -1
    var best_score := -999.0
    for target in range(heroes.size()):
        if target == slot or not bool(heroes[target]["alive"]):
            continue
        var target_pos: Vector2 = heroes[target]["pos"]
        var distance := origin.distance_to(target_pos)
        if distance > reach or _line_blocked(origin, target_pos):
            continue
        var to_target := origin.direction_to(target_pos)
        var forward_dot := facing.dot(to_target)
        if forward_dot < 0.45:
            continue
        var score := forward_dot * 2.2 - distance / maxf(1.0, reach)
        if score > best_score:
            best_score = score
            best = target
    return best

func _try_start_reload(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]):
        return
    if float(h.get("reload_left", 0.0)) > 0.0:
        return
    if float(h["stun_time"]) > 0.0 or float(h["launch_time"]) > 0.0:
        return
    var cap := int(h["equipment"].get("mag_size", 1))
    if int(h.get("mag", cap)) >= cap:
        return
    var reload_dur := float(h["equipment"].get("reload_time", 1.2))
    h["reload_left"] = maxf(0.20, reload_dur)
    h["reload_flash"] = 0.0
    h["spray_index"] = 0.0
    h["spray_idle"] = 1.0
    h["action"] = &"RELOAD"
    heroes[slot] = h


func _stamp_gun_fire(h: Dictionary, slot: int, equipment_id: String) -> void:
    var fx: Dictionary = GunSig.fx_for_equipment(equipment_id)
    var frames := maxi(1, int(fx.get("frames", 2)))
    h["muzzle_row"] = int(fx.get("row", 0))
    h["muzzle_time"] = float(frames) * 0.055
    h["muzzle_scale"] = float(fx.get("scale", 1.0))
    if slot == local_slot:
        local_fire_shake = int(fx.get("shake", 3))

func _try_normal_attack(slot: int, direction: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]) or float(h["fire_cd"]) > 0.0 or float(h["launch_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
        return
    if _hero_has_timed(h, "turtle"):
        return
    if float(h.get("reload_left", 0.0)) > 0.0:
        return
    if int(h.get("mag", 1)) <= 0:
        _try_start_reload(slot)
        return
    var equipment: Dictionary = h["equipment"]
    var equipment_id := str(equipment["id"])
    var base_dir := _attack_direction(direction)
    h["facing"] = base_dir
    h["aim"] = base_dir
    var pellet_count := maxi(1, int(equipment.get("normal_projectiles", 1)))
    var spread := float(equipment.get("normal_spread", 0.0))
    var damage := float(equipment.get("normal_damage", 6.0))
    var knockback := float(equipment.get("normal_knockback", 6.0))
    var kind := StringName(equipment.get("normal_kind", "bolt"))
    if equipment_id == "rail":
        kind = &"tracer"
    elif kind != &"pellet" and kind != &"bolt" and kind != &"shell":
        kind = &"bolt"
    var speed := float(equipment.get("normal_speed", 980.0))
    var ttl := float(equipment.get("normal_range", 0.6))
    var pierce := int(equipment.get("normal_pierce", 0))
    var splash := float(equipment.get("normal_splash", 0.0))
    var radius := float(equipment.get("normal_radius", 5.0))
    var interval := float(equipment.get("normal_interval", 0.2))
    interval *= maxf(0.35, 1.0 - _roulette_stat(slot, "rate"))
    ttl *= 1.0 + _roulette_stat(slot, "range")
    var spray_i := int(floor(float(h.get("spray_index", 0.0))))
    var kick: Vector2 = GunSig.spray_kick(equipment_id, spray_i)
    h["spray_index"] = float(spray_i + 1)
    h["spray_idle"] = 0.0
    if slot == local_slot:
        local_mouse_kick = kick
    if equipment_id == "mortar":
        _spawn_projectile(slot, base_dir, damage, speed, maxf(radius, 12.0), ttl, &"normal", splash if splash > 1.0 else 120.0, false, 0, 0.0, knockback, &"shell", 0.0, "", false)
    else:
        for index in range(pellet_count):
            var offset: float = 0.0
            if pellet_count > 1:
                offset = (float(index) - float(pellet_count - 1) * 0.5) * spread
            _spawn_projectile(slot, base_dir.rotated(offset), damage, speed, radius, ttl, &"normal", splash, false, pierce, 0.0, knockback, kind, 0.0, "", false)
    var burst_cap := int(equipment.get("burst_shots", 0))
    var mag_cap := int(equipment.get("mag_size", 0))
    if burst_cap > 0 and mag_cap <= 0:
        var left := int(h.get("burst_left", burst_cap)) - 1
        if left <= 0:
            interval = float(equipment.get("reload_time", 1.1))
            left = burst_cap
        h["burst_left"] = left
    h["mag"] = maxi(0, int(h.get("mag", mag_cap)) - 1)
    if int(h["mag"]) <= 0:
        h["fire_cd"] = interval
        h["attack_lock_time"] = minf(0.12, interval * 0.45)
        h["normal_step"] = 0
        h["normal_chain_time"] = 0.0
        h["normal_interval"] = interval
        h["combo_target"] = -1
        h["action"] = &"GUN_FIRE"
        _stamp_gun_fire(h, slot, equipment_id)
        heroes[slot] = h
        event_log.emit(tick, &"gun_fire", slot, -1, {"equipment":equipment_id, "gun":equipment.get("name", ""), "mode":equipment.get("fire_mode", "auto")})
        _try_start_reload(slot)
        return
    h["fire_cd"] = interval
    h["attack_lock_time"] = minf(0.12, interval * 0.45)
    h["normal_step"] = 0
    h["normal_chain_time"] = 0.0
    h["normal_interval"] = interval
    h["combo_target"] = -1
    h["action"] = &"GUN_FIRE"
    _stamp_gun_fire(h, slot, equipment_id)
    heroes[slot] = h
    event_log.emit(tick, &"gun_fire", slot, -1, {"equipment":equipment_id, "gun":equipment.get("name", ""), "mode":equipment.get("fire_mode", "auto")})

func _normal_reach(slot: int) -> float:
    var equipment: Dictionary = heroes[slot]["equipment"]
    return float(equipment["normal_speed"]) * float(equipment["normal_range"]) * 0.92 * (1.0 + _roulette_stat(slot, "range"))

func _normal_combo_length(_slot: int) -> int:
    return 1

func _equipment_reach(slot: int) -> float:
    return _normal_reach(slot)

func _add_effect(kind: StringName, pos: Vector2, radius: float, duration: float, color: Color, label: String = "", direction: Vector2 = Vector2.RIGHT) -> void:
    effects.append({"kind":kind, "pos":pos, "radius":radius, "time":duration, "max_time":duration, "color":color, "label":label, "direction":direction})

func _add_zone(owner: int, pos: Vector2, radius: float, delay: float, damage: float, source: StringName, cc_time: float, knockback: float, label: String, color: Color, leech: bool = false, effect_kind: StringName = &"explosion", combo_finisher: bool = false, control_kind: StringName = &"slow") -> void:
    zones.append({"id":next_entity_id, "owner":owner, "pos":pos, "radius":radius, "delay":delay, "warning_duration":delay, "time":delay + 0.28, "damage":damage, "applied":false, "source":source, "cc_time":cc_time, "knockback":knockback, "label":label, "color":color, "leech":leech, "effect_kind":effect_kind, "combo_finisher":combo_finisher, "control_kind":control_kind, "telegraphed":delay > 0.06})
    next_entity_id += 1

func _place_mine(owner: int, desired_pos: Vector2, damage: float, blast_radius: float, arm_time: float = 0.62, lifetime: float = 8.0, fuse_time: float = 0.38, ultimate_mine: bool = false, auto_detonate: float = -1.0) -> void:
    var owner_pos: Vector2 = heroes[owner]["pos"]
    var mine_pos := _resolve_cover_motion(owner_pos, desired_pos - owner_pos)
    mine_pos.x = clampf(mine_pos.x, ARENA_MARGIN + 18.0, ARENA_SIZE.x - ARENA_MARGIN - 18.0)
    mine_pos.y = clampf(mine_pos.y, ARENA_MARGIN + 18.0, ARENA_SIZE.y - ARENA_MARGIN - 18.0)
    if not ultimate_mine:
        var owner_mines: Array[int] = []
        for mine_index in range(deployables.size()):
            if int(deployables[mine_index]["owner"]) == owner and not bool(deployables[mine_index].get("ultimate", false)):
                owner_mines.append(mine_index)
        if owner_mines.size() >= 2:
            var removed_index := owner_mines[0]
            _add_effect(&"mine_fizzle", Vector2(deployables[removed_index]["pos"]), 42.0, 0.24, Color("#8ca0b8"), "REPLACED")
            deployables.remove_at(removed_index)
    deployables.append({
        "id":next_entity_id, "type":&"mine", "owner":owner, "pos":mine_pos,
        "damage":damage, "blast_radius":blast_radius,
        "trigger_radius":minf(126.0, blast_radius * 0.72),
        "arm_time":arm_time, "arm_duration":arm_time,
        "lifetime":lifetime, "max_lifetime":lifetime,
        "triggered":false, "fuse_time":fuse_time, "fuse_duration":fuse_time,
        "cc_time":0.55 if ultimate_mine else 0.40,
        "knockback":175.0 if ultimate_mine else 140.0,
        "ultimate":ultimate_mine, "auto_detonate":auto_detonate
    })
    next_entity_id += 1
    _add_effect(&"mine_place", mine_pos, 48.0, 0.28, Color("#ff765f"), "MINE")
    event_log.emit(tick, &"mine_placed", owner, -1, {"ultimate":ultimate_mine})

func _place_bounce_wall(owner: int, desired_pos: Vector2, facing: Vector2, half_length: float, lifetime: float, speed: float, damage: float, knockback: float) -> void:
    for wall_index in range(deployables.size() - 1, -1, -1):
        if int(deployables[wall_index]["owner"]) == owner and StringName(deployables[wall_index].get("type", &"mine")) == &"wall":
            _add_effect(&"mine_fizzle", Vector2(deployables[wall_index]["pos"]), 58.0, 0.26, Color("#8de1ff"), "REPLACED")
            deployables.remove_at(wall_index)
    var owner_pos: Vector2 = heroes[owner]["pos"]
    var wall_pos := _resolve_cover_motion(owner_pos, desired_pos - owner_pos)
    var travel_direction := _attack_direction(facing)
    wall_pos.x = clampf(wall_pos.x, ARENA_MARGIN + 26.0, ARENA_SIZE.x - ARENA_MARGIN - 26.0)
    wall_pos.y = clampf(wall_pos.y, ARENA_MARGIN + 26.0, ARENA_SIZE.y - ARENA_MARGIN - 26.0)
    deployables.append({
        "id":next_entity_id, "type":&"wall", "owner":owner, "pos":wall_pos,
        "direction":travel_direction.orthogonal(), "travel_direction":travel_direction,
        "half_length":half_length, "speed":speed, "damage":damage, "knockback":knockback,
        "arm_time":0.18, "arm_duration":0.18,
        "lifetime":lifetime, "max_lifetime":lifetime, "hit_slots":[], "hit_cores":[]
    })
    next_entity_id += 1
    _add_effect(&"charge_release", wall_pos, half_length, 0.18, Color("#8de1ff"), "INCOMING", travel_direction)
    event_log.emit(tick, &"wall_placed", owner, -1, {"half_length":half_length, "speed":speed})

func _moving_wall_sweep(wall: Dictionary, old_pos: Vector2, new_pos: Vector2) -> Dictionary:
    var owner := int(wall["owner"])
    var forward := Vector2(wall["travel_direction"]).normalized()
    var side := Vector2(wall["direction"]).normalized()
    var travel_distance := old_pos.distance_to(new_pos)
    var hit_slots: Array = wall.get("hit_slots", [])
    for target in range(PLAYER_COUNT):
        if target == owner or target in hit_slots or not bool(heroes[target]["alive"]):
            continue
        var relative := Vector2(heroes[target]["pos"]) - old_pos
        var forward_distance := relative.dot(forward)
        var side_distance := absf(relative.dot(side))
        if forward_distance < -HERO_RADIUS - 10.0 or forward_distance > travel_distance + HERO_RADIUS + 14.0 or side_distance > float(wall["half_length"]) + HERO_RADIUS:
            continue
        hit_slots.append(target)
        _damage_hero(owner, target, float(wall["damage"]), &"equipment", 0.32, float(wall["knockback"]), Vector2(heroes[target]["pos"]) - forward * 34.0, "WALL SLAM", &"shield_bash", true)
        var victim: Dictionary = heroes[target]
        victim["wall_hit_cd"] = 0.78
        heroes[target] = victim
        _add_effect(&"wall_impact", Vector2(heroes[target]["pos"]), 102.0, 0.30, Color("#8de1ff"), "SLAM", forward)
    wall["hit_slots"] = hit_slots
    var hit_cores: Array = wall.get("hit_cores", [])
    for target in range(PLAYER_COUNT):
        if target == owner or target in hit_cores or not bool(cores[target]["alive"]) or not _core_exposed(target):
            continue
        var relative := Vector2(cores[target]["pos"]) - old_pos
        if relative.dot(forward) < -CORE_RADIUS or relative.dot(forward) > travel_distance + CORE_RADIUS or absf(relative.dot(side)) > float(wall["half_length"]) + CORE_RADIUS:
            continue
        hit_cores.append(target)
        _damage_core(owner, target, float(wall["damage"]) * 0.62, &"equipment")
    wall["hit_cores"] = hit_cores
    return wall

func _mine_has_target(mine: Dictionary) -> bool:
    var owner := int(mine["owner"])
    var mine_pos: Vector2 = mine["pos"]
    var trigger_radius := float(mine["trigger_radius"])
    for target in range(PLAYER_COUNT):
        if target == owner:
            continue
        if bool(heroes[target]["alive"]) and mine_pos.distance_to(Vector2(heroes[target]["pos"])) <= trigger_radius + HERO_RADIUS:
            return true
        if bool(cores[target]["alive"]) and _core_exposed(target) and mine_pos.distance_to(Vector2(cores[target]["pos"])) <= trigger_radius + CORE_RADIUS:
            return true
    return false

func _update_deployables(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for mine0 in deployables:
        var mine: Dictionary = mine0
        if StringName(mine.get("type", &"mine")) == &"wall":
            if float(mine.get("arm_time", 0.0)) > 0.0:
                mine["arm_time"] = maxf(0.0, float(mine["arm_time"]) - dt)
                kept.append(mine)
                continue
            mine["lifetime"] = float(mine["lifetime"]) - dt
            if float(mine["lifetime"]) <= 0.0:
                _add_effect(&"mine_fizzle", Vector2(mine["pos"]), float(mine["half_length"]), 0.24, Color("#8de1ff"), "")
                continue
            var old_wall_pos: Vector2 = mine["pos"]
            var wall_motion := Vector2(mine["travel_direction"]) * float(mine["speed"]) * dt
            var next_wall_pos := old_wall_pos + wall_motion
            var hit_boundary := next_wall_pos.x < ARENA_MARGIN + 24.0 or next_wall_pos.x > ARENA_SIZE.x - ARENA_MARGIN - 24.0 or next_wall_pos.y < ARENA_MARGIN + 24.0 or next_wall_pos.y > ARENA_SIZE.y - ARENA_MARGIN - 24.0
            var hit_cover := _point_in_cover(next_wall_pos, 34.0)
            if hit_boundary or hit_cover:
                _add_effect(&"wall_impact", old_wall_pos, float(mine["half_length"]), 0.30, Color("#8de1ff"), "CRASH", Vector2(mine["travel_direction"]))
                continue
            mine["pos"] = next_wall_pos
            mine = _moving_wall_sweep(mine, old_wall_pos, next_wall_pos)
            kept.append(mine)
            continue
        mine["lifetime"] = float(mine["lifetime"]) - dt
        if float(mine["lifetime"]) <= 0.0:
            _add_effect(&"mine_fizzle", Vector2(mine["pos"]), 42.0, 0.24, Color("#8ca0b8"), "EXPIRED")
            continue
        if float(mine["arm_time"]) > 0.0:
            mine["arm_time"] = maxf(0.0, float(mine["arm_time"]) - dt)
            kept.append(mine)
            continue
        if not bool(mine["triggered"]):
            if float(mine.get("auto_detonate", -1.0)) >= 0.0:
                mine["auto_detonate"] = float(mine["auto_detonate"]) - dt
            if _mine_has_target(mine) or (float(mine.get("auto_detonate", -1.0)) >= -0.5 and float(mine.get("auto_detonate", -1.0)) <= 0.0):
                mine["triggered"] = true
                mine["fuse_time"] = float(mine["fuse_duration"])
                _add_effect(&"fuse", Vector2(mine["pos"]), float(mine["trigger_radius"]), float(mine["fuse_duration"]), Color("#ff554a"), "MOVE!")
                event_log.emit(tick, &"mine_triggered", int(mine["owner"]), -1, {})
            kept.append(mine)
            continue
        mine["fuse_time"] = float(mine["fuse_time"]) - dt
        if float(mine["fuse_time"]) <= 0.0:
            _add_zone(int(mine["owner"]), Vector2(mine["pos"]), float(mine["blast_radius"]), 0.01, float(mine["damage"]), &"ultimate" if bool(mine["ultimate"]) else &"equipment", float(mine["cc_time"]), float(mine["knockback"]), "PANIC MINE" if bool(mine["ultimate"]) else "PROX MINE", Color("#ff554a"), false, &"explosion", true)
            continue
        kept.append(mine)
    deployables = kept

func _deployable_wall_hit(slot: int, old_pos: Vector2, new_pos: Vector2) -> Dictionary:
    if float(heroes[slot].get("wall_hit_cd", 0.0)) > 0.0:
        return {}
    for wall in deployables:
        if StringName(wall.get("type", &"mine")) != &"wall" or int(wall["owner"]) == slot or float(wall.get("arm_time", 0.0)) > 0.0 or slot in Array(wall.get("hit_slots", [])):
            continue
        var wall_pos: Vector2 = wall["pos"]
        var wall_dir := Vector2(wall["direction"]).normalized()
        var wall_a := wall_pos - wall_dir * float(wall["half_length"])
        var wall_b := wall_pos + wall_dir * float(wall["half_length"])
        var closest := Geometry2D.get_closest_point_to_segment(new_pos, wall_a, wall_b)
        var crossed := Geometry2D.segment_intersects_segment(old_pos, new_pos, wall_a, wall_b) != null
        if not crossed and new_pos.distance_to(closest) > HERO_RADIUS + 9.0:
            continue
        var normal := Vector2(wall.get("travel_direction", wall_dir.orthogonal())).normalized()
        if not crossed and (new_pos - old_pos).dot(normal) >= 0.0:
            continue
        return {"id":int(wall["id"]), "owner":int(wall["owner"]), "pos":closest, "normal":normal, "damage":float(wall["damage"]), "knockback":float(wall["knockback"])}
    return {}

func _mark_wall_hit(wall_id: int, slot: int) -> void:
    for index in range(deployables.size()):
        if int(deployables[index].get("id", -1)) != wall_id:
            continue
        var hit_slots: Array = deployables[index].get("hit_slots", [])
        if slot not in hit_slots:
            hit_slots.append(slot)
            deployables[index]["hit_slots"] = hit_slots
        return

func _break_incoming_combo(slot: int) -> void:
    if slot < 0 or slot >= heroes.size():
        return
    var victim: Dictionary = heroes[slot]
    var owner := int(victim.get("combo_owner", -1))
    victim["combo_capture_time"] = 0.0
    victim["combo_hits"] = 0
    victim["combo_time"] = 0.0
    victim["combo_damage"] = 0.0
    victim["combo_owner"] = -1
    victim["combo_immunity"] = maxf(float(victim["combo_immunity"]), 0.52)
    heroes[slot] = victim
    if owner >= 0 and owner < heroes.size():
        var attacker: Dictionary = heroes[owner]
        if int(attacker.get("combo_target", -1)) == slot:
            attacker["combo_target"] = -1
            attacker["normal_step"] = 0
            attacker["normal_chain_time"] = 0.0
            heroes[owner] = attacker

func _try_mobility(slot: int, direction: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]) or float(h["mobility_cd"]) > 0.0 or float(h["launch_time"]) > 0.0 or float(h["root_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
        return
    if _hero_has_timed(h, "turtle"):
        return
    var escaped_combo := float(h["combo_capture_time"]) > 0.0
    if escaped_combo:
        _break_incoming_combo(slot)
        h = heroes[slot]
    _cancel_skill_charge(slot)
    _cancel_attack_recovery(slot)
    h = heroes[slot]
    var equipment: Dictionary = h["equipment"]
    var equipment_id := str(equipment["id"])
    var dir := _attack_direction(direction)
    var distance := float(equipment["mobility_distance"])
    var old_pos: Vector2 = h["pos"]
    h["pos"] = _resolve_cover_motion(old_pos, dir * distance)
    h["pos"] = Vector2(
        clampf(Vector2(h["pos"]).x, ARENA_MARGIN + HERO_RADIUS, ARENA_SIZE.x - ARENA_MARGIN - HERO_RADIUS),
        clampf(Vector2(h["pos"]).y, ARENA_MARGIN + HERO_RADIUS, ARENA_SIZE.y - ARENA_MARGIN - HERO_RADIUS)
    )
    h["mobility_cd"] = float(equipment["mobility_cooldown"])
    h["action"] = &"MOBILITY"
    h["evade_time"] = maxf(float(h["evade_time"]), 0.20)
    if int(h["combo_hits"]) > 0:
        h["combo_hits"] = 0
        h["combo_time"] = 0.0
        h["combo_damage"] = 0.0
        h["combo_owner"] = -1
        h["combo_immunity"] = 0.72
        h["hitstun_time"] = 0.0
        _add_effect(&"combo_break", old_pos, 72.0, 0.34, Color("#6ef3a5"), "COMBO BREAK", dir)
    elif escaped_combo:
        _add_effect(&"combo_break", old_pos, 72.0, 0.34, Color("#6ef3a5"), "ESCAPE", dir)
    match equipment_id:
        "scatter":
            _add_effect(&"speed_streak", Vector2(h["pos"]), distance, 0.30, Color("#ffb45c"), "SKIRMISH HOP", -dir)
        "rail":
            _add_effect(&"beam_step", Vector2(h["pos"]), distance, 0.26, Color("#71e7ff"), "SIGHTLINE STEP", -dir)
        "mortar":
            _add_effect(&"explosion", old_pos, 105.0, 0.36, Color("#ff604f"), "BLAST HOP")
            heroes[slot] = h
            for target in range(PLAYER_COUNT):
                if target != slot and bool(heroes[target]["alive"]) and old_pos.distance_to(Vector2(heroes[target]["pos"])) <= 120.0:
                    _damage_hero(slot, target, 2.0, &"mobility", 0.12, 72.0, old_pos, "BLAST HOP", &"explosion")
            h = heroes[slot]
        "leech":
            h["hp"] = minf(float(h["max_hp"]), float(h["hp"]) + 8.0)
            _add_effect(&"drain", Vector2(h["pos"]), 88.0, 0.42, Color("#d45cff"), "+8 SHADOW PULL", -dir)
        "breaker":
            h["guard_time"] = 0.80
            _add_effect(&"guard", Vector2(h["pos"]), 68.0, 0.80, Color("#ffe066"), "IRON MARCH", dir)
        "burst":
            _add_effect(&"speed_streak", Vector2(h["pos"]), distance, 0.28, Color("#ff5ca8"), "FLASH CUT", -dir)
        "blade":
            h["evade_time"] = 0.48
            _add_effect(&"slash_dash", Vector2(h["pos"]), distance, 0.34, Color("#b9f3ff"), "SHADOW SHEATH", -dir)
        "brawler":
            h["combo_immunity"] = 0.95
            _add_effect(&"speed_streak", Vector2(h["pos"]), distance, 0.28, Color("#ff9466"), "WEAVE", -dir)
        "bomb":
            _add_effect(&"fuse", old_pos, 75.0, 0.50, Color("#ff5d4f"), "BLAST ROLL")
        "spear":
            _add_effect(&"spear_line", Vector2(h["pos"]), distance, 0.32, Color("#ffe27a"), "POLE VAULT", -dir)
        "chain":
            _add_effect(&"chain_arc", Vector2(h["pos"]), distance, 0.34, Color("#b78cff"), "SWING STEP", -dir)
        _:
            h["guard_time"] = 1.20
            _add_effect(&"guard", Vector2(h["pos"]), 78.0, 1.20, Color("#8de1ff"), "BRACE STEP", dir)
    heroes[slot] = h
    event_log.emit(tick, &"mobility_used", slot, -1, {"equipment":equipment_id, "name":equipment["mobility_name"]})

func _cancel_attack_recovery(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    h["attack_lock_time"] = 0.0
    h["fire_cd"] = minf(float(h["fire_cd"]), 0.04)
    heroes[slot] = h

func _cancel_skill_charge(slot: int) -> void:
    if slot < 0 or slot >= heroes.size():
        return
    var h: Dictionary = heroes[slot]
    h["charging_skill"] = false
    h["charge_time"] = 0.0
    heroes[slot] = h

func _begin_skill_charge(_slot: int, _direction: Vector2) -> void:
    return

func _continue_skill_charge(_slot: int, _dt: float, _direction: Vector2) -> void:
    return

func _release_skill_charge(_slot: int, _direction: Vector2) -> void:
    return

func _try_equipment_attack(_slot: int, _direction: Vector2, _charge_ratio: float = 1.0) -> void:
    return



func _begin_ox_gore(slot: int, direction: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    var dir: Vector2 = direction
    if dir.length_squared() < 0.05:
        dir = Vector2(h.get("facing", Vector2.RIGHT))
    if dir.length_squared() < 0.05:
        dir = Vector2.RIGHT
    dir = dir.normalized()
    h["ox_phase"] = "back"
    h["ox_time"] = 0.18
    h["ox_dir"] = dir
    h["ox_hit"] = []
    h["facing"] = dir
    heroes[slot] = h
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.40
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "ox_gore"})

func _tick_ox_charges(dt: float) -> void:
    for slot in range(heroes.size()):
        var h: Dictionary = heroes[slot]
        var phase := str(h.get("ox_phase", ""))
        if phase == "":
            continue
        if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
            h["ox_phase"] = ""
            heroes[slot] = h
            continue
        var dir: Vector2 = h.get("ox_dir", Vector2.RIGHT)
        if dir.length_squared() < 0.05:
            dir = Vector2.RIGHT
        dir = dir.normalized()
        h["ox_time"] = float(h.get("ox_time", 0.0)) - dt
        if phase == "back":
            h["vel"] = -dir * 380.0
            h["facing"] = dir
            if float(h["ox_time"]) <= 0.0:
                h["ox_phase"] = "rush"
                h["ox_time"] = 0.38
                h["ox_hit"] = []
        elif phase == "rush":
            h["vel"] = dir * 1100.0
            h["facing"] = dir
            var hit: Array = h.get("ox_hit", [])
            for other in range(heroes.size()):
                if other == slot or other in hit:
                    continue
                var t: Dictionary = heroes[other]
                if not bool(t.get("alive", false)) or bool(t.get("downed", false)):
                    continue
                if Vector2(h["pos"]).distance_to(Vector2(t["pos"])) > 62.0:
                    continue
                hit.append(other)
                t["stun_time"] = maxf(float(t.get("stun_time", 0.0)), 1.35)
                t["vel"] = dir * 260.0
                t["pos"] = _resolve_cover_motion(Vector2(t["pos"]), dir * 70.0)
                heroes[other] = t
            h["ox_hit"] = hit
            if float(h["ox_time"]) <= 0.0:
                h["ox_phase"] = ""
                h["vel"] = Vector2.ZERO
        heroes[slot] = h

func _begin_rat_tide(slot: int, direction: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    var dir: Vector2 = direction
    if dir.length_squared() < 0.05:
        dir = Vector2(h.get("facing", Vector2.RIGHT))
    if dir.length_squared() < 0.05:
        dir = Vector2.RIGHT
    dir = dir.normalized()
    rat_tides.append({
        "owner": slot,
        "pos": Vector2(h["pos"]) + dir * 70.0,
        "dir": dir,
        "life": 1.70,
        "travel": 720.0,
        "half_w": 118.0,
        "length": 360.0
    })
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.28
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "rat_tide"})

func _hero_in_rat_tide(hpos: Vector2, tide: Dictionary) -> bool:
    var dir: Vector2 = tide["dir"]
    var rel: Vector2 = hpos - Vector2(tide["pos"])
    var along := rel.dot(dir)
    var side := absf(rel.dot(dir.rotated(PI * 0.5)))
    var leng := float(tide.get("length", 360.0))
    return along > -leng * 0.28 and along < leng * 0.72 and side <= float(tide.get("half_w", 118.0))

func _apply_rat_tides(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for tide0 in rat_tides:
        var tide: Dictionary = tide0
        tide["life"] = float(tide.get("life", 0.0)) - dt
        if float(tide["life"]) <= 0.0:
            continue
        var dir: Vector2 = Vector2(tide["dir"])
        tide["pos"] = Vector2(tide["pos"]) + dir * float(tide.get("travel", 720.0)) * dt
        for slot in range(heroes.size()):
            if slot == int(tide.get("owner", -1)):
                continue
            var h: Dictionary = heroes[slot]
            if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
                continue
            if not _hero_in_rat_tide(Vector2(h["pos"]), tide):
                continue
            var wish: Vector2 = h.get("vel", Vector2.ZERO)
            var along := wish.dot(dir)
            var resist := 1.0
            if along < -20.0:
                resist = 0.40
            var lateral: Vector2 = wish - dir * along
            h["vel"] = lateral * 0.50 + dir * (860.0 * resist)
            heroes[slot] = h
        kept.append(tide)
    rat_tides = kept

func _try_ultimate(slot: int, _direction: Vector2) -> void:
    if slot < 0 or slot >= heroes.size():
        return
    var h: Dictionary = heroes[slot]
    if not bool(h.get("alive", false)):
        return
    if float(h.get("ultimate_charge", 0.0)) < ULTIMATE_MAX - 0.5:
        return
    var animal := posmod(int(h.get("animal", slot)), 12)
    if animal != 0 and animal != 1 and animal != 2 and animal != 3 and animal != 4 and animal != 5 and animal != 6 and animal != 7 and animal != 8 and animal != 9 and animal != 10 and animal != 11:
        return
    h["ultimate_charge"] = 0.0
    h["ultimates"] = int(h.get("ultimates", 0)) + 1
    heroes[slot] = h
    if animal == 0:
        _begin_rat_tide(slot, _direction)
        return
    if animal == 1:
        _begin_ox_gore(slot, _direction)
        return
    if animal == 2:
        _begin_tiger_roar(slot)
        return
    if animal == 3:
        _begin_rabbit_burrow(slot, _direction)
        return
    if animal == 4:
        _begin_dragon_smoke(slot)
        return
    if animal == 5:
        _begin_snake_shed(slot)
        return
    if animal == 6:
        _begin_horse_kick(slot)
        return
    if animal == 7:
        _begin_wool_shield(slot)
        return
    if animal == 9:
        _begin_rooster_egg(slot)
        return
    if animal == 10:
        _begin_dog_fetch(slot, _direction)
        return
    if animal == 11:
        _begin_pig_mud(slot)
        return
    h["ult_clone_time"] = 8.0
    var origin: Vector2 = h["pos"]
    var clones: Array = []
    for i in range(1, 8):
        var ang := TAU * 0.125 * float(i)
        clones.append({
            "alive": true,
            "ang": ang,
            "pos": origin,
            "facing": Vector2(h.get("facing", Vector2.RIGHT)).rotated(ang),
            "aim": Vector2(h.get("aim", Vector2.RIGHT)).rotated(ang),
            "hop_time": float(h.get("hop_time", 0.0)),
            "hop_height": float(h.get("hop_height", HOP_LIFT_DEFAULT)),
            "animal": int(h.get("animal", slot)),
            "owner": slot
        })
    h["ult_clones"] = clones
    heroes[slot] = h
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.28
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "mirage", "clones": 7})









func _begin_dog_fetch(slot: int, aim_pos: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    var dest: Vector2 = _clamp_arena_point(aim_pos, HERO_RADIUS)
    dest = _nudge_out_of_cover(dest, HERO_RADIUS)
    dog_bones.append({"pos": dest, "owner": slot, "ttl": 5.0})
    h["dog_rush"] = false
    h["dog_windup"] = 1.0
    h["dog_bone"] = dest
    h["dog_hit"] = []
    heroes[slot] = h
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.18
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "dog_fetch"})

func _tick_dog_rush(dt: float) -> void:
    for slot in range(heroes.size()):
        var h: Dictionary = heroes[slot]
        var wind := float(h.get("dog_windup", 0.0))
        if wind > 0.0:
            wind = maxf(0.0, wind - dt)
            h["dog_windup"] = wind
            if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
                h["dog_windup"] = 0.0
                h["dog_rush"] = false
                heroes[slot] = h
                continue
            if wind <= 0.0:
                h["dog_rush"] = true
                h["dog_hit"] = []
                h["super_armor_time"] = 2.2
                h["super_armor_strength"] = 1.0
            heroes[slot] = h
            if not bool(h.get("dog_rush", false)):
                continue
        if not bool(h.get("dog_rush", false)):
            continue
        if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
            h["dog_rush"] = false
            h["dog_windup"] = 0.0
            heroes[slot] = h
            continue
        var dest: Vector2 = h.get("dog_bone", Vector2(h["pos"]))
        var pos: Vector2 = Vector2(h["pos"])
        var to: Vector2 = dest - pos
        if to.length() <= 36.0:
            h["dog_rush"] = false
            h["vel"] = Vector2.ZERO
            h["super_armor_time"] = 0.0
            heroes[slot] = h
            continue
        var dir := to.normalized()
        h["facing"] = dir
        h["vel"] = dir * 1020.0
        h["super_armor_time"] = maxf(float(h.get("super_armor_time", 0.0)), 0.2)
        h["super_armor_strength"] = 1.0
        var hit: Array = h.get("dog_hit", [])
        for t in range(heroes.size()):
            if t == slot or t in hit:
                continue
            var vic: Dictionary = heroes[t]
            if not bool(vic.get("alive", false)) or bool(vic.get("eliminated", false)):
                continue
            if bool(vic.get("burrowed", false)):
                continue
            if pos.distance_to(Vector2(vic["pos"])) > 52.0:
                continue
            hit.append(t)
            var push := dir * 780.0
            vic["launch_vel"] = push
            vic["launch_time"] = maxf(float(vic.get("launch_time", 0.0)), 0.48)
            vic["stun_time"] = maxf(float(vic.get("stun_time", 0.0)), 1.25)
            vic["vel"] = push
            vic["pos"] = _resolve_cover_motion(Vector2(vic["pos"]), dir * 90.0)
            heroes[t] = vic
        h["dog_hit"] = hit
        heroes[slot] = h
    var kept: Array[Dictionary] = []
    for bone0 in dog_bones:
        var bone: Dictionary = bone0
        bone["ttl"] = float(bone.get("ttl", 0.0)) - dt
        var owner := int(bone.get("owner", -1))
        if owner >= 0 and owner < heroes.size() and (bool(heroes[owner].get("dog_rush", false)) or float(heroes[owner].get("dog_windup", 0.0)) > 0.0):
            bone["ttl"] = maxf(float(bone["ttl"]), 0.05)
        if float(bone["ttl"]) > 0.0:
            kept.append(bone)
    dog_bones = kept


func _wool_shield_pos(h: Dictionary) -> Vector2:
    return Vector2(h["pos"])

func _begin_wool_shield(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    h["wool_time"] = 5.0
    h["wool_hp"] = 5
    h["wool_max"] = 5
    heroes[slot] = h
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.16
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "wool_shield"})

func _tick_wool_shields(dt: float) -> void:
    for slot in range(heroes.size()):
        var h: Dictionary = heroes[slot]
        if float(h.get("wool_time", 0.0)) <= 0.0:
            continue
        if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
            h["wool_time"] = 0.0
            h["wool_hp"] = 0
            heroes[slot] = h
            continue
        h["wool_time"] = float(h["wool_time"]) - dt
        if float(h["wool_time"]) <= 0.0:
            h["wool_time"] = 0.0
            h["wool_hp"] = 0
        heroes[slot] = h

func _absorb_wool_shield(owner: int, target: int, pos: Vector2, radius: float) -> bool:
    if target < 0 or target >= heroes.size():
        return false
    if owner == target:
        return false
    var h: Dictionary = heroes[target]
    if float(h.get("wool_time", 0.0)) <= 0.0 or int(h.get("wool_hp", 0)) <= 0:
        return false
    if not bool(h.get("alive", false)):
        return false
    var shield: Vector2 = _wool_shield_pos(h)
    if pos.distance_to(shield) > radius + 58.0:
        return false
    h["wool_hp"] = int(h.get("wool_hp", 0)) - 1
    _add_effect(&"impact", shield, 36.0, 0.18, Color("#fff6d8"), "")
    if int(h["wool_hp"]) <= 0:
        h["wool_time"] = 0.0
        heroes[target] = h
        _pop_wool_shield(target)
        return true
    heroes[target] = h
    return true

func _pop_wool_shield(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    var center: Vector2 = _wool_shield_pos(h)
    _add_effect(&"explosion", center, 150.0, 0.36, Color("#fff1c8"), "")
    for t in range(heroes.size()):
        if t == slot:
            continue
        var vic: Dictionary = heroes[t]
        if not bool(vic.get("alive", false)) or bool(vic.get("eliminated", false)):
            continue
        if bool(vic.get("burrowed", false)):
            continue
        if Vector2(vic["pos"]).distance_to(center) > 150.0:
            continue
        var dir: Vector2 = center.direction_to(Vector2(vic["pos"]))
        if dir.length_squared() < 0.0001:
            dir = Vector2(h.get("facing", Vector2.RIGHT))
        var push := dir * 560.0
        vic["launch_vel"] = push
        vic["launch_time"] = maxf(float(vic.get("launch_time", 0.0)), 0.38)
        vic["stun_time"] = maxf(float(vic.get("stun_time", 0.0)), 0.55)
        vic["vel"] = push
        vic["pos"] = _resolve_cover_motion(Vector2(vic["pos"]), dir * 70.0)
        heroes[t] = vic

func _begin_pig_mud(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    pig_muds.append({
        "owner": slot,
        "pos": Vector2(h["pos"]),
        "radius": 200.0,
        "ttl": 6.0
    })
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.18
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "pig_mud"})

func _tick_pig_muds(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for mud0 in pig_muds:
        var mud: Dictionary = mud0
        mud["ttl"] = float(mud.get("ttl", 0.0)) - dt
        if float(mud["ttl"]) > 0.0:
            kept.append(mud)
    pig_muds = kept

func _pos_in_enemy_mud(slot: int) -> bool:
    if slot < 0 or slot >= heroes.size():
        return false
    var pos: Vector2 = heroes[slot]["pos"]
    for mud in pig_muds:
        if int(mud.get("owner", -1)) == slot:
            continue
        if pos.distance_to(Vector2(mud.get("pos", Vector2.ZERO))) <= float(mud.get("radius", 200.0)):
            return true
    return false

func _begin_rooster_egg(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    rooster_eggs.append({
        "owner": slot,
        "pos": Vector2(h["pos"]),
        "ttl": 8.0,
        "arm": 0.55,
        "trigger": 150.0,
        "alive": true
    })
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.18
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "rooster_egg"})

func _tick_rooster_eggs(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for egg0 in rooster_eggs:
        var egg: Dictionary = egg0
        if not bool(egg.get("alive", true)):
            continue
        egg["ttl"] = float(egg.get("ttl", 0.0)) - dt
        egg["arm"] = maxf(0.0, float(egg.get("arm", 0.0)) - dt)
        if float(egg["ttl"]) <= 0.0:
            continue
        var origin: Vector2 = egg.get("pos", Vector2.ZERO)
        var trig := float(egg.get("trigger", 150.0)) + HERO_RADIUS
        var boom := false
        if float(egg.get("arm", 0.0)) <= 0.0:
            for t in range(heroes.size()):
                var vic: Dictionary = heroes[t]
                if not bool(vic.get("alive", false)) or bool(vic.get("eliminated", false)):
                    continue
                if bool(vic.get("burrowed", false)):
                    continue
                if Vector2(vic["pos"]).distance_to(origin) <= trig:
                    boom = true
                    break
        if boom:
            _explode_rooster_egg(egg)
            continue
        kept.append(egg)
    rooster_eggs = kept

func _explode_rooster_egg(egg: Dictionary) -> void:
    var origin: Vector2 = egg.get("pos", Vector2.ZERO)
    var owner := int(egg.get("owner", -1))
    var blast := 170.0
    for t in range(heroes.size()):
        if t == owner:
            continue
        var vic: Dictionary = heroes[t]
        if not bool(vic.get("alive", false)) or bool(vic.get("eliminated", false)):
            continue
        if bool(vic.get("burrowed", false)):
            continue
        if Vector2(vic["pos"]).distance_to(origin) > blast:
            continue
        var away: Vector2 = Vector2(vic["pos"]) - origin
        if away.length_squared() < 0.01:
            away = Vector2.RIGHT
        away = away.normalized()
        vic["stun_time"] = maxf(float(vic.get("stun_time", 0.0)), 1.20)
        vic["vel"] = away * 220.0
        heroes[t] = vic
    _add_effect(&"stun_burst", origin, 70.0, 0.36, Color("#ffe27a"), "EGG")
    event_log.emit(tick, &"rooster_egg_boom", owner, -1, {})

func _begin_horse_kick(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    var face: Vector2 = Vector2(h.get("facing", Vector2.RIGHT))
    if face.length_squared() < 0.05:
        face = Vector2.RIGHT
    face = face.normalized()
    var back := -face
    var origin: Vector2 = Vector2(h["pos"])
    var reach := 400.0
    var half := 1.15
    horse_kicks.append({"pos": origin, "dir": back, "age": 0.0, "life": 0.42, "reach": reach})
    for t in range(heroes.size()):
        if t == slot:
            continue
        var vic: Dictionary = heroes[t]
        if not bool(vic.get("alive", false)) or bool(vic.get("eliminated", false)):
            continue
        if bool(vic.get("downed", false)) or bool(vic.get("burrowed", false)):
            continue
        var delta: Vector2 = Vector2(vic["pos"]) - origin
        var dist := delta.length()
        if dist > reach or dist < 1.0:
            continue
        if absf(back.angle_to(delta.normalized())) > half:
            continue
        var push := back * 380.0
        vic["launch_vel"] = push
        vic["launch_time"] = maxf(float(vic.get("launch_time", 0.0)), 0.26)
        vic["stun_time"] = maxf(float(vic.get("stun_time", 0.0)), 1.15)
        vic["vel"] = push
        vic["pos"] = _resolve_cover_motion(Vector2(vic["pos"]), back * 72.0)
        heroes[t] = vic
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.22
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "horse_kick"})

func _tick_horse_kicks(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for kick0 in horse_kicks:
        var kick: Dictionary = kick0
        kick["age"] = float(kick.get("age", 0.0)) + dt
        if float(kick["age"]) < float(kick.get("life", 0.42)):
            kept.append(kick)
    horse_kicks = kept

func _begin_rabbit_burrow(slot: int, aim_pos: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    if bool(h.get("burrowed", false)) or bool(h.get("downed", false)):
        h["ultimate_charge"] = ULTIMATE_MAX
        heroes[slot] = h
        return
    var enter: Vector2 = Vector2(h["pos"])
    var exit_pos: Vector2 = _clamp_arena_point(aim_pos, HERO_RADIUS)
    exit_pos = _nudge_out_of_cover(exit_pos, HERO_RADIUS)
    rabbit_holes.append({"pos": enter, "ttl": 4.5, "kind": "in"})
    h["burrowed"] = true
    h["burrow_left"] = 2.0
    h["burrow_exit"] = exit_pos
    h["vel"] = Vector2.ZERO
    heroes[slot] = h
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.20
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "rabbit_burrow"})

func _tick_rabbit_burrows(dt: float) -> void:
    for slot in range(heroes.size()):
        var h: Dictionary = heroes[slot]
        if not bool(h.get("burrowed", false)):
            continue
        h["burrow_left"] = float(h.get("burrow_left", 0.0)) - dt
        h["vel"] = Vector2.ZERO
        if float(h["burrow_left"]) <= 0.0:
            var exit_pos: Vector2 = _clamp_arena_point(Vector2(h.get("burrow_exit", h["pos"])), HERO_RADIUS)
            exit_pos = _nudge_out_of_cover(exit_pos, HERO_RADIUS)
            rabbit_holes.append({"pos": exit_pos, "ttl": 3.5, "kind": "out"})
            h["pos"] = exit_pos
            h["burrowed"] = false
            h["burrow_left"] = 0.0
            h["spawn_protect_time"] = maxf(float(h.get("spawn_protect_time", 0.0)), 0.25)
        heroes[slot] = h
    var kept: Array[Dictionary] = []
    for hole0 in rabbit_holes:
        var hole: Dictionary = hole0
        hole["ttl"] = float(hole.get("ttl", 0.0)) - dt
        if float(hole["ttl"]) > 0.0:
            kept.append(hole)
    rabbit_holes = kept

func _begin_tiger_roar(slot: int) -> void:
    var origin: Vector2 = heroes[slot]["pos"]
    tiger_roars.append({"pos": origin, "age": 0.0, "life": 1.15, "radius": 300.0, "owner": slot})
    for t in range(heroes.size()):
        if t == slot:
            continue
        var vic: Dictionary = heroes[t]
        if not bool(vic.get("alive", false)) or bool(vic.get("eliminated", false)):
            continue
        if bool(vic.get("downed", false)):
            continue
        if Vector2(vic["pos"]).distance_to(origin) > 300.0:
            continue
        vic["flee_time"] = 1.5
        vic["flee_from"] = origin
        heroes[t] = vic
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.24
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "tiger_roar"})

func _tick_tiger_roars(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for roar0 in tiger_roars:
        var roar: Dictionary = roar0
        roar["age"] = float(roar.get("age", 0.0)) + dt
        if float(roar["age"]) < float(roar.get("life", 1.15)):
            kept.append(roar)
    tiger_roars = kept

func _apply_flee_vel(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    if float(h.get("flee_time", 0.0)) <= 0.0:
        return
    if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
        return
    if float(h.get("launch_time", 0.0)) > 0.0 or float(h.get("stun_time", 0.0)) > 0.0:
        return
    var away: Vector2 = Vector2(h["pos"]) - Vector2(h.get("flee_from", Vector2.ZERO))
    if away.length_squared() < 0.01:
        away = Vector2(h.get("facing", Vector2.RIGHT))
    h["vel"] = away.normalized() * _hero_move_speed(slot) * 1.12
    heroes[slot] = h

func _begin_dragon_smoke(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    dragon_smokes.append({
        "owner": slot,
        "pos": Vector2(h["pos"]),
        "radius": 560.0,
        "ttl": 15.0
    })
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.22
    _add_effect(&"afterimage", Vector2(h["pos"]), 90.0, 0.28, Color("#c8c8c8"), "SMOKE")
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "dragon_smoke"})

func _tick_dragon_smokes(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for smoke0 in dragon_smokes:
        var smoke: Dictionary = smoke0
        smoke["ttl"] = float(smoke.get("ttl", 0.0)) - dt
        if float(smoke["ttl"]) > 0.0:
            kept.append(smoke)
    dragon_smokes = kept

func _pos_in_dragon_smoke(pos: Vector2) -> bool:
    for smoke in dragon_smokes:
        if pos.distance_to(Vector2(smoke.get("pos", Vector2.ZERO))) <= float(smoke.get("radius", 560.0)):
            return true
    return false

func hero_hidden_in_smoke(slot: int) -> bool:
    if slot < 0 or slot >= heroes.size():
        return false
    var h: Dictionary = heroes[slot]
    if not bool(h.get("alive", false)):
        return false
    if not _pos_in_dragon_smoke(Vector2(h["pos"])):
        return false
    var local_animal := 0
    if local_slot >= 0 and local_slot < heroes.size():
        local_animal = posmod(int(heroes[local_slot].get("animal", local_slot)), 12)
    if slot == local_slot and local_animal == 4:
        return false
    return true

func local_is_dragon() -> bool:
    if local_slot < 0 or local_slot >= heroes.size():
        return false
    return posmod(int(heroes[local_slot].get("animal", local_slot)), 12) == 4

func _begin_snake_shed(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    var max_hp := float(h.get("max_hp", 164.0))
    snake_skins.append({
        "owner": slot,
        "pos": Vector2(h["pos"]),
        "facing": Vector2(h.get("facing", Vector2.RIGHT)),
        "aim": Vector2(h.get("aim", Vector2.RIGHT)),
        "animal": 5,
        "hp": max_hp,
        "max_hp": max_hp,
        "scale": 1.5,
        "ttl": 18.0,
        "flash": 0.0,
        "alive": true
    })
    _apply_roulette_face(slot, {"id":"giant", "name":"GIANT", "kind":"timed", "atk":3.0, "spd":5.0, "def":0.0, "hp":3.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":12.0})
    ultimate_focus_slot = slot
    ultimate_focus_time = 0.28
    _add_effect(&"afterimage", Vector2(h["pos"]), 64.0, 0.32, Color("#9ad47a"), "SHED")
    event_log.emit(tick, &"ultimate_used", slot, -1, {"id": "snake_shed"})

func _tick_snake_skins(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for skin0 in snake_skins:
        var skin: Dictionary = skin0
        if not bool(skin.get("alive", true)):
            continue
        skin["ttl"] = float(skin.get("ttl", 0.0)) - dt
        skin["flash"] = maxf(0.0, float(skin.get("flash", 0.0)) - dt)
        if float(skin["ttl"]) <= 0.0 or float(skin.get("hp", 0.0)) <= 0.0:
            _add_effect(&"hit_spark", Vector2(skin["pos"]), 48.0, 0.24, Color("#b7d59a"), "")
            continue
        kept.append(skin)
    snake_skins = kept

func _hurt_snake_skin(index: int, damage: float) -> bool:
    if index < 0 or index >= snake_skins.size():
        return false
    var skin: Dictionary = snake_skins[index]
    if not bool(skin.get("alive", true)) or damage <= 0.0:
        return false
    skin["hp"] = float(skin.get("hp", 0.0)) - damage
    skin["flash"] = 0.11
    event_log.emit(tick, &"snake_shed_hit", -1, -1, {"damage": damage, "pos": Vector2(skin["pos"])})
    if float(skin["hp"]) <= 0.0:
        skin["hp"] = 0.0
        skin["alive"] = false
        snake_skins[index] = skin
        _add_effect(&"hit_spark", Vector2(skin["pos"]), 52.0, 0.28, Color("#c8e8a8"), "SHED")
        event_log.emit(tick, &"snake_shed_break", -1, -1, {})
        return true
    snake_skins[index] = skin
    return true

func _hit_snake_skin(owner: int, ppos: Vector2, radius: float, damage: float) -> bool:
    var best := -1
    var best_d := 99999.0
    for i in range(snake_skins.size()):
        var skin: Dictionary = snake_skins[i]
        if not bool(skin.get("alive", true)):
            continue
        if int(skin.get("owner", -1)) == owner:
            continue
        var d := ppos.distance_to(Vector2(skin.get("pos", Vector2.ZERO)))
        var skin_r := HERO_RADIUS * float(skin.get("scale", 1.5))
        if d < radius + skin_r and d < best_d:
            best_d = d
            best = i
    if best < 0:
        return false
    return _hurt_snake_skin(best, damage)

func _sync_ult_clones(dt: float) -> void:
    for slot in range(heroes.size()):
        var h: Dictionary = heroes[slot]
        var left := float(h.get("ult_clone_time", 0.0))
        if left <= 0.0:
            if h.get("ult_clones", []):
                h["ult_clones"] = []
                heroes[slot] = h
            continue
        left = maxf(0.0, left - dt)
        h["ult_clone_time"] = left
        if left <= 0.0 or not bool(h.get("alive", false)) or bool(h.get("downed", false)):
            h["ult_clones"] = []
            heroes[slot] = h
            continue
        var vel: Vector2 = h.get("vel", Vector2.ZERO)
        var facing: Vector2 = h.get("facing", Vector2.RIGHT)
        var aim: Vector2 = h.get("aim", facing)
        var clones: Array = h.get("ult_clones", [])
        var kept: Array = []
        for clone in clones:
            if not bool(clone.get("alive", true)):
                continue
            var ang := float(clone.get("ang", 0.0))
            var mirrored: Vector2 = vel.rotated(ang)
            var next_pos: Vector2 = _resolve_cover_motion(Vector2(clone.get("pos", h["pos"])), mirrored * dt)
            next_pos = _clamp_arena_point(next_pos, HERO_RADIUS)
            clone["pos"] = next_pos
            clone["facing"] = facing.rotated(ang)
            clone["aim"] = aim.rotated(ang)
            clone["hop_time"] = h.get("hop_time", 0.0)
            clone["hop_height"] = h.get("hop_height", HOP_LIFT_DEFAULT)
            clone["animal"] = int(h.get("animal", slot))
            clone["owner"] = slot
            kept.append(clone)
        h["ult_clones"] = kept
        heroes[slot] = h

func _pop_ult_clone(slot: int, index: int) -> void:
    if slot < 0 or slot >= heroes.size():
        return
    var h: Dictionary = heroes[slot]
    var clones: Array = h.get("ult_clones", [])
    if index < 0 or index >= clones.size():
        return
    var c: Dictionary = clones[index]
    var pos: Vector2 = c.get("pos", h.get("pos", Vector2.ZERO))
    clones.remove_at(index)
    h["ult_clones"] = clones
    heroes[slot] = h
    _add_effect(&"hit_spark", pos, 42.0, 0.22, Color("#c9e7ff"), "")
    event_log.emit(tick, &"clone_pop", slot, -1, {})

func _hit_ult_clone(owner: int, ppos: Vector2, radius: float) -> bool:
    for slot in range(heroes.size()):
        if slot == owner:
            continue
        var h: Dictionary = heroes[slot]
        if float(h.get("ult_clone_time", 0.0)) <= 0.0:
            continue
        var clones: Array = h.get("ult_clones", [])
        for i in range(clones.size()):
            var c: Dictionary = clones[i]
            if not bool(c.get("alive", true)):
                continue
            if ppos.distance_to(Vector2(c.get("pos", Vector2.ZERO))) < radius + HERO_RADIUS:
                _pop_ult_clone(slot, i)
                return true
    return false

func _ultimate_armor(_equipment_id: String) -> Dictionary:
    return {"duration":0.0, "strength":0.0}

func _highest_threat_except(excluded: int) -> int:
    var best := -1
    var best_value := -1.0
    for slot in range(PLAYER_COUNT):
        if slot == excluded or not bool(cores[slot]["alive"]):
            continue
        var value := float(heroes[slot]["threat"]) + float(heroes[slot]["bounty"])
        if value > best_value:
            best_value = value
            best = slot
    return best

func _projectile_impact_kind(kind: String) -> StringName:
    match kind:
        "beam": return &"beam_hit"
        "shell", "seeker": return &"explosion"
        "tether": return &"drain"
        "hammer": return &"hammer_slam"
        "slash": return &"slashwave"
        "fist": return &"fist_burst"
        "bomb": return &"explosion"
        "spear": return &"spear_line"
        "chain": return &"chain_arc"
        "shield": return &"shield_bash"
        _: return &"hit_spark"

func _update_projectiles(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for p0 in projectiles:
        var p: Dictionary = p0
        if bool(p.get("arc", false)):
            p["ttl"] = float(p["ttl"]) - dt
            p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * dt
            var arc_trail: Array = p.get("trail", [])
            if tick % 2 == 0:
                arc_trail.append(Vector2(p["pos"]))
                if arc_trail.size() > 14:
                    arc_trail.pop_front()
            p["trail"] = arc_trail
            if float(p["ttl"]) <= 0.0:
                var landing: Vector2 = p["landing_pos"]
                _add_zone(int(p["owner"]), landing, float(p["splash"]), 0.01, float(p["damage"]), &"normal", float(p["cc_time"]), float(p["knockback"]), "", Color("#ff554a"), false, &"explosion", bool(p["combo_finisher"]))
                var boom_t := 34.0 / 60.0 if str(heroes[int(p["owner"])]["equipment"].get("id", "")) == "mortar" else 0.32
                _add_effect(&"explosion", landing, float(p["splash"]), boom_t, Color("#ff554a"), "")
                continue
            kept.append(p)
            continue
        if float(p.get("homing", 0.0)) > 0.0:
            var owner_slot := int(p["owner"])
            var nearest := -1
            var nearest_distance := 999999.0
            for candidate in range(PLAYER_COUNT):
                if candidate == owner_slot or not bool(heroes[candidate]["alive"]):
                    continue
                var distance := Vector2(p["pos"]).distance_to(Vector2(heroes[candidate]["pos"]))
                if distance < nearest_distance:
                    nearest_distance = distance
                    nearest = candidate
            if nearest >= 0:
                var current_speed := Vector2(p["vel"]).length()
                var desired := Vector2(p["pos"]).direction_to(Vector2(heroes[nearest]["pos"]))
                var turn := clampf(float(p["homing"]) * dt, 0.0, 1.0)
                p["vel"] = Vector2(p["vel"]).normalized().lerp(desired, turn).normalized() * current_speed
        p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * dt
        var trail: Array = p.get("trail", [])
        if tick % 2 == 0:
            trail.append(Vector2(p["pos"]))
            if trail.size() > 14:
                trail.pop_front()
        p["trail"] = trail
        p["ttl"] = float(p["ttl"]) - dt
        if _point_in_cover(Vector2(p["pos"])):
            if float(p.get("splash", 0.0)) > 0.0:
                _splash_damage(int(p["owner"]), Vector2(p["pos"]), float(p["splash"]), float(p["damage"]) * 0.55, -1, StringName(p["source"]), float(p.get("cc_time", 0.0)) * 0.65, float(p.get("knockback", 0.0)) * 0.65)
                _add_effect(&"explosion", Vector2(p["pos"]), float(p["splash"]), 0.32, Color("#ff554a"), "")
            else:
                _add_effect(&"impact", Vector2(p["pos"]), maxf(30.0, float(p["splash"])), 0.24, Color("#c4d0df"), "BLOCKED")
            event_log.emit(tick, &"shot_blocked", int(p["owner"]), -1, {"source":p["source"]})
            continue
        var owner := int(p["owner"])
        var hit := false
        for target in range(PLAYER_COUNT):
            if target == owner or not bool(cores[target]["alive"]):
                continue
            if target in p["hit_targets"]:
                continue
            if _absorb_wool_shield(owner, target, Vector2(p["pos"]), float(p["radius"])):
                hit = true
                break
            if bool(heroes[target]["alive"]) and not bool(heroes[target].get("burrowed", false)) and Vector2(p["pos"]).distance_to(Vector2(heroes[target]["pos"])) < float(p["radius"]) + HERO_RADIUS:
                var from_pos: Vector2 = Vector2(p["pos"])
                if owner >= 0 and owner < heroes.size():
                    from_pos = Vector2(heroes[owner]["pos"])
                _damage_hero(owner, target, float(p["damage"]), StringName(p["source"]), float(p["cc_time"]), float(p.get("knockback", 0.0)), from_pos, str(p.get("label", "")), _projectile_impact_kind(str(p.get("kind", "bolt"))), bool(p.get("combo_finisher", false)), StringName(p.get("control_kind", &"slow")))
                if float(p["splash"]) > 0.0:
                    _splash_damage(owner, Vector2(p["pos"]), float(p["splash"]), float(p["damage"]) * 0.55, target, StringName(p["source"]), float(p["cc_time"]) * 0.65, float(p.get("knockback", 0.0)) * 0.65)
                if bool(p["leech"]):
                    _heal_hero(owner, float(p["damage"]) * 0.13)
                var hit_targets: Array = p["hit_targets"]
                hit_targets.append(target)
                p["hit_targets"] = hit_targets
                if int(p["pierce"]) > 0:
                    p["pierce"] = int(p["pierce"]) - 1
                    continue
                hit = true
                break
            if owner >= 0 and Vector2(p["pos"]).distance_to(Vector2(cores[target]["pos"])) < float(p["radius"]) + CORE_RADIUS:
                _damage_core(owner, target, float(p["damage"]) * 0.78, StringName(p["source"]))
                hit = true
                break
        if not hit:
            if _hit_snake_skin(owner, Vector2(p["pos"]), float(p["radius"]), float(p["damage"])):
                hit = true
        if not hit:
            if _hit_ult_clone(owner, Vector2(p["pos"]), float(p["radius"])):
                hit = true
        if not hit:
            for crate_i in range(crates.size()):
                var crate_hit: Dictionary = crates[crate_i]
                if not bool(crate_hit["alive"]):
                    continue
                if Vector2(p["pos"]).distance_to(Vector2(crate_hit["pos"])) < float(p["radius"]) + CRATE_RADIUS:
                    _hurt_crate(crate_i, float(p["damage"]))
                    if float(p["splash"]) > 0.0:
                        _damage_crates_at(Vector2(p["pos"]), float(p["splash"]), float(p["damage"]))
                    hit = true
                    break
        if not hit and owner >= 0 and bool(mid_tower.get("alive", false)):
            if Vector2(p["pos"]).distance_to(Vector2(mid_tower["pos"])) < float(p["radius"]) + TOWER_RADIUS:
                _hurt_tower(owner, float(p["damage"]))
                if float(p["splash"]) > 0.0:
                    _hurt_tower(owner, float(p["damage"]) * 0.35)
                hit = true
        var projectile_pos: Vector2 = p["pos"]
        if not hit and float(p["ttl"]) > 0.0 and projectile_pos.x >= 0.0 and projectile_pos.x <= ARENA_SIZE.x and projectile_pos.y >= 0.0 and projectile_pos.y <= ARENA_SIZE.y:
            kept.append(p)
    projectiles = kept

func _splash_damage(owner: int, center: Vector2, radius: float, damage: float, primary: int, source: StringName, cc_time: float = 0.0, knockback: float = 0.0) -> void:
    for target in range(PLAYER_COUNT):
        if target == owner or target == primary or not bool(heroes[target]["alive"]):
            continue
        if center.distance_to(Vector2(heroes[target]["pos"])) <= radius:
            _damage_hero(owner, target, damage, source, cc_time, knockback, center, "SPLASH", &"explosion")
    _damage_crates_at(center, radius, damage)
    for si in range(snake_skins.size()):
        var sk: Dictionary = snake_skins[si]
        if not bool(sk.get("alive", true)):
            continue
        if int(sk.get("owner", -1)) == owner:
            continue
        if center.distance_to(Vector2(sk.get("pos", Vector2.ZERO))) <= radius + HERO_RADIUS * float(sk.get("scale", 1.5)):
            _hurt_snake_skin(si, damage)

func _update_zones(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for z0 in zones:
        var z: Dictionary = z0
        z["delay"] = maxf(0.0, float(z.get("delay", 0.0)) - dt)
        if not bool(z["applied"]) and float(z["delay"]) <= 0.0:
            z["applied"] = true
            var owner := int(z["owner"])
            var total_damage := 0.0
            for target in range(PLAYER_COUNT):
                if target == owner or not bool(heroes[target]["alive"]):
                    continue
                if Vector2(z["pos"]).distance_to(Vector2(heroes[target]["pos"])) <= float(z["radius"]) + HERO_RADIUS:
                    _damage_hero(owner, target, float(z["damage"]), StringName(z.get("source", &"equipment")), float(z.get("cc_time", 0.0)), float(z.get("knockback", 52.0)), Vector2(z["pos"]), "", &"hit_spark", bool(z.get("combo_finisher", false)), StringName(z.get("control_kind", &"slow")))
                    total_damage += float(z["damage"])
            for target in range(PLAYER_COUNT):
                if target == owner or not bool(cores[target]["alive"]):
                    continue
                if Vector2(z["pos"]).distance_to(Vector2(cores[target]["pos"])) <= float(z["radius"]) + CORE_RADIUS:
                    _damage_core(owner, target, float(z["damage"]) * 0.72, StringName(z.get("source", &"equipment")))
            if bool(z.get("leech", false)) and total_damage > 0.0:
                _heal_hero(owner, total_damage * 0.32)
            var zone_direction := Vector2(heroes[owner]["pos"]).direction_to(Vector2(z["pos"]))
            if zone_direction.length_squared() < 0.1:
                zone_direction = Vector2(heroes[owner]["aim"])
            if StringName(z.get("source", &"equipment")) != &"normal" or bool(z.get("telegraphed", false)):
                _add_effect(StringName(z.get("effect_kind", &"explosion")), Vector2(z["pos"]), float(z["radius"]), 0.34, Color(z.get("color", Color.WHITE)), "", zone_direction)
            _damage_crates_at(Vector2(z["pos"]), float(z["radius"]), float(z["damage"]))
        z["time"] = float(z["time"]) - dt
        if float(z["time"]) > 0.0:
            kept.append(z)
    zones = kept

func _update_effects(dt: float) -> void:
    var kept: Array[Dictionary] = []
    for effect0 in effects:
        var effect: Dictionary = effect0
        effect["time"] = float(effect["time"]) - dt
        if float(effect["time"]) > 0.0:
            kept.append(effect)
    effects = kept

func _damage_hero(owner: int, target: int, amount: float, source: StringName = &"normal", cc_time: float = 0.0, knockback: float = 0.0, impact_origin: Vector2 = Vector2.ZERO, effect_label: String = "", effect_kind: StringName = &"hit_spark", attack_finisher: bool = false, control_kind: StringName = &"slow") -> void:
    var h: Dictionary = heroes[target]
    if not bool(h["alive"]):
        return
    if bool(h.get("burrowed", false)):
        return
    if float(h.get("spawn_protect_time", 0.0)) > 0.0:
        return
    if float(h["evade_time"]) > 0.0:
        h["evade_time"] = 0.0
        heroes[target] = h
        _add_effect(&"afterimage", Vector2(h["pos"]), 105.0, 0.38, Color("#b9f3ff"), "EVADE")
        event_log.emit(tick, &"attack_evaded", owner, target, {"source":source})
        return
    var attacker: Dictionary = heroes[owner]
    var attacker_id := str(attacker["equipment"]["id"])
    amount *= _streak_damage_multiplier(owner)
    if float(attacker.get("dmg_orb_time", 0.0)) > 0.0:
        amount *= CRATE_ORB_DMG_MUL
    if attacker_id == "brawler" and float(attacker["hp"]) <= float(attacker["max_hp"]) * 0.5:
        amount *= 1.12
    elif attacker_id == "rail" and Vector2(attacker["pos"]).distance_to(Vector2(h["pos"])) >= 430.0:
        amount *= 1.12
    elif attacker_id == "spear" and Vector2(attacker["pos"]).distance_to(Vector2(h["pos"])) >= 280.0:
        amount *= 1.12
    amount *= 1.0 + clampf((match_time - 65.0) / 35.0, 0.0, 1.25)
    var combo_hit := 0
    if bool(h["charging_skill"]):
        h["charging_skill"] = false
        h["charge_time"] = 0.0
        _add_effect(&"charge_break", Vector2(h["pos"]), 54.0, 0.22, Color("#8ca0b8"), "")
    if source != &"mobility":
        if float(h["combo_time"]) <= 0.0 or float(h["combo_immunity"]) > 0.0 or int(h["combo_owner"]) != owner:
            h["combo_hits"] = 1
            h["combo_damage"] = 0.0
        else:
            h["combo_hits"] = int(h["combo_hits"]) + 1
        combo_hit = int(h["combo_hits"])
        h["combo_owner"] = owner
        h["combo_time"] = 0.38 if attack_finisher else 1.05
        amount *= 1.0 + minf(0.12, float(combo_hit - 1) * 0.06)
    amount += _roulette_stat(owner, "atk")
    amount *= maxf(0.05, 1.0 - _roulette_stat(target, "def"))
    amount = _absorb_roulette_shield(h, amount)
    if float(h["guard_time"]) > 0.0:
        amount *= 0.55
        knockback *= 0.52
    var armor_active := float(h["super_armor_time"]) > 0.0
    var armor_strength := clampf(float(h["super_armor_strength"]), 0.0, 1.0) if armor_active else 0.0
    if armor_active:
        h["combo_capture_time"] = 0.0
    if source != &"mobility" and not bool(h.get("downed", false)):
        var combo_cap := float(h["max_hp"]) * float(h["equipment"]["combo_cap_ratio"])
        var combo_remaining := maxf(0.0, combo_cap - float(h["combo_damage"]))
        amount = minf(amount, combo_remaining)
        h["combo_damage"] = float(h["combo_damage"]) + amount
    h["hp"] = float(h["hp"]) - amount
    h["recent_attacker"] = owner
    h["grudge"] = minf(1.0, float(h["grudge"]) + amount / 100.0)
    if owner >= 0:
        var hits: Dictionary = h.get("life_hits", {})
        var key := str(owner)
        var rec: Dictionary = hits.get(key, {"dmg": 0.0, "tick": 0})
        rec["dmg"] = float(rec.get("dmg", 0.0)) + amount
        rec["tick"] = tick
        hits[key] = rec
        h["life_hits"] = hits
    if not armor_active and cc_time > 0.0:
        h["cc_time"] = maxf(float(h["cc_time"]), cc_time)
        match control_kind:
            &"root":
                h["root_time"] = maxf(float(h["root_time"]), cc_time)
                h["vel"] = Vector2.ZERO
                _add_effect(&"chain_bind", Vector2(h["pos"]), 48.0, minf(0.48, cc_time), Color("#b78cff"), "ROOTED")
            &"stun":
                h["stun_time"] = maxf(float(h["stun_time"]), cc_time)
                h["vel"] = Vector2.ZERO
                h["charging_skill"] = false
                h["charge_time"] = 0.0
                _add_effect(&"stun_burst", Vector2(h["pos"]), 58.0, minf(0.52, cc_time), Color("#ffe27a"), "STUNNED")
    var gun_combat := source == &"normal"
    var heavy_blast := effect_kind == &"explosion" or effect_label == "SPLASH"
    if combo_hit > 0 and not gun_combat:
        var hitstun := 0.04 if float(h["combo_immunity"]) > 0.0 else minf(0.28, 0.07 + combo_hit * 0.055)
        if attacker_id == "chain":
            hitstun += 0.05
        if not armor_active:
            h["hitstun_time"] = maxf(float(h["hitstun_time"]), hitstun)
    var launch_knockback := knockback
    if gun_combat and not heavy_blast and not attack_finisher:
        launch_knockback = 0.0
        if absf(knockback) > 0.01 and not armor_active:
            var shove_dir := impact_origin.direction_to(Vector2(h["pos"])) if impact_origin != Vector2.ZERO else Vector2(heroes[owner]["pos"]).direction_to(Vector2(h["pos"]))
            if shove_dir.length_squared() < 0.1:
                shove_dir = Vector2(heroes[owner]["aim"])
            var shove := clampf(5.0 + absf(knockback) * 0.35, 5.0, 16.0)
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), shove_dir * shove)
        if attacker_id == "chain" and not armor_active:
            var tug_distance := Vector2(h["pos"]).distance_to(Vector2(attacker["pos"]))
            var tug_direction := Vector2(h["pos"]).direction_to(Vector2(attacker["pos"]))
            var tug := minf(20.0, maxf(0.0, tug_distance - 55.0))
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), tug_direction * tug)
    elif source == &"normal" and attack_finisher:
        var launch_sign := -1.0 if launch_knockback < 0.0 else 1.0
        launch_knockback = launch_sign * (absf(launch_knockback) + 104.0)
        h["combo_capture_time"] = 0.0
        _add_effect(&"combo_finisher", Vector2(h["pos"]), 118.0, 0.34, Color("#fff2b2"), "", Vector2(attacker["pos"]).direction_to(Vector2(h["pos"])))
        event_log.emit(tick, &"combo_finisher", owner, target, {"damage":float(h["combo_damage"]), "hits":combo_hit})
        impact_ticks = maxi(impact_ticks, 18)
    if armor_active:
        launch_knockback *= 1.0 - armor_strength
        if absf(launch_knockback) < 55.0:
            launch_knockback = 0.0
    if absf(launch_knockback) > 0.01:
        h["combo_capture_time"] = 0.0
        var origin := impact_origin if impact_origin != Vector2.ZERO else Vector2(heroes[owner]["pos"])
        var push_direction := origin.direction_to(Vector2(h["pos"]))
        if push_direction.length_squared() < 0.1:
            push_direction = Vector2(heroes[owner]["aim"])
        var launch_direction := push_direction if launch_knockback > 0.0 else -push_direction
        var launch_speed := (900.0 + absf(launch_knockback) * 9.8) / float(h["equipment"]["weight"])
        h["launch_vel"] = launch_direction * launch_speed
        h["launch_time"] = clampf(0.22 + absf(launch_knockback) * 0.0022, 0.26, 0.72)
        h["wall_bounces"] = 0
        h["launch_owner"] = owner
        h["launch_trail"] = [Vector2(h["pos"])]
        h["launch_trail_fade"] = 0.34
        h["launch_wall_damage"] = float(h["combo_damage"]) if source != &"mobility" else 0.0
        h["vel"] = Vector2.ZERO
    heroes[target] = h
    attacker = heroes[owner]
    attacker["threat"] = float(attacker["threat"]) + amount * 0.38
    attacker["damage_dealt"] = float(attacker["damage_dealt"]) + amount
    attacker["score"] = float(attacker["score"]) + amount
    heroes[owner] = attacker
    if amount > 0.01:
        _award_charge(owner, amount, source)
    var impact_radius := clampf(24.0 + amount * 1.4 + absf(knockback) * 0.12, 32.0, 125.0)
    var effect_direction := Vector2(h["launch_vel"]).normalized() if Vector2(h["launch_vel"]).length_squared() > 0.1 else Vector2(heroes[owner]["pos"]).direction_to(Vector2(h["pos"]))
    _add_effect(effect_kind, Vector2(h["pos"]), impact_radius, 0.22 if source == &"normal" else 0.42, Color("#ffffff"), effect_label, effect_direction)
    if amount > 0.01 and source != &"safe_zone":
        h["hit_flash"] = 0.11
        heroes[target] = h
        if target == local_slot:
            local_hit_shake = 10
        if owner == local_slot:
            local_hit_shake = maxi(local_hit_shake, 8)
    event_log.emit(tick, &"hero_hit", owner, target, {"damage":amount, "knockback":launch_knockback, "label":effect_label, "source":source, "combo":combo_hit})
    if owner == 0 or target == 0:
        impact_ticks = maxi(impact_ticks, 4 if source == &"normal" else (11 if source == &"equipment" else 18))
        impact_pos = Vector2(h["pos"])
    if bool(h.get("downed", false)):
        h["hp"] = 0.0
        h["down_taken"] = float(h.get("down_taken", 0.0)) + amount
        heroes[target] = h
        if float(h["down_taken"]) >= DOWN_FINISH_HP:
            _down_hero(owner, target)
    elif float(h["hp"]) <= 0.0:
        _enter_down(owner, target)

func _damage_core(owner: int, target: int, amount: float, source: StringName = &"normal") -> void:
    var core: Dictionary = cores[target]
    if not bool(core["alive"]):
        return
    if not _core_exposed(target):
        impact_ticks = maxi(impact_ticks, 2)
        event_log.emit(tick, &"core_shield_blocked", owner, target, {"source":source})
        return
    # A crowd-control opening is short and risky to create, so confirmed core
    # hits must feel decisive instead of being lost to the next shield cycle.
    amount *= _streak_damage_multiplier(owner)
    amount *= 1.15
    core["hp"] = float(core["hp"]) - amount
    cores[target] = core
    _award_charge(owner, amount * 0.55, source)
    var attacker: Dictionary = heroes[owner]
    attacker["threat"] = float(attacker["threat"]) + amount * 0.52
    attacker["core_damage"] = float(attacker["core_damage"]) + amount
    attacker["score"] = float(attacker["score"]) + amount * 1.5
    heroes[owner] = attacker
    impact_pos = Vector2(core["pos"])
    event_log.emit(tick, &"core_hit", owner, target, {"damage":amount, "remaining":maxf(0.0, float(core["hp"]))})
    if float(core["hp"]) <= 0.0:
        core["hp"] = 0.0
        core["alive"] = false
        cores[target] = core
        event_log.emit(tick, &"core_destroyed", owner, target, {})

func _award_charge(slot: int, amount: float, source: StringName) -> void:
    if source == &"ultimate" or source == &"mobility" or slot < 0 or slot >= heroes.size():
        return
    var h: Dictionary = heroes[slot]
    if source == &"equipment":
        h["equipment_hits"] = int(h["equipment_hits"]) + 1
    else:
        h["normal_hits"] = int(h["normal_hits"]) + 1
    h["ultimate_charge"] = minf(ULTIMATE_MAX, float(h.get("ultimate_charge", 0.0)) + maxf(4.0, amount * 0.12))
    heroes[slot] = h

func _heal_hero(slot: int, amount: float) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]):
        return
    var before := float(h["hp"])
    h["hp"] = minf(float(h["max_hp"]), before + amount)
    heroes[slot] = h
    var gained := float(h["hp"]) - before
    if gained > 0.4:
        event_log.emit(tick, &"hero_heal", slot, -1, {"amount": gained})

func _item_kind_color(kind: String) -> Color:
    match kind:
        "spring":
            return Color("#ffe066")
        "slide":
            return Color("#70e7ff")
        "pull":
            return Color("#b78cff")
        "pocket":
            return Color("#f4e2ff")
        _:
            return Color("#6ef3a5")

func _roll_pickup_kind(pickup: Dictionary) -> void:
    var roll: float = rng.rangef(0.0, 1.0)
    var kind := "medkit"
    if roll < 0.30:
        kind = "medkit"
    elif roll < 0.48:
        kind = "spring"
    elif roll < 0.66:
        kind = "slide"
    elif roll < 0.80:
        kind = "pull"
    elif roll < 0.90:
        kind = "pocket"
    else:
        kind = "decoy"
    pickup["kind"] = kind
    if kind == "decoy":
        var faces := ["medkit", "spring", "slide", "pull", "pocket"]
        pickup["disguise"] = str(faces[rng.rangei(0, faces.size() - 1)])
    else:
        pickup["disguise"] = kind

func _spawn_dropped_pickup(pos: Vector2, kind: String, ignore_slot: int = -1) -> void:
    if kind == "" or kind == "decoy":
        return
    var drop_pos: Vector2 = _clamp_arena_point(pos, HEALTH_PICKUP_RADIUS)
    for pickup_index in range(health_pickups.size()):
        var old_pickup: Dictionary = health_pickups[pickup_index]
        if bool(old_pickup.get("ephemeral", false)) and not bool(old_pickup["active"]):
            old_pickup["pos"] = drop_pos
            old_pickup["home"] = drop_pos
            old_pickup["kind"] = kind
            old_pickup["disguise"] = kind
            old_pickup["active"] = true
            old_pickup["respawn"] = 0.0
            old_pickup["magnet_slot"] = -1
            old_pickup["ignore_slot"] = ignore_slot
            old_pickup["ignore_time"] = ITEM_DROP_IGNORE if ignore_slot >= 0 else 0.0
            health_pickups[pickup_index] = old_pickup
            return
    health_pickups.append({
        "id":health_pickups.size(),
        "pos":drop_pos,
        "home":drop_pos,
        "magnet_slot":-1,
        "active":true,
        "respawn":0.0,
        "kind":kind,
        "disguise":kind,
        "ephemeral":true,
        "ignore_slot":ignore_slot,
        "ignore_time":ITEM_DROP_IGNORE if ignore_slot >= 0 else 0.0
    })

func _explode_decoy(slot: int, origin: Vector2) -> void:
    if slot < 0 or slot >= heroes.size():
        return
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]):
        return
    if float(h.get("spawn_protect_time", 0.0)) > 0.0:
        return
    if float(h.get("evade_time", 0.0)) > 0.0:
        h["evade_time"] = 0.0
        heroes[slot] = h
        _add_effect(&"afterimage", Vector2(h["pos"]), 105.0, 0.38, Color("#b9f3ff"), "EVADE")
        event_log.emit(tick, &"attack_evaded", -1, slot, {"source":&"decoy"})
        return
    h["hp"] = float(h["hp"]) - DECOY_DAMAGE
    var push: Vector2 = origin.direction_to(Vector2(h["pos"]))
    if push.length_squared() < 0.1:
        push = Vector2(h.get("facing", Vector2.RIGHT))
    var launch_speed: float = (900.0 + DECOY_KNOCK * 9.8) / maxf(0.35, float(h["equipment"]["weight"]))
    h["launch_vel"] = push * launch_speed
    h["launch_time"] = 0.28
    h["vel"] = Vector2.ZERO
    h["launch_owner"] = -1
    heroes[slot] = h
    _add_effect(&"explosion", origin, 78.0, 0.40, Color("#ff665a"), "DECOY")
    event_log.emit(tick, &"decoy_exploded", -1, slot, {"damage":DECOY_DAMAGE})
    _apply_lethal_or_down(-1, slot, DECOY_DAMAGE)

func _collect_item_pickup(slot: int, pickup: Dictionary) -> Dictionary:
    var kind := str(pickup.get("kind", "medkit"))
    var target_pos: Vector2 = heroes[slot]["pos"]
    if kind == "decoy":
        _explode_decoy(slot, Vector2(pickup["pos"]))
        pickup["active"] = false
        pickup["respawn"] = 99999.0 if bool(pickup.get("ephemeral", false)) else HEALTH_PICKUP_RESPAWN
        pickup["magnet_slot"] = -1
        pickup["pos"] = Vector2(pickup["home"])
        return pickup
    var h: Dictionary = heroes[slot]
    var old_item := str(h.get("held_item", ""))
    if old_item != "":
        var drop_pos: Vector2 = target_pos - Vector2(h.get("facing", Vector2.RIGHT)) * 36.0
        _spawn_dropped_pickup(drop_pos, old_item, slot)
    h["held_item"] = kind
    heroes[slot] = h
    pickup["active"] = false
    pickup["respawn"] = 99999.0 if bool(pickup.get("ephemeral", false)) else HEALTH_PICKUP_RESPAWN
    pickup["magnet_slot"] = -1
    pickup["pos"] = Vector2(pickup["home"])
    _add_effect(&"heal_pickup", target_pos, 64.0, 0.38, _item_kind_color(kind), kind.to_upper())
    event_log.emit(tick, &"item_collected", slot, -1, {"kind":kind, "dropped":old_item})
    return pickup

func _steer_slide(slot: int, h: Dictionary, wish: Vector2, control_speed: float, dt: float) -> void:
    var vel: Vector2 = h["vel"]
    var max_speed: float = _hero_move_speed(slot) * control_speed * _streak_move_multiplier(slot)
    if wish.length_squared() > 0.04:
        var wish_dir: Vector2 = wish.normalized()
        vel = vel + wish_dir * SLIDE_ACCEL * dt
        var cap: float = maxf(40.0, max_speed * 1.15)
        if vel.length() > cap:
            vel = vel.normalized() * cap
    else:
        vel = vel.move_toward(Vector2.ZERO, SLIDE_FRICTION * dt)
    h["vel"] = vel
    h["slide_wish"] = wish

func _apply_cpu_move(slot: int, h: Dictionary, wish_dir: Vector2, speed_scale: float) -> void:
    if bool(h.get("dog_rush", false)):
        return
    h["slide_wish"] = wish_dir
    if float(h.get("slide_time", 0.0)) > 0.0:
        return
    var cruise: Vector2 = wish_dir * _hero_move_speed(slot) * speed_scale * _streak_move_multiplier(slot)
    h["vel"] = cruise
    heroes[slot] = h
    _apply_flee_vel(slot)
    h = heroes[slot]
    if float(h.get("spring_time", 0.0)) > 0.0 and wish_dir.length_squared() > 0.1:
        var boosted: Vector2 = Vector2(h["vel"]) + wish_dir.normalized() * SPRING_BOOST
        h["vel"] = boosted

func _pull_target_toward(target: int, user_pos: Vector2) -> void:
    var h: Dictionary = heroes[target]
    var to_user: Vector2 = Vector2(h["pos"]).direction_to(user_pos)
    if to_user.length_squared() < 0.01:
        return
    h["launch_vel"] = to_user * PULL_LAUNCH
    h["launch_time"] = maxf(float(h["launch_time"]), 0.20)
    h["vel"] = Vector2.ZERO
    heroes[target] = h

func _apply_pull_pulse(slot: int, dt: float) -> void:
    var user_pos: Vector2 = heroes[slot]["pos"]
    for target in range(heroes.size()):
        if target == slot:
            continue
        if not bool(heroes[target]["alive"]) or bool(heroes[target]["eliminated"]):
            continue
        if Vector2(heroes[target]["pos"]).distance_to(user_pos) > PULL_RADIUS:
            continue
        _pull_target_toward(target, user_pos)
    for pickup_index in range(health_pickups.size()):
        var pickup: Dictionary = health_pickups[pickup_index]
        if not bool(pickup["active"]):
            continue
        var pickup_pos: Vector2 = pickup["pos"]
        if pickup_pos.distance_to(user_pos) > PULL_RADIUS:
            continue
        var pulled: Vector2 = pickup_pos.move_toward(user_pos, 520.0 * dt)
        pickup["pos"] = pulled
        health_pickups[pickup_index] = pickup

func _update_item_pulses(dt: float) -> void:
    if mode != ITEM_POOL_MODE:
        return
    for slot in range(heroes.size()):
        if not bool(heroes[slot]["alive"]) or bool(heroes[slot]["eliminated"]):
            continue
        if float(heroes[slot].get("pull_time", 0.0)) > 0.0:
            _apply_pull_pulse(slot, dt)

func _hero_in_own_pocket(slot: int) -> bool:
    if slot < 0 or slot >= heroes.size():
        return false
    if float(heroes[slot].get("pocket_time", 0.0)) <= 0.0:
        return false
    var hero_pos: Vector2 = heroes[slot]["pos"]
    return hero_pos.distance_to(Vector2(heroes[slot]["pos"])) <= POCKET_RADIUS

func _try_use_active_item(slot: int) -> void:
    if mode != ITEM_POOL_MODE:
        _try_use_medkit(slot)
        return
    if slot < 0 or slot >= heroes.size():
        return
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]) or bool(h["eliminated"]):
        return
    if _hero_has_timed(h, "turtle"):
        return
    var kind := str(h.get("held_item", ""))
    if kind == "":
        return
    match kind:
        "medkit":
            if float(h["hp"]) >= float(h["max_hp"]) - 0.5:
                return
            h["held_item"] = ""
            heroes[slot] = h
            var heal_amount := float(h["max_hp"]) * MEDKIT_HEAL_RATIO
            _heal_hero(slot, heal_amount)
            _add_effect(&"heal_pickup", Vector2(h["pos"]), 72.0, 0.45, Color("#6ef3a5"), "MEDKIT")
            event_log.emit(tick, &"medkit_used", slot, -1, {"amount":heal_amount, "left":0})
        "spring":
            h["held_item"] = ""
            h["hop_time"] = SPRING_AIR
            h["hop_max"] = SPRING_AIR
            h["hop_height"] = SPRING_LIFT
            h["evade_time"] = maxf(float(h["evade_time"]), SPRING_EVADE)
            h["spring_time"] = SPRING_AIR
            var boost_dir: Vector2 = Vector2(h["vel"])
            if boost_dir.length_squared() < 0.1:
                boost_dir = Vector2(h["facing"])
            if boost_dir.length_squared() > 0.1:
                var boosted: Vector2 = Vector2(h["vel"]) + boost_dir.normalized() * SPRING_BOOST
                h["vel"] = boosted
            heroes[slot] = h
            _add_effect(&"speed_streak", Vector2(h["pos"]), 90.0, 0.34, Color("#ffe066"), "SPRING", boost_dir)
            event_log.emit(tick, &"item_used", slot, -1, {"kind":"spring"})
        "slide":
            h["held_item"] = ""
            h["slide_time"] = SLIDE_DURATION
            heroes[slot] = h
            _add_effect(&"speed_streak", Vector2(h["pos"]), 70.0, 0.28, Color("#70e7ff"), "SLIDE")
            event_log.emit(tick, &"item_used", slot, -1, {"kind":"slide"})
        "pull":
            h["held_item"] = ""
            h["pull_time"] = PULL_DURATION
            heroes[slot] = h
            _apply_pull_pulse(slot, FIXED_DT)
            _add_effect(&"chain_vortex", Vector2(h["pos"]), PULL_RADIUS, 0.55, Color("#b78cff"), "PULL")
            event_log.emit(tick, &"item_used", slot, -1, {"kind":"pull"})
        "pocket":
            h["held_item"] = ""
            h["pocket_time"] = POCKET_DURATION
            heroes[slot] = h
            _add_effect(&"guard", Vector2(h["pos"]), POCKET_RADIUS, 0.45, Color("#f4e2ff"), "POCKET")
            event_log.emit(tick, &"item_used", slot, -1, {"kind":"pocket"})

func _cpu_consider_held_item(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    var kind := str(h.get("held_item", ""))
    if kind == "":
        return
    var hp_ratio := float(h["hp"]) / maxf(1.0, float(h["max_hp"]))
    var should_use := false
    match kind:
        "medkit":
            should_use = hp_ratio < 0.5 and rng.chance(0.30)
        "pocket":
            should_use = (not _hero_in_safe_zone(slot)) and rng.chance(0.22)
        "pull":
            var near := 0
            for other in range(heroes.size()):
                if other == slot or not bool(heroes[other]["alive"]):
                    continue
                if Vector2(h["pos"]).distance_to(Vector2(heroes[other]["pos"])) <= PULL_RADIUS:
                    near += 1
            should_use = near > 0 and rng.chance(0.12)
        "spring":
            should_use = rng.chance(0.06) and (hp_ratio < 0.42 or float(h["mobility_cd"]) > 0.8)
        "slide":
            should_use = rng.chance(0.08) and (h["action"] == &"CLOSE_RANGE" or h["action"] == &"SEEK_HEAL")
    if should_use:
        _try_use_active_item(slot)

func _try_use_medkit(slot: int) -> void:
    if slot < 0 or slot >= heroes.size():
        return
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]) or bool(h["eliminated"]):
        return
    if int(h.get("medkits", 0)) <= 0:
        return
    if float(h["hp"]) >= float(h["max_hp"]) - 0.5:
        return
    h["medkits"] = int(h["medkits"]) - 1
    var heal_amount := float(h["max_hp"]) * MEDKIT_HEAL_RATIO
    heroes[slot] = h
    _heal_hero(slot, heal_amount)
    _add_effect(&"heal_pickup", Vector2(h["pos"]), 72.0, 0.45, Color("#6ef3a5"), "메드킷 +%d" % roundi(heal_amount))
    event_log.emit(tick, &"medkit_used", slot, -1, {"amount":heal_amount, "left":int(h["medkits"])})

func _try_gun_loot(owner: int, attacker: Dictionary) -> Dictionary:
    if mode not in GUN_LOOT_MODES or not bool(attacker["alive"]):
        return attacker
    var current_id := str(attacker["equipment"]["id"])
    var chain_index := GUN_LOOT_CHAIN.find(current_id)
    var next_id := ""
    if chain_index >= 0 and chain_index < GUN_LOOT_CHAIN.size() - 1:
        next_id = str(GUN_LOOT_CHAIN[chain_index + 1])
    elif chain_index < 0:
        next_id = str(GUN_LOOT_CHAIN[0])
    if next_id.is_empty() or next_id == current_id:
        return attacker
    attacker["equipment"] = _make_equipment(next_id)
    attacker["burst_left"] = int(attacker["equipment"].get("burst_shots", 0))
    if int(attacker["burst_left"]) <= 0:
        attacker["burst_left"] = 2
    attacker["mag"] = int(attacker["equipment"].get("mag_size", 1))
    attacker["reload_left"] = 0.0
    attacker["reload_flash"] = 0.0
    event_log.emit(tick, &"gun_upgraded", owner, -1, {"equipment":next_id})
    _announce("P%d %s 획득!" % [owner + 1, str(attacker["equipment"]["name"])], 90)
    return attacker

func _show_streak_callout(title: String, subtitle: String, shutdown: bool) -> void:
    streak_callout = title
    streak_subtitle = subtitle
    streak_callout_shutdown = shutdown
    streak_callout_ticks = 150

func _streak_title(streak: int) -> String:
    if streak >= 6:
        return "막을 수 없습니다!"
    if streak == 5:
        return "폭주 중!"
    if streak == 4:
        return "학살 중!"
    if streak == 3:
        return "연속 처치!"
    return "더블 킬!"


func _apply_lethal_or_down(owner: int, target: int, extra: float) -> void:
    if target < 0 or target >= heroes.size():
        return
    var h: Dictionary = heroes[target]
    if not bool(h.get("alive", false)):
        return
    if bool(h.get("downed", false)):
        h["hp"] = 0.0
        h["down_taken"] = float(h.get("down_taken", 0.0)) + maxf(0.0, extra)
        heroes[target] = h
        if float(h["down_taken"]) >= DOWN_FINISH_HP:
            _down_hero(owner, target)
        return
    if float(h.get("hp", 0.0)) <= 0.0:
        _enter_down(owner, target)

func _enter_down(owner: int, target: int) -> void:
    var h: Dictionary = heroes[target]
    if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
        return
    h["downed"] = true
    h["down_left"] = DOWN_BLEED_TIME
    h["down_taken"] = 0.0
    h["combo_damage"] = 0.0
    h["combo_time"] = 0.0
    h["hp"] = 0.0
    h["vel"] = Vector2.ZERO
    h["launch_time"] = 0.0
    h["launch_vel"] = Vector2.ZERO
    h["ult_clones"] = []
    h["ult_clone_time"] = 0.0
    h["charging_skill"] = false
    heroes[target] = h
    last_down_slot = target
    last_down_ticks = 90
    _add_effect(&"hit_spark", Vector2(h["pos"]), 70.0, 0.35, Color("#ff8d93"), "DOWN")
    if owner >= 0:
        _announce("P%d DOWNED P%d" % [owner + 1, target + 1], 70)
        event_log.emit(tick, &"hero_bled", owner, target, {})
    else:
        _announce("P%d DOWNED" % [target + 1], 70)
        event_log.emit(tick, &"hero_bled", -1, target, {})

func _stand_up(slot: int) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h.get("downed", false)):
        return
    h["downed"] = false
    h["down_left"] = 0.0
    h["down_taken"] = 0.0
    h["alive"] = true
    h["hp"] = maxf(1.0, float(h["max_hp"]) * 0.5)
    h["spawn_protect_time"] = 1.2
    h["vel"] = Vector2.ZERO
    heroes[slot] = h
    _add_effect(&"respawn", Vector2(h["pos"]), 56.0, 0.40, Color("#6ef3a5"), "UP")
    event_log.emit(tick, &"hero_stood", slot, -1, {})

func _tick_downs(dt: float) -> void:
    for slot in range(heroes.size()):
        var h: Dictionary = heroes[slot]
        if not bool(h.get("downed", false)):
            continue
        if not bool(h.get("alive", false)):
            h["downed"] = false
            heroes[slot] = h
            continue
        h["down_left"] = maxf(0.0, float(h.get("down_left", 0.0)) - dt)
        heroes[slot] = h
        if float(h["down_left"]) <= 0.0:
            _stand_up(slot)

func _down_hero(owner: int, target: int) -> void:
    var h: Dictionary = heroes[target]
    var defeated_streak := int(h.get("kill_streak", 0))
    var death_velocity: Vector2 = h["launch_vel"]
    if death_velocity.length() < 450.0:
        var death_direction := Vector2.RIGHT.rotated(float(target) * TAU / float(PLAYER_COUNT))
        if owner >= 0 and owner < heroes.size():
            death_direction = Vector2(heroes[owner]["pos"]).direction_to(Vector2(h["pos"]))
            if death_direction.length_squared() < 0.1:
                death_direction = Vector2.RIGHT.rotated(float(target) * TAU / float(PLAYER_COUNT))
        elif Vector2(h["pos"]).distance_squared_to(safe_zone_center) > 1.0:
            death_direction = safe_zone_center.direction_to(Vector2(h["pos"]))
        death_velocity = death_direction * 1550.0
    else:
        death_velocity = death_velocity.normalized() * maxf(1550.0, death_velocity.length() * 1.35)
    knockouts.append({"slot":target, "pos":Vector2(h["pos"]), "vel":death_velocity, "time":2.15, "max_time":2.15, "bounces":0, "finished":false, "trail":[Vector2(h["pos"])], "equipment":str(h["equipment"]["id"])})
    var death_drop := str(h.get("held_item", ""))
    var death_pos: Vector2 = h["pos"]
    h["alive"] = false
    h["hp"] = 0.0
    h["downed"] = false
    h["down_left"] = 0.0
    h["down_taken"] = 0.0
    h["spawn_protect_time"] = 0.0
    var bounty_victim := (target == wanted_slot)
    var life_hits: Dictionary = h.get("life_hits", {})
    _clear_roulette_buffs(h)
    h["life_hitters"] = []
    h["life_hits"] = {}
    var used := int(h.get("revives_used", 0))
    var final_out := used >= MAX_REVIVES
    if final_out:
        h["eliminated"] = true
        h["respawn"] = 0.0
        h["respawn_left"] = 0.0
    else:
        h["eliminated"] = false
        h["revives_used"] = used + 1
        var wait := _respawn_delay_for(target)
        h["respawn"] = wait
        h["respawn_left"] = wait
    h["vel"] = Vector2.ZERO
    h["launch_vel"] = Vector2.ZERO
    h["launch_time"] = 0.0
    h["launch_trail"] = []
    h["launch_trail_fade"] = 0.0
    h["hitstun_time"] = 0.0
    h["combo_capture_time"] = 0.0
    h["combo_hits"] = 0
    h["combo_time"] = 0.0
    h["combo_damage"] = 0.0
    h["normal_step"] = 0
    h["normal_chain_time"] = 0.0
    h["combo_target"] = -1
    h["attack_lock_time"] = 0.0
    h["charging_skill"] = false
    h["charge_time"] = 0.0
    h["reload_left"] = 0.0
    h["reload_flash"] = 0.0
    h["deaths"] = int(h["deaths"]) + 1
    h["kill_streak"] = 0
    h["held_item"] = ""
    h["slide_time"] = 0.0
    h["pull_time"] = 0.0
    h["pocket_time"] = 0.0
    h["spring_time"] = 0.0
    heroes[target] = h
    if mode == ITEM_POOL_MODE and death_drop != "" and death_drop != "decoy":
        _spawn_dropped_pickup(death_pos, death_drop, -1)
    _add_effect(&"death_burst", Vector2(h["pos"]), 260.0, 1.25, Color("#ff3349"), "", death_velocity.normalized())
    impact_ticks = maxi(impact_ticks, 32)
    last_down_slot = target
    last_down_ticks = 105
    var streak_after := 0
    var shutdown_bonus := 0.0
    if owner >= 0 and owner < heroes.size() and owner != target:
        var attacker: Dictionary = heroes[owner]
        attacker["kills"] = int(attacker["kills"]) + 1
        attacker["eliminations"] = int(attacker["eliminations"]) + 1
        attacker["score"] = float(attacker["score"]) + 120.0
        attacker["bounty"] = float(attacker["bounty"]) + 12.0
        attacker["threat"] = float(attacker["threat"]) + 18.0
        if bool(attacker["alive"]):
            streak_after = int(attacker.get("kill_streak", 0)) + 1
            attacker["kill_streak"] = streak_after
            attacker["best_kill_streak"] = maxi(int(attacker.get("best_kill_streak", 0)), streak_after)
            var momentum_heal := float(attacker["max_hp"]) * minf(0.10, 0.055 + float(streak_after) * 0.01)
            attacker["hp"] = minf(float(attacker["max_hp"]), float(attacker["hp"]) + momentum_heal)
            attacker["equipment_cd"] = maxf(0.0, float(attacker["equipment_cd"]) - (0.50 + float(streak_after) * 0.10))
            attacker["mobility_cd"] = maxf(0.0, float(attacker["mobility_cd"]) - (0.35 + float(streak_after) * 0.08))
            attacker["ultimate_charge"] = minf(ULTIMATE_MAX, float(attacker.get("ultimate_charge", 0.0)) + 35.0)
            attacker["score"] = float(attacker["score"]) + maxf(0.0, float(streak_after - 1) * 15.0)
        if defeated_streak >= 3:
            shutdown_bonus = minf(230.0, 90.0 + float(defeated_streak - 3) * 35.0)
            attacker["score"] = float(attacker["score"]) + shutdown_bonus
            attacker["bounty"] = maxf(0.0, float(attacker["bounty"]) - 20.0)
            if bool(attacker["alive"]):
                attacker["hp"] = minf(float(attacker["max_hp"]), float(attacker["hp"]) + float(attacker["max_hp"]) * 0.14)
                attacker["equipment_cd"] *= 0.50
                attacker["mobility_cd"] *= 0.50
                attacker["ultimate_charge"] = minf(ULTIMATE_MAX, float(attacker.get("ultimate_charge", 0.0)) + 20.0)
            var attacker_name := str(attacker["equipment"]["character_name"])
            var defeated_name := str(h["equipment"]["character_name"])
            _show_streak_callout("연속 처치 종료!", "P%d %s님이 P%d %s님의 %d연속 처치를 끝냈습니다." % [owner + 1, attacker_name, target + 1, defeated_name, defeated_streak], true)
            event_log.emit(tick, &"streak_shutdown", owner, target, {"streak":defeated_streak, "bonus":shutdown_bonus})
        elif streak_after >= 2:
            var streak_attacker_name := str(attacker["equipment"]["character_name"])
            _show_streak_callout(_streak_title(streak_after), "P%d %s님이 %d연속 처치 중입니다." % [owner + 1, streak_attacker_name, streak_after], false)
            event_log.emit(tick, &"kill_streak", owner, target, {"streak":streak_after})
        attacker = _try_gun_loot(owner, attacker)
        heroes[owner] = attacker
        _grant_kill_roulettes(owner, target, bounty_victim, life_hits)
    impact_pos = Vector2(h["pos"])
    event_log.emit(tick, &"hero_downed", owner, target, {"streak":streak_after, "ended_streak":defeated_streak, "shutdown_bonus":shutdown_bonus, "revives_used":int(h.get("revives_used", 0)), "eliminated":bool(h["eliminated"])})
    if bool(h["eliminated"]):
        event_log.emit(tick, &"player_eliminated", owner, target, {"source":&"death"})
        if owner >= 0:
            _announce("P%d ELIMINATED P%d!" % [owner + 1, target + 1], 140)
        else:
            _announce("P%d ELIMINATED BY ZONE!" % [target + 1], 140)
    else:
        if owner >= 0:
            _announce("P%d DOWNED P%d" % [owner + 1, target + 1], 90)
        else:
            _announce("P%d DOWNED BY ZONE" % [target + 1], 90)
    impact_ticks = maxi(impact_ticks, 32)

func _eliminate(owner: int, target: int) -> void:
    var core: Dictionary = cores[target]
    core["alive"] = false
    core["hp"] = 0.0
    cores[target] = core
    var h: Dictionary = heroes[target]
    h["alive"] = false
    h["eliminated"] = true
    h["vel"] = Vector2.ZERO
    h["target"] = -1
    heroes[target] = h
    var attacker: Dictionary = heroes[owner]
    attacker["bounty"] = maxf(0.0, float(attacker["bounty"]) - 15.0)
    attacker["eliminations"] = int(attacker["eliminations"]) + 1
    attacker["score"] = float(attacker["score"]) + 300.0
    heroes[owner] = attacker
    event_log.emit(tick, &"player_eliminated", owner, target, {})
    impact_ticks = 16
    _announce("P%d ELIMINATED P%d!" % [owner + 1, target + 1], 140)

func _update_threat(dt: float) -> void:
    for i in range(heroes.size()):
        var h: Dictionary = heroes[i]
        h["threat"] = maxf(0.0, float(h["threat"]) - dt * 2.3)
        h["bounty"] = maxf(0.0, float(h["bounty"]) - dt * 0.22)
        h["grudge"] = maxf(0.0, float(h["grudge"]) - dt * 0.05)
        heroes[i] = h
    var new_wanted := _standing_leader()
    if new_wanted != wanted_slot and new_wanted >= 0:
        wanted_slot = new_wanted
        _announce("WANTED P%d" % (wanted_slot + 1), 90)
        event_log.emit(tick, &"bounty_moved", wanted_slot, -1, {"score":float(heroes[wanted_slot]["score"])})

func _hero_in_safe_zone(slot: int) -> bool:
    if slot < 0 or slot >= heroes.size():
        return true
    return Vector2(heroes[slot]["pos"]).distance_to(safe_zone_center) <= safe_zone_radius

func _update_safe_zone(dt: float) -> void:
    if not safe_zone_complete:
        safe_zone_phase_time += dt
        if safe_zone_shrinking:
            var shrink_time := maxf(0.01, float(SAFE_ZONE_PHASES[safe_zone_phase]["shrink"]))
            var ratio := clampf(safe_zone_phase_time / shrink_time, 0.0, 1.0)
            var eased := ratio * ratio * (3.0 - 2.0 * ratio)
            safe_zone_radius = lerpf(safe_zone_from_radius, safe_zone_target_radius, eased)
            if ratio >= 1.0:
                safe_zone_radius = safe_zone_target_radius
                safe_zone_shrinking = false
                safe_zone_phase_time = 0.0
                safe_zone_phase += 1
                if safe_zone_phase >= SAFE_ZONE_PHASES.size():
                    safe_zone_complete = true
                    safe_zone_phase = SAFE_ZONE_PHASES.size() - 1
                else:
                    safe_zone_target_radius = float(SAFE_ZONE_PHASES[safe_zone_phase]["radius"])
                    _announce("SAFE ZONE HOLD  %d" % roundi(safe_zone_radius), 70)
        else:
            var wait_time := float(SAFE_ZONE_PHASES[safe_zone_phase]["wait"])
            if safe_zone_phase_time >= wait_time:
                safe_zone_shrinking = true
                safe_zone_phase_time = 0.0
                safe_zone_from_radius = safe_zone_radius
                safe_zone_target_radius = float(SAFE_ZONE_PHASES[safe_zone_phase]["radius"])
                _announce("SAFE ZONE SHRINKING", 80)
                event_log.emit(tick, &"safe_zone_shrink", -1, -1, {"phase":safe_zone_phase, "from":safe_zone_from_radius, "to":safe_zone_target_radius})
    _apply_safe_zone_damage(dt)

func _apply_safe_zone_damage(dt: float) -> void:
    safe_zone_damage_clock += dt
    var show_tick := false
    if safe_zone_damage_clock >= SAFE_ZONE_TICK_INTERVAL:
        safe_zone_damage_clock -= SAFE_ZONE_TICK_INTERVAL
        show_tick = true
    var amount := SAFE_ZONE_DAMAGE_PER_SEC * dt
    for slot in range(heroes.size()):
        if not bool(heroes[slot]["alive"]) or bool(heroes[slot]["eliminated"]):
            continue
        if _hero_in_safe_zone(slot):
            continue
        if _hero_in_own_pocket(slot):
            continue
        _damage_hero_environment(slot, amount, show_tick)
    for crate_i in range(crates.size()):
        var crate: Dictionary = crates[crate_i]
        if not bool(crate.get("alive", false)):
            continue
        if Vector2(crate["pos"]).distance_to(safe_zone_center) <= safe_zone_radius:
            continue
        var shown := SAFE_ZONE_DAMAGE_PER_SEC * SAFE_ZONE_TICK_INTERVAL if show_tick else 0.0
        _hurt_crate(crate_i, amount, show_tick and shown > 0.4)
        if show_tick:
            _add_effect(&"hit_spark", Vector2(crate["pos"]), 28.0, 0.16, Color("#ff4f68"), "ZONE")

func _damage_hero_environment(target: int, amount: float, show_tick: bool) -> void:
    var h: Dictionary = heroes[target]
    if not bool(h["alive"]) or amount <= 0.0:
        return
    if float(h.get("spawn_protect_time", 0.0)) > 0.0:
        return
    h["hp"] = float(h["hp"]) - amount
    heroes[target] = h
    if show_tick:
        _add_effect(&"hit_spark", Vector2(h["pos"]), 36.0, 0.18, Color("#ff4f68"), "ZONE")
        event_log.emit(tick, &"hero_hit", -1, target, {"damage":SAFE_ZONE_DAMAGE_PER_SEC * SAFE_ZONE_TICK_INTERVAL, "source":&"safe_zone"})
    _apply_lethal_or_down(-1, target, amount)

func _hero_hp_ratio(slot: int) -> float:
    if slot < 0 or slot >= heroes.size() or bool(heroes[slot]["eliminated"]):
        return 0.0
    return clampf(float(heroes[slot]["hp"]) / maxf(1.0, float(heroes[slot]["max_hp"])), 0.0, 1.0) if bool(heroes[slot]["alive"]) else 0.0

func _core_hp_ratio(slot: int) -> float:
    if slot < 0 or slot >= cores.size() or not bool(cores[slot]["alive"]):
        return 0.0
    return clampf(float(cores[slot]["hp"]) / maxf(1.0, float(cores[slot]["max_hp"])), 0.0, 1.0)

func _time_limit_better(candidate: int, current: int) -> bool:
    if current < 0:
        return true
    var candidate_hp := _hero_hp_ratio(candidate)
    var current_hp := _hero_hp_ratio(current)
    if not is_equal_approx(candidate_hp, current_hp):
        return candidate_hp > current_hp
    if not is_equal_approx(float(heroes[candidate]["score"]), float(heroes[current]["score"])):
        return float(heroes[candidate]["score"]) > float(heroes[current]["score"])
    return candidate < current

func _declare_winner(slot: int, reason: StringName) -> void:
    winner_slot = slot
    result_reason = reason
    result = &"won" if slot == 0 else &"lost"
    decision_hp_ratio = _hero_hp_ratio(slot)
    decision_core_ratio = _core_hp_ratio(slot)
    var winner: Dictionary = heroes[slot]
    winner["score"] = float(winner["score"]) + 500.0
    heroes[slot] = winner
    impact_pos = Vector2(winner["pos"])
    impact_ticks = maxi(impact_ticks, 26)
    _add_effect(&"victory", Vector2(winner["pos"]), 210.0, 2.20, Color("#ffd166"), "", Vector2.UP)
    event_log.emit(tick, &"match_won", slot, -1, {"reason":reason, "hp_ratio":decision_hp_ratio, "core_ratio":decision_core_ratio, "score":float(winner["score"])})
    _settle_match_visuals()

func _resolve_time_limit() -> void:
    var best := -1
    for slot in range(heroes.size()):
        if bool(heroes[slot]["alive"]) and not bool(heroes[slot]["eliminated"]) and _time_limit_better(slot, best):
            best = slot
    if best < 0:
        result = &"draw"
        result_reason = &"time_limit_draw"
        winner_slot = -1
        _settle_match_visuals()
        return
    _declare_winner(best, &"time_limit")
    event_log.emit(tick, &"time_limit_decided", best, -1, {"hp_ratio":decision_hp_ratio, "core_ratio":decision_core_ratio})

func _standing_better(a: Dictionary, b: Dictionary) -> bool:
    var a_slot := int(a["slot"])
    var b_slot := int(b["slot"])
    if a_slot == winner_slot:
        return true
    if b_slot == winner_slot:
        return false
    if result_reason == &"time_limit":
        return _time_limit_better(a_slot, b_slot)
    var a_alive := bool(a.get("hero_alive", false))
    var b_alive := bool(b.get("hero_alive", false))
    if a_alive != b_alive:
        return a_alive
    return float(a["score"]) > float(b["score"])

func final_standings() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for slot in range(heroes.size()):
        rows.append({
            "slot":slot,
            "hp_ratio":_hero_hp_ratio(slot),
            "core_ratio":_core_hp_ratio(slot),
            "score":float(heroes[slot]["score"]),
            "core_alive":bool(cores[slot]["alive"]),
            "hero_alive":bool(heroes[slot]["alive"]) and not bool(heroes[slot]["eliminated"])
        })
    rows.sort_custom(_standing_better)
    return rows

func _check_end() -> void:
    var alive_slots: Array[int] = []
    for hero in heroes:
        if not bool(hero["eliminated"]):
            alive_slots.append(int(hero["slot"]))
    if alive_slots.size() == 1:
        _declare_winner(alive_slots[0], &"last_survivor")
    elif alive_slots.is_empty():
        result = &"draw"
        result_reason = &"no_survivors"
        winner_slot = -1
        _settle_match_visuals()

func _announce(text: String, duration_ticks: int) -> void:
    callout = text
    callout_ticks = duration_ticks

func summary() -> Dictionary:
    var alive := 0
    var core_hps: Array[float] = []
    var ultimate_uses := 0
    var equipment_hits := 0
    for hero in heroes:
        if not bool(hero["eliminated"]):
            alive += 1
        ultimate_uses += int(hero["ultimates"])
        equipment_hits += int(hero["equipment_hits"])
    for core in cores:
        core_hps.append(maxf(0.0, float(core["hp"])))
    return {"tick":tick, "time":match_time, "time_limit":MATCH_TIME_LIMIT, "alive":alive, "winner":winner_slot, "result":result, "result_reason":result_reason, "decision_hp_ratio":decision_hp_ratio, "decision_core_ratio":decision_core_ratio, "projectiles":projectiles.size(), "start_countdown":start_countdown, "core_hps":core_hps, "ultimate_uses":ultimate_uses, "equipment_hits":equipment_hits, "safe_zone_radius":safe_zone_radius, "safe_zone_target":safe_zone_target_radius, "safe_zone_shrinking":safe_zone_shrinking, "mode":mode}

func leaderboard() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for slot in range(heroes.size()):
        var hero: Dictionary = heroes[slot]
        rows.append({"slot":slot, "score":float(hero["score"]), "kills":int(hero["kills"]), "deaths":int(hero["deaths"]), "streak":int(hero.get("kill_streak", 0)), "best_streak":int(hero.get("best_kill_streak", 0)), "eliminations":int(hero["eliminations"]), "damage":float(hero["damage_dealt"]), "core_damage":float(hero["core_damage"])})
    rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
    return rows

func has_invalid_numbers() -> bool:
    for h in heroes:
        var pos: Vector2 = h["pos"]
        if not is_finite(pos.x) or not is_finite(pos.y):
            return true
    return false


func cycle_local_animal(delta: int) -> void:
    if local_slot < 0 or local_slot >= heroes.size():
        return
    if result != &"playing":
        return
    var h: Dictionary = heroes[local_slot]
    if not bool(h.get("alive", false)):
        return
    var animal := posmod(int(h.get("animal", local_slot)) + delta, 12)
    set_hero_animal(local_slot, animal)

func set_hero_animal(slot: int, animal: int) -> void:
    if slot < 0 or slot >= heroes.size():
        return
    var h: Dictionary = heroes[slot]
    animal = posmod(animal, 12)
    h["animal"] = animal
    var equipment_id := GunSig.equipment_for_animal(animal)
    var equipment := _make_equipment(equipment_id)
    h["equipment"] = equipment
    h["max_hp"] = float(equipment["max_hp"])
    h["hp"] = float(equipment["max_hp"])
    h["mag"] = int(equipment.get("mag_size", 1))
    h["reload_left"] = 0.0
    h["fire_cd"] = 0.0
    heroes[slot] = h
    _announce("P%d %s" % [slot + 1, str(equipment.get("name", equipment_id))], 70)


func _reset_mid_tower() -> void:
    mid_tower = {
        "alive": false,
        "spawned": false,
        "pos": ARENA_CENTER,
        "hp": TOWER_MAX_HP,
        "max_hp": TOWER_MAX_HP,
        "fire_cd": 0.8,
        "pattern": 0,
        "boing": 0.0,
        "hits": {},
        "last_hit": -1
    }

func _update_mid_tower(dt: float) -> void:
    if result != &"playing":
        return
    if not bool(mid_tower.get("spawned", false)) and match_time >= TOWER_SPAWN_TIME:
        mid_tower["spawned"] = true
        mid_tower["alive"] = true
        mid_tower["hp"] = TOWER_MAX_HP
        mid_tower["max_hp"] = TOWER_MAX_HP
        mid_tower["hits"] = {}
        mid_tower["last_hit"] = -1
        mid_tower["fire_cd"] = 1.2
        mid_tower["pattern"] = 0
        mid_tower["boing"] = 0.0
        _announce("BOUNTY TOWER", 90)
        _add_effect(&"explosion", ARENA_CENTER, 90.0, 0.45, Color("#ffb347"), "TOWER")
        event_log.emit(tick, &"tower_spawned", -1, -1, {"hp":TOWER_MAX_HP})
        return
    if not bool(mid_tower.get("alive", false)):
        return
    mid_tower["boing"] = maxf(0.0, float(mid_tower.get("boing", 0.0)) - dt)
    mid_tower["fire_cd"] = maxf(0.0, float(mid_tower.get("fire_cd", 0.0)) - dt)
    if float(mid_tower["fire_cd"]) > 0.0:
        return
    var best := -1
    var best_d := TOWER_RANGE
    var tpos: Vector2 = mid_tower["pos"]
    for slot in range(heroes.size()):
        if not bool(heroes[slot]["alive"]) or bool(heroes[slot].get("eliminated", false)):
            continue
        var d := tpos.distance_to(Vector2(heroes[slot]["pos"]))
        if d < best_d:
            best_d = d
            best = slot
    if best < 0:
        return
    var aim := tpos.direction_to(Vector2(heroes[best]["pos"]))
    if aim.length_squared() < 0.0001:
        aim = Vector2.RIGHT
    var pattern := int(mid_tower.get("pattern", 0)) % 3
    mid_tower["boing"] = 0.22
    if pattern == 0:
        _tower_ring_shot(tpos, 10, 0.0)
        mid_tower["fire_cd"] = TOWER_INTERVAL
    elif pattern == 1:
        _tower_fan_shot(tpos, aim, 7)
        mid_tower["fire_cd"] = TOWER_INTERVAL * 0.82
    else:
        _tower_carpet(tpos, aim)
        mid_tower["fire_cd"] = TOWER_INTERVAL * 1.15
    mid_tower["pattern"] = pattern + 1
    event_log.emit(tick, &"tower_fire", -1, best, {"pattern":pattern})

func _hurt_tower(owner: int, damage: float) -> void:
    if not bool(mid_tower.get("alive", false)) or damage <= 0.0:
        return
    mid_tower["hp"] = float(mid_tower["hp"]) - damage
    if owner >= 0:
        mid_tower["last_hit"] = owner
        var hits: Dictionary = mid_tower.get("hits", {})
        var key := str(owner)
        var rec: Dictionary = hits.get(key, {"dmg": 0.0, "tick": 0})
        rec["dmg"] = float(rec.get("dmg", 0.0)) + damage
        rec["tick"] = tick
        hits[key] = rec
        mid_tower["hits"] = hits
    event_log.emit(tick, &"tower_hit", owner, -1, {"damage": damage, "hp": float(mid_tower["hp"])})
    if float(mid_tower["hp"]) > 0.0:
        return
    mid_tower["hp"] = 0.0
    mid_tower["alive"] = false
    var killer := int(mid_tower.get("last_hit", -1))
    var hits2: Dictionary = mid_tower.get("hits", {})
    if killer >= 0 and killer < heroes.size() and bool(heroes[killer]["alive"]):
        for _i in range(3):
            _queue_roulette(killer, "wanted")
    for assist_slot in _assist_slots(killer, -1, hits2):
        if int(assist_slot) == killer:
            continue
        _queue_roulette(int(assist_slot), "wanted")
    _announce("TOWER DOWN", 80)
    _add_effect(&"explosion", Vector2(mid_tower["pos"]), 110.0, 0.55, Color("#ff5a4a"), "BOUNTY")
    event_log.emit(tick, &"tower_down", killer, -1, {"killer": killer})



func _tower_shell(tpos: Vector2, dir: Vector2, speed: float, splash: float, dmg: float, ttl: float) -> void:
    if dir.length_squared() < 0.0001:
        dir = Vector2.RIGHT
    dir = dir.normalized()
    projectiles.append({
        "id": next_entity_id,
        "owner": -1,
        "pos": tpos + dir * (TOWER_RADIUS + 10.0),
        "vel": dir * speed,
        "damage": dmg,
        "radius": 11.0,
        "ttl": ttl,
        "splash": splash,
        "leech": false,
        "pierce": 0,
        "cc_time": 0.0,
        "knockback": 22.0,
        "kind": &"shell",
        "homing": 0.0,
        "label": "TOWER",
        "combo_finisher": false,
        "control_kind": &"slow",
        "hit_targets": [],
        "trail": [tpos],
        "source": &"tower"
    })
    next_entity_id += 1

func _tower_ring_shot(tpos: Vector2, count: int, rot: float) -> void:
    for i in range(count):
        var dir := Vector2.RIGHT.rotated(rot + TAU * float(i) / float(count))
        _tower_shell(tpos, dir, 620.0, 46.0, TOWER_DAMAGE, 1.15)

func _tower_fan_shot(tpos: Vector2, aim: Vector2, count: int) -> void:
    var mid := (count - 1) * 0.5
    for i in range(count):
        var ang := (float(i) - mid) * 0.18
        _tower_shell(tpos, aim.rotated(ang), 860.0, 58.0, TOWER_DAMAGE + 4.0, 0.95)

func _tower_carpet(tpos: Vector2, aim: Vector2) -> void:
    for i in range(6):
        var side := -1.0 if i % 2 == 0 else 1.0
        var dist := 170.0 + float(i) * 95.0
        var land := tpos + aim * dist + aim.orthogonal() * side * (40.0 + float(i) * 18.0)
        _add_zone(-1, land, 78.0, 0.42 + float(i) * 0.08, TOWER_DAMAGE + 8.0, &"tower", 0.0, 26.0, "BOOM", Color("#ff7a3a"), false, &"explosion")
    _tower_fan_shot(tpos, aim, 3)

