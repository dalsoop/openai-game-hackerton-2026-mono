extends Node2D

const FRAME_COLUMNS := 4

@export_range(0.01, 0.2, 0.005) var frame_duration := 0.045

@onready var sprite: Sprite2D = $Sprite2D

var _archetype := 0
var _impact_archetype := 0
var _direction := Vector2.RIGHT
var _speed := 1400.0
var _remaining_distance := 0.0
var _frame_time := 0.0
var _frame_column := 0
var _active := false


func launch(
		archetype: int,
		impact_archetype: int,
		direction: Vector2,
		distance: float,
		speed: float
) -> void:
	_archetype = clampi(archetype, 0, sprite.vframes - 1)
	_impact_archetype = clampi(impact_archetype, 0, 2)
	_direction = direction.normalized()
	_speed = maxf(speed, 1.0)
	_remaining_distance = maxf(distance, 0.0)
	_frame_column = 0
	_frame_time = 0.0
	_set_frame()
	_active = true

	if _remaining_distance <= 0.0:
		_finish()


func hit_at(global_hit_position: Vector2) -> void:
	global_position = global_hit_position
	_finish()


func _process(delta: float) -> void:
	if not _active:
		return

	var travel := minf(_speed * delta, _remaining_distance)
	global_position += _direction * travel
	_remaining_distance -= travel

	_frame_time += delta
	while _frame_time >= frame_duration:
		_frame_time -= frame_duration
		_frame_column = (_frame_column + 1) % FRAME_COLUMNS
		_set_frame()

	if _remaining_distance <= 0.0:
		_finish()


func _set_frame() -> void:
	sprite.frame = _archetype * FRAME_COLUMNS + _frame_column


func _finish() -> void:
	if not _active:
		return
	_active = false

	var impact = preload("res://Art/Prebs/Effects/ImpactFlash.tscn").instantiate()
	get_tree().current_scene.add_child(impact)
	impact.global_position = global_position
	impact.global_rotation = global_rotation
	impact.scale = scale
	impact.play(_impact_archetype)
	queue_free()
