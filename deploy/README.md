# deploy/

정본은 `apply-apps.py`이다. `main`에 `apps/server-*` 또는 `apps/dagul-*`가 푸시되면
`pve-hackertone`이 바뀐 폴더만 ship 하고 helm 한다. wasm/pck는 git에 넣지 않는다.

- 보드: `https://server-board.external.kr/`
- 올리기: 푸시가 정본. 폴더를 지정해 다시 올리려면 Actions `Apps` `workflow_dispatch`
  (`folders` 예: `dagul-prod`).
- 슬롯 URL: `https://<folder>.external.kr/`
- Grafana: `https://grafana.50.internal.kr/` 대시보드 UID `dagul-game` (허브 `/metrics` · ServiceMonitor 15s)

```bash
python3 deploy/scripts/test_ship_contracts.py
python3 deploy/scripts/apply-apps.py ship dagul-prod
python3 deploy/scripts/apply-apps.py helm
```

허브 스모크·부하는 `deploy/usability/`이다. `node cli.mjs smoke`, 부하는 먼저 `--dry-run`.

## Apps 잡 순서

`.github/workflows/apps.yml`이 한 줄이다.

1. **plan** (`ubuntu-latest`): `test_ship_contracts.py` 후 `ci-plan.py`가 올릴 폴더를 고른다.
2. **lint-web** (`ubuntu-latest`): `lint-web.py`가 `tsc --noEmit`(서버 tsconfig 포함)과 eslint를 돌린다.
   폴더가 없으면 skip 하고 성공한다. apply는 이 잡을 기다린다.
3. **apply** (`self-hosted, hackertone`): `apply-apps.py ship` 다음 `helm`. 동시성은 `apps-ship` 하나다.

로컬 커밋 훅도 `test_ship_contracts.py`를 돌린다. 웹 파일이 스테이지에 있으면 tsc·eslint·vitest까지 막는다.

## ship이 하는 일

슬롯마다 Godot 웹을 익스포트하고 허브 이미지를 굽는다.

1. GD 테스트 통과 뒤에 export. glue strip(`prepare-godot-export.mjs`) 뒤에 brotli/gzip.
   `index.side.wasm`은 압축하지 않는다. 원본보다 낡은 `.br`/`.gz`는 지운다.
2. 매니페스트와 stale 스탬프를 찍고 `public/godot`에 복사한다. 심링크는 이미지에 넣지 않는다.
3. `docker build` 후 Harbor `docker push`를 3회 시도한다.
   `harbor.50.internal.xz`는 러너 공인 DNS에서 이름이 없다.
   클러스터 노드가 1개이면 `k3s ctr import`로 계속하고, 0개이거나 2개 이상이면 ship을 끝내지 않는다.
4. 웹 정적 파일을 노드에 올린 뒤 `.export-hash`를 쓴다. 해시 기록이 실패하면 경고가 아니라 실패다.

Helm은 이미지를 만들지 않는다. 심은 태그가 클러스터에 있는지 확인하고, 허브 스모크를 돌린 뒤
Cloudflare 퍼지를 시도한다.

## 캐시와 퍼지

`dagul-prod.external.kr`는 Cloudflare DNS-only(회색 구름)다. HTTP가 엣지를 거치지 않으므로
Cache Purge가 응답을 바꾸지 않는다.

무버전 Godot 파일은 origin이 `Cache-Control: no-store`와 `CDN-Cache-Control: no-store`를 붙인다.
`?v=해시`만 불변 캐시다. 브라우저만 이상하면 `Cmd+Shift+R`이면 된다.

퍼지 스크립트는 자격이 있으면 돌리고, 없거나 401이어도 helm을 막지 않는다.
강제 실패는 `HACKERTONE_REQUIRE_PURGE=1`일 때만이다. 빈 GitHub 시크릿으로 러너 `CF_API_TOKEN`을
덮지 않는다.

## 테스트

계약 정본은 `deploy/scripts/test_ship_contracts.py`다. plan 잡과 커밋 훅이 돌린다.

| 묶음 | 내용 |
|---|---|
| `ShipPipeline` | kubectl 노드 수, Harbor 재시도, 단일 노드 ctr import, lint-web argv/tsc 순서, export-hash 실패 |
| `PurgeCacheGate` | 퍼지 호스트에 dagul-prod, 빈 env가 파일 토큰을 가리지 않음, 401, helm은 퍼지 실패에도 계속 |
| `PlatformGodotPipeline` | glue strip 뒤에 압축, apply가 lint-web을 기다림 |

Godot 발행 쪽은 `apps/dagul-prod/web`에서 vitest다.

```bash
cd apps/dagul-prod/web
npx vitest run tests/encoding-freshness.test.ts tests/serve-encoding.test.ts
```

낡은 `.br` 삭제, 고아 압축본, `godotCacheHeaders`의 `no-store`를 본다.

## 한 번만 붙이면 되는 것

1. `docker`와 `pve-lan`(또는 PVE 본기) SSH. Godot 4.7.1이 없으면 ship이 받아서 웹을 익스포트한다.
2. 노드를 둘 이상 쓰려면 Harbor를 내부 DNS에 올려 `docker push`가 성공해야 한다.
   지금 러너는 `1.1.1.1`로 `harbor.50.internal.xz`를 찾지 못한다.
