# 지원하며 버티기 — Godot 독립 개발 패키지

## 이 패키지의 목적

이 ZIP 하나만 받아도 **지원하며 버티기**의 CPU 포함 회색상자 프로토타입을 만들고, 재미를 검증하고, 이후 실제 아트와 온라인 구조로 확장할 수 있게 구성했다.

핵심 문장:

> 전선과 보급이 서로 의존하며 한 사람의 작은 지연이 다른 라인까지 번지는 역할 협동

첫 플레이 가능 목표:

> 3개 병사·3개 보급 역할, 3라인, 생산·배송·요청·라인 이탈·5페이즈 Hive 공략이 작동하는 회색상자

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
3. 조작: **1~6 조작 전환 · WASD 이동 · 좌클릭 사격/보급 지정 · Q 수류탄/품목 변경 · F 탄약요청 · E 치료요청 · Space 장벽요청 · R 재시작**
4. 회색상자 스타터는 시스템 전체의 최종 구현이 아니라 **첫 재미 검증용 세로 슬라이스**다.
5. 실제 개발은 `docs/07_BUILD_ORDER.md` 순서와 `checklists/P0_P1_GATE.md`를 따른다.

헤드리스 스모크 테스트:

```bash
godot --headless --path project --script res://tests/smoke_test.gd
```

## 반드시 발생해야 하는 장면

1. 한 라인의 탄약 요청이 늦어져 다른 라인의 지원 병력이 이동하고 연쇄 공백이 생긴다.
2. 보급품이 도착 직전 파괴되어 전선이 무너지지만 원인이 명확하게 남는다.
3. CPU 보급 담당이 완벽하지 않은 예측으로 틀린 물자를 보내 상황이 꼬인다.
4. 생존 국면이 끝나면 전원이 Hive 역공으로 전환해 역할의 의미가 바뀐다.

이 장면이 발생하지 않는다면 기능이 돌아가더라도 이 게임은 완성되지 않은 것이다.

## 재미 게이트

| 검증 항목 | 통과 기준 |
|---|---|
| 상호의존 | 보급 이벤트가 전선 결과에 기여하는 비율 45~75% |
| 연쇄 원인 | 거점 손실의 80% 이상이 최대 6단계 인과 그래프로 설명 |
| CPU 보급 | 실제 수요 적중 65~82%, 의도적 오판 8~18% |
| 대기 시간 | 병사 무탄약 무행동 연속 4초 초과 비율 3% 미만 |
| 역할 재미 | 6역할 각각 분당 의미 있는 결정 5회 이상 |

## 구현 순서

| 마일스톤 | 완료 결과 |
|---|---|
| SH-M0 | 한 라인·병사 1·보급 1·탄약 배송 |
| SH-M1 | 3라인·CPU 5명·요청·라인 이동 |
| SH-M2 | 6역할·생산 큐·배송 파괴 |
| SH-M3 | 3개 방어 페이즈·연쇄 붕괴 |
| SH-M4 | Hive 2페이즈·역공·인과 그래프 |
| SH-M5 | 역할 교환·관전·헤드리스·밸런스 |

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
