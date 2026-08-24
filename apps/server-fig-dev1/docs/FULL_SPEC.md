

---

<!-- 00_READ_FIRST.md -->

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
  FULL_SPEC.md
  SOURCES.md
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
5. 실제 개발은 `docs/07_BUILD_ORDER.md` 순서와 `docs/checklists/P0_P1_GATE.md`를 따른다.

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


---

<!-- 01_GAMEPLAY_SPEC.md -->

# 다굴게임 — 게임플레이·수치 명세

> 기준 엔진은 Godot 4.7.1이지만, 이 문서의 구조체·알고리즘 블록은 언어 독립적 의사코드다. 실제 GDScript 파일·함수·씬 계약은 `03_CODE_BLUEPRINT.md`를 따른다.

## 2.1 재미 계약

다굴게임은 밸런스가 완벽한 1대1 전투를 여럿 붙인 게임이 아니다. **누가 지금 가장 위험해 보이는지, 누구를 먼저 죽일지, 방금까지 같이 때리던 상대를 언제 배신할지**가 본체다. 전투 조작은 정치가 실제 피해로 이어지게 하는 도구다.

반드시 생겨야 하는 상황은 다음과 같다.

1. 좋은 조합을 뽑은 CPU가 초반부터 위협도 1위가 되어 여러 명에게 쫓긴다.
2. 한 플레이어의 코어가 20% 이하가 되자 집중 공격하던 두 명이 서로 막타를 노리며 싸운다.
3. 공격받던 약자가 제3자의 난입으로 살아나고, 이후 그 제3자를 배신한다.
4. 인간이 “쟤부터” 핑을 찍으면 일부 CPU는 동조하지만 전부가 완벽히 복종하지 않는다.
5. 탈락한 플레이어가 누가 배신했는지 관전하며 다음 판을 기대한다.

최악의 실패는 `랜덤 조합 때문에 시작부터 아무것도 못함`, `CPU 5명이 인간만 이유 없이 공격`, `코어를 몰래 순식간에 철거`, `전투가 길어져 아무도 결정을 못 냄`이다.

## 2.2 원본 확인과 고정 규칙

### [원본 확인]

- 플레이어마다 무작위 전투 유닛·능력과 파괴 가능한 기반이 있다.
- 기반이 파괴되면 탈락한다.
- 강한 유닛이나 능력을 가진 플레이어를 먼저 다굴하는 정치가 자연스럽게 생긴다.
- 마지막 생존자가 승리한다.

### [프로토타입 고정]

- 기본 6인: 인간 1 + CPU 5. 지원 범위 4~8인.
- 각 슬롯은 `영웅 아키타입 1 + 무작위 능력 1 + 패시브 1 + 코어 1`을 가진다.
- 영웅이 죽어도 코어가 살아 있으면 6초 후 부활한다.
- 영웅 사망 시 자기 코어가 120 고정 피해를 받는다. 처치가 완전히 무의미해지는 것을 막는다.
- 코어 최대 체력 1,800, 기본 방어 12, 전투 시작 후 18초 동안 직접 피해 면역.
- 마지막 코어가 남으면 승리. 9분부터 코어가 초당 14씩 붕괴해 12분 전에 결판을 낸다.

## 2.3 경기 흐름

```text
0:00~0:06  랜덤 카드 공개. 모든 조합과 예상 강점 표시.
0:06~0:18  정찰·이동 가능, 코어 직접 피해 면역.
0:18~6:00  정상 전투. 위협도·현상금·원한 형성.
6:00~9:00  중립 안전지대 축소, 중앙 충돌 증가.
9:00~12:00 코어 자연 붕괴. 완전한 수비 플레이 종료.
마지막 코어 파괴 후 2.0초 결과·즉시 재시작.
```

랜덤 카드는 이름만 보여주지 않는다. `튼튼함 / 추격 / 순간 피해 / 공성 / 생존` 5축을 1~5로 표시한다. 인간이 자기 조합을 이해하지 못한 채 죽는 것을 방지한다.

## 2.4 맵

- 고정 카메라 1600×900.
- 실제 월드 1600×900. 확대·스크롤 없음.
- 코어는 중심 반경 610의 원주에 균등 배치한다.
- 중앙 반경 210은 엄폐물이 없는 충돌 지역.
- 각 코어 앞 180유닛에 낮은 엄폐물 2개. 원거리 공격은 막지만 이동은 둘러갈 수 있다.
- 코어 사이마다 2개의 연결 통로가 있어 한 방향 봉쇄로 갇히지 않는다.
- 중립 회복·강화 오브젝트는 두지 않는다. 정치보다 오브젝트 최적화가 우선되는 것을 막는다.

### 스폰 회전

슬롯 위치 때문에 특정 아키타입이 유리해지지 않도록 매치 시드로 맵 전체를 0~7 슬롯만큼 회전한다. 코어 간 실제 거리는 모두 ±2% 이내다.

