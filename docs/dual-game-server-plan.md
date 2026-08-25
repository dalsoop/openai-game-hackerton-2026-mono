# 듀얼 게임 + 서버 아키텍처 설계

3개 Godot 4 웹 멀티플레이어 게임을 하나의 서버에서 운영하는 계획.

---

## 1. 서버 아키텍처 (1000명 동시 대응)

### 1.1 부하 추정

| 게임 | 방 크기 | 동시 방 수 (1000명 기준) | 틱레이트 | 방당 대역폭 |
|---|---|---|---|---|
| 다굴 (Gang-Up) | 8명 | ~60방 (480명) | 시뮬 60Hz, 스냅 20Hz | ~80KB/s (델타 압축) |
| 뱀 (Snake Arena) | 50명 | ~6방 (300명) | 시뮬 30Hz, 스냅 15Hz | ~200KB/s |
| 헥스 (Hex Clash) | 6명 | ~37방 (220명) | 시뮬 10Hz, 스냅 5Hz | ~15KB/s |

총 대역폭: ~60×80 + 6×200 + 37×15 ≈ **6.5MB/s 송신** — 일반 VPS에서 충분.

### 1.2 CPU 추정

Godot 헤드리스의 CPU 사용은 시뮬레이션 복잡도에 비례한다.

- **다굴 1방**: 8명, 투사체/존/이펙트 다수 → 시뮬 1방 ≈ 코어의 2~3%
- **뱀 1방**: 50명, 단순 이동+충돌 → 시뮬 1방 ≈ 코어의 5~8%
- **헥스 1방**: 6명, 턴 기반에 가까운 낮은 틱레이트 → 시뮬 1방 ≈ 코어의 0.5%

총 CPU: 60×3% + 6×8% + 37×0.5% ≈ **247%** → **4코어**면 여유 있음.

### 1.3 메모리 추정

- Godot 헤드리스 프로세스 기본: ~80MB
- 방당 추가 메모리: 다굴 ~2MB, 뱀 ~5MB, 헥스 ~1MB
- 총: 3프로세스×80MB + 60×2 + 6×5 + 37×1 = **240 + 120 + 30 + 37 ≈ 430MB**
- Node.js 허브: ~100MB
- **총 ~600MB** → 2GB RAM이면 충분, 4GB면 여유.

### 1.4 권장 VPS 스펙

| 항목 | 최소 | 권장 |
|---|---|---|
| CPU | 4코어 | 8코어 |
| RAM | 4GB | 8GB |
| 대역폭 | 100Mbps | 1Gbps |
| 비용 | $20~40/월 | $40~80/월 |

Hetzner CX31(4코어/8GB, €8.5/월) 또는 Contabo VPS M(6코어/16GB, €8/월)이면 1000명을 넉넉히 커버한다.

### 1.5 프로세스 구조

```
하나의 VPS
├── Node.js 허브 (포트 8080)
│   ├── /gang-up     → 다굴 로비/채팅
│   ├── /snake        → 뱀 로비
│   └── /hex          → 헥스 로비
│
├── Godot 헤드리스: 다굴 (포트 9121/9122)
│   └── 프로세스 내 다중 매치 (최대 60방)
│
├── Godot 헤드리스: 뱀 (포트 9123/9124)
│   └── 프로세스 내 다중 방 (최대 10방)
│
└── Godot 헤드리스: 헥스 (포트 9125/9126)
    └── 프로세스 내 다중 매치 (최대 50방)
```

각 게임은 **별도 Godot 프로세스**로 격리한다. 하나가 크래시해도 다른 게임에 영향 없음. Node.js 허브는 하나로 통합하되, 경로(pathPrefix)로 게임을 구분한다.

### 1.6 로드 밸런싱

1000명 수준에서는 **불필요**하다. 단일 VPS로 충분. 수평 확장이 필요해지는 시점은 5000명+ 부터이며, 그때는:
- 게임별로 별도 VPS 분리
- 허브에서 게임 서버 URL을 동적으로 할당
- Redis로 방 상태 공유

### 1.7 WebSocket 연결 수 제한

