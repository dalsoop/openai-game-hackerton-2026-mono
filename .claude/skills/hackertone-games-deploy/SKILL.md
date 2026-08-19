---
name: hackertone-games-deploy
description: >-
  apps/server-* 폴더를 https://<folder>.external.kr 에 붙인다.
  apply-apps.py, status.py, Helm, 호스트, 배포 확인에 쓴다.
---

# 배포

에이전트는 루트 `AGENTS.md` 다음 이 파일을 읽는다.

`apps/server-<이름>/` → `https://server-<이름>.external.kr/`

`game-*` 는 올리지 않는다. 방 서버는 `hub.enabled` 폴더마다 Dockerfile 이미지와 프로세스가 따로다. 빈 슬롯은 `web.enabled: false` 로 둔다.

허브는 `apps/` 푸시 후 `.github/workflows/apps.yml` (`Apps ship`). Godot 웹은 gitignore다. `python3 deploy/scripts/apply-apps.py web <폴더>`로 올린다. Helm은 Apps ship만 돌린다.
