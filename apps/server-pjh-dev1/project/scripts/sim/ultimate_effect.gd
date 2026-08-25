class_name UltimateEffect
extends RefCounted

var w

func _init(world) -> void:
    w = world

func cancel_finish_cine() -> void:
    w.finish_cine = {}

func try_begin_finish(slot: int) -> void:
    if bool(w.finish_cine.get("on", false)):
        return
    if slot < 0 or slot >= w.heroes.size():
        return
    var me: Dictionary = w.heroes[slot]
    if not bool(me.get("alive", false)) or bool(me.get("downed", false)):
        return
    var best := -1
    var best_d := 280.0
    for t in range(w.heroes.size()):
        if t == slot:
            continue
        var vic: Dictionary = w.heroes[t]
        if not bool(vic.get("downed", false)) or not bool(vic.get("alive", false)):
            continue
        var d: float = Vector2(me["pos"]).distance_to(Vector2(vic["pos"]))
        if d < best_d:
            best_d = d
            best = t
    if best < 0:
        return
    w.finish_cine = {
        "on": true,
        "atk": slot,
        "vic": best,
        "t": 0.0,
        "hit": false,
        "fly": 0.0,
        "vic_x": 0.0,
        "vic_y": 0.0,
        "vic_spin": 0.0,
        "atk_x": 0.0,
        "rush": false,
        "mid": (Vector2(me["pos"]) + Vector2(w.heroes[best]["pos"])) * 0.5
    }
    w.event_log.emit(w.tick, &"finish_start", slot, best, {})

func tick_finish_cine(command: Dictionary, dt: float) -> void:
    if not bool(w.finish_cine.get("on", false)):
        return
    var atk := int(w.finish_cine.get("atk", 0))
    var vic := int(w.finish_cine.get("vic", -1))
    if vic < 0 or vic >= w.heroes.size() or atk < 0 or atk >= w.heroes.size():
        w.finish_cine = {}
        return
    var vh: Dictionary = w.heroes[vic]
    if not bool(vh.get("downed", false)) or not bool(vh.get("alive", false)):
        cancel_finish_cine()
        return
    var ah: Dictionary = w.heroes[atk]
    if not bool(ah.get("alive", false)) or bool(ah.get("eliminated", false)):
        cancel_finish_cine()
        return
    ah["vel"] = Vector2.ZERO
    w.heroes[atk] = ah
    vh["down_left"] = maxf(0.12, float(vh.get("down_left", 0.0)))
    w.heroes[vic] = vh
    w.finish_cine["t"] = float(w.finish_cine.get("t", 0.0)) + dt
    if bool(command.get("finish", false)) and float(w.finish_cine.get("t", 0.0)) > 0.12:
        cancel_finish_cine()
        return
    if bool(w.finish_cine.get("hit", false)):
        w.finish_cine["fly"] = float(w.finish_cine.get("fly", 0.0)) + dt
        w.finish_cine["vic_x"] = float(w.finish_cine.get("vic_x", 0.0)) + 1450.0 * dt
        w.finish_cine["vic_y"] = float(w.finish_cine.get("vic_y", 0.0)) - 420.0 * dt
        w.finish_cine["vic_spin"] = float(w.finish_cine.get("vic_spin", 0.0)) + 18.0 * dt
        if float(w.finish_cine["fly"]) >= 0.95:
            w.finish_cine = {}
            w.lifecycle.down_hero(atk, vic)
        return
    if float(w.finish_cine.get("t", 0.0)) >= 0.35:
        w.finish_cine["rush"] = true
    if bool(w.finish_cine.get("rush", false)):
        w.finish_cine["atk_x"] = float(w.finish_cine.get("atk_x", 0.0)) + 980.0 * dt
        if float(w.finish_cine.get("atk_x", 0.0)) >= 220.0:
            w.finish_cine["rush"] = false
            w.finish_cine["hit"] = true
            w.finish_cine["fly"] = 0.0

func wool_shield_pos(h: Dictionary) -> Vector2:
    return Vector2(h["pos"])

func begin_wool_shield(slot: int) -> void:
    var h: Dictionary = w.heroes[slot]
    h["wool_time"] = 5.0
    h["wool_hp"] = 5
    h["wool_max"] = 5
    w.heroes[slot] = h
    w.ult_animal.set_ultimate_focus(slot, 0.16)
    w.event_log.emit(w.tick, &"ultimate_used", slot, -1, {"id": "wool_shield"})

