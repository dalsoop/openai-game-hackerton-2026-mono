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
var dirt_tile_texture: Texture2D = null
var tree_atlas: Texture2D = null
var rock_atlas: Texture2D = null
var crate_atlas: Texture2D = null
var projectile_textures: Dictionary = {}
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
var animal_down_atlas: Texture2D = null
var bullet_atlas: Texture2D = null
var gun_atlas: Texture2D = null
var muzzle_atlas: Texture2D = null
var impact_atlas: Texture2D = null
var reload_bubble_atlas: Texture2D = null
var tracer_fx_atlas: Texture2D = null
var hit_spark_fx_atlas: Texture2D = null
var explosion_fx_atlas: Texture2D = null
var ammo_casing_texture: Texture2D = null
var mobility_fx_atlases: Dictionary = {}
var dash_departure_atlas: Texture2D = null
var rooster_beam_step_atlas: Texture2D = null
var character_shadow_tex: Texture2D = null
var knockout_trail_atlas: Texture2D = null
var death_burst_atlas: Texture2D = null
var zone_lightning_atlas: Texture2D = null
var zone_impact_atlas: Texture2D = null
var ultimate_fx_atlases: Dictionary = {}
var emote_atlases: Dictionary = {}
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
var world_casings: Array[Dictionary] = []
var world_casing_serial: int = 0

