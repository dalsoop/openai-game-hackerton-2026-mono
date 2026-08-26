# 설계 — 네트 계약 복원 (스킬·연출 상태 전송)

2026-08-27. 브랜치 `feat/dagul-prod-combat-restore`의 후속 작업 설계도.
문제: 서버 sim(`apps/server-pjh-dev1/project/scripts/sim/`)에는 스킬·CC·연출 시스템이 전부 있지만,
스냅샷 와이어에 실리지 않아 게스트 화면에서 애니메이션·스킬 연출이 소실된다.

## 근거 (실측)

| 층 | 위치 | 증상 |
|---|---|---|
| 서버 packer | `apps/server-pjh-dev1/project/scripts/net/network_host.gd` `_snap_players()`(105행) | 플레이어 17키만 전송. `maxHp`·`mag`·`magMax`·`reloadLeft`·`ult`·`characterId`·`downed`·`downLeft`·`deaths`·`score`·`streak`조차 누락 |
| 서버 packer | 같은 파일 `_snap_bullets()`(124행) | 탄환 x·y·owner만 전송. sim은 id·vel·kind·radius·arc·heavy를 갖고 있음(`projectile_hit.gd:11`) |
| 서버 packer | effects·event_log 미전송 | 타격·스킬·궁 연출 원천 소실 |
| 클라 계약 | `apps/dagul-prod/project/games/dagul/net/snap_contract.gd` `_player_view_defaults()`(210행) | 연출 필드를 매 스냅 기본값으로 재생성 |
| 클라 파생 | `net_world.gd:447`, `net_sfx_derive.gd` | gun_fire를 `equipment:""`로 역추정. 이벤트 채널 없음 |

렌더러(`render_heroes.gd` 등)가 실제로 읽는 연출 필드는 모두 서버 sim이 생산한다(실측 grep 완료):
stun_time·root_time·cc_time·guard_time·super_armor_time·spawn_protect_time·launch_time·launch_vel·
charging_skill·charge_time·action·held_item·spring_time·slide_time·pull_time·pocket_time·dmg_orb_time·
down_taken·wool_time·wool_hp·wool_max·roulette_time·roulette_rank·roulette_phase·roulette_spin_id·rl_timed·ult_clones.

## 원칙

1. **계약 SSOT는 `apps/dagul-prod/.../net/snap_contract.gd`.** 키 상수는 여기에만 추가한다.
   서버(별도 Godot 프로젝트라 preload 불가)는 같은 키 문자열을 미러하고, 드리프트는 게이트(§검증)에서 diff로 잡는다.
2. **omit-default**: 새 키는 값이 0/false/""/빈 배열이면 서버가 키 자체를 생략한다.
   클라 unpack은 전부 `get(키, 기본값)`이므로 하위호환이 자동 성립한다(구 서버 스냅도 그대로 동작).
3. 클라 전용 파생 필드(launch_trail, reload_flash, spray_index, muzzle_scale, hop 등)는 와이어에 싣지 않는다.
   RELOAD/GUN_FIRE action과 reloadLeft로 클라가 로컬 재생한다.
4. 기존 delta 압축(`server_match.gd _build_delta`)은 키 단위 str 비교라 그대로 동작한다.

## 와이어 계약 v2

### players 추가 키 (전부 omit-default)

| 와이어 키 | sim 필드 | 형 |
|---|---|---|
| `action` | action | String (StringName→str) |
| `stunT` `rootT` `ccT` `guardT` `armorT` `spawnT` | stun_time root_time cc_time guard_time super_armor_time spawn_protect_time | float |
| `launchT` `launchVX` `launchVY` | launch_time launch_vel.x launch_vel.y | float |
| `charging` `chargeT` | charging_skill charge_time | bool float |
| `heldItem` | held_item | String |
| `springT` `slideT` `pullT` `pocketT` | spring_time slide_time pull_time pocket_time | float |
| `dmgOrbT` `downTaken` | dmg_orb_time down_taken | float |
| `woolT` `woolHp` `woolMax` | wool_time wool_hp wool_max | float int int |
| `rouT` `rouRank` `rouPhase` `rouSpin` `rouLabel` | roulette_time roulette_rank roulette_phase roulette_spin_id roulette_label | float str str int str |
| `rlTimed` | rl_timed | Array(사전 그대로, str/num만) |
| `ultClones` | ult_clones | Array[{x,y}] (실제 shape는 `ultimate_animal.gd:58` 확인 후 x·y만 추출) |

