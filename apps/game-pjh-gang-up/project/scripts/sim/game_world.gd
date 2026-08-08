class_name GangGameWorld
extends RefCounted

const SeededRngScript = preload("res://scripts/sim/seeded_rng.gd")
const EventLogScript = preload("res://scripts/sim/event_log.gd")

const PLAYER_COUNT := 6
const HERO_RADIUS := 20.0
const HERO_SPEED := 310.0
const ARENA_CENTER := Vector2(1400.0, 850.0)
const ARENA_SIZE := Vector2(2800.0, 1700.0)
const ARENA_MARGIN := 52.0
const CORE_RADIUS := 34.0
const CORE_MAX_HP := 210.0
const FIXED_DT := 1.0 / 60.0
const START_COUNTDOWN := 3.0
const MATCH_TIME_LIMIT := 210.0
const ULTIMATE_MAX := 100.0
const HEALTH_PICKUP_RADIUS := 27.0
const HEALTH_PICKUP_RESPAWN := 16.0
const HEALTH_PICKUP_HEAL_RATIO := 0.30
const HEALTH_PICKUP_MAGNET_RADIUS := 155.0
const HEALTH_PICKUP_MAGNET_SPEED := 760.0
const HEALTH_PICKUP_RETURN_SPEED := 280.0
const HEALTH_PICKUP_POINTS := [
    Vector2(1400.0, 430.0),
    Vector2(1400.0, 1270.0),
    Vector2(760.0, 850.0),
    Vector2(2040.0, 850.0)
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

var equipment_defs := [
    {"id":"scatter", "name":"SCATTERGUN", "normal_name":"DOUBLE PELLET", "skill_name":"BACKBLAST", "skill_desc":"Cone knockback plus recoil escape", "ultimate_name":"ROOM CLEARER", "ultimate_desc":"Dash in and blast everyone outward", "normal_damage":5.5, "normal_interval":0.36, "normal_speed":720.0, "normal_range":0.72, "normal_spread":0.055, "normal_projectiles":2, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":10.0, "normal_kind":"pellet", "normal_radius":6.0, "preferred_range":285.0, "cooldown":3.10, "damage":7.0, "speed":720.0, "range":0.72},
    {"id":"rail", "name":"RAIL LANCE", "normal_name":"MARKSMAN SHOT", "skill_name":"ANCHOR BREAK", "skill_desc":"Pierce, stagger and launch in one line", "ultimate_name":"DEADLINE", "ultimate_desc":"Three warned rail strikes split the arena", "normal_damage":12.0, "normal_interval":0.50, "normal_speed":980.0, "normal_range":1.28, "normal_spread":0.012, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":22.0, "normal_kind":"beam", "normal_radius":5.0, "preferred_range":540.0, "cooldown":3.50, "damage":38.0, "speed":1120.0, "range":1.42},
    {"id":"mortar", "name":"CLUSTER MORTAR", "normal_name":"IMPACT SHELL", "skill_name":"SKYFALL", "skill_desc":"Warned blast opens cores and launches groups", "ultimate_name":"NO SAFE PLACE", "ultimate_desc":"Five staggered blasts deny an area", "normal_damage":8.0, "normal_interval":0.58, "normal_speed":560.0, "normal_range":0.98, "normal_spread":0.028, "normal_projectiles":1, "normal_splash":28.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":34.0, "normal_kind":"shell", "normal_radius":9.0, "preferred_range":455.0, "cooldown":4.40, "damage":24.0, "speed":560.0, "range":1.08},
    {"id":"leech", "name":"LEECH CORE", "normal_name":"DRAIN NEEDLE", "skill_name":"BLOOD HARPOON", "skill_desc":"Hook pulls prey in and restores health", "ultimate_name":"BLOOD AUCTION", "ultimate_desc":"Three draining pulses drag everyone inward", "normal_damage":7.5, "normal_interval":0.32, "normal_speed":760.0, "normal_range":0.90, "normal_spread":0.035, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":true, "normal_cc":0.0, "normal_knockback":-12.0, "normal_kind":"tether", "normal_radius":7.0, "preferred_range":390.0, "cooldown":3.40, "damage":18.0, "speed":820.0, "range":1.08},
    {"id":"breaker", "name":"BREACH HAMMER", "normal_name":"HEAVY SLUG", "skill_name":"CRASH ENTRY", "skill_desc":"Armored dash ends in a heavy shockwave", "ultimate_name":"TABLE FLIP", "ultimate_desc":"Long commit with an enormous launch", "normal_damage":20.0, "normal_interval":0.48, "normal_speed":700.0, "normal_range":0.98, "normal_spread":0.022, "normal_projectiles":1, "normal_splash":30.0, "normal_leech":false, "normal_cc":0.75, "normal_knockback":48.0, "normal_kind":"hammer", "normal_radius":12.0, "preferred_range":360.0, "cooldown":3.60, "damage":32.0, "speed":650.0, "range":0.96},
    {"id":"burst", "name":"BURST RACK", "normal_name":"TRIPLE TAP", "skill_name":"SEEKER SALVO", "skill_desc":"Three curving missiles chase evasive prey", "ultimate_name":"HUNTER STORM", "ultimate_desc":"Twelve homing rockets cause chain panic", "normal_damage":4.8, "normal_interval":0.42, "normal_speed":840.0, "normal_range":0.98, "normal_spread":0.065, "normal_projectiles":3, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":8.0, "normal_kind":"burst", "normal_radius":5.0, "preferred_range":435.0, "cooldown":3.35, "damage":10.0, "speed":820.0, "range":1.18},
    {"id":"blade", "name":"MOON KATANA", "normal_name":"MOON CUT", "skill_name":"CROSS STEP", "skill_desc":"Pass through the target and cut the exit", "ultimate_name":"THOUSANDTH EDGE", "ultimate_desc":"Five crossing cuts end in a launch", "normal_damage":9.5, "normal_interval":0.34, "normal_speed":900.0, "normal_range":0.23, "normal_spread":0.0, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":18.0, "normal_kind":"slash", "normal_radius":22.0, "preferred_range":205.0, "cooldown":3.10, "damage":27.0, "speed":980.0, "range":0.32},
    {"id":"brawler", "name":"BARE KNUCKLES", "normal_name":"ONE-TWO", "skill_name":"LIVER SHOT", "skill_desc":"Shoulder in and pin the target in hitstun", "ultimate_name":"TEN COUNT", "ultimate_desc":"A rushing fist storm with a final uppercut", "normal_damage":6.5, "normal_interval":0.38, "normal_speed":780.0, "normal_range":0.17, "normal_spread":0.10, "normal_projectiles":2, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":11.0, "normal_kind":"fist", "normal_radius":16.0, "preferred_range":155.0, "cooldown":3.20, "damage":24.0, "speed":820.0, "range":0.26},
    {"id":"bomb", "name":"MINE SATCHEL", "normal_name":"POCKET BOMB", "skill_name":"PROX MINE", "skill_desc":"Install up to two visible proximity mines", "ultimate_name":"PANIC MINEFIELD", "ultimate_desc":"Install five armed mines that auto-detonate", "normal_damage":8.5, "normal_interval":0.62, "normal_speed":510.0, "normal_range":1.00, "normal_spread":0.025, "normal_projectiles":1, "normal_splash":46.0, "normal_leech":false, "normal_cc":0.35, "normal_knockback":42.0, "normal_kind":"bomb", "normal_radius":11.0, "preferred_range":410.0, "cooldown":4.40, "damage":27.0, "speed":520.0, "range":1.10},
    {"id":"spear", "name":"SUN SPEAR", "normal_name":"LONG THRUST", "skill_name":"VAULT IMPALE", "skill_desc":"Vault forward and skewer a sightline", "ultimate_name":"DRAGON LINE", "ultimate_desc":"Three enormous piercing thrusts", "normal_damage":13.0, "normal_interval":0.52, "normal_speed":1100.0, "normal_range":0.35, "normal_spread":0.0, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":25.0, "normal_kind":"spear", "normal_radius":10.0, "preferred_range":345.0, "cooldown":3.45, "damage":29.0, "speed":1180.0, "range":0.72},
    {"id":"chain", "name":"CHAIN SICKLE", "normal_name":"CHAIN FLICK", "skill_name":"CHAIN LOCK", "skill_desc":"Pull and root one target; charge for a longer bind", "ultimate_name":"BLACK CAROUSEL", "ultimate_desc":"Pull twice, stun, then fling the trapped crowd", "normal_damage":7.5, "normal_interval":0.40, "normal_speed":800.0, "normal_range":0.56, "normal_spread":0.018, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.0, "normal_knockback":-18.0, "normal_kind":"chain", "normal_radius":12.0, "preferred_range":360.0, "cooldown":4.60, "damage":21.0, "speed":900.0, "range":0.78},
    {"id":"shield", "name":"TOWER SHIELD", "normal_name":"SHIELD CHECK", "skill_name":"BULLDOZER WALL", "skill_desc":"Launch a warned moving wall that sweeps enemies away", "ultimate_name":"LAST ONE STANDING", "ultimate_desc":"Fortify, then overturn everyone nearby", "normal_damage":15.0, "normal_interval":0.62, "normal_speed":650.0, "normal_range":0.25, "normal_spread":0.0, "normal_projectiles":1, "normal_splash":0.0, "normal_leech":false, "normal_cc":0.30, "normal_knockback":40.0, "normal_kind":"shield", "normal_radius":24.0, "preferred_range":225.0, "cooldown":5.60, "damage":22.0, "speed":700.0, "range":0.30}
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
        "scatter": return {"move_speed":320.0, "max_hp":102.0, "weight":1.00, "combo_cap_ratio":0.44, "special_name":"RECOIL RHYTHM", "special_desc":"fast close-range reset"}
        "rail": return {"move_speed":292.0, "max_hp":88.0, "weight":0.88, "combo_cap_ratio":0.50, "special_name":"DEAD ANGLE", "special_desc":"long-range hits deal 12% more"}
        "mortar": return {"move_speed":270.0, "max_hp":92.0, "weight":0.92, "combo_cap_ratio":0.47, "special_name":"GLASS ARTILLERY", "special_desc":"controls space but collapses when rushed"}
        "leech": return {"move_speed":310.0, "max_hp":98.0, "weight":0.98, "combo_cap_ratio":0.45, "special_name":"HUNGER", "special_desc":"confirmed hits restore health"}
        "breaker": return {"move_speed":266.0, "max_hp":128.0, "weight":1.34, "combo_cap_ratio":0.40, "special_name":"HEAVY FRAME", "special_desc":"high launch resistance"}
        "burst": return {"move_speed":336.0, "max_hp":90.0, "weight":0.90, "combo_cap_ratio":0.50, "special_name":"PURSUIT", "special_desc":"homing attacks punish escape"}
        "blade": return {"move_speed":354.0, "max_hp":90.0, "weight":0.86, "combo_cap_ratio":0.50, "special_name":"AFTERIMAGE", "special_desc":"mobility evades one incoming hit"}
        "brawler": return {"move_speed":326.0, "max_hp":116.0, "weight":1.12, "combo_cap_ratio":0.43, "special_name":"COMEBACK", "special_desc":"12% more damage below half health"}
        "bomb": return {"move_speed":288.0, "max_hp":104.0, "weight":1.04, "combo_cap_ratio":0.44, "special_name":"MINE LAYER", "special_desc":"two persistent mines control rotations"}
        "spear": return {"move_speed":316.0, "max_hp":102.0, "weight":1.02, "combo_cap_ratio":0.45, "special_name":"TIP RANGE", "special_desc":"far hits deal 12% more"}
        "chain": return {"move_speed":298.0, "max_hp":108.0, "weight":1.08, "combo_cap_ratio":0.43, "special_name":"CAPTURE", "special_desc":"combo tugs hold prey for CHAIN LOCK"}
        _: return {"move_speed":252.0, "max_hp":140.0, "weight":1.55, "combo_cap_ratio":0.38, "special_name":"BULLDOZER", "special_desc":"a moving wall forces enemies out of its lane"}

func _mobility_for_equipment(equipment_id: String) -> Dictionary:
    match equipment_id:
        "scatter": return {"mobility_name":"SKIRMISH HOP", "mobility_desc":"fast lateral recoil", "mobility_cooldown":4.2, "mobility_distance":190.0}
        "rail": return {"mobility_name":"SIGHTLINE STEP", "mobility_desc":"short precise sidestep", "mobility_cooldown":4.8, "mobility_distance":165.0}
        "mortar": return {"mobility_name":"BLAST HOP", "mobility_desc":"jump and repel nearby enemies", "mobility_cooldown":5.2, "mobility_distance":175.0}
        "leech": return {"mobility_name":"SHADOW PULL", "mobility_desc":"long slide with a small heal", "mobility_cooldown":5.0, "mobility_distance":215.0}
        "breaker": return {"mobility_name":"IRON MARCH", "mobility_desc":"short armored advance", "mobility_cooldown":4.6, "mobility_distance":145.0}
        "burst": return {"mobility_name":"FLASH CUT", "mobility_desc":"long blink with no attack", "mobility_cooldown":5.5, "mobility_distance":250.0}
        "blade": return {"mobility_name":"SHADOW SHEATH", "mobility_desc":"blink and evade one hit", "mobility_cooldown":3.8, "mobility_distance":265.0}
        "brawler": return {"mobility_name":"WEAVE", "mobility_desc":"short dodge that breaks a combo", "mobility_cooldown":3.6, "mobility_distance":155.0}
        "bomb": return {"mobility_name":"BLAST ROLL", "mobility_desc":"roll away from the live fuse", "mobility_cooldown":4.8, "mobility_distance":190.0}
        "spear": return {"mobility_name":"POLE VAULT", "mobility_desc":"long committed vault", "mobility_cooldown":4.3, "mobility_distance":230.0}
        "chain": return {"mobility_name":"SWING STEP", "mobility_desc":"curve around the captured target", "mobility_cooldown":4.5, "mobility_distance":205.0}
        _: return {"mobility_name":"BRACE STEP", "mobility_desc":"small step with a long guard", "mobility_cooldown":5.0, "mobility_distance":120.0}

func _init(seed: int = 2222) -> void:
    rng = SeededRngScript.new(seed)
    event_log = EventLogScript.new()
    reset()

func reset() -> void:
    tick = 0
    match_time = 0.0
    result = &"playing"
    winner_slot = -1
    result_reason = &""
    decision_hp_ratio = 0.0
    decision_core_ratio = 0.0
    wanted_slot = -1
    callout = "NO TEAMS. ONLY TEMPORARY CONVENIENCE."
    callout_ticks = 210
    impact_ticks = 0
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
    heroes.clear()
    cores.clear()
    projectiles.clear()
    zones.clear()
    deployables.clear()
    effects.clear()
    knockouts.clear()
    health_pickups.clear()
    covers = [
        {"rect":Rect2(1330.0, 590.0, 140.0, 520.0)},
        {"rect":Rect2(930.0, 810.0, 300.0, 70.0)},
        {"rect":Rect2(1570.0, 810.0, 300.0, 70.0)},
        {"rect":Rect2(590.0, 350.0, 230.0, 82.0)},
        {"rect":Rect2(1980.0, 350.0, 230.0, 82.0)},
        {"rect":Rect2(590.0, 1268.0, 230.0, 82.0)},
        {"rect":Rect2(1980.0, 1268.0, 230.0, 82.0)},
        {"rect":Rect2(340.0, 715.0, 82.0, 270.0)},
        {"rect":Rect2(2378.0, 715.0, 82.0, 270.0)},
        {"rect":Rect2(1030.0, 260.0, 120.0, 120.0)},
        {"rect":Rect2(1650.0, 1320.0, 120.0, 120.0)}
    ]
    for pickup_index in range(HEALTH_PICKUP_POINTS.size()):
        health_pickups.append({
            "id":pickup_index,
            "pos":HEALTH_PICKUP_POINTS[pickup_index],
            "home":HEALTH_PICKUP_POINTS[pickup_index],
            "magnet_slot":-1,
            "active":true,
            "respawn":0.0
        })
    next_entity_id = 100
    event_log.clear()
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
        var core_pos := ARENA_CENTER + Vector2.RIGHT.rotated(angle) * 700.0
        var hero_pos := ARENA_CENTER + Vector2.RIGHT.rotated(angle) * 560.0
        var equipment: Dictionary = equipment_defs[equipment_order[slot]].duplicate(true)
        var identity := _identity_for_equipment(str(equipment["id"]))
        for key in identity:
            equipment[key] = identity[key]
        var mobility := _mobility_for_equipment(str(equipment["id"]))
        for key in mobility:
            equipment[key] = mobility[key]
        var combat_stats := _combat_stats_for_equipment(str(equipment["id"]))
        for key in combat_stats:
            equipment[key] = combat_stats[key]
        var hero_max_hp := float(equipment["max_hp"])
        cores.append({"slot":slot, "pos":core_pos, "hp":CORE_MAX_HP, "max_hp":CORE_MAX_HP, "alive":true})
        var initial_facing := hero_pos.direction_to(ARENA_CENTER)
        heroes.append({
            "slot":slot,
            "pos":hero_pos,
            "vel":Vector2.ZERO,
            "aim":initial_facing,
            "facing":initial_facing,
            "hp":hero_max_hp,
            "max_hp":hero_max_hp,
            "alive":true,
            "eliminated":false,
            "respawn":0.0,
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
            "normal_chain_time":0.0,
            "normal_interval":0.0,
            "attack_lock_time":0.0,
            "charging_skill":false,
            "charge_time":0.0,
            "charge_dir":hero_pos.direction_to(ARENA_CENTER),
            "cpu_charge_target":0.0
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
    _apply_human(command)
    _update_cpus(dt)
    _move_heroes(dt)
    _update_health_pickups(dt)
    _update_knockouts(dt)
    _update_deployables(dt)
    _update_projectiles(dt)
    _update_zones(dt)
    _update_effects(dt)
    _update_threat(dt)
    _check_end()

func _update_post_match_visuals(dt: float) -> void:
    tick += 1
    callout_ticks = maxi(0, callout_ticks - 1)
    impact_ticks = maxi(0, impact_ticks - 1)
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
    last_down_ticks = maxi(0, last_down_ticks - 1)
    streak_callout_ticks = maxi(0, streak_callout_ticks - 1)
    ultimate_focus_time = maxf(0.0, ultimate_focus_time - dt)
    if ultimate_focus_time <= 0.0:
        ultimate_focus_slot = -1
    for i in range(heroes.size()):
        var h: Dictionary = heroes[i]
        h["fire_cd"] = maxf(0.0, float(h["fire_cd"]) - dt)
        h["equipment_cd"] = maxf(0.0, float(h["equipment_cd"]) - dt)
        h["mobility_cd"] = maxf(0.0, float(h["mobility_cd"]) - dt)
        h["guard_time"] = maxf(0.0, float(h["guard_time"]) - dt)
        h["super_armor_time"] = maxf(0.0, float(h["super_armor_time"]) - dt)
        if float(h["super_armor_time"]) <= 0.0:
            h["super_armor_strength"] = 0.0
        h["evade_time"] = maxf(0.0, float(h["evade_time"]) - dt)
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
        h["wall_hit_cd"] = maxf(0.0, float(h["wall_hit_cd"]) - dt)
        if not bool(h["alive"]) and not bool(h["eliminated"]):
            h["respawn"] = maxf(0.0, float(h["respawn"]) - dt)
            if float(h["respawn"]) <= 0.0 and bool(cores[i]["alive"]):
                h["alive"] = true
                h["hp"] = float(h["max_hp"])
                h["pos"] = Vector2(cores[i]["pos"]).lerp(ARENA_CENTER, 0.25)
                h["vel"] = Vector2.ZERO
                h["normal_step"] = 0
                h["normal_chain_time"] = 0.0
                h["combo_target"] = -1
                h["combo_capture_time"] = 0.0
                h["attack_lock_time"] = 0.0
                h["charging_skill"] = false
                h["charge_time"] = 0.0
                _add_effect(&"respawn", Vector2(h["pos"]), 82.0, 0.65, Color("#6ef3a5"), "BACK IN!")
                event_log.emit(tick, &"hero_respawned", i, i, {})
        heroes[i] = h

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
        control_speed = 0.0
    elif float(h["combo_capture_time"]) > 0.0:
        control_speed = 0.0
    if float(h["attack_lock_time"]) > 0.0:
        control_speed *= 0.76
    if bool(h["charging_skill"]):
        control_speed *= 0.62
    h["vel"] = move * float(h["equipment"]["move_speed"]) * control_speed * _streak_move_multiplier(0)
    heroes[0] = h
    if bool(command.get("ultimate", false)):
        _cancel_skill_charge(0)
        _try_ultimate(0, Vector2(h["facing"]))
        return
    if bool(command.get("mobility", false)):
        _cancel_skill_charge(0)
        _try_mobility(0, move if move.length_squared() > 0.1 else Vector2(h["facing"]))
        return
    if bool(command.get("primary", false)):
        _cancel_skill_charge(0)
        _try_normal_attack(0, Vector2(h["facing"]))
    var equipment_held := bool(command.get("equipment", false))
    if bool(command.get("equipment_pressed", false)) or (equipment_held and not bool(heroes[0]["charging_skill"])):
        _begin_skill_charge(0, Vector2(h["facing"]))
    if equipment_held and bool(heroes[0]["charging_skill"]):
        _continue_skill_charge(0, FIXED_DT, Vector2(h["facing"]))
    if bool(command.get("equipment_released", false)):
        _release_skill_charge(0, Vector2(h["facing"]))

func _update_cpus(dt: float) -> void:
    for slot in range(1, heroes.size()):
        var h: Dictionary = heroes[slot]
        if bool(h["eliminated"]):
            continue
        if not bool(h["alive"]):
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
                if float(h["ultimate_charge"]) >= ULTIMATE_MAX and rng.chance(0.035):
                    _try_ultimate(slot, Vector2(h["facing"]))
                    h = heroes[slot]
                elif float(h["mobility_cd"]) <= 0.0 and rng.chance(0.055):
                    _try_mobility(slot, -Vector2(h["facing"]))
                    h = heroes[slot]
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
            if heal_index >= 0:
                var heal_pos: Vector2 = health_pickups[heal_index]["pos"]
                var to_heal := Vector2(h["pos"]).direction_to(heal_pos)
                var heal_strafe := to_heal.orthogonal() * (-1.0 if slot % 2 == 0 else 1.0)
                var heal_move := to_heal
                if _line_blocked(Vector2(h["pos"]), heal_pos):
                    heal_move = (to_heal * 0.38 + heal_strafe).normalized()
                var heal_cc_speed := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
                var heal_hitstun_speed := 0.0 if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 or float(h["root_time"]) > 0.0 else 1.0
                h["vel"] = heal_move * float(h["equipment"]["move_speed"]) * heal_cc_speed * heal_hitstun_speed * _streak_move_multiplier(slot)
                h["action"] = &"SEEK_HEAL"
                if tslot >= 0:
                    h["aim"] = Vector2(h["pos"]).direction_to(_target_position(tslot)).rotated(rng.rangef(-0.085, 0.085))
                    h["facing"] = h["aim"]
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
                elif _core_hp(tslot) < CORE_MAX_HP * 0.28:
                    desired = to_target
                    h["action"] = &"COMMIT_CORE"
                elif dist <= preferred_range * 1.15:
                    desired = (strafe * 0.88 + to_target * 0.12).normalized()
                    h["action"] = &"HOLD_RANGE"
                else:
                    desired = (to_target + strafe * 0.20).normalized()
                    h["action"] = &"CLOSE_RANGE"
                var cc_speed := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
                var hitstun_speed := 0.0 if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 or float(h["root_time"]) > 0.0 else 1.0
                var action_speed := 0.76 if float(h["attack_lock_time"]) > 0.0 else 1.0
                if bool(h["charging_skill"]):
                    action_speed *= 0.62
                h["vel"] = desired * float(h["equipment"]["move_speed"]) * cc_speed * hitstun_speed * action_speed * rng.rangef(0.93, 1.02) * _streak_move_multiplier(slot)
                var aim_error: float = rng.rangef(-0.085, 0.085)
                h["aim"] = to_target.rotated(aim_error)
                h["facing"] = h["aim"]
            var hazard_escape := _hazard_escape_vector(slot)
            if hazard_escape.length_squared() > 0.1:
                var hazard_cc_speed := 0.42 if float(h["cc_time"]) > 0.0 else 1.0
                var hazard_lock_speed := 0.0 if float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 or float(h["root_time"]) > 0.0 else 1.0
                h["vel"] = hazard_escape * float(h["equipment"]["move_speed"]) * hazard_cc_speed * hazard_lock_speed * _streak_move_multiplier(slot)
                h["action"] = &"DODGE_WARNING"
        heroes[slot] = h
        var current_target := int(h["target"])
        if current_target >= 0 and _target_valid(current_target):
            var target_pos := _target_position(current_target)
            var dist := Vector2(h["pos"]).distance_to(target_pos)
            var clear_shot := not _line_blocked(Vector2(h["pos"]), target_pos)
            if bool(h["charging_skill"]):
                _continue_skill_charge(slot, dt, Vector2(h["pos"]).direction_to(target_pos))
                h = heroes[slot]
                if float(h["charge_time"]) >= float(h["cpu_charge_target"]):
                    _release_skill_charge(slot, Vector2(h["pos"]).direction_to(target_pos))
                continue
            if h["action"] != &"SEEK_HEAL" and float(h["mobility_cd"]) <= 0.0 and float(h["launch_time"]) <= 0.0 and (dist > float(h["equipment"]["preferred_range"]) * 1.35 or dist < float(h["equipment"]["preferred_range"]) * 0.48) and rng.chance(0.025):
                var mobility_dir := Vector2(h["vel"]).normalized()
                if mobility_dir.length_squared() < 0.1:
                    mobility_dir = Vector2(h["pos"]).direction_to(target_pos)
                _try_mobility(slot, mobility_dir)
                h = heroes[slot]
            if dist < _normal_reach(slot) and clear_shot and float(h["fire_cd"]) <= 0.0:
                _try_normal_attack(slot, Vector2(h["aim"]))
            h = heroes[slot]
            if dist < _equipment_reach(slot) and clear_shot and float(h["equipment_cd"]) <= 0.0 and rng.chance(0.045):
                _begin_skill_charge(slot, Vector2(h["aim"]))
                h = heroes[slot]
                h["cpu_charge_target"] = rng.rangef(0.34, 1.15)
                heroes[slot] = h
            if dist < 720.0 and clear_shot and float(h["ultimate_charge"]) >= ULTIMATE_MAX and rng.chance(0.08):
                _try_ultimate(slot, Vector2(h["aim"]))

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
        var leader_value := clampf((float(target_h["threat"]) + (CORE_MAX_HP - _core_hp(target)) * 0.35) / 180.0, 0.0, 1.0)
        var finishability := clampf((130.0 - float(target_h["hp"])) / 130.0 + (CORE_MAX_HP * 0.36 - _core_hp(target)) / (CORE_MAX_HP * 0.55), 0.0, 1.0)
        var dogpile := 1.0 if attacker_counts[target] == 1 else 0.0
        var crowd_penalty := maxf(0.0, float(attacker_counts[target] - 1)) * 0.42
        var retaliation := clampf(float(target_h["threat"]) / 150.0, 0.0, 1.0)
        var grudge := 1.0 if int(heroes[slot]["recent_attacker"]) == target else 0.0
        var score := 0.26 * leader_value + 0.20 * finishability + 0.16 * clampf(1.0 - _core_hp(target) / CORE_MAX_HP, 0.0, 1.0)
        score += 0.13 * clampf(float(target_h["threat"]) / 120.0, 0.0, 1.0)
        score += 0.11 * grudge + 0.10 * dogpile + 0.06 * clampf(float(target_h["bounty"]) / 80.0, 0.0, 1.0)
        score -= crowd_penalty + 0.18 * retaliation + 0.15 * clampf(distance / 900.0, 0.0, 1.0)
        score += rng.rangef(-0.025, 0.025)
        if score > best_score:
            best_score = score
            best = target
    return best

func _best_health_pickup(slot: int) -> int:
    var h: Dictionary = heroes[slot]
    var health_ratio := float(h["hp"]) / maxf(1.0, float(h["max_hp"]))
    if health_ratio > 0.65:
        return -1
    var search_radius := 500.0
    if health_ratio <= 0.48:
        search_radius = 850.0
    if health_ratio <= 0.30:
        search_radius = 1250.0
    var best_index := -1
    var best_distance := search_radius
    for pickup_index in range(health_pickups.size()):
        var pickup: Dictionary = health_pickups[pickup_index]
        if not bool(pickup["active"]):
            continue
        var distance := Vector2(h["pos"]).distance_to(Vector2(pickup["pos"]))
        if distance < best_distance:
            best_distance = distance
            best_index = pickup_index
    return best_index

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
    return escape.normalized() if escape.length_squared() > 0.1 else Vector2.ZERO

func _target_valid(slot: int) -> bool:
    return slot >= 0 and slot < PLAYER_COUNT and bool(cores[slot]["alive"])

func _target_position(slot: int) -> Vector2:
    if bool(heroes[slot]["alive"]):
        return Vector2(heroes[slot]["pos"])
    return Vector2(cores[slot]["pos"])

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
                pickup["active"] = true
                pickup["pos"] = Vector2(pickup["home"])
                pickup["magnet_slot"] = -1
                _add_effect(&"heal_ready", Vector2(pickup["pos"]), 62.0, 0.55, Color("#6ef3a5"), "HEAL READY")
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
            _down_hero(launch_owner if launch_owner >= 0 else slot, slot)
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

func _point_in_cover(point: Vector2, padding: float = 0.0) -> bool:
    for cover in covers:
        var rect: Rect2 = cover["rect"]
        if rect.grow(padding).has_point(point):
            return true
    return false

func _line_blocked(from: Vector2, to: Vector2) -> bool:
    for cover in covers:
        var rect: Rect2 = Rect2(cover["rect"]).grow(3.0)
        if rect.has_point(from) or rect.has_point(to):
            return true
        var top_left := rect.position
        var top_right := Vector2(rect.end.x, rect.position.y)
        var bottom_left := Vector2(rect.position.x, rect.end.y)
        var bottom_right := rect.end
        if Geometry2D.segment_intersects_segment(from, to, top_left, top_right) != null:
            return true
        if Geometry2D.segment_intersects_segment(from, to, top_right, bottom_right) != null:
            return true
        if Geometry2D.segment_intersects_segment(from, to, bottom_right, bottom_left) != null:
            return true
        if Geometry2D.segment_intersects_segment(from, to, bottom_left, top_left) != null:
            return true
    return false

func _attack_direction(direction: Vector2) -> Vector2:
    var dir := direction.normalized()
    return Vector2.RIGHT if dir.length_squared() < 0.1 else dir

func _spawn_projectile(slot: int, direction: Vector2, damage: float, speed: float, radius: float, ttl: float, source: StringName, splash: float = 0.0, leech: bool = false, pierce: int = 0, cc_time: float = 0.0, knockback: float = 0.0, kind: StringName = &"bolt", homing: float = 0.0, label: String = "", combo_finisher: bool = false, control_kind: StringName = &"slow") -> void:
    var dir := _attack_direction(direction)
    projectiles.append({
        "id":next_entity_id,
        "owner":slot,
        "pos":Vector2(heroes[slot]["pos"]) + dir * 28.0,
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
        "trail":[Vector2(heroes[slot]["pos"]) + dir * 28.0],
        "source":source
    })
    next_entity_id += 1

func _spawn_arc_bomb(slot: int, direction: Vector2, distance: float, flight_time: float, damage: float, blast_radius: float, cc_time: float, knockback: float, combo_finisher: bool) -> void:
    var dir := _attack_direction(direction)
    var start := Vector2(heroes[slot]["pos"]) + dir * 28.0
    var landing := Vector2(heroes[slot]["pos"]) + dir * distance
    projectiles.append({
        "id":next_entity_id, "owner":slot, "pos":start,
        "vel":start.direction_to(landing) * start.distance_to(landing) / maxf(0.01, flight_time),
        "landing_pos":landing, "arc":true, "max_ttl":flight_time,
        "damage":damage, "radius":11.0, "ttl":flight_time,
        "splash":blast_radius, "leech":false, "pierce":0,
        "cc_time":cc_time, "knockback":knockback, "kind":&"bomb_arc",
        "homing":0.0, "label":"", "combo_finisher":combo_finisher,
        "hit_targets":[], "trail":[start], "source":&"normal"
    })
    next_entity_id += 1

func _normal_combo_pattern(equipment_id: String) -> Array:
    match equipment_id:
        "scatter": return [
            {"interval":0.20, "damage":0.68, "count":1, "spread":0.0, "knockback":8.0},
            {"interval":0.20, "damage":0.68, "count":1, "spread":0.0, "knockback":8.0},
            {"interval":0.13, "damage":0.46, "count":2, "spread":0.07, "knockback":7.0},
            {"interval":0.48, "damage":1.25, "count":3, "spread":0.10, "knockback":38.0, "finisher":true}
        ]
        "rail": return [
            {"interval":0.31, "damage":0.58, "count":1, "spread":0.018, "knockback":8.0},
            {"interval":0.28, "damage":0.72, "count":1, "spread":0.010, "knockback":12.0},
            {"interval":0.64, "damage":1.42, "count":1, "spread":0.0, "knockback":52.0, "finisher":true}
        ]
        "burst": return [
            {"interval":0.12, "damage":0.42, "count":1, "spread":0.018, "knockback":5.0},
            {"interval":0.12, "damage":0.42, "count":1, "spread":-0.018, "knockback":5.0},
            {"interval":0.12, "damage":0.48, "count":1, "spread":0.012, "knockback":6.0},
            {"interval":0.17, "damage":0.38, "count":2, "spread":0.06, "knockback":6.0},
            {"interval":0.42, "damage":0.72, "count":3, "spread":0.075, "knockback":34.0, "finisher":true}
        ]
        "brawler": return [
            {"interval":0.09, "damage":0.34, "reach":58.0, "radius":42.0, "lunge":15.0},
            {"interval":0.09, "damage":0.34, "reach":62.0, "radius":42.0, "lunge":15.0},
            {"interval":0.09, "damage":0.38, "reach":58.0, "radius":44.0, "lunge":16.0},
            {"interval":0.09, "damage":0.38, "reach":62.0, "radius":44.0, "lunge":16.0},
            {"interval":0.13, "damage":0.46, "reach":64.0, "radius":46.0, "lunge":18.0},
            {"interval":0.40, "damage":1.65, "reach":74.0, "radius":52.0, "lunge":34.0, "knockback":48.0, "finisher":true}
        ]
        "blade": return [
            {"interval":0.16, "damage":0.64, "reach":82.0, "radius":55.0, "lunge":25.0},
            {"interval":0.16, "damage":0.66, "reach":86.0, "radius":57.0, "lunge":28.0},
            {"interval":0.20, "damage":0.82, "reach":94.0, "radius":61.0, "lunge":34.0},
            {"interval":0.43, "damage":1.42, "reach":108.0, "radius":68.0, "lunge":52.0, "knockback":54.0, "finisher":true}
        ]
        "breaker": return [
            {"interval":0.27, "damage":0.62, "reach":82.0, "radius":64.0, "lunge":20.0},
            {"interval":0.31, "damage":0.78, "reach":88.0, "radius":72.0, "lunge":25.0},
            {"interval":0.58, "damage":1.28, "reach":96.0, "radius":82.0, "lunge":42.0, "knockback":68.0, "finisher":true}
        ]
        "shield": return [
            {"interval":0.24, "damage":0.58, "reach":70.0, "radius":66.0, "lunge":24.0},
            {"interval":0.28, "damage":0.72, "reach":78.0, "radius":72.0, "lunge":30.0},
            {"interval":0.55, "damage":1.25, "reach":88.0, "radius":82.0, "lunge":46.0, "knockback":58.0, "finisher":true}
        ]
        "spear": return [
            {"interval":0.18, "damage":0.58, "reach":112.0, "radius":42.0, "lunge":24.0},
            {"interval":0.18, "damage":0.62, "reach":126.0, "radius":42.0, "lunge":28.0},
            {"interval":0.23, "damage":0.78, "reach":142.0, "radius":45.0, "lunge":34.0},
            {"interval":0.48, "damage":1.38, "reach":168.0, "radius":50.0, "lunge":58.0, "knockback":56.0, "finisher":true}
        ]
        "chain", "leech": return [
            {"interval":0.20, "damage":0.58, "reach":132.0, "radius":54.0, "knockback":-8.0},
            {"interval":0.20, "damage":0.62, "reach":154.0, "radius":56.0, "knockback":-10.0},
            {"interval":0.24, "damage":0.78, "reach":176.0, "radius":60.0, "knockback":-14.0},
            {"interval":0.48, "damage":1.34, "reach":192.0, "radius":68.0, "knockback":-58.0, "finisher":true}
        ]
        "mortar": return [
            {"interval":0.42, "damage":0.78, "reach":270.0, "radius":58.0, "flight":0.50},
            {"interval":0.46, "damage":0.86, "reach":315.0, "radius":66.0, "flight":0.56},
            {"interval":0.78, "damage":1.48, "reach":370.0, "radius":94.0, "flight":0.66, "knockback":62.0, "finisher":true}
        ]
        "bomb": return [
            {"interval":0.62, "damage":1.02, "reach":330.0, "radius":76.0, "flight":0.46},
            {"interval":0.66, "damage":1.08, "reach":360.0, "radius":82.0, "flight":0.50},
            {"interval":0.92, "damage":1.72, "reach":400.0, "radius":108.0, "flight":0.58, "knockback":72.0, "finisher":true}
        ]
        _: return [{"interval":0.35, "damage":1.0, "reach":90.0, "radius":55.0, "finisher":true}]

func _normal_step_reach(slot: int, step: Dictionary) -> float:
    var equipment: Dictionary = heroes[slot]["equipment"]
    if str(equipment["id"]) in ["scatter", "rail", "burst"]:
        return float(equipment["normal_speed"]) * float(equipment["normal_range"]) * 0.82
    return float(step.get("reach", 90.0)) + float(step.get("radius", 55.0)) + HERO_RADIUS

func _normal_auto_target(slot: int, facing: Vector2, reach: float) -> int:
    var h: Dictionary = heroes[slot]
    var origin: Vector2 = h["pos"]
    var locked := int(h.get("combo_target", -1))
    if locked >= 0 and locked < heroes.size() and locked != slot and bool(heroes[locked]["alive"]):
        var locked_pos: Vector2 = heroes[locked]["pos"]
        var locked_dir := origin.direction_to(locked_pos)
        if origin.distance_to(locked_pos) <= reach + 90.0 and facing.dot(locked_dir) >= -0.10 and not _line_blocked(origin, locked_pos):
            return locked
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

func _try_normal_attack(slot: int, direction: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]) or float(h["fire_cd"]) > 0.0 or float(h["launch_time"]) > 0.0 or float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
        return
    var equipment: Dictionary = h["equipment"]
    var equipment_id := str(equipment["id"])
    var pattern := _normal_combo_pattern(equipment_id)
    var step_index := int(h["normal_step"]) if float(h["normal_chain_time"]) > 0.0 else 0
    step_index = posmod(step_index, pattern.size())
    var step: Dictionary = pattern[step_index]
    var base_dir := _attack_direction(direction)
    h["facing"] = base_dir
    h["aim"] = base_dir
    var assisted_target := _normal_auto_target(slot, base_dir, _normal_step_reach(slot, step))
    if assisted_target >= 0:
        base_dir = Vector2(h["pos"]).direction_to(Vector2(heroes[assisted_target]["pos"]))
        h["combo_target"] = assisted_target
        h["facing"] = base_dir
        h["aim"] = base_dir
    elif step_index == 0:
        h["combo_target"] = -1
    var projectile_count := int(step.get("count", 0))
    var spread := float(step.get("spread", 0.0))
    var center_jitter: float = rng.rangef(-spread * 0.15, spread * 0.15)
    var damage := float(equipment["normal_damage"]) * float(step.get("damage", 1.0))
    var knockback := float(step.get("knockback", float(equipment["normal_knockback"])))
    var finisher := bool(step.get("finisher", false))
    if equipment_id in ["bomb", "mortar"]:
        var bomb_distance := float(step.get("reach", 330.0))
        if assisted_target >= 0:
            bomb_distance = clampf(Vector2(h["pos"]).distance_to(Vector2(heroes[assisted_target]["pos"])), 95.0, bomb_distance)
        _spawn_arc_bomb(slot, base_dir, bomb_distance, float(step.get("flight", 0.50)), damage, float(step.get("radius", 76.0)), float(equipment["normal_cc"]), knockback, finisher)
    elif equipment_id in ["scatter", "rail", "burst"]:
        for index in range(projectile_count):
            var offset: float = (float(index) - float(projectile_count - 1) * 0.5) * spread + center_jitter
            _spawn_projectile(slot, base_dir.rotated(offset), damage, float(equipment["normal_speed"]), float(equipment["normal_radius"]), float(equipment["normal_range"]), &"normal", 0.0, false, 0, float(equipment["normal_cc"]), knockback, StringName(equipment["normal_kind"]), 0.0, "", finisher)
    else:
        var lunge := float(step.get("lunge", 0.0))
        if lunge > 0.0:
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), base_dir * lunge)
        heroes[slot] = h
        var reach := float(step.get("reach", 90.0))
        var radius := float(step.get("radius", 55.0))
        var strike_pos := Vector2(h["pos"]) + base_dir * reach
        var effect_kind := _projectile_impact_kind(str(equipment["normal_kind"]))
        var strike_delay := float(step.get("delay", 0.01))
        _add_zone(slot, strike_pos, radius, strike_delay, damage, &"normal", float(equipment["normal_cc"]), knockback, "", Color("#ffffff"), bool(equipment["normal_leech"]), effect_kind, finisher)
        if strike_delay > 0.06:
            _add_effect(&"fuse", strike_pos, radius * 0.42, strike_delay, Color("#ffb85c"), "", base_dir)
        else:
            _add_effect(effect_kind, strike_pos, radius * (1.12 if finisher else 0.88), 0.14 if finisher else 0.10, Color("#ffffff"), "", base_dir)
    var interval := float(step["interval"])
    h["fire_cd"] = interval
    h["attack_lock_time"] = minf(0.20, interval * 0.62)
    h["normal_step"] = 0 if finisher else step_index + 1
    h["normal_chain_time"] = 0.0 if finisher else maxf(0.72, interval + 0.42)
    h["normal_interval"] = interval
    if finisher:
        h["combo_target"] = -1
    h["action"] = &"NORMAL_COMBO"
    heroes[slot] = h
    event_log.emit(tick, &"normal_combo_step", slot, -1, {"step":step_index + 1, "steps":pattern.size(), "finisher":finisher, "equipment":equipment_id})

func _normal_reach(slot: int) -> float:
    var equipment: Dictionary = heroes[slot]["equipment"]
    if str(equipment["id"]) in ["scatter", "rail", "burst"]:
        return float(equipment["normal_speed"]) * float(equipment["normal_range"]) * 0.82
    var reach := 0.0
    for step in _normal_combo_pattern(str(equipment["id"])):
        reach = maxf(reach, float(step.get("reach", 90.0)) + float(step.get("radius", 55.0)))
    return reach

func _normal_combo_length(slot: int) -> int:
    return _normal_combo_pattern(str(heroes[slot]["equipment"]["id"])).size()

func _equipment_reach(slot: int) -> float:
    var equipment_id := str(heroes[slot]["equipment"]["id"])
    match equipment_id:
        "scatter": return 500.0
        "rail": return 940.0
        "mortar": return 680.0
        "leech": return 650.0
        "breaker": return 600.0
        "burst": return 700.0
        "blade": return 310.0
        "brawler": return 250.0
        "bomb": return 610.0
        "spear": return 820.0
        "chain": return 710.0
        _: return 270.0

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
    if not bool(h["alive"]) or float(h["mobility_cd"]) > 0.0 or float(h["launch_time"]) > 0.0 or float(h["cc_time"]) > 0.65 or float(h["hitstun_time"]) > 0.0 or float(h["root_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
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

func _begin_skill_charge(slot: int, direction: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]) or bool(h["charging_skill"]) or float(h["equipment_cd"]) > 0.0 or float(h["launch_time"]) > 0.0 or float(h["hitstun_time"]) > 0.0 or float(h["combo_capture_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
        return
    _cancel_attack_recovery(slot)
    h = heroes[slot]
    h["charging_skill"] = true
    h["charge_time"] = 0.0
    h["charge_dir"] = _attack_direction(direction)
    h["action"] = &"CHARGING_SKILL"
    heroes[slot] = h
    event_log.emit(tick, &"skill_charge_started", slot, -1, {"equipment":h["equipment"]["id"]})

func _continue_skill_charge(slot: int, dt: float, direction: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h["charging_skill"]):
        return
    if not bool(h["alive"]) or float(h["launch_time"]) > 0.0 or float(h["hitstun_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
        _cancel_skill_charge(slot)
        return
    h["charge_time"] = minf(1.15, float(h["charge_time"]) + dt)
    h["charge_dir"] = _attack_direction(direction)
    heroes[slot] = h

func _release_skill_charge(slot: int, direction: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h["charging_skill"]):
        return
    var charge_ratio := clampf(float(h["charge_time"]) / 1.15, 0.0, 1.0)
    var charge_dir := _attack_direction(direction) if direction.length_squared() > 0.1 else Vector2(h["charge_dir"])
    h["charging_skill"] = false
    h["charge_time"] = 0.0
    heroes[slot] = h
    _try_equipment_attack(slot, charge_dir, charge_ratio)

func _try_equipment_attack(slot: int, direction: Vector2, charge_ratio: float = 1.0) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]) or float(h["equipment_cd"]) > 0.0 or float(h["launch_time"]) > 0.0 or float(h["hitstun_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
        return
    var equipment: Dictionary = h["equipment"]
    var dir := _attack_direction(direction)
    charge_ratio = clampf(charge_ratio, 0.0, 1.0)
    var power := lerpf(0.65, 1.25, charge_ratio)
    var reach_scale := lerpf(0.80, 1.18, charge_ratio)
    var radius_scale := lerpf(0.84, 1.22, charge_ratio)
    h["action"] = &"CHARGED_SKILL"
    _add_effect(&"charge_release", Vector2(h["pos"]), 54.0 + charge_ratio * 28.0, 0.22, Color("#dff8ff"), "", dir)
    match str(equipment["id"]):
        "scatter":
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), -dir * lerpf(65.0, 120.0, charge_ratio))
            heroes[slot] = h
            var pellet_count := 3 + roundi(charge_ratio * 4.0)
            for pellet in range(pellet_count):
                var offset := (float(pellet) - float(pellet_count - 1) * 0.5) * 0.085
                _spawn_projectile(slot, dir.rotated(offset), float(equipment["damage"]) * power, float(equipment["speed"]), 7.0, float(equipment["range"]) * reach_scale, &"equipment", 0.0, false, 0, 0.0, 28.0 + 34.0 * charge_ratio, &"pellet", 0.0, "BACKBLAST", pellet == 0)
            _add_effect(&"cast", Vector2(h["pos"]), 92.0 + 34.0 * charge_ratio, 0.26, Color("#ffb45c"), "", dir)
        "rail":
            _spawn_projectile(slot, dir, float(equipment["damage"]) * power, float(equipment["speed"]) * reach_scale, 7.0, float(equipment["range"]) * reach_scale, &"equipment", 0.0, false, 1 + roundi(charge_ratio * 3.0), 0.55 + 0.65 * charge_ratio, 90.0 + 70.0 * charge_ratio, &"beam", 0.0, "ANCHOR BREAK", true)
            _add_effect(&"line", Vector2(h["pos"]), 620.0 + 220.0 * charge_ratio, 0.30, Color("#71e7ff"), "", dir)
        "mortar":
            var blast_pos := Vector2(h["pos"]) + dir * 430.0 * reach_scale
            _add_zone(slot, blast_pos, 120.0 * radius_scale, lerpf(0.90, 0.62, charge_ratio), float(equipment["damage"]) * power, &"equipment", 0.80 + 0.70 * charge_ratio, 95.0 + 80.0 * charge_ratio, "SKYFALL", Color("#ff795c"), false, &"explosion", true)
        "leech":
            var leech_pos := Vector2(h["pos"]) + dir * 190.0 * reach_scale
            _add_zone(slot, leech_pos, 68.0 * radius_scale, 0.05, float(equipment["damage"]) * power, &"equipment", 0.45 + 0.45 * charge_ratio, -105.0 - 80.0 * charge_ratio, "BLOOD HARPOON", Color("#dc72ff"), true, &"drain", true)
            _add_effect(&"line", Vector2(h["pos"]), 360.0 + 240.0 * charge_ratio, 0.24, Color("#dc72ff"), "", dir)
        "breaker":
            h["super_armor_time"] = maxf(float(h["super_armor_time"]), 0.38 + 0.30 * charge_ratio)
            h["super_armor_strength"] = maxf(float(h["super_armor_strength"]), 0.58)
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), dir * 175.0 * reach_scale)
            heroes[slot] = h
            _add_zone(slot, Vector2(h["pos"]), 112.0 * radius_scale, 0.08, float(equipment["damage"]) * power, &"equipment", 0.85 + 0.75 * charge_ratio, 125.0 + 100.0 * charge_ratio, "CRASH ENTRY", Color("#ffd166"), false, &"shockwave", true)
        "burst":
            var seeker_count := 2 + roundi(charge_ratio * 4.0)
            for seeker in range(seeker_count):
                var offset := (float(seeker) - float(seeker_count - 1) * 0.5) * 0.055
                _spawn_projectile(slot, dir.rotated(offset), float(equipment["damage"]) * power, float(equipment["speed"]), 8.0, float(equipment["range"]) * reach_scale, &"equipment", 18.0 + 16.0 * charge_ratio, false, 0, 0.0, 28.0 + 30.0 * charge_ratio, &"seeker", 2.4 + 2.0 * charge_ratio, "SEEKER SALVO", seeker == 0)
            _add_effect(&"cast", Vector2(h["pos"]), 78.0 + 24.0 * charge_ratio, 0.26, Color("#ff5da2"), "", dir)
        "blade":
            h["evade_time"] = maxf(float(h["evade_time"]), 0.24 + 0.20 * charge_ratio)
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), dir * 190.0 * reach_scale)
            heroes[slot] = h
            _add_zone(slot, Vector2(h["pos"]), 92.0 * radius_scale, 0.03, float(equipment["damage"]) * power, &"equipment", 0.22 + 0.28 * charge_ratio, 78.0 + 70.0 * charge_ratio, "CROSS STEP", Color("#b9f3ff"), false, &"slashwave", true)
        "brawler":
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), dir * 130.0 * reach_scale)
            heroes[slot] = h
            _add_zone(slot, Vector2(h["pos"]), 88.0 * radius_scale, 0.02, float(equipment["damage"]) * power, &"equipment", 0.38 + 0.42 * charge_ratio, 65.0 + 75.0 * charge_ratio, "LIVER SHOT", Color("#ff9466"), false, &"fist_burst", true)
        "bomb":
            var mine_pos := Vector2(h["pos"]) + dir * 320.0 * reach_scale
            _place_mine(slot, mine_pos, float(equipment["damage"]) * power, 118.0 * radius_scale, lerpf(0.72, 0.52, charge_ratio), 8.0, 0.38, false)
        "spear":
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), dir * 150.0 * reach_scale)
            heroes[slot] = h
            _add_zone(slot, Vector2(h["pos"]) + dir * 120.0 * reach_scale, 58.0 * radius_scale, 0.03, float(equipment["damage"]) * power, &"equipment", 0.38 + 0.42 * charge_ratio, 95.0 + 85.0 * charge_ratio, "VAULT IMPALE", Color("#ffe27a"), false, &"spear_line", true)
            _add_effect(&"spear_line", Vector2(h["pos"]), 440.0 + 230.0 * charge_ratio, 0.26, Color("#ffe27a"), "", dir)
        "chain":
            _add_zone(slot, Vector2(h["pos"]) + dir * 175.0 * reach_scale, 76.0 * radius_scale, 0.18, float(equipment["damage"]) * power, &"equipment", 0.75 + 0.80 * charge_ratio, -105.0 - 75.0 * charge_ratio, "CHAIN LOCK", Color("#b78cff"), false, &"chain_arc", true, &"root")
            _add_effect(&"chain_arc", Vector2(h["pos"]), 390.0 + 250.0 * charge_ratio, 0.28, Color("#b78cff"), "", dir)
        "shield":
            h["guard_time"] = 0.42 + 0.48 * charge_ratio
            heroes[slot] = h
            var wall_pos := Vector2(h["pos"]) + dir * (84.0 + 20.0 * charge_ratio)
            _place_bounce_wall(
                slot, wall_pos, dir,
                lerpf(96.0, 142.0, charge_ratio),
                lerpf(0.92, 1.24, charge_ratio),
                lerpf(520.0, 720.0, charge_ratio),
                lerpf(10.0, 16.0, charge_ratio),
                lerpf(185.0, 255.0, charge_ratio)
            )
    h["equipment_cd"] = float(equipment["cooldown"])
    heroes[slot] = h
    if slot == 0:
        impact_ticks = maxi(impact_ticks, 8)
    event_log.emit(tick, &"equipment_used", slot, -1, {"equipment":equipment["id"], "charge":charge_ratio})

func _try_ultimate(slot: int, direction: Vector2) -> void:
    var h: Dictionary = heroes[slot]
    if not bool(h["alive"]) or float(h["ultimate_charge"]) < ULTIMATE_MAX or float(h["launch_time"]) > 0.0 or float(h["hitstun_time"]) > 0.0 or float(h["stun_time"]) > 0.0:
        return
    var escaped_combo := float(h["combo_capture_time"]) > 0.0
    if escaped_combo:
        _break_incoming_combo(slot)
        h = heroes[slot]
    _cancel_skill_charge(slot)
    _cancel_attack_recovery(slot)
    h = heroes[slot]
    var equipment_id := str(h["equipment"]["id"])
    var dir := _attack_direction(direction)
    h["ultimate_charge"] = 0.0
    h["ultimates"] = int(h["ultimates"]) + 1
    var armor := _ultimate_armor(equipment_id)
    h["super_armor_time"] = float(armor["duration"])
    h["super_armor_strength"] = float(armor["strength"])
    heroes[slot] = h
    if escaped_combo:
        _add_effect(&"combo_break", Vector2(h["pos"]), 82.0, 0.32, Color("#ff8dac"), "REVERSAL", dir)
    match equipment_id:
        "scatter":
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), dir * 145.0)
            heroes[slot] = h
            _add_zone(slot, Vector2(h["pos"]), 115.0, 0.22, 18.0, &"ultimate", 0.85, 135.0, "ROOM CLEARER", Color("#ff9a45"), false, &"shockwave")
            for index in range(20):
                _spawn_projectile(slot, Vector2.RIGHT.rotated(TAU * float(index) / 20.0), 11.0, 780.0, 8.0, 0.90, &"ultimate", 0.0, false, 0, 0.55, 52.0, &"pellet")
        "rail":
            for strike in range(3):
                var strike_pos := Vector2(h["pos"]) + dir * (300.0 + 250.0 * strike)
                _add_zone(slot, strike_pos, 88.0, 0.35 + strike * 0.16, 34.0, &"ultimate", 1.85, 145.0, "DEADLINE %d" % (strike + 1), Color("#71e7ff"), false, &"rail_strike")
        "mortar":
            var target_pos := Vector2(h["pos"]) + dir * 500.0
            var offsets := [Vector2.ZERO, Vector2(130.0, 0.0), Vector2(-130.0, 0.0), Vector2(0.0, 130.0), Vector2(0.0, -130.0)]
            for strike in range(offsets.size()):
                _add_zone(slot, target_pos + offsets[strike], 105.0, 0.72 + strike * 0.18, 22.0, &"ultimate", 1.35, 145.0, "NO SAFE PLACE", Color("#ff604f"), false, &"explosion")
        "leech":
            for pulse in range(3):
                _add_zone(slot, Vector2(h["pos"]), 245.0, 0.20 + pulse * 0.34, 19.0, &"ultimate", 0.80, -145.0, "BLOOD AUCTION", Color("#d45cff"), true, &"drain")
        "breaker":
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), dir * 260.0)
            heroes[slot] = h
            _add_zone(slot, Vector2(h["pos"]), 215.0, 0.30, 48.0, &"ultimate", 2.40, 270.0, "TABLE FLIP", Color("#ffe06a"), false, &"shockwave")
        "burst":
            for index in range(12):
                var launch_dir := dir.rotated((float(index) - 5.5) * 0.11)
                _spawn_projectile(slot, launch_dir, 12.0, 850.0, 8.0, 1.45, &"ultimate", 32.0, false, 0, 0.35, 48.0, &"seeker", 5.2, "HUNTER STORM")
        "blade":
            for cut in range(5):
                var cut_dir := dir.rotated((float(cut) - 2.0) * 0.09)
                _spawn_projectile(slot, cut_dir, 12.0, 1180.0, 28.0, 0.62, &"ultimate", 0.0, false, 1, 0.28, 58.0 + cut * 18.0, &"slash", 0.0, "THOUSANDTH EDGE")
        "brawler":
            h["pos"] = _resolve_cover_motion(Vector2(h["pos"]), dir * 240.0)
            heroes[slot] = h
            for punch in range(6):
                _spawn_projectile(slot, dir.rotated((float(punch) - 2.5) * 0.07), 7.0, 900.0, 19.0, 0.28, &"ultimate", 0.0, false, 0, 0.16, 24.0, &"fist", 0.0, "TEN COUNT")
            _add_zone(slot, Vector2(h["pos"]), 125.0, 0.22, 34.0, &"ultimate", 0.85, 230.0, "FINAL UPPERCUT", Color("#ff7d55"), false, &"fist_burst")
        "bomb":
            var minefield_center := Vector2(h["pos"]) + dir * 300.0
            for mine_index in range(5):
                var mine_offset := Vector2.ZERO if mine_index == 0 else Vector2.RIGHT.rotated(TAU * float(mine_index - 1) / 4.0) * 128.0
                _place_mine(slot, minefield_center + mine_offset, 23.0, 128.0, 0.34 + mine_index * 0.04, 5.5, 0.32, true, 1.35 + mine_index * 0.10)
        "spear":
            for thrust in range(3):
                _spawn_projectile(slot, dir.rotated((float(thrust) - 1.0) * 0.045), 26.0, 1420.0, 14.0, 1.05, &"ultimate", 0.0, false, 4, 0.72, 150.0, &"spear", 0.0, "DRAGON LINE")
        "chain":
            _add_zone(slot, Vector2(h["pos"]), 300.0, 0.36, 11.0, &"ultimate", 0.58, -105.0, "CAROUSEL PULL I", Color("#a86cff"), false, &"chain_vortex", false, &"root")
            _add_zone(slot, Vector2(h["pos"]), 300.0, 0.68, 13.0, &"ultimate", 0.72, -150.0, "CAROUSEL PULL II", Color("#b78cff"), false, &"chain_vortex", false, &"root")
            _add_zone(slot, Vector2(h["pos"]), 300.0, 1.02, 26.0, &"ultimate", 0.82, 235.0, "BLACK CAROUSEL", Color("#f2d7ff"), false, &"chain_vortex", true, &"stun")
        "shield":
            h["guard_time"] = 2.40
            h["hp"] = minf(float(h["max_hp"]), float(h["hp"]) + 20.0)
            heroes[slot] = h
            _add_zone(slot, Vector2(h["pos"]), 230.0, 0.34, 42.0, &"ultimate", 1.10, 320.0, "LAST ONE STANDING", Color("#8de1ff"), false, &"shield_bash")
    _add_effect(&"charge_release", Vector2(h["pos"]), 76.0, 0.24, Color("#ff8dac"), "", dir)
    if slot == 0:
        impact_ticks = maxi(impact_ticks, 8)
        impact_pos = Vector2(h["pos"])
    if slot == 0:
        ultimate_focus_slot = slot
        ultimate_focus_time = ultimate_focus_max
        _announce("P%d  %s" % [slot + 1, h["equipment"]["ultimate_name"]], 58)
    event_log.emit(tick, &"ultimate_used", slot, -1, {"equipment":equipment_id})

