# openai-game-hackerton-2026-mono

OpenAI 게임 해커톤 제출용 파티 게임 모노레포다. 제출 엔트리는 8인 개인전 난전 배틀로얄 "다굴" 하나이고, 운영 슬롯 `apps/dagul-prod`는 Next.js(React 로비)와 Colyseus 허브(TypeScript 권위 시뮬)를 한 Node 프로세스로 돌리고 경기 화면은 Godot 4.7.1 웹 빌드가 그린다.
팀원 세 명이 각자 개발 슬롯을 두는 소규모 해커톤 프로젝트다. `apps/` 아래 폴더 이름이 곧 `https://<폴더>.external.kr/` 서브도메인이다.

## 프로젝트 구조

```text
openai-game-hackerton-2026-mono/
├── CLAUDE.md                         ← 에이전트 진입점 (AGENTS.md 와 같은 내용)
├── AGENTS.md                         ← 에이전트 진입점
├── docs/
│   ├── architecture.md               ← 슬롯·허브·Godot·클러스터 구성과 요청 흐름
│   ├── business-rules.md             ← 방·PIN·대기실·재접속·경기 판정 규칙
│   ├── security.md                   ← 게스트 신원, 권한 표, 공개 엔드포인트, 자격 증명
│   ├── standards.md                  ← 커밋 금지 대상, 머지 전 게이트, 정본 지도, GD 린트 규칙
│   ├── engineering-notes.md          ← Colyseus·Godot 웹·캐시 함정과 반복 작업 체크리스트
│   ├── operations.md                 ← 로컬 실행, 검증 명령, 환경 변수, 배포 흐름과 현재 상태
│   ├── contracts.md                  ← HTTP·Colyseus 메시지·핸드오프 키·hackertone.yaml 계약
│   └── tracking/
│       ├── status.md                 ← 기능별 구현·검증 상태와 남은 일
│       ├── findings.md               ← 미해결 문제
│       └── decisions/
│           ├── index.md              ← 결정 기록 목록
│           └── 0001~0007-*.md        ← 개별 결정 기록
├── apps/
│   ├── dagul-prod/
│   │   ├── web/AGENTS.md             ← 허브 프로세스(Next.js + Colyseus + TS 시뮬)
│   │   └── project/AGENTS.md         ← Godot 웹 클라이언트(core 셸 + games 모듈)
│   ├── server-pjh-dev1/AGENTS.md     ← 개발 슬롯(방장 권위 Godot + ws 중계 허브)
│   ├── server-fig-dev1/AGENTS.md     ← 개발 슬롯(같은 구조, 다른 팀원)
│   ├── server-board/AGENTS.md        ← 슬롯 현황 정적 페이지
│   ├── game-pjh-gang-up/             ← 다굴 원본 패키지. 읽기 전용
│   └── game-lhj-animal/              ← 팀원 신규 게임 스캐폴드와 기획 메모
├── deploy/AGENTS.md                  ← Helm 차트, ship·helm 스크립트, 배포 계약 테스트
└── tools/
    └── godot-touch-controls/AGENTS.md ← 모든 슬롯이 링크로 공유하는 터치 애드온
```

## 절대 규칙

1. `apps/game-pjh-gang-up/`은 수정하지 않는다. 규칙과 수치는 읽어서 다른 슬롯에 옮겨 구현한다.
2. Godot 웹 익스포트 산출물(wasm·pck·압축본·매니페스트)과 Colyseus GDExtension 바이너리, 토큰·비밀번호·키 파일을 커밋하지 않는다.
3. `docs/standards.md`의 머지 전 게이트(GD 래칫 린트, GD 테스트, 배포 계약, 웹 tsc·eslint·schema·vitest·check:contract)를 통과하지 않은 변경, 그리고 브라우저에서 Godot이 로드되지 않는 변경은 머지하지 않는다. 래칫 기준값(`lint_gd_baseline.json`)을 올려 통과시키지 않는다.
4. React↔Godot 계약 키는 `apps/dagul-prod/web/lib/contract/wire.ts`에서 먼저 바꾸고 `project/core/contract/web_contract.gd`를 맞춘다. Godot 코드는 소켓을 직접 열지 않고 페이지 브릿지로만 통신한다.

## 작업 전에 읽을 것

- 모든 작업: `docs/standards.md`, `docs/engineering-notes.md`, 작업할 폴더의 `AGENTS.md`.
- 방·좌석·PIN·방장 권한을 바꿀 때: `docs/business-rules.md`의 "PIN과 방 열고 닫기", "연결 끊김과 좌석 이어받기"와 `docs/security.md`의 권한 표·엔진 보조 세션 항목.
- 경기 규칙·수치를 바꿀 때: `docs/business-rules.md`의 "경기 규칙", `apps/dagul-prod/web/AGENTS.md`의 시뮬 패턴, 그리고 조작감 수치 기록 규칙(`docs/standards.md` 기록 규칙).
- Colyseus 스키마나 스냅 필드를 추가할 때: `docs/engineering-notes.md`의 64필드 한도·인코더 버퍼 항목과 `docs/contracts.md`의 방 상태 스키마.
- 개발 슬롯과 운영 슬롯 사이에서 코드를 옮길 때: `docs/engineering-notes.md`의 "슬롯 사이의 코드 이동".
- 배포·차트·Redis·캐시를 건드릴 때: `docs/operations.md`의 "배포" 절(현재 배포 경로가 없다는 사실 포함), `deploy/AGENTS.md`, `docs/tracking/decisions/`의 0004~0007.
- `.claude/` 아래 설정과 스킬, `README.md`·`deploy/README.md` 같은 기존 안내 문서는 삭제된 슬롯과 퇴역 호스트를 가리키는 부분이 있다. 그 안내와 코드가 다르면 코드가 기준이다.

## 문제를 발견하면

아래 상황은 즉시 사용자에게 알린다.

- 잠긴 방의 PIN이나 게스트 키가 방 밖 사람에게 드러나거나, 남의 좌석을 증명 없이 가져갈 수 있는 경로를 새로 발견했을 때
- 토큰·비밀번호·SSH 키가 커밋되었거나 커밋될 뻔했을 때
- `apps/game-pjh-gang-up/`이 수정되었을 때
- `main`에 머지된 변경 때문에 `dagul-prod`의 Godot이 브라우저에서 로드되지 않거나 방 입장이 전부 실패할 때
- 배포 스크립트가 퇴역한 호스트(`pve`, `pve-lan`)나 알 수 없는 클러스터로 명령을 보내려 할 때

그 밖의 문제는 해결을 시도하고, 이번 작업에서 해결할 수 없으면 `docs/tracking/findings.md`에 "조건 → 현상, 영향, 지금 해결하지 못하는 이유, 가능한 접근" 형식으로 기록한다.
