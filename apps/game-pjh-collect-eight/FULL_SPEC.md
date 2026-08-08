

---

<!-- 00_READ_FIRST.md -->

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


---

<!-- 01_GAMEPLAY_SPEC.md -->

# 8원 모으기 — 게임플레이·수치 명세

> 기준 엔진은 Godot 4.7.1이지만, 이 문서의 구조체·알고리즘 블록은 언어 독립적 의사코드다. 실제 GDScript 파일·함수·씬 계약은 `03_CODE_BLUEPRINT.md`를 따른다.

## 3.1 재미 계약

규칙은 한 문장이다. **광물을 한 번 캐서 자기 은행까지 가져오면 승리한다.** 그러나 광물을 든 순간 모두의 목표가 운반자 하나로 모인다. 운반자는 도망치고, 나머지는 잠시 협력하며, 광물이 떨어지는 순간 동맹이 해체된다.

반드시 나와야 하는 장면:

1. 모두가 광산으로 달리다가 서로 밀쳐 첫 채취를 방해한다.
2. 운반자가 중앙 최단로를 택했다가 앞뒤로 포위된다.
3. 거의 은행에 도착한 운반자가 마지막 밀치기에 광물을 놓친다.
4. 추격하던 CPU 둘이 광물을 누가 주울지 싸우다 원 운반자가 되찾는다.
5. 잘하는 운반자가 경로·대시·문 타이밍으로 여러 명을 따돌려 관전자 장면을 만든다.

핵심은 공격으로 사람을 오래 죽이는 것이 아니라 **운반권을 빼앗고 목표가 즉시 바뀌는 것**이다. 사망 시간, 공격 경직, 맵 크기 때문에 추격에 재합류하지 못하면 실패다.

## 3.2 원본 확인과 고정 규칙

### [원본 확인]

- 일꾼이 광물을 한 번 채취하면 승리 조건인 8 미네랄을 운반한다.
- 광물과 귀환 지점 사이가 길고 좁다.
- 운반자가 되면 다른 플레이어가 집중 추격한다.
- 일꾼 컨트롤이 좋은 플레이어가 여러 명을 따돌리는 장면이 핵심 볼거리다.

### [프로토타입 고정]

- 기본 인간 1 + CPU 5, 최대 8명.
- 월드 4096×1536, 횡스크롤 추적 카메라.
- 활성 광물은 한 번에 1개다. 광산에서 먼저 채취한 사람만 운반한다.
- 운반자가 죽으면 광물이 현장에 떨어진다. 누구나 주울 수 있다.
- 광물을 자기 은행에서 0.8초 예치하면 즉시 승리.
- 평균 라운드 2.5~5.5분, 최대 8분. 8분에는 은행 예치 시간이 0.4초로 줄고 문이 모두 열린다.

단일 활성 광물은 원본의 여러 버전 중 확인되지 않은 세부를 재미 검증에 맞춰 고정한 규칙이다. 여러 명이 동시에 광물을 들면 `1명 대 나머지`가 약해지기 때문에 첫 프로토타입에서는 사용하지 않는다.

## 3.3 맵 구조

| 경로 | 주요 좌표 | 거리 성격 | 리스크 |
| --- | --- | --- | --- |
| north | (480,350) → (1420,300) → (2320,430) → (3240,350) → (3660,620) | 넓지만 길다 | 북/남은 우회와 엄폐, 중앙은 추격 집중 |
| center | (480,768) → (1250,768) → (2050,768) → (2850,768) → (3660,768) | 가장 짧고 가장 노출 | 북/남은 우회와 엄폐, 중앙은 추격 집중 |
| south | (480,1180) → (1420,1230) → (2320,1100) → (3240,1180) → (3660,920) | 문과 엄폐물이 많다 | 북/남은 우회와 엄폐, 중앙은 추격 집중 |


### 시작 지점과 은행

- 6인 기준 은행은 X=320, Y=280/472/664/856/1048/1240.
- 모든 시작점은 광산까지 최단거리 차이가 ±1.5% 이내.
- 자기 은행만 예치 가능. 다른 은행은 80유닛 반경의 단단한 장애물로 작동한다.
- 시작 후 2초 동안 플레이어끼리 밀치기와 공격이 비활성이다. 출발 즉시 한 명이 갇히는 것을 막는다.

### 세 경로

- **중앙**: 가장 짧고 시야가 트여 있다. 두 개의 좁은 문을 통과한다.
- **북쪽**: 12% 길지만 넓은 공간과 두 개의 점프 패드가 있다.
- **남쪽**: 9% 길고 엄폐물이 많으며, 한 방향 회전문이 있다.
- 세 경로는 X=1,150, 2,450, 3,180 부근에서 교차한다. 완전히 분리하면 추격자와 운반자가 만나지 않는다.

### 문

- 문 A: 5초 주기, 3.2초 열림.
- 문 B: 6.5초 주기, 4초 열림.
- 닫히기 0.65초 전 바닥 줄무늬와 경고음.
- 문에 끼인 캐릭터는 가장 가까운 열린 쪽으로 42유닛 밀려나며 피해 없음.
- 광물은 문에 끼여 소실되지 않는다.

### 카메라

- 인간을 X축 42% 지점에 두는 횡추적.
- 운반자가 화면 밖이면 가장자리 왕관 화살표와 은행까지 남은 거리 표시.
- 인간이 죽으면 0.8초 사망 지점을 보여준 뒤 광물 운반자를 따라간다. 부활 0.6초 전에 자기 시작점으로 돌아온다.

## 3.4 플레이어 엔티티

### 기본 수치

- 반지름 20.
- 최대 체력 100.
- 이동속도 292유닛/초.
- 가속 2,700, 감속 3,300유닛/초².
- 광물 운반 중 속도 276유닛/초. 약 5.5% 감소만 적용한다.
- 사망 후 2.8초 부활. 부활 후 0.7초 공격·밀치기 면역, 광물 줍기는 0.35초 후 가능.

### 조작

| 입력 | 기능 | 세부 |
|---|---|---|
| WASD | 이동 | 8방향, 카메라와 무관한 월드 방향 |
| 좌클릭 | 전방 밀치기 | 0.22초 준비, 반경 42·전방 110도 |
| Space | 대시 | 125유닛, 기본 4.2초 쿨다운, 운반 중 6초 |
| E | 광물 채취/줍기/예치 | 가까운 유효 상호작용 자동 선택 |
| Q | 급정지 | 1.5초 쿨다운, 속도를 즉시 0으로 만들어 페인트 가능 |
| R | 즉시 재시작 요청 | 결과 화면에서만 |

밀치기는 공격 버튼을 난사하는 게임이 되지 않게 0.72초 쿨다운을 둔다.

### 밀치기 판정

- 피해 34.
- 기본 밀림 84유닛, 운반자는 96유닛.
- 같은 공격자에게 0.6초 내 재적중 불가.
- 벽에 밀려 충돌해도 추가 피해 없음.
- 체력 0 이하가 되면 사망. 광물은 사망 확정 틱에 떨어진다.
- 공격 중 방향은 시전 시작 시 고정하지 않고 70% 시점까지 조준을 따라간다. 조작이 둔하게 느껴지는 것을 막는다.

### 대시

- 0.16초 동안 이동.
- 완전 무적 없음. 밀치기 힘 65% 감소.
- 문·벽을 통과하지 않는다.
- 광물 줍기·예치 채널을 취소한다.
- 대시 종료 후 0.10초 제어 지연을 두지 않는다.

## 3.5 광물 상태 머신

```text
type CrystalState =
  | { kind: 'at_mine' }
  | { kind: 'mining'; playerId: EntityId; progressTicks: number }
  | { kind: 'carried'; playerId: EntityId }
  | { kind: 'dropped'; pos: Vec2Fx; returnTicks: number }
  | { kind: 'banking'; playerId: EntityId; progressTicks: number }
  | { kind: 'delivered'; winnerId: EntityId };
```

### 채취

- 광산 반경 92 안에서 E를 누르고 1.05초 유지.
- 이동·밀치기 피격·대시·공격 사용 시 취소.
- 여러 명이 채취하면 먼저 시작한 사람에게 소유 예약을 주지 않는다. 모두 진행되며 같은 틱 완료 시 광산 중심과 거리, 그다음 엔티티 ID로 결정한다.
- 진행 60% 이상인 플레이어는 머리 위에 곡괭이 아이콘을 크게 표시해 다른 사람이 방해할 수 있게 한다.

### 운반

- 운반자에게 전역 왕관·미니맵 표식.
- 운반자는 광물 때문에 공격을 못 하는 것이 아니다. 밀치기와 대시는 모두 사용 가능.
- 운반자가 시야 밖이어도 공개 위치는 0.25초 지연된 위치로 표시한다. 완전 실시간 GPS는 포위가 너무 쉬워진다.
- 0.25초 위치 지연은 인간과 CPU 모두 동일하게 사용한다.

### 떨어뜨리기

- 사망 위치에 드롭.
- 0.22초 동안 원래 운반자 재획득 불가, 다른 사람은 0.10초 후 가능. 추격자가 보상받을 시간을 준다.
- 드롭 광물은 충돌하지 않는다.
- 7초 동안 아무도 줍지 않으면 0.6초 예고 후 광산으로 귀환.
- 월드 밖·문 내부·장애물 내부에 떨어지면 가장 가까운 네비게이션 셀로 투영한다.

### 줍기

- 36유닛 안에서 E 또는 0.18초 자동 줍기.
- 공격 준비 중에는 자동 줍기하지 않는다. 원치 않는 소유 전환 방지.
- 같은 틱 여러 명이면 거리 → 최근 광물 미보유 시간 → 엔티티 ID 순서.

### 예치

- 자기 은행 반경 72 안에서 0.8초.
- 이동 가능 속도는 최대 35유닛/초로 제한되어 조금씩 위치 조정 가능.
- 피해나 밀치기 적중 시 진행 100% 초기화.
- 다른 플레이어의 몸 충돌만으로는 취소하지 않는다.
- 진행 50%부터 전체 화면 상단에 카운트와 은행 위치 강조.

## 3.6 CPU 역할 전환

CPU는 고정 팀이 없다. 4Hz마다 현재 상황에 따라 다음 역할을 선택한다.

```text
RACE_MINE       광물이 광산에 있을 때 채취 경쟁
INTERRUPT_MINE  다른 플레이어 채취 50% 이상일 때 방해
CARRY_ESCAPE    자신이 운반자
INTERCEPT       운반자의 예상 경로 앞을 막음
CHASE           뒤에서 직접 추격
AMBUSH_BANK     운반자의 은행 근처 매복
THIRD_PARTY     드롭 직전 다른 추격자를 밀쳐 광물 선점
RECOVER         체력 낮을 때 짧게 회피
```

### 운반자 경로 선택

세 주 경로와 교차 지점 변형을 포함해 9개 후보를 만든다.

```text
routeScore =
  0.36 × timeToOwnBank
+ 0.22 × enemyDensityNext2s
+ 0.15 × chokeTimingRisk
+ 0.12 × lineOfSightExposure
+ 0.09 × dashOpportunity
+ 0.06 × personalityRisk
```

점수는 낮을수록 좋다. CPU는 최저 경로를 항상 고르지 않고 `softmax temperature 0.14`로 선택한다. 추격자가 길을 읽을 수 있게 1.1초 이상 같은 경로 의도를 유지하되, 교차점에서 큰 위험이 생기면 전환한다.

### 가로막기

CPU는 운반자의 현재 위치가 아니라 0.25초 공개 위치와 관측 속도로 0.8초 후 지점을 예측한다. 다음 조건을 모두 만족할 때만 선회한다.