## 2.5 조작

### 기본 방식: 직접 이동 + 마우스 조준

| 입력 | 기능 |
|---|---|
| WASD | 이동 |
| 마우스 | 조준 방향 |
| 좌클릭 홀드 | 기본 공격. 사거리 밖이면 발사하지 않고 방향만 유지 |
| 우클릭 | 지정 적 영웅/코어를 표적 고정. 다시 우클릭 또는 시야 이탈 1.2초면 해제 |
| Q | 무작위 능력 |
| W | 아키타입 고유 전술 행동 |
| Space | 공용 짧은 회피. 2회 충전, 충전당 6초 |
| 1~8 | 해당 슬롯 집중 핑 |
| C | 현재 공격자·원한·위협도 패널 |

RTS식 클릭 이동 프리셋을 옵션으로 제공할 수 있지만, 재미 검증 기준은 직접 이동이다. 정치 상황에서 도망·추격·배신을 즉시 표현하기 쉽기 때문이다.

### 이동·공격 수치

- 영웅 반지름 24~30, 아키타입별 정의.
- 공용 회피: 0.18초에 120유닛, 시전 중 피해 감소 35%, 완전 무적 없음.
- 회피가 벽을 통과하지 않는다. 스윕 충돌 후 남은 거리를 접선으로 미끄러뜨린다.
- 기본 공격은 입력 즉시 0.08초 이내 예고가 시작된다.
- 원거리 투사체 속도 760유닛/초. 근접 공격 전방 100도.
- 공격 취소 가능 시점은 준비 동작 45% 전까지. 취소해도 쿨다운 25%를 지불한다.

## 2.6 코어와 탈락

### 코어

- 체력 1,800.
- 반지름 58.
- 방어 12. 최종 피해 `max(1, rawDamage - defense)`.
- 자기 영웅이 300유닛 안에 있으면 6초마다 보호막 35, 최대 105. 전원이 자기 집에만 숨지 않게 보호막은 작다.
- 같은 공격자가 2초 안에 코어에 300 이상 피해를 주면 전체에게 “공성 중” 경고.
- 코어 체력 40%, 20%에서 외형과 경고음이 바뀐다.

### 영웅 사망

1. 피해·공격자·관여자를 확정한다.
2. 코어에 120 고정 피해.
3. 6초 부활 타이머.
4. 카메라는 자유 관전으로 전환하지만 코어 방어 핑은 가능.
5. 코어가 파괴되면 부활 취소·탈락.

### 탈락

- 코어 파괴 시 영웅과 소환물이 0.45초 동안 붕괴한다.
- 탈락자는 투표·핑으로 전투에 영향을 줄 수 없다. 이모트와 관전 대상 전환만 가능.
- 다음 판 재시작 투표는 승패 확정 후에만.

## 2.7 랜덤 조합 시스템

아키타입은 `data/gang_up/archetypes.json`, 능력은 `abilities.json`, 패시브는 `passives.json`을 정답으로 사용한다.

### 아키타입

| ID | 이름 | HP | 속도 | 공격/사거리/주기 | 고유 특성 | 예산 |
| --- | --- | --- | --- | --- | --- | --- |
| runner | 질주자 | 720 | 340 | 58 / 105 / 0.52s | 3초마다 다음 이동이 18% 빨라진다. | 99 |
| bruiser | 난투가 | 1080 | 270 | 92 / 88 / 0.78s | 연속 공격 3회째가 45% 추가 피해. | 101 |
| artillery | 포격수 | 650 | 245 | 118 / 430 / 1.25s | 1.1초 정지 후 사거리 15% 증가. | 100 |
| assassin | 암습자 | 610 | 325 | 126 / 90 / 0.9s | 비전투 4초 후 첫 타격 55% 추가 피해. | 102 |
| bulwark | 방벽 | 1450 | 220 | 54 / 100 / 0.82s | 정면 120도에서 받는 피해 22% 감소. | 100 |
| summoner | 소환가 | 760 | 255 | 42 / 310 / 0.86s | 10초마다 체력 90의 하수인 1기, 최대 3기. | 99 |
| leech | 흡수자 | 880 | 265 | 70 / 115 / 0.65s | 영웅에게 준 피해의 14% 회복. | 101 |
| controller | 교란자 | 800 | 260 | 55 / 280 / 0.78s | 같은 대상 4회 적중 시 0.7초 둔화. | 99 |
| glass | 유리대포 | 520 | 285 | 154 / 360 / 1.05s | 체력 40% 이상일 때 피해 12% 증가. | 101 |
| sapper | 공성가 | 830 | 245 | 64 / 270 / 0.78s | 코어에 주는 피해 35% 증가. | 100 |
| reflector | 반사자 | 970 | 248 | 62 / 120 / 0.7s | 3초마다 다음 단일 피해의 20%를 공격자에게 반사. | 100 |
| supporter | 기회주의 지원가 | 850 | 270 | 50 / 300 / 0.72s | 근처 다른 플레이어가 공격 중인 대상에게 피해 14% 증가. | 98 |


