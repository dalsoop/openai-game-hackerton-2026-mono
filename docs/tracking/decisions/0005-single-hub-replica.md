# 0005. 운영 허브는 평소 1복제로 두고 자동 확장 상한을 2로 둔다

- 날짜: 2026-08-26 (커밋 9988a93에서 20복제 시도, f8f4879에서 1복제로 되돌림)
- 상태: 채택

## 배경

동접 1만을 가정하고 Colyseus 공식 확장 경로(Redis presence, `publicAddress`)와 20복제를 켰다. 차트가 20복제와 Redis PVC 2Gi 확장을 시도했고, Helm 업그레이드가 실패하며 노드가 넘쳤다.

## 결정

허브는 평소 1복제다. 다중 복제 경로(Redis presence·driver, Pod별 직접 WebSocket 주소 `/hubp/<pod>`, 정적 팩 전용 Pod)는 코드와 차트에 남겨 두고, `dagul-prod`만 CPU 기준 HPA로 최대 2복제까지 허용한다. Redis PVC는 기존 1Gi를 유지한다.

## 검토한 대안

- 20복제 상시 운영: 단일 노드 클러스터 자원을 넘어 Helm 실패와 노드 과부하가 났다.

## 결과

- 허브 한 프로세스의 한계(목표 500 동접, 전역 입장 한도 기본 100)가 서비스 용량이다.
- 복제 상한을 올리려면 `HUB_CONFIG`의 `targetCcu`·`perProcessCcu`, 차트 `maxReplicas`, `test_hub_scale.py`를 함께 바꾼다.