- 자신이 예측 지점에 운반자보다 0.3초 이상 먼저 도착.
- 다른 추격자와 목표점 간격 70유닛 이상.
- 자기 체력 35 이상.

모든 CPU가 같은 점에 겹치는 것을 막기 위해 `interceptSlot`을 좌/중/우로 예약한다. 예약은 공개 핑처럼 150ms 지연 후 공유된다.

### 광물 앞 배신

드롭 광물이 생기면 기존 추격 동맹은 즉시 해체된다. CPU는 다음 우선순위를 쓴다.

1. 자신이 0.45초 내 주울 수 있으면 줍기.
2. 다른 사람이 더 가깝고 자신이 밀치기로 끊을 수 있으면 공격.
3. 둘 다 아니면 다음 예상 운반자를 추격.

이 전환이 220ms보다 빠르면 치팅처럼 보인다. 반응 지연 큐를 반드시 거친다.

## 3.7 CPU 실력과 오류

- 대시 회피 반응 평균 230ms.
- 문 주기는 관측 후 기억할 수 있지만 다음 문 상태를 프레임 단위로 알지 않는다. 2회 관측 후 ±0.25초 오차로 예측.
- 운반 중 고압 상황에서 8% 확률로 두 번째 경로 선택.
- 체력 34 이하에서도 `greed > 0.75`면 광물 채취를 15% 더 고집한다.
- 같은 CPU가 광물을 든 뒤 2초 안에 매번 즉사하면 다음 라운드에 0.10만큼 위험 회피가 올라간다. 매치 내 적응은 최대 0.2.
- 인간 입력을 읽어 대시 직후를 완벽히 공격하는 행동 금지. CPU는 대시 시작 시각을 본 뒤 반응한다.

## 3.8 추격 가독성

- 운반자 왕관은 화면 크기 34px 고정. 캐릭터와 겹쳐도 가려지지 않는다.
- 은행까지 남은 거리를 운반자 머리 위에 `82%`처럼 표시하지 않고 바닥 경로의 짧은 진행 띠로 보여준다. 정확한 숫자는 HUD.
- 화면 밖 추격자는 가장자리 화살표. 공격 가능한 1.2초 거리 안이면 화살표가 굵어진다.
- 밀치기 예고는 전방 부채꼴 0.22초. 실제 판정은 예고보다 4유닛 작다.
- 문 닫힘, 대시, 광물 드롭은 서로 다른 모양·음색을 쓴다.

## 3.9 오디오

- 채취 60%: 다른 사람도 들을 수 있는 곡괭이 상승음.
- 광물 획득: 전체 공용 짧은 신호.
- 운반자 교체: 새 운반자 슬롯 음색 + 화면 표식.
- 은행 50%: 3박 카운트 시작.
- 마지막 15% 거리: 운반자와 가장 가까운 추격자에게만 긴장 레이어.
- 밀치기 적중은 피해량보다 위치 변화가 중요하므로 저음 충격과 짧은 방향성 스와이프를 결합한다.

## 3.10 정체 방지와 재진입

- 부활 2.8초. 부활 지점은 자기 은행 앞이지만, 광물이 X<1000이면 중앙 체크포인트 X=900에서 부활해 재합류 시간을 줄인다.
- 같은 플레이어가 20초 안에 3회 죽으면 다음 부활 1.5초 보호막 40을 받는다. 공격은 가능하고 보호막은 밀치기 힘을 줄이지 않는다.
- 광물이 45초 동안 X축으로 300유닛 이상 이동하지 않으면 중앙 문을 10초간 열고 드롭 복귀 시간을 4초로 줄인다.
- 8분부터 모든 문 개방, 예치 0.4초, 운반 속도 페널티 제거.

## 3.11 재미 게이트

| 지표 | 합격 범위 |
|---|---:|
| 평균 라운드 | 2.5~5.5분 |
| 운반자 교체 | 라운드당 3~9회 |
| 은행 거리 20% 이내 차단 | 라운드의 35~65% |
| 광물 드롭 후 2초 내 새 소유자 | 55~85% |
| 한 운반자가 무접촉 완주 | 10~30% |
| 사망 후 추격 재합류 | 평균 5.5초 이하 |
| CPU 단독 승률 분산 | 슬롯별 ±6% 이내 |
| 초행 인간이 3판 내 1회 이상 광물 운반 | 80% 이상 |
| 패배했지만 웃긴 장면이 있었다 응답 | 5점 중앙값 4 이상 |

운반자 교체가 10회를 지속적으로 넘으면 공격·사망이 너무 강하다. 2회 미만이면 추격자가 운반자를 잡을 수 없거나 맵이 분리된 것이다.

## 3.12 Godot 구현

### 렌더 레이어

1. 정적 맵 RenderTexture.
2. 문·점프 패드·광산·은행.
3. 광물 경로 강조와 공격 예고.
4. 플레이어·광물.
5. 세계 UI 왕관·체력·채널.
6. HUD 미니 진행도와 슬롯 상태.

월드가 4096×1536이므로 화면 밖 엔티티는 렌더링하지 않되 시뮬레이션은 계속한다. 플레이어가 최대 8명이라 복잡한 타일 컬링은 필요 없지만, 정적 배경은 한 번 합성한다.

### 이동

- 32유닛 네비게이션 그리드.
- 직접 이동은 A*를 쓰지 않고 연속 충돌.
- CPU 장거리 경로에만 A*.
- 문 상태가 바뀔 때 해당 셀 비용만 갱신.
- 밀치기는 경로와 무관한 강제 속도이며, 정적 충돌 후 접선으로 미끄러진다.

### 이벤트

필수 로그:

```text
mining_started / mining_interrupted / crystal_acquired
carrier_route_committed / carrier_route_changed
shove_hit / dash_used / crystal_dropped / crystal_picked
banking_started / banking_interrupted / delivered
```

결과 화면은 마지막 20초의 소유권 타임라인과 은행까지 최저 잔여 거리를 보여준다.

## 3.13 구현 순서

### 8W-M0 — 왕복

- 인간 한 명, 광산 채취, 은행 예치, 카메라.
- 공격 없음. 이동과 채널 조작감만 통과.

### 8W-M1 — 경쟁

- CPU 5명, 단일 광물 경쟁, 소유권.
- 공격 없이도 광산 경합이 자연스러운지 확인.

### 8W-M2 — 밀치기·사망·드롭

- 밀치기, 체력, 부활, 광물 드롭과 줍기.
- 마지막 20% 차단 사건이 생기도록 수치 튜닝.

### 8W-M3 — 세 경로·문·CPU 가로막기

- 맵 교차 지점, 문, 경로 선택, 매복.
- CPU가 완벽 포위를 하지 않도록 반응 지연 검증.

### 8W-M4 — 피드백·정체 방지

- 왕관, 오프스크린 화살표, 소유권 타임라인, 8분 규칙.

## 3.14 출시 금지 조건

- 광물을 든 순간 1.5초 안에 평균 사망한다.
- 운반자가 공격·대시를 못 해 수동적인 도망만 한다.
- 모든 CPU가 같은 가로막기 점에 겹친다.
- 광물 드롭이 장애물 안·화면 밖에 남는다.
- 부활 후 광물 전선에 복귀하는 데 8초 이상 걸린다.
- 중앙 경로만 통계적으로 65% 이상 선택된다.
- 문 닫힘이 예고와 1틱 이상 어긋난다.
- 은행 예치가 몸 충돌만으로 무한 취소된다.
- 가장 잘하는 CPU가 30% 이상 승리한다(6인 기준).
- 광물 소유권이 바뀌었는데 화면·소리로 250ms 안에 알 수 없다.

# Godot 적용 부록

## Node를 판정 단위로 쓰지 않는다

이 게임의 엔티티는 `GameWorld` 내부 Dictionary/typed data 배열이 정답이다. 회색상자 렌더는 한두 개의 `Node2D`가 일괄 그린다. 아트 단계에서 Sprite2D 풀을 붙여도 판정 상태는 유지한다.

## 스타터와 최종 구현의 차이

- 스타터: 핵심 루프·조작·CPU 상황 발생 여부를 빠르게 느끼기 위한 단일 장면.
- M1 이후: `SimulationHost`, 시스템별 스크립트, 데이터 JSON, 렌더 브리지로 분리.
- 출시 전: 독자 아트·사운드·명칭·튜토리얼·접근성·저장·플랫폼 입력 추가.
- 온라인 이전: 정답 상태를 고정소수점과 명령 리플레이로 검증한 뒤 권한 모델을 선택.

## 절대 제거하면 안 되는 재미 축

- 7원을 가진 선두가 마지막 광물을 들고 은행 앞에서 넘어뜨려진다.
- 모두가 운반자를 쫓는 동안 다른 플레이어가 떨어진 광물을 낚아챈다.
- 추격자끼리 충돌해 오히려 운반자의 탈출로를 열어준다.
- CPU가 최단경로가 아니라 예상 귀환로를 막아 인간을 놀라게 한다.


---

<!-- 02_GODOT_ARCHITECTURE.md -->

# Godot 4.7.1 독립 프로젝트 아키텍처

> 이 문서는 이 ZIP 내부의 게임 하나만으로 개발을 시작할 수 있도록 공통 엔진 규칙까지 모두 포함한다. 다른 게임 ZIP이나 별도 공통 저장소를 참조하지 않는다.

## 1. 기술 기준

- 엔진: **Godot 4.7.1 stable**
- 언어: **GDScript**
- 렌더링: 2D, 기본 `gl_compatibility`. 회색상자 단계에서는 `Node2D._draw()`와 최소한의 `Control`만 사용한다.
- 논리 해상도: 1600×900, 16:9.
- 시뮬레이션: 60Hz.
- 첫 목표 플랫폼: Windows 데스크톱. 조작 검증 후 Android·Web 입력 계층을 추가한다.
- 첫 목표 구성: 인간 1명 + CPU. 온라인, 계정, 매칭, 상점, 라이브옵스는 제외한다.
- 데이터: 밸런스 원본은 `res://data/*.json`, 에디터 친화 자산은 필요할 때 `.tres`로 변환한다.
- 버전 관리: 텍스트 기반 `.tscn`, `.tres`, `.gd`, `.json`만 커밋한다. `.godot/`과 import 캐시는 커밋하지 않는다.

Godot 자체 물리 결과는 완전 결정적이지 않다. 따라서 승패·피해·밀치기·소유권·CPU 판단처럼 재현이 필요한 판정은 `CharacterBody2D`, `RigidBody2D`, `NavigationAgent2D`의 결과를 정답 상태로 삼지 않는다. 이 프로젝트의 `GameWorld`가 직접 계산한 상태가 유일한 정답이며, Godot 노드는 입력·표현·오디오를 담당한다.

## 2. 프로젝트가 지켜야 할 경계

```text
Input
  └─ PlayerCommand 생성
       └─ SimulationHost가 tick 번호를 붙여 CommandQueue에 적재
            └─ GameWorld.step_tick()
                 ├─ CPU Observation 생성
                 ├─ CPU 의사결정
                 ├─ 이동/충돌/전투/목표 판정
                 ├─ EventLog 기록
                 └─ RenderSnapshot 생성
                      ├─ WorldView
                      ├─ WorldUi
                      ├─ Hud
                      └─ AudioCueRouter
```

다음 행위는 금지한다.

