---
name: hackertone-games-deploy
description: >-
  apps/server-* 폴더를 https://<folder>.external.kr 에 붙인다.
  apply-apps.py, status.py, Helm, 호스트, 배포 확인에 쓴다.
---

# 배포

에이전트는 루트 `AGENTS.md` 다음 이 파일을 읽는다.

`apps/<폴더>/` → `https://<폴더>.external.kr/` (server-* · dagul-*)

`game-*` 는 올리지 않는다. 방 서버는 `hub.enabled` 폴더마다 Dockerfile 이미지와 프로세스가 따로다. `dev1`/`dev2`/`dev3`/`prod`는 웹과 허브가 켜져 있다.

`apps/server-*`를 main에 푸시하면 `pve-hackertone`이 바뀐 폴더만 ship 하고 helm 한다. wasm/pck는 git에 넣지 않는다.

파이프라인 순서·Harbor 단일 노드·퍼지·계약 테스트는 `deploy/README.md`가 정본이다.
