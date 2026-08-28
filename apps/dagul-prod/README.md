# dagul-prod

제출·운영 슬롯. 허브(Next.js + Colyseus, `web/`)가 배포 대상 전체다.

주소: `https://dagul-prod.external.kr/`

`web/`이 실제로 빌드·배포되는 유일한 이미지다(`hackertone.yaml`의 `hub.dockerfile: web/Dockerfile`).
과거 별도 WS 릴레이였던 루트 `src/`·`Dockerfile`·`public/`은 어떤 배포 경로에서도 쓰이지 않아 삭제했다.