- 렌더 노드의 현재 위치를 읽어 공격 판정에 사용.
- 애니메이션 종료 시그널을 기다렸다가 피해 적용.
- `randf()`, `randi()`, `Time.get_ticks_msec()`를 시뮬레이션 결과에 사용.
- CPU가 SceneTree에서 숨은 적 노드를 검색.
- `Area2D.body_entered` 순서에 따라 소유권이나 킬을 결정.
- 프레임 델타로 피해량·쿨다운·스폰량을 누적.
- 장면 노드 하나가 UI, 판정, 저장, CPU를 모두 소유.

## 3. 폴더 계약

```text
project.godot
scenes/
  main.tscn
  game/
    game_view.tscn              # 아트가 들어간 뒤 사용
scripts/
  game_root.gd                  # 부팅·재시작·입력 연결
  simulation_host.gd            # 고정 틱과 명령 큐
  sim/
    game_world.gd               # 유일한 정답 상태
    seeded_rng.gd
    command_queue.gd
    event_log.gd
    state_hasher.gd
    spatial_hash_2d.gd
    geometry_2d_fixed.gd
  ai/
    observation.gd
    memory.gd
    utility_brain.gd
    cpu_profile.gd
  render/
    debug_renderer.gd
    render_bridge.gd
    cue_router.gd
  ui/
    hud.gd
  tests/
    smoke_test.gd
    deterministic_replay_test.gd
    invariants_test.gd
data/
  game_config.json
  cpu_profiles.json
  levels/
  regression_seeds.json
docs/
checklists/
```

스타터 프로젝트는 파일 수를 줄이기 위해 일부 역할이 합쳐져 있다. M1에 들어가면 위 구조로 분리한다. 중요한 것은 파일 수가 아니라 **상태 소유권**이다.

## 4. 씬 트리 계약

| 노드 | 타입 | 책임 |
|---|---|---|
| Main | Node | 즉시 매치·시드·재시작 |
| SimulationHost | Node | 이동·밀치기·광물 소유권 처리 |
| MapView | Node2D | 광산·세 경로·문·은행·점프패드 렌더 |
| Camera2D | Camera2D | 인간과 광물 사이 동적 프레이밍 |
| CarrierView | Node2D | 운반자 왕관·추격선·드롭 예고 |
| Hud | CanvasLayer | 플레이어별 보유 원·대시·광물 상태 |
| RoundDirector | Node | 광물 재생성·정체 방지·승리 |
| Telemetry | Node | 소유권 이전·가로막기·7원 실패 사건 |

노드는 정답 데이터를 소유하지 않는다. `WorldView`는 `GameWorld`가 넘긴 스냅샷만 그린다. 노드가 해제되어도 매치 상태가 보존되도록 시뮬레이션은 `RefCounted` 객체로 둔다.

## 5. 60Hz 시뮬레이션

### 5.1 기본 실행

`_physics_process(delta)`는 호출 시점만 제공한다. 실제 판정 함수에는 항상 상수 `1.0 / 60.0`을 넘긴다.

```gdscript
const TICK_RATE := 60
const FIXED_DT := 1.0 / float(TICK_RATE)

func _physics_process(_delta: float) -> void:
    var commands := input_router.flush_for_tick(world.tick)
    world.step_tick(commands, FIXED_DT)
    render_bridge.present(world.make_snapshot())
```

프레임 정지가 발생해도 한 프레임에 임의로 여러 틱을 실행하는 별도 accumulator를 `_physics_process` 위에 다시 만들지 않는다. 헤드리스·리플레이는 직접 `step_tick()`을 반복한다.

### 5.2 정답 상태

정답 상태에 포함:

- 엔티티 ID, 슬롯, 팀, 생존 상태.
- 위치·속도·체력·자원.
- 목표, 페이즈, 쿨다운, 채널링.
- RNG 스트림 상태.
- CPU의 고수준 행동과 반응 큐.
- 소유권·킬·점수·승패.
- 아직 처리되지 않은 명령.

정답 상태에서 제외:

- Sprite2D 프레임.
- 카메라 위치와 흔들림.
- 파티클 수명.
- 재생 중인 오디오.
- 마우스 호버 색.
- 보간된 렌더 좌표.

### 5.3 숫자 규칙

첫 회색상자는 `Vector2`와 `float`로 빠르게 검증해도 된다. 다음 중 하나가 필요해지는 순간 고정소수점으로 교체한다.

1. 입력 리플레이가 다른 PC에서 갈라짐.
2. 온라인 lockstep 또는 rollback 도입.
3. 충돌 순서가 승패를 자주 바꿈.
4. 장시간 시뮬레이션에서 위치 오차가 누적됨.

고정소수점 권장 단위:

```text
POSITION_SCALE = 100          # 1 월드 유닛 = 100 정수
TIME_SCALE = 60               # 시간은 tick 정수
ANGLE_SCALE = 4096            # 한 바퀴
HEALTH_SCALE = 100
```

## 6. RNG 계약

모든 난수는 `SeededRng` 인스턴스에서 나온다. 스트림을 분리한다.

```text
match
spawn
loot
map
cpu:0
cpu:1
...
cosmetic                 # 재현에 필요 없으면 정답 해시에서 제외
```

같은 스트림을 여러 시스템이 공유하면 기능 하나를 추가하는 것만으로 이후 난수열이 전부 바뀐다. `spawn` 난수를 CPU 실수 생성에 사용하지 않는다.

## 7. 명령 계약

```gdscript
{
  "tick": 1204,
  "slot": 0,
  "seq": 89,
  "type": "move",
  "move": Vector2(0.7, -0.7),
  "aim": Vector2(1210, 420),
  "pressed": true,
  "target_id": -1
}
```

정렬 순서:

1. tick 오름차순.
2. slot 오름차순.
3. seq 오름차순.
4. 동일 명령이 중복되면 최초 한 개만 처리.

명령이 들어온 즉시 효과를 내지 않는다. 반드시 다음 `step_tick()`의 명령 단계에서 처리한다.

입력 버퍼:

- 쿨다운 종료 9틱 전부터 능력 입력 수락.
- 새 이동 명령은 이전 클릭 이동을 같은 틱에 취소.
- 죽음·기절 중 이동은 마지막 하나만 보관.
- 포커스 상실 시 모든 눌린 입력을 해제.
- 재시작은 결과 화면뿐 아니라 개발 빌드에서 언제든 `R`로 가능.
- 마우스 월드 좌표는 `Viewport.get_canvas_transform().affine_inverse()`를 거쳐 변환.

## 8. 조작감 기준

| 항목 | 목표 | 실패 |
|---|---:|---:|
| 키 입력→속도 변화 | 다음 physics tick | 2틱 이상 |
| 클릭→표시 마커 | 같은 렌더 프레임 | 2프레임 이상 |
| 능력 선입력 | 준비 150ms 전부터 | 준비 직전 입력 유실 |
| 대시·강제이동 | 입력 방향과 10° 이내 | 보이지 않는 자동 보정 |
| 충돌 후 제어 회복 | 120ms 이내 | 250ms 이상 미끄러짐 |
| 패배→재조작 | 2.5초 이내 | 메뉴를 여러 번 거침 |

조작감을 아트로 가리지 않는다. 회색상자에서 다음을 먼저 맞춘다.

- 가속·감속.
- 회전과 조준 분리 여부.
- 입력 버퍼.
- 충돌 반경.
- 카메라 반감기.
- 위험 예고 시간.
- 피격 정지 시간.
- 사망 후 관전 전환.

## 9. 이동·충돌

### 9.1 권장 방식

- 원형 동적 엔티티.
- 축 정렬 사각형 또는 선분 정적 지형.
- 공간 해시 셀 128.
- 이동 거리가 반지름의 0.75배를 넘으면 스윕 검사.
- 동적 충돌은 ID 오름차순으로 2회 투영.
- 겹침 보정은 틱당 최대 6유닛.
- 판정 반경과 보이는 도형이 다르면 보이는 도형을 4~8유닛 크게 그린다.

### 9.2 한 틱 순서

```text
01 명령 적용
02 CPU Observation 갱신
03 CPU 고수준 행동 선택
04 의도 속도 계산
05 정적 지형 스윕
06 강제 이동
07 동적 충돌 2회
08 공격/스킬 판정
09 목표·소유권·채널 판정
10 사망·부활·탈락
11 페이즈·승패
12 인과 이벤트
13 삭제 큐
14 불변식 검사
15 스냅샷
```

이 순서는 중간에 임의로 바꾸지 않는다. 변경 시 모든 회귀 시드를 다시 실행한다.

## 10. CPU 설계

CPU 목표는 완벽함이 아니라 **초행 인간보다 약간 잘하지만 인간처럼 망설이고 가끔 틀리는 동료/상대**다.

### 10.1 정보 제한

CPU가 알 수 있음:

- 자신의 시야와 공개 UI.
- 직접 본 사건의 기억.
- 공개 핑과 공개 점수.
- 자신에게 맞은 공격의 발신자.
- 맵의 정적 구조.

CPU가 알 수 없음:

- 시야 밖 정확한 위치.
- 다음 난수.
- 플레이어의 입력 큐.
- 가려진 쿨다운의 정확한 잔여 틱.
- 다른 CPU가 아직 실행하지 않은 계획.
- 오브젝트 내부 private 변수.

### 10.2 파이프라인

```text
Perception 10Hz
  → Memory decay
  → Candidate action 생성
  → Utility 평가
  → 현재 행동 1.10~1.18 관성
  → 160~280ms 반응 큐
  → 60Hz ActionRunner
  → 실패 이유 기록
```

기본 점수:

```text
score =
  base
  × urgency
  × feasibility
  × safety
  × role_fit
  × personality_bias
  + bounded_noise
```

### 10.3 인간보다 약간 잘하는 수준

- 위험 예측: 인간 초행 평균보다 10~20% 멀리 본다.
- 조준 오차: 평균 4~9°, 이동 중 2~4° 추가.
- 반응: 평균 210ms, 최저 150ms. 130ms 미만 금지.
- 계획 유지: 최소 0.35초, 치명적 위험이면 즉시 취소.
- 실수: 단순 난수 자살이 아니라 정보 지연·우선순위 충돌·과신에서 발생.
- 인간 집중 방지: 경쟁 게임은 인간이라는 이유로 보너스를 주지 않는다.
- 도움 편향: 협동 게임은 인간이 첫 60초에 규칙을 볼 수 있도록 CPU 한 명이 시범 행동을 한다.
- 치팅 감사: 행동마다 사용한 Observation 필드 목록을 로그에 남긴다.

| 상태 | 구현 계약 |
|---|---|
| RACE_MINE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| MINE_CHANNEL | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| CARRY_HOME | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| CHASE_CARRIER | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| INTERCEPT_ROUTE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| GUARD_BANK | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| STEAL_DROP | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| RECOVER | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| CELEBRATE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |

## 11. 회색상자 렌더 규칙

아트는 더미여도 되지만 정보는 더미여서는 안 된다.

- 인간: 흰 외곽선 3px.
- CPU: 슬롯별 색 + 숫자.
- 목표: 형태가 다른 아이콘. 색만으로 구분 금지.
- 피해 가능 범위: 실제 판정보다 4px 작게 표시.
- 위험 예고: 최소 0.45초. 즉사 위험은 최소 0.65초.
- 소유권: 본체 위 링과 HUD 둘 다 표시.
- 채널링: 월드 게이지와 HUD 문구 둘 다 표시.
- 카메라 흔들림: 최대 5px, 90ms. HUD는 흔들지 않는다.
- 동일 이펙트 20개 이상은 합성하거나 수를 줄인다.
- `Node2D`를 탄환·적마다 생성하는 구조는 대량 게임에서 사용하지 않는다. 배열 상태를 한 렌더 노드가 일괄 그린다.

