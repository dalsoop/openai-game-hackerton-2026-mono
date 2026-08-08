

---

<!-- 00_READ_FIRST.md -->

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


---

<!-- 01_GAMEPLAY_SPEC.md -->

# 지원하며 버티기 — 게임플레이·수치 명세

> 기준 엔진은 Godot 4.7.1이지만, 이 문서의 구조체·알고리즘 블록은 언어 독립적 의사코드다. 실제 GDScript 파일·함수·씬 계약은 `03_CODE_BLUEPRINT.md`를 따른다.

## 5.1 재미 계약

이 게임의 본체는 적을 오래 막는 것이 아니라 **3명의 전선 병사와 3명의 보급 담당자가 서로 없이는 버틸 수 없고, 한 사람의 작은 지연이 다른 라인의 지원 이동과 본부 위기로 번지는 연쇄**다. 병사는 눈앞의 전투가 급하고, 보급은 전체 전선을 봐야 한다. 서로 다른 화면·판단 주기가 같은 사건으로 연결되어야 한다.

반드시 생겨야 하는 장면:

1. 소총병이 탄약 요청을 늦게 보내고, 보급 상자가 도착하기 1초 전에 중앙 방벽이 무너진다.
2. 의무관이 북쪽 부활을 선택한 사이 남쪽 병사가 쓰러져 공병이 임시 포탑으로 시간을 번다.
3. 선봉병이 너무 전진해 배송 경로가 길어지고 상자가 적에게 파괴된다.
4. 한 전선이 무너지자 인접 병사가 이동하고, 비어 버린 원래 라인에 두 번째 위기가 온다.
5. 잘 계산한 긴급투하 하나가 전멸 직전 20초를 벌어 팀이 역전한다.
6. 결과 화면에서 “누구 때문에 졌다”가 감정적 추측이 아니라 사건 사슬로 설명된다.

최악의 실패는 `보급 역할이 메뉴만 누르는 직업`, `병사가 보급 없이도 혼자 다 함`, `보급 CPU가 항상 완벽해 인간 선택이 무의미`, `한 라인 붕괴가 즉시 게임오버`, `실패 원인이 화면 밖에서 발생`이다.

## 5.2 원본 확인과 고정 규칙

### [원본 확인]

- 총 6명의 역할이 3명의 보급 역할과 3명의 전선 병사로 나뉜다.
- 몰려오는 적을 막으며 진행하는 생컨형 컴까기다.
- 최종 목표는 적 Hive 파괴다.
- 여러 전투 페이즈와 다단 보스가 존재한다.

### [프로토타입 고정]

- 정확히 6슬롯. 인간은 하나를 고르고 나머지 5개를 CPU가 채운다.
- 전선 병사 3명은 북·중앙·남 라인의 기본 담당자다.
- 보급 역할 3명은 후방 기지에서 자원을 생산하고 실제 배송 엔티티를 보낸다.
- 3개 필드 페이즈 + Hive 2페이즈. 38~55분.
- 병사가 전투불능이 되어도 10초 동안 구조 가능. 병사 3명이 동시에 10초 이상 전투불능이면 패배.
- 보급 역할은 사망 후 8초 부활. 전 보급 사망은 즉시 패배가 아니다.
- 본부 체력 12,000이 0이면 패배. Hive 핵 파괴 시 승리.

## 5.3 역할 선택과 시작

### 시작 화면

여섯 역할을 `전선 3 / 보급 3`으로 나누어 보여준다. 각 카드에는 다음을 표시한다.

- 분당 예상 행동 빈도.
- 주시해야 할 자원.
- 실패 시 팀에 미치는 영향.
- 추천 난이도.

인간이 선택하지 않은 역할은 CPU가 채운다. 첫 플레이 추천은 소총병 또는 보급관이다. 플레이 중 자유 전환은 금지한다. 페이즈 사이 휴식 20초에만 인간과 CPU 역할을 한 번 교환할 수 있으며, 진행 중 자원·쿨다운은 역할에 남는다.

## 5.4 맵

- 월드 3000×1800.
- X=300 후방 본부, X=900 보급 기지, X=1600 전선 표식, X=2600 적 산란장/Hive.
- Y=360 북, 900 중앙, 1440 남 라인.
- 라인 사이 연결 통로는 X=1200과 X=2050 두 곳.
- 병사가 인접 라인으로 이동하는 데 5~7초.
- 보급 배송은 기지에서 전선까지 5~9초.
- 적이 배송 경로를 공격할 수 있는 교차 지점 2개. 배송이 항상 안전하면 보급은 단순 쿨다운 버튼이 된다.

### 시야

병사는 자기 주변과 인접 라인의 일부를 본다. 보급 역할은 전장 전체 축약 지도를 보되 적의 정확한 체력·개별 위치는 0.5초 간격으로 갱신된다. 보급이 완전한 RTS 감독자처럼 모든 프레임을 읽지 않게 한다.

## 5.5 역할 수치

