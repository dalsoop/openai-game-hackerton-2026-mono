# 0003. Godot 웹 빌드에서 Colyseus GDExtension을 빼고 페이지 브릿지로만 통신한다

- 날짜: 2026-08-25 (커밋 5b48c5b, 플랫폼 바이너리 추적 제외), 2026-08-27 (커밋 2db952f "cut GDExtension")
- 상태: 채택

## 배경

Godot이 Colyseus 방에 직접 붙도록 Colyseus GDExtension을 넣었다. 플랫폼별 바이너리 17개가 저장소에 들어가며 50MB가 넘는 파일로 GitHub GH001 경고가 났다. 웹에서는 GDExtension이 `index.side.wasm`을 동적으로 불러와야 했고, 없는 dylib를 열거나 WASM 메모리 접근 오류로 엔진이 죽었다.

## 결정

2026-08-25에 웹용 wasm 하나만 남기고 나머지 플랫폼 바이너리를 git 추적에서 뺐다. 2026-08-27에는 addon과 side.wasm 로더를 아예 제거했다. Godot의 네트워크는 React 페이지가 가진 Colyseus 소켓을 DOM 이벤트 브릿지로 빌려 쓴다.

## 검토한 대안

- GDExtension 직접 접속 유지: 웹에서 엔진 크래시가 재현되어 버렸다.

## 결과

- `addons/colyseus/plugin.cfg`, `core/net/lobby_state_schema.gd`를 다시 만들면 `lint_gd.py`가 실패하고, 웹 아키텍처 테스트가 GD 스키마 생성을 막는다.
- 경기 입력과 스냅이 모두 React를 한 번 거친다. Godot 쪽 `EngineSocket` 오토로드는 접속 함수가 비어 있는 채로 남아 있다.
- 서버 쪽 엔진 보조 세션 입장 경로는 남아 있다.
