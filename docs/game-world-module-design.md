# game_world.gd 모듈 분리 설계서

## 개요

`GangGameWorld`(4926줄)를 기능별 모듈로 분리한다. 외부 인터페이스(`step_tick`, `reset`, `set_mode`)는 변경하지 않는다. `GangGameWorld`는 모듈을 조합하는 파사드로 남고, 각 모듈은 `RefCounted` 기반 클래스로 분리하여 `preload`로 로드한다.

## 분리 원칙

1. **파사드 패턴**: `GangGameWorld`가 모듈 인스턴스를 보유하고 `step_tick()`에서 순서대로 호출한다.
2. **상태 공유**: 모듈은 자체 상태를 갖지 않고, `GangGameWorld`의 상태(heroes, projectiles 등)를 참조로 받아서 조작한다. 이렇게 해야 결정론이 깨지지 않는다.
3. **호출 순서 불변**: `step_tick()` 내부의 호출 순서가 결정론의 핵심이다. 모듈로 쪼개더라도 같은 순서를 유지해야 한다.
4. **RNG 공유**: 모든 모듈이 같은 `rng` 인스턴스를 사용해야 결정론이 보장된다. 모듈별 별도 RNG를 만들면 호출 순서가 달라져서 시뮬레이션이 달라진다.

## 모듈 설계

### 1. `equipment_data.gd` — 장비/캐릭터 데이터

**책임**: 무기 정의, 캐릭터 스탯, 모드별 설정 등 순수 데이터.

**포함될 함수/데이터 (현재 줄 번호)**:
- `equipment_defs` 배열 (164~177)
- `_identity_for_equipment()` (179)
- `_combat_stats_for_equipment()` (194)
- `_mobility_for_equipment()` (209)
- `_make_equipment()` (232)
- `MODE_START_EQUIPMENT`, `GUN_LOOT_CHAIN` 상수 (161~162)
- `GUN_LOOT_MODES`, `MEDKIT_MODES`, `NO_LOOT_MODES`, `ITEM_POOL_MODE` 상수 (141~144)

**의존**: 없음 (순수 데이터/조회).

**예상 줄 수**: ~250줄

**위험도**: 낮음. 순수 데이터 조회라서 분리해도 동작에 영향이 없다.

---

### 2. `arena.gd` — 아레나/지형/엄폐물

**책임**: 아레나 경계, 엄폐물 생성, 충돌 판정, 좌표 유틸.

**포함될 함수 (현재 줄 번호)**:
- `_resolve_cover_motion()` (1406)
- `_tiled_points()` (1417)
- `_build_tiled_covers()` (1426)
- `_clamp_arena_point()` (1448)
- `_nudge_out_of_cover()` (1454)
- `_cover_radius()` (1465)
- `_point_in_cover()` (1469)
- `_line_blocked()` (1476)
- 아레나 관련 상수: `ARENA_SIZE`, `ARENA_CENTER`, `ARENA_MARGIN`, `SPAWN_*` 등 (10~21)

**의존**: 없음 (순수 기하 연산).

**예상 줄 수**: ~120줄

**위험도**: 낮음. 좌표/충돌 유틸이라 독립적이다.

---

### 3. `crates.gd` — 크레이트/오브/힐팩

**책임**: 크레이트 스폰/파괴, 오브 수집, 힐팩 업데이트.

**포함될 함수 (현재 줄 번호)**:
- `_spawn_breakable_crates()` (1485)
- `_place_crate_ring()` (1491)
- `_hurt_crate()` (1527)
- `_damage_crates_at()` (1546)
- `_spawn_crate_orb()` (1554)
- `_update_crate_orbs()` (1564)
- `_nearest_orb_target()` (1585)
- `_collect_crate_orb()` (1597)
- `_best_crate()` (1610)
- `_best_crate_orb()` (1624)
- `_update_health_pickups()` (1214)
- `_pickup_target_valid()` (1270)
- `_nearest_pickup_target()` (1280)
- 힐팩/크레이트 관련 상수 (32~50)

