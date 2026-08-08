# 등산하기 — Godot 코드 구현 청사진

## 1. 목표

이 문서는 “대충 비슷하게 구현”하는 문서가 아니다. 파일 위치, 상태 소유권, 한 틱의 처리 순서, CPU 입력 방식, 렌더 브리지, 데이터 검증을 고정한다.

스타터 프로젝트는 한 파일에 일부 시스템을 합쳐 실행 가능성을 높였다. 실제 M1부터는 이 청사진대로 분리한다.

## 2. 최종 씬 트리

```text
  ├─ Main (Node)  # 부팅·매치 재시작·씬 수명 관리
  ├─ SimulationHost (Node)  # 60Hz 명령 수집과 GameWorld.step 호출
  ├─ WorldView (Node2D)  # 절벽·벽·낙석·등반자 회색상자 렌더
  ├─ Camera2D (Camera2D)  # 인간 추적, 사망 시 선두 생존자 관전
  ├─ WorldUi (Node2D)  # 깃발 구조 게이지·낙석 경고·비콘 표시
  ├─ Hud (CanvasLayer)  # 스테이지·생존자·벽 충전·도구 쿨다운
  ├─ Audio (Node)  # 경고·벽 붕괴·구조·클리어 큐
  └─ Telemetry (Node)  # 인과 사건·리플레이·재현 시드 기록
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
    stagedirector.gd
    climbersystem.gd
    wallsystem.gd
    bouldersystem.gd
    rescuesystem.gd
    toolsystem.gd
    mountcpusystem.gd
  ai/
    observation.gd
    memory.gd
    utility_brain.gd
    cpu_profile.gd
    mount_impossible_cpu.gd
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
| StageDirector | 5개 스테이지 초기화·성공·전멸 재시작 |
| ClimberSystem | 이동·벽 충전·생존·무적 |
| WallSystem | 설치 유효성·소유권·붕괴·도구 비용 |
| BoulderSystem | 차선 스폰·예고·경로·벽/등반자 충돌 |
| RescueSystem | 깃발·다인 채널·부활 |
| ToolSystem | 폭탄·마비·감속망·미끼·구조대 |
| MountCpuSystem | 진행·회피·구조·목 통과·관전 |

두 시스템이 같은 필드를 직접 수정하지 않는다. 예를 들어 피해는 AbilitySystem이 즉시 HP를 빼는 것이 아니라 `DamageRequest`를 생성하고, 피해 시스템이 정렬해 적용한다.

## 5. GameWorld 계약

```gdscript
class_name MountImpossibleGameWorld
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

- `stage_index`
- `stage_tick`
- `climbers`
- `walls`
- `boulders`
- `flags`
- `tool_zones`
- `summit_capture`
- `restart_ticks`
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

조작: **WASD 이동 · Space 벽 · Q 폭탄 · E 감속망 · G 구조 · R 재시작**

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
| boulder_warning | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| wall_built | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| wall_broken | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| climber_died | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| flag_spawned | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| rescue_started | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| rescue_completed | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| tool_used | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| summit_reached | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |
| team_wiped | EventLog에 tick·actor·target·cause_event_ids와 함께 기록 |

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
4. 한 명만 정상에 도달하면 성공하지만, 서로의 정상 행동이 사고를 키우는 협동 등반
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
