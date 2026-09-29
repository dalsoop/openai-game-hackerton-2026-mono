# apps/server-board

## 맡는 일

배포 슬롯 현황을 한 화면에 보여 주는 정적 페이지다. 허브가 없고(`hub.enabled: false`), `project/web/`의 파일을 공용 `web` 프록시가 그대로 서빙한다. 주소는 `https://server-board.external.kr/`이다.

- `index.html`: `./slots.json`을 읽어 슬롯 카드를 그리고, 각 슬롯 주소를 조회해 상태를 표시한다.
- `monitor.html`: 허브 슬롯들의 `/gang-up/status`를 순서대로 조회하는 모니터 화면이다.
- `slots.json`: 슬롯 카탈로그. 생성물이다.

## 맡지 않는 일

- 배포를 실행하거나 클러스터 상태를 바꾸지 않는다. 읽기 전용 화면이다.
- 슬롯 목록의 정본이 아니다. 정본은 각 슬롯의 `hackertone.yaml`이다.

## 불변 조건

- `slots.json`은 `python3 deploy/scripts/plant-apps.py`가 쓴다. 손으로 고치지 않는다. 슬롯을 추가·삭제·개명하면 스크립트를 다시 돌리고 결과를 함께 커밋한다.
- 이 폴더의 `project/web/`은 다른 슬롯과 달리 git에 커밋되는 정적 파일이다(`.gitignore`의 예외 규칙). 여기에 Godot 산출물을 두지 않는다.
- 페이지는 외부 스크립트 없이 단일 HTML로 동작한다. 조회는 `cache: "no-store"`로 한다.

## 구현 패턴

- `monitor.html`은 조회 대상 목록(`SERVERS`)을 파일 안에 직접 적는다. 현재 목록에는 삭제된 `server-yjh-dev1`이 남아 있고, `/gang-up/status`를 제공하지 않는 `dagul-prod`도 들어 있다. 목록을 바꿀 때는 조회 경로가 실제로 있는 슬롯만 넣는다.
- 조회는 한 번에 하나씩, 3초 타임아웃으로 한다. 동시에 모두 조회하면 브라우저 스레드가 막혔다(2026-08-23 수정).

## 테스트

- 자동 테스트는 없다.
- 바꾼 뒤 로컬에서 `project/web/`을 정적 서버로 띄워 `index.html`과 `monitor.html`이 콘솔 오류 없이 뜨는지 본다.
