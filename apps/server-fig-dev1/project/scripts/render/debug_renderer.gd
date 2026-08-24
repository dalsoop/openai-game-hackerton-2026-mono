extends Node2D

const GunSig = preload("res://scripts/sim/gun_signature.gd")

var world
var colors := [Color.WHITE, Color("#5bc0eb"), Color("#9bc53d"), Color("#e55934"), Color("#fa7921"), Color("#b084cc"), Color("#ffe066"), Color("#70e7ff"), Color("#ff8dac"), Color("#c9f24d"), Color("#7ad7f0"), Color("#e8a87c")]

func _slot_color(index: int) -> Color:
    return colors[posmod(index, colors.size())]

const ZODIAC_NAMES := ["쥐", "소", "호랑이", "토끼", "용", "뱀", "말", "양", "원숭이", "닭", "개", "돼지"]
const ZONE_RING := Color("#b44dff")
const ZONE_RING_HOT := Color("#e05cff")
const BULLET_YELLOW := Color("#ffd23f")

var zodiac_textures: Array = []
var island_texture: Texture2D = null
var tower_texture: Texture2D = null
var rat_run_tex: Texture2D = null
var dragon_smoke_tex: Texture2D = null
var flee_icon_tex: Texture2D = null
var rabbit_hole_tex: Texture2D = null
var pig_mud_tex: Texture2D = null
var dog_bone_tex: Texture2D = null
var wool_shield_tex: Texture2D = null
var finish_bg_tex: Texture2D = null
var finish_glove_tex: Texture2D = null
var roar_shader: Shader = null
var roar_fx: Array = []
var stun_spin_tex: Texture2D = null
var gun_texture: Texture2D = null
var medkit_texture: Texture2D = null
var animal_atlas: Texture2D = null
var bullet_atlas: Texture2D = null
var gun_atlas: Texture2D = null
var muzzle_atlas: Texture2D = null
var impact_atlas: Texture2D = null
var impact_flashes: Array = []
var combat_texts: Array = []
var roulette_icons: Dictionary = {}
var turtle_body_tex: Texture2D = null
var roulette_wheel_tex: Texture2D = null
var roulette_wheel_rank: Dictionary = {}
var lite_draw := false
var last_shot_event_id := 0
var recoil_kick: Array = []
var recoil_rot: Array = []
var recoil_body: Array = []
var recoil_strap: Array = []
var recoil_decay: Array = []
var muzzle_life: Array = []
var rooster_comb_lag: float = 0.0

# lhj 4x3 atlas frames: Rat Ox Tiger Rabbit Snake Dragon Horse Goat Monkey Rooster Dog Pig
# dagul slots:            쥐  소 호랑이  토끼   용    뱀    말   양   원숭이   닭    개  돼지
const ANIMAL_ATLAS_FRAME := [0, 1, 2, 3, 5, 4, 6, 7, 8, 9, 10, 11]
const ANIMAL_COLS := 4
const ANIMAL_ROWS := 3
const BULLET_COLS := 4
const BULLET_ROWS := 4


func _process(_dt: float) -> void:
    _sync_roar_fx()

func _sync_roar_fx() -> void:
    if world == null:
        return
    var roars: Array = world.tiger_roars
    while roar_fx.size() < roars.size():
        var rect := ColorRect.new()
        rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        rect.size = Vector2(1160, 1160)
        rect.pivot_offset = rect.size * 0.5
        if roar_shader != null:
            var mat := ShaderMaterial.new()
            mat.shader = roar_shader
            rect.material = mat
        add_child(rect)
        roar_fx.append(rect)
    for i in range(roar_fx.size()):
        var node: ColorRect = roar_fx[i]
        if i >= roars.size():
            node.visible = false
            continue
        var roar: Dictionary = roars[i]
        var life := maxf(0.01, float(roar.get("life", 1.15)))
        var progress := clampf(float(roar.get("age", 0.0)) / life, 0.0, 1.0)
        var pos: Vector2 = roar.get("pos", Vector2.ZERO)
        node.visible = true
        var rad := float(roar.get("radius", 300.0))
        node.size = Vector2(rad * 2.0 + 80.0, rad * 2.0 + 80.0)
        node.pivot_offset = node.size * 0.5
        node.position = pos - node.size * 0.5
        node.z_index = 40
        var mat2 = node.material
        if mat2 is ShaderMaterial:
            mat2.set_shader_parameter("progress", progress)
            mat2.set_shader_parameter("strength", 0.10)

func _ready() -> void:
    lite_draw = OS.has_feature("web")
    if lite_draw:
        RenderingServer.viewport_set_msaa_2d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_DISABLED)
    for index in range(12):
        zodiac_textures.append(_load_tex("res://assets/sprites/zodiac_%02d.png" % (index + 1)))
    island_texture = _load_tex("res://assets/world/island_bg.png")
    tower_texture = _load_tex("res://assets/world/bounty-tower.png")
    rat_run_tex = _load_tex("res://assets/fx/rat-run.png")
    dragon_smoke_tex = _load_tex("res://assets/fx/dragon-smoke.png")
    flee_icon_tex = _load_tex("res://assets/fx/flee-icon.png")
    rabbit_hole_tex = _load_tex("res://assets/fx/rabbit-hole.png")
    pig_mud_tex = _load_tex("res://assets/fx/pig-mud.png")
    dog_bone_tex = _load_tex("res://assets/fx/dog-bone.png")
    wool_shield_tex = _load_tex("res://assets/fx/sheep-wool-ring.png")
    finish_bg_tex = _load_tex("res://assets/fx/finish-bg.png")
    finish_glove_tex = _load_tex("res://assets/fx/finish-glove.png")
    roar_shader = load("res://assets/fx/roar_distort.gdshader") as Shader
    stun_spin_tex = _load_tex("res://assets/fx/stun-spin.png")
    gun_texture = _load_tex("res://assets/items/gun.png")
    medkit_texture = _load_tex("res://assets/items/medkit.png")
    animal_atlas = _load_tex("res://assets/lhj/Tex_Animal_4x3.png")
    bullet_atlas = _load_tex("res://assets/lhj/Tex_FX_Bullet_4x4_256x144.png")
    gun_atlas = _load_tex("res://assets/lhj/Tex_Gun_4x3.png")
    muzzle_atlas = _load_tex("res://assets/lhj/Tex_Fx_MuzzleFlash_4x3.png")
    impact_atlas = _load_tex("res://assets/lhj/Tex_Fx_ImpactFlash.png")
    for icon_id in ["atk", "spd", "def", "hp", "rate", "range", "giant", "shield", "berserk", "turtle", "sniper", "double_giant"]:
        var icon_tex := _load_tex("res://assets/hud/roulette/%s.png" % icon_id)
        if icon_tex != null:
            roulette_icons[icon_id] = icon_tex
    turtle_body_tex = _load_tex("res://assets/hud/roulette/turtle_body.png")
    roulette_wheel_tex = _load_tex("res://assets/hud/roulette/wheel.png")
    roulette_wheel_rank["assist"] = _load_tex("res://assets/hud/roulette/wheel_assist.png")
    roulette_wheel_rank["kill"] = _load_tex("res://assets/hud/roulette/wheel_kill.png")
    roulette_wheel_rank["wanted"] = _load_tex("res://assets/hud/roulette/wheel_wanted.png")
    if roulette_wheel_rank.get("kill", null) == null:
        roulette_wheel_rank["kill"] = roulette_wheel_tex
    _reset_recoil_state()

func _load_tex(path: String) -> Texture2D:
    if ResourceLoader.exists(path):
        var res = load(path)
        if res is Texture2D:
            return res
    var img := Image.new()
    var err := img.load(ProjectSettings.globalize_path(path))
    if err != OK:
        err = img.load(path)
    if err == OK and img.get_width() > 0:
        return ImageTexture.create_from_image(img)
    return null

func _reset_recoil_state() -> void:
    recoil_kick.clear()
    recoil_rot.clear()
    recoil_body.clear()
    recoil_strap.clear()
    recoil_decay.clear()
    muzzle_life.clear()
    for i in range(12):
        recoil_kick.append(0.0)
        recoil_rot.append(0.0)
        recoil_body.append(0.0)
        recoil_strap.append(0.0)
        recoil_decay.append(10.0)
        muzzle_life.append(0.0)
    last_shot_event_id = 0


func _gun_src_rect(frame: int) -> Rect2:
    var cell: Vector2 = Vector2(float(gun_atlas.get_width()) / 4.0, float(gun_atlas.get_height()) / 3.0)
    var col := posmod(frame, 4)
    var row := int(frame / 4)
    return Rect2(Vector2(float(col), float(row)) * cell, cell)


func _muzzle_src_rect(row: int, col: int) -> Rect2:
    var cell: Vector2 = Vector2(float(muzzle_atlas.get_width()) / 4.0, float(muzzle_atlas.get_height()) / 3.0)
    return Rect2(Vector2(float(posmod(col, 4)), float(posmod(row, 3))) * cell, cell)

func _impact_src_rect(row: int, col: int) -> Rect2:
    if impact_atlas == null:
        return Rect2()
    var cell: Vector2 = Vector2(float(impact_atlas.get_width()) / 4.0, float(impact_atlas.get_height()) / 3.0)
    return Rect2(Vector2(float(posmod(col, 4)), float(posmod(row, 3))) * cell, cell)


func _consume_shot_events() -> void:
    if world == null or world.event_log == null:
        return
    if int(world.event_log.next_id) <= last_shot_event_id:
        last_shot_event_id = 0
    for event in world.event_log.events:
        var eid := int(event.get("event_id", 0))
        if eid <= last_shot_event_id:
            continue
        last_shot_event_id = maxi(last_shot_event_id, eid)
        var et := StringName(event.get("type", &""))
        if et == &"gun_fire" or et == &"normal_combo_step":
            var slot := int(event.get("actor_id", -1))
            if slot >= 0 and slot < recoil_kick.size():
                _apply_shot_recoil(slot)
        elif et == &"tower_hit":
            var td: Dictionary = event.get("data", {})
            var tdmg := float(td.get("damage", 0.0))
            if tdmg > 0.4 and world.mid_tower:
                _push_combat_text(Vector2(world.mid_tower.get("pos", Vector2.ZERO)), "%d" % roundi(tdmg), Color("#ffd36a"))
        elif et == &"snake_shed_hit":
            var sdata: Dictionary = event.get("data", {})
            var sdmg := float(sdata.get("damage", 0.0))
            var spos = sdata.get("pos", null)
            if typeof(spos) == TYPE_VECTOR2 and sdmg > 0.4:
                _push_combat_text(spos, "%d" % roundi(sdmg), Color("#b6e37a"))
        elif et == &"crate_hit":
            var cdata: Dictionary = event.get("data", {})
            var cdmg := float(cdata.get("damage", 0.0))
            var cpos = cdata.get("pos", null)
            if typeof(cpos) != TYPE_VECTOR2:
                var ci := int(cdata.get("crate", -1))
                if ci >= 0 and ci < world.crates.size():
                    cpos = Vector2(world.crates[ci]["pos"])
            if typeof(cpos) == TYPE_VECTOR2 and cdmg > 0.4:
                _push_combat_text(cpos, "%d" % roundi(cdmg), Color("#ffd36a"))
        elif et == &"hero_heal":
            var hslot := int(event.get("actor_id", -1))
            var hdata: Dictionary = event.get("data", {})
            var heal_n := float(hdata.get("amount", 0.0))
            if hslot >= 0 and hslot < world.heroes.size() and heal_n > 0.4:
                _push_combat_text(Vector2(world.heroes[hslot]["pos"]), "+%d" % roundi(heal_n), Color("#7dff9a"))
        elif et == &"hero_hit":
            var data: Dictionary = event.get("data", {})
            if StringName(data.get("source", &"")) == &"safe_zone":
                continue
            var tpos = event.get("pos", null)
            var target := int(event.get("target_id", -1))
            var hit_pos := Vector2.ZERO
            if typeof(tpos) == TYPE_VECTOR2:
                hit_pos = tpos
            elif target >= 0 and target < world.heroes.size():
                hit_pos = Vector2(world.heroes[target]["pos"])
            else:
                continue
            var owner := int(event.get("actor_id", -1))
            var row := 1
            var hid := "burst"
            if owner >= 0 and owner < world.heroes.size():
                var held = world.heroes[owner].get("equipment", {})
                if typeof(held) == TYPE_DICTIONARY:
                    hid = str(held.get("id", "burst"))
                var fam := GunSig.family_of(hid)
                if fam == "pistol":
                    row = 0
                elif fam == "shotgun" or fam == "heavy":
                    row = 2
            var delay := 0.0
            if hid == "rail":
                delay = -0.10
            impact_flashes.append({"pos": hit_pos, "row": row, "time": delay})
            var dmg_n := float(data.get("damage", 0.0))
            if StringName(data.get("source", &"")) != &"safe_zone" and dmg_n > 0.4:
                _push_combat_text(hit_pos, "%d" % roundi(dmg_n), Color("#ffd36a"))


func feel_muzzle_max(row: int) -> float:
    var counts := [2, 3, 4]
    return float(counts[clampi(row, 0, 2)]) * 0.055

func _apply_shot_recoil(slot: int) -> void:
    var equip_id := "burst"
    if slot < world.heroes.size():
        var held = world.heroes[slot].get("equipment", {})
        if typeof(held) == TYPE_DICTIONARY:
            equip_id = str(held.get("id", "burst"))
    var feel: Dictionary = GunSig.feel_for_equipment(equip_id)
    recoil_kick[slot] = float(feel.get("kick", 4.2))
    recoil_rot[slot] = float(feel.get("rot", 0.045))
    recoil_body[slot] = float(feel.get("body", 0.05))
    recoil_strap[slot] = float(feel.get("strap", 1.4))
    recoil_decay[slot] = float(feel.get("decay", 22.0))
    var mrow := 0
    var vis0: Dictionary = GunSig.visual_for_equipment(equip_id)
    mrow = int(vis0.get("muzzle_row", 0))
    muzzle_life[slot] = feel_muzzle_max(mrow)
    if posmod(slot, 12) == 9:
        rooster_comb_lag = 1.0


