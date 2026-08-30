# godot-touch-controls

Godot 4.7 공용 터치 오버레이 (가로 파티게임용). 이동 스틱 + 조준·발사 스틱 + 한글 액션 버튼.

## 조작 개요

- **왼쪽 스틱** — 이동만.
- **오른쪽 스틱** — 조준과 발사가 하나다. 밀고 있으면 그 방향으로 계속 쏘고, 손을 떼면 멈추되 **바라보는 방향은 남는다**. 밀지 않고 툭 치면(탭) 마지막 방향으로 한 발.
- **버튼** — 대시, 궁 둘뿐. 공격 버튼은 오른쪽 스틱에 흡수돼 없앴다.

## 사용법 (10줄)

1. 이 폴더를 프로젝트의 `addons/godot-touch-controls/` 로 복사하거나 심볼릭 링크한다.
2. 게임 루트에서 `preload("res://addons/godot-touch-controls/touch_controls.gd")` 후 `new()` 로 인스턴스.
3. HUD CanvasLayer 아래에 `add_child()` 한다 (자체 layer=2 로 HUD 위에 그림).
4. 플레이 페이즈 진입/해제 시 `set_playing(true/false)` 호출 — 아니면 숨김.
5. 표시 조건: `OS.has_feature("mobile")` 또는 터치스크린 또는 웹. 데스크톱 네이티브는 자동 숨김.
6. 매 틱 `move`(Vector2 -1..1, 데드존 0.12) 와 `aim_last` 를 읽어 키보드/마우스와 병합.
7. 월드 조준은 `player_pos + aim_last * AIM_RANGE`. `aim_last` 는 손을 떼도 남으므로 항상 유효하다.
8. 홀드 입력은 `fire`(= 조준 스틱을 밀고 있음), `dash_held`, `ult_held` 를 읽는다.
9. 엣지 입력은 `consume_aim_tap()`(탭 1발), `consume_dash()`, `consume_ult()` 로 1회 소비. 틱당 한 번만 호출할 것.
10. 스틱은 추가 관성 없이 즉시 매핑 (snappy). 폰트는 GameFont → gui/custom_font → ThemeDB 순.

## 호환 스텁

`skill`, `medkit_held`, `consume_medkit()` 는 해당 버튼을 없앴지만 이 패드를 함께 쓰는 다른 앱이 읽으므로 이름만 남겨 두고 항상 `false` 를 준다. 새 코드는 쓰지 말 것.

## 조준 스틱 세부

- `aim_dir` / `aiming` — 미는 **동안만** 유효한 실시간 값.
- `aim_last` — 마지막 유효 방향. 손을 떼도, `reset()` 후에도 남는다. 조준은 이걸 쓴다.
- 탭 판정은 `tap_max_travel`(기본 24px), `tap_max_msec`(기본 250ms). 순수 함수 `VirtualStick.is_tap()` 로 분리돼 테스트가 붙는다.
- 누른 지점이 원점이다. 스틱 가장자리를 처음 찍어도 최대 편향으로 튀지 않는다.
