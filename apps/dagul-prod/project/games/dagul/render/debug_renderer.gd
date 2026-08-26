extends Node2D

const GunSig = preload("res://games/dagul/sim/gun_signature.gd")
const RenderEnvScript = preload("res://games/dagul/render/render_environment.gd")
const RenderHeroesScript = preload("res://games/dagul/render/render_heroes.gd")
const RenderProjScript = preload("res://games/dagul/render/render_projectiles.gd")
const RenderOverlayScript = preload("res://games/dagul/render/render_ui_overlay.gd")
const RenderWorldFxScript = preload("res://games/dagul/render/render_world_fx.gd")

var world
var colors := [Color.WHITE, Color("#5bc0eb"), Color("#9bc53d"), Color("#e55934"), Color("#fa7921"), Color("#b084cc"), Color("#ffe066"), Color("#70e7ff"), Color("#ff8dac"), Color("#c9f24d"), Color("#7ad7f0"), Color("#e8a87c")]


const ZODIAC_NAMES := ["쥐", "소", "호랑이", "토끼", "용", "뱀", "말", "양", "원숭이", "닭", "개", "돼지"]
const ZONE_RING := Color("#b44dff")
const ZONE_RING_HOT := Color("#e05cff")
const BULLET_YELLOW := Color("#ffd23f")

var zodiac_textures: Array = []
var grass_tile_textures: Array[Texture2D] = []
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
var unknown_character_tex: Texture2D = null
var bullet_atlas: Texture2D = null
var gun_atlas: Texture2D = null
var muzzle_atlas: Texture2D = null
var impact_atlas: Texture2D = null
var reload_bubble_atlas: Texture2D = null
var tracer_fx_atlas: Texture2D = null
var hit_spark_fx_atlas: Texture2D = null
var explosion_fx_atlas: Texture2D = null
var ammo_casing_texture: Texture2D = null
var world_casings: Array[Dictionary] = []
var world_casing_serial: int = 0
var mobility_fx_atlases: Dictionary = {}
var dash_departure_atlas: Texture2D = null
var rooster_beam_step_atlas: Texture2D = null
var character_shadow_tex: Texture2D = null
var knockout_trail_atlas: Texture2D = null
var death_burst_atlas: Texture2D = null
var zone_lightning_atlas: Texture2D = null
var zone_impact_atlas: Texture2D = null
var crate_orb_atlas: Texture2D = null
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
var _wfx


func _slot_color(index: int) -> Color:
    return colors[posmod(index, colors.size())]

func _ready() -> void:
    lite_draw = OS.has_feature("web")
    if lite_draw:
        RenderingServer.viewport_set_msaa_2d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_DISABLED)
    _load_world_textures()
    _load_fx_textures()
    _load_combat_textures()
    _load_hud_textures()
    _reset_recoil_state()
    _env = RenderEnvScript.new(self)
    _heroes = RenderHeroesScript.new(self)
    _proj = RenderProjScript.new(self)
    _overlay = RenderOverlayScript.new(self)
    _wfx = RenderWorldFxScript.new(self)

func _load_world_textures() -> void:
    for index in range(12):
        zodiac_textures.append(_load_tex("res://games/dagul/assets/sprites/zodiac_%02d.png" % (index + 1)))
    for grass_index in range(1, 9):
        var grass_texture := _load_tex("res://games/dagul/assets/world/Tex_BG_Tile_Grass_%d.png" % grass_index)
        if grass_texture != null:
            grass_tile_textures.append(grass_texture)
    tree_atlas = _load_tex("res://games/dagul/assets/world/Tex_BG_Trees_3x1.png")
    rock_atlas = _load_tex("res://games/dagul/assets/world/Tex_BG_Rocks_5x1.png")
    crate_atlas = _load_tex("res://games/dagul/assets/world/Tex_BG_Crates_4x1.png")
    tower_texture = _load_tex("res://games/dagul/assets/world/bounty-tower.png")

