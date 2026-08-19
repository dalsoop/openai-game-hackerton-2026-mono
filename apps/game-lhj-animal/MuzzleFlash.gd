extends Node2D

const FRAME_COLUMNS := 4
const FRAME_COUNTS := [2, 3, 4]

@export_range(0.01, 0.2, 0.005) var frame_duration := 0.055

@onready var sprite: Sprite2D = $Sprite2D

var _play_version := 0


func _ready() -> void:
	sprite.visible = false


func play(archetype: int) -> void:
	_play_version += 1
	_play_sequence(clampi(archetype, 0, FRAME_COUNTS.size() - 1), _play_version)


func stop() -> void:
	_play_version += 1
	sprite.visible = false


func _play_sequence(archetype: int, version: int) -> void:
	sprite.visible = true
	for column in FRAME_COUNTS[archetype]:
		if version != _play_version:
			return
		sprite.frame = archetype * FRAME_COLUMNS + column
		await get_tree().create_timer(frame_duration).timeout

	if version == _play_version:
		sprite.visible = false