### 능력

| ID | 이름 | 쿨다운 | 시전 | 사거리 | 효과 |
| --- | --- | --- | --- | --- | --- |
| gravity | 중력장 | 16s | 0.25s | 430 | 반경 170 적을 중앙으로 끌고 1.8초 35% 둔화. |
| blink_strike | 점멸 베기 | 12s | 0.1s | 360 | 대상 뒤로 이동해 135 피해. 코어에는 70 피해. |
| fortify | 요새화 | 18s | 0.0s | 0 | 2.8초 동안 받는 피해 45% 감소, 속도 25% 감소. |
| chain_bolt | 연쇄탄 | 13s | 0.2s | 420 | 90 피해, 3회 튕김. 같은 대상 재적중 불가. |
| decoy | 미끼 복제 | 15s | 0.0s | 120 | 3초 동안 가짜 영웅. CPU 표적 점수에 실제처럼 반영되나 공격 1회 후 들통. |
| swap | 위치 교환 | 20s | 0.35s | 390 | 적 영웅과 위치를 교환. 코어·무적 대상 불가. |
| silence | 침묵파 | 17s | 0.2s | 320 | 원뿔 내 적의 능력을 2.2초 봉인. |
| heal | 응급 복구 | 19s | 0.55s | 0 | 자신 220, 자신의 코어 120 회복. 피격 시 시전 취소. |
| minefield | 기뢰 지대 | 14s | 0.2s | 270 | 20초 유지 기뢰 3개. 각 72 피해와 밀쳐내기. |
| hook | 끌어오기 | 11s | 0.15s | 500 | 첫 적 영웅을 250 거리 끌고 60 피해. |
| overclock | 과부하 | 18s | 0.0s | 0 | 4초 공격속도 45% 증가, 종료 후 1초 침묵. |
| clone | 분신 | 21s | 0.15s | 80 | 5초 동안 공격력 35% 분신 1기. 코어 피해는 50%만. |
| reflect | 응징막 | 17s | 0.0s | 0 | 2초 동안 받은 영웅 피해의 35% 반사, 최대 240. |
| smoke | 연막 | 13s | 0.1s | 280 | 반경 190 시야 차단 4초. 내부 대상 자동조준 불가. |
| shockwave | 충격파 | 12s | 0.25s | 240 | 주변 78 피해와 170 밀쳐내기. |
| steal | 강탈 | 22s | 0.3s | 280 | 적의 남은 일반 능력 쿨다운 20%를 빼앗아 자신의 쿨다운 단축. |


### 패시브

| ID | 이름 | 효과 |
| --- | --- | --- |
| revenge | 복수심 | 최근 15초 동안 자신에게 가장 많은 피해를 준 적에게 피해 9% 증가. |
| underdog | 약자 보정 | 자신의 코어 체력이 최하위면 이동속도 8% 증가. |
| bounty_hunter | 현상금 사냥 | 현재 위협도 1위에게 준 피해의 5%를 코어 보호막으로 전환. |
| last_stand | 최후의 저항 | 코어 체력 20% 이하에서 영웅 최대 체력 14% 증가. |
| opportunist | 막타 본능 | 체력 25% 이하 영웅에게 피해 10% 증가. |
| home_guard | 수문장 | 자신 코어 260 이내에서 받는 피해 12% 감소. |
| nomad | 유랑 | 자신 코어 600 밖에서 이동속도 7% 증가. |
| scavenger | 잔해 수거 | 영웅 처치 관여 시 체력 90 회복. |
| volatile | 폭발성 | 사망 시 반경 120에 60 피해. 같은 플레이어에게 10초 내 반복 피해 불가. |
| diplomat | 외교가 | 5초간 피해를 주고받지 않은 플레이어에게 첫 피해 8% 감소. |
| siege_insurance | 공성 보험 | 코어가 5초 내 최대 체력 15% 이상 잃으면 4초 보호막 120. |
| momentum | 기세 | 영웅 처치 관여 후 4초 공격속도 12% 증가. |


### 조합 생성

1. 슬롯마다 아키타입을 독립 추첨하되 같은 아키타입은 한 매치에 최대 2명.
2. 능력을 추첨한다.
3. 패시브를 추첨한다.
4. 금지 조합을 검사한다.
5. 추정 파워를 계산해 88~112 범위 밖이면 능력 또는 패시브만 다시 뽑는다.
6. 모든 슬롯의 추정 파워 표준편차가 9를 넘으면 가장 극단적인 두 슬롯만 재추첨한다.

금지 조합 예:

