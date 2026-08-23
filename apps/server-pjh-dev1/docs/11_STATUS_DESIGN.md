# 다굴 스테이터스 기획서

문서 목적: 지금 `server-pjh-dev1`에 들어 있는 스테이터스가 **무엇을 의미하는지**, **왜 그 값인지**를 한곳에 모은다.  
권위 있는 숫자 출처는 코드다. `project/scripts/sim/game_world.gd`. 표 형태는 `docs/dagul_status_sheet.xlsx`.

이 문서는 두 층을 섞지 않는다.

- **확정 의도**: 이 브랜치에서 명시적으로 바꾼 규칙. 이유까지 적는다.
- **읽히는 설계**: 장비별 숫자 분산에서 보이는 역할 설계. 회의록이 아니라 코드 해석이다.
- **구 문서와 다른 점**: `10_EQUIPMENT_COMBAT.md`는 리스폰/코어 승리 시절 계약이다. 현재 룰과 다르다.

---

## 1. 한 줄 목표

다굴은 8인 난전 배틀로얄이다.  
스테이터스는 **한 명이 한 방에 안 죽고**, **오래 끌면 존이 중앙으로 밀어 넣으며**, **장비마다 사거리/생존/압박 방식이 달라지게** 짜여 있다.

---

## 2. 확정 의도 (이 프로젝트에서 실제로 정한 것)

### 2.1 승패: 집 파괴 ≠ 패배, 사망 = 탈락

- 스폰 패드(집/코어)는 남아 있어도 그 자체로 패배 조건이 아니다.
- 캐릭터 HP가 0이 되면 그 슬롯은 즉시 탈락한다. 집 리스폰 없음.
- 승패는 생존자 기준 (`last_survivor` / 시간 제한 시 남은 HP).

이유: 집을 지키는 게임이 아니라, 사람이 죽는 난전으로 읽히게 하기 위해서.  
코어 HP 210은 예전 “집 파괴=탈락” 잔재다. 지금은 지형/점수 대상이지 생명줄이 아니다.

### 2.2 HP: 일반 풀콤보 4회 전후

장비 `max_hp`는 137~213이다.

| id | max_hp | 의도된 위치 |
|---|---:|---|
| burst | 137 | 가장 유리 |
| mortar | 140 | 유리 |
| rail | 141 | 유리 |
| leech | 149 | 중간 |
| scatter | 155 | 중간 |
| blade | 157 | 중간 |
| bomb | 158 | 중간 |
| chain | 164 | 단단 |
| brawler | 176 | 단단 |
| breaker | 195 | 탱크 |
| spear | 204 | 탱크 |
| shield | 213 | 최탱크 |

이유 (명시): 일반 공격 풀콤보를 **4번 맞으면 거의/딱 죽고**, **5번째 풀콤보가 끝나기 전에 죽는** 구간.  
구 계약(`10_EQUIPMENT_COMBAT.md`)의 “2콤보/3콤보 킬, 콤보 캡 38~50%”는 더 이상 목표가 아니다.  
현재 `combo_cap_ratio`는 0.24~0.27로 내려가 있다. 한 콤보로 전 체력을 못 가져가게 막고, 킬은 여러 번 붙어야 나게 한다.

존 도트 8 HP/s는 전투 킬을 대체하지 않게 낮게 둔 값이다. 137 HP 기준으로도 존만으로 죽으려면 약 17초다.

### 2.3 맵과 자기장: 중앙 수렴 배틀로얄

- 맵: 원본 아레나 2800×1700을 2×2로 붙인 뒤 0.7배 → **3920×2380**, 중심 (1960, 1190).
- 자기장 중심은 처음부터 끝까지 그 좌표. 옆으로 이동하지 않는다.
- 초기 반경 1652. 가장자리 스폰은 초반 안전, 코너에는 링이 보인다.
- 페이즈: 8/10→1204, 8/10→812, 8/9→476, 7/8→252, 6/8→98.

