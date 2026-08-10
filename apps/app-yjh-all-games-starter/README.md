# app-yjh-all-games-starter

모노레포의 모든 게임(`apps/game-*`)을 한 창에서 바로 체험하는 런처. Rust + egui GUI.

- `apps/` 를 스캔해 게임 카드 자동 나열 (`project.godot` 루트/`project/` 양쪽 지원)
- 접두사 `game-{작성자}` 별 섹션 그룹 (예: `game-pjh · 5종`, `game-yjh · 5종`) — 새 작성자가 규칙대로 추가하면 자동 반영
- 싱글: **플레이** 버튼 한 번 → Godot 창 실행
- 멀티(`-multi`): **서버 시작**(headless) + **클라 접속**(창) 분리 버튼, 인스턴스 수 표시
- 실행 중 프로세스 추적·전부 중지, 런처 종료 시 자식 프로세스 정리
- Godot 탐색: PATH `godot`/`godot4` → `/Applications/Godot.app`

## 실행 (개발)

```bash
cd apps/app-yjh-all-games-starter
cargo run --release
```

## 딸깍 실행 (배포 바이너리)

- **macOS**: `cargo install cargo-bundle` 후 `cargo bundle --release`
  → `target/release/bundle/osx/all-games-starter.app` 더블클릭 (dmg 도 같이 생성됨)
- **Windows**: `cargo build --release`
  → `target\release\app-yjh-all-games-starter.exe` 더블클릭 (콘솔 창 없음)

앱을 레포 밖으로 꺼내 실행하면 게임을 못 찾는데, 헤더의 **폴더 변경** 버튼으로
레포(또는 `apps/`)를 한 번 지정하면 `~/.app-yjh-all-games-starter` 에 저장돼 이후 자동 인식된다.

전제: Rust 툴체인, Godot 4 설치. 빌드 산출물(`target/`)은 커밋하지 않는다.