## 12. UI

HUD는 규칙을 설명하지 않고 **지금 무엇이 중요한지** 보여준다.

필수:

- 현재 목표 한 문장.
- 내 생존·자원·쿨다운.
- 다른 슬롯의 핵심 공개 상태.
- 승리에 가까운 대상.
- 위험의 방향.
- 상호작용 가능 상태.
- 실패 원인 한 문장.
- 즉시 재시작.

튜토리얼은 3단계 이하:

1. 이동.
2. 핵심 상호작용.
3. 다른 플레이어 때문에 생기는 변화.

모달 팝업으로 전투를 멈추지 않는다. 첫 판에는 화면 가장자리 카드로 4초 이내 보여준다.

## 13. 오디오

오디오 큐는 판정 이벤트에서만 발생한다.

```text
EventLog event
  → CueRouter dedupe
  → AudioStreamPlayer/AudioStreamPlayer2D
```

- 같은 큐는 80ms 창에서 최대 한 번.
- 인간이 직접 만든 사건은 +2dB 이내로 강조.
- 즉사 경고, 소유권 획득, 목표 임박, 패배 원인은 서로 다른 음색.
- CPU 5명이 동시에 같은 요청 음성을 반복하지 않는다.
- 회색상자는 저작권 없는 클릭·노이즈·톤으로 충분하다.

## 14. 이벤트·인과 로그

모든 중요한 사건은 다음 형식을 사용한다.

```gdscript
{
  "event_id": 812,
  "tick": 3920,
  "type": "player_downed",
  "actor_id": 4,
  "target_id": 0,
  "position": Vector2(920, 410),
  "cause_event_ids": [806, 809],
  "value": 1.0,
  "tags": ["chain_failure", "visible"]
}
```

최대 6단계 원인 추적. 결과 화면에는 가장 큰 원인 3개만 보여준다.

나쁜 결과 문구:

> 패배했습니다.

좋은 결과 문구:

> 3번 라인의 탄약 배송이 11초 늦어졌고, 지원 이동으로 2번 라인까지 비었습니다.

게임별 문구는 별도 명세를 따른다.

## 15. 헤드리스 실행

프로젝트는 렌더 없이 `GameWorld`만 돌릴 수 있어야 한다.

```bash
godot --headless --path project \
  --script res://scripts/tests/smoke_test.gd
```

배치 테스트 입력:

```text
--seed=123
--ticks=36000
--human_policy=cpu_veteran
--cpu_profile=veteran_default
--report=user://report.json
```

필수 자동 검사:

- NaN/Infinity 없음.
- 엔티티 ID 중복 없음.
- 소유권 불변식.
- 죽은 엔티티가 명령 실행하지 않음.
- 쿨다운 음수 없음.
- 승패가 동시에 두 번 확정되지 않음.
- 30분 실행 뒤 배열 크기 누수 없음.
- 같은 시드·명령에서 상태 요약 동일.
- CPU가 비가시 엔티티를 직접 표적으로 삼지 않음.

## 16. 성능 예산

| 항목 | 회색상자 목표 |
|---|---:|
| physics tick 평균 | 5ms 이하 |
| physics tick p99 | 12ms 이하 |
| 렌더 평균 | 10ms 이하 |
| 매치 중 메모리 증가 | 안정화 후 10% 이하 |
| 런타임 Node 수 | 소규모 250 이하, 대량전 120 이하 |
| 한 틱 할당 | 대표 구간 평균 50KB 이하 |
| CPU 의사결정 | 10Hz, 슬롯당 0.25ms 이하 |
| 이벤트 보관 | 최근 10,000개 + 요약 |

Profiler에서 노드 수·스크립트 시간·draw call을 매 마일스톤 기록한다.

## 17. 개발 디버그 기능

개발 빌드 키:

- `F1`: 충돌 도형.
- `F2`: CPU 행동·Utility.
- `F3`: 경로·흐름장.
- `F4`: 이벤트 인과선.
- `F5`: 0.5×/1×/2× 시뮬레이션.
- `F6`: 다음 회귀 시드.
- `F7`: 인간을 CPU 정책으로 교체.
- `F8`: 현재 상태 JSON 덤프.
- `F9`: 10초 전 입력 리플레이.
- `R`: 즉시 재시작.

디버그 표시가 시뮬레이션 상태를 변경하면 안 된다.

## 18. Git 작업 규칙

- 씬 파일은 담당자 한 명이 소유하거나 작은 하위 씬으로 나눈다.
- 밸런스 값은 코드에 중복 기입하지 않는다.
- 엔티티 이름 대신 안정 ID를 저장한다.
- signal은 UI·표현 통지에 사용하고 판정 순서에는 사용하지 않는다.
- `_process`에서 게임 판정 금지.
- `await` 뒤에 매치 상태가 유효한지 반드시 재검사.
- `call_deferred`로 승패 판정을 미루지 않는다.
- 삭제는 `pending_remove` 표시 후 틱 끝에 일괄 처리.
- PR에는 재현 시드, 체크리스트 ID, 전후 지표를 포함한다.

## 19. 완료 정의

기능 하나는 다음이 모두 충족되어야 완료다.

1. 정상 흐름 구현.
2. 경계값 구현.
3. CPU가 사용.
4. UI가 상태를 읽히게 표현.
5. 사건 로그가 남음.
6. 헤드리스 테스트 존재.
7. 체크리스트 P0/P1 통과.
8. 최소 한 개 회귀 시드 등록.
9. 실패 시 조작 불량과 규칙 실패를 구분 가능.
10. 아트를 교체해도 판정이 변하지 않음.

## 20. 공식 참고

- Godot 4.7.1 release/archive: `https://godotengine.org/download/archive/4.7.1-stable/`
- Physics introduction and determinism warning: `https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html`
- Headless/command line: `https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html`
- GDScript: `https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html`
- Custom drawing in 2D: `https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html`


---

<!-- 03_CODE_BLUEPRINT.md -->

# 8원 모으기 — Godot 코드 구현 청사진

## 1. 목표

이 문서는 “대충 비슷하게 구현”하는 문서가 아니다. 파일 위치, 상태 소유권, 한 틱의 처리 순서, CPU 입력 방식, 렌더 브리지, 데이터 검증을 고정한다.

스타터 프로젝트는 한 파일에 일부 시스템을 합쳐 실행 가능성을 높였다. 실제 M1부터는 이 청사진대로 분리한다.

## 2. 최종 씬 트리

```text
  ├─ Main (Node)  # 즉시 매치·시드·재시작
  ├─ SimulationHost (Node)  # 이동·밀치기·광물 소유권 처리
  ├─ MapView (Node2D)  # 광산·세 경로·문·은행·점프패드 렌더
  ├─ Camera2D (Camera2D)  # 인간과 광물 사이 동적 프레이밍
  ├─ CarrierView (Node2D)  # 운반자 왕관·추격선·드롭 예고
  ├─ Hud (CanvasLayer)  # 플레이어별 보유 원·대시·광물 상태
  ├─ RoundDirector (Node)  # 광물 재생성·정체 방지·승리
  └─ Telemetry (Node)  # 소유권 이전·가로막기·7원 실패 사건
```

씬 노드는 표현과 수명 관리만 한다. `GameWorld`가 승패·위치·체력·소유권·CPU 상태를 갖는다.

## 3. 최종 소스 트리

```text
scripts/
  game_root.gd
  simulation_host.gd
  sim/
    game_world.gd
    game_config.gd
    command_queue.gd
    seeded_rng.gd
    event_log.gd
    state_hasher.gd
    invariants.gd
    spatial_hash_2d.gd
    collision_math.gd
  systems/
    rounddirector.gd
    runnersystem.gd
    collisionsystem.gd
    mineralsystem.gd
    doorsystem.gd
    chasepresentation.gd
    collectcpusystem.gd
  ai/
    observation.gd
    memory.gd
    utility_brain.gd
    cpu_profile.gd
    collect_eight_cpu.gd
  render/
    render_snapshot.gd
    debug_renderer.gd
    render_bridge.gd
    cue_router.gd
  ui/
    hud.gd
    tutorial_cards.gd
  tests/
    smoke_test.gd
    invariants_test.gd
    replay_test.gd
    cpu_cheat_audit_test.gd
```

파일명은 예시지만 책임을 합치지 않는다.

## 4. 시스템 책임

| 시스템 | 유일 책임 |
|---|---|
| RoundDirector | 광물 생성·정체 방지·8원 승리 |
| RunnerSystem | 이동·대시·회복 |
| CollisionSystem | 몸통박치기·밀침·벽 투영 |
| MineralSystem | 광산·채취·소유·드롭·줍기·예치 |
| DoorSystem | 문·점프패드·일방 회전문 |
| ChasePresentation | 운반자·추격자·가로막기 가독성 |
| CollectCpuSystem | 운반·추격·예측 차단·은행 방어 |

두 시스템이 같은 필드를 직접 수정하지 않는다. 예를 들어 피해는 AbilitySystem이 즉시 HP를 빼는 것이 아니라 `DamageRequest`를 생성하고, 피해 시스템이 정렬해 적용한다.

## 5. GameWorld 계약

```gdscript
class_name CollectEightGameWorld
extends RefCounted

var tick: int = 0
var seed: int
var config: Dictionary
var commands: Array[Dictionary] = []
var events: Array[Dictionary] = []
var result: Dictionary = {}

func _init(match_seed: int, validated_config: Dictionary) -> void:
    seed = match_seed
    config = validated_config
    reset()

func reset() -> void:
    pass

func step_tick(input_commands: Array[Dictionary], dt: float) -> void:
    pass

func make_snapshot() -> Dictionary:
    return {}

func assert_invariants() -> void:
    pass
```

정답 필드:

- `round_tick`
- `runners`
- `mineral`
- `banks`
- `scores`
- `doors`
- `dash_hits`
- `stagnation`
- `result`

`GameWorld` 외부는 위 필드를 직접 수정하지 않는다. 디버그 치트도 명령으로 넣는다.

## 6. SimulationHost 계약

```gdscript
extends Node

const FIXED_DT := 1.0 / 60.0
var world
var command_queue
var replay_recorder

func _physics_process(_delta: float) -> void:
    var commands: Array[Dictionary] = command_queue.pop_for_tick(world.tick)
    world.step_tick(commands, FIXED_DT)
    replay_recorder.record_tick(world.tick, commands, world.state_digest())
    world.assert_invariants()
```

- `delta`를 판정에 사용하지 않는다.
- 일시정지 중에는 tick이 증가하지 않는다.
- 재시작은 현재 World를 새 인스턴스로 교체한다.
- 씬 reload에 의존하지 않는다. 개발 중 리소스 누수 여부를 보려면 같은 씬에서 100회 매치를 재시작한다.

## 7. PlayerCommand

```gdscript
{
  "tick": int,
  "slot": int,
  "seq": int,
  "type": StringName,
  "move": Vector2,
  "aim": Vector2,
  "target_id": int,
  "pressed": bool,
  "payload": Dictionary
}
```

필수 명령 종류:

```text
move
aim
primary
ability_1
ability_2
interact
ping
cancel
restart
debug_step
```

게임에 없는 명령은 무시하되 오류로 기록하지 않는다. 유효하지 않은 target은 비용 없이 실패한다.

## 8. InputRouter

입력은 `_unhandled_input(event)`에서 edge를 수집하고 `_physics_process` 직전 명령으로 만든다.

```gdscript
func consume_command_frame(tick: int) -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    out.append(make_move_command(tick, read_move_vector()))
    if primary_pressed:
        out.append(make_primary_command(tick, mouse_world))
    # edge flag는 여기서 한 번만 소모
    return out
```