이유: 스폰은 흩어 두고, 시간이 갈수록 **정중앙으로만** 모이게 하려고.  
반경은 예전 작은 맵 값을 맵 스케일(약 1.4배)에 맞춰 키운 것이다. 첫 대기만 12초에서 8초로 줄였다(2026-08-20 템포 패치). 이후 페이즈 대기와 수축 시간은 전투 압박용이라 그대로다.

### 2.4 시간 뼈대

| 항목 | 값 | 왜 |
|---|---:|---|
| 틱 | 60 Hz | 시뮬 고정 |
| 시작 카운트 | 3초 | 전원 동시에 출발 |
| 매치 제한 | 210초 | 존이 98까지 가는 누적 78초보다 길다. 존이 먼저 압박하고, 시계는 최후 판정 |
| 힐 픽업 리스폰 | 16초 | 회복을 주기적으로 다시 쟁점화 |
| 힐 비율 | 30% | 한 번에 풀피 복구 금지 |

구 문서의 “평균 경기 40~105초”는 현재 210초 제한·큰 맵과 같이 보면 목표가 아니라 옛 계약이다.

### 2.5 표현 이동

Space hop is visual only (height + squash). Shift is the combat flash/mobility. Hop does not change pos, i-frames, or move_speed.

### 2.6 Item mode active pool

Item mode only. Field pickups roll one active: medkit / spring / slide / pull / pocket / decoy. One held slot, E uses and consumes, swap drops the old item, death drops the held item (never a decoy). Decoy explodes on touch. Space hop stays visual-only; spring is the real hop. Classic field heal and full medkit-count stay unchanged.

---

## 2026-08-20 템포 패치

맵이 2800폭에서 3920(약 1.4배)로 커졌는데 이속·첫 존 대기·대시 거리는 옛 작은 맵 값이었다.

| 레버 | 전 | 후 | 왜 |
|---|---|---|---|
| 장비 `move_speed` / `HERO_SPEED` | 252–354 / 310 | ×1.35 반올림 → 340–478 / 419 | 맵 스케일 1.4를 그대로 주면 카이팅이 미끄럽다. 1.35면 가로 횡단이 옛 8–11초로 거의 복귀하고, 탱크는 암살보다 느리다. |
| 첫 자기장 wait | 12초 | 8초 | 12초는 새 맵을 한 바퀴 걷는 시간과 같다. 8초면 여유 있게 건너기 전에 수축이 시작된다. 이후 wait 8/8/7/6과 shrink·반경은 그대로. |
| 기동 거리 | 120–265px | ×1.15 반올림 → 138–305px | 대시가 새 맵 공백을 못 메운다. 거리를 조금 키워 옛 아레나 재배치 감각을 되돌린다. 쿨은 그대로. 새 기동 유형은 없음. |

---

## 3. 읽히는 설계: 장비가 캐릭터다

다굴에는 별도 캐릭터 스탯 테이블이 없다.  
**장비가 이속, HP, 무게, 콤보 캡, 패시브, 기동, 평타, 스킬, 궁을 전부 결정한다.**  
로비의 십이지 이미지는 슬롯 비주얼이다. 전투 성능은 장비 id가 정한다.

역할 분산은 코드 숫자에서 이렇게 읽힌다.

### 3.1 이속 vs HP

이속이 빠른 쪽은 HP가 낮거나, 근접/암살 쪽이다.

- 빠름: blade 478 / burst 454 / brawler 440 / scatter 432
- 느림: shield 340 / breaker 359 / mortar 365 / bomb 389

탱크(shield, breaker, spear)는 걸어가는 대가으로 맞는다.  
암살/사냥꾼은 먼저 붙고 먼저 빠진다.

`HERO_SPEED` 419는 기본값일 뿐이고, 스폰 이후에는 장비 `move_speed`가 덮어쓴다.

### 3.2 무게 (weight)

런치/넉백 저항으로 쓰인다.

- 가벼움: blade 0.86, rail 0.88, burst 0.90
- 무거움: shield 1.55, breaker 1.34, brawler 1.12

