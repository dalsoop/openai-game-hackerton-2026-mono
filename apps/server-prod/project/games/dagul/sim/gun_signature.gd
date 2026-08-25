class_name GunSignature
extends RefCounted

## Animal = play tendency. Gun = current combat kit.
## Visual frames from game-lhj-animal Art/Prebs/Gun tscn (Tex_Gun_4x3, hframes=4 vframes=3).
## Frame 7 is AKM art used as AWM stand-in (no AWM texture in repo).
## No animal-based fire interval / damage / spread / ammo / crit.

const COLS := 4
const ROWS := 3

# Zodiac slot order: Rat Ox Tiger Rabbit Dragon Snake Horse Goat Monkey Rooster Dog Pig
const ANIMAL_SIGNATURE_EQUIPMENT := [
    "burst",
    "breaker",
    "spear",
    "brawler",
    "mortar",
    "leech",
    "chain",
    "shield",
    "blade",
    "rail",
    "scatter",
    "bomb",
]

# equipment_id -> gun visual. Each equipment and each gun frame used once.
# Feel pairing: burst~Glock, rail~AWM/AKM, mortar~M79, scatter~SPAS, bomb~DB, breaker~RPK.
const EQUIP_VISUAL := {
    "burst": {"frame": 1, "gun": "Glock 18", "family": "pistol", "muzzle_row": 0, "ox": 9.302326, "oy": -12.403107, "mx": 93.0, "my": -22.000305},
    "brawler": {"frame": 0, "gun": "M1911", "family": "pistol", "muzzle_row": 0, "ox": 12.403101, "oy": -20.155045, "mx": 89.0, "my": -22.000305},
    "leech": {"frame": 2, "gun": "MP5", "family": "smg", "muzzle_row": 1, "ox": 41.860466, "oy": -29.45737, "mx": 133.0, "my": -22.000305},
    "blade": {"frame": 3, "gun": "Thompson", "family": "smg", "muzzle_row": 1, "ox": -6.2015514, "oy": -17.05427, "mx": 114.0, "my": -19.0},
    "spear": {"frame": 6, "gun": "AK-47", "family": "rifle", "muzzle_row": 1, "ox": 29.457336, "oy": 0.0, "mx": 138.0, "my": -10.0},
    "chain": {"frame": 5, "gun": "M4A1", "family": "rifle", "muzzle_row": 1, "ox": 27.906982, "oy": -4.651169, "mx": 137.0, "my": -16.50813},
    "shield": {"frame": 10, "gun": "Winchester M1873", "family": "rifle", "muzzle_row": 1, "ox": 35.658913, "oy": 21.705421, "mx": 144.0, "my": -19.0},
    "scatter": {"frame": 9, "gun": "SPAS-12", "family": "shotgun", "muzzle_row": 1, "ox": 40.310078, "oy": 18.604645, "mx": 145.0, "my": -17.0},
    "bomb": {"frame": 8, "gun": "Double barrel", "family": "shotgun", "muzzle_row": 2, "ox": 29.457365, "oy": 20.155033, "mx": 140.0, "my": -22.0},
    "breaker": {"frame": 4, "gun": "RPK", "family": "heavy", "muzzle_row": 2, "ox": 20.15503, "oy": 7.751938, "mx": 130.0, "my": -9.675},
    "rail": {"frame": 7, "gun": "AWM (AKM stand-in)", "family": "heavy", "muzzle_row": 2, "ox": 49.612404, "oy": -17.05427, "mx": 151.0, "my": -14.754375},
    "mortar": {"frame": 11, "gun": "M79", "family": "heavy", "muzzle_row": 2, "ox": 9.302326, "oy": -4.651169, "mx": 120.0, "my": -20.0},
}



