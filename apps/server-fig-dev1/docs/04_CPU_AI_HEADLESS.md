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
