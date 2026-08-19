# godot-touch-controls

Godot 4.7 공용 터치 오버레이 (가로 파티게임용). 이동 스틱 + 조준 스틱 + 한글 액션 버튼.

## 사용법 (10줄)

1. 이 폴더를 프로젝트의 `addons/godot-touch-controls/` 로 복사하거나 심볼릭 링크한다.
2. 게임 루트에서 `preload("res://addons/godot-touch-controls/touch_controls.gd")` 후 `new()` 로 인스턴스.
3. HUD CanvasLayer 아래에 `add_child()` 한다 (자체 layer=2 로 HUD 위에 그림).
4. 플레이 페이즈 진입/해제 시 `set_playing(true/false)` 호출 — 아니면 숨김.
5. 표시 조건: `OS.has_feature("mobile")` 또는 터치스크린 또는 웹. 데스크톱 네이티브는 자동 숨김.
6. 매 틱 `move`(Vector2 -1..1, 데드존 0.12) 와 `aim_dir`/`aiming` 을 읽어 키보드/마우스와 병합.
7. 월드 조준은 `player_pos + aim_dir * 400` 처럼 변환 (카메라 변환 불필요).
8. 홀드 입력은 `fire`, `skill`, `dash_held`, `medkit_held`, `ult_held` 를 읽는다.
9. 엣지 입력은 `consume_dash()`, `consume_medkit()`, `consume_ult()` 로 1회 소비.
10. 스틱은 추가 관성 없이 즉시 매핑 (snappy). 폰트는 GameFont → gui/custom_font → ThemeDB 순.