**의존**: `arena.gd` (좌표 유틸), `event_log`, `rng`.

**예상 줄 수**: ~350줄

**위험도**: 중간. `_hurt_crate`가 `_add_effect`를 호출하고, `_collect_crate_orb`가 히어로 상태를 직접 수정한다. 이 호출을 콜백으로 처리하거나 world 참조를 넘겨야 한다.

---

### 4. `cpu_ai.gd` — CPU 행동

**책임**: CPU 플레이어의 이동/공격/스킬 판단.

**포함될 함수 (현재 줄 번호)**:
- `_update_cpus()` (813) — 172줄, 가장 큰 함수
- `_choose_target()` (986)
- `_best_health_pickup()` (1022)
- `_is_signature_floor_gun()` (1052)
- `_hazard_escape_vector()` (1058)
- `_target_valid()` (1136)
- `_target_position()` (1139)
- `_cpu_try_ultimate()` (2728)
- `_cpu_consider_held_item()` (4196)
- `_apply_cpu_move()` (4073)
- `_highest_threat_except()` (3533)

**의존**: 거의 모든 모듈에 의존 (전투, 이동, 아이템 함수를 호출). world 참조가 필수.

**예상 줄 수**: ~350줄

**위험도**: 높음. `_update_cpus`가 전투/이동/아이템 함수를 직접 호출한다. world 파사드의 메서드를 통해 호출하게 리다이렉트해야 한다.

---

### 5. `combat.gd` — 전투/투사체/히트

**책임**: 공격, 투사체 업데이트, 데미지 계산, 히트 판정.

**포함될 함수 (현재 줄 번호)**:
- `_try_normal_attack()` (2199) — 94줄
- `_spawn_projectile()` (2096)
- `_spawn_arc_bomb()` (2122)
- `_update_projectiles()` (3559) — 111줄
- `_splash_damage()` (3671)
- `_update_zones()` (3687)
- `_update_effects()` (3720)
- `_damage_hero()` (3729) — 159줄
- `_damage_core()` (3889)
- `_damage_hero_environment()` (4582)
- `_heal_hero()` (3928)
- `_award_charge()` (3917)
- `_add_effect()` (2304)
- `_add_zone()` (2307)
- `_attack_direction()` (2070)
- `_muzzle_spawn_pos()` (2075)
- `_normal_combo_pattern()` (2138)
- `_normal_step_reach()` (2141)
- `_normal_auto_target()` (2144)
- `_try_start_reload()` (2167)
- `_stamp_gun_fire()` (2187)
- `_normal_reach()` (2294)
- `_normal_combo_length()` (2298)
- `_equipment_reach()` (2301)
- `_break_incoming_combo()` (2487)
- `_absorb_roulette_shield()` (2014)
- `_projectile_impact_kind()` (3545)
- `_streak_damage_multiplier()` (1151)
- `_streak_move_multiplier()` (1156)

**의존**: `equipment_data.gd`, `arena.gd`, `event_log`, `rng`. 히어로/투사체/존/이펙트 상태 직접 조작.

**예상 줄 수**: ~800줄

**위험도**: 높음. 가장 복잡한 모듈. `_damage_hero`가 콤보, 넉백, 다운, 제거, 스트릭, 궁극기 충전을 전부 처리한다. 분리 시 콜백 지점이 많다.

---

### 6. `ultimates.gd` — 궁극기/동물별 스킬

**책임**: 12종 동물별 궁극기 실행 및 틱.

