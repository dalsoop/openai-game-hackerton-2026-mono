class_name CharacterCatalog
extends RefCounted
## 캐릭터 레지스트리 거울 — 항목 나열은 JSON 이 정본이다.
## 정본: web/lib/characters/characters.json
## 코드는 id 조회·시트 전개만 한다. 캐릭터 이름을 여기 쓰지 않는다.

const DATA_PATH := "res://core/contract/characters.json"

static func normalize(raw: String) -> String:
	var want := raw.strip_edges()
	for item in all():
		if str(item.get("id", "")) == want:
			return want
	return _default_id()


static func is_random(raw: String) -> bool:
	var id := normalize(raw)
	for item in all():
		if str(item.get("id", "")) == id:
			return str(item.get("pick", "")) == "random"
	return false


static func resolve_playable(raw: String, key: String = "animal") -> String:
	var id := normalize(raw)
	if not is_random(id) and bind_int(id, key) >= 0:
		return id
	var pool: Array = []
	for item in all():
		var binds: Dictionary = item.get("binds", {})
		if binds.has(key):
			pool.append(str(item.get("id", "")))
	if pool.is_empty():
		return id
	return str(pool[randi() % pool.size()])


static func bind_key() -> String:
	var sheets: Variant = _load_data().get("sheets", [])
	if typeof(sheets) != TYPE_ARRAY or (sheets as Array).is_empty():
		return "animal"
	var first: Variant = (sheets as Array)[0]
	if typeof(first) != TYPE_DICTIONARY:
		return "animal"
	var key := str((first as Dictionary).get("indexBind", ""))
	return key if key != "" else "animal"


static func match_bind() -> String:
	return bind_key()


static func portrait_index(raw: String) -> int:
	var id := normalize(raw)
	for item in all():
		if str(item.get("id", "")) != id:
			continue
		var portrait: Dictionary = item.get("portrait", {})
		if portrait.has("index"):
			return int(portrait["index"])
		return bind_int(id, bind_key())
	return -1


static func id_for_bind(key: String, value: int) -> String:
	for item in all():
		var binds: Dictionary = item.get("binds", {})
		if binds.has(key) and int(binds[key]) == value:
			return str(item.get("id", ""))
	return ""


static func bind_int(raw: String, key: String) -> int:
	var id := normalize(raw)
	for item in all():
		if str(item.get("id", "")) != id:
			continue
		var binds: Dictionary = item.get("binds", {})
		if not binds.has(key):
			return -1
		return int(binds[key])
	return -1


static func all() -> Array:
	var data := _load_data()
	var out: Array = []
	for entry in data.get("entries", []):
		out.append(entry)
	for sheet in data.get("sheets", []):
		out.append_array(_expand_sheet(sheet))
	return out


static func _default_id() -> String:
	return str(_load_data().get("defaultId", ""))


static func _expand_sheet(sheet: Dictionary) -> Array:
	var cols := maxi(0, int(sheet.get("cols", 0)))
	var rows := maxi(0, int(sheet.get("rows", 0)))
	var prefix := str(sheet.get("idPrefix", ""))
	var title_prefix := str(sheet.get("titleKeyPrefix", ""))
	var src := str(sheet.get("src", ""))
	var bind_key := str(sheet.get("indexBind", ""))
	var out: Array = []
	for index in range(cols * rows):
		var binds := {}
		if bind_key != "":
			binds[bind_key] = index
		out.append({
			"id": "%s%d" % [prefix, index],
			"titleKey": "%s%d" % [title_prefix, index],
			"portrait": {"src": src, "cols": cols, "rows": rows, "index": index},
			"binds": binds,
		})
	return out


static func _load_data() -> Dictionary:
	if not FileAccess.file_exists(DATA_PATH):
		return {}
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
