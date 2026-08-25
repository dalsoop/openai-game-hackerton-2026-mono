class_name Spectator
extends RefCounted

## Spectator mode: cycle through alive players after elimination.

var slot: int = 0


func is_valid(world, candidate: int) -> bool:
	return candidate >= 0 and candidate != world.local_slot and candidate < world.heroes.size() and bool(world.heroes[candidate]["alive"]) and not bool(world.heroes[candidate]["eliminated"])


func best(world) -> int:
	var best_slot := -1
	var best_score := -1.0
	for s in range(world.heroes.size()):
		if is_valid(world, s) and float(world.heroes[s]["score"]) > best_score:
			best_slot = s
			best_score = float(world.heroes[s]["score"])
	return best_slot


func cycle(world, direction: int) -> void:
	var current: int = slot if slot >= 0 else world.local_slot
	for offset in range(1, world.heroes.size() + 1):
		var candidate := posmod(current + direction * offset, world.heroes.size())
		if is_valid(world, candidate):
			slot = candidate
			return


func update(world, input: PlayerInput) -> void:
	if world == null or world.heroes.is_empty():
		return
	var me_slot := clampi(world.local_slot, 0, world.heroes.size() - 1)
	if not bool(world.heroes[me_slot]["eliminated"]):
		slot = world.local_slot
		return
	if not is_valid(world, slot):
		slot = best(world)
	if input.edge(KEY_A):
		cycle(world, -1)
	if input.edge(KEY_D) or input.edge(KEY_TAB):
		cycle(world, 1)
	if input.edge(KEY_SPACE):
		slot = best(world)
