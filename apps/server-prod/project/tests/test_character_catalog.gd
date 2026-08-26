extends RefCounted
## CharacterCatalog 거울 — JSON 전개·정규화·bind 만 검증한다. 이름을 여기 쓰지 않는다.

const Catalog := preload("res://core/contract/character_catalog.gd")

func run(t) -> void:
	var items: Array = Catalog.all()
	t.check("항목이 있다", items.size() > 1)
	var default_id := Catalog.normalize("___missing___")
	t.check("미등재는 defaultId", default_id != "" and default_id != "___missing___")
	t.check("default 정규화 고정", Catalog.normalize(default_id) == default_id)
	t.check("기본 항목 animal 없음", Catalog.bind_int(default_id, "animal") == -1)

	var sheet_id := ""
	for item in items:
		var binds: Dictionary = item.get("binds", {})
		if binds.has("animal") and int(binds["animal"]) == 0:
			sheet_id = str(item.get("id", ""))
			break
	t.check("시트 첫 칸이 있다", sheet_id != "")
	t.check("시트 첫 칸 bind 0", Catalog.bind_int(sheet_id, "animal") == 0)
	t.check("없는 bind 키", Catalog.bind_int(sheet_id, "nope") == -1)

	var last_bind := -1
	for item in items:
		var binds: Dictionary = item.get("binds", {})
		if binds.has("animal"):
			last_bind = maxi(last_bind, int(binds["animal"]))
	t.check("시트 마지막 칸 bind", Catalog.bind_int("%s%d" % [sheet_id.left(sheet_id.length() - 1), last_bind], "animal") == last_bind)
