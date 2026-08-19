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
