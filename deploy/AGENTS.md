# deploy

## 맡는 일

슬롯을 k3s 클러스터에 올리는 모든 것이다.

- `chart/`: Helm 차트 하나로 전체 슬롯을 올린다. 공용 `web`(Caddy 프록시), 슬롯별 허브 StatefulSet·서비스·HPA, `dagul-prod` 정적 팩 Deployment(`hub-static`), Redis, 인그레스(`*.external.kr`)·TLS 발급자, 유지보수 페이지, ServiceMonitor·Prometheus 규칙·Grafana 대시보드 ConfigMap.
- `scripts/apply-apps.py`: `ship`(Godot 웹 익스포트 → 허브 이미지 빌드·푸시 → 웹 정적 파일 업로드 → 카탈로그 갱신)과 `helm`(태그 확인 → `helm upgrade` → 허브 스모크 → 퍼지 → Grafana 주석).
- `scripts/plant-apps.py`: `apps/*/hackertone.yaml`로 `chart/values-games.yaml`과 보드 `slots.json`을 만든다. 허브 이미지 태그는 이미지에 들어가는 입력 파일(Dockerfile, 패키지 파일, 소스 트리)의 해시다.
- `scripts/ci-plan.py`: 커밋 범위에서 바뀐 슬롯과 helm 필요 여부를 JSON으로 낸다.
- `scripts/lint-web.py`: 배포 대상 슬롯 웹의 tsc·eslint·vitest.
- `scripts/build-godot.sh`: Godot 웹 빌드 정본(테스트 → 익스포트 → 글루 정리 → 압축 → 매니페스트 → 소스 해시 스탬프).
- `scripts/status.py`: 공개 주소 조회. `scripts/purge-cache.py`: Cloudflare 퍼지.
- `scripts/test_ship_contracts.py`, `scripts/test_hub_scale.py`: 배포 계약 테스트.
- `usability/`: 개발 슬롯 중계 허브용 스모크·부하 CLI. `redis/`: 로컬 Redis. `web/`: 공용 프록시 이미지(Caddy). `env.yaml`: 환경 이름과 기본 이미지 태그.

## 맡지 않는 일

- 앱 코드와 앱 이미지 내용(각 슬롯 `Dockerfile`)은 슬롯 폴더가 맡는다.
- 클러스터 YAML을 `apps/` 아래에 두지 않는다. 슬롯은 `hackertone.yaml`로 선언만 한다.

## 불변 조건

- 배포 대상은 `apps/` 아래 `hackertone.yaml`이 있고 이름이 `server-` 또는 `dagul-`로 시작하는 폴더뿐이다. 수동 배포 입력은 `(server|dagul)-[a-z0-9-]+`만 받는다.
- `chart/values-games.yaml`은 생성물이다. 손으로 고치지 않고 `plant-apps.py`를 돌린다. Redis DB 번호는 한 번 배정되면 유지되고(`prod`는 1), 새 슬롯은 빈 번호를 받는다.
- `helm`은 이미지를 만들지 않는다. 심은 태그가 클러스터에 없으면 실패한다. 이미지를 바꾸려면 `ship`을 먼저 한다.
- 웹 정적 파일 업로드 뒤 `.export-hash` 기록이 실패하면 ship 전체가 실패한다.
- Cloudflare 퍼지 실패(자격 없음, 401)는 helm을 막지 않는다. `HACKERTONE_REQUIRE_PURGE=1`일 때만 실패로 본다. 빈 GitHub 시크릿으로 러너의 `CF_API_TOKEN`을 덮지 않는다.
- Harbor 푸시는 3회 시도하고, 실패하면 준비된 노드가 1개 이상일 때만 k3s-prod에 직접 적재하고 계속한다.
- `hub.terminationGracePeriodSeconds`(270)는 허브의 경기 드레인 시간(240초) 이상이어야 한다.
- `dagul-prod`의 `maxReplicas`(2)는 허브 설정의 목표 동접 ÷ 프로세스당 동접과 맞춘다. `test_hub_scale.py`가 이 값과 스케일 관련 템플릿 요소를 문자열로 확인한다.
- 원격 실행은 `pve` 호스트 또는 SSH 별칭 `pve-lan`을 전제로 짜여 있다. 이 경로는 2026-09-24에 퇴역했으므로, 새 경로를 정하기 전에는 `ship`·`helm`을 실행하지 않는다.

## 구현 패턴

- Python 스크립트는 표준 라이브러리만 쓴다. 하이픈이 든 파일 이름은 다른 스크립트와 테스트가 `importlib`로 불러 쓴다(예: `scripts/gd_test.py`가 `apply-apps.py`의 Godot 경로 탐색을 재사용).
- 계약 테스트는 스크립트를 import 해 함수 단위로 검사하거나, 차트·README 파일에 특정 문자열이 있는지 확인한다. 차트나 README 문구를 바꾸면 이 테스트가 깨질 수 있으므로 바꾼 뒤 반드시 돌린다.
- 외부 명령은 `subprocess`로 실행하고 원격은 `ssh -o BatchMode=yes`로 한다.

## 테스트

- `python3 deploy/scripts/test_ship_contracts.py`(59개), `python3 deploy/scripts/test_hub_scale.py`(4개). 커밋 훅과 `Apps`의 `plan` 잡이 둘 다 돌린다.
- 새 동작을 넣으면 `test_ship_contracts.py`에 묶음(`ShipPipeline`, `PurgeCacheGate`, `PlatformGodotPipeline` 등)별 케이스를 추가한다. 특히 실패를 경고로 낮추거나 경고를 실패로 올리는 변경은 반드시 테스트로 고정한다.
- `usability/` 부하는 먼저 `--dry-run`으로 계획을 확인한다.
