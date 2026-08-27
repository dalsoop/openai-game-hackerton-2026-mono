class_name HudBuffs
extends RefCounted

static func roulette_rank_color(rank: String) -> Color:
	if rank == "assist":
		return Color("#4da3ff")
	if rank == "wanted":
		return Color("#ff3349")
	return Color("#b84dff")

static func collect_buff_icons(me: Dictionary, world_mode: String) -> Array:
	var icons: Array = []
	var until_stats: Dictionary = me.get("until_buffs", {})
	var until_meta := [
		{"key":"atk", "id":"atk", "label":"ATK", "color":Color("#ff6b4a")},
		{"key":"spd", "id":"spd", "label":"SPD", "color":Color("#70e7ff")},
		{"key":"def", "id":"def", "label":"DEF", "color":Color("#8ad0ff")},
		{"key":"hp", "id":"hp", "label":"HP", "color":Color("#6ef3a5")},
		{"key":"rate", "id":"rate", "label":"RATE", "color":Color("#ffd166")},
		{"key":"range", "id":"range", "label":"RNG", "color":Color("#e8d5ff")}
	]
	for meta in until_meta:
		var value := float(until_stats.get(str(meta["key"]), 0.0))
		if value > 0.001:
			var shown := ("%d%%" % int(round(value * 100.0))) if str(meta["key"]) in ["def", "rate", "range"] else ("%d" % int(round(value)))
			icons.append({"id":str(meta["id"]), "label":str(meta["label"]), "color":meta["color"], "text":shown, "time":0.0, "kind":"until"})
	for buff in me.get("timed_buffs", []):
		var bid := str(buff.get("id", buff.get("name", "buff"))).to_lower()
		var left := float(buff.get("time", 0.0))
		var extra := ""
		if float(buff.get("shield", 0.0)) > 0.01:
			extra = "%d" % int(round(float(buff["shield"])))
		icons.append({"id":bid, "label":str(buff.get("name", "BUFF")), "color":timed_buff_color(bid), "text":extra, "time":left, "kind":"timed"})
	if float(me.get("dmg_orb_time", 0.0)) > 0.05:
		icons.append({"id":"dmg_orb", "label":"DMG", "color":Color("#ff3349"), "text":"", "time":float(me["dmg_orb_time"]), "kind":"orb"})
	if float(me.get("spawn_protect_time", 0.0)) > 0.05:
		icons.append({"id":"protect", "label":"SAFE", "color":Color("#ffe36a"), "text":"", "time":float(me["spawn_protect_time"]), "kind":"item"})
	if float(me.get("slide_time", 0.0)) > 0.05:
		icons.append({"id":"slide", "label":"ICE", "color":Color("#70e7ff"), "text":"", "time":float(me["slide_time"]), "kind":"item"})
	if float(me.get("pocket_time", 0.0)) > 0.05:
		icons.append({"id":"pocket", "label":"ZONE", "color":Color("#f4e2ff"), "text":"", "time":float(me["pocket_time"]), "kind":"item"})
	if float(me.get("spring_time", 0.0)) > 0.05:
		icons.append({"id":"spring", "label":"HOP", "color":Color("#ffe066"), "text":"", "time":float(me["spring_time"]), "kind":"item"})
	var held := str(me.get("held_item", ""))
	if held != "" and world_mode == "item":
		icons.append({"id":held, "label":held_item_label(held), "color":held_item_color(held), "text":"E", "time":0.0, "kind":"held"})
	return icons

static func timed_buff_color(buff_id: String) -> Color:
	match buff_id:
		"giant", "double_giant":
			return Color("#ff9f1c")
		"shield":
			return Color("#70e7ff")
		"berserk":
			return Color("#ff3349")
		"turtle":
			return Color("#6ef3a5")
		"sniper":
			return Color("#c8d5e4")
		_:
			return Color("#b84dff")

static func held_item_label(kind: String) -> String:
	match kind:
		"medkit":
			return "MEDKIT"
		"spring":
			return "SPRING"
		"slide":
			return "SLIDE"
		"pull":
			return "PULL"
		"pocket":
			return "POCKET"
		"decoy":
			return "DECOY"
		_:
			return "EMPTY"

static func held_item_color(kind: String) -> Color:
	match kind:
		"medkit":
			return Color("#6ef3a5")
		"spring":
			return Color("#ffe066")
		"slide":
			return Color("#70e7ff")
		"pull":
			return Color("#b78cff")
		"pocket":
			return Color("#f4e2ff")
		"decoy":
			return Color("#ff9f7a")
		_:
			return Color("#6b7480")

static func roulette_effect_line(buff_id: String, won: String) -> String:
	var key := "buff_%s" % buff_id
	var result := HudStrings.t(key)
	if result != key:
		return result
	if won != "":
		return won
	return HudStrings.t("buff_default")

static func draw_buff_glyph(canvas: CanvasItem, c: Vector2, buff_id: String, accent: Color, roulette_icons: Dictionary) -> void:
	var icon_tex: Texture2D = roulette_icons.get(buff_id) as Texture2D
	if icon_tex != null:
		var size := 28.0 if buff_id == "medkit" else 32.0
		canvas.draw_texture_rect(icon_tex, Rect2(c - Vector2(size, size) * 0.5, Vector2(size, size)), false)
		return
	if _draw_stat_glyph(canvas, c, buff_id, accent):
		return
	_draw_effect_glyph(canvas, c, buff_id, accent)

