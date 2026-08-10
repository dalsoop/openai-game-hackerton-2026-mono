# app-yjh-all-games-starter

모노레포의 모든 게임(`apps/game-*`)을 한 창에서 바로 체험하는 런처. Rust + egui GUI.

- `apps/` 를 스캔해 게임 카드 자동 나열 (yjh·pjh 공통, `project.godot` 루트/`project/` 양쪽 지원)
- 싱글: **플레이** 버튼 한 번 → Godot 창 실행
- 멀티(`-multi`): **서버 시작**(headless) + **클라 접속**(창) 분리 버튼, 인스턴스 수 표시
- 실행 중 프로세스 추적·전부 중지, 런처 종료 시 자식 프로세스 정리
- Godot 탐색: PATH `godot`/`godot4` → `/Applications/Godot.app`

```bash
cd apps/app-yjh-all-games-starter
cargo run
```

전제: Rust 툴체인, Godot 4 설치. 빌드 산출물(`target/`)은 커밋하지 않는다.
