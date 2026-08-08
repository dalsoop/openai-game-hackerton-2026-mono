# 신 마을 지키기 — Godot 4.7.1 독립 패키지

이 ZIP은 다른 네 게임이나 별도 공통 저장소에 의존하지 않는다. **이 폴더 하나만으로** 문서를 읽고, CPU 포함 회색상자를 실행하고, 체크리스트를 관리할 수 있다.

## 바로 실행

1. Godot **4.7.1 Standard**에서 `project/project.godot`을 연다.
2. import가 끝나면 `F5`를 누른다.
3. P1 헌터: **WASD 이동 · 마우스 조준/좌클릭 공격 · Q 스킬 · E 스테이시스 · Space 패닉 · U 강화**
4. P2 메이지: **방향키 이동/조준 · Enter 준비/공격 · Shift 스킬 · . 스테이시스 · / 패닉 · Backspace 강화**
5. 두 플레이어가 모두 준비해야 시작하며, `R`은 새 시드로 즉시 재시작한다.

Windows에서 Godot 실행 파일이 PATH에 등록돼 있으면:

```bat
RUN_GAME_WINDOWS.bat
RUN_SMOKE_WINDOWS.bat
```

Linux/macOS:

```bash
chmod +x RUN_GAME.sh RUN_SMOKE.sh
./RUN_GAME.sh
./RUN_SMOKE.sh
```

## 현재 들어 있는 실행물

- 로컬 인간 **2명** + CPU **4명** (서로 다른 직업과 역할 스킬)
- 아트 없이도 핵심 판정과 상황을 읽을 수 있는 1600×900 회색상자
- 고정 시드 RNG, 60Hz 커스텀 시뮬레이션, 인과 EventLog
- 즉시 재시작, 결과 요약, NaN/INF 검사
- 헤드리스 smoke test
- 상용 핵심 루프 강화: 역할별 이동 관성·반동, 어시스트 코인, 처치 콤보, 역할 시너지, 스테이시스 혼돈 부채와 피해자 탈출 역공, 공유 패닉 벨 토큰과 적 격분
- 첫 재미 검증 목표: **4라인·12웨이브·6영웅·킬 진화·업그레이드·CPU 역할 이동·최종 보스가 작동하는 회색상자**

회색상자는 최종 콘텐츠 완성본이 아니라, 최종 구현을 시작하기 전에 핵심 재미를 직접 느끼고 수치 방향을 잡는 **실행 가능한 M0**다. 최종 재현 범위는 `docs/`와 **3,731개 체크리스트**가 정답이다.

## 읽는 순서

1. `docs/00_READ_FIRST.md`
2. `docs/01_GAMEPLAY_SPEC.md`
3. `docs/02_GODOT_ARCHITECTURE.md`
4. `docs/03_CODE_BLUEPRINT.md`
5. `docs/04_CPU_AI_HEADLESS.md`
6. `docs/05_LEVEL_DATA_BALANCE.md`
7. `docs/07_BUILD_ORDER.md`
8. `checklists/CHECKLIST_VIEWER.html`

## 중요 원칙

- `GameWorld`만 승패·위치·체력·소유권을 결정한다.
- Node2D·Sprite2D·AnimationPlayer·시그널 순서는 판정의 정답이 아니다.
- CPU는 인간과 같은 명령·쿨다운·충돌 규칙을 사용한다.
- CPU는 숨은 상태나 미래 RNG를 읽지 않는다.
- P0/P1이 모두 완료되기 전에 아트 완성·온라인 이전·콘텐츠 양산을 하지 않는다.
- 실패 장면의 원인 행위자와 인과가 5초 안에 읽히지 않으면 기능이 돌아가도 불합격이다.

## 폴더

```text
docs/                       게임 하나의 전체 명세
checklists/                  P0/P1 핵심 구현 게이트
project/                     바로 열 수 있는 Godot 프로젝트
project/data/design/         최종 구현용 룰·맵·수치 JSON
tools/                       설정·체크리스트·소스 구조 검증
FULL_SPEC.md                 이 게임 문서만 합친 단일 파일
SOURCES.md                   원본 확인 범위와 기술 기준
```

## 헤드리스 검증

```bash
godot --headless --path project --script res://tests/smoke_test.gd
python tools/validate_package.py
```

`SMOKE_OK` JSON이 출력되고 종료 코드가 0이어야 한다.
