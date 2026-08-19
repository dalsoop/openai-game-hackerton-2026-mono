extends Node2D

const FRAME_COLUMNS := 4
const FRAME_COUNTS := [2, 3, 4]

@export_range(0.01, 0.2, 0.005) var frame_duration := 0.055

@onready var sprite: Sprite2D = $Sprite2D


func play(archetype: int) -> void:
	_play_sequence(clampi(archetype, 0, FRAME_COUNTS.size() - 1))


func _play_sequence(archetype: int) -> void:
	for column in FRAME_COUNTS[archetype]:
		sprite.frame = archetype * FRAME_COLUMNS + column
		await get_tree().create_timer(frame_duration).timeout
	queue_free()