func tick_wool_shields(dt: float) -> void:
    for slot in range(w.heroes.size()):
        var h: Dictionary = w.heroes[slot]
        if float(h.get("wool_time", 0.0)) <= 0.0:
            continue
        if not bool(h.get("alive", false)) or bool(h.get("downed", false)):
            h["wool_time"] = 0.0
            h["wool_hp"] = 0
            w.heroes[slot] = h
            continue
        h["wool_time"] = float(h["wool_time"]) - dt
        if float(h["wool_time"]) <= 0.0:
            h["wool_time"] = 0.0
            h["wool_hp"] = 0
        w.heroes[slot] = h

func absorb_wool_shield(owner: int, target: int, pos: Vector2, radius: float) -> bool:
    if target < 0 or target >= w.heroes.size():
        return false
    if owner == target:
        return false
    var h: Dictionary = w.heroes[target]
    if float(h.get("wool_time", 0.0)) <= 0.0 or int(h.get("wool_hp", 0)) <= 0:
        return false
    if not bool(h.get("alive", false)):
        return false
    var shield: Vector2 = wool_shield_pos(h)
    if pos.distance_to(shield) > radius + 58.0:
        return false
    h["wool_hp"] = int(h.get("wool_hp", 0)) - 1
    w.proj.add_effect(&"impact", shield, 36.0, 0.18, Color("#fff6d8"), "")
    if int(h["wool_hp"]) <= 0:
        h["wool_time"] = 0.0
        w.heroes[target] = h
        pop_wool_shield(target)
        return true
    w.heroes[target] = h
    return true

func pop_wool_shield(slot: int) -> void:
    var h: Dictionary = w.heroes[slot]
    var center: Vector2 = wool_shield_pos(h)
    w.proj.add_effect(&"sheep_pop", center, 150.0, 0.36, Color("#fff1c8"), "")
    for t in range(w.heroes.size()):
        if t == slot:
            continue
        var vic: Dictionary = w.heroes[t]
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
        vic["pos"] = w.arena.resolve_cover_motion(Vector2(vic["pos"]), dir * 70.0)
        w.heroes[t] = vic

func sync_ult_clones(dt: float) -> void:
    for slot in range(w.heroes.size()):
        var h: Dictionary = w.heroes[slot]
        var left := float(h.get("ult_clone_time", 0.0))
        if left <= 0.0:
            if h.get("ult_clones", []):
                h["ult_clones"] = []
                w.heroes[slot] = h
            continue
        left = maxf(0.0, left - dt)
        h["ult_clone_time"] = left
        if left <= 0.0 or not bool(h.get("alive", false)) or bool(h.get("downed", false)):
            h["ult_clones"] = []
            w.heroes[slot] = h
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
            var next_pos: Vector2 = w.arena.resolve_cover_motion(Vector2(clone.get("pos", h["pos"])), mirrored * dt)
            next_pos = w.arena.clamp_arena_point(next_pos, w.HERO_RADIUS)
            clone["pos"] = next_pos
            clone["facing"] = facing.rotated(ang)
            clone["aim"] = aim.rotated(ang)
            clone["hop_time"] = h.get("hop_time", 0.0)
            clone["hop_height"] = h.get("hop_height", w.HOP_LIFT_DEFAULT)
            clone["animal"] = int(h.get("animal", slot))
            clone["owner"] = slot
            kept.append(clone)
        h["ult_clones"] = kept
        w.heroes[slot] = h

func pop_ult_clone(slot: int, index: int) -> void:
    if slot < 0 or slot >= w.heroes.size():
        return
    var h: Dictionary = w.heroes[slot]
    var clones: Array = h.get("ult_clones", [])
    if index < 0 or index >= clones.size():
        return
    var c: Dictionary = clones[index]
    var pos: Vector2 = c.get("pos", h.get("pos", Vector2.ZERO))
    clones.remove_at(index)
    h["ult_clones"] = clones
    w.heroes[slot] = h
    w.proj.add_effect(&"monkey_pop", pos, 54.0, 0.28, Color("#c9e7ff"), "")
    w.event_log.emit(w.tick, &"clone_pop", slot, -1, {})

func hit_ult_clone(owner: int, ppos: Vector2, radius: float) -> bool:
    for slot in range(w.heroes.size()):
        if slot == owner:
            continue
        var h: Dictionary = w.heroes[slot]
        if float(h.get("ult_clone_time", 0.0)) <= 0.0:
            continue
        var clones: Array = h.get("ult_clones", [])
        for i in range(clones.size()):
            var c: Dictionary = clones[i]
            if not bool(c.get("alive", true)):
                continue
            if ppos.distance_to(Vector2(c.get("pos", Vector2.ZERO))) < radius + w.HERO_RADIUS:
                pop_ult_clone(slot, i)
                return true
    return false

func ultimate_armor(_equipment_id: String) -> Dictionary:
    return {"duration":0.0, "strength":0.0}