static func _draw_stat_glyph(canvas: CanvasItem, c: Vector2, buff_id: String, accent: Color) -> bool:
	match buff_id:
		"atk":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0.0, -10.0), c + Vector2(7.0, 8.0), c + Vector2(-7.0, 8.0)]), accent)
		"spd":
			canvas.draw_line(c + Vector2(-8.0, 0.0), c + Vector2(8.0, 0.0), accent, 3.0)
			canvas.draw_line(c + Vector2(2.0, -6.0), c + Vector2(8.0, 0.0), accent, 3.0)
			canvas.draw_line(c + Vector2(2.0, 6.0), c + Vector2(8.0, 0.0), accent, 3.0)
		"def", "shield":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0.0, -10.0), c + Vector2(9.0, -4.0), c + Vector2(7.0, 8.0), c + Vector2(0.0, 11.0), c + Vector2(-7.0, 8.0), c + Vector2(-9.0, -4.0)]), accent)
		"hp", "medkit":
			canvas.draw_rect(Rect2(c + Vector2(-3.0, -9.0), Vector2(6.0, 18.0)), accent)
			canvas.draw_rect(Rect2(c + Vector2(-9.0, -3.0), Vector2(18.0, 6.0)), accent)
		"rate":
			canvas.draw_circle(c + Vector2(-7.0, 0.0), 3.0, accent)
			canvas.draw_circle(c, 3.0, accent)
			canvas.draw_circle(c + Vector2(7.0, 0.0), 3.0, accent)
		"range", "sniper":
			canvas.draw_arc(c, 8.0, 0.0, TAU, 20, accent, 2.0)
			canvas.draw_line(c + Vector2(-10.0, 0.0), c + Vector2(10.0, 0.0), accent, 1.5)
			canvas.draw_line(c + Vector2(0.0, -10.0), c + Vector2(0.0, 10.0), accent, 1.5)
		"giant", "double_giant":
			_draw_giant_glyph(canvas, c, buff_id, accent)
		_:
			return false
	return true

static func _draw_giant_glyph(canvas: CanvasItem, c: Vector2, buff_id: String, accent: Color) -> void:
	canvas.draw_circle(c + Vector2(0.0, -6.0), 5.0, accent)
	canvas.draw_rect(Rect2(c + Vector2(-6.0, -1.0), Vector2(12.0, 12.0)), accent)
	if buff_id == "double_giant":
		canvas.draw_circle(c + Vector2(8.0, -4.0), 3.5, Color.WHITE)

static func _draw_effect_glyph(canvas: CanvasItem, c: Vector2, buff_id: String, accent: Color) -> void:
	match buff_id:
		"berserk":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-2.0, 10.0), c + Vector2(-8.0, -2.0), c + Vector2(-1.0, 1.0), c + Vector2(2.0, -11.0), c + Vector2(8.0, 2.0), c + Vector2(1.0, -1.0)]), accent)
		"turtle":
			canvas.draw_circle(c, 9.0, accent)
			canvas.draw_arc(c, 6.0, 0.4, PI + 0.4, 12, Color(0.02, 0.03, 0.05, 0.85), 2.0)
		"dmg_orb":
			canvas.draw_circle(c, 9.0, accent)
			canvas.draw_circle(c, 4.0, Color.WHITE)
		"protect":
			canvas.draw_arc(c, 9.0, 0.0, TAU, 18, accent, 2.5)
			canvas.draw_circle(c, 3.0, Color.WHITE)
		"slide":
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-9.0, 6.0), c + Vector2(9.0, 6.0), c + Vector2(5.0, -8.0), c + Vector2(-4.0, -2.0)]), accent)
		"pocket":
			canvas.draw_arc(c, 9.0, 0.0, TAU, 20, accent, 2.5)
			canvas.draw_circle(c, 3.5, Color(accent, 0.55))
		"spring":
			canvas.draw_line(c + Vector2(-7.0, 8.0), c + Vector2(-2.0, -2.0), accent, 2.5)
			canvas.draw_line(c + Vector2(-2.0, -2.0), c + Vector2(3.0, 6.0), accent, 2.5)
			canvas.draw_line(c + Vector2(3.0, 6.0), c + Vector2(8.0, -8.0), accent, 2.5)
		"pull":
			canvas.draw_arc(c, 8.0, PI * 0.15, PI * 0.85, 10, accent, 2.5)
			canvas.draw_line(c + Vector2(-2.0, 8.0), c + Vector2(0.0, 2.0), accent, 2.5)
		"decoy":
			canvas.draw_circle(c + Vector2(0.0, -3.0), 6.0, accent)
			canvas.draw_circle(c + Vector2(-2.5, -4.5), 1.4, Color.WHITE)
			canvas.draw_circle(c + Vector2(2.5, -4.5), 1.4, Color.WHITE)
		_:
			canvas.draw_circle(c, 8.0, accent)
