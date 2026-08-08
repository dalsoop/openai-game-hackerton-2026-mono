extends Node

const WorldScript = preload("res://scripts/sim/game_world.gd")

@onready var world_view: Node2D = $WorldView
@onready var camera: Camera2D = $WorldView/Camera2D
@onready var hud: Control = $HUD/Overlay

var world
var previous_keys: Dictionary = {}
var seed: int = 55001
var p1_ready: bool = false
var p2_ready: bool = false
var p2_target: int = 0

func _ready() -> void:
    _restart()

func _restart() -> void:
    world = WorldScript.new(seed)
    world_view.world = world
    hud.world = world
    camera.position = world.camera_target()
    p1_ready = false
    p2_ready = false
    p2_target = 0

func _physics_process(_delta: float) -> void:
    if _edge(KEY_R):
        seed += 1
        _restart()
        return
    if not p1_ready and _edge(KEY_SPACE):
        p1_ready = true
    if not p2_ready and _edge(KEY_ENTER):
        p2_ready = true
    if p2_ready and _edge(KEY_SHIFT):
        p2_target = (p2_target + 1) % 3
    var p1_move := Vector2(
        float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
        float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
    )
    if p1_move.length_squared() > 1.0:
        p1_move = p1_move.normalized()
    var p2_move := Vector2(
        float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)),
        float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
    )
    if p2_move.length_squared() > 1.0:
        p2_move = p2_move.normalized()
    var supplier: Dictionary = world.actors[3]
    var target_pos: Vector2 = world.actors[p2_target]["pos"]
    var command := {
        "party_ready":p1_ready and p2_ready,
        "p1":{"move":p1_move, "aim":world_view.get_global_mouse_position(), "primary":Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), "ability":_edge(KEY_Q), "request_ammo":_edge(KEY_F), "request_med":_edge(KEY_E), "request_barrier":_edge(KEY_SPACE)},
        "p2":{"move":p2_move, "aim":target_pos, "primary":Input.is_key_pressed(KEY_ENTER), "cycle_supply":_edge(KEY_PERIOD), "overcharge":Input.is_key_pressed(KEY_SLASH), "supply_kind":supplier["selected_supply"], "target_actor":p2_target}
    }
    world.step_tick(command, 1.0 / 60.0)
    var shake := Vector2.ZERO
    if world.impact_ticks > 0:
        shake = Vector2(sin(float(world.tick) * 2.6), cos(float(world.tick) * 4.0)) * (2.0 + world.impact_ticks * 0.35)
    camera.position = camera.position.lerp(world.camera_target(), 0.12) + shake
    world_view.queue_redraw()
    hud.queue_redraw()

func _edge(keycode: int) -> bool:
    var now := Input.is_key_pressed(keycode)
    var was := bool(previous_keys.get(keycode, false))
    previous_keys[keycode] = now
    return now and not was