func _tick_recoil(dt: float) -> void:
    for slot in range(recoil_kick.size()):
        var decay := float(recoil_decay[slot])
        var factor: float = exp(-decay * dt)
        recoil_kick[slot] = float(recoil_kick[slot]) * factor
        recoil_rot[slot] = float(recoil_rot[slot]) * factor
        recoil_body[slot] = float(recoil_body[slot]) * factor
        recoil_strap[slot] = float(recoil_strap[slot]) * factor
        muzzle_life[slot] = maxf(0.0, float(muzzle_life[slot]) - dt)
    if rooster_comb_lag > 0.0:
        rooster_comb_lag = maxf(0.0, rooster_comb_lag - 1.0)
    var keep: Array = []
    for flash in impact_flashes:
        flash["time"] = float(flash.get("time", 0.0)) + dt
        var row := int(flash.get("row", 1))
        var counts := [2, 3, 4]
        var n: int = int(counts[clampi(row, 0, 2)])
        if float(flash["time"]) < float(n) * 0.055:
            keep.append(flash)
    impact_flashes = keep


func _zodiac_texture(slot: int) -> Texture2D:
    if zodiac_textures.is_empty():
        return null
    return zodiac_textures[posmod(slot, 12)]


func _animal_src_rect(slot: int) -> Rect2:
    var frame := int(ANIMAL_ATLAS_FRAME[posmod(slot, 12)])
    var cell := Vector2(float(animal_atlas.get_width()) / float(ANIMAL_COLS), float(animal_atlas.get_height()) / float(ANIMAL_ROWS))
    var col := frame % ANIMAL_COLS
    var row := int(frame / ANIMAL_COLS)
    return Rect2(Vector2(float(col), float(row)) * cell, cell)


func _bullet_src_rect(kind: String, tick: int) -> Rect2:
    var row := 1
    match kind:
        "pellet":
            row = 0
        "burst", "bolt":
            row = 1
        "shell":
            row = 2
        "seeker":
            row = 3
        _:
            row = 1
    var col := posmod(tick / 3, BULLET_COLS)
    var cell := Vector2(float(bullet_atlas.get_width()) / float(BULLET_COLS), float(bullet_atlas.get_height()) / float(BULLET_ROWS))
    return Rect2(Vector2(float(col), float(row)) * cell, cell)


func _draw_lhj_bullet(projectile_pos: Vector2, direction: Vector2, kind: String, scale: float = 1.0) -> void:
    if bullet_atlas == null:
        return
    var dir := direction if direction.length_squared() > 0.0001 else Vector2.RIGHT
    var src := _bullet_src_rect(kind, int(world.tick))
    var dest := Rect2(Vector2(-28.0, -10.0) * scale, Vector2(56.0, 20.0) * scale)
    draw_set_transform(projectile_pos, dir.angle(), Vector2.ONE)
    draw_texture_rect_region(bullet_atlas, dest, src)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _zodiac_name(slot: int) -> String:
    return ZODIAC_NAMES[posmod(slot, 12)]

func _projectile_color(projectile: Dictionary) -> Color:
    match str(projectile.get("kind", "bolt")):
        "pellet": return Color("#ffae57")
        "beam": return Color("#70e7ff")
        "shell": return Color("#ff665a")
        "tether": return Color("#db6cff")
        "hammer": return Color("#ffe066")
        "seeker": return Color("#ff5ca8")
        "burst": return Color("#8bffde")
        "slash": return Color("#b9f3ff")
        "fist": return Color("#ff9466")
        "bomb": return Color("#ff554a")
        "spear": return Color("#ffe27a")
        "chain": return Color("#b78cff")
        "shield": return Color("#8de1ff")
        _: return _slot_color(int(projectile["owner"]))

func _draw_dashed_circle(center: Vector2, radius: float, color: Color, width: float = 3.0, dash: float = 0.10, gap: float = 0.08) -> void:
    var angle := 0.0
    while angle < TAU:
        draw_arc(center, radius, angle, minf(angle + dash, TAU), 4, color, width)
        angle += dash + gap

func _draw_dashed_tracer(pos: Vector2, dir: Vector2, color: Color, width: float = 5.0) -> void:
    var cursor := 12.0
    for index in range(3):
        draw_line(pos - dir * (cursor + 15.0), pos - dir * cursor, color, width, true)
        cursor += 15.0 + 9.0

func _draw_motion_trail(trail: Array, color: Color, width: float, opacity: float = 1.0) -> void:
    if lite_draw or trail.size() < 2 or opacity <= 0.001:
        return
    var last_index := trail.size() - 1
    for segment_index in range(1, trail.size()):
        var age_ratio := float(segment_index) / float(last_index)
        var fade := pow(age_ratio, 1.65) * opacity
        var segment_width := width * lerpf(0.22, 1.0, age_ratio)
        var from: Vector2 = trail[segment_index - 1]
        var to: Vector2 = trail[segment_index]
        draw_line(from, to, Color(color, fade * 0.16), segment_width * 1.75, true)
        draw_line(from, to, Color(color, fade * 0.76), segment_width, true)

func _draw_island() -> void:
    var arena := Rect2(Vector2.ZERO, world.ARENA_SIZE)
    draw_rect(arena.grow(900.0), Color("#17456f"))
    if island_texture != null:
        var tex_size := island_texture.get_size()
        var arena_aspect: float = world.ARENA_SIZE.x / world.ARENA_SIZE.y
        var tex_aspect: float = tex_size.x / tex_size.y
        var src := Rect2(Vector2.ZERO, tex_size)
        if tex_aspect > arena_aspect:
            var w: float = tex_size.y * arena_aspect
            src = Rect2(Vector2((tex_size.x - w) * 0.5, 0.0), Vector2(w, tex_size.y))
        else:
            var h: float = tex_size.x / arena_aspect
            src = Rect2(Vector2(0.0, (tex_size.y - h) * 0.5), Vector2(tex_size.x, h))
        draw_texture_rect_region(island_texture, arena, src)
    else:
        draw_rect(arena, Color("#cbb37a"))
        draw_circle(Vector2(world.ARENA_CENTER), world.ARENA_SIZE.y * 0.48, Color("#d9c088"))

func _draw_safe_zone() -> void:
    var center: Vector2 = world.safe_zone_center
    var radius: float = maxf(8.0, float(world.safe_zone_radius))
    var target_radius: float = maxf(8.0, float(world.safe_zone_target_radius))
    var outer := maxf(world.ARENA_SIZE.x, world.ARENA_SIZE.y)
    var mid := (radius + outer) * 0.5
    var width := maxf(12.0, outer - radius)
    var seg := 32 if lite_draw else 96
    draw_arc(center, mid, 0.0, TAU, seg, Color(0.45, 0.10, 0.78, 0.30), width)
    if not lite_draw:
        draw_arc(center, mid, 0.0, TAU, seg, Color(0.30, 0.02, 0.50, 0.22), width * 0.55)
    var shrinking := bool(world.safe_zone_shrinking)
    var ring := ZONE_RING_HOT if shrinking else ZONE_RING
    var pulse := 7.0 + (3.0 if shrinking else 0.0) + sin(float(world.tick) * 0.12) * 1.4
    draw_arc(center, radius, 0.0, TAU, 96, Color(ring, 0.28), pulse * 2.8)
    draw_arc(center, radius, 0.0, TAU, 96, ring, pulse)
    draw_arc(center, radius, 0.0, TAU, 96, Color("#f4e2ff"), 2.0)
    if shrinking or absf(target_radius - radius) > 4.0:
        _draw_dashed_circle(center, target_radius, Color(1.0, 1.0, 1.0, 0.62), 3.0)

func _draw_covers() -> void:
    for cover in world.covers:
        var rect: Rect2 = cover["rect"]
        var c := rect.get_center()
        var base := minf(rect.size.x, rect.size.y) * 0.5
        draw_circle(c + Vector2(3.0, 5.0), base, Color(0.16, 0.17, 0.19, 0.85))
        draw_circle(c, base, Color("#7d838e"))
        draw_circle(c - Vector2(base * 0.25, base * 0.30), base * 0.55, Color("#9aa1ac"))
        draw_circle(c + Vector2(base * 0.35, base * 0.25), base * 0.34, Color("#6a707a"))

func _item_display_kind(pickup: Dictionary) -> String:
    var kind := str(pickup.get("kind", ""))
    if kind == "":
        return "medkit"
    if kind == "decoy":
        return str(pickup.get("disguise", "medkit"))
    return kind

func _item_tint(kind: String) -> Color:
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

func _item_label(kind: String) -> String:
    match kind:
        "spring":
            return "SPRING"
        "slide":
            return "SLIDE"
        "pull":
            return "PULL"
        "pocket":
            return "POCKET"
        _:
            return "MEDKIT"

func _draw_pickups() -> void:
    for pickup in world.health_pickups:
        if not bool(pickup["active"]):
            continue
        var pickup_pos: Vector2 = pickup["pos"]
        var pulse := 1.0 + sin(float(world.tick) * 0.10 + float(pickup["id"])) * 0.10
        var gun_name := str(pickup.get("gun_name", ""))
        if gun_name != "":
            draw_circle(pickup_pos, 24.0 * pulse, Color(1.0, 0.82, 0.25, 0.16))
            draw_arc(pickup_pos, 27.0, 0.0, TAU, 28, Color("#ffd166"), 3.5)
            var pickup_equip := str(pickup.get("equipment", pickup.get("gun_id", "")))
            if gun_atlas != null and pickup_equip != "":
                var vis: Dictionary = GunSig.visual_for_equipment(pickup_equip)
                draw_texture_rect_region(gun_atlas, Rect2(pickup_pos - Vector2(26.0, 14.0) * pulse, Vector2(52.0, 28.0) * pulse), _gun_src_rect(int(vis.get("frame", 0))))
            elif gun_texture != null:
                draw_texture_rect(gun_texture, Rect2(pickup_pos - Vector2(24.0, 14.0) * pulse, Vector2(48.0, 28.0) * pulse), false)
            draw_string(GameFont.get_font(), pickup_pos + Vector2(-60.0, 44.0), gun_name, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, Color("#ffd166"))
            continue
        var show_kind := _item_display_kind(pickup)
        var tint: Color = _item_tint(show_kind)
        var magnet_slot := int(pickup.get("magnet_slot", -1))
        if magnet_slot >= 0 and magnet_slot < world.heroes.size():
            var magnet_dir := pickup_pos.direction_to(Vector2(world.heroes[magnet_slot]["pos"]))
            for trail_index in range(3):
                var side := magnet_dir.orthogonal() * (float(trail_index) - 1.0) * 7.0
                draw_line(pickup_pos - magnet_dir * (20.0 + float(trail_index) * 9.0) + side, pickup_pos - magnet_dir * (48.0 + float(trail_index) * 12.0) + side, Color(tint, 0.72), 4.0)
            draw_arc(pickup_pos, 25.0, magnet_dir.angle() - 1.1, magnet_dir.angle() + 1.1, 18, Color(tint, 0.95), 5.0)
        else:
            draw_circle(pickup_pos, 24.0 * pulse, Color(tint, 0.16))
            draw_arc(pickup_pos, 27.0, 0.0, TAU, 28, tint, 3.5)
        if show_kind == "medkit" and medkit_texture != null:
            draw_texture_rect(medkit_texture, Rect2(pickup_pos - Vector2(19.0, 19.0) * pulse, Vector2(38.0, 38.0) * pulse), false)
        elif show_kind == "medkit":
            draw_rect(Rect2(pickup_pos + Vector2(-5.0, -16.0), Vector2(10.0, 32.0)), Color("#d9ffe8"))
            draw_rect(Rect2(pickup_pos + Vector2(-16.0, -5.0), Vector2(32.0, 10.0)), Color("#d9ffe8"))
        else:
            draw_circle(pickup_pos, 11.0 * pulse, Color(tint, 0.92))
            draw_arc(pickup_pos, 16.0 * pulse, 0.0, TAU, 20, Color.WHITE, 2.0)
        if show_kind != "medkit" or str(pickup.get("kind", "")) != "":
            draw_string(GameFont.get_font(), pickup_pos + Vector2(-48.0, 42.0), _item_label(show_kind), HORIZONTAL_ALIGNMENT_CENTER, 96.0, 11, tint)

func _draw_cores() -> void:
    for core in world.cores:
        var slot := int(core["slot"])
        var pos: Vector2 = core["pos"]
        var color: Color = Color(_slot_color(slot))
        draw_circle(pos, 20.0, Color(color, 0.10))
        draw_arc(pos, 20.0, 0.0, TAU, 24, Color(color, 0.26), 2.0)
        draw_string(GameFont.get_font(), pos + Vector2(-18.0, 5.0), "P%d" % (slot + 1), HORIZONTAL_ALIGNMENT_CENTER, 36.0, 11, Color(color, 0.5))