func _ultimate_armor(equipment_id: String) -> Dictionary:
    match equipment_id:
        "shield": return {"duration":1.15, "strength":1.0}
        "breaker": return {"duration":0.95, "strength":0.90}
        "brawler": return {"duration":0.82, "strength":0.82}
        "blade", "spear": return {"duration":0.64, "strength":0.68}
        "chain": return {"duration":1.08, "strength":0.68}
        "scatter", "leech": return {"duration":0.52, "strength":0.55}
        _: return {"duration":0.40, "strength":0.42}

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
                _add_effect(&"explosion", landing, float(p["splash"]), 0.32, Color("#ff554a"), "")
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
            if bool(heroes[target]["alive"]) and Vector2(p["pos"]).distance_to(Vector2(heroes[target]["pos"])) < float(p["radius"]) + HERO_RADIUS:
                _damage_hero(owner, target, float(p["damage"]), StringName(p["source"]), float(p["cc_time"]), float(p.get("knockback", 0.0)), Vector2(heroes[owner]["pos"]), str(p.get("label", "")), _projectile_impact_kind(str(p.get("kind", "bolt"))), bool(p.get("combo_finisher", false)), StringName(p.get("control_kind", &"slow")))
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
            if Vector2(p["pos"]).distance_to(Vector2(cores[target]["pos"])) < float(p["radius"]) + CORE_RADIUS:
                _damage_core(owner, target, float(p["damage"]) * 0.78, StringName(p["source"]))
                hit = true
                break
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
    if float(h["evade_time"]) > 0.0:
        h["evade_time"] = 0.0
        heroes[target] = h
        _add_effect(&"afterimage", Vector2(h["pos"]), 105.0, 0.38, Color("#b9f3ff"), "EVADE")
        event_log.emit(tick, &"attack_evaded", owner, target, {"source":source})
        return
    var attacker: Dictionary = heroes[owner]
    var attacker_id := str(attacker["equipment"]["id"])
    amount *= _streak_damage_multiplier(owner)
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
    if float(h["guard_time"]) > 0.0:
        amount *= 0.55
        knockback *= 0.52
    var armor_active := float(h["super_armor_time"]) > 0.0
    var armor_strength := clampf(float(h["super_armor_strength"]), 0.0, 1.0) if armor_active else 0.0
    if armor_active:
        h["combo_capture_time"] = 0.0
    if source != &"mobility":
        var combo_cap := float(h["max_hp"]) * float(h["equipment"]["combo_cap_ratio"])
        var combo_remaining := maxf(0.0, combo_cap - float(h["combo_damage"]))
        amount = minf(amount, combo_remaining)
        h["combo_damage"] = float(h["combo_damage"]) + amount
    h["hp"] = float(h["hp"]) - amount
    h["recent_attacker"] = owner
    h["grudge"] = minf(1.0, float(h["grudge"]) + amount / 100.0)
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
    if combo_hit > 0:
        var hitstun := 0.04 if float(h["combo_immunity"]) > 0.0 else minf(0.28, 0.07 + combo_hit * 0.055)
        if source == &"normal":
            var attack_interval := maxf(0.09, float(attacker.get("normal_interval", 0.24)))
            hitstun = 0.04 if float(h["combo_immunity"]) > 0.0 else clampf(attack_interval * 0.52, 0.045, 0.16)
            if attack_finisher:
                h["combo_capture_time"] = 0.0
            elif float(h["combo_immunity"]) <= 0.0 and not armor_active:
                h["combo_capture_time"] = maxf(float(h["combo_capture_time"]), attack_interval + 0.20)
        elif attacker_id == "chain":
            hitstun += 0.05
        if not armor_active:
            h["hitstun_time"] = maxf(float(h["hitstun_time"]), hitstun)
    var launch_knockback := knockback
    if source == &"normal" and not attack_finisher:
        launch_knockback = 0.0
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
    event_log.emit(tick, &"hero_hit", owner, target, {"damage":amount, "knockback":launch_knockback, "label":effect_label, "source":source, "combo":combo_hit})
    if owner == 0 or target == 0:
        impact_ticks = maxi(impact_ticks, 4 if source == &"normal" else (11 if source == &"equipment" else 18))
        impact_pos = Vector2(h["pos"])
    if float(h["hp"]) <= 0.0:
        _down_hero(owner, target)

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
        _eliminate(owner, target)

