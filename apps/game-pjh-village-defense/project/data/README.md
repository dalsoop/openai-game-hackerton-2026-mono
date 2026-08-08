# 신 마을 지키기 데이터

- `game_config.json`: 실행 가능한 회색상자의 기술 계약.
- `cpu_profiles.json`: CPU 반응 지연·공정성·성격.
- `regression_seeds.json`: 헤드리스 회귀 시드.
- `design/`: 최종 게임을 체크리스트대로 확장할 때 사용하는 맵·룰·스폰·스킬 정답 데이터.

스타터 `game_world.gd`는 M0의 즉시 실행성을 위해 일부 값을 상수로 갖는다. M1 첫 작업은 상수를 `design/` JSON으로 이전하고 fail-fast 검증기를 붙이는 것이다.
