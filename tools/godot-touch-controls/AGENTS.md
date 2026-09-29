# tools/godot-touch-controls

## 맡는 일

모든 Godot 슬롯이 함께 쓰는 터치 오버레이 애드온이다. 왼쪽 이동 스틱, 조준·발사를 겸하는 오른쪽 스틱, 대시·궁극기 버튼을 그린다. 각 슬롯의 `project/addons/godot-touch-controls`는 이 폴더로 가는 심볼릭 링크이고, 웹 익스포트가 이 폴더를 묶어야 하므로 git에 둔다.

## 맡지 않는 일

- 게임별 입력 해석(월드 조준 좌표 계산, 키보드·마우스와의 병합)은 각 게임의 입력 모듈이 맡는다.
- 설정 화면(조작 방식 선택 UI)은 각 슬롯의 UI가 맡고, 여기서는 `set_control_mode`만 받는다.
- 슬롯별 복사본을 만들지 않는다. 링크를 실제 폴더로 바꾸면 슬롯마다 애드온이 갈라진다.

## 불변 조건

- 이 폴더를 고치면 `dagul-prod`, `server-pjh-dev1`, `server-fig-dev1`이 모두 바뀐다. 고친 뒤에는 세 슬롯에서 동작을 확인한다.
- 공개 API(`move`, `aim_dir`, `aiming`, `aim_last`, `fire`, `dash_held`, `ult_held`, `skill`, `medkit_held`, `set_playing`, `set_control_mode`, `is_enabled`, `consume_dash`, `consume_ult`, `consume_aim_tap`, `consume_medkit`)의 이름과 의미를 바꾸면 슬롯 코드가 깨진다. 슬롯은 `preload` 없이 경로 문자열로 로드하므로 컴파일 단계에서 잡히지 않는다.
- `set_control_mode`는 `"auto"`(플랫폼 감지), `"keyboard"`(항상 숨김), `"touch"`(항상 표시) 세 값만 받는다.
- `touch_controls.gd`의 `AIM_RANGE`(400)는 `apps/dagul-prod/project/games/dagul/input/player_input.gd`에 같은 값으로 복제되어 있다. 탭 판정 규칙(`virtual_stick.gd`의 `is_tap`)은 `apps/dagul-prod/project/core/contract/touch_policy.gd`에 복제되어 있다. 여기 값을 바꾸면 두 곳을 함께 바꾼다. 링크가 없는 체크아웃에서도 게임이 뜨도록 일부러 복제한 것이다.

## 구현 패턴

- 루트 노드는 `CanvasLayer`(layer 2)이고, 플레이 중(`set_playing(true)`)이면서 플랫폼 조건을 만족할 때만 보인다.
- 한 번만 처리할 입력(대시, 궁극기, 탭 발사, 메디킷)은 `consume_*`로 읽으면서 지운다. 계속 눌린 상태는 `*_held` 속성으로 읽는다.

## 테스트

- 이 애드온 자체를 검사하는 자동 테스트는 없다. `apps/dagul-prod/project/tests/test_virtual_stick.gd`는 링크가 해석되지 않는 체크아웃에서도 돌도록 애드온 대신 복제된 탭 규칙(`touch_policy.gd`)을 검사한다(`python3 scripts/gd_test.py`).
- 탭 임계값이나 판정 방식을 바꾸면 `touch_policy.gd`와 그 테스트를 함께 고친다.
- 데드존(0.12), 손을 뗀 뒤 `aim_last` 유지, `keyboard` 모드에서 숨김 같은 동작은 웹 빌드를 모바일 폭으로 띄워 직접 확인한다.
