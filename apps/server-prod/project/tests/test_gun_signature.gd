extends RefCounted
## 무기 서명 매핑 — 12동물 슬롯×장비·비주얼·계열 정합성.
## class_name 은 --script 단독 실행에서 글로벌 캐시에 없다. preload 가 정본이다.

const GunSignature := preload("res://games/dagul/sim/gun_signature.gd")

func run(t) -> void:
	# 12동물 전 슬롯이 서명 무기를 갖는다
	var all_mapped := true
	for slot in range(12):
		if GunSignature.equipment_for_animal(slot) == "":
			all_mapped = false
	t.check("all 12 slots mapped", all_mapped)

	# 서명 판정 — 슬롯과 장비가 일치할 때만 참
	t.check("signature matches own slot", GunSignature.is_signature(0, "burst"))
	t.check("signature rejects other equipment", GunSignature.is_signature(0, "blade") == false)
	t.check("signature rejects out-of-range slot", GunSignature.is_signature(99, "burst") == false)

	# 비주얼·계열은 등록된 장비만, 미등록은 폴백("burst")
	t.check("visual has frame+gun", GunSignature.visual_for_equipment("spear").has("frame") and GunSignature.visual_for_equipment("spear").has("gun"))
	t.check("visual fallback to burst", GunSignature.visual_for_equipment("unknown").get("gun", "") == "Glock 18")
	t.check("family of registered", GunSignature.family_of("rail") == "heavy")
	t.check("family fallback empty-ish", GunSignature.family_of("unknown") != "heavy")

	# 프레임 중복 없음 — 각 총 그림 한 번씩(주석 계약)
	var frames := []
	for equip in GunSignature.EQUIP_VISUAL:
		frames.append(int(GunSignature.EQUIP_VISUAL[equip]["frame"]))
	var unique := true
	for i in range(frames.size()):
		for j in range(i + 1, frames.size()):
			if frames[i] == frames[j]:
				unique = false
	t.check("visual frames unique (0..11)", unique and frames.size() == 12)

	# 느낌(반동) — 등록 장비는 양수 kick, 미등록은 폴백
	t.check("feel kick positive", float(GunSignature.feel_for_equipment("scatter")["kick"]) > 0.0)
	t.check("feel fallback burst", GunSignature.feel_for_equipment("unknown") == GunSignature.feel_for_equipment("burst"))

	# 스프레이 — 인덱스를 넘겨도 마지막 단계 클램프(존재 검증)
	var step := GunSignature.spray_kick("spear", 0)
	t.check("spray kick is Vector2", step is Vector2)