**포함될 함수 (현재 줄 번호)**:
- `_try_ultimate()` (2790) — 75줄, 동물별 분기
- `_set_ultimate_focus()` (2783)
- 황소: `_begin_ox_gore()` (2609), `_tick_ox_charges()` (2626)
- 쥐: `_begin_rat_tide()` (2671), `_hero_in_rat_tide()` (2691), `_apply_rat_tides()` (2699)
- 뱀: `_begin_snake_shed()` (3388), `_tick_snake_skins()` (3409), `_hurt_snake_skin()` (3423), `_hit_snake_skin()` (3442)
- 용: `_begin_dragon_smoke()` (3341), `_tick_dragon_smokes()` (3353), `_pos_in_dragon_smoke()` (3362), `hero_hidden_in_smoke()` (3368), `local_is_dragon()` (3383)
- 호랑이: `_begin_tiger_roar()` (3299), `_tick_tiger_roars()` (3318), `_apply_flee_vel()` (3327)
- 토끼: `_begin_rabbit_burrow()` (3257), `_tick_rabbit_burrows()` (3275)
- 말: `_begin_horse_kick()` (3211), `_tick_horse_kicks()` (3248)
- 닭: `_begin_rooster_egg()` (3145), `_tick_rooster_eggs()` (3158), `_explode_rooster_egg()` (3187)
- 돼지: `_begin_pig_mud()` (3114), `_tick_pig_muds()` (3125), `_pos_in_enemy_mud()` (3134)
- 개: `_begin_dog_fetch()` (2866), `_tick_dog_rush()` (2879)
- 양(울): `_begin_wool_shield()` (3041), `_tick_wool_shields()` (3050), `_absorb_wool_shield()` (3066), `_pop_wool_shield()` (3089), `_wool_shield_pos()` (3038)
- 클론: `_sync_ult_clones()` (3460), `_pop_ult_clone()` (3498), `_hit_ult_clone()` (3513)
- `_ultimate_armor()` (3530)
- 피니시 시네마틱: `_try_begin_finish()` (2957), `_tick_finish_cine()` (2996), `_cancel_finish_cine()` (2954)

**의존**: `combat.gd`(데미지/이펙트), `arena.gd`(좌표), `event_log`, `rng`.

**예상 줄 수**: ~900줄

**위험도**: 중간. 각 동물별 로직이 독립적이라 분리하기 쉽지만, `_damage_hero`와 `_add_effect` 등 전투 함수를 호출하므로 world 참조가 필요하다.

---

### 7. `items.gd` — 아이템/모빌리티/배치물

**책임**: 액티브 아이템, 모빌리티 스킬, 설치물(지뢰/벽).

**포함될 함수 (현재 줄 번호)**:
- `_try_mobility()` (2507) — 73줄
- `_try_use_active_item()` (4136) — 59줄
- `_try_use_medkit()` (4223)
- `_try_gun_loot()` (4240)
- `_place_mine()` (2311)
- `_place_bounce_wall()` (2340)
- `_moving_wall_sweep()` (2361)
- `_mine_has_target()` (2394)
- `_update_deployables()` (2407)
- `_deployable_wall_hit()` (2457)
- `_mark_wall_hit()` (2477)
- `_cancel_attack_recovery()` (2581)
- `_cancel_skill_charge()` (2587)
- `_begin_skill_charge()` (2595)
- `_continue_skill_charge()` (2598)
- `_release_skill_charge()` (2601)
- `_try_equipment_attack()` (2604)
- `_item_kind_color()` (3939)
- `_roll_pickup_kind()` (3952)
- `_spawn_dropped_pickup()` (3974)
- `_explode_decoy()` (4006)
- `_collect_item_pickup()` (4034)
- `_steer_slide()` (4059)
- `_pull_target_toward()` (4088)
- `_apply_pull_pulse()` (4098)
- `_update_item_pulses()` (4119)
- `_hero_in_own_pocket()` (4128)

**의존**: `combat.gd`, `arena.gd`, `equipment_data.gd`, `event_log`, `rng`.

**예상 줄 수**: ~600줄

**위험도**: 중간. 모빌리티와 아이템이 히어로 상태를 직접 변경한다.

---

### 8. `lifecycle.gd` — 생존/부활/승리 판정

**책임**: 다운/제거, 부활, 세이프존, 타워, 승리 조건.