# Per-gun fire feel. Recoil kick snaps then decays (higher decay = faster settle).
const GUN_FEEL := {
    "burst": {"kick": 6.2, "rot": 0.07, "body": 0.07, "strap": 1.4, "decay": 24.0, "muzzle": 0.12},
    "brawler": {"kick": 11.0, "rot": 0.16, "body": 0.12, "strap": 1.8, "decay": 22.0, "muzzle": 0.055},
    "leech": {"kick": 5.0, "rot": 0.065, "body": 0.06, "strap": 1.8, "decay": 22.0, "muzzle": 0.11},
    "blade": {"kick": 6.4, "rot": 0.085, "body": 0.08, "strap": 2.0, "decay": 18.0, "muzzle": 0.12},
    "spear": {"kick": 10.5, "rot": 0.15, "body": 0.12, "strap": 2.0, "decay": 13.0, "muzzle": 0.14},
    "chain": {"kick": 8.2, "rot": 0.11, "body": 0.09, "strap": 1.6, "decay": 15.0, "muzzle": 0.13},
    "shield": {"kick": 12.5, "rot": 0.20, "body": 0.14, "strap": 2.2, "decay": 11.0, "muzzle": 0.16},
    "scatter": {"kick": 20.0, "rot": 0.34, "body": 0.22, "strap": 3.2, "decay": 7.5, "muzzle": 0.16},
    "bomb": {"kick": 24.0, "rot": 0.40, "body": 0.26, "strap": 3.6, "decay": 6.5, "muzzle": 0.17},
    "breaker": {"kick": 13.5, "rot": 0.18, "body": 0.15, "strap": 2.4, "decay": 8.5, "muzzle": 0.15},
    "rail": {"kick": 20.0, "rot": 0.26, "body": 0.20, "strap": 3.0, "decay": 7.0, "muzzle": 0.18},
    "mortar": {"kick": 18.0, "rot": 0.24, "body": 0.19, "strap": 2.8, "decay": 7.5, "muzzle": 0.17},
}


