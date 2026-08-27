extends Node2D

const GunSig = preload("res://games/dagul/sim/gun_signature.gd")
const RenderEnvScript = preload("res://games/dagul/render/render_environment.gd")
const RenderHeroesScript = preload("res://games/dagul/render/render_heroes.gd")
const RenderProjScript = preload("res://games/dagul/render/render_projectiles.gd")
const RenderOverlayScript = preload("res://games/dagul/render/render_ui_overlay.gd")
const RenderWorldFxScript = preload("res://games/dagul/render/render_world_fx.gd")
const RenderHeroLayerScript = preload("res://games/dagul/render/render_hero_layer.gd")
const RenderFxLayerScript = preload("res://games/dagul/render/render_fx_layer.gd")
const BgLayerScript = preload("res://games/dagul/render/background_layer.gd")

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
var _hero_layer
var _fx_layer
var _bg

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
    _hero_layer = RenderHeroLayerScript.new(self)
    _fx_layer = RenderFxLayerScript.new(self)
    _bg = BgLayerScript.new()
    _bg.setup(self)
    add_child(_bg)

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
    if _bg != null:
        _bg.sync()

func _sync_roar_fx() -> void: _fx_layer.sync_roar_fx()

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

func _gun_src_rect(frame: int) -> Rect2: return _hero_layer.gun_src_rect(frame)
func _muzzle_src_rect(row: int, col: int) -> Rect2: return _hero_layer.muzzle_src_rect(row, col)
func _impact_src_rect(row: int, col: int) -> Rect2: return _fx_layer.impact_src_rect(row, col)
func _horizontal_fx_src_rect(texture: Texture2D, columns: int, frame: int) -> Rect2: return _fx_layer.horizontal_fx_src_rect(texture, columns, frame)
func _mobility_fx_texture(kind: StringName, label: String) -> Texture2D: return _fx_layer.mobility_fx_texture(kind, label)

func _consume_shot_events() -> void:
    if world == null or world.event_log == null:
        return
    var log = world.event_log
    var start: int = log.first_index_after(last_shot_event_id)
    for i in range(start, log.events.size()):
        var event: Dictionary = log.events[i]
        var eid := int(event.get("event_id", 0))
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
    log.discard_up_to(last_shot_event_id)

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

func _zodiac_texture(animal: int) -> Texture2D: return _hero_layer.zodiac_texture(animal)
func _animal_src_rect(animal: int) -> Rect2: return _hero_layer.animal_src_rect(animal)
func _animal_down_src_rect(animal: int) -> Rect2: return _hero_layer.animal_down_src_rect(animal)
func _zone_lightning_src_rect(frame: int) -> Rect2: return _fx_layer.zone_lightning_src_rect(frame)
func _ultimate_src_rect(texture: Texture2D, frame: int, row: int = 0) -> Rect2: return _fx_layer.ultimate_src_rect(texture, frame, row)
func draw_ultimate_frame(animal: int, pos: Vector2, size: Vector2, frame: int, row: int = 0, rotation: float = 0.0, alpha: float = 1.0) -> bool:
    return _fx_layer.draw_ultimate_frame(animal, pos, size, frame, row, rotation, alpha)
func _bullet_src_rect(kind: String, tick: int) -> Rect2: return _fx_layer.bullet_src_rect(kind, tick)
func _draw_lhj_bullet(projectile_pos: Vector2, direction: Vector2, kind: String, scale: float = 1.0) -> void: _fx_layer.draw_lhj_bullet(projectile_pos, direction, kind, scale)
func _zodiac_name(animal: int) -> String: return _hero_layer.zodiac_name(animal)
func _projectile_color(projectile: Dictionary) -> Color: return _fx_layer.projectile_color(projectile)
func _draw_dashed_circle(center: Vector2, radius: float, color: Color, width: float = 3.0, dash: float = 0.10, gap: float = 0.08) -> void: _fx_layer.draw_dashed_circle(center, radius, color, width, dash, gap)
func _draw_dashed_tracer(pos: Vector2, dir: Vector2, color: Color, width: float = 5.0) -> void: _fx_layer.draw_dashed_tracer(pos, dir, color, width)
func _draw_motion_trail(trail: Array, color: Color, width: float, opacity: float = 1.0) -> void: _fx_layer.draw_motion_trail(trail, color, width, opacity)
func _draw_hero_gun(pos: Vector2, slot: int, aim: Vector2, opacity: float = 1.0, extra_squash: float = 0.0) -> void: _hero_layer.draw_hero_gun(pos, slot, aim, opacity, extra_squash)
func _draw_muzzle_flash(slot: int, vis: Dictionary, opacity: float) -> void: _hero_layer.draw_muzzle_flash(slot, vis, opacity)

func _push_combat_text(pos: Vector2, text: String, color: Color) -> void:
    combat_texts.append({"pos":pos, "text":text, "color":color, "time":0.0})

func _tick_combat_texts(dt: float) -> void:
    var keep: Array = []
    for ct in combat_texts:
        ct["time"] = float(ct["time"]) + dt
        if float(ct["time"]) < 0.75:
            keep.append(ct)
    combat_texts = keep

func _draw_projectile_texture(pos: Vector2, direction: Vector2, kind: String, size_scale: float = 1.0) -> bool: return _fx_layer.draw_projectile_texture(pos, direction, kind, size_scale)
func _draw_projectiles() -> void: _proj.draw_projectiles_main()
func _draw_zones() -> void: _proj.draw_zones_main()
func _draw_effects() -> void: _proj.draw_effects_main()
func _draw_blob_shadow(ground_pos: Vector2, hop_lift: float, opacity: float) -> void: _hero_layer.draw_blob_shadow(ground_pos, hop_lift, opacity)

func visible_world_rect() -> Rect2:
    # canvas→viewport (Camera2D 포함). stretch 는 get_viewport_rect() 에 이미 반영됨.
    # get_viewport_transform() 은 embedder(stretch)까지 포함해 가시 영역이 줄어든다.
    return (get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()).grow(384.0)

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
    _hero_layer.world = world
    _fx_layer.world = world


func _draw_world_pass() -> void:
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
