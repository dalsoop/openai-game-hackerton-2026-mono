# 0001. 로비는 React, 인게임만 Godot이 맡고 한 Node 프로세스로 서빙한다

- 날짜: 2026-08-25 (커밋 4560aed "Next.js 단일 허브 플랫폼")
- 상태: 채택

## 배경

그전에는 Godot 웹 앱이 로비와 방까지 직접 그렸다. Godot 웹 빌드는 수십 MB 규모라 로딩 중 브라우저가 멈췄고, 그동안 로비조차 쓸 수 없었다. 이를 피하려고 `custom_shell.html`에 HTML 로비를 넣는 우회책을 썼지만, Godot과 HTML 양쪽에 로비 상태가 생겨 상태가 꼬이고 같은 코드를 두 번 관리해야 했다. 게임을 하나 추가할 때마다 허브·로비·배포를 복제해야 하는 문제도 있었다.

## 결정

로비·방·대기실은 Next.js(React)가 즉시 보여 주고, Godot 웹 엔진은 경기 화면만 맡는다. Next.js 커스텀 서버와 Colyseus 허브를 한 Node 프로세스(`apps/dagul-prod/web/server.ts`)에 합쳐 페이지·WebSocket·Godot 팩을 같은 호스트에서 서빙한다. React와 Godot 사이의 데이터는 정해진 핸드오프 키와 DOM 이벤트로만 주고받는다.

## 검토한 대안

- Godot 안에 로비를 두는 기존 방식: 엔진 로딩이 끝나야 로비가 떠서 첫 화면이 멈추는 문제를 해결할 수 없었다.
- `custom_shell.html`에 HTML 로비를 넣는 우회: 상태가 두 곳에 생겨 꼬였고 코드가 이중이 되었다.

## 결과

- Godot 코드에 로비·방 UI나 로비 메시지를 다시 넣을 수 없다. `lint_gd.py`의 `lobby-verb`·`banned-file` 규칙이 막는다.
- 핸드오프 키는 `wire.ts`와 `web_contract.gd` 두 곳에 있고, 둘이 어긋나면 `check:contract`가 실패한다. 키를 바꿀 때는 반드시 양쪽을 함께 고친다.
- Next 빌드와 허브가 한 이미지·한 프로세스라 페이지만 따로 배포하거나 허브만 따로 재시작할 수 없다.
- 개발 슬롯(`server-pjh-dev1`, `server-fig-dev1`)은 이 구조로 옮겨지지 않았고 Godot 로비 + 중계 허브 구조로 남았다.
