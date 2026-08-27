class_name GameRegistry
extends RefCounted
## games/<id>/game.gd 를 동적 로드한다 — 셸은 게임 이름을 하드코딩하지 않는다.

static func load_game(game_id: String) -> GameModule:
	var path := "res://games/%s/game.gd" % game_id
	if not ResourceLoader.exists(path):
		push_error("GameRegistry: 게임 없음 — %s" % path)  # lint-gd: i18n-ok
		return null
	var script: GDScript = load(path)
	var module: GameModule = script.new()
	return module
