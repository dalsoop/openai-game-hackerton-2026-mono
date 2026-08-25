class_name HexWorld
extends RefCounted

const PLAYER_COUNT := 6
const MAP_RADIUS := 8
const MATCH_DURATION := 180.0
const TICK_RATE := 1.0 / 20.0
const BASE_ENERGY_RATE := 1.2
const TERRITORY_ENERGY_BONUS := 0.08
const MAX_ENERGY := 20.0
const CLAIM_COST_EMPTY := 2.0
const CLAIM_COST_ENEMY := 5.0
const FORTIFY_COST := 4.0
const FORTIFY_DEFENSE_BONUS := 3.0

const PLAYER_COLORS := [
	Color("5bc0eb"), Color("e55934"), Color("9bc53d"),
	Color("fa7921"), Color("b084cc"), Color("ffd166")
]

var cells: Dictionary = {}
var players: Array[Dictionary] = []
var match_time: float = 0.0
var result: StringName = &"playing"
var winner: int = -1
var tick: int = 0

func _init() -> void:
	_build_map()
	_init_players()

func _build_map() -> void:
	var coords := HexGrid.generate_map(MAP_RADIUS)
	for c in coords:
		cells[c] = {"owner": -1, "fortified": false, "pulse": 0.0}

func _init_players() -> void:
	players.clear()
	var spawn_angles := [0.0, TAU / 6.0, TAU / 3.0, TAU / 2.0, TAU * 2.0 / 3.0, TAU * 5.0 / 6.0]
	var spawn_radius := MAP_RADIUS - 2
	for i in PLAYER_COUNT:
		var angle: float = spawn_angles[i]
		var sq := roundi(cos(angle) * float(spawn_radius))
		var sr := roundi(sin(angle) * float(spawn_radius) * 0.66)
		var spawn := _nearest_valid(Vector2i(sq, sr))
		players.append({
			"id": i,
			"energy": 5.0,
			"territory": 0,
			"color": PLAYER_COLORS[i],
			"alive": true,
			"spawn": spawn,
			"pending_claim": Vector2i(-999, -999),
		})
		if cells.has(spawn):
			cells[spawn]["owner"] = i
			cells[spawn]["pulse"] = 1.0
	_recount()

func _nearest_valid(target: Vector2i) -> Vector2i:
	if cells.has(target) and int(cells[target]["owner"]) == -1:
		return target
	var best := Vector2i(0, 0)
	var best_dist := 9999
	for c in cells:
		if int(cells[c]["owner"]) != -1:
			continue
		var d := HexGrid.distance(target, c)
		if d < best_dist:
			best_dist = d
			best = c
	return best

func reset() -> void:
	cells.clear()
	players.clear()
	match_time = 0.0
	result = &"playing"
	winner = -1
	tick = 0
	_build_map()
	_init_players()

func step_tick(commands: Dictionary, dt: float = TICK_RATE) -> void:
	if result != &"playing":
		return
	tick += 1
	match_time += dt
	for i in PLAYER_COUNT:
		if not bool(players[i]["alive"]):
			continue
		var rate := BASE_ENERGY_RATE + float(players[i]["territory"]) * TERRITORY_ENERGY_BONUS
		players[i]["energy"] = minf(MAX_ENERGY, float(players[i]["energy"]) + rate * dt)
	for i in PLAYER_COUNT:
		if not bool(players[i]["alive"]):
			continue
		var cmd = commands.get(i, null)
		if cmd == null:
			continue
		var target: Vector2i = cmd.get("claim", Vector2i(-999, -999))
		if target == Vector2i(-999, -999):
			continue
		_try_claim(i, target)
	for c in cells:
		var cell: Dictionary = cells[c]
		cell["pulse"] = maxf(0.0, float(cell["pulse"]) - dt * 2.0)
	if match_time >= MATCH_DURATION:
		_end_match()

func _try_claim(player_id: int, target: Vector2i) -> void:
	if not cells.has(target):
		return
	var cell: Dictionary = cells[target]
	var owner := int(cell["owner"])
	if owner == player_id:
		if not bool(cell["fortified"]) and float(players[player_id]["energy"]) >= FORTIFY_COST:
			players[player_id]["energy"] = float(players[player_id]["energy"]) - FORTIFY_COST
			cell["fortified"] = true
			cell["pulse"] = 1.0
		return
	var adjacent := false
	for n in HexGrid.neighbors(target):
		if cells.has(n) and int(cells[n]["owner"]) == player_id:
			adjacent = true
			break
	if not adjacent:
		return
	var cost := CLAIM_COST_EMPTY if owner == -1 else CLAIM_COST_ENEMY
	if bool(cell["fortified"]) and owner != -1:
		cost += FORTIFY_DEFENSE_BONUS
	if float(players[player_id]["energy"]) < cost:
		return
	players[player_id]["energy"] = float(players[player_id]["energy"]) - cost
	cell["owner"] = player_id
	cell["fortified"] = false
	cell["pulse"] = 1.0
	_recount()

func _recount() -> void:
	for i in PLAYER_COUNT:
		players[i]["territory"] = 0
	for c in cells:
		var o := int(cells[c]["owner"])
		if o >= 0 and o < PLAYER_COUNT:
			players[o]["territory"] = int(players[o]["territory"]) + 1

func _end_match() -> void:
	result = &"finished"
	var best := -1
	var best_count := -1
	for i in PLAYER_COUNT:
		var t := int(players[i]["territory"])
		if t > best_count:
			best_count = t
			best = i
	winner = best

func leaderboard() -> Array[Dictionary]:
	var board: Array[Dictionary] = []
	for i in PLAYER_COUNT:
		board.append({"id": i, "territory": players[i]["territory"], "color": players[i]["color"]})
	board.sort_custom(func(a, b): return int(a["territory"]) > int(b["territory"]))
	return board

func time_remaining() -> float:
	return maxf(0.0, MATCH_DURATION - match_time)
