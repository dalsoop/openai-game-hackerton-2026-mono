# tools

공용 스크립트 자리. v0는 앱 내부 npm 스크립트만 사용.

## godot-touch-controls · control mode (2026-08-20)

`touch_controls.gd` 에 `set_control_mode(mode: String)` / `is_enabled()` 를 추가했다.
`mode` 는 `"auto"`(플랫폼 감지) · `"keyboard"`(항상 숨김) · `"touch"`(항상 표시).
`apps/server-yjh-dev1` 의 설정창(조작 방식: 자동 / PC 키보드형 / 모바일형)이 이 API를 호출한다.
웹 익스포트가 이 폴더를 묶어야 하므로 git에 둔다. `apps/server-*/project/addons/godot-touch-controls` 는 여기로 가는 링크다.
