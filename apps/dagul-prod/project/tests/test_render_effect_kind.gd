extends RefCounted
## 이펙트 kind 라우팅 — 서버 match-skill/match-effects 문자열이 십자 플래시로 떨어지지 않게.

const Proj := preload("res://games/dagul/render/render_projectiles.gd")


func run(t) -> void:
	var dummy := Node2D.new()
	var proj = Proj.new(dummy)
	t.check("cast 는 beam 계열", proj.effect_family(&"cast") == &"beam")
	t.check("blast_hop 는 mobility(impact) 계열", proj.effect_family(&"blast_hop") == &"impact")
	t.check("line 은 beam 유지", proj.effect_family(&"line") == &"beam")
	t.check("speed_streak 는 impact 유지", proj.effect_family(&"speed_streak") == &"impact")
	t.check("heal_pickup 은 pickup 유지", proj.effect_family(&"heal_pickup") == &"pickup")
	t.check("미등록 kind 는 pickup 폴백", proj.effect_family(&"unknown_fx") == &"pickup")
	dummy.free()