- `artillery + blink_strike + nomad`: 지나친 안전성과 도주.
- `bulwark + fortify + last_stand`: 시간 지연 과다.
- `glass + overclock + momentum`: 순간 삭제 위험.
- `summoner + clone`: 화면 엔티티·코어 공성 과다. 허용하려면 소환 한도를 공유해야 한다.

### 불공평함 허용 범위

모든 조합이 동일할 필요는 없다. “쟤 좋은 거 뽑았다”가 다굴 이유가 된다. 다만 다음은 금지한다.

- 공개 카드 기준 최강과 최약의 1대1 자동 시뮬레이션 승률이 72:28을 넘는다.
- 최약 조합이 도망·정치·공성 중 어느 축에서도 3점 이상을 갖지 못한다.
- 어떤 조합이 3명에게 공격받아도 8초 이상 무피해로 버틴다.
- 한 능력으로 코어 체력 20% 이상을 예고 없이 제거한다.

## 2.8 위협도·현상금·정치 정보

### 위협도

화면 상단에 순위를 보여주되 정확한 수식은 숨기지 않는다.

```text
threat =
  0.30 × normalizedPowerCard
+ 0.26 × damageDealtLast30s
+ 0.18 × coreHealthPercent
+ 0.14 × heroKillParticipation
+ 0.12 × coreDamageDealt
```

- 1초마다 갱신, 5초 지수평활.
- 위협도 1위에게 왕관 표시.
- 1위가 죽어도 즉시 0이 되지 않고 12초에 걸쳐 감소한다.
- 위협도는 공격력 보너스를 주지 않는다. 오직 정보와 현상금 계산에 사용한다.

### 현상금

현재 1위 영웅 처치 관여 시 각 관여자는 자기 코어에 60 보호막을 얻는다. 골드·영구 스탯을 주지 않는다. 보상이 너무 커지면 “정치”가 아니라 강제 정답이 된다.

### 원한

각 CPU와 인간 UI는 자신에게 받은 피해를 상대별로 기록한다.

```text
grudge[target] += heroDamage * 0.006 + coreDamage * 0.012
onBetrayalPingBreak += 0.20
halfLife = 18 seconds
cap = 1.0
```

원한은 CPU 표적 선정과 결과 타임라인에 쓰인다. “왜 나만 쫓아왔지?”를 설명할 수 있어야 한다.

### 비공식 동맹

동맹 버튼은 만들지 않는다. 대신 핑만 제공한다.

- `집중`: 8초 동안 대상 슬롯을 공개 표시.
- `잠깐 휴전`: 자신이 해당 슬롯을 6초간 공격하지 않겠다는 공개 의사. 강제력 없음.
- `도와줘`: 자기 주변 위험 표시.
- `배신`: 시스템 버튼이 아니라 휴전 선언 후 공격이 발생했을 때 자동 태그.

휴전 위반은 법적 제재가 아니라 원한·결과 로그·CPU 성향에만 반영한다.

## 2.9 CPU 표적 선정

### 후보

- 시야 안 적 영웅.
- 최근 4초 내 본 자기 코어 공격자.
- 공개 위협도 1위.
- 핑으로 지정된 적.
- 체력 25% 이하의 도주 적.
- 접근 가능한 적 코어.

### 점수

```text
targetScore =
  0.28 × publicThreat
+ 0.22 × vulnerability
+ 0.17 × personalGrudge
+ 0.13 × nearbyAttackersOnTarget
+ 0.10 × coreExposure
+ 0.08 × pingSupport
+ 0.07 × abilityMatchup
- 0.14 × travelCost
- 0.12 × retaliationRisk
- 0.09 × ownCoreDanger
```

각 항목은 0~1. 현재 표적은 1.15배 관성. 새 표적 점수가 현재의 1.15배를 넘거나 현재 표적이 불가능해져야 전환한다.

### 행동 상태

```text
SCOUT → HARASS → COMMIT → FINISH_CORE
   ↘ DEFEND_HOME
   ↘ FLEE
   ↘ THIRD_PARTY
   ↘ FAKE_RETREAT
   ↘ WAIT_AND_BETRAY
```

### 배신 규칙

CPU가 휴전·공동공격 관계를 배신할 수 있는 조건:

- 공동 표적 코어 체력 24% 이하.
- 옆 동맹의 영웅 체력 38% 이하 또는 코어가 노출.
- 자기 코어 위험 35% 미만.
- `loyalty`보다 `greed + grudge`가 0.20 이상 높음.
- 마지막 배신 이후 45초 이상.

배신은 입력 지연 220~420ms 후 실행한다. 즉시 프레임 완벽 막타는 금지한다. 한 매치에서 같은 CPU가 3회 이상 배신하지 않는다.

### 인간 집중 방지

CPU가 인간이라는 이유로 가중치를 주지 않는다. 자동 테스트에서 슬롯 0을 CPU로 바꿔 500회 돌렸을 때 표적 비율이 다른 슬롯 평균의 ±8% 이내여야 한다.

