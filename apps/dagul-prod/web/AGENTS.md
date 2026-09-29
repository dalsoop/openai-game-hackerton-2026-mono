# apps/dagul-prod/web

## 맡는 일

운영 슬롯의 허브 프로세스 전체다. 한 Node 프로세스(`server.ts`)가 Next.js 페이지(로비·방 만들기·대기실), Colyseus 방 `LobbyRoom`, TypeScript 권위 경기 시뮬(`lib/hub/match-*.ts`), Godot 팩 정적 서빙(`lib/godot/asset-server.ts`), 메타·메트릭 HTTP를 함께 띄운다. 운영 이미지는 이 폴더의 `Dockerfile`로 굽고 빌드 컨텍스트는 슬롯 루트(`apps/dagul-prod`)다.

## 맡지 않는 일

- Godot 인게임 렌더·입력·예측은 `../project`가 맡는다. 이 폴더에서 GDScript를 고치지 않는다. Godot과의 약속은 `lib/contract/wire.ts` 한 곳으로만 바꾼다.
- 클러스터 배포(Helm, 이미지 푸시)는 저장소 루트 `deploy/`가 맡는다.
- 개발 슬롯(`server-pjh-dev1`, `server-fig-dev1`)의 허브와 코드를 공유하지 않는다. 그쪽 `src/`를 import 하거나 복사해 오지 않는다.

## 불변 조건

- 로비 목록은 HTTP `GET /rooms`로만 제공한다. Colyseus 리스트 방을 만들지 않는다.
- 방장 전용 명령(`start`, `kick`, `set_password`, `room_toggle`, `set_game`)은 핸들러 첫머리에서 `client.sessionId === state.hostSessionId`를 확인한다. 이 확인 없이 방 상태를 바꾸는 핸들러를 추가하지 않는다.
- 게스트 키(`guestKey`)는 `LobbyRoom`의 비공개 `claims` 맵에만 둔다. 스키마 상태·메타데이터·로그·메트릭에 싣지 않는다.
- 사용자에게 보이는 문구는 `messages/{ko,en}.json`에, 서버 안내문은 `lib/hub/config.ts`의 `KO`에만 둔다. 다른 TS/TSX 파일에 한글 리터럴을 쓰면 `tests/architecture.test.ts`가 실패한다.
- 상태·이펙트 훅은 `hooks/`에서만 호출한다. `components/`와 `app/**/page.tsx`는 렌더만 한다.
- `@colyseus/schema` 클래스 하나의 필드는 64개 미만으로 유지한다.
- `HUB_CONFIG.shutdownDrainMs`를 바꾸면 차트의 `hub.terminationGracePeriodSeconds`가 그 값 이상인지 확인한다.
- 게임 id → 산출물 폴더 변환은 `lib/games/catalog.ts`의 `packOf`로만 한다. `/godot/${gameId}` 형태로 경로를 만들지 않는다.

## 구현 패턴

- `LobbyRoom.ts`는 얇은 파사드다. 대기실 로직은 `lobby-waiting.ts`, 경기 진행은 `lobby-play.ts`, 좌석 계산은 `lobby-seats.ts`, 경기 권위는 `match-authority.ts`에 있고, `LobbyBag`(타이머·권위 객체 묶음)을 넘겨 호출한다.
- 시뮬 모듈(`match-*.ts`)은 난수와 시계를 직접 쓰지 않는 결정론 코드다. 파일 머리 주석에 포팅 원본 GD 파일과 함수가 적혀 있다. 규칙을 바꿀 때 원본 주석과 상수 이름을 함께 갱신한다.
- 신뢰할 수 없는 입력(join 옵션, 메시지 페이로드)은 `room-options.ts`, `room-password.ts`, `guest-identity.ts`의 `parse*` 함수로 정규화한 뒤에 쓴다. 서버와 브라우저가 같은 함수를 쓴다.
- 서버 코드는 `@/` 경로 별칭을 쓰고, 이미지 빌드에서 `tsc-alias`와 `scripts/rewrite-dist-aliases.mjs`가 풀어 준다. 프로세스 시작 시 `alias-register.ts`가 `@/` 해석을 등록한다(개발은 `server.ts` 첫 줄 import, 운영 이미지는 `node -r ./dist/alias-register.js`). 이 등록이 빠지면 Colyseus 기동 시 모듈을 찾지 못한다.
- 환경 변수를 런타임에 다시 읽어야 하는 값(`DAGUL_SKILLS`, `DAGUL_CCU_CAP`)은 호출할 때마다 `process.env`를 읽는 함수로 만든다. 테스트가 환경 변수를 바꿔도 반영되게 하기 위해서다.

## 테스트

- 전체: `npx tsc --noEmit && npx tsc --project tsconfig.server.json --noEmit && npm run lint && npm run schema:check && npx vitest run && npm run check:contract`.
- 방 규칙은 `@colyseus/testing` 인메모리 서버로 `tests/rooms/`에서 검증한다. 방장 권한, PIN 예외(첫 입장자·이어받기), 닫힌 방 입장 거절, 유예 만료 후 좌석 제거, 이어받기 뒤 옛 세션 재접속 거절, 로딩 장벽 60초 퇴장을 바꾸면 해당 케이스를 추가하거나 고친다.
- 시뮬 변경은 `tests/match-*.test.ts`에 경계값(자기장 단계 전환 시점, 210초 동점 처리, 부활 3회 소진, 영웅 2명 미만일 때 승자 판정 생략)을 넣는다.
- 규칙 수준 계약(아키텍처·i18n 키 실존·JPEG 금지·GameId 경로 금지)은 `tests/architecture*.test.ts`가 소스 텍스트를 검사한다. 새 규칙을 코드로 강제하려면 여기에 추가한다.
- `tests/rooms/lobby-room.test.ts`의 이어받기 방장 케이스는 전체 실행에서 간헐적으로 실패한다. 실패하면 단독으로 다시 돌려 구분한다.