func _draw_deployables() -> void:
    var max_deploy := 4 if lite_draw else 999
    var deploy_drawn := 0
    for mine in world.deployables:
        if lite_draw and deploy_drawn >= max_deploy:
            break
        deploy_drawn += 1
        var mine_pos: Vector2 = mine["pos"]
        var mine_owner := int(mine["owner"])
        var mine_color: Color = _slot_color(mine_owner)
        if StringName(mine.get("type", &"mine")) == &"wall":
            var wall_dir := Vector2(mine["direction"]).normalized()
            var wall_normal := Vector2(mine.get("travel_direction", wall_dir.orthogonal())).normalized()
            var wall_a := mine_pos - wall_dir * float(mine["half_length"])
            var wall_b := mine_pos + wall_dir * float(mine["half_length"])
            var life_ratio := clampf(float(mine["lifetime"]) / maxf(0.01, float(mine["max_lifetime"])), 0.0, 1.0)
            var arming := float(mine.get("arm_time", 0.0)) > 0.0
            var pulse := 0.72 + sin(float(world.tick) * 0.18) * 0.12
            draw_colored_polygon(PackedVector2Array([
                wall_a - wall_normal * 55.0,
                wall_b - wall_normal * 55.0,
                wall_b - wall_normal * 12.0,
                wall_a - wall_normal * 12.0
            ]), Color(0.16, 0.69, 0.88, 0.08 if not arming else 0.16))
            draw_line(wall_a - wall_normal * 44.0, wall_b - wall_normal * 44.0, Color("#63d8ff", 0.18), 5.0)
            draw_line(wall_a, wall_b, Color("#102b3e", 0.82), 27.0)
            draw_line(wall_a, wall_b, Color("#8de1ff", pulse), 11.0)
            for wall_segment in range(7):
                var segment_pos := wall_a.lerp(wall_b, float(wall_segment) / 6.0)
                draw_line(segment_pos - wall_normal * 17.0, segment_pos + wall_normal * 17.0, Color.WHITE, 3.0)
                draw_colored_polygon(PackedVector2Array([segment_pos + wall_normal * 13.0, segment_pos + wall_dir * 7.0, segment_pos - wall_normal * 13.0, segment_pos - wall_dir * 7.0]), Color(mine_color, 0.72))
            var arrow_center := mine_pos + wall_normal * 48.0
            draw_colored_polygon(PackedVector2Array([
                arrow_center + wall_normal * 20.0,
                arrow_center - wall_normal * 12.0 + wall_dir * 13.0,
                arrow_center - wall_normal * 5.0,
                arrow_center - wall_normal * 12.0 - wall_dir * 13.0
            ]), Color("#dff8ff", 0.55 if arming else 0.95))
            draw_rect(Rect2(mine_pos + Vector2(-54.0, -36.0), Vector2(108.0, 20.0)), Color(0.02, 0.06, 0.09, 0.82))
            var wall_text := "P%d LAUNCH" % (mine_owner + 1) if arming else "P%d RAM %.1f" % [mine_owner + 1, float(mine["lifetime"])]
            draw_string(GameFont.get_font(), mine_pos + Vector2(-50.0, -21.0), wall_text, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 11, Color("#dff8ff", 1.0 if arming else life_ratio))
            continue
        var armed := float(mine["arm_time"]) <= 0.0
        var triggered := bool(mine["triggered"])
        var trigger_radius := float(mine["trigger_radius"])
        if armed:
            for sensor_arc in range(8):
                var sensor_start := TAU * float(sensor_arc) / 8.0 + 0.08
                draw_arc(mine_pos, trigger_radius, sensor_start, sensor_start + 0.48, 8, Color("#ff765f", 0.48 if not triggered else 0.88), 3.0)
        else:
            var arm_ratio := 1.0 - clampf(float(mine["arm_time"]) / maxf(0.01, float(mine["arm_duration"])), 0.0, 1.0)
            draw_arc(mine_pos, 31.0, -PI * 0.5, -PI * 0.5 + TAU * arm_ratio, 24, Color("#ffd166"), 5.0)
        if triggered:
            var fuse_ratio := clampf(float(mine["fuse_time"]) / maxf(0.01, float(mine["fuse_duration"])), 0.0, 1.0)
            draw_circle(mine_pos, float(mine["blast_radius"]), Color(0.42, 0.03, 0.02, 0.08 + (1.0 - fuse_ratio) * 0.12))
            draw_arc(mine_pos, float(mine["blast_radius"]) * lerpf(0.34, 1.0, fuse_ratio), 0.0, TAU, 42, Color("#ff554a"), 5.0)
            draw_string(GameFont.get_font(), mine_pos + Vector2(-42.0, -39.0), "MOVE! %.1f" % float(mine["fuse_time"]), HORIZONTAL_ALIGNMENT_CENTER, 84.0, 13, Color.WHITE)
        draw_circle(mine_pos, 19.0, Color("#241014"))
        draw_colored_polygon(PackedVector2Array([mine_pos + Vector2(0.0, -18.0), mine_pos + Vector2(18.0, 0.0), mine_pos + Vector2(0.0, 18.0), mine_pos + Vector2(-18.0, 0.0)]), Color("#ff554a") if armed else Color("#8ca0b8"))
        draw_circle(mine_pos, 7.0 + (sin(float(world.tick) * 0.28) * 2.0 if armed else 0.0), Color.WHITE if triggered else mine_color)
        draw_string(GameFont.get_font(), mine_pos + Vector2(-30.0, 34.0), "P%d MINE" % (mine_owner + 1), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 10, Color.WHITE)

func _draw_projectiles() -> void:
    for projectile in world.projectiles:
        var source := StringName(projectile["source"])
        var projectile_color: Color = Color.WHITE if source == &"ultimate" else _projectile_color(projectile)
        var projectile_pos: Vector2 = projectile["pos"]
        var direction := Vector2(projectile["vel"]).normalized()
        var kind := str(projectile.get("kind", "bolt"))
        if bool(projectile.get("arc", false)):
            _draw_motion_trail(projectile.get("trail", []), projectile_color, 5.0)
            var arc_progress := clampf(1.0 - float(projectile["ttl"]) / maxf(0.01, float(projectile["max_ttl"])), 0.0, 1.0)
            var bomb_scale := 0.72 + sin(arc_progress * PI) * 0.95
            var landing: Vector2 = projectile["landing_pos"]
            draw_circle(projectile_pos + Vector2(7.0, 9.0), 13.0 * bomb_scale, Color(0.0, 0.0, 0.0, 0.23))
            draw_circle(projectile_pos, 11.0 * bomb_scale, Color("#2c1115"))
            draw_arc(projectile_pos, 13.0 * bomb_scale, 0.0, TAU, 22, Color("#ff6b4a"), 4.0)
            draw_circle(landing, float(projectile["splash"]), Color(0.35, 0.04, 0.03, 0.07))
            draw_arc(landing, float(projectile["splash"]) * lerpf(1.0, 0.78, arc_progress), 0.0, TAU, 36, Color(1.0, 0.34, 0.22, 0.68), 3.0)
            continue
        match kind:
            "beam":
                draw_line(projectile_pos - direction * 125.0, projectile_pos + direction * 18.0, Color(projectile_color, 0.28), 18.0)
                draw_line(projectile_pos - direction * 145.0, projectile_pos + direction * 22.0, Color.WHITE, 3.5)
                draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 18.0, projectile_pos + direction.orthogonal() * 7.0, projectile_pos - direction * 16.0, projectile_pos - direction.orthogonal() * 7.0]), projectile_color)
            "shell":
                _draw_dashed_tracer(projectile_pos, direction, BULLET_YELLOW, 5.0)
                draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 15.0, projectile_pos + direction.orthogonal() * 10.0, projectile_pos - direction * 11.0, projectile_pos - direction.orthogonal() * 10.0]), Color("#ff503f"))
                draw_line(projectile_pos - direction * 34.0, projectile_pos - direction * 8.0, Color("#ffcf66"), 8.0)
            "tether":
                for segment in range(3):
                    var center := projectile_pos - direction * float(segment * 13)
                    draw_line(center - direction.orthogonal() * 7.0, center + direction.orthogonal() * 7.0, projectile_color, 4.0)
            "seeker":
                _draw_dashed_tracer(projectile_pos, direction, BULLET_YELLOW, 4.0)
                var star := PackedVector2Array()
                for point in range(8):
                    star.append(projectile_pos + Vector2.RIGHT.rotated(TAU * float(point) / 8.0) * (12.0 if point % 2 == 0 else 5.0))
                draw_colored_polygon(star, projectile_color)
            "slash":
                var slash_angle := direction.angle()
                draw_arc(projectile_pos - direction * 8.0, 31.0, slash_angle - 1.05, slash_angle + 1.05, 18, Color("#b9f3ff"), 10.0)
                draw_arc(projectile_pos - direction * 8.0, 25.0, slash_angle - 0.95, slash_angle + 0.95, 16, Color.WHITE, 3.0)
            "fist":
                draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 18.0, projectile_pos + direction.orthogonal() * 13.0, projectile_pos - direction * 13.0 + direction.orthogonal() * 9.0, projectile_pos - direction * 13.0 - direction.orthogonal() * 9.0]), Color("#ff9466"))
                draw_line(projectile_pos - direction * 38.0, projectile_pos - direction * 8.0, Color("#ffd0ac"), 9.0)
            "bomb":
                _draw_dashed_tracer(projectile_pos, direction, BULLET_YELLOW, 4.0)
                draw_circle(projectile_pos, 13.0, Color("#2c1115"))
                draw_arc(projectile_pos, 14.0, 0.0, TAU, 22, Color("#ff554a"), 5.0)
                draw_line(projectile_pos - direction.orthogonal() * 12.0, projectile_pos - direction.orthogonal() * 23.0 - direction * 7.0, Color("#ffe36a"), 4.0)
            "spear":
                draw_line(projectile_pos - direction * 66.0, projectile_pos + direction * 24.0, Color("#d0a447"), 7.0)
                draw_colored_polygon(PackedVector2Array([projectile_pos + direction * 36.0, projectile_pos + direction * 17.0 + direction.orthogonal() * 10.0, projectile_pos + direction * 17.0 - direction.orthogonal() * 10.0]), Color("#fff1a8"))
            "chain":
                draw_arc(projectile_pos, 14.0, -direction.angle() - PI * 0.6, -direction.angle() + PI * 0.7, 14, Color("#e2c8ff"), 6.0)
            "shield":
                var shield_side := direction.orthogonal()
                draw_colored_polygon(PackedVector2Array([projectile_pos - shield_side * 18.0 - direction * 8.0, projectile_pos + shield_side * 18.0 - direction * 8.0, projectile_pos + shield_side * 14.0 + direction * 17.0, projectile_pos + direction * 26.0, projectile_pos - shield_side * 14.0 + direction * 17.0]), Color("#8de1ff"))
            "tracer":
                var origin: Vector2 = projectile_pos
                var trail: Array = projectile.get("trail", [])
                if trail.size() > 0:
                    origin = trail[0]
                draw_line(origin, projectile_pos + direction * 28.0, Color(1.0, 1.0, 1.0, 0.22), 10.0)
                draw_line(origin, projectile_pos + direction * 28.0, Color(1.0, 0.95, 0.75, 0.95), 3.0)
            "pellet", "burst", "bolt":
                _draw_lhj_bullet(projectile_pos, direction, kind, 2.5 if bool(projectile.get("heavy", false)) else 1.0)
            _:
                if bullet_atlas != null and kind not in ["beam", "slash", "fist", "spear", "chain", "shield", "tether", "bomb"]:
                    _draw_dashed_tracer(projectile_pos, direction, BULLET_YELLOW, 3.0)
                    _draw_lhj_bullet(projectile_pos, direction, kind)
                else:
                    _draw_dashed_tracer(projectile_pos, direction, BULLET_YELLOW, 5.0)
                    draw_circle(projectile_pos + direction * 6.0, 7.0, Color(BULLET_YELLOW, 0.35))
                    draw_circle(projectile_pos + direction * 6.0, 4.5, BULLET_YELLOW)
                    draw_circle(projectile_pos + direction * 8.0, 2.2, Color.WHITE)

