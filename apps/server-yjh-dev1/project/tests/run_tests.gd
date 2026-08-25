extends SceneTree
## 헤드리스 유닛 러너 — 루트 scripts/gd_test.py 가 --headless --script 로 실행한다.
## 계약: 각 체크는 "GDTEST PASS|FAIL <desc>" 한 줄, 마지막에 SUMMARY, 실패 시 exit 1.
## 테스트 파일은 export_presets exclude_filter="tests/*" 로 웹 산출물에 끼지 않는다.

const SUITES := [
	"res://tests/test_seeded_rng.gd",
	"res://tests/test_arena_geometry.gd",
	"res://tests/test_event_log.gd",
	"res://tests/test_safe_zone.gd",
	"res://tests/test_rooster_egg.gd",
	"res://tests/test_seat_codec.gd",
	"res://tests/test_gun_signature.gd",
	"res://tests/test_hub_state_sync.gd",
	"res://tests/test_touch_policy.gd",
]

var pass_count := 0
var fail_count := 0

func _init() -> void:
	for suite_path in SUITES:
		var suite = load(suite_path).new()
		suite.run(self)
	print("GDTEST SUMMARY pass=%d fail=%d" % [pass_count, fail_count])
	quit(1 if fail_count > 0 else 0)

func check(desc: String, ok: bool) -> void:
	if ok:
		pass_count += 1
		print("GDTEST PASS %s" % desc)
	else:
		fail_count += 1
		print("GDTEST FAIL %s" % desc)