func _load_fx_textures() -> void:
    rat_run_tex = _load_tex("res://games/dagul/assets/fx/rat-run.png")
    dragon_smoke_tex = _load_tex("res://games/dagul/assets/fx/dragon-smoke.png")
    flee_icon_tex = _load_tex("res://games/dagul/assets/fx/flee-icon.png")
    rabbit_hole_tex = _load_tex("res://games/dagul/assets/fx/rabbit-hole.png")
    pig_mud_tex = _load_tex("res://games/dagul/assets/fx/pig-mud.png")
    dog_bone_tex = _load_tex("res://games/dagul/assets/fx/dog-bone.png")
    wool_shield_tex = _load_tex("res://games/dagul/assets/fx/sheep-wool-ring.png")
    finish_bg_tex = _load_tex("res://games/dagul/assets/fx/finish-bg.png")
    finish_glove_tex = _load_tex("res://games/dagul/assets/fx/finish-glove.png")
    roar_shader = load("res://games/dagul/assets/fx/roar_distort.gdshader") as Shader
    stun_spin_tex = _load_tex("res://games/dagul/assets/fx/stun-spin.png")
    for projectile_kind in PROJECTILE_TEXTURE_SIZES:
        projectile_textures[projectile_kind] = _load_tex("res://games/dagul/assets/fx/projectiles/projectile_%s.png" % projectile_kind)
    _load_mobility_textures()

func _load_mobility_textures() -> void:
    var mobility_files := {
        "speed_streak": "Tex_FX_MobilityDash_4x1.png", "beam_step": "Tex_FX_BeamStep_4x1.png",
        "drain": "Tex_FX_DrainStep_4x1.png", "guard": "Tex_FX_GuardStep_4x1.png",
        "slash_dash": "Tex_FX_SlashDash_4x1.png", "fuse": "Tex_FX_FuseStep_4x1.png",
        "spear_line": "Tex_FX_SpearStep_4x1.png", "chain_arc": "Tex_FX_ChainStep_4x1.png",
        "blast_hop": "Tex_FX_BlastHop_4x1.png",
    }
    for mobility_kind in mobility_files:
        mobility_fx_atlases[mobility_kind] = _load_tex("res://games/dagul/assets/fx/mobility/%s" % mobility_files[mobility_kind])
    dash_departure_atlas = _load_tex("res://games/dagul/assets/fx/mobility/Tex_FX_DashDeparture_4x1.png")
    rooster_beam_step_atlas = _load_tex("res://games/dagul/assets/fx/mobility/Tex_FX_RoosterBeamStep_4x1.png")
    character_shadow_tex = _load_tex("res://games/dagul/assets/fx/character/Tex_FX_CharacterShadow.png")
    knockout_trail_atlas = _load_tex("res://games/dagul/assets/fx/character/Tex_FX_KnockoutTrail_4x1.png")
    death_burst_atlas = _load_tex("res://games/dagul/assets/fx/character/Tex_FX_DeathBurst_6x1.png")
    zone_lightning_atlas = _load_tex("res://games/dagul/assets/fx/zone/Tex_FX_ZoneLightning_4x2.png")
    zone_impact_atlas = _load_tex("res://games/dagul/assets/fx/zone/Tex_FX_ZoneImpact_4x2.png")
    crate_orb_atlas = _load_tex("res://games/dagul/assets/fx/pickups/Tex_FX_CrateEnergyOrb_4x2.png")
    var ultimate_names := ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Sheep", "Monkey", "Rooster", "Dog", "Pig"]
    for ultimate_index in range(ultimate_names.size()):
        ultimate_fx_atlases[ultimate_index] = _load_tex("res://games/dagul/assets/fx/ultimates/Tex_FX_Ult_%s_4x2.png" % ultimate_names[ultimate_index])
    var emote_names := ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Sheep", "Monkey", "Rooster", "Dog", "Pig"]
    for emote_index in range(emote_names.size()):
        emote_atlases[emote_index] = _load_tex("res://games/dagul/assets/fx/emotes/Tex_UI_Emote_%s_4x1.png" % emote_names[emote_index])

func _load_combat_textures() -> void:
    gun_texture = _load_tex("res://games/dagul/assets/items/gun.png")
    medkit_texture = _load_tex("res://games/dagul/assets/items/medkit.png")
    animal_atlas = _load_tex("res://games/dagul/assets/lhj/Tex_Animal_4x3.png")
    animal_down_atlas = _load_tex("res://games/dagul/assets/lhj/Tex_AnimalDown_4x3.png")
    unknown_character_tex = _load_tex("res://core/assets/characters/unknown.png")
    bullet_atlas = _load_tex("res://games/dagul/assets/lhj/Tex_FX_Bullet_4x4_256x144.png")
    gun_atlas = _load_tex("res://games/dagul/assets/lhj/Tex_Gun_4x3.png")
    muzzle_atlas = _load_tex("res://games/dagul/assets/lhj/Tex_Fx_MuzzleFlash_4x3.png")
    impact_atlas = _load_tex("res://games/dagul/assets/lhj/Tex_Fx_ImpactFlash.png")
    tracer_fx_atlas = _load_tex("res://games/dagul/assets/fx/combat/Tex_FX_Tracer_4x1.png")
    hit_spark_fx_atlas = _load_tex("res://games/dagul/assets/fx/combat/Tex_FX_HitSpark_4x1.png")
    explosion_fx_atlas = _load_tex("res://games/dagul/assets/fx/combat/Tex_FX_Explosion_6x1.png")
    ammo_casing_texture = _load_tex("res://games/dagul/assets/fx/ui/Tex_UI_AmmoCasing.png")