const ANIMAL_ATLAS_FRAME := [0, 1, 2, 3, 5, 4, 6, 7, 8, 9, 10, 11]
const ANIMAL_COLS := 4
const ANIMAL_ROWS := 3
const BULLET_COLS := 4
const BULLET_ROWS := 4
const ROCK_SOURCE_RECTS := [
    Rect2(136.0, 205.0, 169.0, 157.0),
    Rect2(510.0, 158.0, 274.0, 227.0),
    Rect2(927.0, 204.0, 329.0, 175.0),
    Rect2(1380.0, 178.0, 283.0, 201.0),
    Rect2(1743.0, 94.0, 411.0, 297.0),
]
const CRATE_SOURCE_RECTS := [
    Rect2(28.0, 16.0, 344.0, 374.0),
    Rect2(442.0, 20.0, 342.0, 374.0),
    Rect2(848.0, 34.0, 340.0, 362.0),
    Rect2(1242.0, 116.0, 342.0, 262.0),
]
const PROJECTILE_TEXTURE_SIZES := {
    "beam": Vector2(180.0, 42.0), "shell": Vector2(54.0, 28.0),
    "tether": Vector2(50.0, 26.0), "seeker": Vector2(46.0, 30.0),
    "slash": Vector2(66.0, 48.0), "fist": Vector2(68.0, 38.0),
    "bomb": Vector2(34.0, 38.0), "spear": Vector2(106.0, 28.0),
    "chain": Vector2(72.0, 30.0), "shield": Vector2(52.0, 48.0),
}

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
    island_texture = _load_tex("res://assets/world/Tex_BG_Tile_Grass.png")
    dirt_tile_texture = _load_tex("res://assets/world/Tex_BG_Tile_Dirt.png")
    tree_atlas = _load_tex("res://assets/world/Tex_BG_Trees_3x1.png")
    texture_filter = TEXTURE_FILTER_NEAREST
    print("[gangup] rpg tiles grass=%s dirt=%s trees=%s" % [island_texture != null, dirt_tile_texture != null, tree_atlas != null])
    rock_atlas = _load_tex("res://assets/world/Tex_BG_Rocks_5x1.png")
    crate_atlas = _load_tex("res://assets/world/Tex_BG_Crates_4x1.png")
    reload_bubble_atlas = _load_tex("res://assets/fx/ui/Tex_FX_ReloadBubble_4x3.png")
    for projectile_kind in PROJECTILE_TEXTURE_SIZES:
        projectile_textures[projectile_kind] = _load_tex("res://assets/fx/projectiles/projectile_%s.png" % projectile_kind)
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
    animal_down_atlas = _load_tex("res://assets/lhj/Tex_AnimalDown_4x3.png")
    bullet_atlas = _load_tex("res://assets/lhj/Tex_FX_Bullet_4x4_256x144.png")
    gun_atlas = _load_tex("res://assets/lhj/Tex_Gun_4x3.png")
    muzzle_atlas = _load_tex("res://assets/lhj/Tex_Fx_MuzzleFlash_4x3.png")
    impact_atlas = _load_tex("res://assets/lhj/Tex_Fx_ImpactFlash.png")
    tracer_fx_atlas = _load_tex("res://assets/fx/combat/Tex_FX_Tracer_4x1.png")
    hit_spark_fx_atlas = _load_tex("res://assets/fx/combat/Tex_FX_HitSpark_4x1.png")
    explosion_fx_atlas = _load_tex("res://assets/fx/combat/Tex_FX_Explosion_6x1.png")
    ammo_casing_texture = _load_tex("res://assets/fx/ui/Tex_UI_AmmoCasing.png")
    var mobility_files := {
        "speed_streak": "Tex_FX_MobilityDash_4x1.png", "beam_step": "Tex_FX_BeamStep_4x1.png",
        "drain": "Tex_FX_DrainStep_4x1.png", "guard": "Tex_FX_GuardStep_4x1.png",
        "slash_dash": "Tex_FX_SlashDash_4x1.png", "fuse": "Tex_FX_FuseStep_4x1.png",
        "spear_line": "Tex_FX_SpearStep_4x1.png", "chain_arc": "Tex_FX_ChainStep_4x1.png",
        "blast_hop": "Tex_FX_BlastHop_4x1.png",
    }
    for mobility_kind in mobility_files:
        mobility_fx_atlases[mobility_kind] = _load_tex("res://assets/fx/mobility/%s" % mobility_files[mobility_kind])
    dash_departure_atlas = _load_tex("res://assets/fx/mobility/Tex_FX_DashDeparture_4x1.png")
    rooster_beam_step_atlas = _load_tex("res://assets/fx/mobility/Tex_FX_RoosterBeamStep_4x1.png")
    character_shadow_tex = _load_tex("res://assets/fx/character/Tex_FX_CharacterShadow.png")
    knockout_trail_atlas = _load_tex("res://assets/fx/character/Tex_FX_KnockoutTrail_4x1.png")
    death_burst_atlas = _load_tex("res://assets/fx/character/Tex_FX_DeathBurst_6x1.png")
    zone_lightning_atlas = _load_tex("res://assets/fx/zone/Tex_FX_ZoneLightning_4x2.png")
    zone_impact_atlas = _load_tex("res://assets/fx/zone/Tex_FX_ZoneImpact_4x2.png")
    var ultimate_names := ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Sheep", "Monkey", "Rooster", "Dog", "Pig"]
    for ultimate_index in range(ultimate_names.size()):
        ultimate_fx_atlases[ultimate_index] = _load_tex("res://assets/fx/ultimates/Tex_FX_Ult_%s_4x2.png" % ultimate_names[ultimate_index])
    var emote_names := ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Sheep", "Monkey", "Rooster", "Dog", "Pig"]
    for emote_index in range(emote_names.size()):
        emote_atlases[emote_index] = _load_tex("res://assets/fx/emotes/Tex_UI_Emote_%s_4x1.png" % emote_names[emote_index])
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
        print("[gangup] tex raw %s %sx%s" % [path, img.get_width(), img.get_height()])
        return ImageTexture.create_from_image(img)
    print("[gangup] tex miss %s" % path)
    return null

func _ultimate_src_rect(texture: Texture2D, frame: int, row: int = 0) -> Rect2:
    if texture == null:
        return Rect2()
    var cell := Vector2(float(texture.get_width()) / 4.0, float(texture.get_height()) / 2.0)
    return Rect2(Vector2(float(clampi(frame, 0, 3)), float(clampi(row, 0, 1))) * cell, cell)

