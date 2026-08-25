extends Node
## 게임 무관 부트 — 유즈맵 진입점. KEY_GAME(허브 핸드오프)으로
## games/<id>/main.tscn 을 띄운다. 이 파일이 유일하게 games/ 경로를
#   언급하는 core 파일이다(동적 디스패치 — lint 게이트 예외 사실).

const DEFAULT_GAME := "dagul"

func _ready() -> void:
	var path := "res://games/%s/main.tscn" % _game_id()
	if not ResourceLoader.exists(path):
		path = "res://games/%s/main.tscn" % DEFAULT_GAME
	get_tree().change_scene_to_file(path)

func _game_id() -> String:
	if not OS.has_feature("web"):
		return DEFAULT_GAME
	var raw := str(JavaScriptBridge.eval(
		"try{localStorage.getItem('%s')||''}catch(e){''}" % WebContract.KEY_GAME, true)).strip_edges()
	if raw == "" or raw == "null" or raw == "undefined":
		return DEFAULT_GAME
	return raw