func _draw_zones() -> void:
    var max_zones := 4 if lite_draw else 999
    var zone_drawn := 0
    for zone in world.zones:
        if lite_draw and zone_drawn >= max_zones:
            break
        zone_drawn += 1
        var zone_color: Color = zone.get("color", _slot_color(int(zone["owner"])))
        var delay := float(zone.get("delay", 0.0))
        var warning_duration := maxf(0.01, float(zone.get("warning_duration", delay)))
        var warning_ratio := clampf(delay / warning_duration, 0.0, 1.0)
        var impact_progress := 1.0 - warning_ratio
        var warning_alpha := 0.08 + impact_progress * 0.18 + 0.04 * sin(float(world.tick) * 0.32)
        var zone_pos: Vector2 = zone["pos"]
        var zone_radius := float(zone["radius"])
        var zone_kind := StringName(zone.get("effect_kind", &"explosion"))
        if delay <= 0.06:
            continue
        draw_circle(zone_pos, zone_radius, Color("#15090b", warning_alpha * 1.35) if zone_kind == &"explosion" else Color(zone_color, warning_alpha * 0.72))
        draw_arc(zone_pos, zone_radius, 0.0, TAU, 42, Color(zone_color, 0.78), 4.0)
        if zone_kind == &"rail_strike":
            draw_line(zone_pos - Vector2(zone_radius * 1.6, 0.0), zone_pos + Vector2(zone_radius * 1.6, 0.0), Color(zone_color, 0.75), 5.0)
            draw_line(zone_pos - Vector2(0.0, zone_radius * 1.6), zone_pos + Vector2(0.0, zone_radius * 1.6), Color.WHITE, 2.0)
        elif zone_kind == &"drain":
            for ring in range(3):
                draw_arc(zone_pos, zone_radius * (0.35 + ring * 0.23), float(world.tick) * 0.05 + ring, float(world.tick) * 0.05 + ring + PI * 1.35, 24, Color(zone_color, 0.72), 4.0)
        elif zone_kind == &"shockwave":
            for spoke in range(8):
                var radial := Vector2.RIGHT.rotated(TAU * float(spoke) / 8.0)
                draw_line(zone_pos + radial * zone_radius * 0.45, zone_pos + radial * zone_radius, Color(zone_color, 0.75), 4.0)
        elif zone_kind == &"slashwave":
            for slash in range(3):
                var slash_angle := float(world.tick) * 0.08 + slash * PI / 3.0
                draw_arc(zone_pos, zone_radius * (0.55 + slash * 0.16), slash_angle, slash_angle + PI * 0.85, 18, Color(zone_color, 0.82), 6.0)
        elif zone_kind == &"fist_burst":
            for fist_ray in range(6):
                var fist_dir := Vector2.RIGHT.rotated(TAU * float(fist_ray) / 6.0)
                draw_line(zone_pos + fist_dir * 18.0, zone_pos + fist_dir * zone_radius, Color(zone_color, 0.82), 10.0)
        elif zone_kind == &"chain_vortex":
            for ring in range(3):
                draw_arc(zone_pos, zone_radius * (0.42 + ring * 0.22), float(world.tick) * -0.08 + ring, float(world.tick) * -0.08 + ring + PI * 1.55, 28, Color(zone_color, 0.86), 7.0)
        elif zone_kind == &"shield_bash":
            draw_arc(zone_pos, zone_radius * 0.82, -PI * 0.75, PI * 0.75, 28, Color(zone_color, 0.92), 15.0)
            draw_line(zone_pos - Vector2(0.0, zone_radius * 0.8), zone_pos + Vector2(0.0, zone_radius * 0.8), Color.WHITE, 4.0)
        if delay > 0.0:
            var timer_radius := float(zone["radius"]) * lerpf(0.28, 1.0, warning_ratio)
            draw_arc(zone_pos, timer_radius, 0.0, TAU, 36, Color.WHITE, 3.0 + impact_progress * 2.0)
            for warning_tick in range(8):
                var tick_dir := Vector2.RIGHT.rotated(TAU * float(warning_tick) / 8.0)
                draw_line(zone_pos + tick_dir * (zone_radius + 5.0), zone_pos + tick_dir * (zone_radius + 13.0), Color(zone_color, 0.82), 3.0)
            var warning_label := str(zone.get("label", ""))
            if not warning_label.is_empty() and zone_radius >= 90.0:
                draw_rect(Rect2(zone_pos + Vector2(-72.0, -13.0), Vector2(144.0, 25.0)), Color(0.04, 0.02, 0.03, 0.76))
                draw_string(GameFont.get_font(), zone_pos + Vector2(-68.0, 6.0), "%s  %.1f" % [warning_label, delay], HORIZONTAL_ALIGNMENT_CENTER, 136.0, 13, Color.WHITE)

func _draw_effects() -> void:
    var max_effects := 8 if lite_draw else 999
    var drawn := 0
    for effect in world.effects:
        if lite_draw and drawn >= max_effects:
            break
        drawn += 1
        var effect_color: Color = effect["color"]
        var ratio := clampf(float(effect["time"]) / float(effect["max_time"]), 0.0, 1.0)
        var effect_pos: Vector2 = effect["pos"]
        var effect_radius := float(effect["radius"])
        var effect_kind := StringName(effect["kind"])
        var direction := Vector2(effect["direction"]).normalized()
        var progress := 1.0 - ratio
        match effect_kind:
            &"line", &"beam_hit", &"beam_step":
                var line_start := effect_pos - direction * effect_radius * (0.75 if effect_kind == &"beam_hit" else 1.0)
                var line_end := effect_pos + direction * effect_radius * (0.65 if effect_kind == &"beam_hit" else 0.05)
                draw_line(line_start, line_end, Color(effect_color, ratio * 0.34), 26.0 * ratio + 5.0)
                draw_line(line_start, line_end, Color.WHITE, 4.0 * ratio + 1.5)
            &"explosion":
                var blast_radius := effect_radius * lerpf(0.18, 1.28, progress)
                draw_circle(effect_pos, blast_radius * 0.72, Color("#3a0808", ratio * 0.72))
                draw_circle(effect_pos, blast_radius * 0.48, Color(effect_color, ratio * 0.86))
                draw_arc(effect_pos, blast_radius, 0.0, TAU, 52, Color.WHITE, ratio, 9.0 * ratio + 2.0)
            &"drain":
                for arc_index in range(4):
                    var arc_radius := effect_radius * (0.28 + float(arc_index) * 0.18) * (0.65 + progress * 0.35)
                    var arc_start := progress * TAU * (1.0 if arc_index % 2 == 0 else -1.0) + arc_index
                    draw_arc(effect_pos, arc_radius, arc_start, arc_start + PI * 1.25, 22, Color(effect_color, ratio), 5.0)
            &"shockwave":
                var shock_radius := effect_radius * lerpf(0.25, 1.18, progress)
                draw_arc(effect_pos, shock_radius, 0.0, TAU, 32, Color(effect_color, ratio), 10.0 * ratio + 2.0)
                for spoke in range(10):
                    var radial := Vector2.RIGHT.rotated(TAU * float(spoke) / 10.0)
                    draw_line(effect_pos + radial * shock_radius * 0.48, effect_pos + radial * shock_radius, Color(Color.WHITE, ratio * 0.85), 3.0)
            &"wall_impact", &"hit_spark":
                for spark in range(9):
                    var spark_dir := (-direction).rotated((float(spark) - 4.0) * 0.16)
                    draw_line(effect_pos, effect_pos + spark_dir * effect_radius * (0.45 + float(spark % 3) * 0.22), Color(effect_color, ratio), 5.0 if effect_kind == &"wall_impact" else 3.0)
            &"speed_streak":
                for streak in range(5):
                    var side := direction.orthogonal() * (float(streak) - 2.0) * 9.0
                    draw_line(effect_pos + side, effect_pos + side + direction * effect_radius, Color(effect_color, ratio * 0.8), 4.0)
            &"slashwave", &"slash_dash":
                var slash_angle := direction.angle()
                var slash_radius := effect_radius * lerpf(0.72, 1.04, progress)
                draw_arc(effect_pos, slash_radius, slash_angle - 1.05, slash_angle + 1.05, 20, Color(effect_color, ratio), 8.0)
                draw_arc(effect_pos, slash_radius - 9.0, slash_angle - 0.86, slash_angle + 0.86, 16, Color(Color.WHITE, ratio * 0.72), 2.0)
            &"fist_burst":
                draw_line(effect_pos - direction * effect_radius * 0.38, effect_pos + direction * effect_radius * 0.52, Color(effect_color, ratio * 0.42), 18.0)
                draw_line(effect_pos - direction * 8.0, effect_pos + direction * effect_radius * 0.64, Color.WHITE, ratio, 6.0)
                draw_line(effect_pos - direction * 2.0, effect_pos + direction.rotated(0.26) * effect_radius * 0.48, Color(effect_color, ratio * 0.74), 5.0)
            &"hammer_slam":
                var hammer_side := direction.orthogonal()
                draw_line(effect_pos - direction * effect_radius * 0.56, effect_pos + direction * effect_radius * 0.16, Color(effect_color, ratio * 0.72), 20.0)
                draw_line(effect_pos - hammer_side * effect_radius * 0.42, effect_pos + hammer_side * effect_radius * 0.42, Color.WHITE, ratio, 7.0)
                draw_line(effect_pos, effect_pos + direction.rotated(0.55) * effect_radius * 0.56, Color(effect_color, ratio), 5.0)
                draw_line(effect_pos, effect_pos + direction.rotated(-0.55) * effect_radius * 0.56, Color(effect_color, ratio), 5.0)
            &"spear_line":
                draw_line(effect_pos - direction * effect_radius, effect_pos + direction * effect_radius * 0.18, Color(effect_color, ratio * 0.34), 22.0)
                draw_line(effect_pos - direction * effect_radius, effect_pos + direction * effect_radius * 0.22, Color.WHITE, ratio, 4.0)
                draw_colored_polygon(PackedVector2Array([effect_pos + direction * effect_radius * 0.28, effect_pos + direction * effect_radius * 0.08 + direction.orthogonal() * 14.0, effect_pos + direction * effect_radius * 0.08 - direction.orthogonal() * 14.0]), Color(effect_color, ratio))
            &"chain_arc":
                for link in range(9):
                    var link_angle := progress * PI * 1.4 + float(link) * 0.19
                    var link_pos := effect_pos - direction * effect_radius * (float(link) / 9.0) + direction.orthogonal() * sin(link_angle) * 24.0
                    draw_arc(link_pos, 7.0, 0.0, TAU, 10, Color(effect_color, ratio), 3.0)
            &"fuse":
                draw_line(effect_pos, effect_pos + Vector2.UP.rotated(progress * 2.0) * effect_radius * 0.7, Color("#ffe36a", ratio), 5.0)
                for spark in range(6):
                    var spark_dir := Vector2.RIGHT.rotated(TAU * float(spark) / 6.0 + progress * 4.0)
                    draw_line(effect_pos, effect_pos + spark_dir * effect_radius * 0.45, Color(effect_color, ratio), 4.0)
            &"shield_bash":
                var shield_angle := direction.angle()
                draw_arc(effect_pos, effect_radius * lerpf(0.55, 1.15, progress), shield_angle - 1.15, shield_angle + 1.15, 30, Color(effect_color, ratio), 18.0)
                draw_line(effect_pos - direction.orthogonal() * effect_radius * 0.7, effect_pos + direction.orthogonal() * effect_radius * 0.7, Color.WHITE, ratio, 5.0)
            &"combo_finisher":
                for ray in range(5):
                    var ray_dir := (-direction).rotated((float(ray) - 2.0) * 0.13)
                    draw_line(effect_pos - direction * 10.0, effect_pos + ray_dir * effect_radius * (0.62 + float(ray) * 0.08), Color("#fff2b2", ratio * 0.82), 7.0 - absf(float(ray) - 2.0))
                draw_line(effect_pos - direction.orthogonal() * 34.0, effect_pos + direction.orthogonal() * 34.0, Color.WHITE, ratio, 6.0)
            &"charge_release":
                draw_arc(effect_pos, effect_radius * (0.75 + progress * 0.18), direction.angle() - 0.65, direction.angle() + 0.65, 20, Color(effect_color, ratio), 5.0)
                draw_line(effect_pos - direction * effect_radius * 0.45, effect_pos + direction * effect_radius * 0.28, Color.WHITE, ratio * 0.8, 3.0)
            &"victory":
                for victory_ring in range(3):
                    var ring_radius := effect_radius * (0.26 + float(victory_ring) * 0.19 + progress * 0.32)
                    draw_arc(effect_pos, ring_radius, progress * TAU + victory_ring, progress * TAU + victory_ring + PI * 1.45, 42, Color(effect_color, ratio * (0.86 - victory_ring * 0.18)), 7.0 - victory_ring)
                for victory_ray in range(10):
                    var ray_dir := Vector2.UP.rotated(TAU * float(victory_ray) / 10.0)
                    var ray_start := effect_pos + ray_dir * effect_radius * 0.38
                    draw_line(ray_start, ray_start + ray_dir * effect_radius * (0.22 + progress * 0.26), Color(Color.WHITE, ratio * 0.72), 5.0)
            &"combo_break", &"afterimage":
                draw_arc(effect_pos, effect_radius * lerpf(0.45, 1.20, progress), 0.0, TAU, 34, Color(effect_color, ratio), 8.0)
                draw_line(effect_pos - direction * effect_radius, effect_pos + direction * effect_radius, Color(effect_color, ratio * 0.72), 5.0)
            &"death_burst":
                var death_radius := effect_radius * lerpf(0.16, 1.10, progress)
                draw_circle(effect_pos, death_radius * 0.52, Color("#48030b", ratio * 0.82))
                draw_arc(effect_pos, death_radius, 0.0, TAU, 54, Color("#ff3349", ratio), 16.0)
                draw_line(effect_pos - Vector2.ONE * death_radius * 0.72, effect_pos + Vector2.ONE * death_radius * 0.72, Color.WHITE, ratio, 12.0)
                draw_line(effect_pos + Vector2(-1.0, 1.0) * death_radius * 0.72, effect_pos + Vector2(1.0, -1.0) * death_radius * 0.72, Color.WHITE, ratio, 12.0)
            &"guard":
                draw_arc(effect_pos, effect_radius, -PI * 0.8, PI * 0.8, 28, Color(effect_color, ratio), 9.0)
                draw_arc(effect_pos, effect_radius - 12.0, -PI * 0.8, PI * 0.8, 28, Color(Color.WHITE, ratio * 0.8), 3.0)
            &"heal_pickup":
                var heal_lift := progress * effect_radius * 0.55
                draw_line(effect_pos + Vector2(-12.0, -heal_lift), effect_pos + Vector2(12.0, -heal_lift), Color(effect_color, ratio), 7.0)
                draw_line(effect_pos + Vector2(0.0, -12.0 - heal_lift), effect_pos + Vector2(0.0, 12.0 - heal_lift), Color(effect_color, ratio), 7.0)
            &"heal_ready":
                draw_arc(effect_pos, effect_radius * lerpf(0.52, 0.92, progress), -PI * 0.35, PI * 0.35, 18, Color(effect_color, ratio), 5.0)
                draw_arc(effect_pos, effect_radius * lerpf(0.52, 0.92, progress), PI * 0.65, PI * 1.35, 18, Color(effect_color, ratio), 5.0)
            &"respawn":
                for beam in range(3):
                    var beam_x := (float(beam) - 1.0) * 16.0
                    draw_line(effect_pos + Vector2(beam_x, effect_radius * 0.48), effect_pos + Vector2(beam_x, -effect_radius * (0.35 + progress * 0.48)), Color(effect_color, ratio * (0.55 + float(beam) * 0.18)), 5.0)
            &"mine_place":
                draw_arc(effect_pos, effect_radius * lerpf(1.0, 0.35, progress), 0.0, TAU, 28, Color(effect_color, ratio), 7.0)
                for bolt in range(4):
                    var bolt_dir := Vector2.RIGHT.rotated(TAU * float(bolt) / 4.0)
                    draw_line(effect_pos + bolt_dir * 12.0, effect_pos + bolt_dir * effect_radius, Color.WHITE, ratio, 3.0)
            &"mine_fizzle":
                for smoke in range(5):
                    var smoke_dir := Vector2.UP.rotated((float(smoke) - 2.0) * 0.28)
                    draw_circle(effect_pos + smoke_dir * effect_radius * progress, 7.0 + smoke * 1.5, Color(effect_color, ratio * 0.32))
            _:
                var flash_radius := maxf(5.0, effect_radius * lerpf(0.12, 0.28, progress))
                draw_circle(effect_pos, flash_radius, Color(effect_color, ratio * 0.46))
                draw_line(effect_pos - Vector2(flash_radius * 1.8, 0.0), effect_pos + Vector2(flash_radius * 1.8, 0.0), Color(Color.WHITE, ratio * 0.7), 2.0)
        if str(effect["label"]) != "" and effect_kind in [&"heal_pickup", &"respawn"]:
            draw_string(GameFont.get_font(), effect_pos + Vector2(-100.0, -effect_radius - 10.0), str(effect["label"]), HORIZONTAL_ALIGNMENT_CENTER, 200.0, 16, Color(effect_color, ratio))