func draw_ultimate_frame(animal: int, pos: Vector2, size: Vector2, frame: int, row: int = 0, rotation: float = 0.0, alpha: float = 1.0) -> bool:
    var texture: Texture2D = ultimate_fx_atlases.get(posmod(animal, 12), null)
    if texture == null:
        return false
    draw_set_transform(pos, rotation, Vector2.ONE)
    draw_texture_rect_region(texture, Rect2(-size * 0.5, size), _ultimate_src_rect(texture, frame, row), Color(1.0, 1.0, 1.0, alpha))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    return true

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

func _horizontal_fx_src_rect(texture: Texture2D, columns: int, frame: int) -> Rect2:
    var cell := Vector2(float(texture.get_width()) / float(columns), float(texture.get_height()))
    return Rect2(Vector2(float(clampi(frame, 0, columns - 1)) * cell.x, 0.0), cell)

func _mobility_fx_texture(kind: StringName, label: String) -> Texture2D:
    if kind == &"guard" and label not in ["IRON MARCH", "BRACE STEP"]:
        return null
    if kind == &"drain" and label != "+8 SHADOW PULL":
        return null
    if kind == &"fuse" and label != "BLAST ROLL":
        return null
    return mobility_fx_atlases.get(str(kind)) as Texture2D

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
                if et == &"gun_fire":
                    _spawn_world_casing(slot)
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

func _world_casing_size(equipment_id: String) -> Vector2:
    var family := GunSig.family_of(equipment_id)
    match family:
        "pistol":
            return Vector2(10.0, 7.0)
        "smg":
            return Vector2(12.0, 8.0)
        "shotgun":
            return Vector2(16.0, 11.0)
        "heavy":
            return Vector2(18.0, 12.0)
        _:
            return Vector2(14.0, 9.0)

func _spawn_world_casing(slot: int) -> void:
    if slot < 0 or slot >= world.heroes.size():
        return
    var hero: Dictionary = world.heroes[slot]
    if not bool(hero.get("alive", false)):
        return
    var aim := Vector2(hero.get("aim", Vector2.RIGHT))
    if aim.length_squared() < 0.0001:
        aim = Vector2.RIGHT
    aim = aim.normalized()
    var side := Vector2(-aim.y, aim.x)
    var equipment: Dictionary = hero.get("equipment", {})
    var equipment_id := str(equipment.get("id", "burst"))
    world_casing_serial += 1
    var seed := fposmod(float(world_casing_serial * 37), 101.0) / 101.0
    world_casings.append({
        "pos": Vector2(hero.get("pos", Vector2.ZERO)) + aim * 24.0 + side * (7.0 + seed * 5.0),
        "aim": aim,
        "age": 0.0,
        "seed": seed,
        "spin": 1.5 + fposmod(float(world_casing_serial * 23), 100.0) / 100.0,
        "clockwise": 1.0 if world_casing_serial % 2 == 0 else -1.0,
        "size": _world_casing_size(equipment_id),
    })
    while world_casings.size() > 48:
        world_casings.pop_front()

func _tick_world_casings(dt: float) -> void:
    var alive: Array[Dictionary] = []
    for casing in world_casings:
        casing["age"] = float(casing.get("age", 0.0)) + dt
        if float(casing["age"]) < 0.95:
            alive.append(casing)
    world_casings = alive

