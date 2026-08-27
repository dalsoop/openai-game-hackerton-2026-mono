# deploy/

정본은 `apply-apps.py`이다. main에 `apps/server-*`가 푸시되면 `pve-hackertone`이 바뀐 폴더만 ship 하고 helm 한다. wasm/pck는 git에 넣지 않는다.

- 보드: `https://server-board.external.kr/`
- 올리기: 푸시가 정본. 폴더를 지정해 다시 올리려면 Actions `Apps` `workflow_dispatch`.
- 퍼지: `helm`이 끝난 뒤 시도한다. 실패해도 helm 은 통과한다.

Helm은 이미지를 만들지 않는다. 바꾼 슬롯만 ship 한 뒤 helm 한다.
Harbor `docker push` 가 실패하면 ship 을 끝내지 않는다. `k3s ctr import` 는 그 노드 보강일 뿐 레지스트리를 대체하지 않는다.
웹 슬롯은 apply 전에 `tsc --noEmit` 과 eslint 를 통과해야 한다.

## 한 번만 붙이면 되는 것

1. `docker`와 `pve-lan`(또는 PVE 본기) SSH. Godot 4.7.1이 없으면 ship이 받아서 웹을 익스포트한다.
2. `dagul-prod.external.kr` 는 Cloudflare DNS-only(회색 구름)다. HTTP 가 엣지를 거치지 않으므로
   Cache Purge 가 응답을 바꾸지 않는다. 무버전 Godot 파일은 origin 이 `Cache-Control: no-store` 와
   `CDN-Cache-Control: no-store` 를 붙인다. `?v=해시` 만 불변 캐시다.
   퍼지 스크립트는 자격이 있으면 돌리고, 없거나 401이어도 배포를 막지 않는다.

## 웹 캐시

wasm·pck는 브라우저가 들고 있다. 무버전 URL 은 no-store 라 강력 새로고침이 기본 경로가 아니다.
자기 브라우저만 이상하면 `Cmd+Shift+R` 이면 된다.

허브 스모크·부하는 `deploy/usability/` 이다. `node cli.mjs smoke`, 부하는 먼저 `--dry-run`.

```bash
python3 deploy/scripts/apply-apps.py ship dagul-prod
python3 deploy/scripts/apply-apps.py helm
```