## 2.10 전투 판정

### 피해 파이프라인

```text
base damage
→ 공격자 배율
→ 대상 조건 배율
→ 방어·피해감소
→ 보호막
→ HP
→ 흡혈·반사
→ 사망 예약
```

같은 틱에 서로 치명 피해를 주면 둘 다 죽는다. ID 순서 때문에 한 명만 사는 결과를 금지한다. 사망은 틱 끝에 일괄 확정한다.

### 밀치기

- 한 틱 최대 110유닛/초의 강제 속도 증가.
- 코어와 벽을 관통하지 않는다.
- 연속 밀치기 면역: 첫 강제 이동 후 0.45초 동안 추가 밀치기 55% 감소.
- 중앙에서 코어까지 한 번에 날려 보내는 콤보를 막는다.

### 연막·시야

연막 안팎을 가르는 선분이 있으면 자동 표적 고정이 끊긴다. 수동 방향 공격은 가능하다. CPU는 연막 안 실제 위치가 아니라 마지막 관측 위치와 속도 추정만 쓴다.

## 2.11 경기 정체 방지

6분부터 중앙 외곽 반경이 610에서 460까지 90초에 걸쳐 줄어든다. 바깥에 있으면 초당 최대 체력 1.5% 피해를 받지만 코어 주변 160유닛은 예외다. 이 장치는 중앙 충돌을 만들되 코어 방어 자체를 불가능하게 하지 않는다.

9분부터 모든 코어가 초당 14 고정 피해를 받는다. 이 피해로 파괴될 수 있으며, 마지막 피해자는 없음으로 기록한다. 자연 붕괴 직전 코어를 한 번이라도 공격한 플레이어에게 처치 관여를 주되, 승패는 마지막 생존만 본다.

## 2.12 렌더링·UI

### 영웅

- 아키타입은 모양으로 구분한다: 원, 사각, 삼각, 육각 등.
- 슬롯 색은 소유자를 나타내고, 모양은 전투 역할을 나타낸다.
- 능력 예고는 슬롯 색보다 능력 고유 패턴을 우선한다.

### 공격 관계선

지난 1.2초 동안 코어 또는 영웅에게 피해를 준 관계만 얇은 선으로 표시한다. 화면에 최대 8개. 모든 공격선을 계속 그리면 정치 정보가 오히려 안 읽힌다.

### 상단 패널

각 슬롯 카드에 다음만 표시한다.

- 코어 HP.
- 영웅 생존/부활 시간.
- 위협도 왕관.
- 현재 집중 핑.
- 능력 준비 여부는 본인 카드에만 정확히, 타인은 “최근 사용”만.

## 2.13 오디오

- 코어 공격 경고는 영웅 피격음보다 우선.
- 위협도 1위가 바뀌면 짧은 왕관 큐. 5초 안 재변경은 재생하지 않는다.
- 휴전 선언과 위반은 서로 다른 0.4초 큐.
- 3명 이상이 같은 대상을 1초 안에 공격하면 저음의 “다굴 시작” 큐를 대상에게만 재생한다.
- 코어 20% 이하 경고는 4초 재생 제한.

## 2.14 재미 게이트

| 지표 | 합격 범위 |
|---|---:|
| 평균 경기 시간 | 6.5~11.5분 |
| 위협도 1위 교체 | 경기당 3~9회 |
| 3인 이상 집중 공격 사건 | 경기당 2~7회 |
| CPU 배신 사건 | 경기당 0.8~3.0회 |
| 같은 슬롯 최초 탈락 비율 | 500회에서 최고 24% 이하 |
| 랜덤 조합별 우승률 | 5000회에서 5~14% (6인 기준) |
| 인간 초행자 상대 CPU 개별 교전 승률 | 58~68% |
| 인간이 이유 없는 집중이라 평가 | 10회 중 2회 이하 |
| 탈락 후 관전 지속률 | 70% 이상 |

우승률은 아키타입 단독뿐 아니라 능력·패시브 조합으로 본다. 샘플이 100회 미만인 조합은 판단하지 않는다.

## 2.15 구현 순서

### GU-M0 — 코어와 한 영웅

- 2인, 한 아키타입, 기본 공격, 코어 파괴, 부활.
- 같은 틱 상호 사망·코어 피해 테스트.

### GU-M1 — 6인 CPU

- 위협도 없이 순수 표적 선정.
- 인간 슬롯 편향이 없는지 500회 시뮬레이션.

### GU-M2 — 랜덤 조합

- 12 아키타입 → 4 능력 → 전체 16 능력 → 12 패시브 순서.
- 능력 추가마다 자동 전투 매트릭스 재실행.

### GU-M3 — 정치

