extends RefCounted
## GameState 는 오토로드 노드다. Engine.get_singleton 으로 찾으면 웹에서 매치가 죽는다.

func run(t) -> void:
	var gs: Node = t.root.get_node_or_null("GameState")
	t.check("오토로드 GameState 는 /root 노드", gs != null)
	t.check("Engine 싱글톤 이름 아님", not Engine.has_singleton("GameState"))
	if gs == null:
		return
	t.check("request/is_state 계약", gs.has_method("request") and gs.has_method("is_state"))
	gs.set("net_active", true)
	t.check("net_active 기록", bool(gs.get("net_active")) == true)
	gs.set("net_active", false)
	var audio: Node = t.root.get_node_or_null("Audio")
	t.check("오토로드 Audio 는 /root 노드", audio != null)
	t.check("Audio 도 엔진 싱글톤 이름 아님", not Engine.has_singleton("Audio"))
