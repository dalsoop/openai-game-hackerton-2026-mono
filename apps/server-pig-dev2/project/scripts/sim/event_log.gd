extends RefCounted

var events: Array[Dictionary] = []
var next_id: int = 1
var max_events: int = 10000

func clear() -> void:
    events.clear()
    next_id = 1

func emit(tick: int, type: StringName, actor_id: int = -1, target_id: int = -1, data: Dictionary = {}, causes: Array = []) -> int:
    var event := {
        "event_id": next_id,
        "tick": tick,
        "type": type,
        "actor_id": actor_id,
        "target_id": target_id,
        "data": data.duplicate(true),
        "cause_event_ids": causes.duplicate()
    }
    next_id += 1
    events.append(event)
    if events.size() > max_events:
        events.pop_front()
    return int(event["event_id"])

func add(tick: int, type: StringName, actor_id: int = -1, target_id: int = -1, data: Dictionary = {}, causes: Array = []) -> int:
    return emit(tick, type, actor_id, target_id, data, causes)

func recent(count: int = 8) -> Array[Dictionary]:
    var start := maxi(0, events.size() - count)
    var out: Array[Dictionary] = []
    for i in range(start, events.size()):
        out.append(events[i])
    return out