func _draw_world_casings() -> void:
    for casing in world_casings:
        var age := float(casing.get("age", 0.0))
        var seed := float(casing.get("seed", 0.0))
        var aim := Vector2(casing.get("aim", Vector2.RIGHT))
        var origin := Vector2(casing.get("pos", Vector2.ZERO))
        var velocity := aim * (110.0 + seed * 34.0) + Vector2(0.0, -90.0 - seed * 24.0)
        var pos := origin + velocity * age + Vector2(0.0, 180.0 * age * age)
        var rotation := float(casing.get("clockwise", 1.0)) * TAU * float(casing.get("spin", 2.0)) * age + seed * TAU
        var alpha := 0.72 * (1.0 - clampf((age - 0.58) / 0.37, 0.0, 1.0))
        var casing_size := Vector2(casing.get("size", Vector2(14.0, 9.0)))
        draw_set_transform(pos, rotation, Vector2.ONE)
        if ammo_casing_texture != null:
            draw_texture_rect_region(ammo_casing_texture, Rect2(-casing_size * 0.5, casing_size), Rect2(240.0, 280.0, 800.0, 680.0), Color(1.0, 1.0, 1.0, alpha))
        else:
            draw_rect(Rect2(-casing_size * 0.5, casing_size), Color(0.95, 0.64, 0.18, alpha))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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

func _animal_down_src_rect(slot: int) -> Rect2:
    if animal_down_atlas == null:
        return Rect2()
    var frame := int(ANIMAL_ATLAS_FRAME[posmod(slot, 12)])
    var cell := Vector2(float(animal_down_atlas.get_width()) / float(ANIMAL_COLS), float(animal_down_atlas.get_height()) / float(ANIMAL_ROWS))
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

func _zone_lightning_src_rect(frame: int) -> Rect2:
    if zone_lightning_atlas == null:
        return Rect2()
    var cell := Vector2(float(zone_lightning_atlas.get_width()) / 4.0, float(zone_lightning_atlas.get_height()) / 2.0)
    var safe_frame := posmod(frame, 8)
    return Rect2(Vector2(float(safe_frame % 4), float(safe_frame / 4)) * cell, cell)

func _zone_impact_src_rect(frame: int) -> Rect2:
    if zone_impact_atlas == null:
        return Rect2()
    var cell := Vector2(float(zone_impact_atlas.get_width()) / 4.0, float(zone_impact_atlas.get_height()) / 2.0)
    var safe_frame := clampi(frame, 0, 7)
    return Rect2(Vector2(float(safe_frame % 4), float(safe_frame / 4)) * cell, cell)

func _draw_lhj_bullet(projectile_pos: Vector2, direction: Vector2, kind: String, scale: float = 1.0) -> void:
    if bullet_atlas == null:
        return
    var dir := direction if direction.length_squared() > 0.0001 else Vector2.RIGHT
    var src := _bullet_src_rect(kind, int(world.tick))
    var dest := Rect2(Vector2(-28.0, -10.0) * scale * 3.0, Vector2(56.0, 20.0) * scale * 3.0)
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

func _push_combat_text(pos: Vector2, text: String, color: Color) -> void:
    combat_texts.append({"pos":pos, "text":text, "color":color, "time":0.0})

func _tick_combat_texts(dt: float) -> void:
    var keep: Array = []
    for ct in combat_texts:
        ct["time"] = float(ct["time"]) + dt
        if float(ct["time"]) < 0.75:
            keep.append(ct)
    combat_texts = keep