# Screen-pixel mouse kicks after each shot (x right, y up is negative).
# Shot 0 is already on the cursor. These kicks move the cursor for the NEXT shot.
# Pattern shape: climb first, then a fixed left/right tail. Same every mag.
const SPRAY_KICK := {
    "spear": [
        Vector2(0, -15), Vector2(1, -17), Vector2(-1, -16), Vector2(2, -15),
        Vector2(-2, -14), Vector2(3, -12), Vector2(-5, -10), Vector2(7, -7),
        Vector2(-9, -4), Vector2(11, -2), Vector2(-12, 0), Vector2(12, 1),
        Vector2(-11, 1), Vector2(10, 0), Vector2(-10, 1), Vector2(9, 0),
        Vector2(-9, 1), Vector2(8, 0), Vector2(-8, 0), Vector2(8, 1),
        Vector2(-7, 0), Vector2(7, 0), Vector2(-7, 1), Vector2(6, 0),
        Vector2(-6, 0), Vector2(6, 0), Vector2(-5, 0), Vector2(5, 0),
        Vector2(-5, 0), Vector2(5, 0)
    ],
    "chain": [
        Vector2(0, -12), Vector2(1, -13), Vector2(0, -13), Vector2(1, -12),
        Vector2(-2, -11), Vector2(3, -9), Vector2(-4, -7), Vector2(6, -5),
        Vector2(-7, -3), Vector2(8, -1), Vector2(-8, 0), Vector2(8, 1),
        Vector2(-7, 0), Vector2(7, 0), Vector2(-6, 1), Vector2(6, 0),
        Vector2(-6, 0), Vector2(5, 0), Vector2(-5, 0), Vector2(5, 0),
        Vector2(-5, 0), Vector2(4, 0), Vector2(-4, 0), Vector2(4, 0),
        Vector2(-4, 0), Vector2(4, 0), Vector2(-3, 0), Vector2(3, 0),
        Vector2(-3, 0), Vector2(3, 0)
    ],
    "leech": [
        Vector2(1, -8), Vector2(-1, -9), Vector2(2, -8), Vector2(-3, -7),
        Vector2(4, -6), Vector2(-6, -4), Vector2(7, -3), Vector2(-8, -1),
        Vector2(8, 0), Vector2(-8, 1), Vector2(7, 0), Vector2(-7, 0),
        Vector2(6, 1), Vector2(-6, 0), Vector2(6, 0), Vector2(-5, 0),
        Vector2(5, 0), Vector2(-5, 0), Vector2(4, 0), Vector2(-4, 0),
        Vector2(4, 0), Vector2(-4, 0), Vector2(3, 0), Vector2(-3, 0), Vector2(3, 0)
    ],
    "blade": [
        Vector2(1, -10), Vector2(-2, -11), Vector2(3, -10), Vector2(-4, -8),
        Vector2(6, -6), Vector2(-8, -4), Vector2(9, -2), Vector2(-10, 0),
        Vector2(10, 1), Vector2(-9, 0), Vector2(9, 0), Vector2(-8, 1),
        Vector2(8, 0), Vector2(-7, 0), Vector2(7, 0), Vector2(-6, 0),
        Vector2(6, 0), Vector2(-6, 0), Vector2(5, 0), Vector2(-5, 0),
        Vector2(5, 0), Vector2(-4, 0), Vector2(4, 0), Vector2(-4, 0),
        Vector2(4, 0), Vector2(-3, 0), Vector2(3, 0), Vector2(-3, 0),
        Vector2(3, 0), Vector2(-3, 0), Vector2(3, 0), Vector2(-2, 0)
    ],
    "breaker": [
        Vector2(0, -14), Vector2(1, -15), Vector2(-1, -14), Vector2(2, -13),
        Vector2(-3, -12), Vector2(4, -10), Vector2(-6, -8), Vector2(8, -5),
        Vector2(-9, -3), Vector2(11, -1), Vector2(-12, 0), Vector2(12, 1),
        Vector2(-11, 0), Vector2(10, 0), Vector2(-10, 1), Vector2(9, 0),
        Vector2(-9, 0), Vector2(8, 0), Vector2(-8, 0), Vector2(8, 1),
        Vector2(-7, 0), Vector2(7, 0), Vector2(-7, 0), Vector2(6, 0),
        Vector2(-6, 0), Vector2(6, 0), Vector2(-5, 0), Vector2(5, 0),
        Vector2(-5, 0), Vector2(5, 0), Vector2(-5, 0), Vector2(4, 0),
        Vector2(-4, 0), Vector2(4, 0), Vector2(-4, 0), Vector2(4, 0),
        Vector2(-3, 0), Vector2(3, 0), Vector2(-3, 0), Vector2(3, 0)
    ],
    "burst": [
        Vector2(1, -9), Vector2(-2, -10), Vector2(3, -9), Vector2(-4, -7),
        Vector2(6, -5), Vector2(-7, -3), Vector2(8, -1), Vector2(-8, 0),
        Vector2(7, 1), Vector2(-7, 0), Vector2(6, 0), Vector2(-6, 0),
        Vector2(5, 0), Vector2(-5, 0), Vector2(5, 0), Vector2(-4, 0),
        Vector2(4, 0), Vector2(-4, 0)
    ],
    "brawler": [
        Vector2(0, -18), Vector2(2, -16), Vector2(-3, -14), Vector2(4, -10),
        Vector2(-5, -6), Vector2(5, -3), Vector2(-4, 0)
    ],
    "shield": [
        Vector2(0, -20), Vector2(2, -16), Vector2(-3, -12), Vector2(4, -8),
        Vector2(-5, -4), Vector2(5, -2), Vector2(-4, 0), Vector2(4, 0)
    ],
    "scatter": [
        Vector2(3, -28), Vector2(-4, -24), Vector2(6, -18), Vector2(-7, -12),
        Vector2(8, -8), Vector2(-6, -4), Vector2(5, 0)
    ],
    "bomb": [
        Vector2(5, -34), Vector2(-6, -22)
    ],
    "rail": [
        Vector2(1, -30), Vector2(0, -8), Vector2(-1, -6), Vector2(1, -5), Vector2(0, -4)
    ],
    "mortar": [
        Vector2(2, -26)
    ],
}

const SPRAY_RECOVER := {
    "spear": 10.0, "chain": 12.0, "leech": 16.0, "blade": 14.0, "breaker": 8.0,
    "burst": 15.0, "brawler": 14.0, "shield": 9.0, "scatter": 7.0, "bomb": 7.0,
    "rail": 6.0, "mortar": 6.0,
}

static func feel_for_equipment(equipment_id: String) -> Dictionary:
    if GUN_FEEL.has(equipment_id):
        return GUN_FEEL[equipment_id]
    return GUN_FEEL["burst"]

static func equipment_for_animal(slot: int) -> String:
    return str(ANIMAL_SIGNATURE_EQUIPMENT[posmod(slot, 12)])