이유: 저체력 원거리/암살은 한 대에 밀려 콤보가 끊기기 쉽고, 탱크는 자리를 지킨다.

### 3.3 평타 템포

`normal_interval` 0.32~0.62초.

- 빠른 손: leech 0.32, blade 0.34, scatter 0.36
- 느린 한 방: bomb/shield 0.62, mortar 0.58, spear 0.52

`normal_damage × projectiles / interval`로 보면 burst는 연사 합이 높고, breaker/shield는 한 방이 크다.  
TTK 계산(자기 HP ÷ 그 DPS)은 시트 노란칸. 콤보 배율·가드·거리 미포함이라 **실제 킬은 더 길다.**

### 3.4 사거리

`preferred_range`가 그 장비의 “서고 싶은 거리”다.

- 근접: brawler 155, blade 205, shield 225
- 중거리: scatter 285, spear 345, breaker 360
- 원거리: burst 435, mortar 455, rail 540

이유: 같은 원에서 전원 난타가 아니라, 존이 줄어들수록 원거리와 근접의 유불리가 뒤집히게 하려고.

### 3.5 스킬 쿨 / 기동 쿨

- 스킬 쿨 3.10~5.60초. 실드/체인/봄/박격이 길다.
- 기동 쿨 3.6~5.5초. 암살(blade 3.8, 305px)과 스트라이커(brawler 3.6)가 짧다. 탱크 기동은 짧고 느리다(shield 138px).

이유: 생존 무기는 스킬로 공간을 사고, 암살은 쿨 짧은 이동으로 각을 다시 만든다.

### 3.6 장비별 한 줄

| id | 캐릭터 | 왜 이 스탯인가 (해석) |
|---|---|---|
| scatter | REX | 근접 샷건. 이속·공속 빠르게, HP 중간. 난전에서 리셋 |
| rail | SCOPE | 저격. 이속·HP 낮고 사거리·한 방 큼. 맞으면 밀린다 |
| mortar | BOMBI | 공간 거부. 이속 낮고 공속 느림. 존이 줄어들면 강해짐 |
| leech | NYX | 흡혈. HP 중간, 공속 빠름. 맞추면 유지 |
| breaker | BRICK | 돌파. HP·무게 높고 이속 낮음. 한 방과 런치 |
| burst | ZIP | 추적. 최속이면서 최저 HP. 연사 합으로 사냥 |
| blade | AKARI | 암살. 최고속, 짧은 기동쿨, 낮은 무게. 맞으면 잘 죽음 |
| brawler | MACK | 근접 주먹. 이속·HP 둘 다 준수. 기동으로 콤보 탈출 |
| bomb | MIMI | 설치. 공속 느리고 스플래시. 동선 통제 |
| spear | ORIN | 창. 높은 HP + 긴 찌르기. 거리 유지 탱크 |
| chain | RIVA | 포획. 당기는 넉백(음수). 콤보 후 락 |
| shield | WARD | 방패. 최저속 최고HP 최고무게. 밀어내는 벽 |

---

## 4. 모드가 스테이터스를 어떻게 쓰나

| 모드 | 시작 장비 | 의미 |
|---|---|---|
| classic | 각자 다름 | 위 역할 분산이 그대로 노출 |
| gun-semi | 전원 rail | 저격 스탯으로 통일 후, 처치 시 총 체인 |
| gun-auto | 전원 burst | 사냥꾼 스탯으로 통일 후 체인 |
| item | 전원 scatter | 샷건 + 원슬롯 액티브 |
| full | 루팅 전부 | 가장 긴 빌드업 |

총 체인: rail → burst → scatter → mortar → breaker → bomb → leech → blade → spear → chain → shield → brawler.  
처치할수록 **원거리 저격에서 근접 탱크로** 직업이 바뀐다. 후반은 존이 작아지므로 근접 스탯이 이득이 되게 읽힌다.

---

## 5. 구 기획과 충돌하는 숫자

`10_EQUIPMENT_COMBAT.md`에 남아 있지만 **현재 코드와 다른 것**:

