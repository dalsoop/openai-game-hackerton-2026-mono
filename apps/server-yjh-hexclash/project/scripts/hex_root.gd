extends Node

@onready var renderer: Node2D = $HexView
@onready var ui: Control = $UI

var world: HexWorld
var local_player := 0
var ai_timer := 0.0
var tick_accum := 0.0
var phase := &"intro"
var player_name := "플레이어"

func _ready() -> void:
	Engine.max_fps = 60
	_show_intro()

func _show_intro() -> void:
	phase = &"intro"
	world = null
	renderer.world = null
	ui.world = null
	ui.phase = &"intro"
	ui.queue_redraw()

func _start_game() -> void:
	world = HexWorld.new()
	renderer.world = world
	renderer.local_player = local_player
	ui.world = world
	ui.local_player = local_player
	ui.phase = &"playing"
	phase = &"playing"
	ai_timer = 0.0
	tick_accum = 0.0

func _process(delta: float) -> void:
	if phase == &"intro":
		ui.queue_redraw()
		return
	if world == null:
		return
	tick_accum += delta
	ai_timer += delta
	while tick_accum >= HexWorld.TICK_RATE:
		tick_accum -= HexWorld.TICK_RATE
		var commands := {}
		if ai_timer >= 0.15:
			ai_timer -= 0.15
			_ai_commands(commands)
		world.step_tick(commands)
	if world.result == &"finished":
		phase = &"result"
		ui.phase = &"result"
	var mouse := renderer.get_global_mouse_position()
	renderer.hover_cell = renderer.screen_to_hex(mouse)
	renderer.queue_redraw()
	ui.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if phase == &"intro":
		if event is InputEventMouseButton and event.pressed:
			_start_game()
		if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
			_start_game()
		return
	if phase == &"result":
		if event is InputEventMouseButton and event.pressed:
			_show_intro()
		if event is InputEventKey and event.pressed:
			_show_intro()
		return
	if world == null or world.result != &"playing":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hex = renderer.screen_to_hex(event.position)
		if world.cells.has(hex):
			var cmd := {"claim": hex}
			var commands := {local_player: cmd}
			world.step_tick(commands, 0.0)
			renderer.queue_redraw()
			ui.queue_redraw()

func _ai_commands(commands: Dictionary) -> void:
	for i in range(1, HexWorld.PLAYER_COUNT):
		if not bool(world.players[i]["alive"]):
			continue
		if float(world.players[i]["energy"]) < HexWorld.CLAIM_COST_EMPTY:
			continue
		var target := _ai_pick_target(i)
		if target != Vector2i(-999, -999):
			commands[i] = {"claim": target}

func _ai_pick_target(player_id: int) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for c in world.cells:
		var owner := int(world.cells[c]["owner"])
		if owner == player_id:
			continue
		var adjacent := false
		for n in HexGrid.neighbors(c):
			if world.cells.has(n) and int(world.cells[n]["owner"]) == player_id:
				adjacent = true
				break
		if not adjacent:
			continue
		candidates.append(c)
	if candidates.is_empty():
		return Vector2i(-999, -999)
	var empty: Array[Vector2i] = []
	var enemy: Array[Vector2i] = []
	for c in candidates:
		if int(world.cells[c]["owner"]) == -1:
			empty.append(c)
		else:
			enemy.append(c)
	if not empty.is_empty():
		return empty[randi() % empty.size()]
	if not enemy.is_empty() and float(world.players[player_id]["energy"]) >= HexWorld.CLAIM_COST_ENEMY:
		return enemy[randi() % enemy.size()]
	return Vector2i(-999, -999)
