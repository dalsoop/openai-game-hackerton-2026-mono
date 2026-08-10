# game-yjh-balloon-pump

풍선 펌프 룰렛 (서버 권위 턴제 + WebSocket, ws :9106).
자기 턴에 최소 1번 펌프(+1점), 욕심내면 계속 누를 수 있다 — 랜덤 한계에서 빵 터지면 -5점.
클릭/스페이스=펌프, 엔터/버튼=패스. 2인 이상(파티게임). 점수 높은 사람이 승.

```bash
godot --headless --path . # 서버
godot --headless --export-release "Web" web/index.html
```
