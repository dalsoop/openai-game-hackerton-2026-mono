# 등산하기 — Godot 독립 개발 패키지

## 이 패키지의 목적

이 ZIP 하나만 받아도 **등산하기**의 CPU 포함 회색상자 프로토타입을 만들고, 재미를 검증하고, 이후 실제 아트와 온라인 구조로 확장할 수 있게 구성했다.

핵심 문장:

> 한 명만 정상에 도달하면 성공하지만, 서로의 정상 행동이 사고를 키우는 협동 등반

첫 플레이 가능 목표:

> 5개 스테이지, 낙석·벽·사망 깃발·구조·CPU 협동 사고가 모두 작동하는 회색상자

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
3. 조작: **WASD 이동 · Space 벽 · Q 폭탄 · E 감속망 · G 구조 · R 재시작**
4. 회색상자 스타터는 시스템 전체의 최종 구현이 아니라 **첫 재미 검증용 세로 슬라이스**다.
5. 실제 개발은 `docs/07_BUILD_ORDER.md` 순서와 `checklists/P0_P1_GATE.md`를 따른다.

헤드리스 스모크 테스트:

```bash
godot --headless --path project --script res://tests/smoke_test.gd
```

## 반드시 발생해야 하는 장면

1. 앞사람의 회피가 뒤사람의 길을 막아 연쇄 사망한다.
2. 구조하러 온 CPU가 위험을 끌고 와 구조자까지 쓰러진다.
3. 소유자 사망과 동시에 벽이 무너져 안전지대가 사라진다.
4. 한 명이 정상 직전까지 가면 죽은 인원도 관전하며 응원하게 된다.

이 장면이 발생하지 않는다면 기능이 돌아가더라도 이 게임은 완성되지 않은 것이다.

## 재미 게이트

| 검증 항목 | 통과 기준 |
|---|---|
| 첫 규칙 이해 | 초행자가 30초 안에 위로 이동·낙석 회피·벽의 용도를 설명 |
| 사건 밀도 | 스테이지당 기억 가능한 연쇄 사고 1.2~3.5회 |
| CPU 구조 | 안전한 구조 기회 중 55~78% 시도, 무모한 동반 사망 8~22% |
| 불공정 사망 | 경고 이전 또는 피할 공간 0인 사망 1% 미만 |
| 재도전 | 전멸 후 2.5초 이내 다시 조작 |

## 구현 순서

| 마일스톤 | 완료 결과 |
|---|---|
| MT-M0 | 한 스테이지, 인간 이동, 낙석, 사망, 즉시 재시작 |
| MT-M1 | 벽 설치·붕괴·소유자 사망 연쇄 |
| MT-M2 | CPU 5명 회피·진행·구조 |
| MT-M3 | 5스테이지·도구·카메라·관전 |
| MT-M4 | 인과 로그·헤드리스·재현 시드·조작 튜닝 |

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
