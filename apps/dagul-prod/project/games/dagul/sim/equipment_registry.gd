class_name EquipmentRegistry
extends RefCounted

const MODE_START_EQUIPMENT := {"gun-semi":"rail", "gun-auto":"burst", "item":"scatter"}
const GUN_LOOT_CHAIN := ["rail", "burst", "scatter", "mortar", "breaker", "bomb", "leech", "blade", "spear", "chain", "shield", "brawler"]

var defs := [
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

## 일반공격 발사 프로필(발사 모드·간격·탄속·사거리=비행시간) — match-gun.ts spawnShot/
## tryNormalAttack 과 같은 weapon_id 키. 로컬 발사 예측이 실탄과 같은 탄속·TTL로
## 시각 총알을 그리고, auto 무기의 연사 간격을 아는 데 쓴다.
func fire_profile_for(equipment_id: String) -> Dictionary:
    for def in defs:
        if str(def["id"]) == equipment_id:
            return {
                "fire_mode": str(def.get("fire_mode", "auto")),
                "interval": float(def.get("normal_interval", 0.12)),
                "speed": float(def.get("normal_speed", 1000.0)),
                "range": float(def.get("normal_range", 0.5)),
            }
    return {"fire_mode": "auto", "interval": 0.12, "speed": 1000.0, "range": 0.5}

func identity_for(equipment_id: String) -> Dictionary:
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

func combat_stats_for(equipment_id: String) -> Dictionary:
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

func skill_stats_for(equipment_id: String) -> Dictionary:
    match equipment_id:
        "scatter": return {"cooldown": 3.10, "damage": 7.0, "speed": 720.0, "range": 0.72, "skill_name": "BACKBLAST", "skill_desc": "Cone knockback plus recoil escape"}
        "rail": return {"cooldown": 3.50, "damage": 38.0, "speed": 1120.0, "range": 1.42, "skill_name": "ANCHOR BREAK", "skill_desc": "Pierce, stagger and launch in one line"}
        "mortar": return {"cooldown": 4.40, "damage": 24.0, "speed": 560.0, "range": 1.08, "skill_name": "SKYFALL", "skill_desc": "Warned blast opens cores and launches groups"}
        "leech": return {"cooldown": 3.40, "damage": 18.0, "speed": 820.0, "range": 1.08, "skill_name": "BLOOD HARPOON", "skill_desc": "Hook pulls prey in and restores health"}
        "breaker": return {"cooldown": 3.60, "damage": 32.0, "speed": 650.0, "range": 0.96, "skill_name": "CRASH ENTRY", "skill_desc": "Armored dash ends in a heavy shockwave"}
        "burst": return {"cooldown": 3.35, "damage": 10.0, "speed": 820.0, "range": 1.18, "skill_name": "SEEKER SALVO", "skill_desc": "Three curving missiles chase evasive prey"}
        "blade": return {"cooldown": 3.10, "damage": 27.0, "speed": 980.0, "range": 0.32, "skill_name": "CROSS STEP", "skill_desc": "Pass through the target and cut the exit"}
        "brawler": return {"cooldown": 3.20, "damage": 24.0, "speed": 820.0, "range": 0.26, "skill_name": "LIVER SHOT", "skill_desc": "Shoulder in and pin the target in hitstun"}
        "bomb": return {"cooldown": 4.40, "damage": 27.0, "speed": 520.0, "range": 1.10, "skill_name": "PROX MINE", "skill_desc": "Install up to two visible proximity mines"}
        "spear": return {"cooldown": 3.45, "damage": 29.0, "speed": 1180.0, "range": 0.72, "skill_name": "VAULT IMPALE", "skill_desc": "Vault forward and skewer a sightline"}
        "chain": return {"cooldown": 4.60, "damage": 21.0, "speed": 900.0, "range": 0.78, "skill_name": "CHAIN LOCK", "skill_desc": "Pull and root one target; charge for a longer bind"}
        _: return {"cooldown": 5.60, "damage": 22.0, "speed": 700.0, "range": 0.30, "skill_name": "BULLDOZER WALL", "skill_desc": "Launch a warned moving wall that sweeps enemies away"}

func mobility_for(equipment_id: String) -> Dictionary:
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

func make_equipment(equipment_id: String) -> Dictionary:
    var base: Dictionary = defs[0]
    for def in defs:
        if str(def["id"]) == equipment_id:
            base = def
            break
    var equipment: Dictionary = base.duplicate(true)
    var identity := identity_for(str(equipment["id"]))
    for key in identity:
        equipment[key] = identity[key]
    var mobility := mobility_for(str(equipment["id"]))
    for key in mobility:
        equipment[key] = mobility[key]
    var combat_stats := combat_stats_for(str(equipment["id"]))
    for key in combat_stats:
        equipment[key] = combat_stats[key]
    var skill := skill_stats_for(str(equipment["id"]))
    for key in skill:
        equipment[key] = skill[key]
    return equipment
