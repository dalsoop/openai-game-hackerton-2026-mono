# deploy/usability

다굴 허브 사용성 점검. Godot 없이 WebSocket만 붙인다. 의존성은 Node 내장 `WebSocket`만 쓴다.

기본 대상은 `wss://server-yjh-dev1.external.kr/gang-up/ws` 이다. `GANG_UP_WS`로 바꿀 수 있다.

```bash
cd deploy/usability
node cli.mjs smoke
node cli.mjs smoke --url ws://127.0.0.1:9120
node cli.mjs load --dry-run
node cli.mjs load --rooms 2 --players 2 --seconds 6
node cli.mjs load --rooms 6 --players 4 --seconds 20 --force
```

`server-prod`는 `--allow-prod`가 없으면 부하를 걸지 않는다. 기본 한도보다 큰 방·인원·시간은 `--force`가 필요하다.

스모크는 health, 2인 create/join/start, 8인 스냅(빈 자리 CPU), ~50ms snap, ack 증가, 100ms 보간이 원시 텔레포트보다 작은지를 본다. 부하는 방 여러 개를 동시에 열고 입력을 밀어 넣은 뒤 snap 간격만 모은다.

결과는 `last-report.json`에 덮어 쓴다. 이 파일은 git에 넣지 않는다.