static func visual_for_equipment(equipment_id: String) -> Dictionary:
    if EQUIP_VISUAL.has(equipment_id):
        return EQUIP_VISUAL[equipment_id]
    return EQUIP_VISUAL["burst"]


static func is_signature(slot: int, equipment_id: String) -> bool:
    return equipment_for_animal(slot) == equipment_id


static func family_of(equipment_id: String) -> String:
    return str(visual_for_equipment(equipment_id).get("family", "rifle"))

const GUN_FX := {
    "brawler": {"row": 0, "frames": 2, "scale": 1.0, "shake": 3},
    "burst": {"row": 0, "frames": 2, "scale": 1.0, "shake": 2},
    "leech": {"row": 1, "frames": 3, "scale": 1.0, "shake": 3},
    "blade": {"row": 1, "frames": 3, "scale": 1.0, "shake": 3},
    "chain": {"row": 1, "frames": 3, "scale": 1.0, "shake": 4},
    "spear": {"row": 1, "frames": 3, "scale": 1.28, "shake": 5},
    "shield": {"row": 1, "frames": 3, "scale": 1.0, "shake": 4},
    "scatter": {"row": 1, "frames": 3, "scale": 1.0, "shake": 10},
    "breaker": {"row": 2, "frames": 4, "scale": 1.0, "shake": 6},
    "bomb": {"row": 2, "frames": 4, "scale": 1.12, "shake": 14},
    "rail": {"row": 2, "frames": 4, "scale": 1.1, "shake": 14},
    "mortar": {"row": 2, "frames": 4, "scale": 1.1, "shake": 11},
}

static func fx_for_equipment(equipment_id: String) -> Dictionary:
    if GUN_FX.has(equipment_id):
        return GUN_FX[equipment_id]
    return GUN_FX["burst"]

static func spray_kick(equipment_id: String, index: int) -> Vector2:
    var table: Array = SPRAY_KICK["burst"]
    if SPRAY_KICK.has(equipment_id):
        table = SPRAY_KICK[equipment_id]
    if index < 0 or table.is_empty():
        return Vector2.ZERO
    if index >= table.size():
        return table[table.size() - 1]
    return table[index]

static func spray_step(equipment_id: String, index: int) -> Vector2:
    var acc := Vector2.ZERO
    var last := maxi(0, index)
    for i in range(last + 1):
        acc += spray_kick(equipment_id, i)
    return acc

static func spray_recover_rate(equipment_id: String) -> float:
    if SPRAY_RECOVER.has(equipment_id):
        return float(SPRAY_RECOVER[equipment_id])
    return 12.0



const GUN_TSCN_SCALE := 0.645
const MUZZLE_FLASH_LOCAL := Vector2(49.536, 0.0)
const GUN_CELL_W := 256.0

static func gun_world_scale() -> float:
    return 72.0 / (GUN_CELL_W * GUN_TSCN_SCALE)

static func gun_mount_pos(body_pos: Vector2, aim: Vector2, kick: float = 0.0) -> Vector2:
    var dir := aim.normalized() if aim.length_squared() > 0.0001 else Vector2.RIGHT
    var flip := -1.0 if dir.x < 0.0 else 1.0
    return body_pos + Vector2(flip * 6.0, 4.0) + dir * (18.0 - kick)

static func _aim_dir(aim: Vector2) -> Vector2:
    return aim.normalized() if aim.length_squared() > 0.0001 else Vector2.RIGHT

static func _local_to_world(mount: Vector2, aim: Vector2, local: Vector2) -> Vector2:
    var dir := _aim_dir(aim)
    var flip := -1.0 if dir.x < 0.0 else 1.0
    var angle := dir.angle()
    var world_s := gun_world_scale()
    var scaled := Vector2(local.x * world_s, local.y * world_s * flip)
    return mount + Vector2(cos(angle), sin(angle)) * scaled.x + Vector2(-sin(angle), cos(angle)) * scaled.y

static func muzzle_world_pos(body_pos: Vector2, aim: Vector2, equipment_id: String, kick: float = 0.0) -> Vector2:
    var vis: Dictionary = visual_for_equipment(equipment_id)
    var mount := gun_mount_pos(body_pos, aim, kick)
    var socket := Vector2(float(vis.get("mx", 90.0)), float(vis.get("my", -18.0)))
    return _local_to_world(mount, aim, socket)