### 입력 상태 분리

- hold: 이동·조준·기본 공격 유지.
- edge pressed: 능력·상호작용·대시.
- edge released: 충전형 기술 취소.
- buffered: 쿨다운 종료 직전 입력.
- modal: 역할 선택이나 결과 화면에서만.

조작: **WASD 이동 · Space 대시/몸통박치기 · E 채취·줍기·예치 · R 재시작**

## 9. 한 틱의 정확한 순서

```text
00 pending_remove가 남아 있으면 오류
01 인간 명령 정렬·검증
02 공개 상태에서 CPU Observation 생성
03 CPU 반응 큐에서 실행할 명령 방출
04 입력 버퍼·쿨다운·상태 제한 적용
05 고수준 목표/역할 갱신
06 의도 이동 계산
07 정적 충돌 스윕
08 강제 이동·밀치기
09 동적 충돌 2회
10 공격·투사체·범위 판정
11 상호작용·채널·소유권
12 피해 요청 정렬·적용
13 사망·부활·탈락
14 점수·진화·자원
15 페이즈·스폰·정체 방지
16 승패 확정
17 인과 EventLog
18 삭제 큐 처리
19 불변식
20 RenderSnapshot
21 tick += 1
```

같은 틱 동시 사건은 `actor_id`, `target_id`, `request_seq`로 정렬한다. Dictionary 순회 순서를 판정에 사용하지 않는다.

## 10. 게임 이벤트

| 이벤트 | 계약 |
|---|---|
| mining_started | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| mineral_claimed | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| carrier_hit | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| mineral_dropped | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| mineral_stolen | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| intercept_success | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| coin_deposited | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| seven_coin_alarm | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| winner | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |

시그널은 EventLog를 UI로 전달하는 데만 쓴다.

```gdscript
signal event_presented(event: Dictionary)
```

시그널 수신 순서가 피해·소유권·승패에 영향을 주면 P0 결함이다.

## 11. RenderSnapshot

```gdscript
{
  "tick": int,
  "phase": StringName,
  "camera_target": Vector2,
  "entities": PackedVector2Array,
  "entity_meta": Array[Dictionary],
  "projectiles": Array[Dictionary],
  "zones": Array[Dictionary],
  "world_ui": Array[Dictionary],
  "hud": Dictionary,
  "recent_events": Array[Dictionary]
}
```

`WorldView`는 snapshot 두 개를 보간해도 되지만, 충돌·공격은 보간 위치를 읽지 않는다.

## 12. 렌더 구현 단계

### M0

`Node2D._draw()`:

- 원: 플레이어·CPU·적·낙석·투사체.
- 사각형: 벽·코어·은행·기지.
- 선: 경로·공격 관계·예상선.
- 호/게이지: 채널링·쿨다운.
- 텍스트: 슬롯·체력·점수.

### M2

- 정적 지형을 한 `TileMapLayer` 또는 한 RenderTexture로 교체.
- 움직이는 중요 엔티티만 Sprite2D 풀 사용.
- 수백 적은 MultiMeshInstance2D 또는 일괄 custom draw.
- 월드 UI는 거리·줌에 따라 LOD.
- 파티클은 판정 이벤트에서 생성하고 수명 후 풀 반환.

### 아트 교체 규칙

- Sprite 크기로 충돌 반경 자동 계산 금지.
- AnimationPlayer 트랙으로 피해 적용 금지.
- 프레임 수가 바뀌어도 시전 시간 유지.
- 아트 anchor 변경 시 판정 위치가 변하지 않음.
- 이펙트가 판정 범위를 가리면 투명도·층을 낮춤.

## 13. 데이터 로딩

`res://data/game_config.json`은 부팅 때 한 번 읽고 검증한다.

```gdscript
func load_json(path: String) -> Dictionary:
    var text := FileAccess.get_file_as_string(path)
    var parsed = JSON.parse_string(text)
    assert(typeof(parsed) == TYPE_DICTIONARY)
    return parsed

func validate_config(c: Dictionary) -> void:
    require_number(c, "tick_rate", 60, 60)
    require_unique_ids(c)
    require_non_negative_cooldowns(c)
    require_referenced_ids_exist(c)
    require_probability_sums(c)
```

검증 실패는 조용히 기본값으로 바꾸지 않는다. 오류 경로와 값을 출력하고 부팅을 중단한다.

## 14. 상태 해시와 리플레이

상태 요약은 정렬된 JSON 호환 Dictionary를 만든 뒤 `JSON.stringify`한다. `hash()`만 사용하면 버전·플랫폼 차이를 감사하기 어렵기 때문에 로그에는 원본 요약과 SHA-256을 함께 남긴다.

```gdscript
var ctx := HashingContext.new()
ctx.start(HashingContext.HASH_SHA256)
ctx.update(summary_json.to_utf8_buffer())
var digest := ctx.finish().hex_encode().substr(0, 16)
```

300틱마다 저장한다. 불일치가 발생하면 마지막 일치 tick 이후의 명령과 사건을 덤프한다.

## 15. 불변식

매 tick 개발 빌드:

- 모든 ID 유일.
- 배열 인덱스와 ID를 혼동하지 않음.
- 위치·속도 finite.
- 체력·자원 허용 범위.
- 죽은 엔티티의 활성 공격 0.
- 삭제 예정 엔티티를 새 target으로 선택하지 않음.
- 하나의 목표물은 허용된 수만큼만 소유됨.
- 결과 확정 후 점수 변화 없음.
- CPU action target은 Observation 또는 기억에 존재.
- 이벤트 cause graph 순환 없음.

릴리스 빌드는 60틱마다 축약 검사한다.

## 16. 스타터 프로젝트의 역할

`project/`는 다음을 바로 확인하기 위한 것이다.

1. Godot 프로젝트가 열림.
2. 인간 입력이 다음 physics tick에 반영됨.
3. CPU 5명이 함께 움직이고 목표를 수행함.
4. 광물을 집은 한 명이 즉시 모두의 표적이 되고, 추격 대상이 계속 바뀌는 운반 경쟁
5. `R`로 즉시 재시작.
6. 더미 도형만으로 목표와 실패 원인이 보임.

스타터 수치를 최종값으로 간주하지 않는다. `01_GAMEPLAY_SPEC.md`의 정답값과 체크리스트를 기준으로 확장한다.

## 17. PR 단위

좋은 PR:

- “광물 소유권 상태 머신 + 동시 줍기 테스트”
- “CPU 위험 예측 + 20개 회귀 시드”
- “스테이시스 아군 영향 표시”
- “배송 ETA와 파괴 인과 로그”

나쁜 PR:

- “게임 시스템 전부”
- “리팩토링”
- “AI 개선”
- “밸런스 수정”

모든 PR 설명에 체크리스트 ID·재현 시드·전후 지표를 적는다.


---

<!-- 04_CPU_AI_HEADLESS.md -->

# 8원 모으기 — CPU·헤드리스·재현 명세

## 1. 목표

CPU는 단순히 게임을 진행시키는 봇이 아니다. 인간 한 명이 플레이할 때도 **광물을 집은 한 명이 즉시 모두의 표적이 되고, 추격 대상이 계속 바뀌는 운반 경쟁**라는 상황을 만들어내는 공동 연출자다.

기준:

- 인간 초행 평균보다 약간 잘함.
- 숨은 정보 치팅 없음.
- 반응 지연 존재.
- 현재 행동을 어느 정도 고집.
- 상황에 근거한 실수.
- 인간을 특별히 괴롭히거나 봐주지 않음. 단, 협동 튜토리얼 시범은 허용.
- 결정 이유와 사용한 정보가 로그로 남음.

## 2. CPU 구성

```text
CpuController
  ├─ Perception
  ├─ ObservationBuilder
  ├─ Memory
  ├─ UtilityBrain
  ├─ ReactionQueue
  ├─ ActionRunner
  └─ CheatAudit
```

CPU는 `GameWorld`의 원본 상태를 받지 않는다. `ObservationBuilder`가 공개 가능한 복사본을 만든다.

## 3. 업데이트 빈도

| 계층 | 빈도 |
|---|---:|
| 위험 회피 실행 | 60Hz |
| 반응 큐 실행 | 60Hz |
| Perception | 10Hz |
| 고수준 Utility | 5~10Hz |
| 경로 재계산 | 2~5Hz 또는 경로 무효화 시 |
| 장기 전략 | 1Hz |
| 보급 예측 등 무거운 계산 | 2~5Hz |

판단 주기를 슬롯별로 0~5틱 어긋나게 해 한 프레임에 몰리지 않게 한다.

## 4. 공통 프로필

```json
{
  "id": "veteran_default",
  "reaction_mean_ms": 215,
  "reaction_jitter_ms": 55,
  "aim_error_deg": 6.0,
  "prediction_horizon_sec": 1.15,
  "action_inertia": 1.14,
  "risk_tolerance": 0.56,
  "helpfulness": 0.52,
  "greed": 0.48,
  "betrayal": 0.44,
  "mistake_interval_sec": [12, 20]
}
```

매치 시작 시 각 CPU에 ±10~18% 변형을 준다. 변형은 시드 기반이다.

## 5. 상태

| 행동 | 필수 계약 |
|---|---|
| RACE_MINE | 진입·유지·취소·완료·실패 이유를 구현 |
| MINE_CHANNEL | 진입·유지·취소·완료·실패 이유를 구현 |
| CARRY_HOME | 진입·유지·취소·완료·실패 이유를 구현 |
| CHASE_CARRIER | 진입·유지·취소·완료·실패 이유를 구현 |
| INTERCEPT_ROUTE | 진입·유지·취소·완료·실패 이유를 구현 |
| GUARD_BANK | 진입·유지·취소·완료·실패 이유를 구현 |
| STEAL_DROP | 진입·유지·취소·완료·실패 이유를 구현 |
| RECOVER | 진입·유지·취소·완료·실패 이유를 구현 |
| CELEBRATE | 진입·유지·취소·완료·실패 이유를 구현 |


## 5. 게임별 Observation

```gdscript
{
  "self": {"pos": Vector2, "score": int, "dash_cd": float},
  "mineral": {"state": StringName, "pos": Vector2, "owner": int},
  "visible_runners": [
    {"slot": int, "pos": Vector2, "velocity": Vector2, "score": int, "dash_ready": bool}
  ],
  "banks": Array[Vector2],
  "doors": Array[Dictionary],
  "public_scores": PackedInt32Array
}
```

### 역할 선택

```text
if self owns mineral → CARRY_HOME
elif mineral dropped and reachable first → STEAL_DROP
elif another owns mineral:
    if predicted route intercept is viable → INTERCEPT_ROUTE
    else → CHASE_CARRIER
elif mineral in mine → RACE_MINE or GUARD_BANK
```

### 운반 경로

```text
route_score =
  0.34 × inverse_eta
+ 0.24 × low_enemy_density
+ 0.18 × door_advantage
+ 0.14 × escape_options
+ 0.10 × unpredictability
```

최단경로만 고르지 않는다. 두 경로 점수 차가 8% 미만이면 최근 자신이 덜 사용한 경로를 선택한다.

### 가로막기

운반자의 은행 후보 경로에서 0.9~1.7초 후 위치를 예측한다. CPU의 도착 ETA가 운반자보다 0.35초 이상 빠르면 그 점으로 이동한다. 예상 오차는 반응 지연과 시야 갱신으로 자연스럽게 생긴다.

### 대시