- Linux 기본: 파일 디스크립터 1024 → `ulimit -n 65535`로 올림
- Node.js ws 라이브러리: 제한 없음 (OS 한도까지)
- Godot WebSocketMultiplayerPeer: 제한 없음 (OS 한도까지)
- 1000명 × 2 연결(허브+게임) = 2000 WebSocket → **문제 없음**

### 1.8 Caddy 리버스 프록시

```
*.external.kr {
    # 웹 정적 파일 (Godot WASM)
    handle /gang-up/* {
        reverse_proxy 127.0.0.1:8080
    }
    handle /snake/* {
        reverse_proxy 127.0.0.1:8080
    }
    handle /hex/* {
        reverse_proxy 127.0.0.1:8080
    }
    
    # 게임 WebSocket
    handle /game-ws/gangup {
        reverse_proxy 127.0.0.1:9121
    }
    handle /game-ws/snake {
        reverse_proxy 127.0.0.1:9123
    }
    handle /game-ws/hex {
        reverse_proxy 127.0.0.1:9125
    }
}
```

---

## 2. 뱀 게임 (Snake Arena)

### 2.1 컨셉

slither.io 스타일 멀티플레이어 뱀 게임. 오픈 월드, 한 방에 50~100명. 먹이를 먹어 길이를 늘리고, 다른 뱀의 몸통에 부딪히면 사망하여 먹이로 변환된다. 부스트로 가속하되 길이가 줄어든다.

### 2.2 핵심 메카닉

| 메카닉 | 설명 |
|---|---|
| 이동 | 마우스/터치 방향으로 일정 속도 이동. 몸통은 머리의 경로를 따라감 |
| 성장 | 먹이(orb)를 먹으면 길이+1, 점수+1 |
| 충돌 | 다른 뱀의 몸통에 머리가 닿으면 사망. 자기 몸통에는 안 죽음 |
| 부스트 | 클릭/탭으로 가속 (2배 속도). 가속 중 꼬리에서 먹이가 떨어짐 (길이 감소) |
| 사망 | 몸통 전체가 먹이로 변환. 큰 뱀을 잡으면 대량의 먹이 획득 |
| 리스폰 | 즉시 리스폰 (길이 3으로 재시작) |

### 2.3 서버 권위 모델

다굴과 동일한 패턴:
- 서버: 뱀 위치 업데이트, 충돌 판정, 먹이 스폰/수집
- 클라이언트: 방향 입력만 전송, 서버 스냅샷을 보간
- 틱레이트: 시뮬 30Hz, 스냅샷 15Hz
- 공간 해싱으로 충돌 최적화 (50명 × 평균 길이 50 = 2500 세그먼트)

### 2.4 기술 스택

- Godot 4 + GDScript + 웹 내보내기
- RefCounted 기반 시뮬레이션 (다굴 패턴)
- `_draw()`로 렌더링 (도형 기반 — 원으로 된 뱀 몸통)
- WebSocketMultiplayerPeer

### 2.5 예상 코드 규모

| 파일 | 줄 수 | 역할 |
|---|---|---|
| snake_world.gd | ~400 | 시뮬레이션 (이동, 충돌, 먹이, 부스트) |
| snake_renderer.gd | ~300 | 뱀/먹이/맵 렌더링 |
| snake_server.gd | ~120 | 헤드리스 서버 |
| snake_client.gd | ~100 | 클라이언트 네트워크 |
| snake_hud.gd | ~150 | 점수, 리더보드, 미니맵 |
| snake_root.gd | ~200 | 메인 루프, 입력 |
| 총 | **~1300줄** | 6개 파일 |

### 2.6 구현 난이도와 소요 시간

- 난이도: **중간** — 공간 해싱과 50명 동시 처리가 핵심 과제
- 소요: **2~3일** (다굴 서버 코어를 재활용하면)

---

## 3. 두 번째 게임 — 추천

### 후보 A: 헥스 클래시 (Hex Clash) — 영토 전쟁

**핵심 메카닉**: 6명이 육각형 격자 위에서 영토를 확장한다. 매 턴(1초) 자기 영토에 인접한 빈 칸 또는 적 칸을 클릭하여 점령. 점령에는 "병력"이 필요하고, 병력은 영토 크기에 비례하여 매 턴 자동 생산. 3분 후 가장 넓은 영토가 승리.

