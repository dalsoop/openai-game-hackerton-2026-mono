# server-yjh-dev1

정한(yjh) 본 작업 슬롯. Godot 클라와 방 허브가 여기 있다.

`apps/game-pjh-gang-up`는 크리엘(pjh) 원본이다. 그쪽은 수정하지 않는다.

주소: `https://server-yjh-dev1.external.kr/`

```bash
godot --path apps/server-yjh-dev1/project
cd apps/server-yjh-dev1/web && npm install && npm run dev
```

`npm run dev` 가 `deploy/redis/compose.yaml` 로 Redis 1대를 띄우고 `REDIS_URL=redis://127.0.0.1:6379` 로 붙는다. 클러스터의 공용 Redis 와 같다.

허브 헬스: `https://server-yjh-dev1.external.kr/health`  
로컬 허브: `ws://127.0.0.1:9120` · 웹은 같은 호스트 `/gang-up/ws`
