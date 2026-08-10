extends Node2D

const W := 960.0
const H := 540.0
const PLAYER_SIZE := Vector2(40, 40)
const PLAYER_SPEED := 420.0
const BLOCK_SIZE := Vector2(36, 36)

var player: ColorRect
var score_label: Label
var info_label: Label
var blocks: Array[ColorRect] = []
var score := 0.0
var spawn_timer := 0.0
var spawn_interval := 0.9
var fall_speed := 220.0
var game_over := false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.09, 0.13)
	bg.size = Vector2(W, H)
	add_child(bg)

	player = ColorRect.new()
	player.color = Color(0.3, 0.85, 0.5)
	player.size = PLAYER_SIZE
	player.position = Vector2(W / 2 - PLAYER_SIZE.x / 2, H - 70)
	add_child(player)

	score_label = Label.new()
	score_label.position = Vector2(16, 12)
	score_label.add_theme_font_size_override("font_size", 24)
	add_child(score_label)

	info_label = Label.new()
	info_label.position = Vector2(W / 2 - 200, H / 2 - 20)
	info_label.add_theme_font_size_override("font_size", 28)
	info_label.visible = false
	add_child(info_label)

func _process(delta: float) -> void:
	if game_over:
		if Input.is_key_pressed(KEY_ENTER):
			_restart()
		return

	score += delta
	score_label.text = "SCORE %d" % int(score * 10)

	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	player.position.x = clampf(player.position.x + dir * PLAYER_SPEED * delta, 0.0, W - PLAYER_SIZE.x)

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_block()
		spawn_interval = maxf(0.25, spawn_interval * 0.985)
		fall_speed = minf(560.0, fall_speed + 4.0)

	var player_rect := Rect2(player.position, PLAYER_SIZE)
	for block in blocks.duplicate():
		block.position.y += fall_speed * delta
		if block.position.y > H:
			blocks.erase(block)
			block.queue_free()
		elif Rect2(block.position, BLOCK_SIZE).intersects(player_rect):
			_end_game()
			return

func _spawn_block() -> void:
	var block := ColorRect.new()
	block.color = Color(0.9, 0.35, 0.35)
	block.size = BLOCK_SIZE
	block.position = Vector2(randf_range(0.0, W - BLOCK_SIZE.x), -BLOCK_SIZE.y)
	add_child(block)
	blocks.append(block)

func _end_game() -> void:
	game_over = true
	info_label.text = "GAME OVER — SCORE %d\nEnter 로 재시작" % int(score * 10)
	info_label.visible = true

func _restart() -> void:
	for block in blocks:
		block.queue_free()
	blocks.clear()
	score = 0.0
	spawn_timer = 0.0
	spawn_interval = 0.9
	fall_speed = 220.0
	game_over = false
	info_label.visible = false
	player.position = Vector2(W / 2 - PLAYER_SIZE.x / 2, H - 70)