| 구분 | 역할 | HP/속도 | 기본 행동 | 고유 자원 | 스킬 |
| --- | --- | --- | --- | --- | --- |
| soldier | 선봉병 | 1650 / 235 | 근거리 방패 타격 | 방패 내구도 | 도발, 방패돌진, 최후방벽 |
| soldier | 소총병 | 980 / 270 | 탄약 소비 원거리 사격 | 탄약 | 점사, 수류탄, 제압사격 |
| soldier | 제압병 | 1120 / 250 | 광역 둔화탄 | 중화기 열 | 빙결탄, 지뢰, 포격표식 |
| support | 보급관 | 820 / 260 | 보급품 생산·배송 | 보급점수 | 탄약상자, 긴급투하, 생산가속 |
| support | 의무관 | 780 / 275 | 치료드론 운용 | 의료물자 | 치료팩, 전투부활, 사기주입 |
| support | 공병 | 900 / 250 | 바리케이드·포탑·수송로 수리 | 부품 | 바리케이드, 수리드론, 임시포탑 |


### 스킬 고정값

| 역할 | 스킬 | 쿨다운 | 효과 |
| --- | --- | --- | --- |
| 선봉병 | 도발 / KeyQ | 9s | 반경 260 적을 3초 고정, 방패 내구 8 회복. |
| 선봉병 | 방패돌진 / KeyW | 11s | 320유닛 돌진, 경로 적 밀침·95 피해. |
| 선봉병 | 최후방벽 / KeyE | 30s | 6초 받는 피해 50%, 뒤 아군 피해 25% 감소. |
| 소총병 | 점사 / KeyQ | 5s | 탄약 6, 0.45초간 3발 각 82 피해. |
| 소총병 | 수류탄 / KeyW | 10s | 탄약 8, 반경 150에 165 피해. |
| 소총병 | 제압사격 / KeyE | 20s | 탄약 20, 5초 원뿔 지속사격·적 속도 35% 감소. |
| 제압병 | 빙결탄 / KeyQ | 7s | 열 +18, 반경 125 적 2초 55% 둔화. |
| 제압병 | 지뢰 / KeyW | 11s | 열 +12, 30초 지뢰, 반경 130에 150 피해. |
| 제압병 | 포격표식 / KeyE | 24s | 열 +35, 1.5초 후 반경 210에 420 피해. |
| 보급관 | 탄약 긴급투하 / KeyQ | 18s | 비용 22, 1.2초 후 지정 전선에 탄약 28. 물리 배송 없음. |
| 보급관 | 우선 수송로 / KeyW | 20s | 8초 해당 경로 배송 속도 45%, 받는 피해 25% 감소. |
| 보급관 | 생산가속 / KeyE | 32s | 10초 생산시간 40% 단축, 비용 15% 증가. |
| 의무관 | 치료팩 / KeyQ | 8s | 비용 18, 사거리 360 아군 체력 180 즉시 회복. |
| 의무관 | 전투부활 / KeyW | 45s | 비용 45, 사거리 140에서 1.4초 채널 후 병사 부활. |
| 의무관 | 사기주입 / KeyE | 25s | 8초 대상 라인 병사 이동·공격 15%, 받는 회복 20% 증가. |
| 공병 | 바리케이드 / KeyQ | 12s | 비용 20, 체력 760 바리케이드. 라인당 최대 3. |
| 공병 | 수리드론 / KeyW | 16s | 비용 18, 8초간 초당 75 구조물 수리. |
| 공병 | 임시포탑 / KeyE | 28s | 비용 42, 35초 포탑, 초당 95 피해. |


## 5.6 병사 조작과 자원

### 공통

- WASD 이동, 마우스 조준, 좌클릭 기본 공격, Q/W/E 스킬.
- 반지름 26~31.
- 전선 표식 600유닛 바깥으로 전진하면 배송 ETA가 거리만큼 증가하고, 해당 병사에게 `보급선 연장` 경고.
- 병사끼리 소프트 충돌. 적·바리케이드는 단단한 충돌.
- 전투불능 시 제자리에서 쓰러져 10초 구조 창. 기어가기는 불가.

### 선봉병

- 방패 내구도 100.
- 정면 130도 피해의 55%를 내구도가 대신 받는다.
- 내구 0이면 3초 방패 파손, 받는 피해 15% 증가.
- 전투 밖 5초 후 초당 4 회복. 탄약 상자로도 일부 회복.
- 기본 공격 68 피해, 0.65초, 사거리 100.

### 소총병

- 탄약 최대 100.
- 기본 공격 1발, 62 피해, 0.24초. 탄약 1.
- 탄약 0이면 1.3초마다 18 피해의 비상 권총만 사용.
- 탄약 25/10에서 자동 핑. 인간은 핑 자동전송을 끌 수 있지만 HUD 경고는 유지.
- 탄약 상자 60 회복.

### 제압병

- 중화기 열 0~100.
- 기본 공격 48 피해, 반경 60, 0.48초, 열 +4.
- 열 75 이상 공격속도 20% 감소, 100에서 3초 과열 정지.
- 공격하지 않으면 초당 14 냉각.
- 탄약 상자는 열 -45.

## 5.7 보급 역할의 직접 플레이

보급 역할은 전체 지도를 보며 버튼만 누르지 않는다. 후방 기지 안에서 캐릭터를 직접 움직여 다음 일을 한다.