func _load_hud_textures() -> void:
    reload_bubble_atlas = _load_tex("res://games/dagul/assets/fx/ui/Tex_FX_ReloadBubble_4x3.png")
    for icon_id in ["atk", "spd", "def", "hp", "rate", "range", "giant", "shield", "berserk", "turtle", "sniper", "double_giant"]:
        var icon_tex := _load_tex("res://games/dagul/assets/hud/roulette/%s.png" % icon_id)
        if icon_tex != null:
            roulette_icons[icon_id] = icon_tex
    turtle_body_tex = _load_tex("res://games/dagul/assets/hud/roulette/turtle_body.png")
    roulette_wheel_tex = _load_tex("res://games/dagul/assets/hud/roulette/wheel.png")
    roulette_wheel_rank["assist"] = _load_tex("res://games/dagul/assets/hud/roulette/wheel_assist.png")
    roulette_wheel_rank["kill"] = _load_tex("res://games/dagul/assets/hud/roulette/wheel_kill.png")
    roulette_wheel_rank["wanted"] = _load_tex("res://games/dagul/assets/hud/roulette/wheel_wanted.png")
    if roulette_wheel_rank.get("kill", null) == null:
        roulette_wheel_rank["kill"] = roulette_wheel_tex

func _load_tex(path: String) -> Texture2D:
    if not ResourceLoader.exists(path):
        return null
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
                    _wfx.world = world
                    _wfx.spawn_casing(slot)
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
            _consume_crate_hit(event)
        elif et == &"hero_heal":
            var hdata: Dictionary = event.get("data", {})
            var heal := float(hdata.get("heal", 0.0))
            var hslot := int(event.get("actor_id", -1))
            if hslot >= 0 and hslot < world.heroes.size() and heal > 0.4:
                _push_combat_text(Vector2(world.heroes[hslot]["pos"]), "+%d" % roundi(heal), Color("#6ef3a5"))
        elif et == &"hero_hit":
            _consume_hero_hit(event)


func _consume_crate_hit(event: Dictionary) -> void:
    var cdata: Dictionary = event.get("data", {})
    var cdmg := float(cdata.get("damage", 0.0))
    var cpos = cdata.get("pos", null)
    if typeof(cpos) != TYPE_VECTOR2:
        var ci := int(cdata.get("crate", -1))
        if ci >= 0 and ci < world.crates.size():
            cpos = world.crates[ci].get("pos", Vector2.ZERO)
    if typeof(cpos) == TYPE_VECTOR2 and cdmg > 0.4:
        _push_combat_text(cpos, "%d" % roundi(cdmg), Color("#ffd36a"))

func _consume_hero_hit(event: Dictionary) -> void:
    var hdata: Dictionary = event.get("data", {})
    if StringName(hdata.get("source", &"")) == &"safe_zone":
        return
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

func _zodiac_texture(animal: int) -> Texture2D:
    if zodiac_textures.is_empty():
        return null
    return zodiac_textures[posmod(animal, 12)]

func _animal_src_rect(animal: int) -> Rect2:
    var frame := int(ANIMAL_ATLAS_FRAME[posmod(animal, 12)])
    var cell := Vector2(float(animal_atlas.get_width()) / float(ANIMAL_COLS), float(animal_atlas.get_height()) / float(ANIMAL_ROWS))
    var col := frame % ANIMAL_COLS
    var row := int(frame / ANIMAL_COLS)
    return Rect2(Vector2(float(col), float(row)) * cell, cell)