func _draw_blob_shadow(ground_pos: Vector2, hop_lift: float, opacity: float) -> void:
    var height_t: float = clampf(hop_lift / 19.0, 0.0, 1.0)
    var size_mul: float = lerpf(1.0, 0.52, height_t)
    var alpha_mul: float = lerpf(1.0, 0.38, height_t)
    var radius_x: float = 26.0 * size_mul
    var radius_y: float = 11.5 * size_mul
    var center: Vector2 = ground_pos + Vector2(1.5, 34.0)
    draw_set_transform(center, 0.0, Vector2(1.0, radius_y / radius_x))
    var rings: Array = [
        [1.00, 0.07],
        [0.88, 0.10],
        [0.74, 0.13],
        [0.58, 0.16],
        [0.40, 0.17],
        [0.22, 0.14]
    ]
    for ring in rings:
        var ring_scale: float = float(ring[0])
        var ring_alpha: float = float(ring[1])
        draw_circle(Vector2.ZERO, radius_x * ring_scale, Color(0.0, 0.0, 0.0, ring_alpha * alpha_mul * opacity))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_hero_sprite(pos: Vector2, slot: int, aim: Vector2, opacity: float = 1.0, hop_lift: float = 0.0, hop_scale: Vector2 = Vector2.ONE, hit_flash: float = 0.0) -> void:
    var hit_tint: Color = Color(3.4, 3.4, 3.4, opacity) if hit_flash > 0.0 else Color(1.0, 1.0, 1.0, opacity)
    _draw_blob_shadow(pos, hop_lift, opacity)
    draw_arc(pos, 30.0, 0.0, TAU, 28, Color(_slot_color(slot), 0.85 * opacity), 3.5)
    var sprite_pos: Vector2 = pos + Vector2(0.0, -hop_lift)
    var flip: float = -1.0 if aim.x < -0.05 else 1.0
    var draw_scale: Vector2 = Vector2(flip * hop_scale.x, hop_scale.y)
    if animal_atlas != null:
        draw_set_transform(sprite_pos, 0.0, draw_scale)
        draw_texture_rect_region(animal_atlas, Rect2(Vector2(-36.0, -36.0), Vector2(72.0, 72.0)), _animal_src_rect(slot), hit_tint)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    else:
        var tex := _zodiac_texture(slot)
        if tex != null:
            draw_set_transform(sprite_pos, 0.0, draw_scale)
            draw_texture_rect(tex, Rect2(Vector2(-33.0, -33.0), Vector2(66.0, 66.0)), false, hit_tint)
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        else:
            draw_circle(sprite_pos, 22.0, Color(_slot_color(slot), opacity))
            draw_arc(sprite_pos, 22.0, 0.0, TAU, 24, Color(0.0, 0.0, 0.0, 0.8 * opacity), 3.0)

func _draw_hero_gun(pos: Vector2, slot: int, aim: Vector2, opacity: float = 1.0, extra_squash: float = 0.0) -> void:
    var dir := aim if aim.length_squared() > 0.0001 else Vector2.RIGHT
    var equip_id := "burst"
    if world != null and slot >= 0 and slot < world.heroes.size():
        var held = world.heroes[slot].get("equipment", {})
        if typeof(held) == TYPE_DICTIONARY:
            equip_id = str(held.get("id", "burst"))
    var vis: Dictionary = GunSig.visual_for_equipment(equip_id)
    var family := str(vis.get("family", "rifle"))
    var kick := 0.0
    var rot_kick := 0.0
    var strap_kick := 0.0
    if slot >= 0 and slot < recoil_kick.size():
        kick = float(recoil_kick[slot])
        rot_kick = float(recoil_rot[slot])
        strap_kick = float(recoil_strap[slot])
    if extra_squash > 0.0 and posmod(slot, 12) == 11:
        extra_squash += 0.04
    var flip := -1.0 if dir.x < 0.0 else 1.0
    var mount: Vector2 = pos + Vector2(flip * 6.0, 4.0) + dir * (18.0 - kick)
    var angle := dir.angle() + rot_kick * (-1.0 if flip < 0.0 else 1.0)
    const GUN_TSCN_SCALE := 0.645
    const MUZZLE_LOCAL := Vector2(49.536, 0.0)
    const MUZZLE_TSCN_SCALE := 0.74175
    if gun_atlas != null:
        var src := _gun_src_rect(int(vis.get("frame", 0)))
        var cell := Vector2(float(gun_atlas.get_width()) / 4.0, float(gun_atlas.get_height()) / 3.0)
        var world_s := 72.0 / (cell.x * GUN_TSCN_SCALE)
        draw_set_transform(mount, angle, Vector2(world_s, world_s * flip))
        var off := Vector2(float(vis.get("ox", 0.0)), float(vis.get("oy", 0.0)))
        var gun_rect := Rect2((-cell * 0.5 + off) * GUN_TSCN_SCALE, cell * GUN_TSCN_SCALE)
        draw_texture_rect_region(gun_atlas, gun_rect, src, Color(1.0, 1.0, 1.0, opacity))
        var hero_muzzle := 0.0
        var hero_mrow := 0
        if world != null and slot >= 0 and slot < world.heroes.size():
            hero_muzzle = float(world.heroes[slot].get("muzzle_time", 0.0))
            hero_mrow = int(world.heroes[slot].get("muzzle_row", 0))
        if muzzle_atlas != null and (hero_muzzle > 0.0 or (slot >= 0 and slot < muzzle_life.size() and float(muzzle_life[slot]) > 0.0)):
            var counts := [2, 3, 4]
            var row := hero_mrow if hero_muzzle > 0.0 else int(vis.get("muzzle_row", 0))
            var n := int(counts[clampi(row, 0, 2)])
            var life := hero_muzzle if hero_muzzle > 0.0 else float(muzzle_life[slot])
            var played := maxf(0.0, float(feel_muzzle_max(row)) - life)
            var col := clampi(int(played / 0.055), 0, n - 1)
            var mcell := Vector2(float(muzzle_atlas.get_width()) / 4.0, float(muzzle_atlas.get_height()) / 3.0)
            var mscale := 1.0
            if world != null and slot >= 0 and slot < world.heroes.size():
                mscale = float(world.heroes[slot].get("muzzle_scale", 1.0))
            var msize := mcell * MUZZLE_TSCN_SCALE * mscale
            var mcenter := Vector2(float(vis.get("mx", 90.0)), float(vis.get("my", -18.0))) + MUZZLE_LOCAL
            draw_texture_rect_region(muzzle_atlas, Rect2(mcenter - msize * 0.5, msize), _muzzle_src_rect(row, col), Color(1.0, 1.0, 1.0, opacity))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    elif gun_texture != null:
        draw_set_transform(mount, angle, Vector2(1.0, flip))
        draw_texture_rect(gun_texture, Rect2(Vector2(-5.0, -9.0), Vector2(34.0, 18.0)), false, Color(1.0, 1.0, 1.0, opacity))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)



