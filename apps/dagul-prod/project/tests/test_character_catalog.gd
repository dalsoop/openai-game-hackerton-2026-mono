extends RefCounted
## CharacterCatalog 거울 — JSON 전개·정규화·bind 만 검증한다. 이름을 여기 쓰지 않는다.

const Catalog := preload("res://core/contract/character_catalog.gd")
const View := preload("res://core/contract/character_view.gd")

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
	t.check("bind_key 는 시트 indexBind", Catalog.bind_key() == "animal")
	t.check("match_bind 는 bind_key", Catalog.match_bind() == Catalog.bind_key())
	t.check("id_for_bind 0", Catalog.id_for_bind("animal", 0) == sheet_id)
	t.check("portrait_index 첫 칸", Catalog.portrait_index(sheet_id) == 0)
	var view_hero := {}
	View.apply_id(view_hero, sheet_id)
	t.check("apply_id 는 다시 굴리지 않는다", str(view_hero.get("character_id", "")) == sheet_id)
	t.check("apply_id animal 은 bind", int(view_hero.get("animal", -99)) == 0)
	View.apply_id(view_hero, default_id)
	t.check("랜덤 id 는 클라에서 풀지 않는다", str(view_hero.get("character_id", "")) == default_id)
	t.check("랜덤 animal 은 -1", int(view_hero.get("animal", 99)) == -1)
	_apply_id_cache_isolated(t, sheet_id)


func _apply_id_cache_isolated(t, sheet_id: String) -> void:
	var a := {}
	var b := {}
	View.apply_id(a, sheet_id)
	View.apply_id(b, sheet_id)
	t.check("apply_id 2회 character_id 동일", str(a.get("character_id", "")) == sheet_id and str(b.get("character_id", "")) == sheet_id)
	t.check("apply_id 2회 animal 동일", int(a.get("animal", -99)) == int(b.get("animal", -98)))
	var found_mutable := false
	for key in a.keys():
		var value: Variant = a[key]
		var other: Variant = b.get(key)
		if value is Dictionary:
			found_mutable = true
			(value as Dictionary)["__pollute"] = true
			t.check("apply_id 캐시가 다른 hero 를 오염시키지 않는다", other is Dictionary and not (other as Dictionary).has("__pollute"))
			break
		if value is Array:
			found_mutable = true
			(value as Array).append("__pollute")
			t.check("apply_id 캐시가 다른 hero 를 오염시키지 않는다", other is Array and not (other as Array).has("__pollute"))
			break
	if not found_mutable:
		t.check("apply_id 캐시가 다른 hero 를 오염시키지 않는다", false)
