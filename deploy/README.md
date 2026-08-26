# deploy/

정본은 `apply-apps.py`이다. main에 `apps/server-*`가 푸시되면 `pve-hackertone`이 바뀐 폴더만 ship 하고 helm 한다. wasm/pck는 git에 넣지 않는다.

- 보드: `https://server-board.external.kr/`
- 올리기: 푸시가 정본. 폴더를 지정해 다시 올리려면 Actions `Apps` `workflow_dispatch`.
- 퍼지: `helm`이 끝난 뒤 자동.

Helm은 이미지를 만들지 않는다. 바꾼 슬롯만 ship 한 뒤 helm 한다.

## 한 번만 붙이면 되는 것

1. `docker`와 `pve-lan`(또는 PVE 본기) SSH. Godot 4.7.1이 없으면 ship이 받아서 웹을 익스포트한다.
2. 퍼지용 `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_ID` (로컬 환경 또는 Actions 시크릿)

## 웹 캐시

wasm·pck는 브라우저가 들고 있다. 퍼지는 배포 흐름에서 자동이다. 자기 브라우저만 이상하면 강력 새로고침(`Cmd+Shift+R`)이면 된다.

허브 스모크·부하는 `deploy/usability/` 이다. `node cli.mjs smoke`, 부하는 먼저 `--dry-run`.

```bash
python3 deploy/scripts/apply-apps.py ship server-prod
python3 deploy/scripts/apply-apps.py helm
```