1. 생산기 선택과 큐 관리.
2. 완성 상자를 목적지 패드로 운반하거나 자동 운반 드론에 싣기.
3. 적 침투병·공중 습격으로부터 생산기를 방어.
4. 배송 경로를 선택하고 우선 수송로를 활성화.
5. 필요하면 전선 가까이 직접 가서 즉시 스킬을 사용. 전진할수록 사망 위험과 생산 공백이 커진다.

### 생산 UI

- 각 보급 역할 최대 큐 3개.
- 생산 시작 시 비용 30% 예약, 완료 시 70% 지불. 자원이 부족하면 완료 직전 멈추지 않고 시작 자체를 막는다.
- 큐 항목은 드래그로 순서 변경. 진행 중 1번은 변경 불가.
- 취소 환불: 시작 30% 이전 85%, 이후 50%.
- 숫자·색 외에 상자 모양으로 종류를 구분한다.

### 보급 자원

- 보급관 초당 5.0, 의무관 4.8, 공병 4.6.
- 자원 최대 160. 가득 차면 “낭비” 경고를 주되 자동 소비하지 않는다.
- 페이즈 종료 시 최대 80만 이월. 무한 비축으로 후반을 무력화하지 않는다.

## 5.8 배송

| 상자 | 생산자 | 비용/생산 | 이동/HP | 효과 |
| --- | --- | --- | --- | --- |
| 탄약 상자 | quartermaster | 28 / 3.0s | 240 / 180 | 소총병 탄약 60, 제압병 중화기 열 -45, 선봉병 방패 내구 20. |
| 의료 상자 | medic | 30 / 3.4s | 250 / 160 | 대상 병사 체력 420 회복, 8초 재생 160. |
| 수리 부품 | engineer_support | 26 / 3.2s | 220 / 220 | 바리케이드/포탑/수송차량 체력 520 회복. |
| 혼합 긴급 상자 | any_support | 55 / 5.5s | 270 / 140 | 체력 220, 탄약 30, 방패 12, 열 -20. 효율은 낮지만 어떤 전선도 살린다. |
| 증원 분대 | quartermaster | 70 / 7.5s | 190 / 420 | 해당 라인에 35초 민병대 4기. |
| 구조 드론 | medic | 65 / 4.5s | 300 / 120 | 전투불능 병사 부활 채널 2.2초. 피격 시 중단. |
| 포탑 키트 | engineer_support | 62 / 6.0s | 190 / 260 | 전선에 45초 임시 포탑 설치. |


### 배송 상태 머신

```text
type ShipmentState =
  | 'building'
  | 'waiting_dispatch'
  | 'loading'
  | 'in_transit'
  | 'under_attack'
  | 'delivered'
  | 'destroyed'
  | 'expired';
```

### 경로

- 각 라인에 `안전 경로`와 `빠른 경로` 두 개.
- 안전 경로는 18% 길고 엄폐·수리 지점이 있다.
- 빠른 경로는 적 교차 지점을 지나며 18% 빠르다.
- 우선 수송로 스킬은 선택 경로의 속도·방어만 올린다.
- 배송 대상 병사가 라인을 바꾸면 상자는 기존 전선 표식으로 간다. 인간의 현재 좌표를 추적해 맵 전체를 쫓지 않는다.

### 인수

- 상자가 전선 표식 90유닛 안에 들어가면 자동 전달.
- 병사가 180유닛 바깥으로 전진했으면 표식에 20초 동안 보관된다.
- 병사가 돌아오거나 E로 원격 회수 드론을 부르면 적용. 원격 회수 2.2초, 공격받으면 취소.
- 같은 종류가 넘치면 초과분은 30%만 예비 저장. 무한 중첩 금지.

### 파괴

- 적이 상자를 공격할 수 있다.
- 상자 체력 0이면 파괴되고 35% 자원이 잔해로 남는다. 공병이 2초 채널로 회수.
- 배송 파괴는 병사와 보급자 모두에게 경고하며 공격자 위치를 2초 공개한다.
- 화면 밖에서 예고 없이 파괴되지 않도록 첫 피격 시 1.0초 보호막 30을 주고 경고한다. 같은 배송당 한 번.

## 5.9 핑과 요청

### 자동 요청 임계값

- 소총병 탄약 25: 노란 요청, 10: 빨간 요청.
- 선봉병 방패 30, 체력 45%.
- 제압병 열 75, 체력 45%.
- 전선 표식 체력 35%.
- 병사 전투불능.

자동 요청은 연속 8초에 한 번. 인간이 수동 핑하면 4초 동안 자동 핑을 억제한다.

### 수동 핑 휠

`V` 홀드:

- 탄약, 치료, 수리, 증원.
- 여기 사수, 후퇴, 다른 라인 지원.
- 배송 위험, 보스 준비.

핑에는 요청자, 위치, 현재 자원 값, 예상 필요 시간이 포함된다. “힐 줘”만 보내고 실제 체력을 숨기지 않는다.

### CPU 핑 해석

CPU는 핑을 강제 명령이 아니라 유틸리티 +0.18로 처리한다. 같은 사람이 5초 안에 3회 스팸하면 추가 핑 가중치는 0. CPU가 인간에게 무조건 복종해 최적 지원을 버리지 않는다.

## 5.10 페이즈

