extends Node
## 게임 무관 부트 — 유즈맵 진입점. KEY_GAME(허브 핸드오프)으로
## games/<id>/main.tscn 을 띄운다. 이 파일이 유일하게 games/ 경로를
#   언급하는 core 파일이다(동적 디스패치 — lint 게이트 예외 사실).

func _ready() -> void:
	# --script res://tests/run_tests.gd 는 본편 씬을 열면 CI 헤드리스가 멈춘다.
	for arg in OS.get_cmdline_args():
		if str(arg).ends_with("run_tests.gd"):
			return
	var path := "res://games/%s/main.tscn" % _game_id()
	if not ResourceLoader.exists(path):
		path = "res://games/%s/main.tscn" % WebContract.DEFAULT_GAME
	# _ready 안에서 즉시 바꾸면 트리가 자식 추가 중이라 remove_child 가 거절된다.
	get_tree().call_deferred("change_scene_to_file", path)

func _game_id() -> String:
	if not OS.has_feature("web"):
		return WebContract.DEFAULT_GAME
	var raw := str(JavaScriptBridge.eval(
		"try{sessionStorage.getItem('%s')||''}catch(e){''}" % WebContract.KEY_GAME, true)).strip_edges()
	if raw == "" or raw == "null" or raw == "undefined":
		return WebContract.DEFAULT_GAME
	return raw
