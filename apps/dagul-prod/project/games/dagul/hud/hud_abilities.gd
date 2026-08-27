class_name HudAbilities
extends RefCounted
## Q / 우클릭 / 대시 / 재장전 칸. 이름은 HudStrings, 키캡은 LayoutKeys.

const LayoutKeysScript := preload("res://core/input/layout_keys.gd")

var h: Control

func _init(hud: Control) -> void:
	h = hud

func draw_tray(me: Dictionary) -> void:
	var origin := Vector2(14.0, 808.0)
	var slot := Vector2(90.0, 70.0)
	var gap := 5.0
	var step := slot.x + gap
	_draw_ult_slot(Rect2(origin, slot), me)
	_draw_skill_slot(Rect2(origin + Vector2(step, 0.0), slot), me)
	_draw_dash_slot(Rect2(origin + Vector2(step * 2.0, 0.0), slot), me)
	_draw_reload_slot(Rect2(origin + Vector2(step * 3.0, 0.0), slot), me)

func _equip_id(me: Dictionary) -> String:
	return str(me.get("equipment", {}).get("id", "default"))

func _draw_frame(rect: Rect2, accent: Color, ready: bool) -> void:
	h.draw_rect(rect, Color(0.055, 0.064, 0.082, 0.94))
	h.draw_rect(rect, Color(accent, 0.90 if ready else 0.28), false, 2.0)

func _draw_ult_slot(rect: Rect2, me: Dictionary) -> void:
	var charge := float(me.get("ultimate_charge", 0.0))
	var ready := charge >= 99.5
	var animal := int(me.get("animal", 0))
	_draw_frame(rect, Color("#a970ff"), ready)
	var key := LayoutKeysScript.seat_label(KEY_Q)
	h._text(rect.position + Vector2(8.0, 14.0), key, 11, Color("#a970ff") if ready else Color("#6b7480"))
	h._text(rect.position + Vector2(8.0, 34.0), HudStrings.animal_ult(animal), 14, Color.WHITE, rect.size.x - 16.0)
	var status := HudStrings.t("hud_ult_ready") if ready else HudStrings.t("hud_ult_pct") % roundi(charge)
	h._text(rect.position + Vector2(8.0, 54.0), status, 11, Color("#c5ccd6"), rect.size.x - 16.0)

func _draw_skill_slot(rect: Rect2, me: Dictionary) -> void:
	var cd := float(me.get("equipment_cd", 0.0))
	var ready := cd <= 0.04
	_draw_frame(rect, Color("#ffb347"), ready)
	h._text(rect.position + Vector2(8.0, 14.0), HudStrings.t("hud_key_rmb"), 11, Color("#ffb347") if ready else Color("#6b7480"))
	h._text(rect.position + Vector2(8.0, 34.0), HudStrings.skill(_equip_id(me)), 14, Color.WHITE, rect.size.x - 16.0)
	var status := HudStrings.t("hud_ready") if ready else "%.1f" % cd
	h._text(rect.position + Vector2(8.0, 54.0), status, 11, Color("#c5ccd6"), rect.size.x - 16.0)

func _draw_dash_slot(rect: Rect2, me: Dictionary) -> void:
	var cd := float(me.get("mobility_cd", 0.0))
	var ready := cd <= 0.04
	var accent := Color("#66e09a")
	_draw_frame(rect, accent, ready)
	var key := HudStrings.t("touch_dash") if h.touch_hints else LayoutKeysScript.seat_label(KEY_SHIFT)
	h._text(rect.position + Vector2(8.0, 14.0), key, 11, accent if ready else Color("#6b7480"))
	h._text(rect.position + Vector2(8.0, 34.0), HudStrings.mobility(_equip_id(me)), 14, Color.WHITE, rect.size.x - 16.0)
	var status := HudStrings.t("hud_ready") if ready else "%.1f" % cd
	h._text(rect.position + Vector2(8.0, 54.0), status, 11, Color("#c5ccd6"), rect.size.x - 16.0)

func _draw_reload_slot(rect: Rect2, me: Dictionary) -> void:
	var left := float(me.get("reload_left", 0.0))
	var mag := int(me.get("mag", 0))
	var mag_max := int(me.get("equipment", {}).get("mag_size", 0))
	var reloading := left > 0.04
	var can_reload := (not reloading) and mag_max > 0 and mag < mag_max
	var active := reloading or can_reload
	var accent := Color("#ffd166")
	_draw_frame(rect, accent, active)
	var key := HudStrings.t("hud_reload_name") if h.touch_hints else LayoutKeysScript.seat_label(KEY_R)
	h._text(rect.position + Vector2(8.0, 14.0), key, 11, accent if active else Color("#6b7480"))
	h._text(rect.position + Vector2(8.0, 34.0), HudStrings.t("hud_reload_name"), 14, Color.WHITE, rect.size.x - 16.0)
	var status := "%d / %d" % [mag, mag_max]
	if reloading:
		status = HudStrings.t("hud_reload_time") % left
	elif can_reload:
		status = HudStrings.t("hud_ready")
	h._text(rect.position + Vector2(8.0, 54.0), status, 11, Color("#c5ccd6"), rect.size.x - 16.0)
