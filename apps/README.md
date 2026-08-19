# apps/

폴더 이름이 곧 배포 서브도메인이다.

`apps/server-*` 만 배포된다. 허브는 푸시로 올라가고, Godot 웹은 따로 올린다.

```text
game-pjh-gang-up/   다굴 Godot 원본. 크리엘(pjh). 수정하지 않음
server-yjh-dev1/    정한 본 슬롯. Godot + 자기 허브
server-pjh-dev1/    크리엘 본 슬롯. Godot + 자기 허브
server-pig-dev1/    Figix 본 슬롯. Godot + 자기 허브
server-*-dev2/      보조 슬롯. 빈 자리
server-*-dev3/      보조 슬롯. 빈 자리
server-prod/        제출·운영 슬롯. 빈 자리
server-board/       배포 보드. https://server-board.external.kr/
```

- `apps/server-yjh-dev1` → `https://server-yjh-dev1.external.kr/`
- `apps/server-pjh-dev1` → `https://server-pjh-dev1.external.kr/`
- `apps/server-pig-dev1` → `https://server-pig-dev1.external.kr/`

`dev2`/`dev3`에 본게임을 통째로 복사하지 않는다. 허브(`src/` · Dockerfile)는 슬롯마다 따로 둔다. 작업은 `apps/` 안에서만 한다.

모드는 로비에서 고른다. 폴더를 모드마다 쪼개지 않는다.

`src/`와 Dockerfile을 푸시하면 Actions `Apps ship`이 허브와 Helm을 올린다. `project/web`의 wasm/pck는 git에 넣지 않는다. 익스포트한 뒤 아래처럼 올린다.

```bash
python3 deploy/scripts/apply-apps.py web server-yjh-dev1
```

상태는 `https://server-board.external.kr/` 이다. 파란 구슬은 노드에 파일이 있는 슬롯이다.