**포함될 함수 (현재 줄 번호)**:
- `_apply_lethal_or_down()` (4281)
- `_enter_down()` (4297)
- `_stand_up()` (4324)
- `_tick_downs()` (4339)
- `_down_hero()` (4361) — 126줄
- `_eliminate()` (4488)
- `_update_threat()` (4508)
- `_update_respawns()` (1670)
- `_respawn_delay_for()` (1640)
- `_respawn_point()` (1660)
- `_standing_leader()` (1705)
- `_hero_in_safe_zone()` (4521)
- `_update_safe_zone()` (4526)
- `_apply_safe_zone_damage()` (4556)
- `_hero_hp_ratio()` (4596)
- `_core_hp_ratio()` (4601)
- `_time_limit_better()` (4606)
- `_declare_winner()` (4617)
- `_resolve_time_limit()` (4632)
- `_standing_better()` (4646)
- `final_standings()` (4661)
- `_check_end()` (4675)
- `_show_streak_callout()` (4263)
- `_streak_title()` (4269)
- `_note_life_hitter()` (2029)
- `_note_life_damage()` (2032)
- `_assist_slots()` (2047)
- 세이프존 관련 상수/변수 (62~72, 125~133)
- 타워: `_reset_mid_tower()` (4751), `_update_mid_tower()` (4765), `_hurt_tower()` (4818), `_tower_shell()` (4851), `_tower_point_blank()` (4880), `_tower_ring_shot()` (4908), `_tower_fan_shot()` (4913), `_tower_carpet()` (4919)

**의존**: `combat.gd`(데미지), `arena.gd`(세이프존 좌표), `event_log`, `rng`.

**예상 줄 수**: ~600줄

**위험도**: 중간~높음. `_down_hero`가 스트릭/룰렛/킬 보상 등 많은 부수 효과를 가진다.

---

### 9. `roulette.gd` — 룰렛/버프 시스템

**책임**: 킬 보상 룰렛, 버프 적용/만료.

**포함될 함수 (현재 줄 번호)**:
- `_roulette_faces()` (1754)
- `_roulette_b_chance()` (1803)
- `_pick_roulette_face()` (1810)
- `_roulette_face_list()` (1817)
- `_clear_roulette_buffs()` (1826)
- `_apply_roulette_face()` (1841)
- `_roulette_face_desc()` (1881)
- `_roulette_rank_color()` (1911)
- `_begin_next_roulette()` (1918)
- `_queue_roulette()` (1941)
- `_grant_kill_roulettes()` (1952)
- `_expire_timed_buff()` (1958)
- `_tick_roulette()` (1964)
- `_roulette_stat()` (1745)
- `_hero_has_timed()` (1739)

**의존**: `event_log`, `rng`.

**예상 줄 수**: ~250줄

**위험도**: 낮음. 자체 완결적인 서브시스템이고 다른 모듈에 대한 의존이 적다.

---

### 10. `movement.gd` — 이동/넉백/물리

**책임**: 히어로 이동, 넉백, 점프, 발사체 이동 제외(그건 combat).

**포함될 함수 (현재 줄 번호)**:
- `_move_heroes()` (1161)
- `_move_launched_hero()` (1292)
- `_update_knockouts()` (1361)
- `_hero_move_speed()` (1729)
- `_apply_human()` (654) — 입력→이동 변환
- `_apply_peer_humans()` (756)

**의존**: `arena.gd`(충돌), `equipment_data.gd`(이동 속도), `rng`.

**예상 줄 수**: ~350줄

**위험도**: 중간. `_apply_human`이 전투 함수(`_try_normal_attack`, `_try_mobility`)를 호출한다. 이 호출을 world 파사드 경유로 바꿔야 한다.

---

## GangGameWorld 파사드 구조 (분리 후)