| 페이즈 | 이름 | 목표 시간 | 목표 | 실패 |
| --- | --- | --- | --- | --- |
| 1 | 외곽 참호 | 480s | 3개 전선 표식 중 2개 이상 유지 | 모든 표식 상실 후 30초 내 복구 실패 |
| 2 | 보급로 개통 | 540s | 수송차량을 전진기지까지 호위 | 수송차량 파괴 후 재건 자원 부족 |
| 3 | 산란장 역공 | 600s | 3개 산란장을 파괴하고 적 Hive 진입로 개방 | 본부 체력 0 또는 전 병사 동시 전투불능 10초 |
| 4 | Hive 외피 | 360s | 보호막 발생기 3개 파괴 | 본부 체력 0 |
| 5 | Hive 핵 | 420s | 폭주 핵 파괴 | 전멸기 3회 누적 또는 본부 체력 0 |


### 1페이즈 — 외곽 참호

- 3개 전선 표식을 지킨다.
- 한 표식이 파괴되면 해당 라인의 적이 본부 방향으로 이동하고 인접 라인 스폰이 15% 증가.
- 파괴된 표식은 공병 부품 60과 6초 채널로 재건 가능.
- 3개 중 2개 이상을 8분 끝까지 유지하면 통과. 하나만 남아도 즉시 실패하지 않는다.

### 2페이즈 — 보급로 개통

- 중앙 수송차량 체력 5,500.
- 병사는 전방을 정리하고, 보급 역할은 차량 연료·수리·호위 드론을 공급.
- 차량은 3개 체크포인트에서 멈춘다. 멈출 때 북·남 습격.
- 파괴되면 90초 안에 부품 140으로 한 번 재건 가능. 즉시 20분 삭제 금지.

### 3페이즈 — 산란장 역공

- 각 라인 끝 산란장 체력 9,000.
- 산란장 하나를 파괴하면 해당 라인 적 스폰이 줄지만 다른 두 라인이 12% 강화.
- 병사 3명이 한 산란장에만 모이면 비어 있는 라인에 침투병이 본부로 간다.
- 보급은 전진 창고를 설치해 배송 시간을 줄일 수 있지만, 파괴되면 저장 자원 50% 손실.

### 4페이즈 — Hive 외피

- 보호막 발생기 3개를 각 라인에서 파괴.
- 발생기가 살아 있는 동안 Hive 본체 무적.
- 40초마다 한 라인에 산성 폭격. 공병 바리케이드와 병사 이동으로 대응.
- 발생기 파괴 순서는 자유. 마지막 발생기에서 모든 지원을 몰아주는 장면을 만든다.

### 5페이즈 — Hive 핵

- 핵 체력 180,000.
- 1페이즈 패턴: 촉수·소환·배송 경로 산성 웅덩이.
- 체력 55%에서 폭주: 32초마다 `핵 맥동`, 모든 라인에 2.6초 후 큰 피해. 세 병사가 각 라인 차단 장치에 동시에 서거나 공병 비상 장치 1회로 막는다.
- 지원 역할은 핵 직접 공격보다 탄약·치료·수리·장치 활성화에 집중.
- 전멸기 3회 누적 시 본부가 붕괴해 패배.

## 5.11 연쇄 붕괴 시스템

한 라인 실패가 즉시 게임오버가 아니라 다른 문제를 만든다.

```text
탄약 고갈
  → 소총병 DPS 감소
  → 전선 표식이 더 오래 공격받음
  → 선봉병이 중앙 지원 이동
  → 북쪽 방패 담당 공백
  → 북쪽 적이 배송로 진입
  → 의료 상자 파괴
  → 제압병 회복 실패
  → 본부 압박
```

각 이벤트는 `causeEventId`를 가진다. 결과 화면은 손실 이벤트에서 최대 6단계 역추적해 주요 원인 3개를 보여준다.

### 인과 이벤트 예

```text
interface CausalEvent {
  id: number;
  tick: number;
  type: string;
  actorId?: EntityId;
  targetId?: EntityId;
  causeEventId?: number;
  magnitude: number;
  tags: string[];
}
```

“탄약 상자가 1.1초 늦었다”는 배송 ETA와 실제 전선 붕괴 사이의 수치로 계산한다. 단순히 마지막 피격자를 범인으로 표시하지 않는다.

## 5.12 CPU 병사

### 공통 행동

```text
HOLD_LINE
KITE_BACK
PUSH_FORWARD
CROSS_SUPPORT
PROTECT_SHIPMENT
RECOVER_RESOURCE
REVIVE_ALLY
OBJECTIVE_BURST
```

### 라인 이탈 판단

```text
crossSupport =
  targetLaneCollapseRisk
× travelFeasibility
× ownLaneSafetyAfterLeaving
× roleFit
× requestWeight
```

자기 라인 예상 붕괴시간이 12초 미만이면 이동하지 않는다. 단, 본부 위험이 0.8 이상이면 모든 라인 규칙보다 본부를 우선한다.

### 보급 사용

- 상자가 곧 도착하면 자원 5% 이하까지 버틸 수 있다.
- ETA가 4초 이상이고 자원 15% 이하이면 후퇴.
- CPU는 보급 상자 위치를 공개 지도 갱신 0.5초 간격으로만 본다.
- 상자를 받으려고 위험한 적 무리 안으로 역주행하지 않는다.

