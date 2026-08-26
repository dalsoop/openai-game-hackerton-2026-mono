class_name CharacterCatalog
extends RefCounted
## 캐릭터 레지스트리 거울 — 항목 나열은 JSON 이 정본이다.
## 정본: web/lib/characters/characters.json
## 코드는 id 조회·시트 전개만 한다. 캐릭터 이름을 여기 쓰지 않는다.

const DATA_PATH := "res://core/contract/characters.json"

static var _data := {}
static var _data_ready := false
static var _items: Array = []
static var _items_ready := false
static var _by_id := {}
static var _bind_key_cache := ""
static var _bind_key_ready := false
static var _id_for_bind_cache := {}
static var _normalize_cache := {}
static var _bind_int_cache := {}

static func normalize(raw: String) -> String:
	var want := raw.strip_edges()
	if _normalize_cache.has(want):
		return str(_normalize_cache[want])
	all()
	var resolved := want if _by_id.has(want) else _default_id()
	_normalize_cache[want] = resolved
	return resolved


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
	if _bind_key_ready:
		return _bind_key_cache
	_bind_key_cache = _sheet_bind_key(_load_data().get("sheets", []))
	_bind_key_ready = true
	return _bind_key_cache


static func _sheet_bind_key(sheets: Variant) -> String:
	if typeof(sheets) != TYPE_ARRAY or (sheets as Array).is_empty():
		return "animal"
	var first: Variant = (sheets as Array)[0]
	if typeof(first) != TYPE_DICTIONARY:
		return "animal"
	var raw := str((first as Dictionary).get("indexBind", ""))
	return raw if raw != "" else "animal"


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
	var cache_key := "%s:%d" % [key, value]
	if _id_for_bind_cache.has(cache_key):
		return str(_id_for_bind_cache[cache_key])
	var found := ""
	for item in all():
		var binds: Dictionary = item.get("binds", {})
		if binds.has(key) and int(binds[key]) == value:
			found = str(item.get("id", ""))
			break
	_id_for_bind_cache[cache_key] = found
	return found


static func bind_int(raw: String, key: String) -> int:
	var id := normalize(raw)
	var cache_key := "%s:%s" % [id, key]
	if _bind_int_cache.has(cache_key):
		return int(_bind_int_cache[cache_key])
	var item: Dictionary = _item_by_id(id)
	var binds: Dictionary = item.get("binds", {})
	var n := int(binds[key]) if binds.has(key) else -1
	_bind_int_cache[cache_key] = n
	return n


static func all() -> Array:
	if _items_ready:
		return _items
	var data := _load_data()
	var out: Array = []
	for entry in data.get("entries", []):
		out.append(entry)
	for sheet in data.get("sheets", []):
		out.append_array(_expand_sheet(sheet))
	_items = out
	_by_id.clear()
	for item in out:
		_by_id[str(item.get("id", ""))] = item
	_items_ready = true
	return _items


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


static func _item_by_id(id: String) -> Dictionary:
	all()
	var item: Variant = _by_id.get(id, {})
	return item if item is Dictionary else {}


static func _load_data() -> Dictionary:
	if _data_ready:
		return _data
	_data = _read_data_file()
	_data_ready = true
	return _data


static func _read_data_file() -> Dictionary:
	if not FileAccess.file_exists(DATA_PATH):
		return {}
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
