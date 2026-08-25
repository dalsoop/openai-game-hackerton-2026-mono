extends Node
## 게임 상태 SSOT — 매치 생명주기의 단일 정본.
## 웹 로비(React)는 Godot 밖에 있으므로 여기엔 매치 셸에 필요한 상태만 둔다.

enum State { BOOT, LOBBY, ROOM_WAIT, PLAYING, PAUSED, RESULT }

signal state_changed(from_state: State, to_state: State)  # lint-gd: public-api — 구독용 공개 계약

const _TRANSITIONS := {
	State.BOOT: [State.LOBBY, State.ROOM_WAIT, State.PLAYING],
	State.LOBBY: [State.ROOM_WAIT, State.BOOT],
	State.ROOM_WAIT: [State.PLAYING, State.LOBBY, State.BOOT],
	State.PLAYING: [State.PAUSED, State.RESULT, State.ROOM_WAIT, State.LOBBY, State.BOOT],
	State.PAUSED: [State.PLAYING, State.ROOM_WAIT, State.LOBBY, State.BOOT],
	State.RESULT: [State.PLAYING, State.ROOM_WAIT, State.LOBBY, State.BOOT],
}

var current_state: State = State.BOOT  # lint-gd: public-api — FSM 상태 노출 계약
var net_active := false
var net_host := false

func request(next: State) -> void:
	if current_state == next:
		return
	var allowed: Array = _TRANSITIONS.get(current_state, [])
	if next not in allowed:
		push_warning("GameState: invalid transition %s → %s" % [State.keys()[current_state], State.keys()[next]])
		return
	var prev := current_state
	current_state = next
	state_changed.emit(prev, next)

func is_state(s: State) -> bool:
	return current_state == s
