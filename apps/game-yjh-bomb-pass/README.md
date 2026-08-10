# game-yjh-bomb-pass

폭탄 돌리기 (서버 권위 실시간 + WebSocket, ws :9107).
심지 길이는 비밀 — 폭탄 든 사람이 다른 사람을 클릭해 넘기고, 터질 때 든 사람 폭사.
스파크가 빨라질수록 위험(힌트). 2인 이상(파티게임), 폭사 횟수 적을수록 승.

```bash
godot --headless --path . # 서버
godot --headless --export-release "Web" web/index.html
```