- 다운 후 10초 리스폰 → 없음. 사망=탈락.
- 코어 파괴 승리 / 코어 점수 300 → 생존자 승패.
- 콤보 캡 38~50% HP, 2~3콤보 킬 → 캡 24~27%, 약 4콤보 킬.
- 평균 경기 40~105초 → 제한 210초, 존 시계 78초+.
- 인간 6인 전제 문장 일부 → 현재 PLAYER_COUNT 8.

밸런스를 손볼 때는 이 문서와 시트를 보고, 구 문서는 역사로만 본다.

---

## 6. 지금 감각으로 보이는 문제 (다음 패치 후보)

2026-08-20 템포 패치 이후 이속은 340~478, 가로 횡단은 약 8~11초, 첫 자기장 대기는 8초다.  
남은 템포 레버는 평타/스킬 쿨과 맵 스케일이다. 이속·첫 존 대기는 더 이상 1순위 후보가 아니다.

손대기 쉬운 레버, 영향 큰 순:

1. `move_speed` (전체 배율)
2. 자기장 `wait` (1페이즈는 이미 8초. 이후 페이즈는 전투 압박용)
3. `normal_interval` / 스킬 쿨
4. 맵 스케일 (이미 한 번 키움. 다시 줄이면 스폰·존 반경을 같이 재계산해야 함)

숫자는 시트에 있고, 이 문서는 그 숫자의 이유다.  
템포를 올리기로 하면 어떤 레버를 얼마만큼 올릴지 이 표에서 고른 뒤 코드와 시트를 같이 고친다.

---

## 7. Animal tendency vs gun combat (signature)

Animals are play tendency (CPU habits, juice). Guns are the current combat kit.

Kit skills and ultimates are retired. Combat is the 12 guns only (family fire + FX).
RMB skill charge, Q ult, melee combo patterns, mines-as-gun, seekers, tethers, and walls are no-ops.
Body `move_speed` / HP / weight stay on the animal kit. Same gun = same fire numbers.


Rules:
- Do not change a gun's fire interval, damage, spread, or ammo because of the animal.
- No signature crit or damage bonus.
- Skills must not name a gun or buff a caliber.

Classic / default spawn uses that animal's signature equipment. Item mode still forces scatter. gun-semi / gun-auto keep their mode start kit. CPU may add one small preference step if a floor gun is the signature kit; it must not path across the map ignoring danger.

AWM has no art in-repo. Frame 7 of Tex_Gun_4x3 is the AKM cell and is the AWM stand-in.

Signature table (zodiac slot order; atlas already swaps Dragon/Snake):

| slot | animal | signature equipment | gun visual | family |
|---:|---|---|---|---|
| 0 | Rat | burst | Glock 18 (frame 1) | pistol |
| 1 | Ox | breaker | RPK (frame 4) | heavy |
| 2 | Tiger | spear | AK-47 (frame 6) | rifle |
| 3 | Rabbit | brawler | M1911 (frame 0) | pistol |
| 4 | Dragon | mortar | M79 (frame 11) | heavy |
| 5 | Snake | leech | MP5 (frame 2) | smg |
| 6 | Horse | chain | M4A1 (frame 5) | rifle |
| 7 | Goat | shield | Winchester M1873 (frame 10) | rifle |
| 8 | Monkey | blade | Thompson (frame 3) | smg |
| 9 | Rooster | rail | AWM / AKM stand-in (frame 7) | heavy |
| 10 | Dog | scatter | SPAS-12 (frame 9) | shotgun |
| 11 | Pig | bomb | Double barrel (frame 8) | shotgun |

Atlas cells from game-lhj-animal Gun tscn `frame` fields: 0 M1911, 1 Glock18, 2 MP5, 3 Thompson, 4 RPK, 5 M4A1, 6 AK-47, 7 AKM (AWM stand-in), 8 DB, 9 SPAS-12, 10 Winchester, 11 M79.
Death is 3-revive then out, not instant out. After each revive the hero has 3.0s i-frames.
