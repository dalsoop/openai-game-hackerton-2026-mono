# game-yjh-mine-run

지뢰밭 달리기 (서버 권위 + WebSocket, ws :9108).
줄마다 지뢰 2개가 숨은 격자를 클릭으로 한 줄씩 전진(대각 1칸까지).
밟으면 시작점 리셋 + 그 지뢰는 전원 공개 — 뒤에 가는 사람이 유리해지는 눈치 게임.
먼저 결승선에 닿으면 라운드 승, 새 지뢰밭 재생성. 2인 이상(파티게임).

```bash
godot --headless --path . # 서버
godot --headless --export-release "Web" web/index.html
```
