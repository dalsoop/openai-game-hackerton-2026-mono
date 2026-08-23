---
name: hackertone-games-deploy
description: >-
  apps/server-* 폴더를 https://<folder>.external.kr 에 붙인다.
  apply-apps.py, status.py, Helm, 호스트, 배포 확인에 쓴다.
---

# 배포

에이전트는 루트 `AGENTS.md` 다음 이 파일을 읽는다.

`apps/server-<이름>/` → `https://server-<이름>.external.kr/`

`game-*` 는 올리지 않는다. 방 서버는 `hub.enabled` 폴더마다 Dockerfile 이미지와 프로세스가 따로다. `dev1`/`dev2`/`dev3`/`prod`는 웹과 허브가 켜져 있다.

`apps/` 푸시 후 `.github/workflows/apps.yml` (`Apps ship`)이 Godot 웹 익스포트·허브 이미지·Helm을 올린다. wasm/pck는 git에 넣지 않는다.
