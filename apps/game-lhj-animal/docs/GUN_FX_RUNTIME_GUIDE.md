# 총기 FX 런타임 구성 가이드

## 목적

동물 캐릭터의 `Gun Socket`에 총기를 장착해도 캐릭터의 위치·회전·좌우 반전·스케일 변화에 머즐 플래시가 자연스럽게 따라가도록 구성한다. 발사 후 이동하는 탄환과 피격 임팩트는 월드 공간에 생성하여 부모 노드의 후속 변형으로 궤적이 틀어지지 않게 한다.

## 노드 구조

```text
Animal (Node2D)
└─ Sprite2D
   └─ Gun Socket (Node2D)
      └─ Gun (Node2D, Effect.gd)
         └─ MuzzleSocket (Node2D)
            └─ MuzzleFlash (Node2D)
               └─ Sprite2D
```

- 총기는 메인 씬이 아니라 각 동물의 `Sprite2D/Gun Socket` 아래에 인스턴스한다.
- `MuzzleSocket`은 총구 위치를 나타낸다. 무기 이미지를 바꾸면 이 노드의 위치부터 조정한다.
- 머즐 플래시는 총기 자식으로 유지하므로 동물의 스케일과 좌우 반전을 그대로 상속한다.
- 탄환과 임팩트는 현재 씬 루트에 월드 좌표로 생성한다. 생성 순간 `MuzzleSocket`의 절대 스케일을 복사한다.

## Inspector 아키타입

총기 최상위 노드의 `Effect Archetypes` 그룹에서 다음 값을 개별 설정한다.

| 속성 | 범위 | 역할 |
| --- | --- | --- |
| `MuzzleFlash Archetype Index` | Small / Medium / Large | 머즐 플래시 시트의 행 선택 |
| `Bullet Archetype Index` | Short / Standard / Long / Heavy | 탄환 시트의 행 선택 |
| `Impact Archetype Index` | Small / Medium / Large | 피격 임팩트 시트의 행 선택 |

`Bullet Visual Speed`는 연출용 탄환의 이동 속도이며 기본값은 `1400 px/s`다.

## 스프라이트 시트 규격

### 머즐 플래시

- 파일: `Art/Textures/Tex_Fx_MuzzleFlash_4x3.png`
- 가로 4칸, 세로 3칸
- 행: Small / Medium / Large
- 실제 재생 프레임 수: 2 / 3 / 4

### 탄환

- 파일: `Art/Textures/Tex_FX_Bullet_4x4_256x144.png`
- 전체 크기: 1024×576
- 셀 크기: 256×144
- 가로 4칸: 애니메이션 프레임
- 세로 4칸: Short / Standard / Long / Heavy
- 비행 중 네 프레임을 반복한다.

### 임팩트

- 파일: `Art/Textures/Tex_Fx_ImpactFlash.png`
- 전체 크기: 1024×768
- 셀 크기: 256×256
- 가로 4칸, 세로 3칸
- 행: Small / Medium / Large
- 실제 재생 프레임 수: 2 / 3 / 4

모든 FX 텍스처는 알파가 제거된 마젠타 원본에서 투명도를 복구하고 외곽의 흰색·마젠타 노이즈를 제거한 결과물을 사용한다. Godot에서는 픽셀 경계를 유지하기 위해 Sprite2D의 필터를 끈다.

## 발사 및 피격 연동

### 목표 지점까지 전체 FX 재생

```gdscript
gun.fire_visual_towards(target_global_position)
```

다음 순서로 동작한다.

1. 선택된 머즐 플래시 재생
2. 총구의 월드 위치에서 선택된 탄환 생성
3. 목표 지점까지 탄환 이동 및 4프레임 반복
4. 도착 지점에서 선택된 임팩트 재생

### 게임 충돌 지점에서 탄환 종료

탄환의 실제 충돌 판정은 게임플레이 시스템에서 담당한다. 충돌이 발생하면 활성 탄환에 다음을 호출한다.

```gdscript
bullet.hit_at(collision_global_position)
```

탄환이 해당 위치로 이동한 뒤 즉시 임팩트를 만들고 제거된다.

### 임팩트만 직접 재생

```gdscript
gun.play_impact_at(collision_global_position)
gun.play_impact_at(collision_global_position, custom_archetype_index)
```

두 번째 인자를 생략하면 총기의 `Impact Archetype Index`를 사용한다.

## 총기별 기본 배정

| 총기 | Muzzle | Bullet | Impact |
| --- | --- | --- | --- |
| M1911 | Small | Short | Small |
| Glock 18 | Small | Short | Small |
| MP5 | Medium | Short | Medium |
| Thompson | Medium | Standard | Medium |
| RPK | Large | Long | Large |
| M4A1 | Medium | Standard | Medium |
| AK-47 | Medium | Standard | Medium |
| 8번 총기 | Large | Long | Large |
| Double Barrel Shotgun | Large | Heavy | Large |
| SPAS-12 | Large | Heavy | Large |
| Winchester M1873 | Medium | Standard | Medium |
| M79 | Large | Long | Large |

## 관련 파일

- `Effect.gd`: 총기 최상위 Inspector 설정과 발사 FX 진입점
- `MuzzleFlash.gd`: 머즐 행 선택 및 프레임 재생
- `BulletVisual.gd`: 탄환 행 선택, 월드 이동, 충돌 종료
- `ImpactFlash.gd`: 임팩트 행 선택 및 일회성 재생
- `Art/Prebs/Effects/MuzzleFlash.tscn`
- `Art/Prebs/Effects/BulletVisual.tscn`
- `Art/Prebs/Effects/ImpactFlash.tscn`

## 검증

- Godot 4.7.1 headless editor 프로젝트 로드 성공
- 메인 씬 headless 런타임 실행 성공
- 12개 총기 씬에 세 아키타입 속성 저장 확인