func _draw_dog_alert(body_pos: Vector2, hero: Dictionary) -> void:
    if float(hero.get("dog_windup", 0.0)) <= 0.0 and not bool(hero.get("dog_rush", false)):
        return
    var mark := body_pos + Vector2(0.0, -124.0)
    var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.018)
    draw_circle(mark + Vector2(0.0, 2.0), 18.0 * pulse, Color(0.12, 0.02, 0.02, 0.55))
    draw_circle(mark, 16.0 * pulse, Color("#ff2a2a"))
    draw_circle(mark, 13.0 * pulse, Color("#ffef6a"))
    draw_string(GameFont.get_font(), mark + Vector2(-16.0, 10.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 32.0, 28, Color("#d40000"))

func _draw_flee_mark(body_pos: Vector2, hero: Dictionary) -> void:
    if float(hero.get("flee_time", 0.0)) <= 0.0:
        return
    if flee_icon_tex == null:
        flee_icon_tex = _load_tex("res://assets/fx/flee-icon.png")
    var mark := body_pos + Vector2(0.0, -118.0)
    if flee_icon_tex != null:
        draw_texture_rect(flee_icon_tex, Rect2(mark + Vector2(-28.0, -22.0), Vector2(56.0, 44.0)), false)
    else:
        draw_circle(mark, 16.0, Color("#ffcc33"))
    draw_string(GameFont.get_font(), mark + Vector2(-30.0, 28.0), "도망", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 12, Color("#ffe066"))

func _draw_nametag(pos: Vector2, slot: int, hp_ratio: float, opacity: float = 1.0, display_name: String = "", hp_now: float = 0.0, hp_max: float = 0.0) -> void:
    var name := display_name if display_name != "" else "P%d %s" % [slot + 1, _zodiac_name(slot)]
    draw_string(GameFont.get_font(), pos + Vector2(-71.0, -78.0), name, HORIZONTAL_ALIGNMENT_CENTER, 144.0, 14, Color(0.0, 0.0, 0.0, 0.85 * opacity))
    draw_string(GameFont.get_font(), pos + Vector2(-72.0, -79.0), name, HORIZONTAL_ALIGNMENT_CENTER, 144.0, 14, Color(1.0, 1.0, 1.0, opacity))
    var bar := Rect2(pos + Vector2(-46.0, -64.0), Vector2(92.0, 16.0))
    draw_rect(bar.grow(2.0), Color(0.04, 0.05, 0.07, 0.92 * opacity))
    draw_rect(bar, Color(0.16, 0.18, 0.22, 0.95 * opacity))
    var fill := Color("#3fe37a") if hp_ratio > 0.34 else Color("#ff5d73")
    var fill_w := (bar.size.x - 4.0) * clampf(hp_ratio, 0.0, 1.0)
    draw_rect(Rect2(bar.position + Vector2(2.0, 2.0), Vector2(fill_w, bar.size.y - 4.0)), Color(fill, opacity))
    var hp_label := "%d / %d" % [roundi(hp_now), roundi(hp_max)]
    draw_string(GameFont.get_font(), bar.position + Vector2(1.0, 13.0), hp_label, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 11, Color(0.0, 0.0, 0.0, 0.7 * opacity))
    draw_string(GameFont.get_font(), bar.position + Vector2(0.0, 12.0), hp_label, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 11, Color(1.0, 1.0, 1.0, opacity))

func _draw_knockouts() -> void:
    for knockout in world.knockouts:
        var knockout_slot := int(knockout["slot"])
        var knockout_fade := clampf(float(knockout["time"]) / 0.42, 0.0, 1.0)
        _draw_motion_trail(knockout.get("trail", []), _slot_color(knockout_slot), 9.0, knockout_fade)
        var knockout_pos: Vector2 = knockout["pos"]
        var spin := float(knockout.get("max_time", 1.0)) - float(knockout["time"])
        if animal_atlas != null:
            draw_set_transform(knockout_pos, spin * 5.0, Vector2.ONE)
            draw_texture_rect_region(animal_atlas, Rect2(Vector2(-30.0, -30.0), Vector2(60.0, 60.0)), _animal_src_rect(knockout_slot), Color(1.0, 1.0, 1.0, 0.72 * knockout_fade))
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        else:
            var tex := _zodiac_texture(knockout_slot)
            if tex != null:
                draw_set_transform(knockout_pos, spin * 5.0, Vector2.ONE)
                draw_texture_rect(tex, Rect2(Vector2(-30.0, -30.0), Vector2(60.0, 60.0)), false, Color(1.0, 1.0, 1.0, 0.72 * knockout_fade))
                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
            else:
                draw_circle(knockout_pos, 22.0, Color(_slot_color(knockout_slot), 0.72 * knockout_fade))

func _timed_ids(hero: Dictionary) -> Array:
    var ids: Array = []
    for buff in hero.get("rl_timed", []):
        ids.append(str(buff.get("id", "")))
    return ids

func _timed_body_scale(hero: Dictionary) -> float:
    var ids: Array = _timed_ids(hero)
    if ids.has("double_giant"):
        return 2.05
    if ids.has("giant"):
        return 1.55
    if ids.has("turtle"):
        return 0.0
    return 1.0













func _draw_keycap(center: Vector2, letter: String) -> void:
    var box := Rect2(center + Vector2(-16.0, -18.0), Vector2(32.0, 32.0))
    draw_rect(box.grow(2.0), Color(0.10, 0.08, 0.06, 0.55))
    draw_rect(box, Color("#f4efe4"))
    draw_rect(Rect2(box.position + Vector2(2.0, 2.0), Vector2(box.size.x - 4.0, box.size.y - 5.0)), Color("#fffaf2"))
    draw_rect(box, Color("#c8bba8"), false, 2.0)
    draw_string(GameFont.get_font(), box.position + Vector2(0.0, 23.0), letter, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 16, Color("#2a2218"))

func _draw_finish_prompts() -> void:
    if world == null:
        return
    if not world.finish_cine.is_empty() and bool(world.finish_cine.get("on", false)):
        return
    var me := int(world.local_slot)
    if me < 0 or me >= world.heroes.size():
        me = 0
    var me_pos: Vector2 = world.heroes[me]["pos"]
    if bool(world.heroes[me].get("downed", false)) or not bool(world.heroes[me].get("alive", false)):
        return
    for hero in world.heroes:
        var slot := int(hero.get("slot", -1))
        if slot == me:
            continue
        if not bool(hero.get("downed", false)) or not bool(hero.get("alive", false)):
            continue
        var pos: Vector2 = hero["pos"]
        if me_pos.distance_to(pos) > 180.0:
            continue
        var bob := sin(float(world.tick) * 0.18) * 3.0
        var cap := pos + Vector2(0.0, -78.0 + bob)
        _draw_keycap(cap, "F")

func _draw_finish_actor(pos: Vector2, animal: int, face_right: bool, scale: float, spin: float, opacity: float, flash: float) -> void:
    var tint := Color(3.2, 3.2, 3.2, opacity) if flash > 0.0 else Color(1.0, 1.0, 1.0, opacity)
    var flip := 1.0 if face_right else -1.0
    draw_set_transform(pos, spin, Vector2(flip * scale, scale))
    if animal_atlas != null:
        draw_texture_rect_region(animal_atlas, Rect2(Vector2(-40.0, -40.0), Vector2(80.0, 80.0)), _animal_src_rect(animal), tint)
    else:
        draw_circle(Vector2.ZERO, 28.0, Color(_slot_color(animal), opacity))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_finish_cine() -> void:
    if world == null:
        return
    var cine: Dictionary = world.finish_cine
    if cine.is_empty() or not bool(cine.get("on", false)):
        return
    var atk := int(cine.get("atk", 0))
    var vic := int(cine.get("vic", -1))
    if atk < 0 or vic < 0 or atk >= world.heroes.size() or vic >= world.heroes.size():
        return
    if finish_bg_tex == null:
        finish_bg_tex = _load_tex("res://assets/fx/finish-bg.png")
    var mid := Vector2.ZERO
    var cam := get_viewport().get_camera_2d()
    if cam != null:
        mid = cam.get_screen_center_position()
    elif cine.has("mid"):
        mid = Vector2(cine["mid"])
    if finish_bg_tex != null:
        draw_texture_rect(finish_bg_tex, Rect2(mid + Vector2(-520.0, -260.0), Vector2(1040.0, 520.0)), false)
    else:
        draw_circle(mid, 220.0, Color(1.0, 0.32, 0.28, 0.6))
    var atk_h: Dictionary = world.heroes[atk]
    var vic_h: Dictionary = world.heroes[vic]
    var atk_an := int(atk_h.get("animal", atk))
    var vic_an := int(vic_h.get("animal", vic))
    var atk_pos := mid + Vector2(-150.0 + float(cine.get("atk_x", 0.0)), 28.0)
    var vic_pos := mid + Vector2(150.0, 36.0) + Vector2(float(cine.get("vic_x", 0.0)), float(cine.get("vic_y", 0.0)))
    _draw_finish_actor(atk_pos, atk_an, true, 1.55, 0.0, 1.0, 0.0)
    var spin := float(cine.get("vic_spin", 0.0))
    if not bool(cine.get("hit", false)):
        spin = 0.85
    var fade := 1.0
    if bool(cine.get("hit", false)):
        fade = clampf(1.0 - float(cine.get("fly", 0.0)) / 0.95, 0.15, 1.0)
    _draw_finish_actor(vic_pos, vic_an, false, 1.45, spin, fade, 0.4 if bool(cine.get("hit", false)) else 0.0)
    if not bool(cine.get("hit", false)):
        draw_string(GameFont.get_font(), mid + Vector2(-110.0, -176.0), "F / ESC", HORIZONTAL_ALIGNMENT_CENTER, 220.0, 14, Color("#fff4d2"))

func _draw_wool_shields() -> void:
    if world == null:
        return
    if wool_shield_tex == null:
        wool_shield_tex = _load_tex("res://assets/fx/sheep-wool-ring.png")
    for hero in world.heroes:
        if float(hero.get("wool_time", 0.0)) <= 0.0 or int(hero.get("wool_hp", 0)) <= 0:
            continue
        if bool(hero.get("eliminated", false)) or not bool(hero.get("alive", false)):
            continue
        var pos: Vector2 = hero["pos"]
        var hp_a := clampf(float(hero.get("wool_hp", 0)) / maxf(1.0, float(hero.get("wool_max", 5))), 0.45, 1.0)
        var sz := 128.0
        if wool_shield_tex != null:
            draw_texture_rect(wool_shield_tex, Rect2(pos - Vector2(sz, sz), Vector2(sz * 2.0, sz * 2.0)), false, Color(1.0, 1.0, 1.0, maxf(0.82, hp_a)))
        else:
            draw_arc(pos, 56.0, 0.0, TAU, 40, Color(1.0, 0.96, 0.88, 0.95), 14.0)

func _draw_dog_bones() -> void:
    if world == null:
        return
    if dog_bone_tex == null:
        dog_bone_tex = _load_tex("res://assets/fx/dog-bone.png")
    for bone in world.dog_bones:
        var pos: Vector2 = bone.get("pos", Vector2.ZERO)
        if dog_bone_tex != null:
            draw_texture_rect(dog_bone_tex, Rect2(pos + Vector2(-48.0, -22.0), Vector2(96.0, 44.0)), false)
        else:
            draw_circle(pos, 12.0, Color("#f3efe4"))

func _draw_pig_muds() -> void:
    if world == null:
        return
    if pig_mud_tex == null:
        pig_mud_tex = _load_tex("res://assets/fx/pig-mud.png")
    for mud in world.pig_muds:
        var pos: Vector2 = mud.get("pos", Vector2.ZERO)
        var rad := float(mud.get("radius", 200.0))
        var ttl := float(mud.get("ttl", 0.0))
        var fade := clampf(ttl / 1.4, 0.0, 1.0)
        var sz := rad * 2.15
        if pig_mud_tex != null:
            draw_texture_rect(pig_mud_tex, Rect2(pos - Vector2(sz * 0.5, sz * 0.38), Vector2(sz, sz * 0.76)), false, Color(1, 1, 1, 0.4 + 0.6 * fade))
        else:
            draw_circle(pos, rad, Color(0.36, 0.22, 0.08, 0.55 * fade))
        draw_arc(pos, rad, 0.0, TAU, 48, Color(0.42, 0.24, 0.08, 0.55 * fade), 3.0)

func _draw_rooster_eggs() -> void:
    if world == null:
        return
    for egg in world.rooster_eggs:
        if not bool(egg.get("alive", true)):
            continue
        var pos: Vector2 = egg.get("pos", Vector2.ZERO)
        draw_set_transform(pos + Vector2(0.0, 4.0), 0.0, Vector2(1.0, 1.18))
        draw_circle(Vector2.ZERO, 16.0, Color("#f4e6c8"))
        draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 20, Color("#3a2a18"), 3.0)
        draw_circle(Vector2(-4.0, -5.0), 4.0, Color("#fff6e4"))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_horse_kicks() -> void:
    if world == null:
        return
    for kick in world.horse_kicks:
        var pos: Vector2 = kick.get("pos", Vector2.ZERO)
        var dir: Vector2 = kick.get("dir", Vector2.LEFT)
        if dir.length_squared() < 0.01:
            dir = Vector2.LEFT
        dir = dir.normalized()
        var reach := float(kick.get("reach", 400.0))
        var t := clampf(float(kick.get("age", 0.0)) / maxf(0.01, float(kick.get("life", 0.42))), 0.0, 1.0)
        var fade := 1.0 - t
        var ang := dir.angle()
        var pts: PackedVector2Array = PackedVector2Array()
        pts.append(pos)
        for i in range(12):
            var a := ang - 1.15 + 2.30 * (float(i) / 11.0)
            pts.append(pos + Vector2(cos(a), sin(a)) * reach)
        draw_colored_polygon(pts, Color(0.62, 0.42, 0.16, 0.16 * fade))
        draw_arc(pos, reach * (0.35 + t * 0.65), ang - 1.15, ang + 1.15, 28, Color(0.92, 0.72, 0.32, 0.85 * fade), 7.0)
        for i in range(6):
            var a := ang - 1.00 + 2.00 * (float(i) / 6.0)
            var p: Vector2 = pos + Vector2(cos(a), sin(a)) * (70.0 + t * 150.0)
            draw_circle(p, 10.0 + (1.0 - t) * 8.0, Color(0.45, 0.30, 0.12, 0.35 * fade))

func _draw_rabbit_holes() -> void:
    if world == null:
        return
    if rabbit_hole_tex == null:
        rabbit_hole_tex = _load_tex("res://assets/fx/rabbit-hole.png")
    for hole in world.rabbit_holes:
        var pos: Vector2 = hole.get("pos", Vector2.ZERO)
        var ttl := float(hole.get("ttl", 0.0))
        var fade := clampf(ttl / 1.2, 0.0, 1.0)
        var sz := 118.0
        if str(hole.get("kind", "")) == "out":
            sz = 118.0
        if rabbit_hole_tex != null:
            draw_texture_rect(rabbit_hole_tex, Rect2(pos - Vector2(sz * 0.5, sz * 0.42), Vector2(sz, sz * 0.86)), false, Color(1, 1, 1, 0.35 + 0.65 * fade))
        else:
            draw_circle(pos, 34.0, Color(0.18, 0.08, 0.04, 0.85 * fade))

func _draw_tiger_roars() -> void:
    if world == null:
        return
    for roar in world.tiger_roars:
        var pos: Vector2 = roar.get("pos", Vector2.ZERO)
        var rad := float(roar.get("radius", 300.0))
        var life := maxf(0.01, float(roar.get("life", 1.15)))
        var t := clampf(float(roar.get("age", 0.0)) / life, 0.0, 1.0)
        var front := rad * t
        var fade := 1.0 - t * 0.28
        draw_circle(pos, front, Color(1.0, 0.72, 0.12, 0.10 * fade))
        draw_arc(pos, front, 0.0, TAU, 64, Color(1.0, 0.86, 0.26, 0.95 * fade), 8.0)

func _draw_dragon_smokes() -> void:
    if world == null:
        return
    if dragon_smoke_tex == null:
        dragon_smoke_tex = _load_tex("res://assets/fx/dragon-smoke.png")
    if dragon_smoke_tex == null:
        return
    for smoke in world.dragon_smokes:
        var pos: Vector2 = smoke.get("pos", Vector2.ZERO)
        var rad := float(smoke.get("radius", 300.0))
        var life := clampf(float(smoke.get("ttl", 0.0)) / 15.0, 0.0, 1.0)
        var sz := rad * 2.0
        draw_texture_rect(dragon_smoke_tex, Rect2(pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), false, Color(1.0, 1.0, 1.0, 0.78 * life + 0.18))

func _draw_snake_skins() -> void:
    for skin in world.snake_skins:
        if not bool(skin.get("alive", true)):
            continue
        var pos: Vector2 = skin.get("pos", Vector2.ZERO)
        if world._pos_in_dragon_smoke(pos) and int(skin.get("owner", -1)) != int(world.local_slot):
            continue
        var aim: Vector2 = skin.get("aim", Vector2.RIGHT)
        var flash := float(skin.get("flash", 0.0))
        var sc := float(skin.get("scale", 1.5))
        _draw_hero_sprite(pos, 5, aim, 0.78, 0.0, Vector2(1.02 * sc, 0.92 * sc), flash)
        var hp_now := float(skin.get("hp", 0.0))
        var hp_max := float(skin.get("max_hp", 1.0))
        var hp_ratio := clampf(hp_now / maxf(1.0, hp_max), 0.0, 1.0)
        var bar := Rect2(pos + Vector2(-42.0, -68.0), Vector2(84.0, 10.0))
        draw_rect(bar, Color(0.05, 0.08, 0.06, 0.72))
        draw_rect(Rect2(bar.position + Vector2(1.0, 1.0), Vector2((bar.size.x - 2.0) * hp_ratio, bar.size.y - 2.0)), Color("#8fd36a"))
        draw_string(GameFont.get_font(), pos + Vector2(-36.0, -76.0), "허물", HORIZONTAL_ALIGNMENT_CENTER, 72.0, 13, Color("#d8f5c4"))

func _draw_rat_tides() -> void:
    if world == null:
        return
    if rat_run_tex == null:
        rat_run_tex = _load_tex("res://assets/fx/rat-run.png")
    if rat_run_tex == null:
        return
    var tides: Array = world.rat_tides
    for tide in tides:
        var pos: Vector2 = tide.get("pos", Vector2.ZERO)
        var dir: Vector2 = tide.get("dir", Vector2.RIGHT)
        if dir.length_squared() < 0.01:
            dir = Vector2.RIGHT
        dir = dir.normalized()
        var perp := dir.rotated(PI * 0.5)
        var leng := float(tide.get("length", 360.0))
        var half_w := float(tide.get("half_w", 118.0))
        var ang := dir.angle()
        for i in range(30):
            var u := fposmod(float(i) * 0.173 + float(world.tick) * 0.045, 1.0)
            var along := (u - 0.28) * leng
            var side := sin(float(i) * 2.1 + float(world.tick) * 0.31) * half_w * 0.82
            var p: Vector2 = pos + dir * along + perp * side
            var bob := 1.0 + 0.08 * sin(float(world.tick) * 0.4 + float(i))
            draw_set_transform(p, ang, Vector2(bob, bob))
            draw_texture_rect(rat_run_tex, Rect2(Vector2(-34.0, -24.0), Vector2(68.0, 48.0)), false)
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_smoke_lost_self(hero: Dictionary) -> void:
    var pos: Vector2 = hero.get("pos", Vector2.ZERO)
    var wob := Vector2(sin(float(world.tick) * 0.21) * 54.0, cos(float(world.tick) * 0.17) * 46.0)
    var ghost: Vector2 = pos + wob
    var aim := Vector2(hero.get("aim", Vector2.RIGHT))
    var animal := int(hero.get("animal", 0))
    _draw_hero_sprite(ghost, animal, aim, 0.28, 0.0, Vector2(1.05, 0.92), 0.0)