```gdscript
class_name GangGameWorld
extends RefCounted

const EquipData = preload("res://scripts/sim/equipment_data.gd")
const Arena = preload("res://scripts/sim/arena.gd")
const Crates = preload("res://scripts/sim/crates.gd")
const CpuAI = preload("res://scripts/sim/cpu_ai.gd")
const Combat = preload("res://scripts/sim/combat.gd")
const Ultimates = preload("res://scripts/sim/ultimates.gd")
const Items = preload("res://scripts/sim/items.gd")
const Lifecycle = preload("res://scripts/sim/lifecycle.gd")
const Roulette = preload("res://scripts/sim/roulette.gd")
const Movement = preload("res://scripts/sim/movement.gd")

# 모든 상태 변수는 여기에 남는다 (heroes, projectiles, ...)
# 모듈 인스턴스
var _equip: EquipData
var _arena: Arena
var _crates: Crates
var _cpu: CpuAI
var _combat: Combat
var _ult: Ultimates
var _items: Items
var _life: Lifecycle
var _roul: Roulette
var _move: Movement

func _init(seed_val: int = 2222) -> void:
    rng = SeededRngScript.new(seed_val)
    event_log = EventLogScript.new()
    # 모듈은 self(world)를 참조로 받는다
    _equip = EquipData.new()
    _arena = Arena.new(self)
    _crates = Crates.new(self)
    _combat = Combat.new(self)
    _ult = Ultimates.new(self)
    _items = Items.new(self)
    _life = Lifecycle.new(self)
    _roul = Roulette.new(self)
    _move = Movement.new(self)
    _cpu = CpuAI.new(self)

func step_tick(command: Dictionary, dt: float = FIXED_DT) -> void:
    # 호출 순서는 현재와 정확히 동일하게 유지
    if result != &"playing":
        _life.update_post_match_visuals(dt)
        return
    tick += 1
    # ... (기존과 동일한 순서)
    _life.update_timers(dt)
    _items.update_item_pulses(dt)
    _life.update_safe_zone(dt)
    _move.apply_human(command)
    _move.apply_peer_humans()
    _life.tick_finish_cine(command, dt)
    _cpu.update_cpus(dt)
    _ult.tick_ox_charges(dt)
    _ult.apply_rat_tides(dt)
    _ult.tick_snake_skins(dt)
    _ult.tick_dragon_smokes(dt)
    _ult.tick_tiger_roars(dt)
    _ult.tick_rabbit_burrows(dt)
    _ult.tick_horse_kicks(dt)
    _ult.tick_dog_rush(dt)
    _move.move_heroes(dt)
    _ult.tick_rooster_eggs(dt)
    _ult.tick_pig_muds(dt)
    _ult.tick_wool_shields(dt)
    _life.tick_downs(dt)
    _ult.sync_ult_clones(dt)
    _crates.update_health_pickups(dt)
    _crates.update_crate_orbs(dt)
    _life.update_respawns(dt)
    _move.update_knockouts(dt)
    _items.update_deployables(dt)
    _life.update_mid_tower(dt)
    _combat.update_projectiles(dt)
    _combat.update_zones(dt)
    _combat.update_effects(dt)
    _life.update_threat(dt)
    _life.check_end()
```

## 모듈의 world 참조 패턴

각 모듈은 생성 시 world 참조를 받아 저장한다:

```gdscript
# 모듈 예시 (roulette.gd)
class_name GangRoulette
extends RefCounted

var w  # GangGameWorld 참조

func _init(world) -> void:
    w = world

func tick_roulette(slot: int, dt: float) -> void:
    var h: Dictionary = w.heroes[slot]
    # w.rng, w.event_log, w.heroes 등을 통해 world 상태에 접근
```

이 패턴이면 모든 모듈이 같은 rng를 쓰고, 같은 상태를 조작하므로 결정론이 유지된다.

## 모듈 간 의존 관계

```
equipment_data  ← (의존 없음, 순수 데이터)
arena           ← (의존 없음, 순수 기하)
roulette        ← event_log, rng
crates          ← arena, event_log, rng, combat(이펙트)
movement        ← arena, equipment_data, combat(공격 호출)
combat          ← arena, equipment_data, event_log, rng, lifecycle(다운 처리)
items           ← arena, equipment_data, combat, event_log, rng
ultimates       ← combat, arena, event_log, rng
lifecycle       ← combat, arena, event_log, rng
cpu_ai          ← 거의 전부 (movement, combat, items, ultimates)
```

