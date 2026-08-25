extends RefCounted
## 허브 소켓 주인은 React. NetworkManager 는 reconnect 하지 않는다.

func run(t) -> void:
	var src := FileAccess.get_file_as_string("res://core/autoload/network_manager.gd")
	t.check("NetworkManager 소스 읽힘", src != "")
	var code := ""
	for line in src.split("\n"):
		if not line.strip_edges().begins_with("#"):
			code += line + "\n"
	t.check("Colyseus.Client 없음", code.find("Colyseus.Client") < 0)
	t.check(".reconnect( 없음", code.find(".reconnect(") < 0)
	t.check("페이지 브릿지 TO", code.find("EVT_TO_ENGINE") >= 0)
	t.check("페이지 브릿지 FROM", code.find("EVT_FROM_ENGINE") >= 0)
	t.check("반전: matchmake/reconnect 경로 금지", code.find("matchmake") < 0)
	t.check("MATCH 재소비 가드", code.find("if match_running:") >= 0)