## 5.13 CPU 보급 역할

### 수요 예측

각 라인에 12초 예측을 만든다.

```text
needAmmo = projectedConsumption - currentAmmo - inboundAmmo
needHeal = projectedDamage - currentEffectiveHp - inboundHeal
needRepair = projectedStructureDamage - currentStructureHp - inboundRepair
```

예측은 최근 6초 소비·피해의 지수평활이며, 다음 스폰 종류의 공개 예고를 반영한다. 미래 RNG나 적의 정확한 공격 대상을 읽지 않는다.

### 생산 점수

```text
shipmentScore =
  0.32 × urgency
+ 0.20 × preventCollapse
+ 0.16 × roleEfficiency
+ 0.12 × deliverySurvival
+ 0.10 × requestWeight
+ 0.10 × stockBalance
- 0.16 × opportunityCost
```

CPU는 점수가 높은 3개까지 큐에 넣되 자원 20을 비상 예비로 남긴다. `risk > 0.75`인 CPU는 예비를 8까지 줄일 수 있다.

### 의도된 지연과 실수

- 동시 두 라인 빨간 요청 시 8~15% 확률로 더 가까운 라인을 먼저 처리해 다른 라인이 늦어진다.
- 생산 큐를 0.4초마다 완벽히 재정렬하지 않는다. 진행 25% 이상 항목은 유지.
- 배송 경로가 공격받으면 230ms 후 재경로 판단.
- 한 판에 같은 종류 배송을 잘못 보낸 사건은 CPU당 최대 1회. 오류는 수요 예측 오차로만 발생하며 무작위 파괴 행동은 금지.

## 5.14 역할별 화면

### 병사 HUD

- 체력, 고유 자원, 현재 라인 압력.
- 들어오는 배송 종류·ETA·경로 위험.
- 다른 라인 위험은 3단계만: 안정/주의/붕괴 임박.
- 보급 큐 전체를 보여주지 않는다. 병사가 모든 보급 운영을 감시하는 게임이 되지 않게 한다.

### 보급 HUD

- 3라인 수요 카드: 현재량, 12초 예상, 배송 중 수량.
- 생산 큐 3칸.
- 경로 지도와 위험도.
- 전선 카메라 미리보기는 한 번에 하나, 320×180. 전체 3개 영상을 동시에 렌더링하지 않는다.
- 병사의 정확한 스킬 쿨다운은 보이지 않고 `교전 가능/회복 중`만.

## 5.15 렌더링과 성능

- 3개 라인은 동일한 지형 모듈을 Y만 바꿔 재사용한다.
- 배송 엔티티는 최대 18개. 별도 경로 그래프 사용.
- 일반 적 최대 650, 투사체 500, 구조물 80.
- 화면 밖 라인은 20Hz 애니메이션, 시뮬레이션은 60Hz 위치 적분.
- 보급 전술 지도는 실제 월드를 두 번째로 렌더하지 않고 스냅샷 기반 아이콘만 그린다.
- 배송 ETA는 경로 길이/속도와 현재 정체를 계산하며, 단순 직선거리로 속이지 않는다.

## 5.16 오디오

병사와 보급 역할의 오디오 우선순위가 다르다.

### 병사

1. 자기 체력·자원 위험.
2. 도착 배송.
3. 전선 표식 위험.
4. 인접 라인 요청.

### 보급

1. 배송 공격·파괴.
2. 빨간 자원 요청.
3. 생산 완료·큐 정지.
4. 적 침투.

같은 사건을 두 역할에서 다른 소리로 표현하되 이벤트 ID는 같다. 결과 리플레이에서 양쪽 관점을 재생할 수 있다.

## 5.17 재미 게이트

| 지표 | 합격 범위 |
|---|---:|
| 세션 | 38~55분 |
| 보급 역할 유효 결정 간격 | 평균 3~7초 |
| 병사 자원 0 상태 | 세션의 3~12% |
| 배송으로 붕괴 방지 | 세션당 3~9회 |
| 라인 간 병사 구조 이동 | 세션당 2~6회 |
| 배송 파괴 | 세션당 1~5회 |
| 한 라인 붕괴 후 복구 | 40~75% |
| CPU 보급 지연이 만든 위기 | 세션당 0.5~2회 |
| 이유 불명 패배 신고 | 10회 중 1회 이하 |
| 인간이 보급 역할 선택 후 지루함 5점 | 2 이하 |
| 첫 5판 승률 | 35~60% |

보급 역할 결정 간격이 2초 미만이면 정신없고, 9초 이상이면 지루하다. 병사 자원 0이 전혀 없으면 보급 의존이 약하고, 20%를 넘으면 보급이 벌주는 시스템이 된다.

## 5.18 구현 순서

### SH-M0 — 한 라인·두 역할

- 소총병 + 보급관.
- 탄약 소비, 상자 생산, 물리 배송, 전선 유지.
- 10분 회색 상자로 보급 의존과 행동 빈도 검증.

### SH-M1 — 세 라인·6 CPU

- 역할은 소총병 3 + 보급관 3으로 단순화.
- 라인 간 이동과 배송 경로, 붕괴 전염.

### SH-M2 — 6개 역할

