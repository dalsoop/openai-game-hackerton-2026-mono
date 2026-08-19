# apps/

폴더 이름이 곧 배포 서브도메인이다.

`apps/server-*` 만 배포된다. 푸시하면 `Apps ship`이 허브와 Godot 웹을 같이 올린다.

```text
game-pjh-gang-up/   다굴 Godot 원본. 크리엘(pjh). 수정하지 않음
server-yjh-dev1/    정한 개발환경 1. 지금 다굴이 여기
server-pjh-dev1/    크리엘 개발환경 1. 지금 다굴이 여기
server-pig-dev1/    Figix 개발환경 1. 지금 다굴이 여기
server-*-dev2/      그 사람의 개발환경 2
server-*-dev3/      그 사람의 개발환경 3
server-prod/        제출·운영 슬롯
server-board/       배포 보드. https://server-board.external.kr/
```

- `apps/server-yjh-dev1` → `https://server-yjh-dev1.external.kr/`
- `apps/server-pjh-dev1` → `https://server-pjh-dev1.external.kr/`
- `apps/server-pig-dev1` → `https://server-pig-dev1.external.kr/`

사람마다 `dev1`/`dev2`/`dev3`가 있다. 폴더마다 호스트와 허브가 따로다. 웹은 모두 켜져 있다. 작업은 `apps/` 안에서만 한다.

모드는 로비에서 고른다. 폴더를 모드마다 쪼개지 않는다.

`apps/`를 푸시하면 Actions `Apps ship`이 Godot 웹 익스포트·허브·Helm을 올린다. `project/web`의 wasm/pck는 git에 넣지 않는다.

상태는 `https://server-board.external.kr/` 이다. 파란 구슬은 노드에 파일이 있는 슬롯이다.