또한 서버 `_snap_players()`는 dagul-prod PLAYER_KEYS에 이미 정의된 누락 키를 채운다:
`maxHp` `mag` `magMax` `reloadLeft` `ult` `characterId` `downed` `downLeft` `deaths` `score` `streak`, `parked`(실값).

### bullets 추가 키

`id`(next_entity_id), `vx` `vy`(vel), `kind`(str), `radius`, `arc`(bool, omit-false), `heavy`(bool, omit-false), `src`(source str).
클라 `parse_bullets`는 이 키들을 소비하고, vx/vy가 없을 때만 기존 위치차 유도(`_vel_by_id`) 폴백을 쓴다.

### 신규 섹션

- `effects`: `[{k,x,y,r,t,maxT,color,label,dx,dy,follow}]` — 서버 `world.effects`를 스냅마다 실어 보낸다. cap 48.
  클라는 서버 effects를 권위로 교체하되, 클라 로컬 이펙트(kind가 `local_` 접두)는 병합 유지한다.
- `events`: `[{t,k,a,b,d}]` — 서버 `world.event_log`에서 직전 전송 이후 발생분. cap 32.
  서버는 마지막 전송 이벤트 인덱스를 기억한다(full snap 수신자는 최근 32건).
  클라는 수신 이벤트를 자기 event_log로 emit한다. 스냅에 `events` 키가 있으면
  `SfxDerive`·`_apply_bullets`의 gun_fire 역추정을 끄고(중복 방지), 이벤트의 equipment 값을 그대로 쓴다.

## 작업 분해 (파일 경계 = 워커 경계)

### W1 — 계약 층 (dagul-prod)
- 파일: `apps/dagul-prod/project/games/dagul/net/snap_contract.gd`, `net_snap_parser.gd`, `tests/test_snap_contract.gd`
- 내용: 위 v2 키 상수 추가(P_*·B_*·EFFECTS·EVENTS), `pack_player`/`unpack_player`(omit-default 대칭),
  `parse_bullets` v2 키 소비, `parse_effects`/`parse_events` 신설, 왕복 테스트 확장.
- 수용 기준: pack→unpack 왕복에서 v2 필드 보존. 키 없는 구 스냅도 기본값으로 통과(기존 테스트 유지).

### W2 — 서버 packer (server-pjh-dev1)
- 파일: `apps/server-pjh-dev1/project/scripts/net/network_host.gd` (필요시 `server_match.gd` 최소 수정)
- 내용: `_snap_players` v2 전체 키(omit-default), `_snap_bullets` v2, `_snap_effects`, `_snap_events`(인덱스 추적).
- 수용 기준: 키 문자열이 본 설계 표와 일치. 0값 키 생략. event 인덱스는 재접속 full snap에서 최근 32건.

### W3 — 클라 소비 (dagul-prod, W1 완료 후)
- 파일: `apps/dagul-prod/project/games/dagul/net/net_world.gd`, `net_sfx_derive.gd`, `tests/test_net_world.gd`
- 내용: `apply_snap`에서 effects/events 소비, events 존재 시 gun_fire 역추정 비활성, 이벤트 equipment 전달,
  `_lerp_motion`이 새 연출 필드를 덮어쓰지 않는지 확인, 테스트 확장(events 소비·중복 방지·effects 병합).
- 수용 기준: events 있는 스냅에서 gun_fire 이벤트가 정확히 1회. 구 스냅(events 없음)에서 기존 역추정 유지.

