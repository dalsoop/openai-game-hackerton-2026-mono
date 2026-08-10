# game-yjh-dodge

총알 피하기 생존 멀티 (서버 권위 + WebSocket, ws :9104).
총알이 2초마다 하나씩 늘어나 벽에 튕기며 쌓인다 — 제일 오래 버티는 사람이 이긴다.
각자 자기 화면(클라)으로 접속, 전멸 시 생존 시간 순위 정산 후 다음 라운드.
방향키/WASD 이동.

```bash
godot --headless --path . # 서버
godot --headless --export-release "Web" web/index.html # 클라 export 후 정적 서빙
```