- 충돌 예상 0.18~0.55초.
- 벽에 박힐 확률 25% 미만.
- 맞춘 뒤 광물이 접근 가능한 위치에 떨어짐.
- 다른 추격자가 바로 훔칠 위험이 지나치게 높지 않음.

7원 보유 운반자에게는 공격 우선도가 올라가지만 CPU가 번갈아 몸통박치기하도록 예약 토큰을 둔다.


## 6. 반응 큐

판단 즉시 명령을 실행하지 않는다.

```gdscript
{
  "decided_tick": 1200,
  "execute_tick": 1213,
  "action": "INTERCEPT_ROUTE",
  "target_id": 4,
  "observation_version": 83,
  "reason": {"utility": 0.74, "top_factors": ["seven_coin", "eta_advantage"]}
}
```

실행 시점에 다음을 재검사한다.

- 대상이 여전히 존재.
- 행동이 여전히 가능.
- 치명적 위험이 새로 생기지 않음.
- 비용과 쿨다운 유효.
- 이미 다른 CPU가 독점 예약한 상호작용이 아님.

실패하면 같은 틱에 무한 재판단하지 않고 `action_failed`를 기록하고 최소 3틱 후 재평가한다.

## 7. CPU 예약 토큰

동일 목표에 CPU가 과도하게 몰리는 것을 막기 위한 공개 팀 내부 예약:

```text
rescue:<flag_id>
intercept:<route_point_id>
lane:<lane_id>:reinforcement
delivery:<request_id>
finisher:<target_id>
```

예약은 CPU끼리 숨은 정보를 공유하는 텔레파시가 아니다. 같은 팀의 공개 핑 또는 이미 시작한 행동을 요약한 것이다. 경쟁 게임의 비공식 동맹에는 제한적으로만 사용한다.

## 8. 헤드리스 API

`GameWorld`는 SceneTree 없이 생성 가능해야 한다.

```gdscript
var world = GameWorld.new(seed, config)
for tick in range(36000):
    var commands := policy.commands_for_tick(world.public_snapshot(), tick)
    world.step_tick(commands, 1.0 / 60.0)
    world.assert_invariants()
var report := world.build_report()
```

### 실행 모드

- `human_idle`: 인간 입력 없음. CPU가 진행 불가를 스스로 회복하는지.
- `human_scripted`: 고정 명령. 회귀.
- `human_as_cpu`: 인간 슬롯도 veteran CPU. 밸런스 분포.
- `random_fuzz`: 유효·무효 입력 혼합. 불변식.
- `adversarial`: 벽 모서리·동시 줍기·동시 사망 등 경계 시나리오.
- `long_run`: 30~120분 누수·정체.

## 9. 배치 리포트

```json
{
  "build": "0.3.0",
  "game": "collect_eight",
  "seed": 123,
  "ticks": 36000,
  "result": {},
  "state_hashes": [],
  "events": {},
  "cpu": {
    "reaction_ms": {},
    "action_counts": {},
    "fail_reasons": {},
    "cheat_audit_failures": 0
  },
  "fun_metrics": {},
  "invariant_failures": []
}
```

## 10. 치팅 감사

모든 CPU 결정은 사용한 field path를 기록한다.

```text
visible_players[2].pos
public_scoreboard[4].threat
memory.damage_source[3]
static_map.route_2
```

원본 `world.players[4].hidden_cooldown` 같은 path가 나오면 즉시 실패다.

테스트:

1. 시야 밖 대상 위치만 바꾼 두 세계를 만든다.
2. CPU Observation을 동일하게 유지한다.
3. 300틱 명령 로그가 같아야 한다.
4. 시야에 들어온 뒤에만 행동이 갈라져야 한다.

## 11. 약간 잘하는 수준 검증

초행 인간 10명의 데이터가 생기기 전 임시 기준:

- CPU 목표 수행률이 scripted novice보다 10~25% 높음.
- 생존 시간 또는 승리 기여가 novice보다 8~22% 높음.
- perfect policy보다 20~40% 낮음.
- 반응 최솟값 150ms.
- 10분 동안 적어도 2회 판단 실수가 관찰됨.
- 실수의 80% 이상이 결과 로그로 설명 가능.

인간 데이터가 생기면 백분위로 교체:

```text
기본 CPU = 인간 P60~P70
쉬움 CPU = 인간 P35~P45
어려움 CPU = 인간 P80~P88
```

수치 보너스로 난이도를 만들지 않고 정보 갱신, 예측, 조준, 반응, 계획 깊이를 조절한다.

## 12. 재미 자동 지표

| 측정 | 목표 |
|---|---|
| 추격 전환 | 광물 소유권 1회당 추격 대상 전환 1.4회 이상 |
| 운반 성공률 | 광물 획득 후 예치 성공 28~48% |
| 가로막기 | CPU 추격 중 직접 뒤쫓기보다 예측 차단 선택 25~45% |
| 7원 클라이맥스 | 7원 보유자가 마지막 운반 중 공격받는 비율 70% 이상 |
| 소유권 오류 | 동일 틱 이중 소유·중복 예치 0건 |

자동 지표는 “재미있다”를 증명하지 않는다. 명백하게 재미가 죽은 빌드를 빠르게 거르는 용도다.

## 13. 회귀 시드

`data/regression_seeds.json`:

```json
{
  "must_pass": [
    {"seed": 7, "reason": "기본 완주"},
    {"seed": 81, "reason": "동시 충돌"},
    {"seed": 1042, "reason": "연쇄 실패"},
    {"seed": 9001, "reason": "정체 회복"}
  ],
  "known_story": [],
  "performance": []
}
```

버그를 고치면 재현 시드를 삭제하지 않고 `must_pass`에 추가한다.

## 14. CPU 완료 조건

- 사람이 전혀 조작하지 않아도 매치가 끝남.
- 매치가 끝나는 것뿐 아니라 게임별 사건 지표가 범위 안.
- 인간 한 명이 섞였을 때 CPU가 인간만 노리지 않음.
- 1000개 시드에서 무한 행동·벽 끼임·소유권 deadlock 없음.
- CPU 행동 이유를 결과 화면이나 디버그 HUD에서 읽을 수 있음.


---

<!-- 05_LEVEL_DATA_BALANCE.md -->

# 8원 모으기 — 레벨·데이터·밸런스 계약

## 1. 원칙

- 코드 안의 숫자는 기본값·상수 단위만 허용한다.
- 플레이 수치, 스폰, 맵 좌표, CPU 프로필은 데이터 파일에서 읽는다.
- 데이터가 잘못되면 조용히 보정하지 않고 부팅을 실패시킨다.
- 모든 ID는 문자열이며 파일을 합친 뒤 전역 유일.
- 좌표 원점은 월드 좌상단, 단위는 논리 픽셀.
- 시간은 문서에서는 초, 런타임에서는 tick 정수로 변환.
- 확률 표는 합 1.0 ± 0.0001.
- 아트 크기와 판정 크기를 분리.

## 2. 기본 파일

```text
data/
  game_config.json
  cpu_profiles.json
  entities.json
  abilities.json
  levels/
  waves/
  regression_seeds.json
  schema_version.json
```

`schema_version`이 다르면 마이그레이션 없이 로드하지 않는다.

## 3. 공통 config

```json
{
  "schema_version": 1,
  "tick_rate": 60,
  "logical_size": [1600, 900],
  "human_slot": 0,
  "cpu_count": 5,
  "restart_delay_sec": 1.8,
  "input_buffer_sec": 0.15,
  "camera_shake_scale": 1.0,
  "debug": true
}
```


## 4. 맵 데이터

```json
{
  "id": "highway_loop",
  "size": [1600, 900],
  "mine": {"pos": [800,450], "radius": 70, "channel_sec": 1.0},
  "banks": [],
  "routes": [
    {"id":"north","points":[],"length":0},
    {"id":"center","points":[],"length":0},
    {"id":"south","points":[],"length":0}
  ],
  "doors": [],
  "jump_pads": [],
  "one_way_gates": [],
  "solid_rects": []
}
```

검증:

- 각 은행에서 광산까지 3개 경로가 존재.
- 최단·최장 경로 차이 12~28%.
- 어느 문 하나가 닫혀도 모든 은행이 고립되지 않음.
- 드롭 가능한 모든 위치에서 은행 또는 광산 방향 경로 존재.
- 점프패드 출구가 벽·은행 안이 아님.
- 운반자가 카메라 밖으로 사라지는 시간이 1.2초를 넘지 않음.


## 5. 시스템별 데이터 책임

| 데이터 소비 시스템 | 검증 책임 |
|---|---|
| RoundDirector | 광물 생성·정체 방지·8원 승리 |
| RunnerSystem | 이동·대시·회복 |
| CollisionSystem | 몸통박치기·밀침·벽 투영 |
| MineralSystem | 광산·채취·소유·드롭·줍기·예치 |
| DoorSystem | 문·점프패드·일방 회전문 |
| ChasePresentation | 운반자·추격자·가로막기 가독성 |
| CollectCpuSystem | 운반·추격·예측 차단·은행 방어 |

각 시스템은 자신의 데이터 하위 트리만 검증하고, `ConfigValidator`가 전체 참조를 검사한다.

## 6. 데이터 검증 순서

1. JSON 문법.
2. schema_version.
3. 필수 키와 타입.
4. 범위.
5. ID 유일성.
6. 참조 존재.
7. 그래프 연결.
8. 확률 합.
9. 성능 상한.
10. 게임별 불변식.
11. 정규화된 config hash 생성.
12. 리플레이 헤더에 hash 기록.

## 7. 밸런스 변경 규칙

한 PR에서 바꾸는 가설은 하나다.

좋은 예:

> 운반자가 너무 자주 바로 빼앗긴다. 드롭 무적 0.18→0.28초로 늘리면 소유권 핑퐁이 줄고 예치율이 30~45%에 들어올 것이다.

나쁜 예:

> 전체적으로 더 재밌게 수치 조정.

PR에 포함:

- 변경 전/후 JSON diff.
- 재현 시드 20개.
- 헤드리스 1000판 분포.
- 사람 테스트 영상 3개 이상.
- 사건 지표 변화.
- 부작용.
- 되돌림 기준.

## 8. 튜닝 우선순위

1. 입력 지연·카메라·충돌 오해.
2. 규칙 가독성.
3. 무한 정체·진행 불가.
4. CPU 치팅·집중.
5. 사건이 안 생기는 구조.
6. 승률·수치.
7. 연출.
8. 아트.

조작 불량을 캐릭터 수치로 해결하지 않는다.

## 9. 자동 생성과 수동 승인

AI나 스크립트로 다음을 생성 가능:

- 시드별 스폰표.
- 경로 점.
- 체크리스트 조합.
- 회귀 시나리오.
- CPU 프로필 변형.

다음은 사람이 승인:

- 첫 30초 경험.
- 위험 예고 시간.
- 실패가 웃긴지 억울한지.
- 목표 UI.
- 최종 카메라.
- 역할별 조작감.
- 출시 명칭과 아트.

## 10. 아트 교체

더미 원을 스프라이트로 바꿀 때:

- pivot과 판정 중심을 문서화.
- 실제 충돌 반경 유지.
- 그림자·무기 돌출부는 판정에 포함하지 않음.
- 1프레임 투명 여백으로 위치가 흔들리지 않음.
- 공격 프레임과 피해 tick을 분리.
- 색 없이도 팀·위험·소유권 구분.


---

<!-- 06_PLAYTEST_TELEMETRY.md -->

# 8원 모으기 — 플레이테스트·텔레메트리 명세

## 1. 기능 완료와 재미 완료를 분리

기능 체크리스트가 모두 통과해도 다음이면 실패다.

