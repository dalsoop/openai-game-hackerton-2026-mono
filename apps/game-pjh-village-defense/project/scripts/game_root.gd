extends Node

const WorldScript = preload("res://scripts/sim/game_world.gd")

@onready var world_view: Node2D = $WorldView
@onready var camera: Camera2D = $WorldView/Camera2D
@onready var hud: Control = $HUD/Overlay

var world
var previous_keys: Dictionary = {}
var seed: int = 44001
var p1_ready: bool = false
var p2_ready: bool = false
var p2_aim_dir := Vector2.RIGHT

func _ready() -> void:
    _restart()

func _restart() -> void:
    world = WorldScript.new(seed)
    world_view.world = world
    hud.world = world
    camera.position = world.camera_target()
    p1_ready = false
    p2_ready = false
    p2_aim_dir = Vector2.RIGHT

func _physics_process(_delta: float) -> void:
    if _edge(KEY_R):
        seed += 1
        _restart()
        return
    if not p1_ready and _edge(KEY_SPACE):
        p1_ready = true
    if not p2_ready and _edge(KEY_ENTER):
        p2_ready = true
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
    if p2_move.length_squared() > 0.01:
        p2_aim_dir = p2_move
    var p2_pos: Vector2 = world.heroes[1]["pos"]
    var command := {
        "party_ready":p1_ready and p2_ready,
        "p1":{"move":p1_move, "aim":world_view.get_global_mouse_position(), "primary":Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), "skill":_edge(KEY_Q), "stasis":_edge(KEY_E), "panic":_edge(KEY_SPACE), "upgrade":_edge(KEY_U)},
        "p2":{"move":p2_move, "aim":p2_pos + p2_aim_dir * 460.0, "primary":Input.is_key_pressed(KEY_ENTER), "skill":_edge(KEY_SHIFT), "stasis":_edge(KEY_PERIOD), "panic":_edge(KEY_SLASH), "upgrade":_edge(KEY_BACKSPACE)}
    }
    world.step_tick(command, 1.0 / 60.0)
    var shake := Vector2.ZERO
    if world.impact_ticks > 0:
        shake = Vector2(sin(float(world.tick) * 2.4), cos(float(world.tick) * 3.7)) * (2.0 + world.impact_ticks * 0.35)
    camera.position = camera.position.lerp(world.camera_target(), 0.12) + shake
    world_view.queue_redraw()
    hud.queue_redraw()

func _edge(keycode: int) -> bool:
    var now := Input.is_key_pressed(keycode)
    var was := bool(previous_keys.get(keycode, false))
    previous_keys[keycode] = now
    return now and not was