선봉병 → 제압병 → 의무관 → 공병 순서. 각 역할 추가 시 다른 역할의 필요성이 실제로 생기는지 수치로 확인한다.

### SH-M3 — 3개 필드 페이즈

외곽 참호, 수송차량, 산란장. 한 페이즈를 통과하기 전 다음 페이즈를 만들지 않는다.

### SH-M4 — Hive 2페이즈와 인과 로그

- 보스 패턴.
- 전멸기.
- 원인 이벤트 그래프와 결과 설명.

### SH-M5 — 역할 교환·관전·표현

페이즈 사이 한 번 교환, 튜토리얼, 오디오, 더미 아트 교체.

## 5.19 출시 금지 조건

- 보급 담당자가 10초 이상 의미 있는 입력 없이 기다린다.
- 보급 없이 병사가 90초 이상 정상 화력을 유지한다.
- 배송 ETA 오차가 평상시 0.8초, 혼잡 시 1.5초를 넘는다.
- 상자가 첫 피격 경고 없이 화면 밖에서 파괴된다.
- 한 라인 붕괴가 5초 안에 자동 패배로 이어진다.
- CPU 보급이 인간보다 20% 이상 효율적이라 인간이 맡으면 항상 약해진다.
- CPU가 모든 요청을 완벽히 충족해 위기가 사라진다.
- 결과 화면이 마지막 피격자만 원인으로 지목한다.
- 병사가 다른 라인 지원 후 원래 라인으로 돌아갈 길을 찾지 못한다.
- 보급 전술 지도를 실제 월드 3회 렌더링해 프레임이 떨어진다.
- 보스 전멸기 차단이 특정 한 역할의 단일 입력에만 의존하고 대체 수단이 없다.

# Godot 적용 부록

## Node를 판정 단위로 쓰지 않는다

이 게임의 엔티티는 `GameWorld` 내부 Dictionary/typed data 배열이 정답이다. 회색상자 렌더는 한두 개의 `Node2D`가 일괄 그린다. 아트 단계에서 Sprite2D 풀을 붙여도 판정 상태는 유지한다.

## 스타터와 최종 구현의 차이

- 스타터: 핵심 루프·조작·CPU 상황 발생 여부를 빠르게 느끼기 위한 단일 장면.
- M1 이후: `SimulationHost`, 시스템별 스크립트, 데이터 JSON, 렌더 브리지로 분리.
- 출시 전: 독자 아트·사운드·명칭·튜토리얼·접근성·저장·플랫폼 입력 추가.
- 온라인 이전: 정답 상태를 고정소수점과 명령 리플레이로 검증한 뒤 권한 모델을 선택.

## 절대 제거하면 안 되는 재미 축

- 한 라인의 탄약 요청이 늦어져 다른 라인의 지원 병력이 이동하고 연쇄 공백이 생긴다.
- 보급품이 도착 직전 파괴되어 전선이 무너지지만 원인이 명확하게 남는다.
- CPU 보급 담당이 완벽하지 않은 예측으로 틀린 물자를 보내 상황이 꼬인다.
- 생존 국면이 끝나면 전원이 Hive 역공으로 전환해 역할의 의미가 바뀐다.


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
| Main | Node | 역할 선택·페이즈 수명 |
| SimulationHost | Node | 전투·수요·생산·배송·인과 그래프 |
| BattlefieldView | Node2D | 3라인·기지·Hive·유닛·배송 렌더 |
| Camera2D | Camera2D | 병사 추적 또는 보급 지휘 시 전체 뷰 |
| RequestOverlay | Node2D | 핑·수요·ETA·라인 압력 |
| Hud | CanvasLayer | 역할별 HUD·생산 큐·탄약·체력 |
| PhaseDirector | Node | 5페이즈·목표 전환·Hive 체력 |
| Telemetry | Node | 요청→생산→배송→손실 인과 그래프 |

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
| HOLD_POSITION | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| PUSH | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| RETREAT | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| REQUEST_SUPPLY | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| ROTATE_SUPPORT | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| PRODUCE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| DISPATCH | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| ESCORT_DELIVERY | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |
| ASSAULT_HIVE | 행동 진입 조건·유지 조건·취소 조건·실패 이유를 별도 함수로 둔다. |

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

# 지원하며 버티기 — Godot 코드 구현 청사진

## 1. 목표

이 문서는 “대충 비슷하게 구현”하는 문서가 아니다. 파일 위치, 상태 소유권, 한 틱의 처리 순서, CPU 입력 방식, 렌더 브리지, 데이터 검증을 고정한다.

스타터 프로젝트는 한 파일에 일부 시스템을 합쳐 실행 가능성을 높였다. 실제 M1부터는 이 청사진대로 분리한다.

## 2. 최종 씬 트리