- CPU가 목표를 수행하지만 상황이 매번 같음.
- 실패 원인이 읽히지 않음.
- 사람이 개입할수록 CPU 진행을 방해하는 느낌만 남음.
- 승리 직전 긴장보다 반복 노동이 큼.
- 아트가 없으면 규칙을 이해할 수 없음.
- 지고 나서 다시 할 이유가 없음.

이 게임의 플레이테스트 질문은 다음 한 문장으로 시작한다.

> 방금 판에서 누가 무엇을 해서 상황이 어떻게 꼬였는가?

대답이 “그냥 적이 세서”, “랜덤이라서”, “CPU가 이상해서”뿐이면 인과 설계가 부족하다.

## 2. 빌드 단계

| 단계 | 참가자 | 목적 |
|---|---|---|
| A | 개발자 1 + CPU | 조작·진행·불변식 |
| B | 장르 경험자 3명, 각자 CPU 포함 | 핵심 재미 발생 |
| C | 초행 10명 | 규칙 이해·억울함 |
| D | 친구 3~6명 역할 대체 테스트 | 분탕·웃음·비난 가능성 |
| E | 1000~10000판 헤드리스 | 분포·정체·극단값 |
| F | 아트 교체 후 10명 | 정보 손실 여부 |

현재 목표는 A~C다.

## 3. 세션 절차

### 초행 테스트

1. 게임 이름과 조작만 알려준다.
2. 목표 설명은 화면 UI에 맡긴다.
3. 첫 판은 끼어들지 않는다.
4. 판 종료 직후 먼저 기억나는 장면을 말하게 한다.
5. 패배 원인을 물어본다.
6. 다시 할지와 이유를 묻는다.
7. 두 번째 판에만 시스템 질문을 받는다.

관찰자는 “그렇게 하면 안 돼요”라고 말하지 않는다.

### 기록

- 전체 화면과 손/키 입력.
- seed.
- build hash.
- 입력 로그.
- EventLog.
- CPU action log.
- 첫 목표 이해 시점.
- 첫 웃음·욕·감탄 타임코드.
- 첫 재시작 클릭 시점.

## 4. 핵심 지표

| 지표 | 허용 범위 |
|---|---|
| 추격 전환 | 광물 소유권 1회당 추격 대상 전환 1.4회 이상 |
| 운반 성공률 | 광물 획득 후 예치 성공 28~48% |
| 가로막기 | CPU 추격 중 직접 뒤쫓기보다 예측 차단 선택 25~45% |
| 7원 클라이맥스 | 7원 보유자가 마지막 운반 중 공격받는 비율 70% 이상 |
| 소유권 오류 | 동일 틱 이중 소유·중복 예치 0건 |

이 범위는 초기 가설이다. 사람 테스트 30판 뒤 중앙값과 상·하위 10%를 다시 고정한다.

## 5. 사건 이벤트

필수 원시 이벤트:

- `mining_started`
- `mineral_claimed`
- `carrier_hit`
- `mineral_dropped`
- `mineral_stolen`
- `intercept_success`
- `coin_deposited`
- `seven_coin_alarm`
- `winner`

### story_event 생성

원시 사건 2개 이상이 4초 안에 인과로 연결되고, 다음 중 하나를 만족하면 `story_event`를 만든다.

- 두 명 이상에게 영향.
- 선두 또는 승패 상태 변경.
- 구조·배신·소유권 이전.
- 실패 원인이 특정 플레이어 행동으로 추적.
- 관전자에게 의미 있는 반전.
- 플레이어가 직접 만든 위험이 되돌아옴.

```json
{
  "type": "story_event",
  "start_tick": 1800,
  "end_tick": 1974,
  "actors": [0, 3, 4],
  "root_cause": 812,
  "outcome": "leader_changed",
  "severity": 0.72,
  "readability": 0.83,
  "tags": ["player_caused", "chain", "comeback"]
}
```

## 6. 웃긴 실패와 억울한 실패 구분

### 웃긴 실패

- 경고를 봤다.
- 자신의 선택이나 다른 플레이어의 선택이 원인이다.
- 사건이 0.5~4초 사이에 전개돼 이해 가능하다.
- 패배 뒤 “다음에는 이렇게 하자”가 생긴다.
- 관전자도 원인을 볼 수 있다.

### 억울한 실패

- 화면 밖 즉사.
- 회피 공간 없음.
- 입력이 먹지 않음.
- CPU가 숨은 정보로 선행 대응.
- 동시 판정 순서가 매번 다름.
- 결과 문구가 실제 원인과 다름.
- 10초 이상 아무것도 못한 뒤 패배.

억울한 실패 태그가 전체 실패의 5%를 넘으면 밸런스 전에 규칙·카메라·예고를 고친다.

## 7. 결과 화면

결과 화면은 숫자 표보다 이야기 요약이 먼저다.

```text
가장 큰 전환
1. [00:54] 2번이 운반자를 밀쳤지만 광물이 5번 앞으로 떨어졌습니다.
2. [01:03] 5번이 7원을 완성했고 모두의 표적이 됐습니다.
3. [01:11] 은행 앞 충돌로 5번이 마지막 광물을 잃었습니다.
```

게임별 문구는 이벤트 ID와 cause graph로 생성한다. LLM을 런타임 필수 의존으로 두지 않는다. 규칙 기반 문구를 먼저 만든다.

## 8. 자동 시뮬레이션 층화

1000판 기준:

- 시드 0~399: 일반.
- 400~599: CPU 성격 극단.
- 600~749: 스폰·조합 극단.
- 750~849: 인간 scripted novice.
- 850~929: 인간 veteran policy.
- 930~969: 입력 fuzz.
- 970~999: 성능 최대 부하.

각 층에서 별도 분포를 본다. 전체 평균으로 극단 실패를 숨기지 않는다.

## 9. CPU 캘리브레이션

사람 10명의 첫 3판을 기준 데이터로 사용:

- 반응 시간.
- 목표까지 경로 효율.
- 위험 회피 성공.
- 공격 명중.
- 상호작용 성공.
- 동료/상대 관찰 횟수.
- 계획 변경 빈도.
- 정체 탈출 시간.

CPU는 사람 평균보다 모든 항목이 높은 것이 아니라 핵심 수행 2~3개만 높고, 사회적 판단과 새로운 상황에서는 흔들리게 한다.

## 10. 튜닝 회의 형식

각 이슈는 다음 형식:

```text
현상:
재현 seed/tick:
사용자 발언:
EventLog 원인:
조작/가독성/룰/CPU/수치 중 분류:
가설:
최소 변경:
통과 지표:
회귀 위험:
담당:
```

“재미없음”을 곧바로 수치 상향으로 번역하지 않는다.

## 11. 출시 금지

- P0 미완료 1개 이상.
- P1 핵심 재미 항목 미완료.
- 1000판 중 진행 불가 1회 이상.
- CPU 치팅 감사 실패.
- 같은 시드·입력에서 승패가 갈라짐.
- 첫 판 목표 이해 중앙값 60초 초과.
- 패배 원인 오답률 25% 초과.
- 재시작까지 중앙값 4초 초과.
- 핵심 story_event 판당 0.6회 미만.
- 인간 한 명이 CPU에게 비정상 집중.
- 런타임 오류 또는 NaN.


---

<!-- 07_BUILD_ORDER.md -->

# 8원 모으기 — 실제 구현 순서

## 1. 원칙

처음부터 최종 아키텍처와 모든 콘텐츠를 동시에 만들지 않는다. 단, 임시 코드가 판정과 표현을 섞는 것은 허용하지 않는다.

매 단계:

1. 회색상자.
2. 인간 조작.
3. CPU가 같은 규칙 사용.
4. 실패 원인 표시.
5. 헤드리스 시나리오.
6. 체크리스트.
7. 사람 테스트.
8. 다음 단계.

## 2. 단계

| 단계 | 산출물 | 진입/종료 게이트 |
|---|---|---|
| 8W-M0 | 한 광산·두 은행·채취·운반·예치 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| 8W-M1 | 6인 CPU와 점수·승리 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| 8W-M2 | 대시·밀치기·드롭·동시 경합 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| 8W-M3 | 세 경로·문·예측 가로막기 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| 8W-M4 | 7원 클라이맥스·카메라·인과 로그·헤드리스 | 해당 마일스톤 P0 100%·P1 90% 이상 |

## 3. 첫 3일 작업

### Day 1 — 부팅과 인간 입력

- Godot 4.7.1 프로젝트 생성.
- 1600×900 stretch.
- Main Scene.
- 60Hz SimulationHost.
- InputRouter.
- 인간 엔티티 하나.
- `R` 재시작.
- F1 충돌 표시.
- smoke_test.
- Git CI에서 headless import와 smoke 실행.

완료 증거:

- 키 입력 다음 physics tick에 위치 변화.
- 10분 실행 오류 0.
- 매치 100회 재시작 후 Node·메모리 안정.
- P0 부팅/입력 항목 통과.

### Day 2 — 최소 목표 루프

- 목표물과 승패.
- 실패 조건.
- 결과 화면.
- 2.5초 내 재시작.
- 핵심 이벤트 3종.
- 인간만으로 한 판 완료.

완료 증거:

- 설명 없이 개발자 외 1명이 목표 이해.
- 승리·패배 모두 재현.
- 결과 원인 한 문장.
- 조작 불량 없음.

### Day 3 — CPU 한 명

- Observation.
- 반응 큐.
- 고수준 행동 2~3개.
- 같은 명령 계약으로 움직임.
- 디버그 행동 문구.
- CPU 치팅 감사 첫 테스트.

완료 증거:

- CPU가 사람 없이 목표 수행.
- 150ms 미만 반응 없음.
- 시야 밖 상태 변경에 명령 로그 동일.
- 행동 왕복 초당 2회 미만.

## 4. 시스템 분할 순서

- **RoundDirector**: 광물 생성·정체 방지·8원 승리
- **RunnerSystem**: 이동·대시·회복
- **CollisionSystem**: 몸통박치기·밀침·벽 투영
- **MineralSystem**: 광산·채취·소유·드롭·줍기·예치
- **DoorSystem**: 문·점프패드·일방 회전문
- **ChasePresentation**: 운반자·추격자·가로막기 가독성
- **CollectCpuSystem**: 운반·추격·예측 차단·은행 방어

먼저 `GameWorld` 안에서 함수로 구현하고, 한 파일이 700줄 또는 한 시스템이 3개 이상 필드를 독점하기 시작하면 별도 스크립트로 옮긴다. 분할 시 동작 변경 금지. 리플레이 해시가 같아야 한다.

## 5. CPU 도입 순서

1. scripted 이동.
2. 위험 회피.
3. 목표 수행.
4. 다른 슬롯 인식.
5. 역할/표적 선택.
6. 행동 관성.
7. 반응 지연.
8. 성격.
9. 상황 기반 실수.
10. 치팅 감사.
11. 사람 데이터 캘리브레이션.

랜덤 실수를 먼저 넣지 않는다. 기본 판단이 옳은지 알 수 없어진다.

## 6. 콘텐츠 도입 순서

- 맵 1개.
- 핵심 상호작용 1개.
- CPU 1명.
- CPU 5명.
- 사건 가독성.
- 나머지 능력/역할.
- 전체 맵/웨이브.
- 성능.
- 아트.

콘텐츠 양을 늘리기 전에 한 판에서 핵심 사건이 반복적으로 발생해야 한다.

## 7. 역할 분담 예시

### 클라이언트/시스템 개발자

- SimulationHost.
- GameWorld.
- 입력·충돌.
- 시스템 구현.
- 리플레이·테스트.
- CPU 실행기.