func _award_charge(slot: int, amount: float, source: StringName) -> void:
    if source == &"ultimate" or source == &"mobility" or slot < 0 or slot >= heroes.size():
        return
    var h: Dictionary = heroes[slot]
    var previous := float(h["ultimate_charge"])
    var gain := minf(7.0, 1.5 + amount * 0.38)
    if source == &"equipment":
        gain = minf(18.0, 7.0 + amount * 0.28)
        h["equipment_hits"] = int(h["equipment_hits"]) + 1
    else:
        h["normal_hits"] = int(h["normal_hits"]) + 1
    h["ultimate_charge"] = minf(ULTIMATE_MAX, previous + gain)
    heroes[slot] = h
    if previous < ULTIMATE_MAX and float(h["ultimate_charge"]) >= ULTIMATE_MAX:
        if slot == 0:
            _announce("ULTIMATE READY", 48)
        event_log.emit(tick, &"ultimate_ready", slot, -1, {})

func _heal_hero(slot: int, amount: float) -> void:
    var h: Dictionary = heroes[slot]
    if bool(h["alive"]):
        h["hp"] = minf(float(h["max_hp"]), float(h["hp"]) + amount)
        heroes[slot] = h

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

func _down_hero(owner: int, target: int) -> void:
    var h: Dictionary = heroes[target]
    var defeated_streak := int(h.get("kill_streak", 0))
    var death_velocity: Vector2 = h["launch_vel"]
    if death_velocity.length() < 450.0:
        var death_direction := Vector2(heroes[owner]["pos"]).direction_to(Vector2(h["pos"]))
        if death_direction.length_squared() < 0.1:
            death_direction = Vector2.RIGHT.rotated(float(target) * TAU / float(PLAYER_COUNT))
        death_velocity = death_direction * 1550.0
    else:
        death_velocity = death_velocity.normalized() * maxf(1550.0, death_velocity.length() * 1.35)
    knockouts.append({"slot":target, "pos":Vector2(h["pos"]), "vel":death_velocity, "time":2.15, "max_time":2.15, "bounces":0, "finished":false, "trail":[Vector2(h["pos"])], "equipment":str(h["equipment"]["id"])})
    h["alive"] = false
    h["hp"] = 0.0
    h["respawn"] = 10.0
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
    h["deaths"] = int(h["deaths"]) + 1
    h["kill_streak"] = 0
    heroes[target] = h
    _add_effect(&"death_burst", Vector2(h["pos"]), 260.0, 1.25, Color("#ff3349"), "", death_velocity.normalized())
    impact_ticks = maxi(impact_ticks, 32)
    last_down_slot = target
    last_down_ticks = 105
    var streak_after := 0
    var shutdown_bonus := 0.0
    if owner >= 0 and owner < heroes.size() and owner != target:
        var attacker: Dictionary = heroes[owner]
        attacker["kills"] = int(attacker["kills"]) + 1
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
            attacker["ultimate_charge"] = minf(ULTIMATE_MAX, float(attacker["ultimate_charge"]) + 7.0 + minf(5.0, float(streak_after)))
            attacker["score"] = float(attacker["score"]) + maxf(0.0, float(streak_after - 1) * 15.0)
        if defeated_streak >= 3:
            shutdown_bonus = minf(230.0, 90.0 + float(defeated_streak - 3) * 35.0)
            attacker["score"] = float(attacker["score"]) + shutdown_bonus
            attacker["bounty"] = maxf(0.0, float(attacker["bounty"]) - 20.0)
            if bool(attacker["alive"]):
                attacker["hp"] = minf(float(attacker["max_hp"]), float(attacker["hp"]) + float(attacker["max_hp"]) * 0.14)
                attacker["equipment_cd"] *= 0.50
                attacker["mobility_cd"] *= 0.50
                attacker["ultimate_charge"] = minf(ULTIMATE_MAX, float(attacker["ultimate_charge"]) + minf(30.0, 14.0 + float(defeated_streak) * 2.0))
            var attacker_name := str(attacker["equipment"]["character_name"])
            var defeated_name := str(h["equipment"]["character_name"])
            _show_streak_callout("연속 처치 종료!", "P%d %s님이 P%d %s님의 %d연속 처치를 끝냈습니다." % [owner + 1, attacker_name, target + 1, defeated_name, defeated_streak], true)
            event_log.emit(tick, &"streak_shutdown", owner, target, {"streak":defeated_streak, "bonus":shutdown_bonus})
        elif streak_after >= 2:
            var streak_attacker_name := str(attacker["equipment"]["character_name"])
            _show_streak_callout(_streak_title(streak_after), "P%d %s님이 %d연속 처치 중입니다." % [owner + 1, streak_attacker_name, streak_after], false)
            event_log.emit(tick, &"kill_streak", owner, target, {"streak":streak_after})
        heroes[owner] = attacker
    impact_pos = Vector2(h["pos"])
    event_log.emit(tick, &"hero_downed", owner, target, {"streak":streak_after, "ended_streak":defeated_streak, "shutdown_bonus":shutdown_bonus})
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
    var new_wanted := _highest_threat_except(-1)
    if new_wanted != wanted_slot and new_wanted >= 0:
        wanted_slot = new_wanted
        _announce("BOUNTY: EVERYONE GET P%d!" % (wanted_slot + 1), 105)

