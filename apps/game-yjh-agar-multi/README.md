# game-yjh-agar-multi

agar.io 스타일 멀티 (서버 권위 + WebSocket). 마우스 이동.
같은 스크립트가 헤드리스면 서버(ws :9101), 브라우저면 클라이언트.

```bash
godot --headless --path . # 서버
godot --headless --export-release "Web" web/index.html # 클라 export 후 정적 서빙
```