- **왜 Godot 웹에 적합**: 육각형 격자는 `_draw()`로 깔끔하게 그릴 수 있고, 턴 기반이라 틱레이트가 낮아 서버 부하가 최소. 6명이라 매칭이 빠름.
- **규모**: ~1000줄, 5개 파일
- **난이도**: 낮음~중간 (1.5~2일)
- **인상**: "간단한 규칙인데 전략이 깊다"는 인상. 실시간 영토 변화가 시각적으로 강렬함.

### 후보 B: 바운스 아레나 (Bounce Arena) — 물리 격투

**핵심 메카닉**: 8명이 원형 아레나에서 공(자기 캐릭터)을 조종. 다른 공을 밀어서 아레나 밖으로 떨어뜨리면 점수. 대시로 가속하여 충돌 에너지를 높임. 아레나가 점점 줄어듦. 마지막 생존 승리.

- **왜 Godot 웹에 적합**: 원+원 충돌만으로 구현 가능. 물리 시뮬이 단순(탄성 충돌). 시각적으로 공이 튕기는 게 재미있음.
- **규모**: ~800줄, 5개 파일
- **난이도**: 낮음 (1~1.5일)
- **인상**: 즉각적인 재미. 하지만 전략적 깊이가 얕을 수 있음.

### 후보 C: 잉크 워즈 (Ink Wars) — 스플래툰 2D

**핵심 메카닉**: 4 vs 4 팀전. 각 팀이 맵에 자기 색 잉크를 칠한다. 이동하면 발자국으로 칠해지고, 발사로 원거리에 칠할 수 있음. 3분 후 더 넓은 면적을 칠한 팀이 승리. 적 잉크 위에서는 이동 속도가 느려지고, 자기 잉크 위에서는 빨라짐.

- **왜 Godot 웹에 적합**: 픽셀 단위 잉크 맵은 Image 텍스처로 구현 가능. 도형 캐릭터 + 잉크 분사 이펙트. 팀전이라 사회적 재미가 있음.
- **규모**: ~1500줄, 7개 파일
- **난이도**: 중간~높음 (3~4일). 잉크 맵 동기화가 과제.
- **인상**: 가장 인상적이지만 구현 비용도 가장 높음.

### 최종 추천: **헥스 클래시 (Hex Clash)**

이유:
1. **구현 비용 대비 완성도가 가장 높다** — 1000줄, 1.5~2일이면 100점 완성 가능
2. **서버 부하가 가장 낮다** — 턴 기반이라 틱레이트 10Hz, 방당 CPU 0.5%
3. **시각적으로 인상적** — 육각형 격자 위에서 색이 실시간으로 번져나가는 건 도형 기반으로도 강렬
4. **해커톤 심사에서 차별화** — 배틀로얄(다굴) + io 게임(뱀) + 전략(헥스) = 장르 다양성
5. **규칙이 10초 안에 이해됨** — "빈 칸을 클릭해서 영토를 넓혀라. 3분 후 가장 넓은 사람이 승리"
6. **6명 매칭** — 8명보다 빠르게 방이 찬다

---

## 4. 모노레포 구조

