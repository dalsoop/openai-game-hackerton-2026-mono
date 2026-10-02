extends Node
## 게임 무관 부트 — 유즈맵 진입점. KEY_GAME(허브 핸드오프)으로
## games/<id>/main.tscn 을 띄운다. 이 파일이 유일하게 games/ 경로를
#   언급하는 core 파일이다(동적 디스패치 — lint 게이트 예외 사실).

func _ready() -> void:
	for arg in OS.get_cmdline_args():
		if str(arg).ends_with("run_tests.gd"):
			return
	if not OS.has_feature("web"):
		get_tree().call_deferred("change_scene_to_file", "res://core/native/native_lobby.tscn")
		return
	var path := "res://games/%s/main.tscn" % _game_id()
	if not ResourceLoader.exists(path):
		path = "res://games/%s/main.tscn" % WebContract.DEFAULT_GAME
	get_tree().call_deferred("change_scene_to_file", path)

func _game_id() -> String:
	if not OS.has_feature("web"):
		return WebContract.DEFAULT_GAME
	var raw := str(JavaScriptBridge.eval(
		"try{sessionStorage.getItem('%s')||''}catch(e){''}" % WebContract.KEY_GAME, true)).strip_edges()
	if raw == "" or raw == "null" or raw == "undefined":
		return WebContract.DEFAULT_GAME
	return raw
