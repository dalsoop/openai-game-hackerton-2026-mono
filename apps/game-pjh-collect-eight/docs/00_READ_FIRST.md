# 8원 모으기 — Godot 독립 개발 패키지

## 이 패키지의 목적

이 ZIP 하나만 받아도 **8원 모으기**의 CPU 포함 회색상자 프로토타입을 만들고, 재미를 검증하고, 이후 실제 아트와 온라인 구조로 확장할 수 있게 구성했다.

핵심 문장:

> 광물을 집은 한 명이 즉시 모두의 표적이 되고, 추격 대상이 계속 바뀌는 운반 경쟁

첫 플레이 가능 목표:

> 6인 경쟁, 중앙 광물, 소유권 경합, 드롭·줍기·은행 예치·세 경로·CPU 가로막기가 작동하는 회색상자

기본 구성은 인간 1명 + CPU 5명이다. CPU는 숨은 정보를 읽지 않고, 초행 인간보다 약간 잘하며, 반응 지연과 의도된 판단 오류가 있다.

## 패키지 구성

```text
README.md
docs/
  00_READ_FIRST.md
  01_GAMEPLAY_SPEC.md
  02_GODOT_ARCHITECTURE.md
  03_CODE_BLUEPRINT.md
  04_CPU_AI_HEADLESS.md
  05_LEVEL_DATA_BALANCE.md
  06_PLAYTEST_TELEMETRY.md
  07_BUILD_ORDER.md
  08_ACCEPTANCE_RULES.md
  09_PIXI_TO_GODOT_MIGRATION.md
checklists/
  CHECKLIST_VIEWER.html
  implementation_checklist.csv
  implementation_checklist.json
  P0_P1_GATE.md
project/
  project.godot
  scenes/main.tscn
  scripts/
  data/
  tests/
```

## 실행

1. Godot 4.7.1에서 `project/project.godot`을 연다.
2. 프로젝트 매니저가 import를 끝내면 `F6`가 아니라 `F5`로 Main Scene을 실행한다.
3. 조작: **WASD 이동 · Space 대시/몸통박치기 · E 채취·줍기·예치 · R 재시작**
4. 회색상자 스타터는 시스템 전체의 최종 구현이 아니라 **첫 재미 검증용 세로 슬라이스**다.
5. 실제 개발은 `docs/07_BUILD_ORDER.md` 순서와 `checklists/P0_P1_GATE.md`를 따른다.

헤드리스 스모크 테스트:

```bash
godot --headless --path project --script res://tests/smoke_test.gd
```

## 반드시 발생해야 하는 장면

1. 7원을 가진 선두가 마지막 광물을 들고 은행 앞에서 넘어뜨려진다.
2. 모두가 운반자를 쫓는 동안 다른 플레이어가 떨어진 광물을 낚아챈다.
3. 추격자끼리 충돌해 오히려 운반자의 탈출로를 열어준다.
4. CPU가 최단경로가 아니라 예상 귀환로를 막아 인간을 놀라게 한다.

이 장면이 발생하지 않는다면 기능이 돌아가더라도 이 게임은 완성되지 않은 것이다.

## 재미 게이트

| 검증 항목 | 통과 기준 |
|---|---|
| 추격 전환 | 광물 소유권 1회당 추격 대상 전환 1.4회 이상 |
| 운반 성공률 | 광물 획득 후 예치 성공 28~48% |
| 가로막기 | CPU 추격 중 직접 뒤쫓기보다 예측 차단 선택 25~45% |
| 7원 클라이맥스 | 7원 보유자가 마지막 운반 중 공격받는 비율 70% 이상 |
| 소유권 오류 | 동일 틱 이중 소유·중복 예치 0건 |

## 구현 순서

| 마일스톤 | 완료 결과 |
|---|---|
| 8W-M0 | 한 광산·두 은행·채취·운반·예치 |
| 8W-M1 | 6인 CPU와 점수·승리 |
| 8W-M2 | 대시·밀치기·드롭·동시 경합 |
| 8W-M3 | 세 경로·문·예측 가로막기 |
| 8W-M4 | 7원 클라이맥스·카메라·인과 로그·헤드리스 |

마일스톤을 건너뛰지 않는다. 특히 CPU와 조작감을 마지막에 붙이면 재미 문제와 AI 문제를 구분할 수 없다.

## 문서 사용 원칙

- `01_GAMEPLAY_SPEC`: 무엇을 만들어야 하는가.
- `02_GODOT_ARCHITECTURE`: Godot에서 상태와 노드를 어떻게 나눌 것인가.
- `03_CODE_BLUEPRINT`: 파일·클래스·함수·틱 순서.
- `04_CPU_AI_HEADLESS`: CPU가 무엇을 보고 어떻게 판단하며 어떻게 검증되는가.
- `05_LEVEL_DATA_BALANCE`: 좌표·스폰·수치·데이터 계약.
- `06_PLAYTEST_TELEMETRY`: 재미를 수치와 관찰로 판정하는 법.
- `07_BUILD_ORDER`: 실제 작업 순서.
- `08_ACCEPTANCE_RULES`: 체크리스트 통과 규칙.
- `09_PIXI_TO_GODOT_MIGRATION`: 이전 PixiJS 명세를 Godot 개념으로 옮긴 대응표.

## 중요한 제한

원본 SCX 바이너리의 모든 트리거와 픽셀 좌표를 역분석한 복제본은 아니다. 공개적으로 확인되는 원형과 핵심 재미를 기준으로, 확인 불가능한 값은 프로토타입 정답값으로 고정했다. 따라서 목표는 **원본의 기억 가능한 핵심 루프와 사회적 상황을 재현하는 것**이며, 저작물·아트·명칭은 출시 전에 독자 자산으로 교체해야 한다.
