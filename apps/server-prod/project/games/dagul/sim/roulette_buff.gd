class_name RouletteBuff
extends RefCounted

var w

func _init(world) -> void:
    w = world

func hero_has_timed(h: Dictionary, buff_id: String) -> bool:
    for buff in h.get("rl_timed", []):
        if str(buff.get("id", "")) == buff_id:
            return true
    return false

func roulette_stat(slot: int, key: String) -> float:
    if slot < 0 or slot >= w.heroes.size():
        return 0.0
    var h: Dictionary = w.heroes[slot]
    var total := float(h.get("rl_until", {}).get(key, 0.0))
    for buff in h.get("rl_timed", []):
        total += float(buff.get(key, 0.0))
    return total

func roulette_faces(rank: String, timed_group: bool) -> Array:
    if rank == "assist":
        return _roulette_faces_assist(timed_group)
    if rank == "wanted":
        return _roulette_faces_wanted(timed_group)
    if timed_group:
        return _roulette_faces_kill_timed()
    return _roulette_faces_kill_until()

func _roulette_faces_assist(timed_group: bool) -> Array:
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

func _roulette_faces_wanted(timed_group: bool) -> Array:
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

func _roulette_faces_kill_timed() -> Array:
    return [
        {"id":"giant", "name":"GIANT", "kind":"timed", "atk":3.0, "spd":5.0, "def":0.0, "hp":3.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":12.0},
        {"id":"shield", "name":"SHIELD", "kind":"timed", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":40.0, "dur":3.0},
        {"id":"berserk", "name":"BERSERK", "kind":"timed", "atk":3.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.07, "range":0.0, "shield":0.0, "dur":8.0},
        {"id":"sniper", "name":"SNIPER", "kind":"timed", "atk":3.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.08, "shield":0.0, "dur":9.0}
    ]

func _roulette_faces_kill_until() -> Array:
    return [
        {"id":"atk", "name":"ATK +3", "kind":"until", "atk":3.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
        {"id":"spd", "name":"SPD +4", "kind":"until", "atk":0.0, "spd":4.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
        {"id":"def", "name":"DEF +6%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.06, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
        {"id":"hp", "name":"HP +14", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":14.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":0.0},
        {"id":"rate", "name":"RATE +7%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.07, "range":0.0, "shield":0.0, "dur":0.0},
        {"id":"range", "name":"RANGE +8%", "kind":"until", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.08, "shield":0.0, "dur":0.0}
    ]

func roulette_b_chance(rank: String) -> float:
    if rank == "assist":
        return 0.25
    if rank == "wanted":
        return 0.55
    return 0.40

func pick_roulette_face(rank: String) -> Dictionary:
    if w.rng.rangef(0.0, 1.0) < 0.03:
        return {"id":"turtle", "name":"TURTLE", "kind":"timed", "atk":0.0, "spd":0.0, "def":0.0, "hp":0.0, "rate":0.0, "range":0.0, "shield":0.0, "dur":2.0}
    var timed_group: bool = w.rng.rangef(0.0, 1.0) < roulette_b_chance(rank)
    var faces: Array = roulette_faces(rank, timed_group)
    return faces[w.rng.rangei(0, faces.size() - 1)]

func roulette_face_list(rank: String) -> Array:
    var faces: Array = []
    for face in roulette_faces(rank, false):
        faces.append({"id":str(face["id"]), "name":str(face["name"])})
    for face in roulette_faces(rank, true):
        faces.append({"id":str(face["id"]), "name":str(face["name"])})
    faces.append({"id":"turtle", "name":"TURTLE"})
    return faces

func clear_roulette_buffs(h: Dictionary) -> void:
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

func apply_roulette_face(slot: int, face: Dictionary) -> void:
    if slot < 0 or slot >= w.heroes.size() or not bool(w.heroes[slot]["alive"]):
        return
    var h: Dictionary = w.heroes[slot]
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
    w.heroes[slot] = h
    w.proj.add_effect(&"heal_pickup", Vector2(h["pos"]), 72.0, 0.50, roulette_rank_color(str(h.get("roulette_rank", "kill"))), str(face.get("name", "")))
    w.event_log.emit(w.tick, &"kill_roulette", slot, -1, {"label":str(face.get("name", "")), "rank":str(h.get("roulette_rank", "")), "kind":str(face.get("kind", ""))})

func roulette_face_desc(face: Dictionary) -> String:
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

func roulette_rank_color(rank: String) -> Color:
    if rank == "assist":
        return Color("#4da3ff")
    if rank == "wanted":
        return Color("#ff3349")
    return Color("#b84dff")

func begin_next_roulette(slot: int) -> void:
    var h: Dictionary = w.heroes[slot]
    var queue: Array = h.get("roulette_queue", [])
    if queue.is_empty() or not bool(h["alive"]):
        h["roulette_phase"] = ""
        h["roulette_time"] = 0.0
        h["roulette_pending"] = {}
        w.heroes[slot] = h
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
    h["roulette_faces"] = roulette_face_list(rank)
    h["roulette_spin_id"] = ""
    w.heroes[slot] = h
    w._announce("KILL BONUS!", 50)

func queue_roulette(slot: int, rank: String) -> void:
    if slot < 0 or slot >= w.heroes.size() or not bool(w.heroes[slot]["alive"]):
        return
    var h: Dictionary = w.heroes[slot]
    var queue: Array = h.get("roulette_queue", [])
    queue.append({"rank":rank, "face":pick_roulette_face(rank)})
    h["roulette_queue"] = queue
    w.heroes[slot] = h
    if str(h.get("roulette_phase", "")) == "":
        begin_next_roulette(slot)

func grant_kill_roulettes(owner: int, target: int, bounty_kill: bool, hits: Dictionary) -> void:
    if owner >= 0 and owner < w.heroes.size() and owner != target and bool(w.heroes[owner]["alive"]):
        queue_roulette(owner, "wanted" if bounty_kill else "kill")
    for assist_slot in w.lifecycle.assist_slots(owner, target, hits):
        queue_roulette(int(assist_slot), "assist")

func expire_timed_buff(h: Dictionary, buff: Dictionary) -> void:
    var hp_drop := float(buff.get("hp", 0.0))
    if hp_drop > 0.0:
        h["max_hp"] = maxf(float(h["equipment"]["max_hp"]), float(h["max_hp"]) - hp_drop)
        h["hp"] = minf(float(h["hp"]), float(h["max_hp"]))

func tick_roulette(slot: int, dt: float) -> void:
    var h: Dictionary = w.heroes[slot]
    var timed_keep: Array = []
    for buff in h.get("rl_timed", []):
        var left := maxf(0.0, float(buff.get("time", 0.0)) - dt)
        if left <= 0.0:
            expire_timed_buff(h, buff)
            continue
        buff["time"] = left
        timed_keep.append(buff)
    h["rl_timed"] = timed_keep
    var phase := str(h.get("roulette_phase", ""))
    if phase == "":
        w.heroes[slot] = h
        return
    h["roulette_time"] = maxf(0.0, float(h.get("roulette_time", 0.0)) - dt)
    if phase == "bonus":
        h["roulette_label"] = "KILL BONUS!"
        if float(h["roulette_time"]) <= 0.0:
            h["roulette_phase"] = "spin"
            h["roulette_time"] = 0.9
            h["roulette_spin_dur"] = 0.9
    elif phase == "spin":
        h = _tick_spin_phase(slot, h)
    elif phase == "land":
        if float(h["roulette_time"]) <= 0.0:
            w.heroes[slot] = h
            begin_next_roulette(slot)
            return
    w.heroes[slot] = h

func _tick_spin_phase(slot: int, h: Dictionary) -> Dictionary:
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
        w.heroes[slot] = h
        apply_roulette_face(slot, face)
        h = w.heroes[slot]
        h["roulette_phase"] = "land"
        h["roulette_time"] = 2.40
        h["roulette_label"] = str(face.get("name", ""))
        h["roulette_spin_id"] = str(face.get("id", ""))
        h["roulette_desc"] = roulette_face_desc(face)
        h["roulette_pending"] = {}
    return h

func absorb_roulette_shield(h: Dictionary, amount: float) -> float:
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
