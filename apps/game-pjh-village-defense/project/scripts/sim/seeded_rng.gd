extends RefCounted

var state: int = 1

func _init(seed: int = 1) -> void:
    reseed(seed)

func reseed(seed: int) -> void:
    state = seed & 0x7fffffff
    if state == 0:
        state = 1

func next_u32() -> int:
    state = int((state * 1664525 + 1013904223) & 0xffffffff)
    return state

func randf_value() -> float:
    return float(next_u32() & 0x00ffffff) / 16777216.0

func next_float() -> float:
    return randf_value()

func rangef(min_value: float, max_value: float) -> float:
    return lerpf(min_value, max_value, randf_value())

func rangei(min_value: int, max_value: int) -> int:
    if max_value <= min_value:
        return min_value
    return min_value + int(next_u32() % (max_value - min_value + 1))

func chance(probability: float) -> bool:
    return randf_value() < clampf(probability, 0.0, 1.0)

func choose(values: Array):
    if values.is_empty():
        return null
    return values[rangei(0, values.size() - 1)]
