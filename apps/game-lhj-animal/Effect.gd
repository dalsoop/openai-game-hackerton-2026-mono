extends Node2D

################################################
enum FxArchetype { SMALL, MEDIUM, LARGE }

const BULLET_VISUAL_SCENE := preload("res://Art/Prebs/Effects/BulletVisual.tscn")
const IMPACT_FLASH_SCENE := preload("res://Art/Prebs/Effects/ImpactFlash.tscn")

@export_group("Effect Archetypes")
@export_enum("Small", "Medium", "Large") var MuzzleFlashArchetypeIndex := 0
@export_enum("Short", "Standard", "Long", "Heavy") var BulletArchetypeIndex := 0
@export_enum("Small", "Medium", "Large") var ImpactArchetypeIndex := 0

@export_group("Bullet Visual")
@export_range(100.0, 4000.0, 50.0, "suffix:px/s") var BulletVisualSpeed := 1400.0

@onready var muzzle_socket: Node2D = $MuzzleSocket
@onready var muzzle_flash = $MuzzleSocket/MuzzleFlash

################################################
func _ready() -> void:
	# MuzzleFlash is a deterministic local AnimatedSprite-like effect. Because it
	# remains below MuzzleSocket, animal squash/scale and horizontal flip are
	# inherited without GPUParticles2D world-space simulation drift.
	pass

################################################
func play_muzzle_flash(archetype: FxArchetype) -> void:
	muzzle_flash.play(archetype)


func fire_visual_towards(target_global_position: Vector2) -> void:
	play_muzzle_flash(MuzzleFlashArchetypeIndex)

	var start_position := muzzle_socket.global_position
	var shot_offset := target_global_position - start_position
	if shot_offset.is_zero_approx():
		return

	var bullet = BULLET_VISUAL_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = start_position
	bullet.global_rotation = shot_offset.angle()

	var socket_scale := muzzle_socket.global_transform.get_scale()
	bullet.scale = Vector2(absf(socket_scale.x), absf(socket_scale.y))
	bullet.launch(
		BulletArchetypeIndex,
		ImpactArchetypeIndex,
		shot_offset.normalized(),
		shot_offset.length(),
		BulletVisualSpeed
	)


func play_impact_at(global_hit_position: Vector2, archetype := -1) -> void:
	var impact = IMPACT_FLASH_SCENE.instantiate()
	get_tree().current_scene.add_child(impact)
	impact.global_position = global_hit_position

	var socket_scale := muzzle_socket.global_transform.get_scale()
	impact.scale = Vector2(absf(socket_scale.x), absf(socket_scale.y))
	impact.play(ImpactArchetypeIndex if archetype < 0 else archetype)

################################################
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fire_visual_towards(get_global_mouse_position())
