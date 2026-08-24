extends Node2D

const GunSig = preload("res://scripts/sim/gun_signature.gd")
const RenderEnvScript = preload("res://scripts/render/render_environment.gd")
const RenderHeroesScript = preload("res://scripts/render/render_heroes.gd")
const RenderProjScript = preload("res://scripts/render/render_projectiles.gd")
const RenderOverlayScript = preload("res://scripts/render/render_ui_overlay.gd")

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

const ANIMAL_ATLAS_FRAME := [0, 1, 2, 3, 5, 4, 6, 7, 8, 9, 10, 11]
const ANIMAL_COLS := 4
const ANIMAL_ROWS := 3
const BULLET_COLS := 4
const BULLET_ROWS := 4

var _env
var _heroes
var _proj
var _overlay

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
    _env = RenderEnvScript.new(self)
    _heroes = RenderHeroesScript.new(self)
    _proj = RenderProjScript.new(self)
    _overlay = RenderOverlayScript.new(self)

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
                    cpos = world.crates[ci].get("pos", Vector2.ZERO)
            if typeof(cpos) == TYPE_VECTOR2 and cdmg > 0.4:
                _push_combat_text(cpos, "%d" % roundi(cdmg), Color("#ffd36a"))
        elif et == &"hero_heal":
            var hdata: Dictionary = event.get("data", {})
            var heal := float(hdata.get("heal", 0.0))
            var hslot := int(event.get("actor_id", -1))
            if hslot >= 0 and hslot < world.heroes.size() and heal > 0.4:
                _push_combat_text(Vector2(world.heroes[hslot]["pos"]), "+%d" % roundi(heal), Color("#6ef3a5"))
        elif et == &"hero_hit":
            var hdata: Dictionary = event.get("data", {})
            if StringName(hdata.get("source", &"")) == &"safe_zone":
                continue
            var hdmg := float(hdata.get("damage", 0.0))
            var htarget := int(hdata.get("target", -1))
            if htarget >= 0 and htarget < world.heroes.size() and hdmg > 0.4:
                var htpos: Vector2 = world.heroes[htarget]["pos"]
                _push_combat_text(htpos, "%d" % roundi(hdmg), Color("#ff5d73"))
                var hrow := 1
                var hid := "burst"
                var hactor := int(event.get("actor_id", -1))
                if hactor >= 0 and hactor < world.heroes.size():
                    var held = world.heroes[hactor].get("equipment", {})
                    if typeof(held) == TYPE_DICTIONARY:
                        hid = str(held.get("id", "burst"))
                var vis: Dictionary = GunSig.visual_for_equipment(hid)
                hrow = int(vis.get("impact_row", 1))
                impact_flashes.append({"pos":htpos, "row":hrow, "time":0.0})

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
        "pellet": row = 0
        "burst", "bolt": row = 1
        "shell": row = 2
        "seeker": row = 3
        _: row = 1
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

func _draw_hero_gun(pos: Vector2, slot: int, aim: Vector2, opacity: float = 1.0, extra_squash: float = 0.0) -> void:
    var equip_id := "burst"
    if slot < world.heroes.size():
        var held = world.heroes[slot].get("equipment", {})
        if typeof(held) == TYPE_DICTIONARY:
            equip_id = str(held.get("id", "burst"))
    var vis: Dictionary = GunSig.visual_for_equipment(equip_id)
    var gun_frame := int(vis.get("gun_frame", 0))
    var gun_scale := float(vis.get("gun_scale", 1.0))
    var muzzle_row := int(vis.get("muzzle_row", 0))
    var kick := 0.0
    var rot := 0.0
    var strap := 0.0
    var ml := 0.0
    if slot < recoil_kick.size():
        kick = float(recoil_kick[slot])
        rot = float(recoil_rot[slot])
        strap = float(recoil_strap[slot])
        ml = float(muzzle_life[slot])
    var flip: float = -1.0 if aim.x < -0.05 else 1.0
    var ang := aim.angle()
    var base_offset := Vector2(28.0, 8.0)
    var recoil_offset := Vector2(-kick * 3.8, strap * 0.7)
    var gun_pos := pos + base_offset.rotated(ang) * Vector2(flip, 1.0) + recoil_offset.rotated(ang)
    var squash_scale := Vector2(1.0 + extra_squash * 0.4, 1.0 - extra_squash * 0.3)
    if gun_atlas != null:
        draw_set_transform(gun_pos, ang + rot * flip, Vector2(flip * gun_scale, gun_scale) * squash_scale)
        draw_texture_rect_region(gun_atlas, Rect2(Vector2(-36.0, -20.0), Vector2(72.0, 40.0)), _gun_src_rect(gun_frame), Color(1.0, 1.0, 1.0, opacity))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    else:
        draw_line(pos, gun_pos, Color(_slot_color(slot), opacity), 5.0)
        draw_circle(gun_pos, 6.0, Color(_slot_color(slot), opacity))
    if ml > 0.0 and muzzle_atlas != null:
        var muzzle_pos := gun_pos + Vector2(32.0 * gun_scale, 0.0).rotated(ang)
        var frame_count := [2, 3, 4]
        var n: int = int(frame_count[clampi(muzzle_row, 0, 2)])
        var max_time := feel_muzzle_max(muzzle_row)
        var col := clampi(int((1.0 - ml / max_time) * float(n)), 0, n - 1)
        var mscale := lerpf(1.4, 0.9, 1.0 - ml / max_time)
        draw_set_transform(muzzle_pos, ang, Vector2(flip * mscale, mscale))
        draw_texture_rect_region(muzzle_atlas, Rect2(Vector2(-38.0, -38.0), Vector2(76.0, 76.0)), _muzzle_src_rect(muzzle_row, col), Color(1.0, 1.0, 1.0, opacity))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _push_combat_text(pos: Vector2, text: String, color: Color) -> void:
    combat_texts.append({"pos":pos, "text":text, "color":color, "time":0.0})

func _tick_combat_texts(dt: float) -> void:
    var keep: Array = []
    for ct in combat_texts:
        ct["time"] = float(ct["time"]) + dt
        if float(ct["time"]) < 0.75:
            keep.append(ct)
    combat_texts = keep

func _draw() -> void:
    if world == null:
        return
    _consume_shot_events()
    _tick_recoil(1.0 / 60.0)
    _tick_combat_texts(1.0 / 60.0)
    _env.world = world
    _heroes.world = world
    _proj.world = world
    _overlay.world = world
    _env.draw_island()
    _env.draw_safe_zone()
    _env.draw_covers()
    _env.draw_crates()
    _env.draw_mid_tower()
    _env.draw_crate_orbs()
    _env.draw_pickups()
    _env.draw_cores()
    _proj.draw_deployables()
    _proj.draw_zones()
    _proj.draw_projectiles()
    _proj.draw_impact_flashes()
    _proj.draw_effects()
    _heroes.draw_knockouts()
    _overlay.draw_pocket_bubbles()
    _heroes.draw_dog_bones()
    _heroes.draw_wool_shields()
    _heroes.draw_pig_muds()
    _heroes.draw_rooster_eggs()
    _heroes.draw_horse_kicks()
    _heroes.draw_rabbit_holes()
    _heroes.draw_tiger_roars()
    _heroes.draw_heroes()
    _overlay.draw_finish_prompts()
    _heroes.draw_rat_tides()
    _heroes.draw_snake_skins()
    _heroes.draw_dragon_smokes()
    _proj.draw_combat_texts()
    _overlay.draw_finish_cine()