func _animal_down_src_rect(animal: int) -> Rect2:
    if animal_down_atlas == null:
        return Rect2()
    var frame := int(ANIMAL_ATLAS_FRAME[posmod(animal, 12)])
    var cell := Vector2(float(animal_down_atlas.get_width()) / float(ANIMAL_COLS), float(animal_down_atlas.get_height()) / float(ANIMAL_ROWS))
    var col := frame % ANIMAL_COLS
    var row := int(frame / ANIMAL_COLS)
    return Rect2(Vector2(float(col), float(row)) * cell, cell)

func _zone_lightning_src_rect(frame: int) -> Rect2:
    if zone_lightning_atlas == null:
        return Rect2()
    var cell := Vector2(float(zone_lightning_atlas.get_width()) / 4.0, float(zone_lightning_atlas.get_height()) / 2.0)
    var safe_frame := posmod(frame, 8)
    return Rect2(Vector2(float(safe_frame % 4), float(safe_frame / 4)) * cell, cell)

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

func _zodiac_name(animal: int) -> String:
    return ZODIAC_NAMES[posmod(animal, 12)]

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
    if gun_atlas != null:
        var src := _gun_src_rect(int(vis.get("frame", 0)))
        var cell := Vector2(float(gun_atlas.get_width()) / 4.0, float(gun_atlas.get_height()) / 3.0)
        var world_s := 72.0 / (cell.x * GUN_TSCN_SCALE)
        draw_set_transform(mount, angle, Vector2(world_s, world_s * flip))
        var off := Vector2(float(vis.get("ox", 0.0)), float(vis.get("oy", 0.0)))
        var gun_rect := Rect2((-cell * 0.5 + off) * GUN_TSCN_SCALE, cell * GUN_TSCN_SCALE)
        draw_texture_rect_region(gun_atlas, gun_rect, src, Color(1.0, 1.0, 1.0, opacity))
        _draw_muzzle_flash(slot, vis, opacity)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    elif gun_texture != null:
        draw_set_transform(mount, angle, Vector2(1.0, flip))
        draw_texture_rect(gun_texture, Rect2(Vector2(-5.0, -9.0), Vector2(34.0, 18.0)), false, Color(1.0, 1.0, 1.0, opacity))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_muzzle_flash(slot: int, vis: Dictionary, opacity: float) -> void:
    const MUZZLE_LOCAL := Vector2(49.536, 0.0)
    const MUZZLE_TSCN_SCALE := 0.74175
    var hero_muzzle := 0.0
    var hero_mrow := 0
    if world != null and slot >= 0 and slot < world.heroes.size():
        hero_muzzle = float(world.heroes[slot].get("muzzle_time", 0.0))
        hero_mrow = int(world.heroes[slot].get("muzzle_row", 0))
    if muzzle_atlas == null or not (hero_muzzle > 0.0 or (slot >= 0 and slot < muzzle_life.size() and float(muzzle_life[slot]) > 0.0)):
        return
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
    var draw_size: Vector2 = Vector2(PROJECTILE_TEXTURE_SIZES[kind]) * size_scale
    draw_set_transform(pos, direction.angle(), Vector2.ONE)
    draw_texture_rect(texture, Rect2(Vector2(-draw_size.x * 0.72, -draw_size.y * 0.5), draw_size), false)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    return true

func _draw_projectiles() -> void: _proj.draw_projectiles_main()
func _draw_zones() -> void: _proj.draw_zones_main()
func _draw_effects() -> void: _proj.draw_effects_main()
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

func visible_world_rect() -> Rect2:
    return (get_viewport_transform().affine_inverse() * get_viewport_rect()).grow(192.0)

func _draw() -> void:
    if world == null:
        return
    _tick_draw_state()
    _draw_world_pass()
    _draw_actor_pass()


func _tick_draw_state() -> void:
    _consume_shot_events()
    _tick_recoil(1.0 / 60.0)
    _wfx.world = world
    _wfx.tick_casings(1.0 / 60.0)
    _tick_combat_texts(1.0 / 60.0)
    _env.world = world
    _heroes.world = world
    _proj.world = world
    _overlay.world = world


func _draw_world_pass() -> void:
    _env.draw_island()
    _env.draw_safe_zone()
    _env.draw_trees()
    _wfx.draw_casings()
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


func _draw_actor_pass() -> void:
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
    _wfx.draw_zone_impacts()
    _proj.draw_impact_flashes()
    _overlay.draw_finish_prompts()
    _heroes.draw_rat_tides()
    _heroes.draw_snake_skins()
    _heroes.draw_dragon_smokes()
    _proj.draw_combat_texts()
    _overlay.draw_finish_cine()
