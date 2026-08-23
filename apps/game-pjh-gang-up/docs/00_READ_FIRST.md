# 다굴게임 — Godot 독립 개발 패키지

## 이 패키지의 목적

이 ZIP 하나만 받아도 **다굴게임**의 CPU 포함 회색상자 프로토타입을 만들고, 재미를 검증하고, 이후 실제 아트와 온라인 구조로 확장할 수 있게 구성했다.

핵심 문장:

> 강해 보이는 순간 모두의 적이 되고, 임시 동맹과 배신이 매초 바뀌는 난전

첫 플레이 가능 목표:

> 6인 개인전, 각자 코어, 랜덤 조합, 위협도·현상금·CPU 정치·배신이 작동하는 회색상자

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
3. 조작: **WASD 이동 · 마우스 조준 · 좌클릭 공격 · Q 주능력 · E 보조능력 · R 재시작**
4. 회색상자 스타터는 시스템 전체의 최종 구현이 아니라 **첫 재미 검증용 세로 슬라이스**다.
5. 실제 개발은 `docs/07_BUILD_ORDER.md` 순서와 `checklists/P0_P1_GATE.md`를 따른다.

헤드리스 스모크 테스트:

```bash
godot --headless --path project --script res://tests/smoke_test.gd
```

## 반드시 발생해야 하는 장면

1. 좋은 조합을 뽑은 플레이어가 시작 직후 공공의 적이 된다.
2. 두 CPU가 한 대상을 치다가 체력이 약해진 순간 서로 배신한다.
3. 뒤처진 플레이어가 현상금을 이용해 일시적으로 살아남는다.
4. 선두를 잡은 직후 새로운 선두에게 공격 관계선이 몰린다.

이 장면이 발생하지 않는다면 기능이 돌아가더라도 이 게임은 완성되지 않은 것이다.

## 재미 게이트

| 검증 항목 | 통과 기준 |
|---|---|
| 정치 발생 | 한 판당 타깃 재편 8~24회, 동맹 파기 2~8회 |
| 인간 집중 방지 | 인간이 3명 이상에게 동시에 4초 넘게 집중되는 시간 12% 미만 |
| 선두 압박 | 위협도 1위가 8초 안에 평균 1.8명 이상에게 표적 |
| 무기 격차 | 최상 조합 승률 22~38%, 최하 조합 승률 7~15% |
| 정체 | 무피해 12초 구간 판당 1회 이하 |

## 구현 순서

| 마일스톤 | 완료 결과 |
|---|---|
| GU-M0 | 인간 1명, 코어 2개, 이동·사격·코어 파괴 |
| GU-M1 | 6인 CPU, 타깃 선정, 인간 집중 방지 |
| GU-M2 | 아키타입·능력·패시브 랜덤 조합 |
| GU-M3 | 위협도·현상금·원한·임시 동맹·배신 |
| GU-M4 | 정체 방지·관전·인과 로그·밸런스 시뮬레이션 |

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