- 위협도, 핑, 원한, 휴전, 배신.
- 결과 타임라인에서 모든 CPU 표적 전환 이유를 읽을 수 있어야 한다.

### GU-M4 — 정체 방지·관전·표현

- 6분 구역, 9분 코어 붕괴.
- 탈락 관전과 즉시 재시작.

## 2.16 출시 금지 조건

- CPU가 매치 시작부터 인간을 다른 슬롯보다 8% 초과해 선택한다.
- 코어가 화면 밖·이펙트 뒤에서 20% 이상 피해를 받는다.
- 최강 조합이 6인 우승률 18%를 넘는다.
- 최약 조합이 4% 미만이다.
- 배신이 이유 로그 없이 일어난다.
- 휴전 핑이 강제 동맹처럼 피해를 막는다.
- 코어 수비만으로 평균 12분을 넘긴다.
- 3명 집중 공격을 받은 플레이어가 아무 탈출 선택 없이 2초 안에 확정 사망한다.
- 탈락자가 전투 결과에 실질 피해를 줄 수 있다.

# Godot 적용 부록

## Node를 판정 단위로 쓰지 않는다

이 게임의 엔티티는 `GameWorld` 내부 Dictionary/typed data 배열이 정답이다. 회색상자 렌더는 한두 개의 `Node2D`가 일괄 그린다. 아트 단계에서 Sprite2D 풀을 붙여도 판정 상태는 유지한다.

## 스타터와 최종 구현의 차이

- 스타터: 핵심 루프·조작·CPU 상황 발생 여부를 빠르게 느끼기 위한 단일 장면.
- M1 이후: `SimulationHost`, 시스템별 스크립트, 데이터 JSON, 렌더 브리지로 분리.
- 출시 전: 독자 아트·사운드·명칭·튜토리얼·접근성·저장·플랫폼 입력 추가.
- 온라인 이전: 정답 상태를 고정소수점과 명령 리플레이로 검증한 뒤 권한 모델을 선택.

## 절대 제거하면 안 되는 재미 축

- 좋은 조합을 뽑은 플레이어가 시작 직후 공공의 적이 된다.
- 두 CPU가 한 대상을 치다가 체력이 약해진 순간 서로 배신한다.
- 뒤처진 플레이어가 현상금을 이용해 일시적으로 살아남는다.
- 선두를 잡은 직후 새로운 선두에게 공격 관계선이 몰린다.


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
| Main | Node | 로비 없이 즉시 매치 시작·재시작 |
| SimulationHost | Node | 결정적 전투 틱·명령 큐 |
| ArenaView | Node2D | 경기장·영웅·코어·투사체·범위 렌더 |
| Camera2D | Camera2D | 전체 경기장이 읽히도록 제한된 추적 |
| RelationView | Node2D | 공격 대상·임시 동맹·현상금 관계 표시 |
| Hud | CanvasLayer | 생존자·조합·위협도·코어 체력 |
| MatchDirector | Node | 정체 방지·축소 구역·결과 처리 |
| Telemetry | Node | 타깃 변경·배신·집중 공격·인과 로그 |

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
| HARASS | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| COMMIT_CORE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| DEFEND_CORE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| JOIN_DOGPILE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| BREAK_ALLIANCE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| ESCAPE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| BAIT | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| FINISH | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| SPECTATE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |

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

# 다굴게임 — Godot 코드 구현 청사진

## 1. 목표

이 문서는 “대충 비슷하게 구현”하는 문서가 아니다. 파일 위치, 상태 소유권, 한 틱의 처리 순서, CPU 입력 방식, 렌더 브리지, 데이터 검증을 고정한다.

스타터 프로젝트는 한 파일에 일부 시스템을 합쳐 실행 가능성을 높였다. 실제 M1부터는 이 청사진대로 분리한다.

## 2. 최종 씬 트리

```text
  ├─ Main (Node)  # 로비 없이 즉시 매치 시작·재시작
  ├─ SimulationHost (Node)  # 결정적 전투 틱·명령 큐
  ├─ ArenaView (Node2D)  # 경기장·영웅·코어·투사체·범위 렌더
  ├─ Camera2D (Camera2D)  # 전체 경기장이 읽히도록 제한된 추적
  ├─ RelationView (Node2D)  # 공격 대상·임시 동맹·현상금 관계 표시
  ├─ Hud (CanvasLayer)  # 생존자·조합·위협도·코어 체력
  ├─ MatchDirector (Node)  # 정체 방지·축소 구역·결과 처리
  └─ Telemetry (Node)  # 타깃 변경·배신·집중 공격·인과 로그
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
    matchdirector.gd
    herosystem.gd
    coresystem.gd
    projectilesystem.gd
    abilitysystem.gd
    threatsystem.gd
    gangcpusystem.gd
  ai/
    observation.gd
    memory.gd
    utility_brain.gd
    cpu_profile.gd
    gang_up_cpu.gd
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
| MatchDirector | 스폰·랜덤 조합·정체 방지·승패 |
| HeroSystem | 이동·조준·사망·재등장 제한 |
| CoreSystem | 코어 피해·방어·탈락 |
| ProjectileSystem | 투사체·범위·관통·충돌 |
| AbilitySystem | 주/보조 능력·상태 효과 |
| ThreatSystem | 위협도·현상금·원한·공격 관계 |
| GangCpuSystem | 표적·다굴 참여·배신·도주 |

두 시스템이 같은 필드를 직접 수정하지 않는다. 예를 들어 피해는 AbilitySystem이 즉시 HP를 빼는 것이 아니라 `DamageRequest`를 생성하고, 피해 시스템이 정렬해 적용한다.

## 5. GameWorld 계약

```gdscript
class_name GangUpGameWorld
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

