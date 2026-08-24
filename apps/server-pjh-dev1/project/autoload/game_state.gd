extends Node

enum State { BOOT, LOBBY, ROOM_WAIT, PLAYING, PAUSED, RESULT }

signal state_changed(from_state: State, to_state: State)

const TRANSITIONS := {
	State.BOOT: [State.LOBBY, State.ROOM_WAIT, State.PLAYING],
	State.LOBBY: [State.ROOM_WAIT],
	State.ROOM_WAIT: [State.PLAYING, State.LOBBY],
	State.PLAYING: [State.PAUSED, State.RESULT, State.ROOM_WAIT, State.LOBBY],
	State.PAUSED: [State.PLAYING, State.ROOM_WAIT, State.LOBBY],
	State.RESULT: [State.PLAYING, State.ROOM_WAIT, State.LOBBY],
}

var current_state: State = State.BOOT
var hub_launched := false
var selected_mode := "classic"
var player_name := tr("NET_DEFAULT_PLAYER")
var net_active := false
var net_host := false
var match_seed: int = 2222

func request(next: State) -> void:
	if current_state == next:
		return
	var allowed: Array = TRANSITIONS.get(current_state, [])
	if next not in allowed:
		push_warning("GameState: invalid transition %s → %s" % [State.keys()[current_state], State.keys()[next]])
		return
	var prev := current_state
	current_state = next
	state_changed.emit(prev, next)

func is_state(s: State) -> bool:
	return current_state == s

func _ready() -> void:
	var net: Node = get_node_or_null("/root/NetworkManager")
	if net == null:
		return
	hub_launched = net.consume_hub_launch()
	if hub_launched:
		var hub_name: String = net.get_hub_name()
		if hub_name != "":
			player_name = hub_name
			net.player_name = hub_name