func _draw_heroes() -> void:
    for hero in world.heroes:
        var slot := int(hero["slot"])
        if not bool(hero["alive"]):
            continue
        if bool(hero.get("burrowed", false)):
            continue
        if world.hero_hidden_in_smoke(slot):
            continue
        var pos: Vector2 = hero["pos"]
        var aim := Vector2(hero["aim"])
        var is_down := bool(hero.get("downed", false))
        var launch_trail_opacity := clampf(float(hero.get("launch_trail_fade", 0.0)) / 0.34, 0.0, 1.0)
        _draw_motion_trail(hero.get("launch_trail", []), _slot_color(slot), 6.5, launch_trail_opacity)
        if float(hero.get("launch_time", 0.0)) > 0.0 and Vector2(hero.get("launch_vel", Vector2.ZERO)).length_squared() > 1.0:
            var launch_dir := Vector2(hero["launch_vel"]).normalized()
            draw_line(pos - launch_dir * 94.0, pos - launch_dir * 18.0, Color(_slot_color(slot), 0.28), 9.0)
        if slot == world.wanted_slot:
            draw_colored_polygon(PackedVector2Array([pos + Vector2(-18.0, -58.0), pos + Vector2(-15.0, -74.0), pos + Vector2(-5.0, -65.0), pos + Vector2(0.0, -80.0), pos + Vector2(5.0, -65.0), pos + Vector2(15.0, -74.0), pos + Vector2(18.0, -58.0)]), Color("#ff3349"))
            draw_string(GameFont.get_font(), pos + Vector2(-40.0, -86.0), "WANTED", HORIZONTAL_ALIGNMENT_CENTER, 80.0, 11, Color("#ffd166"))
        if float(hero["cc_time"]) > 0.0:
            draw_arc(pos, 34.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(hero["cc_time"]) / 1.5, 0.15, 1.0), 24, Color("#63d8ff"), 5.0)
        if float(hero.get("root_time", 0.0)) > 0.0:
            var root_spin := float(world.tick) * 0.018
            for link_index in range(4):
                var link_dir := Vector2.RIGHT.rotated(root_spin + TAU * float(link_index) / 4.0)
                var link_center := pos + link_dir * 40.0
                draw_arc(link_center, 7.0, 0.0, TAU, 12, Color("#b78cff"), 3.0)
                draw_line(pos + link_dir * 31.0, pos + link_dir * 36.0, Color("#e2c9ff"), 3.0)
        if float(hero.get("stun_time", 0.0)) > 0.0:
            var stun_spin := float(world.tick) * 0.16
            for star_index in range(3):
                var star_pos := pos + Vector2(26.0, 8.0).rotated(stun_spin + TAU * float(star_index) / 3.0) + Vector2(0.0, -58.0)
                if stun_spin_tex != null:
                    draw_set_transform(star_pos, stun_spin * 1.4, Vector2.ONE)
                    draw_texture_rect(stun_spin_tex, Rect2(Vector2(-12.0, -12.0), Vector2(24.0, 24.0)), false)
                    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                else:
                    draw_colored_polygon(PackedVector2Array([star_pos + Vector2(0.0, -8.0), star_pos + Vector2(7.0, 0.0), star_pos + Vector2(0.0, 8.0), star_pos + Vector2(-7.0, 0.0)]), Color("#ffe27a"))
        if float(hero.get("guard_time", 0.0)) > 0.0:
            draw_arc(pos, 38.0, -PI * 0.82, PI * 0.82, 28, Color("#ffe066"), 7.0)
        if float(hero.get("super_armor_time", 0.0)) > 0.0:
            var armor_pulse := 42.0 + sin(float(world.tick) * 0.34 + slot) * 2.0
            draw_arc(pos, armor_pulse, 0.0, TAU, 32, Color(Color("#ff8dac"), 0.82), 4.0)
        if bool(hero.get("charging_skill", false)):
            var charge_ratio := clampf(float(hero.get("charge_time", 0.0)) / 1.15, 0.0, 1.0)
            draw_arc(pos, 45.0, -PI * 0.5, -PI * 0.5 + TAU * charge_ratio, 36, Color("#dff8ff"), 6.0)
        if world.result != &"playing" and slot == world.winner_slot:
            var winner_pulse := 56.0 + sin(float(world.tick) * 0.11) * 4.0
            draw_circle(pos, winner_pulse + 18.0, Color(1.0, 0.78, 0.24, 0.07))
            draw_arc(pos, winner_pulse, 0.0, TAU, 48, Color("#ffd166"), 6.0)
            draw_arc(pos, winner_pulse + 11.0, float(world.tick) * 0.025, float(world.tick) * 0.025 + PI * 1.45, 38, Color(Color.WHITE, 0.72), 3.0)
            var crown_y := -86.0 + sin(float(world.tick) * 0.08) * 2.0
            draw_colored_polygon(PackedVector2Array([pos + Vector2(-22.0, crown_y + 17.0), pos + Vector2(-20.0, crown_y), pos + Vector2(-7.0, crown_y + 10.0), pos + Vector2(0.0, crown_y - 6.0), pos + Vector2(7.0, crown_y + 10.0), pos + Vector2(20.0, crown_y), pos + Vector2(22.0, crown_y + 17.0)]), Color("#ffd166"))
        var hop_time: float = float(hero.get("hop_time", 0.0))
        var hop_lift: float = 0.0
        var hop_scale: Vector2 = Vector2.ONE
        if hop_time > 0.0:
            var hop_max: float = maxf(0.001, float(hero.get("hop_max", 0.30)))
            var hop_t: float = clampf(1.0 - hop_time / hop_max, 0.0, 1.0)
            var hop_height: float = float(hero.get("hop_height", 19.0))
            hop_lift = hop_height * sin(PI * hop_t)
            var hop_squash: float = cos(PI * hop_t)
            hop_scale = Vector2(1.00 + 0.12 * hop_squash, 1.02 - 0.14 * hop_squash)
        var body_pos: Vector2 = pos + Vector2(0.0, -hop_lift)
        var body_squash := 0.0
        if slot < recoil_body.size():
            body_squash = float(recoil_body[slot])
        if posmod(int(hero.get("animal", slot)), 12) == 11:
            hop_scale = Vector2(hop_scale.x * (1.0 + body_squash * 1.35), hop_scale.y * (1.0 - body_squash * 1.55))
        else:
            hop_scale = Vector2(hop_scale.x * (1.0 + body_squash), hop_scale.y * (1.0 - body_squash))
        var timed_ids: Array = _timed_ids(hero)
        var is_turtle: bool = timed_ids.has("turtle")
        var body_mul := _timed_body_scale(hero)
        if is_turtle:
            hop_scale = Vector2(1.25, 0.68)
        elif body_mul > 1.01:
            hop_scale = Vector2(hop_scale.x * body_mul, hop_scale.y * body_mul)
        var comb_nudge := 0.0
        if posmod(int(hero.get("animal", slot)), 12) == 9 and rooster_comb_lag > 0.0:
            comb_nudge = 1.0
        var ghost := 1.0
        if float(hero.get("spawn_protect_time", 0.0)) > 0.0:
            ghost = 0.38 + 0.38 * absf(sin(float(world.tick) * 0.35))
        if float(hero.get("dmg_orb_time", 0.0)) > 0.0:
            draw_arc(pos, 33.0 + sin(float(world.tick) * 0.28) * 2.0, 0.0, TAU, 28, Color(Color("#ff4f4f"), 0.80), 4.0)
        var shield_hp := 0.0
        for buff in hero.get("rl_timed", []):
            shield_hp += float(buff.get("shield", 0.0))
        if (shield_hp > 0.01 or timed_ids.has("shield")) and float(hero.get("wool_time", 0.0)) <= 0.0:
            draw_circle(pos, 40.0, Color(0.25, 0.78, 1.0, 0.16))
            draw_arc(pos, 42.0 + sin(float(world.tick) * 0.22) * 2.0, 0.0, TAU, 36, Color(Color("#70e7ff"), 0.95), 6.0)
        var hit_flash: float = float(hero.get("hit_flash", 0.0))
        if is_turtle:
            var turtle_tex: Texture2D = turtle_body_tex if turtle_body_tex != null else roulette_icons.get("turtle", null)
            var turtle_size := 110.0
            var flip: float = -1.0 if aim.x < -0.05 else 1.0
            if turtle_tex != null:
                draw_set_transform(pos + Vector2(0.0, 8.0), 0.0, Vector2(flip, 1.0))
                draw_texture_rect(turtle_tex, Rect2(Vector2(-turtle_size * 0.5, -turtle_size * 0.62), Vector2(turtle_size, turtle_size)), false)
                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
            else:
                draw_circle(pos + Vector2(0.0, 6.0), 28.0, Color("#3d8f4a"))
                draw_circle(pos + Vector2(0.0, 6.0), 16.0, Color("#6ef3a5"))
        else:
            var animal := int(hero.get("animal", slot))
            if is_down:
                draw_set_transform(pos + Vector2(0.0, 10.0), 1.25, Vector2(1.0, 0.72))
                _draw_hero_sprite(Vector2.ZERO, animal, aim, 0.95, 0.0, Vector2.ONE, 0.15)
                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                var bleed := clampf(float(hero.get("down_left", 0.0)) / 5.0, 0.0, 1.0)
                draw_arc(pos, 34.0, -PI * 0.5, -PI * 0.5 + TAU * bleed, 28, Color("#ff8d93"), 4.0)
                var fin := clampf(float(hero.get("down_taken", 0.0)) / 48.0, 0.0, 1.0)
                draw_arc(pos, 28.0, -PI * 0.5, -PI * 0.5 + TAU * fin, 22, Color("#ff3349"), 3.0)
                draw_string(GameFont.get_font(), pos + Vector2(-36.0, 48.0), "DOWN %.1f" % float(hero.get("down_left", 0.0)), HORIZONTAL_ALIGNMENT_CENTER, 72.0, 12, Color("#ffe066"))
            else:
                _draw_hero_sprite(pos + Vector2(0.0, comb_nudge), animal, aim, ghost, hop_lift, hop_scale, hit_flash)
                _draw_hero_gun(body_pos, slot, aim, ghost, body_squash)
                _draw_flee_mark(body_pos, hero)
                _draw_dog_alert(body_pos, hero)
            for clone in hero.get("ult_clones", []):
                if not bool(clone.get("alive", true)):
                    continue
                var cpos: Vector2 = clone.get("pos", pos)
                if world._pos_in_dragon_smoke(cpos) and slot != int(world.local_slot):
                    continue
                var caim: Vector2 = clone.get("aim", aim)
                var chop := hop_lift
                var cbody: Vector2 = cpos + Vector2(0.0, -chop)
                _draw_hero_sprite(cpos, animal, caim, 0.94, chop, hop_scale, 0.0)
                _draw_hero_gun(cbody, slot, caim, 0.94, body_squash)
        var icon_x := -18.0
        for mark_id in ["berserk", "sniper", "shield"]:
            if not timed_ids.has(mark_id):
                continue
            var mark_tex: Texture2D = roulette_icons.get(mark_id, null)
            var mark_pos: Vector2 = body_pos + Vector2(icon_x, -108.0)
            if mark_tex != null:
                draw_texture_rect(mark_tex, Rect2(mark_pos, Vector2(36.0, 36.0)), false)
            else:
                draw_circle(mark_pos + Vector2(18.0, 18.0), 14.0, Color.WHITE)
            icon_x += 40.0
        var hp_ratio := maxf(0.0, float(hero["hp"]) / float(hero["max_hp"]))
        var animal_name := _zodiac_name(int(hero.get("animal", slot)))
        var tag := str(hero.get("display_name", ""))
        if tag == "":
            tag = "P%d %s" % [slot + 1, animal_name]
        _draw_nametag(body_pos, slot, hp_ratio, ghost, tag, float(hero["hp"]), float(hero["max_hp"]))
        if int(hero.get("kill_streak", 0)) >= 2:
            draw_string(GameFont.get_font(), body_pos + Vector2(-40.0, -62.0), "x%d 연속" % int(hero["kill_streak"]), HORIZONTAL_ALIGNMENT_CENTER, 80.0, 11, Color("#ffd166"))

        _draw_reload_bubble(body_pos, hero)
        _draw_head_roulette(body_pos, hero)


