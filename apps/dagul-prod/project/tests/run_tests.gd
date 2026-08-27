extends SceneTree
## 헤드리스 유닛 러너 — 루트 scripts/gd_test.py 가 --headless --script 로 실행한다.
## 계약: 각 체크는 "GDTEST PASS|FAIL <desc>" 한 줄, 마지막에 SUMMARY, 실패 시 exit 1.
## 테스트 파일은 export_presets exclude_filter="tests/*" 로 웹 산출물에 끼지 않는다.

const SUITES := [
	"res://tests/test_seeded_rng.gd",
	"res://tests/test_arena_geometry.gd",
	"res://tests/test_grass_tile_index.gd",
	"res://tests/test_text_cache.gd",
	"res://tests/test_event_log.gd",
	"res://tests/test_safe_zone.gd",
	"res://tests/test_rooster_egg.gd",
	"res://tests/test_seat_codec.gd",
	"res://tests/test_character_catalog.gd",
	"res://tests/test_gun_signature.gd",
	"res://tests/test_hub_state_sync.gd",
	"res://tests/test_touch_policy.gd",
	"res://tests/test_touch_pad.gd",
	"res://tests/test_game_state_autoload.gd",
	"res://tests/test_input_release.gd",
	"res://tests/test_layout_keys.gd",
	"res://tests/test_net_world.gd",
	"res://tests/test_net_pred.gd",
	"res://tests/test_render_locomotion.gd",
	"res://tests/test_render_effect_kind.gd",
	"res://tests/test_snap_contract.gd",
	"res://tests/test_network_bridge.gd",
	"res://tests/test_match_snap_adapter.gd",
	"res://tests/test_engine_socket_fallback.gd",
	"res://tests/test_engine_input_channel.gd",
	"res://tests/test_engine_predict.gd",
	"res://tests/test_rb1_client.gd",
	"res://tests/test_settings_store.gd",
	"res://tests/test_play_chrome.gd",
	"res://tests/test_perf_overlay.gd",
]

var pass_count := 0
var fail_count := 0

func _init() -> void:
	# 오토로드(/root/GameState 등)는 메인 루프 첫 프레임 뒤에 붙는다.
	call_deferred("_run_all")

func _run_all() -> void:
	for suite_path in SUITES:
		var script = load(suite_path)
		if script == null or not script.can_instantiate():
			check("load " + suite_path, false)
			continue
		var suite = script.new()
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
