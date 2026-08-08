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