```text
  ├─ Main (Node)  # 역할 선택·페이즈 수명
  ├─ SimulationHost (Node)  # 전투·수요·생산·배송·인과 그래프
  ├─ BattlefieldView (Node2D)  # 3라인·기지·Hive·유닛·배송 렌더
  ├─ Camera2D (Camera2D)  # 병사 추적 또는 보급 지휘 시 전체 뷰
  ├─ RequestOverlay (Node2D)  # 핑·수요·ETA·라인 압력
  ├─ Hud (CanvasLayer)  # 역할별 HUD·생산 큐·탄약·체력
  ├─ PhaseDirector (Node)  # 5페이즈·목표 전환·Hive 체력
  └─ Telemetry (Node)  # 요청→생산→배송→손실 인과 그래프
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
    phasedirector.gd
    soldiersystem.gd
    supplysystem.gd
    deliverysystem.gd
    requestsystem.gd
    pressuresystem.gd
    supportcpusystem.gd
  ai/
    observation.gd
    memory.gd
    utility_brain.gd
    cpu_profile.gd
    support_and_hold_cpu.gd
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
| PhaseDirector | 5페이즈·방어→역공·Hive |
| SoldierSystem | 세 병사 역할·탄약·체력·스킬 |
| SupplySystem | 세 보급 역할·생산 큐·자원 |
| DeliverySystem | 경로·ETA·인수·파괴 |
| RequestSystem | 자동/수동 요청·핑·우선순위 |
| PressureSystem | 3라인 압력·지원 이동·연쇄 붕괴 |
| SupportCpuSystem | 수요 예측·생산·배송·의도적 오판 |

두 시스템이 같은 필드를 직접 수정하지 않는다. 예를 들어 피해는 AbilitySystem이 즉시 HP를 빼는 것이 아니라 `DamageRequest`를 생성하고, 피해 시스템이 정렬해 적용한다.

## 5. GameWorld 계약

```gdscript
class_name SupportandHoldGameWorld
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

- `phase`
- `phase_tick`
- `actors`
- `enemies`
- `lane_pressure`
- `supply_stock`
- `production_queues`
- `deliveries`
- `requests`
- `base_hp`
- `hive_hp`
- `cause_graph`
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

조작: **1~6 조작 전환 · WASD 이동 · 좌클릭 사격/보급 지정 · Q 수류탄/품목 변경 · F 탄약요청 · E 치료요청 · Space 장벽요청 · R 재시작**

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
| supply_requested | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| production_started | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| delivery_dispatched | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| delivery_damaged | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| delivery_received | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| ammo_empty | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| actor_rotated | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| lane_breached | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| phase_changed | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| hive_exposed | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| hive_destroyed | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |

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
4. 전선과 보급이 서로 의존하며 한 사람의 작은 지연이 다른 라인까지 번지는 역할 협동
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

# 지원하며 버티기 — CPU·헤드리스·재현 명세

## 1. 목표

CPU는 단순히 게임을 진행시키는 봇이 아니다. 인간 한 명이 플레이할 때도 **전선과 보급이 서로 의존하며 한 사람의 작은 지연이 다른 라인까지 번지는 역할 협동**라는 상황을 만들어내는 공동 연출자다.

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
| HOLD_POSITION | 진입·유지·취소·완료·실패 이유를 구현 |
| PUSH | 진입·유지·취소·완료·실패 이유를 구현 |
| RETREAT | 진입·유지·취소·완료·실패 이유를 구현 |
| REQUEST_SUPPLY | 진입·유지·취소·완료·실패 이유를 구현 |
| ROTATE_SUPPORT | 진입·유지·취소·완료·실패 이유를 구현 |
| PRODUCE | 진입·유지·취소·완료·실패 이유를 구현 |
| DISPATCH | 진입·유지·취소·완료·실패 이유를 구현 |
| ESCORT_DELIVERY | 진입·유지·취소·완료·실패 이유를 구현 |
| ASSAULT_HIVE | 진입·유지·취소·완료·실패 이유를 구현 |


## 5. 게임별 Observation

```gdscript
{
  "self": {"role": StringName, "pos": Vector2, "hp": float, "ammo": float},
  "lane_pressure": PackedFloat32Array,
  "requests": Array[Dictionary],
  "production_queues": Array[Dictionary],
  "deliveries": Array[Dictionary],
  "visible_enemies": Array[Dictionary],
  "base_hp": float,
  "hive_hp": float,
  "phase": int
}
```

### 병사 판단

```text
hold_score = line_importance × current_pressure × role_fit
rotate_score = target_pressure × travel_feasibility × remaining_line_safety × requested_help
```

자기 라인을 비우면 3초 후 예측 압력이 임계값을 넘는 경우 이동 금지. 기지가 8초 안에 파괴될 예측이면 제한을 해제한다.

### 보급 수요

```text
demand =
  0.30 × current_deficit
+ 0.23 × consumption_rate
+ 0.18 × delivery_eta
+ 0.14 × lane_pressure
+ 0.09 × role_criticality
+ 0.06 × manual_request
```

생산 시간과 배송 시간을 포함해 6~18초 후 부족을 예측한다.

### 의도적 오판

- 오래된 소비율·동시 요청·배송 파괴 미인지에서 오판.
- 보급 Observation 갱신은 5Hz.
- 요청 스팸은 1.5초 병합.
- 두 품목 점수 차가 6% 미만이면 성격 선호.
- 완벽한 ETA가 아니라 공개 경로와 마지막으로 본 위험 사용.

### 배송

