class_name CharacterView
extends RefCounted
## 히어로 정체는 character_id. animal 숫자는 카탈로그 bind 로만 읽는다.
## 랜덤 해소는 허브가 한다. 여기서 다시 굴리지 않는다.

const Catalog := preload("res://core/contract/character_catalog.gd")

static func id_of(hero: Dictionary) -> String:
	return Catalog.normalize(str(hero.get("character_id", "")))


static func apply_id(hero: Dictionary, raw: String) -> void:
	var id := Catalog.normalize(raw)
	hero["character_id"] = id
	hero["animal"] = Catalog.bind_int(id, Catalog.bind_key())


static func bind_of(hero: Dictionary) -> int:
	return Catalog.bind_int(id_of(hero), Catalog.bind_key())


static func atlas_index(hero: Dictionary) -> int:
	return Catalog.portrait_index(id_of(hero))