- `match_tick`
- `heroes`
- `cores`
- `projectiles`
- `zones`
- `loadouts`
- `threat`
- `grudges`
- `alliances`
- `alive_slots`
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

조작: **WASD 이동 · 마우스 조준 · 좌클릭 공격 · Q 주능력 · E 보조능력 · R 재시작**

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
| loadout_revealed | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| target_changed | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| alliance_started | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| betrayal | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| hero_hit | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| core_hit | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| bounty_claimed | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| player_eliminated | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| sudden_death | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| match_won | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |

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
4. 강해 보이는 순간 모두의 적이 되고, 임시 동맹과 배신이 매초 바뀌는 난전
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

# 다굴게임 — CPU·헤드리스·재현 명세

## 1. 목표

CPU는 단순히 게임을 진행시키는 봇이 아니다. 인간 한 명이 플레이할 때도 **강해 보이는 순간 모두의 적이 되고, 임시 동맹과 배신이 매초 바뀌는 난전**라는 상황을 만들어내는 공동 연출자다.

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
| HARASS | 진입·유지·취소·완료·실패 이유를 구현 |
| COMMIT_CORE | 진입·유지·취소·완료·실패 이유를 구현 |
| DEFEND_CORE | 진입·유지·취소·완료·실패 이유를 구현 |
| JOIN_DOGPILE | 진입·유지·취소·완료·실패 이유를 구현 |
| BREAK_ALLIANCE | 진입·유지·취소·완료·실패 이유를 구현 |
| ESCAPE | 진입·유지·취소·완료·실패 이유를 구현 |
| BAIT | 진입·유지·취소·완료·실패 이유를 구현 |
| FINISH | 진입·유지·취소·완료·실패 이유를 구현 |
| SPECTATE | 진입·유지·취소·완료·실패 이유를 구현 |


## 5. 게임별 Observation

```gdscript
{
  "self": {"pos": Vector2, "hp": float, "core_hp": float, "loadout": Dictionary},
  "visible_players": [
    {"slot": int, "pos": Vector2, "hp": float, "core_hp": float,
     "threat": float, "bounty": float, "attacking": int}
  ],
  "recent_damage_sources": Array[Dictionary],
  "public_scoreboard": Array[Dictionary],
  "visible_projectiles": Array[Dictionary],
  "zone": {"center": Vector2, "radius": float}
}
```

### 표적 점수

```text
target_score =
  0.26 × leader_value
+ 0.20 × finishability
+ 0.16 × core_access
+ 0.13 × public_threat
+ 0.11 × grudge
+ 0.08 × nearby_dogpile
+ 0.06 × bounty
- 0.18 × retaliation_risk
- 0.15 × distance_cost
```

`leader_value`는 공개 점수·코어 체력·최근 피해량으로만 계산한다. 인간 슬롯 보너스는 없다.

### 다굴 참여

다른 두 명이 같은 대상을 공격 중이면 `nearby_dogpile`이 증가한다. 공격자 4명째부터 효율을 0.55로 낮춰 전원이 인간 한 명만 쫓는 것을 막는다. CPU는 타깃을 정한 뒤 최소 0.7초 유지한다.

### 배신

다음 중 둘 이상이면 동맹 파기 후보:

- 공동 타깃 코어가 20% 이하.
- 동맹자가 내 코어에서 340유닛 이내.
- 동맹자가 위협도 1위.
- 공동 타깃을 마무리하면 동맹자가 명백한 1위가 됨.
- 최근 5초 동맹자가 나에게 오발 또는 범위 피해.

배신에는 0.2~0.5초의 망설임이 있고, 공격 관계선이 먼저 짧게 깜빡여 플레이어가 원인을 읽을 수 있다.

### 인간 집중 방지

