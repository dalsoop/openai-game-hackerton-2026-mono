# game-yjh-croc-teeth

악어 이빨 룰렛 3D (서버 권위 + WebSocket, ws :9105).
돌아가며 이빨을 하나씩 클릭 — 지뢰 이빨을 누르면 악어가 덥썩 물어 그 사람 패배.
물린 사람이 다음 라운드 선공, 물린 횟수가 적을수록 승리. 2인 이상 필수(파티게임).
마우스 클릭.

```bash
godot --headless --path . # 서버
godot --headless --export-release "Web" web/index.html # 클라 export 후 정적 서빙
```
