# 0006. Cloudflare 캐시 퍼지 실패가 helm 배포를 막지 않는다

- 날짜: 2026-08-28 (커밋 c91d098·ad49666에서 퍼지를 helm 게이트로 만들었다가 b451e09에서 되돌림)
- 상태: 채택

## 배경

배포 후 브라우저가 옛 Godot 엔진을 쓰는 문제를 막으려고 Cloudflare 퍼지를 helm의 필수 단계로 만들었다. 그런데 `dagul-prod.external.kr`은 Cloudflare DNS 전용 레코드라 HTTP가 Cloudflare 엣지를 거치지 않는다. 퍼지는 응답을 바꾸지 못했고, 토큰이 없거나 거부되면 배포만 실패했다.

## 결정

오리진이 버전 쿼리 없는 Godot 파일에 `Cache-Control: no-store`와 `CDN-Cache-Control: no-store`를 붙이고, `?v=<해시>` 요청만 불변 캐시로 준다. 퍼지는 자격이 있으면 시도하되 없거나 401이어도 helm을 계속한다. `HACKERTONE_REQUIRE_PURGE=1`일 때만 실패로 본다.

## 검토한 대안

- 퍼지를 helm 게이트로 강제: DNS 전용 호스트에서는 효과가 없는데 배포만 막았다.

## 결과

- 캐시 신선도는 오리진 헤더와 매니페스트 해시가 책임진다. 버전 쿼리 없이 불변 캐시를 주는 변경은 금지된다.
- 레코드를 프록시(주황 구름)로 바꾸면 이 판단을 다시 해야 한다.