func _draw_projectile_texture(pos: Vector2, direction: Vector2, kind: String, size_scale: float = 1.0) -> bool:
    var texture: Texture2D = projectile_textures.get(kind) as Texture2D
    if texture == null or not PROJECTILE_TEXTURE_SIZES.has(kind):
        return false
    var draw_size: Vector2 = Vector2(PROJECTILE_TEXTURE_SIZES[kind]) * size_scale * 3.0
    draw_set_transform(pos, direction.angle(), Vector2.ONE)
    draw_texture_rect(texture, Rect2(Vector2(-draw_size.x * 0.72, -draw_size.y * 0.5), draw_size), false)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    return true

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
            if not _draw_projectile_texture(projectile_pos, direction, "bomb", bomb_scale):
                draw_circle(projectile_pos, 11.0 * bomb_scale, Color("#2c1115"))
                draw_arc(projectile_pos, 13.0 * bomb_scale, 0.0, TAU, 22, Color("#ff6b4a"), 4.0)
            draw_circle(landing, float(projectile["splash"]), Color(0.35, 0.04, 0.03, 0.07))
            draw_arc(landing, float(projectile["splash"]) * lerpf(1.0, 0.78, arc_progress), 0.0, TAU, 36, Color(1.0, 0.34, 0.22, 0.68), 3.0)
            continue
        if kind in ["shell", "seeker", "bomb"]:
            _draw_dashed_tracer(projectile_pos, direction, BULLET_YELLOW, 4.0)
        if _draw_projectile_texture(projectile_pos, direction, kind):
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
                var tracer_end := projectile_pos + direction * 28.0
                if tracer_fx_atlas != null:
                    var tracer_length := clampf(origin.distance_to(tracer_end), 96.0, 240.0)
                    var tracer_center := origin.lerp(tracer_end, 0.5)
                    var tracer_frame := posmod(int(world.tick / 2), 4)
                    draw_set_transform(tracer_center, direction.angle(), Vector2.ONE)
                    draw_texture_rect_region(tracer_fx_atlas, Rect2(Vector2(-tracer_length * 0.5, -28.0), Vector2(tracer_length, 56.0)), _horizontal_fx_src_rect(tracer_fx_atlas, 4, tracer_frame))
                    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                else:
                    draw_line(origin, tracer_end, Color(1.0, 1.0, 1.0, 0.22), 10.0)
                    draw_line(origin, tracer_end, Color(1.0, 0.95, 0.75, 0.95), 3.0)
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
        if effect_kind == &"zone_impact" and zone_impact_atlas != null:
            continue
        var direction := Vector2(effect["direction"]).normalized()
        var progress := 1.0 - ratio
        var follow_slot := int(effect.get("follow_slot", -1))
        var effect_label := str(effect.get("label", ""))
        var ultimate_effect_animal := -1
        match effect_kind:
            &"snake_pop":
                ultimate_effect_animal = 5
            &"sheep_pop":
                ultimate_effect_animal = 7
            &"monkey_pop":
                ultimate_effect_animal = 8
            &"rooster_burst":
                ultimate_effect_animal = 9
        if ultimate_effect_animal >= 0:
            var ultimate_frame := clampi(int(progress * 4.0), 0, 3)
            draw_ultimate_frame(ultimate_effect_animal, effect_pos, Vector2.ONE * effect_radius * 2.35, ultimate_frame, 1, direction.angle(), clampf(ratio * 1.25, 0.0, 1.0))
            continue
        var mobility_texture := _mobility_fx_texture(effect_kind, effect_label)
        if effect_label == "SIGHTLINE STEP" and effect_kind == &"beam_step" and rooster_beam_step_atlas != null:
            mobility_texture = rooster_beam_step_atlas
        if mobility_texture != null:
            var mobility_frame := clampi(int(progress * 4.0), 0, 3)
            var mobility_alpha := clampf(ratio * 1.20 + 0.18, 0.18, 1.0)
            var directional := effect_kind in [&"speed_streak", &"beam_step", &"slash_dash", &"spear_line", &"chain_arc", &"blast_hop"]
            var mobility_size := Vector2(effect_radius * 1.25, clampf(effect_radius * 0.62, 72.0, 168.0)) if directional else Vector2.ONE * effect_radius * 2.15
            if effect_label in ["IRON MARCH", "BRACE STEP"]:
                mobility_size *= 1.35
            var start_pos: Vector2 = effect.get("start_pos", effect_pos)
            if dash_departure_atlas != null and bool(effect.get("draw_departure", true)):
                var departure_size := Vector2.ONE * clampf(effect_radius * 0.55, 84.0, 138.0)
                draw_set_transform(start_pos, 0.0, Vector2.ONE)
                draw_texture_rect_region(dash_departure_atlas, Rect2(-departure_size * 0.5, departure_size), _horizontal_fx_src_rect(dash_departure_atlas, 4, mobility_frame), Color(effect_color, mobility_alpha))
                draw_texture_rect_region(dash_departure_atlas, Rect2(-departure_size * 0.5, departure_size), _horizontal_fx_src_rect(dash_departure_atlas, 4, mobility_frame), Color(effect_color, mobility_alpha * 0.65))
            if follow_slot >= 0 and follow_slot < world.heroes.size():
                effect_pos = Vector2(world.heroes[follow_slot].get("pos", effect_pos))
            if effect_label == "SIGHTLINE STEP":
                effect_pos += direction * 58.0
            var mobility_angle := direction.angle() + (PI if effect_label == "SHADOW SHEATH" else 0.0)
            draw_set_transform(effect_pos, mobility_angle, Vector2.ONE)
            draw_texture_rect_region(mobility_texture, Rect2(-mobility_size * 0.5, mobility_size), _horizontal_fx_src_rect(mobility_texture, 4, mobility_frame), Color(1.0, 1.0, 1.0, mobility_alpha))
            draw_texture_rect_region(mobility_texture, Rect2(-mobility_size * 0.5, mobility_size), _horizontal_fx_src_rect(mobility_texture, 4, mobility_frame), Color(1.0, 1.0, 1.0, mobility_alpha * 0.65))
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
            continue
        match effect_kind:
            &"line", &"beam_hit", &"beam_step":
                var line_start := effect_pos - direction * effect_radius * (0.75 if effect_kind == &"beam_hit" else 1.0)
                var line_end := effect_pos + direction * effect_radius * (0.65 if effect_kind == &"beam_hit" else 0.05)
                draw_line(line_start, line_end, Color(effect_color, ratio * 0.34), 26.0 * ratio + 5.0)
                draw_line(line_start, line_end, Color.WHITE, 4.0 * ratio + 1.5)
            &"explosion":
                if explosion_fx_atlas != null:
                    var explosion_frame := clampi(int(progress * 6.0), 0, 5)
                    var explosion_size := Vector2.ONE * effect_radius * 2.35
                    draw_texture_rect_region(explosion_fx_atlas, Rect2(effect_pos - explosion_size * 0.5, explosion_size), _horizontal_fx_src_rect(explosion_fx_atlas, 6, explosion_frame))
                else:
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
            &"wall_impact", &"hit_spark", &"impact":
                if effect_kind in [&"hit_spark", &"impact"] and hit_spark_fx_atlas != null:
                    var hit_frame := clampi(int(progress * 4.0), 0, 3)
                    var hit_size := Vector2.ONE * effect_radius * 2.1
                    draw_set_transform(effect_pos, direction.angle(), Vector2.ONE)
                    draw_texture_rect_region(hit_spark_fx_atlas, Rect2(-hit_size * 0.5, hit_size), _horizontal_fx_src_rect(hit_spark_fx_atlas, 4, hit_frame))
                    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                else:
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
                if death_burst_atlas != null:
                    var death_frame := clampi(int(progress * 6.0), 0, 5)
                    var death_size := effect_radius * lerpf(0.72, 2.05, progress)
                    var death_rect := Rect2(effect_pos - Vector2.ONE * death_size * 0.5, Vector2.ONE * death_size)
                    draw_texture_rect_region(death_burst_atlas, death_rect, _horizontal_fx_src_rect(death_burst_atlas, 6, death_frame), Color(1.0, 1.0, 1.0, ratio))
                else:
                    var death_radius := effect_radius * lerpf(0.16, 1.10, progress)
                    draw_circle(effect_pos, death_radius * 0.52, Color("#48030b", ratio * 0.82))
                    draw_arc(effect_pos, death_radius, 0.0, TAU, 54, Color("#ff3349", ratio), 16.0)
                    draw_line(effect_pos - Vector2.ONE * death_radius * 0.72, effect_pos + Vector2.ONE * death_radius * 0.72, Color.WHITE, ratio, 12.0)
                    draw_line(effect_pos + Vector2(-1.0, 1.0) * death_radius * 0.72, effect_pos + Vector2(1.0, -1.0) * death_radius * 0.72, Color.WHITE, ratio, 12.0)
            &"guard":
                draw_arc(effect_pos, effect_radius, -PI * 0.8, PI * 0.8, 28, Color(effect_color, ratio), 9.0)
                draw_arc(effect_pos, effect_radius - 12.0, -PI * 0.8, PI * 0.8, 28, Color(Color.WHITE, ratio * 0.8), 3.0)
            &"heal_pickup":
                var heal_lift := progress * effect_radius * 0.68
                var cross_center := effect_pos + Vector2(0.0, -heal_lift)
                var strong_ratio := clampf(1.0 - progress * 0.72, 0.34, 1.0)
                var cross_color := Color(effect_color, strong_ratio)
                draw_rect(Rect2(cross_center + Vector2(-18.0, -6.0), Vector2(36.0, 12.0)), Color(effect_color, strong_ratio * 0.38))
                draw_rect(Rect2(cross_center + Vector2(-6.0, -18.0), Vector2(12.0, 36.0)), Color(effect_color, strong_ratio * 0.38))
                draw_rect(Rect2(cross_center + Vector2(-15.0, -5.0), Vector2(30.0, 10.0)), cross_color)
                draw_rect(Rect2(cross_center + Vector2(-5.0, -15.0), Vector2(10.0, 30.0)), cross_color)
                draw_rect(Rect2(cross_center + Vector2(-6.0, -6.0), Vector2(12.0, 12.0)), Color(Color.WHITE, strong_ratio * 0.90))
                var burst_radius := effect_radius * lerpf(0.20, 0.88, progress)
                draw_arc(effect_pos, burst_radius, 0.0, TAU, 24, Color(effect_color, strong_ratio * 0.76), 6.0)
                for heal_pixel in range(10):
                    var heal_angle := TAU * float(heal_pixel) / 10.0 + progress * 1.7
                    var heal_pos := effect_pos + Vector2.RIGHT.rotated(heal_angle) * effect_radius * lerpf(0.20, 0.82, progress)
                    var heal_size := 7.0 if heal_pixel % 3 == 0 else 4.0
                    draw_rect(Rect2(heal_pos - Vector2.ONE * heal_size * 0.5, Vector2.ONE * heal_size), Color(effect_color, strong_ratio * 0.92))
            &"heal_ready":
                var ready_radius := effect_radius * lerpf(0.48, 0.88, progress)
                for ready_pixel in range(12):
                    if ready_pixel in [2, 3, 8, 9]:
                        continue
                    var ready_angle := TAU * float(ready_pixel) / 12.0
                    var ready_pos := effect_pos + Vector2.RIGHT.rotated(ready_angle) * ready_radius
                    draw_rect(Rect2(ready_pos - Vector2.ONE * 3.0, Vector2.ONE * 6.0), Color(effect_color, ratio))
            &"zone_impact":
                var impact_scale := lerpf(0.34, 1.16, progress)
                var impact_alpha := clampf(1.0 - progress * 0.74, 0.26, 1.0)
                for impact_arc in range(8):
                    var arc_angle := TAU * float(impact_arc) / 8.0 + float(posmod(impact_arc * 7 + int(world.tick / 2), 5)) * 0.08
                    var radial := Vector2.RIGHT.rotated(arc_angle)
                    var tangent := radial.orthogonal()
                    var arc_start := effect_pos + radial * effect_radius * 0.22 * impact_scale
                    var points := PackedVector2Array([
                        arc_start,
                        arc_start + radial * effect_radius * 0.18 + tangent * (7.0 if impact_arc % 2 == 0 else -7.0),
                        arc_start + radial * effect_radius * 0.38 - tangent * 5.0,
                        arc_start + radial * effect_radius * 0.62 + tangent * (9.0 if impact_arc % 3 == 0 else -4.0),
                    ])
                    draw_polyline(points, Color("#7920bd", impact_alpha * 0.62), 8.0)
                    draw_polyline(points, Color("#f0c8ff", impact_alpha), 3.0)
                draw_arc(effect_pos, effect_radius * impact_scale * 0.72, 0.0, TAU, 28, Color(effect_color, impact_alpha * 0.82), 7.0)
                draw_arc(effect_pos, effect_radius * impact_scale * 0.48, 0.0, TAU, 20, Color("#ffffff", impact_alpha * 0.72), 3.0)
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

