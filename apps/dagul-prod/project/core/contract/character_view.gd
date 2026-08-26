class_name CharacterView
extends RefCounted
## 히어로 정체는 character_id. animal 숫자는 카탈로그 bind 로만 읽는다.
## 랜덤 해소는 허브가 한다. 여기서 다시 굴리지 않는다.

const Catalog := preload("res://core/contract/character_catalog.gd")

## id → 속성 Dictionary. 캐시 값은 불변. hero 에 넣을 때만 가변 항목을 복제한다.
static var _cache := {}

static func id_of(hero: Dictionary) -> String:
	return Catalog.normalize(str(hero.get("character_id", "")))


static func apply_id(hero: Dictionary, raw: String) -> void:
	var id := Catalog.normalize(raw)
	_merge_attrs(hero, _attrs_for(id))


static func _attrs_for(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var key := Catalog.bind_key()
	var animal := Catalog.bind_int(id, key)
	var binds := {}
	if animal >= 0:
		binds[key] = animal
	var attrs := {
		"character_id": id,
		"animal": animal,
		"binds": binds,
	}
	_cache[id] = attrs
	return attrs


static func _merge_attrs(hero: Dictionary, attrs: Dictionary) -> void:
	for key in attrs:
		hero[key] = _copy_cached(attrs[key])


static func _copy_cached(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate()
	if value is Array:
		return (value as Array).duplicate()
	return value


static func bind_of(hero: Dictionary) -> int:
	return Catalog.bind_int(id_of(hero), Catalog.bind_key())


static func atlas_index(hero: Dictionary) -> int:
	return Catalog.portrait_index(id_of(hero))