`DISPATCHED → IN_TRANSIT → DELIVERED/DESTROYED`를 추적한다. 파괴되면 재생산 점수에 손실 원인과 현재 라인 생존 시간을 반영한다.


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
  "game": "support_and_hold",
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
| 상호의존 | 보급 이벤트가 전선 결과에 기여하는 비율 45~75% |
| 연쇄 원인 | 거점 손실의 80% 이상이 최대 6단계 인과 그래프로 설명 |
| CPU 보급 | 실제 수요 적중 65~82%, 의도적 오판 8~18% |
| 대기 시간 | 병사 무탄약 무행동 연속 4초 초과 비율 3% 미만 |
| 역할 재미 | 6역할 각각 분당 의미 있는 결정 5회 이상 |

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

# 지원하며 버티기 — 레벨·데이터·밸런스 계약

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


## 4. 전장·배송 데이터

```json
{
  "id": "three_fronts",
  "size": [2200, 1200],
  "base": {"pos":[160,600],"hp":12000},
  "hive": {"pos":[2040,600],"hp":18000},
  "lanes": [
    {"id":0,"center_y":260,"front_points":[],"delivery_safe":[],"delivery_fast":[]}
  ],
  "production_nodes": [],
  "handoff_zones": [],
  "cover": [],
  "spawn_zones": []
}
```

검증:

- 각 라인에 안전 배송로와 빠른 배송로가 각각 존재.
- 빠른 길 ETA가 15~30% 짧고 적 노출은 25% 이상 높음.
- 배송 파괴 위치에서 잔해가 길을 영구 봉쇄하지 않음.
- 병사 역할은 5초 이내 인접 라인으로 이동 가능.
- 보급 역할 카메라에서 요청·ETA·위험이 한 화면에 읽힘.
- 페이즈 전환 시 기존 배송의 목적지가 유효하거나 명시적으로 반환됨.


## 5. 시스템별 데이터 책임

| 데이터 소비 시스템 | 검증 책임 |
|---|---|
| PhaseDirector | 5페이즈·방어→역공·Hive |
| SoldierSystem | 세 병사 역할·탄약·체력·스킬 |
| SupplySystem | 세 보급 역할·생산 큐·자원 |
| DeliverySystem | 경로·ETA·인수·파괴 |
| RequestSystem | 자동/수동 요청·핑·우선순위 |
| PressureSystem | 3라인 압력·지원 이동·연쇄 붕괴 |
| SupportCpuSystem | 수요 예측·생산·배송·의도적 오판 |

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

# 지원하며 버티기 — 플레이테스트·텔레메트리 명세

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
| 상호의존 | 보급 이벤트가 전선 결과에 기여하는 비율 45~75% |
| 연쇄 원인 | 거점 손실의 80% 이상이 최대 6단계 인과 그래프로 설명 |
| CPU 보급 | 실제 수요 적중 65~82%, 의도적 오판 8~18% |
| 대기 시간 | 병사 무탄약 무행동 연속 4초 초과 비율 3% 미만 |
| 역할 재미 | 6역할 각각 분당 의미 있는 결정 5회 이상 |

이 범위는 초기 가설이다. 사람 테스트 30판 뒤 중앙값과 상·하위 10%를 다시 고정한다.

## 5. 사건 이벤트

필수 원시 이벤트:

- `supply_requested`
- `production_started`
- `delivery_dispatched`
- `delivery_damaged`
- `delivery_received`
- `ammo_empty`
- `actor_rotated`
- `lane_breached`
- `phase_changed`
- `hive_exposed`
- `hive_destroyed`

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

# 지원하며 버티기 — 실제 구현 순서

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
| SH-M0 | 한 라인·병사 1·보급 1·탄약 배송 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| SH-M1 | 3라인·CPU 5명·요청·라인 이동 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| SH-M2 | 6역할·생산 큐·배송 파괴 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| SH-M3 | 3개 방어 페이즈·연쇄 붕괴 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| SH-M4 | Hive 2페이즈·역공·인과 그래프 | 해당 마일스톤 P0 100%·P1 90% 이상 |
| SH-M5 | 역할 교환·관전·헤드리스·밸런스 | 해당 마일스톤 P0 100%·P1 90% 이상 |

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

- **PhaseDirector**: 5페이즈·방어→역공·Hive
- **SoldierSystem**: 세 병사 역할·탄약·체력·스킬
- **SupplySystem**: 세 보급 역할·생산 큐·자원
- **DeliverySystem**: 경로·ETA·인수·파괴
- **RequestSystem**: 자동/수동 요청·핑·우선순위
- **PressureSystem**: 3라인 압력·지원 이동·연쇄 붕괴
- **SupportCpuSystem**: 수요 예측·생산·배송·의도적 오판

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

# 지원하며 버티기 — 체크리스트 운용·완료 판정

## 1. 체크리스트

이 패키지에는 공통 Godot 항목과 지원하며 버티기 전용 항목을 합친 **4,653개 체크리스트**가 들어간다.

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

- 3개 병사·3개 보급 역할, 3라인, 생산·배송·요청·라인 이탈·5페이즈 Hive 공략이 작동하는 회색상자
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

# 지원하며 버티기 — PixiJS 명세를 Godot로 옮기는 대응표

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

지원하며 버티기의 핵심 재미는 플레이어 간 연쇄 원인이므로 같은 입력이 다른 원인을 만들면 디버깅과 CPU 검증이 불가능해진다.

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