### 백엔드 개발자

첫 프로토타입에서는 백엔드 대신:

- 헤드리스 runner.
- 배치 리포트.
- seed 관리.
- telemetry schema.
- 추후 authoritative server 조사.
- CI.

### 아트

- 회색상자 정보 설계 검토.
- 판정과 맞는 silhouette.
- 위험·소유권·팀 형태 언어.
- UI mock.
- 최종 sprite/animation.
- 효과가 판정을 가리지 않는지 검수.

아트가 늦어도 플레이 테스트는 중단하지 않는다.

## 8. AI 코딩 워크플로우

AI에게 한 번에 “게임 전체 구현”을 시키지 않는다.

좋은 요청:

```text
GameWorld의 MineralSystem만 구현.
입력: 현재 mineral state, runners, interact commands.
출력: state transition requests와 event records.
동시 줍기 우선순위는 distance → slot id.
Node API 사용 금지.
아래 14개 테스트를 모두 통과해야 함.
```

필수 첨부:

- 수정 가능한 파일.
- 상태 소유권.
- 금지 API.
- 함수 signature.
- 체크리스트 ID.
- 테스트.
- 성능 예산.
- 완료 예.

AI 결과 검토:

1. 판정이 Node/애니메이션을 읽는가.
2. 랜덤 API를 직접 쓰는가.
3. Dictionary 순서에 의존하는가.
4. CPU가 private 상태를 읽는가.
5. 실패 경계를 처리하는가.
6. 테스트가 실제 요구를 검증하는가.
7. 코드보다 데이터로 가야 할 수치가 박혔는가.

## 9. 브랜치·PR

```text
main
prototype/<milestone>
feature/<checklist-id>-short-name
fix/<seed>-short-name
balance/<hypothesis>
```

PR 하나는 가능하면 1~3일 크기. 변경 체크리스트 5~30개. 생성형 AI가 만든 대형 코드 덤프는 기능별로 나눠 검토한다.

## 10. 각 단계 종료 회의

질문:

- 이번 단계에서 새로 생긴 기억 가능한 사건은?
- 실패는 누구 행동 때문인지 보이는가?
- CPU가 재미를 만들었나, 단순히 진행만 했나?
- 조작으로 해결할 문제를 수치로 덮었나?
- 다음 콘텐츠가 정말 필요한가?
- 삭제할 기능은?
- 최악 seed는?
- 초행자에게 설명이 필요했던 부분은?

## 11. 최종 전환

회색상자 재미 게이트 통과 후에만:

- 실제 아트.
- 저장.
- 옵션.
- 모바일 입력.
- 온라인.
- 계정.
- 수익화.
- 라이브 콘텐츠.

온라인부터 만들면 재미가 없는 루프를 비싼 구조로 고정할 수 있다.


---

<!-- 08_ACCEPTANCE_RULES.md -->

# 8원 모으기 — 체크리스트 운용·완료 판정

## 1. 체크리스트

이 패키지에는 공통 Godot 항목과 8원 모으기 전용 항목을 합친 **3,193개 체크리스트**가 들어간다.

- `CHECKLIST_VIEWER.html`: 검색·필터·완료 상태 저장.
- `implementation_checklist.csv`: 스프레드시트·이슈 import.
- `implementation_checklist.json`: 자동화·CI.
- `P0_P1_GATE.md`: 실제 개발에서 먼저 처리할 항목.

각 항목 필드:

```text
id
game
milestone
subsystem
priority
source_status
title
precondition
steps
expected
automation
evidence
owner
trace
status
```

## 2. 우선순위

### P0

- 프로젝트 부팅.
- 조작.
- 승패.
- 진행 불가.
- 소유권·킬·동시 판정.
- CPU 치팅.
- 재현.
- 데이터 손상.
- 크래시·NaN.
- 핵심 실패 원인.

P0 하나라도 미완료면 플레이테스트 빌드로 배포하지 않는다.

### P1

- 핵심 재미.
- CPU 행동 품질.
- 위험·목표 가독성.
- 카메라.
- 오디오 큐.
- 성능 대표 구간.
- 재시작.
- 관전.
- 역할별 의미.

마일스톤 종료 시 해당 P1 90% 이상, 최종 회색상자는 100%.

### P2

- 조합·시드·해상도·경계값의 대량 회귀.
- 출시 안정성을 높이지만 초기 재미 세로 슬라이스를 막지는 않음.
- 최종 QA에서는 정의된 대상 범위를 모두 실행.

## 3. 완료 증거

“제가 해봤는데 됨”은 증거가 아니다.

허용 증거:

- headless test 로그.
- 상태 해시.
- 스크린샷 diff.
- profiler capture.
- seed + tick.
- 30초 이하 재현 영상.
- EventLog.
- 사람이 작성한 관찰 기록.
- 데이터 validator 출력.

## 4. 체크 순서

1. 현재 마일스톤 필터.
2. P0.
3. P1.
4. 사람 테스트.
5. 수정.
6. P0/P1 재실행.
7. 대표 P2.
8. 회귀 시드 전체.
9. 다음 단계.

## 5. 예외 금지

다음 사유로 체크를 닫지 않는다.

- “아트 나오면 해결.”
- “CPU라 어쩔 수 없음.”
- “낮은 확률.”
- “내 PC에서는 됨.”
- “원본도 불친절했음.”
- “나중에 온라인에서 수정.”
- “사용자가 익숙해지면 됨.”

## 6. 기능별 완료 템플릿

```text
체크리스트 ID:
구현 파일:
상태 소유자:
입력:
정상 결과:
실패 결과:
CPU 사용:
UI 표현:
EventLog:
자동 테스트:
회귀 seed:
성능:
남은 위험:
```

## 7. 게임 완료 판정

아래를 모두 충족:

- 6인 경쟁, 중앙 광물, 소유권 경합, 드롭·줍기·은행 예치·세 경로·CPU 가로막기가 작동하는 회색상자
- 인간 1 + CPU 5 즉시 시작.
- 30초 안에 핵심 목표 이해.
- CPU가 인간보다 약간 잘하되 치팅 없음.
- 판당 기억 가능한 player-caused story_event 1회 이상.
- 실패 원인을 특정 사건까지 추적.
- 전멸/패배 뒤 2.5초 내 재시작.
- 대표 PC 60 physics FPS.
- 1000 seed 진행 불가 0.
- P0/P1 100%.
- `01_GAMEPLAY_SPEC`의 출시 금지 조건 0건.

## 8. 원본 동일성과 독자화

프로토타입은 원형의 핵심 규칙과 재미를 검증하기 위한 것이다. 출시 전:

- 고유명사 교체.
- 아트·사운드 완전 독자 제작.
- 맵 레이아웃 재해석.
- UI 독자화.
- 규칙 차별화.
- 사용한 공개 자료·라이선스 검토.

체크리스트의 “동일 수준”은 원본 파일 복제가 아니라 **핵심 루프·조작 반응·사회적 사건·실패 재미가 재현되는 수준**을 뜻한다.


---

<!-- 09_PIXI_TO_GODOT_MIGRATION.md -->

# 8원 모으기 — PixiJS 명세를 Godot로 옮기는 대응표

## 1. 핵심 변경

| 기존 PixiJS 개념 | Godot 대응 | 주의 |
|---|---|---|
| `Application` | 프로젝트 + Main Scene | 엔진 부팅과 게임 매치를 분리 |
| `Container` 레이어 | Node2D/CanvasLayer | 노드 트리를 판정 상태로 사용 금지 |
| `Graphics` | Node2D `_draw()` | 회색상자 일괄 렌더 |
| Sprite pool | Sprite2D pool/MultiMeshInstance2D | 대량 엔티티는 노드 수 제한 |
| ticker | `_physics_process` / `_process` | 판정은 physics tick만 |
| DOM pointer 변환 | Viewport canvas transform 역변환 | stretch·Camera2D 고려 |
| TypeScript interface | GDScript class/Dictionary/Resource | 런타임 validator 필수 |
| JSON module | `FileAccess` + `JSON.parse_string` | import 시 schema 검사 |
| WebAudio | AudioStreamPlayer/2D | 판정 이벤트에서 큐 생성 |
| browser localStorage | `user://` FileAccess | 회색상자에는 진행 저장 불필요 |
| headless Node.js | Godot `--headless` | SceneTree 없이 GameWorld 실행 |
| Vite build | Godot import/export | CI에서 `--headless --editor --quit` |
| Pixi viewport | Camera2D + CanvasLayer | HUD는 카메라와 분리 |
| custom event bus | signal + EventLog | signal 순서로 판정 금지 |

## 2. 그대로 유지할 것

엔진을 바꿔도 다음은 바꾸지 않는다.

- 60Hz 명령 기반 시뮬레이션.
- 인간과 CPU가 같은 Command 계약.
- 시드 RNG.
- 상태 해시·리플레이.
- 인과 EventLog.
- 조작 지연 목표.
- CPU 정보 제한.
- P0/P1 체크리스트.
- 더미 아트 우선.
- 실패 원인 가독성.

## 3. Godot 물리 사용 범위

사용 가능:

- 에디터에서 충돌 도형 시각화.
- 비권위적 파티클·잔해.
- 카메라와 화면 효과.
- 최종 아트의 물리성 보조.
- 플레이 결과와 무관한 장식.

정답 판정에 사용하지 않음:

- RigidBody2D 충돌 순서.
- Area2D signal 순서.
- CharacterBody2D의 현재 global_position.
- NavigationAgent2D의 실시간 회피 결과.
- AnimationPlayer callback.

8원 모으기의 핵심 재미는 플레이어 간 연쇄 원인이므로 같은 입력이 다른 원인을 만들면 디버깅과 CPU 검증이 불가능해진다.

## 4. 씬 분리

PixiJS에서 한 stage에 모든 레이어를 붙이던 방식을 그대로 옮겨 Main 하나에 수백 노드를 만들지 않는다.

```text
Main
├─ SimulationHost
├─ WorldView
│  └─ Camera2D
├─ WorldUi
├─ Hud
├─ Audio
└─ Telemetry
```

아트가 늘어나면 WorldView 아래에 지형·엔티티·이펙트 하위 노드를 추가하되 SimulationHost는 참조하지 않는다.

## 5. 입력

브라우저 keydown/up 직접 처리 대신 InputMap을 사용하되, edge와 hold를 `InputRouter`가 명령으로 바꾼다. 스타터는 키 코드를 직접 읽을 수 있지만 M1에서 InputMap으로 고정한다.

모바일 이전 시에도 가상 조이스틱이 `move` 명령을 만들 뿐 GameWorld는 입력 장치를 모른다.

## 6. 데이터

이전 JSON은 그대로 가져올 수 있으나 다음을 추가:

- `schema_version`.
- `godot_min_version`.
- 좌표 단위.
- ID 참조 validator.
- Resource 변환 여부.
- config hash.

에디터 Inspector에서 편집할 항목만 custom Resource로 노출한다. 같은 값의 JSON·Resource 이중 원본은 만들지 않는다.

## 7. 스타터 프로젝트

이 ZIP의 `project/`는 Godot-native 회색상자다. 이전 PixiJS 코드가 없어도 실행된다. 문서와 체크리스트도 다른 패키지를 참조하지 않는다.

실제 이관 시 기존 PixiJS 구현을 줄 단위로 번역하지 말고:

1. 상태 구조 추출.
2. 명령 추출.
3. 한 틱 순서 추출.
4. Godot GameWorld 재작성.
5. 상태 해시 비교.
6. 렌더 재작성.
7. 입력 재연결.

순서로 진행한다.