func _draw_zone_impacts_foreground() -> void:
    if zone_impact_atlas == null:
        return
    for effect in world.effects:
        if StringName(effect.get("kind", &"")) != &"zone_impact":
            continue
        var ratio := clampf(float(effect["time"]) / maxf(0.001, float(effect["max_time"])), 0.0, 1.0)
        var progress := 1.0 - ratio
        var effect_pos: Vector2 = effect["pos"]
        var follow_slot := int(effect.get("follow_slot", -1))
        if follow_slot >= 0 and follow_slot < world.heroes.size():
            effect_pos = Vector2(world.heroes[follow_slot].get("pos", effect_pos))
        var frame := clampi(int(progress * 8.0), 0, 7)
        var size := Vector2.ONE * 164.0
        var alpha := clampf(ratio * 1.35, 0.24, 1.0)
        draw_set_transform(effect_pos, 0.0, Vector2.ONE)
        draw_texture_rect_region(zone_impact_atlas, Rect2(-size * 0.5, size), _zone_impact_src_rect(frame), Color(1.0, 1.0, 1.0, alpha))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_blob_shadow(ground_pos: Vector2, hop_lift: float, opacity: float) -> void:
    var height_t: float = clampf(hop_lift / 19.0, 0.0, 1.0)
    var size_mul: float = lerpf(1.0, 0.52, height_t)
    var alpha_mul: float = lerpf(1.0, 0.38, height_t)
    var radius_x: float = 26.0 * size_mul
    var radius_y: float = 11.5 * size_mul
    var center: Vector2 = ground_pos + Vector2(1.5, 34.0)
    draw_set_transform(center, 0.0, Vector2(1.0, radius_y / radius_x))
    var rings: Array = [
        [1.00, 0.07], [0.88, 0.10], [0.74, 0.13],
        [0.58, 0.16], [0.40, 0.17], [0.22, 0.14]
    ]
    for ring in rings:
        draw_circle(Vector2.ZERO, radius_x * float(ring[0]), Color(0.0, 0.0, 0.0, float(ring[1]) * alpha_mul * opacity))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw() -> void:
    if world == null:
        return
    _consume_shot_events()
    _tick_recoil(1.0 / 60.0)
    _tick_world_casings(1.0 / 60.0)
    _tick_combat_texts(1.0 / 60.0)
    _env.world = world
    _heroes.world = world
    _proj.world = world
    _overlay.world = world
    _env.draw_island()
    _env.draw_safe_zone()
    _env.draw_trees()
    _draw_world_casings()
    _env.draw_covers()
    _env.draw_crates()
    _env.draw_mid_tower()
    _env.draw_crate_orbs()
    _env.draw_pickups()
    _env.draw_cores()
    _proj.draw_deployables()
    _draw_zones()
    _draw_projectiles()
    _draw_effects()
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
    _draw_zone_impacts_foreground()
    _proj.draw_impact_flashes()
    _overlay.draw_finish_prompts()
    _heroes.draw_rat_tides()
    _heroes.draw_snake_skins()
    _heroes.draw_dragon_smokes()
    _proj.draw_combat_texts()
    _overlay.draw_finish_cine()