인간에게 공격자 3명 이상이 4초 지속되면 추가 CPU의 인간 target score에 0.72를 곱한다. 인간이 실제 1위거나 현상금 대상이면 이 보호는 50%만 적용한다.


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
  "game": "gang_up",
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
| 정치 발생 | 한 판당 타깃 재편 8~24회, 동맹 파기 2~8회 |
| 인간 집중 방지 | 인간이 3명 이상에게 동시에 4초 넘게 집중되는 시간 12% 미만 |
| 선두 압박 | 위협도 1위가 8초 안에 평균 1.8명 이상에게 표적 |
| 무기 격차 | 최상 조합 승률 22~38%, 최하 조합 승률 7~15% |
| 정체 | 무피해 12초 구간 판당 1회 이하 |

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

# 다굴게임 — 레벨·데이터·밸런스 계약

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


## 4. 경기장 데이터

```json
{
  "id": "arena_hex_6",
  "size": [1600, 900],
  "center": [800, 450],
  "spawn_ring_radius": 330,
  "core_ring_radius": 610,
  "spawn_rotation_seeded": true,
  "obstacles": [],
  "cover_points": [],
  "sudden_death": {"start_sec": 210, "shrink_sec": 70, "final_radius": 190}
}
```

절차 생성 검증:

- 모든 코어에서 중앙까지 경로 비용 편차 8% 이하.
- 초기 4초에 다른 코어를 직접 사격할 수 없음.
- 코어 뒤 숨은 영웅이 완전 무적이 되지 않음.
- 스폰 회전으로 슬롯별 장기 승률 편차 3%p 이하.
- 정체 축소 구역이 코어를 한 번에 제거하지 않음.

조합 데이터는 `archetypes.json`, `abilities.json`, `passives.json`으로 분리하고 ID 참조만 한다.


## 5. 시스템별 데이터 책임

| 데이터 소비 시스템 | 검증 책임 |
|---|---|
| MatchDirector | 스폰·랜덤 조합·정체 방지·승패 |
| HeroSystem | 이동·조준·사망·재등장 제한 |
| CoreSystem | 코어 피해·방어·탈락 |
| ProjectileSystem | 투사체·범위·관통·충돌 |
| AbilitySystem | 주/보조 능력·상태 효과 |
| ThreatSystem | 위협도·현상금·원한·공격 관계 |
| GangCpuSystem | 표적·다굴 참여·배신·도주 |

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

# 다굴게임 — 플레이테스트·텔레메트리 명세

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
| 정치 발생 | 한 판당 타깃 재편 8~24회, 동맹 파기 2~8회 |
| 인간 집중 방지 | 인간이 3명 이상에게 동시에 4초 넘게 집중되는 시간 12% 미만 |
| 선두 압박 | 위협도 1위가 8초 안에 평균 1.8명 이상에게 표적 |
| 무기 격차 | 최상 조합 승률 22~38%, 최하 조합 승률 7~15% |
| 정체 | 무피해 12초 구간 판당 1회 이하 |

이 범위는 초기 가설이다. 사람 테스트 30판 뒤 중앙값과 상·하위 10%를 다시 고정한다.

## 5. 사건 이벤트

필수 원시 이벤트:

- `loadout_revealed`
- `target_changed`
- `alliance_started`
- `betrayal`
- `hero_hit`
- `core_hit`
- `bounty_claimed`
- `player_eliminated`
- `sudden_death`
- `match_won`

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

# 다굴게임 — 실제 구현 순서

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
| GU-M0 | 인간 1명, 코어 2개, 이동·사격·코어 파괴 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| GU-M1 | 6인 CPU, 타깃 선정, 인간 집중 방지 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| GU-M2 | 아키타입·능력·패시브 랜덤 조합 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| GU-M3 | 위협도·현상금·원한·임시 동맹·배신 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| GU-M4 | 정체 방지·관전·인과 로그·밸런스 시뮬레이션 | 해당 마일스톤 P0 100%·P1 90% 이상 |

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

- **MatchDirector**: 스폰·랜덤 조합·정체 방지·승패
- **HeroSystem**: 이동·조준·사망·재등장 제한
- **CoreSystem**: 코어 피해·방어·탈락
- **ProjectileSystem**: 투사체·범위·관통·충돌
- **AbilitySystem**: 주/보조 능력·상태 효과
- **ThreatSystem**: 위협도·현상금·원한·공격 관계
- **GangCpuSystem**: 표적·다굴 참여·배신·도주

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

# 다굴게임 — 체크리스트 운용·완료 판정

## 1. 체크리스트

이 패키지에는 공통 Godot 항목과 다굴게임 전용 항목을 합친 **4,027개 체크리스트**가 들어간다.

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

- 6인 개인전, 각자 코어, 랜덤 조합, 위협도·현상금·CPU 정치·배신이 작동하는 회색상자
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

# 다굴게임 — PixiJS 명세를 Godot로 옮기는 대응표

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

다굴게임의 핵심 재미는 플레이어 간 연쇄 원인이므로 같은 입력이 다른 원인을 만들면 디버깅과 CPU 검증이 불가능해진다.

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
