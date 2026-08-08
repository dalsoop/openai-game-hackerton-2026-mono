# 신 마을 지키기 — Godot 독립 개발 패키지

## 이 패키지의 목적

이 ZIP 하나만 받아도 **신 마을 지키기**의 CPU 포함 회색상자 프로토타입을 만들고, 재미를 검증하고, 이후 실제 아트와 온라인 구조로 확장할 수 있게 구성했다.

핵심 문장:

> 협동 디펜스 안에서 막타·진화·전선 이동·광역 방해가 비공식 경쟁을 만드는 성장전

첫 플레이 가능 목표:

> 4라인·12웨이브·6영웅·킬 진화·업그레이드·CPU 역할 이동·최종 보스가 작동하는 회색상자

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
3. 조작: **WASD 이동 · 마우스 조준 · 좌클릭 기본공격 · Q 주스킬 · E 스테이시스 · U 강화 · R 재시작**
4. 회색상자 스타터는 시스템 전체의 최종 구현이 아니라 **첫 재미 검증용 세로 슬라이스**다.
5. 실제 개발은 `docs/07_BUILD_ORDER.md` 순서와 `checklists/P0_P1_GATE.md`를 따른다.

헤드리스 스모크 테스트:

```bash
godot --headless --path project --script res://tests/smoke_test.gd
```

## 반드시 발생해야 하는 장면

1. 한 라인의 막타 경쟁 때문에 다른 라인이 잠시 비어 연쇄 지원이 발생한다.
2. 스테이시스가 적과 아군 모두를 멈춰 좋은 구조인지 분탕인지 논쟁이 생긴다.
3. 한 CPU가 진화 직전이라 무리하다 쓰러지고 다른 영웅이 수습한다.
4. 최종 보스가 마을 내부로 들어오며 성장 경쟁이 공동 생존으로 전환된다.

이 장면이 발생하지 않는다면 기능이 돌아가더라도 이 게임은 완성되지 않은 것이다.

## 재미 게이트

| 검증 항목 | 통과 기준 |
|---|---|
| 라인 붕괴 가독성 | 마을 피해의 직접 원인을 5초 안에 플레이어가 지목 |
| 막타 경쟁 | 킬 20% 이상이 둘 이상의 영웅 공격 경합에서 발생 |
| 역할 이동 | CPU 라인 이동 중 실제 압력 완화 성공 60~82% |
| 대량 성능 | 권장 PC에서 500적 회색상자 60 physics FPS 유지 |
| 성장 체감 | 진화 직후 20초 DPS 또는 제어 기여 18~35% 증가 |

## 구현 순서

| 마일스톤 | 완료 결과 |
|---|---|
| VD-M0 | 한 라인·한 영웅·한 적·마을 피해 |
| VD-M1 | 4라인·CPU 5명·흐름장 |
| VD-M2 | 킬·진화·업그레이드·막타 경합 |
| VD-M3 | 8직업·스테이시스·역할 이동 |
| VD-M4 | 12웨이브·최종 보스·대량 성능 |
| VD-M5 | 헤드리스·장기 회귀·인과 결과 |

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
