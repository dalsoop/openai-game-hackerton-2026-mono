# deploy/

정본은 `apply-apps.py`이다. 이 Mac에서 PVE SSH가 되면 로컬에서 돌리고, 아니면 `pve-hackertone` 러너에 `workflow_dispatch`로 같은 명령을 보낸다. 푸시만으로는 이미지를 만들지 않는다. wasm/pck는 git에 넣지 않는다.

- 보드: `https://server-board.external.kr/`
- 올리기: Actions `Apps`를 `workflow_dispatch`로 실행. 폴더만 넘긴다.
- 퍼지: `helm`이 끝난 뒤 자동. main에 `apps/`·`deploy/`가 푸시되면 Actions도 한 번 더 지운다.

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