### 모듈화 (웨이브 사이 필수 단계 — "700줄 넘으면"이 아니라 계획된 분리)
- W1 직후: `snap_contract.gd`(453줄 → 600줄 예상)에서 플레이어 코덱
  (pack_player/unpack_player/_apply_player_vitals/_player_view_defaults)을 `snap_player_codec.gd`로 분리.
  SnapContract 는 키 상수 + 파사드 유지, 기존 호출부 시그니처 불변. 왕복 테스트로 분리 검증.
- W3 후: `net_world.gd`(517줄)가 600줄 초과 시 events/effects 소비를 `net_event_feed.gd`로 분리.
- 렌더 활용 단계: `debug_renderer.gd`는 이미 696/700줄로 한계 — 신규 필드 활용 전에 계층 분리 필수.

### W5 — 프로드 실서버(TS 허브 심) 송신부 (아키텍처 정정 후 추가)
**정정(실측)**: dagul-prod 의 권위 서버는 Godot 게임 서버가 아니라 **Next.js 허브의 TS 심**
(`apps/dagul-prod/web/lib/hub/match-*.ts`, Colyseus)이다. `packAuthoritySnap`(match-authority.ts)이
MSG.SNAP 딕셔너리를 방송하고 Godot 이 SnapContract 로 언팩한다. server-pjh-dev1 의 game_server.gd(ENet)는
dev 슬롯 전용이며 프로드 배포 체인에 없다. `src/`(구 Node 허브)의 GAME_SERVER_URL 경로는 미배선 잔재.
- 파일: `web/lib/hub/match-authority.ts`, `web/lib/hub/lobby-play.ts`
- 내용: 플레이어 v2 키(심 보유분) + 탄환 확장 + events 채널(fx→events 편입, MSG.GUN_FIRE 방송 제거).
- TS 심 보유 실측: stun/root/launch/guard/armor/spawnProtect/roulette/clone/wool/dmgOrb/slide/pull ○ ·
  spring/pocket/heldItem/effects 채널 ×(미이식).

### 후속 (이번 웨이브 제외)
- **TS 심 미이식 시스템 포팅**: active item(spring·pocket·heldItem 노출), 서버 effects 채널(원본 add_effect 계열).
- 클라 렌더러 전용 연출 없는 kind 7종(chain_bind·charge_break·monkey_pop·rooster_burst·sheep_pop·snake_pop·stun_burst)
  — 현재 제네릭 버스트 폴백으로 표시됨.
- `apps/server-fig-dev1` 동일 반영(W4), `SNAP_HZ` 하드코딩 20.0 → 틱 유도(리뷰 발견 #3), 렌더러 신규 필드 활용 확대.

## 실행 계획

- 웨이브 1: W1·W2 병렬 (Grok 워커, 서로 다른 프로젝트라 충돌 없음)
- 웨이브 2: W3 (W1의 상수를 사용하므로 순차)
- 코디네이터 게이트(전 웨이브 공통):
  1. `python3 lint_gd.py apps/dagul-prod/project/games/dagul` → 0건
  2. `python3 lint_gd.py apps/server-pjh-dev1/project/scripts` → 기존 대비 증가 0
  3. Godot 헤드리스 `run_tests.gd` 전건 통과 (237건 + 신규)
  4. 키 드리프트 diff: 서버 `_snap_players` 방출 키 집합 ⊇ 클라 PLAYER_KEYS ∪ v2 표
  5. 코드 규칙: 파일 ≤700줄(필요시 모듈 분리), 함수 ≤40줄, 중첩 if 금지(early return)

## 리스크

- 대역폭: 20Hz × 8인 × v2 키. omit-default로 평시엔 거의 늘지 않고, delta 압축이 반복 값을 거른다.
- 이벤트 중복: events 채널과 SfxDerive 역추정 동시 활성 시 사운드 2회 — W3 수용 기준으로 차단.
- 파일 크기: snap_contract.gd·network_host.gd가 700줄 근접 시 pack/unpack 모듈 분리.
