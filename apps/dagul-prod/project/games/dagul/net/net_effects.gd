class_name NetEffects
extends RefCounted

const NetSnapParser = preload("res://games/dagul/net/net_snap_parser.gd")
const SnapContract = preload("res://games/dagul/net/snap_contract.gd")

static func add(effects: Array[Dictionary], kind: StringName, pos: Vector2, radius: float, duration: float, color: Color, direction: Vector2 = Vector2.RIGHT) -> void:
    effects.append({
        "kind":kind,
        "pos":pos,
        "radius":radius,
        "time":duration,
        "max_time":duration,
        "color":color,
        "direction":direction,
        "label":""
    })

static func decay(effects: Array[Dictionary], dt: float, tick_rate: float) -> void:
    var step := dt if dt > 0.0 else 1.0 / tick_rate
    for i in range(effects.size() - 1, -1, -1):
        var effect: Dictionary = effects[i]
        effect["time"] = float(effect["time"]) - step
        if float(effect["time"]) <= 0.0:
            effects.remove_at(i)
        else:
            effects[i] = effect

static func replace_server(effects: Array[Dictionary], snap: Dictionary) -> void:
    if not snap.has(SnapContract.EFFECTS):
        return
    var locals := _keep_local(effects)
    var server := NetSnapParser.parse_effects(snap.get(SnapContract.EFFECTS, []))
    server.append_array(locals)
    effects.assign(server)

static func _keep_local(effects: Array[Dictionary]) -> Array[Dictionary]:
    var kept: Array[Dictionary] = []
    for fx in effects:
        if str(fx.get("kind", "")).begins_with("local_"):
            kept.append(fx)
    return kept