func _draw_head_roulette(body_pos: Vector2, hero: Dictionary) -> void:
    if int(hero.get("slot", -1)) != int(world.local_slot):
        return
    var phase := str(hero.get("roulette_phase", ""))
    if phase == "":
        return
    var slice_ids: Array = ["atk", "spd", "def", "hp", "rate", "range", "giant", "shield", "berserk", "sniper", "double_giant", "turtle"]
    var count := slice_ids.size()
    var spin_id := str(hero.get("roulette_spin_id", ""))
    var current := 0
    if spin_id != "":
        for i in range(count):
            if str(slice_ids[i]) == spin_id:
                current = i
                break
    var wheel_pos: Vector2 = body_pos + Vector2(0.0, -88.0)
    var radius := 54.0
    var slice := TAU / float(count)
    var rot := 0.0
    if phase == "spin":
        var dur := maxf(0.001, float(hero.get("roulette_spin_dur", 0.9)))
        var u := clampf(1.0 - float(hero.get("roulette_time", 0.0)) / dur, 0.0, 1.0)
        var eased := 1.0 - (1.0 - u) * (1.0 - u)
        rot = TAU * 1.65 * eased
    elif phase == "land":
        rot = -float(current) * slice
    var rank := str(hero.get("roulette_rank", "kill"))
    var cols: Array = _roulette_slice_palette(rank)
    var rim: Color = _roulette_rank_color(rank)
    for i in range(count):
        var a0 := -PI * 0.5 + rot + float(i) * slice - slice * 0.5
        var a1 := a0 + slice
        var pts := PackedVector2Array()
        pts.append(wheel_pos)
        for s in range(7):
            var a := lerpf(a0, a1, float(s) / 6.0)
            pts.append(wheel_pos + Vector2(cos(a), sin(a)) * radius)
        draw_colored_polygon(pts, cols[i % cols.size()])
        draw_line(wheel_pos, wheel_pos + Vector2(cos(a0), sin(a0)) * radius, Color(1.0, 1.0, 1.0, 0.88), 1.6)
    draw_arc(wheel_pos, radius, 0.0, TAU, 48, rim.darkened(0.25), 5.0)
    draw_circle(wheel_pos, 7.5, Color(0.96, 0.93, 0.86, 1.0))
    draw_arc(wheel_pos, 7.5, 0.0, TAU, 20, rim.darkened(0.15), 1.6)
    for i in range(count):
        var mid := -PI * 0.5 + rot + float(i) * slice
        var face_id := str(slice_ids[i])
        var icon_pos: Vector2 = wheel_pos + Vector2(cos(mid), sin(mid)) * (radius * 0.58)
        var icon_tex: Texture2D = roulette_icons.get(face_id, null)
        var glow := phase == "land" and i == current
        var sz := 24.0 if glow else 20.0
        if icon_tex != null:
            draw_texture_rect(icon_tex, Rect2(icon_pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), false)
        else:
            draw_circle(icon_pos, 5.0, Color.WHITE)
    draw_colored_polygon(PackedVector2Array([
        wheel_pos + Vector2(0.0, -radius - 7.0),
        wheel_pos + Vector2(-7.0, -radius + 6.0),
        wheel_pos + Vector2(7.0, -radius + 6.0)
    ]), Color(0.98, 0.98, 0.98, 1.0))

func _roulette_slice_palette(rank: String) -> Array:
    if rank == "assist":
        return [Color("#2f6fff"), Color("#7eb6ff"), Color("#163a8a")]
    if rank == "wanted":
        return [Color("#e11d2e"), Color("#ff6b6b"), Color("#7a121c")]
    return [Color("#8b3dff"), Color("#c89bff"), Color("#4a1d86")]

func _roulette_rank_color(rank: String) -> Color:
    if rank == "assist":
        return Color("#4da3ff")
    if rank == "wanted":
        return Color("#ff3349")
    return Color("#b84dff")


func _draw_reload_bubble(body_pos: Vector2, hero: Dictionary) -> void:
    if not bool(hero.get("alive", false)):
        return
    var mag_now := int(hero.get("mag", 1))
    var reloading := float(hero.get("reload_left", 0.0)) > 0.0
    var flash := float(hero.get("reload_flash", 0.0)) > 0.0
    var mode := ""
    if reloading:
        mode = "RELOADING"
    elif flash:
        mode = "RELOADED"
    elif mag_now <= 0:
        mode = "NEED"
    if mode == "":
        return
    var bw := 36.0
    var bh := 28.0
    var origin: Vector2 = body_pos + Vector2(-bw * 0.5, -88.0)
    draw_rect(Rect2(origin, Vector2(bw, bh)), Color(1.0, 1.0, 1.0, 0.96))
    draw_rect(Rect2(origin, Vector2(bw, bh)), Color(0.05, 0.05, 0.07, 1.0), false, 1.0)
    var tail: PackedVector2Array = PackedVector2Array([
        body_pos + Vector2(-4.0, -60.0),
        origin + Vector2(bw * 0.5 - 5.0, bh),
        origin + Vector2(bw * 0.5 + 5.0, bh)
    ])
    draw_colored_polygon(tail, Color(1.0, 1.0, 1.0, 0.96))
    draw_line(tail[0], tail[1], Color(0.05, 0.05, 0.07, 1.0), 1.0)
    draw_line(tail[0], tail[2], Color(0.05, 0.05, 0.07, 1.0), 1.0)
    var c: Vector2 = origin + Vector2(bw * 0.5, bh * 0.5 - 1.0)
    if mode == "NEED":
        draw_rect(Rect2(c + Vector2(-7.0, -8.0), Vector2(14.0, 16.0)), Color(0.12, 0.12, 0.14, 1.0), false, 1.5)
        draw_rect(Rect2(c + Vector2(-4.0, -4.0), Vector2(8.0, 9.0)), Color(0.22, 0.22, 0.24, 1.0))
        draw_rect(Rect2(c + Vector2(8.0, -9.0), Vector2(3.0, 10.0)), Color(0.92, 0.18, 0.22, 1.0))
        draw_rect(Rect2(c + Vector2(8.0, 3.0), Vector2(3.0, 3.0)), Color(0.92, 0.18, 0.22, 1.0))
    elif mode == "RELOADING":
        var phase := int(world.tick / 4) % 8
        for i in range(8):
            var ang := float(i) * TAU / 8.0
            var p0: Vector2 = c + Vector2(cos(ang), sin(ang)) * 5.0
            var p1: Vector2 = c + Vector2(cos(ang), sin(ang)) * 10.0
            var col := Color(0.18, 0.18, 0.2, 1.0)
            if i == phase:
                col = Color(0.12, 0.45, 0.95, 1.0)
            draw_line(p0, p1, col, 2.0)
    else:
        draw_line(c + Vector2(-7.0, 1.0), c + Vector2(-2.0, 6.0), Color(0.12, 0.72, 0.28, 1.0), 2.4)
        draw_line(c + Vector2(-2.0, 6.0), c + Vector2(8.0, -6.0), Color(0.12, 0.72, 0.28, 1.0), 2.4)

func _draw_pocket_bubbles() -> void:
    for hero in world.heroes:
        if not bool(hero.get("alive", false)):
            continue
        if float(hero.get("pocket_time", 0.0)) <= 0.0:
            continue
        var bubble_pos: Vector2 = hero["pos"]
        var pulse := 150.0 + sin(float(world.tick) * 0.14 + float(hero.get("slot", 0))) * 4.0
        draw_circle(bubble_pos, pulse, Color(0.92, 0.95, 1.0, 0.10))
        draw_arc(bubble_pos, pulse, 0.0, TAU, 48, Color(0.90, 0.94, 1.0, 0.55), 3.0)
        draw_arc(bubble_pos, pulse * 0.70, 0.0, TAU, 32, Color(0.78, 0.86, 1.0, 0.22), 2.0)

func _draw() -> void:
    if world == null:
        return
    _consume_shot_events()
    _tick_recoil(1.0 / 60.0)
    _tick_combat_texts(1.0 / 60.0)
    _draw_island()
    _draw_safe_zone()
    _draw_covers()
    _draw_crates()
    _draw_mid_tower()
    _draw_crate_orbs()
    _draw_pickups()
    _draw_cores()
    _draw_deployables()
    _draw_zones()
    _draw_projectiles()
    _draw_impact_flashes()
    _draw_effects()
    _draw_knockouts()
    _draw_pocket_bubbles()
    _draw_dog_bones()
    _draw_wool_shields()
    _draw_pig_muds()
    _draw_rooster_eggs()
    _draw_horse_kicks()
    _draw_rabbit_holes()
    _draw_tiger_roars()
    _draw_heroes()
    _draw_finish_prompts()
    _draw_rat_tides()
    _draw_snake_skins()
    _draw_dragon_smokes()
    _draw_combat_texts()
    _draw_finish_cine()

func _draw_crates() -> void:
    if world.crates.is_empty():
        return
    for crate in world.crates:
        if not bool(crate.get("alive", false)):
            continue
        var pos: Vector2 = crate["pos"]
        var body := Rect2(pos + Vector2(-22.0, -20.0), Vector2(44.0, 40.0))
        draw_rect(body, Color("#5a3a1c"))
        draw_rect(body, Color("#3b2410"), false, 2.0)
        draw_rect(Rect2(pos + Vector2(-20.0, -16.0), Vector2(40.0, 5.0)), Color("#7a5130"))
        draw_rect(Rect2(pos + Vector2(-20.0, -4.0), Vector2(40.0, 5.0)), Color("#6b4526"))
        draw_rect(Rect2(pos + Vector2(-20.0, 8.0), Vector2(40.0, 5.0)), Color("#7a5130"))
        var hp_now := float(crate.get("hp", 0.0))
        var hp_max := float(crate.get("max_hp", 48.0))
        var hp_ratio := clampf(hp_now / maxf(1.0, hp_max), 0.0, 1.0)
        var bar := Rect2(pos + Vector2(-40.0, -38.0), Vector2(80.0, 14.0))
        draw_rect(bar.grow(2.0), Color(0.04, 0.05, 0.07, 0.9))
        draw_rect(bar, Color(0.16, 0.18, 0.22, 0.95))
        draw_rect(Rect2(bar.position + Vector2(2.0, 2.0), Vector2((bar.size.x - 4.0) * hp_ratio, bar.size.y - 4.0)), Color("#e0a15a"))
        var hp_label := "%d / %d" % [roundi(hp_now), roundi(hp_max)]
        draw_string(GameFont.get_font(), bar.position + Vector2(1.0, 12.0), hp_label, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 11, Color(0.0, 0.0, 0.0, 0.7))
        draw_string(GameFont.get_font(), bar.position + Vector2(0.0, 11.0), hp_label, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 11, Color.WHITE)

func _draw_crate_orbs() -> void:
    if world.crate_orbs.is_empty():
        return
    for orb in world.crate_orbs:
        if not bool(orb.get("active", true)):
            continue
        var pos: Vector2 = orb["pos"]
        var pulse := 1.0 + sin(float(world.tick) * 0.18) * 0.12
        var tint := Color("#ff4f4f") if bool(orb.get("red", true)) else Color("#4f8cff")
        draw_circle(pos, 18.0 * pulse, Color(tint, 0.18))
        draw_circle(pos, 11.0 * pulse, Color(tint, 0.92))
        draw_arc(pos, 16.0 * pulse, 0.0, TAU, 22, Color.WHITE, 2.0)

func _draw_impact_flashes() -> void:
    if impact_atlas == null:
        return
    for flash in impact_flashes:
        var row := int(flash.get("row", 1))
        var counts := [2, 3, 4]
        var n: int = int(counts[clampi(row, 0, 2)])
        if float(flash.get("time", 0.0)) < 0.0:
            continue
        var col := clampi(int(float(flash.get("time", 0.0)) / 0.055), 0, n - 1)
        var pos: Vector2 = flash["pos"]
        draw_texture_rect_region(impact_atlas, Rect2(pos - Vector2(28.0, 28.0), Vector2(56.0, 56.0)), _impact_src_rect(row, col), Color.WHITE)

func _push_combat_text(pos: Vector2, text: String, color: Color) -> void:
    combat_texts.append({"pos": pos + Vector2(randf_range(-10.0, 10.0), -28.0), "text": text, "color": color, "time": 0.0})

func _tick_combat_texts(dt: float) -> void:
    var keep: Array = []
    for item in combat_texts:
        item["time"] = float(item.get("time", 0.0)) + dt
        item["pos"] = Vector2(item["pos"]) + Vector2(0.0, -42.0 * dt)
        if float(item["time"]) < 0.85:
            keep.append(item)
    combat_texts = keep

func _draw_combat_texts() -> void:
    for item in combat_texts:
        var fade := 1.0 - clampf(float(item["time"]) / 0.85, 0.0, 1.0)
        var pos: Vector2 = item["pos"]
        var text := str(item.get("text", ""))
        var col: Color = item.get("color", Color.WHITE)
        draw_string(GameFont.get_font(), pos + Vector2(-31.0, 1.0), text, HORIZONTAL_ALIGNMENT_CENTER, 64.0, 18, Color(0.0, 0.0, 0.0, 0.75 * fade))
        draw_string(GameFont.get_font(), pos + Vector2(-32.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, 64.0, 18, Color(col, fade))


func _draw_mid_tower() -> void:
    if world == null or not bool(world.mid_tower.get("alive", false)):
        return
    var pos: Vector2 = world.mid_tower["pos"]
    var boing := float(world.mid_tower.get("boing", 0.0))
    var squash := 1.0 + sin(boing * PI / 0.22) * 0.16 if boing > 0.0 else 1.0
    var sz := Vector2(210.0, 278.0) * squash
    if tower_texture != null:
        draw_texture_rect(tower_texture, Rect2(pos - sz * 0.5 + Vector2(0, -22.0), sz), false)
    var hp_now := float(world.mid_tower.get("hp", 0.0))
    var hp_max := float(world.mid_tower.get("max_hp", 1.0))
    var ratio := clampf(hp_now / maxf(1.0, hp_max), 0.0, 1.0)
    var bar := Rect2(pos + Vector2(-88.0, -150.0), Vector2(176.0, 18.0))
    draw_rect(bar.grow(2.0), Color(0.04, 0.05, 0.07, 0.9))
    draw_rect(bar, Color(0.16, 0.18, 0.22, 0.95))
    draw_rect(Rect2(bar.position + Vector2(2.0, 2.0), Vector2((bar.size.x - 4.0) * ratio, bar.size.y - 4.0)), Color("#ff5a4a"))
    var label := "%d / %d" % [roundi(hp_now), roundi(hp_max)]
    draw_string(GameFont.get_font(), bar.position + Vector2(0.0, 13.0), label, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 12, Color.WHITE)
