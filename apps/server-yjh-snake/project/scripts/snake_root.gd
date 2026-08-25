extends Node

const WorldScript = preload("res://scripts/snake_world.gd")

@onready var renderer: Node2D = $WorldView
@onready var camera: Camera2D = $WorldView/Camera2D
@onready var ui: Control = $UI/Overlay

var world
var _prev_space := false
var _prev_enter := false

func _ready() -> void:
	world = WorldScript.new(randi())
	renderer.world = world
	ui.world = world
	camera.position = Vector2(2000, 2000)
	Engine.max_fps = 60

func _physics_process(_delta: float) -> void:
	if world == null:
		return
	var ps: Dictionary = world.player_snake()
	if ps.is_empty():
		return
	var input := _build_input()
	world.step_tick(input)
	var segs: Array = ps["segments"]
	if segs.size() > 0:
		var head := Vector2(segs[0]["x"], segs[0]["y"])
		camera.position = camera.position.lerp(head, 8.0 * _delta_safe())

func _build_input() -> Dictionary:
	var cmd := {}
	var mouse_pos := get_viewport().get_mouse_position()
	var vp_center := get_viewport().get_visible_rect().size * 0.5
	if mouse_pos.distance_to(vp_center) > 20.0:
		var world_aim := camera.position + (mouse_pos - vp_center)
		cmd["aim_x"] = world_aim.x
		cmd["aim_y"] = world_aim.y
	var mx := 0.0
	var my := 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		my -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		my += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		mx -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		mx += 1.0
	if mx != 0.0 or my != 0.0:
		cmd["mx"] = mx
		cmd["my"] = my
	cmd["boost"] = Input.is_key_pressed(KEY_SHIFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var space_now := Input.is_key_pressed(KEY_SPACE)
	var enter_now := Input.is_key_pressed(KEY_ENTER)
	cmd["restart"] = (space_now and not _prev_space) or (enter_now and not _prev_enter)
	_prev_space = space_now
	_prev_enter = enter_now
	return cmd

func _delta_safe() -> float:
	var d := get_process_delta_time()
	return d if d > 0.0 else 1.0 / 60.0