```
openai-game-hackerton-2026-mono/
├── apps/
│   ├── server-yjh-dev1/          # 다굴 (기존)
│   │   ├── hackertone.yaml
│   │   ├── Dockerfile
│   │   ├── src/                   # Node.js 허브 (다굴용)
│   │   └── project/               # Godot 프로젝트
│   │
│   ├── snake-arena/               # 뱀 게임 (신규)
│   │   ├── hackertone.yaml        # id: snake-arena, pathPrefix: /snake
│   │   ├── Dockerfile
│   │   ├── src/                   # Node.js 허브 (뱀용, 다굴 src/ 포크)
│   │   └── project/               # Godot 프로젝트
│   │       └── scripts/
│   │           ├── snake_world.gd
│   │           ├── snake_renderer.gd
│   │           ├── snake_server.gd
│   │           ├── snake_client.gd
│   │           ├── snake_hud.gd
│   │           └── snake_root.gd
│   │
│   ├── hex-clash/                 # 헥스 클래시 (신규)
│   │   ├── hackertone.yaml        # id: hex-clash, pathPrefix: /hex
│   │   ├── Dockerfile
│   │   ├── src/                   # Node.js 허브 (헥스용, 다굴 src/ 포크)
│   │   └── project/               # Godot 프로젝트
│   │       └── scripts/
│   │           ├── hex_world.gd
│   │           ├── hex_renderer.gd
│   │           ├── hex_server.gd
│   │           ├── hex_client.gd
│   │           ├── hex_hud.gd
│   │           └── hex_root.gd
│   │
│   ├── server-board/              # 배포 보드 (기존)
│   └── server-prod/               # 운영 (기존)
│
├── deploy/
│   ├── chart/                     # Helm — 게임별 Deployment 템플릿
│   └── scripts/
│       └── status.py              # 전체 게임 상태 확인
│
├── shared/                        # 공유 코드 (신규, 선택)
│   ├── net/                       # 서버/클라이언트 기반 클래스 (GameServerBase, GameClientBase)
│   └── ui/                        # 공통 UI 테마/위젯
│
└── docs/
    ├── DESIGN.md
    └── dual-game-server-plan.md   # 이 문서
```

### 4.1 공유 vs 독립

| 요소 | 공유 | 독립 |
|---|---|---|
| Node.js 허브 코드 | 포크 후 게임별 커스텀 | 각 게임의 src/ |
| Godot 서버 기반 | 패턴만 공유 (별도 구현) | 각 게임의 project/ |
| UI 테마 | UiTheme.gd를 복사하여 사용 | 각 게임에서 커스텀 가능 |
| Dockerfile | 구조 동일, 포트만 다름 | 각 게임의 Dockerfile |
| Helm 차트 | 하나의 차트에 게임별 values | deploy/chart/ |
| hackertone.yaml | 동일 스키마, 값만 다름 | 각 게임의 yaml |

### 4.2 hackertone.yaml 예시

**뱀:**
```yaml
id: snake-arena
kind: game
title: 스네이크 아레나
blurb: 50인 실시간 뱀 배틀
players: 1–50
web:
  enabled: true
  exportDir: project/web
hub:
  enabled: true
  pathPrefix: /snake
  dockerfile: Dockerfile
```

**헥스:**
```yaml
id: hex-clash
kind: game
title: 헥스 클래시
blurb: 6인 실시간 영토 전쟁
players: 2–6
web:
  enabled: true
  exportDir: project/web
hub:
  enabled: true
  pathPrefix: /hex
  dockerfile: Dockerfile
```

### 4.3 구현 순서

| 순서 | 작업 | 소요 |
|---|---|---|
| 1 | 다굴 안정화 + 배포 확인 | 완료 |
| 2 | 뱀 게임 구현 (다굴 서버 패턴 재활용) | 2~3일 |
| 3 | 헥스 클래시 구현 | 1.5~2일 |
| 4 | 통합 허브 + Caddy 설정 + 배포 | 0.5일 |
| 5 | 전체 테스트 (3게임 동시 운영) | 0.5일 |

---

## 참고 출처

- [Gameye — Godot Dedicated Server Hosting](https://gameye.com/blog/godot-dedicated-server-hosting/)
- [Ziva — Godot 4 Multiplayer Best Practices](https://ziva.sh/blogs/godot-multiplayer)
- [600 Snakes on the Edge — Slither.io Server Implementation](https://dev.to/linmingren/600-snakes-on-the-edge-how-i-built-a-slitherio-server-with-trail-algorithms-spatial-hashing--24ca)
- [An Embarrassing Tale: Server Capacity](https://www.freecodecamp.org/news/an-embarrassing-tale-why-my-server-could-only-handle-10-players-3b83b6fa8136)
- [agar.io-clone Game Architecture](https://github.com/owenashurst/agar.io-clone/wiki/Game-Architecture)
- [Supercraft — Godot Dedicated Server Setup](https://crux.supercraft.host/blog/godot-multiplayer-dedicated-server-backend/)
- [Sourcerize — Godot 4 Multiplayer Web Capabilities](https://medium.com/@sourcerize/godot-4-experimenting-with-multiplayer-web-game-capabilities-1a8a23ced481)
