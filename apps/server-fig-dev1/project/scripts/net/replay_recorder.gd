class_name ReplayRecorder
extends RefCounted

var _seed: int
var _mode: String
var _player_names: Array[String] = []
var _commands: Array[Dictionary] = []
var _recording := false

func start(seed_val: int, mode: String, players: Array) -> void:
	_seed = seed_val
	_mode = mode
	_player_names.clear()
	_commands.clear()
	for p in players:
		_player_names.append(str(p.get("name", "CPU")))
	_recording = true

func record_input(tick: int, slot: int, input_data: Dictionary) -> void:
	if not _recording:
		return
	_commands.append({"tick": tick, "slot": slot, "input": input_data})

func stop() -> void:
	_recording = false

func save_to_file() -> String:
	var replay := {
		"seed": _seed,
		"mode": _mode,
		"player_names": _player_names,
		"command_count": _commands.size(),
		"commands": _commands,
	}
	var dir_path := "user://replays"
	DirAccess.make_dir_recursive_absolute(dir_path)
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var file_path := "%s/replay_%s.json" % [dir_path, timestamp]
	var f := FileAccess.open(file_path, FileAccess.WRITE)
	if f == null:
		push_warning("ReplayRecorder: failed to write %s" % file_path)
		return ""
	f.store_string(JSON.stringify(replay))
	print("ReplayRecorder: saved %d commands to %s" % [_commands.size(), file_path])
	return file_path

func is_recording() -> bool:
	return _recording