func _hero_hp_ratio(slot: int) -> float:
    if slot < 0 or slot >= heroes.size() or not bool(cores[slot]["alive"]):
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
    var candidate_core := _core_hp_ratio(candidate)
    var current_core := _core_hp_ratio(current)
    if not is_equal_approx(candidate_core, current_core):
        return candidate_core > current_core
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
    for slot in range(cores.size()):
        if bool(cores[slot]["alive"]) and _time_limit_better(slot, best):
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
    if bool(a["core_alive"]) != bool(b["core_alive"]):
        return bool(a["core_alive"])
    return float(a["score"]) > float(b["score"])

func final_standings() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for slot in range(heroes.size()):
        rows.append({
            "slot":slot,
            "hp_ratio":_hero_hp_ratio(slot),
            "core_ratio":_core_hp_ratio(slot),
            "score":float(heroes[slot]["score"]),
            "core_alive":bool(cores[slot]["alive"])
        })
    rows.sort_custom(_standing_better)
    return rows

func _check_end() -> void:
    var alive_slots: Array[int] = []
    for core in cores:
        if bool(core["alive"]):
            alive_slots.append(int(core["slot"]))
    if alive_slots.size() == 1:
        _declare_winner(alive_slots[0], &"last_core")
    elif alive_slots.is_empty():
        result = &"draw"
        result_reason = &"no_cores"
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
    for core in cores:
        if bool(core["alive"]):
            alive += 1
        core_hps.append(maxf(0.0, float(core["hp"])))
    for hero in heroes:
        ultimate_uses += int(hero["ultimates"])
        equipment_hits += int(hero["equipment_hits"])
    return {"tick":tick, "time":match_time, "time_limit":MATCH_TIME_LIMIT, "alive":alive, "winner":winner_slot, "result":result, "result_reason":result_reason, "decision_hp_ratio":decision_hp_ratio, "decision_core_ratio":decision_core_ratio, "projectiles":projectiles.size(), "start_countdown":start_countdown, "core_hps":core_hps, "ultimate_uses":ultimate_uses, "equipment_hits":equipment_hits}

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