순환 의존은 없다. 모든 모듈이 world 파사드를 통해 다른 모듈의 함수를 호출하므로, 직접적인 모듈→모듈 참조는 발생하지 않는다.

## 분리 순서 (안전한 순서)

| 순서 | 모듈 | 이유 |
|---|---|---|
| 1 | `equipment_data.gd` | 의존 없음. 순수 데이터 조회. 분리해도 아무것도 안 깨진다 |
| 2 | `arena.gd` | 의존 없음. 순수 기하 유틸. 분리해도 안 깨진다 |
| 3 | `roulette.gd` | 자체 완결적. 의존이 rng/event_log뿐 |
| 4 | `crates.gd` | arena만 의존. 비교적 독립적 |
| 5 | `movement.gd` | arena, equipment_data 의존. combat 호출은 world 경유 |
| 6 | `combat.gd` | 가장 크지만 핵심. 여기까지 하면 전체의 60% 분리 완료 |
| 7 | `ultimates.gd` | combat 의존. 동물별 로직이 독립적이라 분리 자체는 기계적 |
| 8 | `items.gd` | combat, movement 의존 |
| 9 | `lifecycle.gd` | combat 의존. 타워/세이프존/승리 판정 |
| 10 | `cpu_ai.gd` | 마지막. 거의 모든 모듈을 호출하므로 다른 모듈이 먼저 안정화되어야 한다 |

**해커톤 최소 범위**: 1~3번(equipment_data, arena, roulette)만 분리해도 ~620줄이 빠져서 game_world.gd가 4300줄 → 충분한 개선이면서 위험이 낮다.

**현실적 권장**: 1~4번(+ crates)까지 하면 ~970줄이 빠져서 3950줄. 이 정도가 하루 안에 안전하게 할 수 있는 최대치다.

## 위험 평가

| 위험 | 설명 | 완화 |
|---|---|---|
| **결정론 깨짐** | rng 호출 순서가 바뀌면 시뮬이 달라진다 | 모듈이 자체 rng를 갖지 않고 world.rng를 공유. step_tick() 호출 순서를 그대로 유지 |
| **순환 참조** | 모듈 A가 모듈 B를 호출하고 B가 A를 호출 | 모든 교차 호출은 world 파사드 경유. 직접 모듈→모듈 참조 없음 |
| **누락된 함수** | 분리 시 함수를 빠뜨리면 런타임 에러 | 분리 후 Godot --headless --quit로 파싱 에러 확인 |
| **combat.gd 분리 복잡도** | _damage_hero가 159줄이고 부수 효과가 많다 | combat은 후순위(6번)로 미루고, 안정적인 것부터 분리 |

## game_root.gd, net_world.gd, network_host.gd 영향

**영향 없음.** 이 세 파일은 `GangGameWorld`의 외부 인터페이스만 사용한다:

- `game_root.gd`: `WorldScript.new(seed)`, `world.step_tick(command)`, `world.reset()`, `world.set_mode()`, `world.heroes`, `world.local_slot` 등 — 전부 파사드에 남는다.
- `net_world.gd`: 스냅샷 파싱으로 world 상태를 덮어쓴다 — 내부 모듈 구조와 무관.
- `network_host.gd`: `build_snapshot()`이 world의 상태 변수를 읽는다 — 변수가 파사드에 남으므로 무관.

## 요약

| 항목 | 값 |
|---|---|
| 분리 대상 | 10개 모듈 |
| 파사드(game_world.gd) 잔여 | ~400줄 (상태 변수 + step_tick 오케스트레이션 + reset) |
| 외부 인터페이스 변경 | 없음 |
| 결정론 보장 방법 | world.rng 공유 + step_tick 호출 순서 유지 |
| 해커톤 최소 범위 | equipment_data + arena + roulette (620줄 분리, 위험 낮음) |
| 현실적 권장 | + crates (970줄 분리, 위험 낮음~중간) |
| 전체 완료 시 | 10개 모듈, game_world.gd는 ~400줄 파사드 |
