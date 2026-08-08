# 등산하기 — P0/P1 완료 게이트

- P0: **121개**
- P1: **814개**
- P0 또는 P1 중 하나라도 미완료면 다음 공개 빌드·아트 교체·온라인 확장을 진행하지 않는다.
- 실제 상태 기록은 `CHECKLIST_VIEWER.html`, CSV 또는 팀 이슈 트래커 중 하나를 정답으로 정하고 중복 관리하지 않는다.

| ID | 등급 | 마일스톤 | 영역 | 항목 | 통과 기준 |
|---|---:|---|---|---|---|
| MT-COM-00001 | P0 | M0 | boot | 앱 최초 부팅 | Viewport가 2초 이내 생성되고 Output/Debugger 오류이 비어 있다 |
| MT-COM-00002 | P0 | M0 | loop | 60Hz 고정 틱 | 최종 상태 해시가 모두 동일하다 |
| MT-COM-00003 | P0 | M0 | rng | randf()/randi() 금지 | 시뮬레이션 경로에서 randf()/randi() 호출 0건 |
| MT-COM-00004 | P0 | M0 | input | 포커스 상실 키 해제 | 복귀 시 캐릭터가 계속 이동하지 않는다 |
| MT-COM-00005 | P0 | M0 | input | 우클릭 브라우저 메뉴 차단 | 브라우저 컨텍스트 메뉴가 뜨지 않고 게임 명령만 기록된다 |
| MT-COM-00006 | P0 | M0 | replay | 입력 리플레이 | 300틱 간격 모든 상태 해시가 일치한다 |
| MT-COM-00007 | P0 | M0 | data | 설정 해시 | 정규화된 configHash가 동일하다 |
| MT-COM-00019 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00020 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00021 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00022 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00023 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00059 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00060 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00061 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00062 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00063 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00099 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00100 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00101 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00102 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00103 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00139 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00140 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00141 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00142 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00143 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00179 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00180 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00181 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00182 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00183 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00219 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00220 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00221 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00222 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-COM-00223 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| MT-GD-0001 | P0 | M0 | boot | Godot 4.7.1 프로젝트 import | 스크립트·씬 import 오류 0건, Main Scene 지정 |
| MT-GD-0002 | P0 | M0 | boot | F5 최초 실행 | 2초 안에 회색상자 월드와 HUD가 표시되고 오류 0건 |
| MT-GD-0003 | P0 | M0 | boot | 독립 ZIP 의존성 | 외부 상대경로·공통 저장소 없이 실행 |
| MT-GD-0004 | P0 | M0 | loop | physics tick 60 고정 | 정확히 60 |
| MT-GD-0005 | P0 | M0 | loop | _process 판정 변경 금지 | _process에서 GameWorld의 판정 필드를 직접 변경하는 코드 0건 |
| MT-GD-0006 | P0 | M0 | loop | Godot 물리 콜백 순서 비의존 | 명령 정렬·커스텀 판정 결과 해시 동일 |
| MT-GD-0007 | P0 | M0 | rng | 시뮬레이션 randf/randi 금지 | 시드 RNG 래퍼 외 randf/randi/randomize 호출 0건 |
| MT-GD-0008 | P0 | M0 | rng | 시드 재현 | 300틱 간격 상태 해시 100% 일치 |
| MT-GD-0009 | P0 | M0 | input | edge 입력 1회 소비 | 기술 명령은 1회만 생성 |
| MT-GD-0010 | P0 | M0 | input | 포커스 상실 입력 해제 | 이동·공격 hold가 고착되지 않음 |
| MT-GD-0012 | P0 | M0 | viewport | 1600x900 논리 좌표 | 월드 판정 좌표 동일, 레터박스/확장 정책대로 표시 |
| MT-GD-0013 | P0 | M0 | camera | Camera2D와 HUD 분리 | CanvasLayer HUD는 화면에 고정 |
| MT-GD-0015 | P0 | M0 | render | 렌더 상태 역류 금지 | 다음 physics tick 판정에 영향 0 |
| MT-GD-0017 | P0 | M0 | scene | 씬 reload 없는 매치 재시작 | Node 수·메모리·시그널 연결 수가 기준 ±1% 이내 |
| MT-GD-0018 | P0 | M0 | scene | World 교체 후 이전 참조 제거 | 이전 World의 엔티티·이벤트가 보이지 않음 |
| MT-GD-0019 | P0 | M0 | data | JSON 문법과 스키마 | 파싱 오류·중복 ID·미존재 참조 0건 |
| MT-GD-0020 | P0 | M0 | data | 잘못된 데이터 fail-fast | 명확한 경로·키와 함께 부팅 중단, 조용한 기본값 대체 없음 |
| MT-GD-0021 | P0 | M0 | event-log | EventLog 순번 | event_id가 중복 없이 증가하고 tick/actor/target 포함 |
| MT-GD-0022 | P0 | M0 | invariant | NaN·INF 즉시 검출 | 불변식 오류와 시드·tick 덤프 후 테스트 실패 |
| MT-GD-0023 | P0 | M0 | headless | 헤드리스 smoke 진입 | 종료코드 0과 SMOKE_OK JSON 출력 |
| MT-GD-0024 | P0 | M0 | headless | 헤드리스 시간 독립 | 게임 판정이 렌더 노드 없이 완료 |
| MT-GD-0049 | P0 | M0 | starter | 스타터 조작 계약 | 각 입력의 즉시 피드백과 비용·쿨다운이 HUD/월드에 표시 |
| MT-GD-0050 | P0 | M0 | starter | 인간 1+CPU 구성 | 인간 1명과 CPU 5명이 생성되고 CPU가 목표 행동 시작 |
| MT-GD-0051 | P0 | M0 | starter | R 새 시드 재시작 | 즉시 새 World가 만들어지고 seed가 1씩 증가 |
| MT-COM-00008 | P0 | M1 | collision | NaN 방지 | 위치·속도·체력에 NaN/Infinity가 없다 |
| MT-GD-0025 | P0 | M1 | ai | CPU도 PlayerCommand 사용 | 인간과 동일 명령 스키마·검증·쿨다운 경로 사용 |
| MT-GD-0026 | P0 | M1 | ai-audit | CPU 숨은 상태 접근 감사 | Observation에 없던 값으로 행동이 바뀌지 않음 |
| MT-GD-0030 | P0 | M1 | performance | physics 프레임 예산 | p95 simulation step 8ms 이하 |
| MT-GD-0032 | P0 | M1 | replay | 명령 리플레이 | 최종 결과·중간 해시·중요 EventLog 동일 |
| MT-GD-0033 | P0 | M1 | replay | 리플레이 버전 거부 | 호환 불가 사유 표시 후 실행 거부 |
| MT-GD-0034 | P0 | M1 | ux | 실패 원인 5초 식별 | 80% 이상이 원인 행위자·사건을 5초 내 식별 |
| MT-GD-0037 | P0 | M1 | pause | 일시정지 tick 정지 | World tick·쿨다운·스폰이 증가하지 않음 |
| MT-GD-0053 | P0 | M1 | fun | 핵심 재미 사건 발생률 | 문서의 핵심 재미 사건이 목표 빈도 범위에 들어옴 |
| MT-GD-0054 | P0 | M1 | fun | 실패도 관전 가능 | 매치가 계속 진행되고 중요한 사건·승패 원인이 표시 |
| MT-COM-00010 | P0 | M2 | ai | 숨은 정보 금지 | 비가시 엔티티를 직접 action target으로 선택하지 않는다 |
| MT-COM-00011 | P0 | M2 | ai | 반응 지연 | 130ms 미만 반응 0건, 평균 175~270ms |
| MT-GD-0039 | P0 | M2 | export | Windows export 입력 유지 | 편집기와 조작·판정·결과 동일 |
| MT-GD-0043 | P0 | M2 | cleanup | 결과 확정 후 상태 고정 | 점수·HP·소유권·스폰 변화 0 |
| MT-GD-0045 | P0 | M2 | package | smoke/playability 회귀 검사 | 두 테스트가 오류 없이 종료 |
| MT-GD-0046 | P0 | M2 | package | 문서-코드 경로 정합 | 존재하지 않는 파일 0건 |
| MT-GD-0058 | P0 | M2 | acceptance | 최종 수락 지표 | 기능 오류 없이 핵심 재미가 최소 70% 판에서 체감되고 원인 로그 존재 |
| MT-COM-00013 | P0 | M3 | performance | 풀 누수 | 활성 수가 안정된 뒤 풀 총량이 10% 이상 증가하지 않는다 |
| MT-COM-00014 | P0 | M3 | performance | 시뮬레이션 오버런 | 최대 5틱 실행 후 잔여 누적을 버리고 입력 가능 |
| MT-COM-00017 | P0 | M4 | telemetry | 원인 이벤트 연결 | 손실 이벤트가 최대 6단계 원인으로 역추적 가능 |
| MT-00001 | P0 | MT-M0 | movement | 최고속도 도달 | 속도가 310±1에 도달하고 프레임률과 무관하다 |
| MT-00002 | P0 | MT-M0 | boulder | 낙석 즉사 | 같은 틱 dead_flag로 전환되고 사망 원인이 낙석 ID로 기록 |
| MT-00003 | P0 | MT-M1 | wall | 사망 시 소유 벽 붕괴 | 모든 자기 벽만 0.04초 간격으로 제거되고 타인 벽은 유지 |
| MT-00004 | P0 | MT-M1 | revive | 깃발 구조 | 사망자가 동일 슬롯으로 부활하고 0.65초 무적 |
| MT-00005 | P0 | MT-M1 | stage | 한 명 정상 도달 | 스테이지 성공하며 전원이 다음 스테이지에 생존 스폰 |
| MT-00006 | P0 | MT-M2 | item | 도구 벽 비용 | 벽 1개만 사라지고 범위 내 낙석만 제거 |
| MT-00007 | P0 | MT-M2 | item | 구조대 10벽 | 벽 10개와 쿨다운 소비, 깃발 3개 모두 부활 |
| MT-01410 | P0 | MT-M2 | item | 벽 양도 / valid / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01430 | P0 | MT-M2 | item | 벽 양도 / caster_dies / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01435 | P0 | MT-M2 | item | 벽 양도 / insufficient_walls / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01460 | P0 | MT-M2 | item | 폭탄 / valid / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01461 | P0 | MT-M2 | item | 폭탄 / valid / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01480 | P0 | MT-M2 | item | 폭탄 / caster_dies / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01481 | P0 | MT-M2 | item | 폭탄 / caster_dies / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01485 | P0 | MT-M2 | item | 폭탄 / insufficient_walls / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01486 | P0 | MT-M2 | item | 폭탄 / insufficient_walls / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01510 | P0 | MT-M2 | item | 마비침 / valid / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01511 | P0 | MT-M2 | item | 마비침 / valid / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01530 | P0 | MT-M2 | item | 마비침 / caster_dies / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01531 | P0 | MT-M2 | item | 마비침 / caster_dies / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01535 | P0 | MT-M2 | item | 마비침 / insufficient_walls / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01536 | P0 | MT-M2 | item | 마비침 / insufficient_walls / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01560 | P0 | MT-M2 | item | 감속망 / valid / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01561 | P0 | MT-M2 | item | 감속망 / valid / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01580 | P0 | MT-M2 | item | 감속망 / caster_dies / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01581 | P0 | MT-M2 | item | 감속망 / caster_dies / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01585 | P0 | MT-M2 | item | 감속망 / insufficient_walls / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01586 | P0 | MT-M2 | item | 감속망 / insufficient_walls / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01610 | P0 | MT-M2 | item | 가짜 낙석 / valid / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01611 | P0 | MT-M2 | item | 가짜 낙석 / valid / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01630 | P0 | MT-M2 | item | 가짜 낙석 / caster_dies / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01631 | P0 | MT-M2 | item | 가짜 낙석 / caster_dies / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01635 | P0 | MT-M2 | item | 가짜 낙석 / insufficient_walls / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01636 | P0 | MT-M2 | item | 가짜 낙석 / insufficient_walls / 벽 1 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01660 | P0 | MT-M2 | item | 구조대 / valid / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01663 | P0 | MT-M2 | item | 구조대 / valid / 벽 10 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01680 | P0 | MT-M2 | item | 구조대 / caster_dies / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01683 | P0 | MT-M2 | item | 구조대 / caster_dies / 벽 10 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01685 | P0 | MT-M2 | item | 구조대 / insufficient_walls / 벽 0 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-01688 | P0 | MT-M2 | item | 구조대 / insufficient_walls / 벽 10 | 명세의 대상·비용·취소 순서와 일치하고 중복 효과·음수 벽 수가 없다 |
| MT-GD-0011 | P1 | M0 | input | 키보드 동시입력 정규화 | 대각선 속도가 축 속도와 동일 |
| MT-GD-0014 | P1 | M0 | camera | 마우스 월드 좌표 역변환 | 조준점 오차 1 world unit 이하 |
| MT-GD-0016 | P1 | M0 | render | queue_redraw 호출 상한 | 월드·HUD 각각 physics tick당 최대 1회 |
| MT-GD-0052 | P1 | M0 | starter | 더미 아트 판정 가독성 | 색·형태·번호만으로 객체 역할과 소유자 식별 |
| MT-COM-00009 | P1 | M1 | camera | 레터박스 좌표 | 월드 좌표가 보이는 클릭 마커와 2px 이내 일치 |
| MT-COM-00259 | P1 | M1 | viewport | 960×540 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00260 | P1 | M1 | viewport | 960×540 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00261 | P1 | M1 | viewport | 960×540 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00262 | P1 | M1 | viewport | 960×540 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00263 | P1 | M1 | viewport | 960×540 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00264 | P1 | M1 | viewport | 960×540 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00265 | P1 | M1 | viewport | 960×540 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00266 | P1 | M1 | viewport | 960×540 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00267 | P1 | M1 | viewport | 960×540 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00268 | P1 | M1 | viewport | 960×540 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00269 | P1 | M1 | viewport | 960×540 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00270 | P1 | M1 | viewport | 960×540 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00271 | P1 | M1 | viewport | 960×540 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00272 | P1 | M1 | viewport | 960×540 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00273 | P1 | M1 | viewport | 960×540 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00304 | P1 | M1 | viewport | 1600×900 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00305 | P1 | M1 | viewport | 1600×900 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00306 | P1 | M1 | viewport | 1600×900 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00307 | P1 | M1 | viewport | 1600×900 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00308 | P1 | M1 | viewport | 1600×900 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00309 | P1 | M1 | viewport | 1600×900 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00310 | P1 | M1 | viewport | 1600×900 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00311 | P1 | M1 | viewport | 1600×900 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00312 | P1 | M1 | viewport | 1600×900 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00313 | P1 | M1 | viewport | 1600×900 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00314 | P1 | M1 | viewport | 1600×900 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00315 | P1 | M1 | viewport | 1600×900 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00316 | P1 | M1 | viewport | 1600×900 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00317 | P1 | M1 | viewport | 1600×900 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00318 | P1 | M1 | viewport | 1600×900 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00349 | P1 | M1 | viewport | 3840×2160 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00350 | P1 | M1 | viewport | 3840×2160 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00351 | P1 | M1 | viewport | 3840×2160 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00352 | P1 | M1 | viewport | 3840×2160 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00353 | P1 | M1 | viewport | 3840×2160 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00354 | P1 | M1 | viewport | 3840×2160 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00355 | P1 | M1 | viewport | 3840×2160 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00356 | P1 | M1 | viewport | 3840×2160 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00357 | P1 | M1 | viewport | 3840×2160 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00358 | P1 | M1 | viewport | 3840×2160 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00359 | P1 | M1 | viewport | 3840×2160 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00360 | P1 | M1 | viewport | 3840×2160 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00361 | P1 | M1 | viewport | 3840×2160 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00362 | P1 | M1 | viewport | 3840×2160 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00363 | P1 | M1 | viewport | 3840×2160 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| MT-COM-00364 | P1 | M1 | input | 입력 move_up / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00370 | P1 | M1 | input | 입력 move_up / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00373 | P1 | M1 | input | 입력 move_up / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00374 | P1 | M1 | input | 입력 move_down / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00380 | P1 | M1 | input | 입력 move_down / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00383 | P1 | M1 | input | 입력 move_down / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00384 | P1 | M1 | input | 입력 move_left / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00390 | P1 | M1 | input | 입력 move_left / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00393 | P1 | M1 | input | 입력 move_left / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00394 | P1 | M1 | input | 입력 move_right / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00400 | P1 | M1 | input | 입력 move_right / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00403 | P1 | M1 | input | 입력 move_right / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00404 | P1 | M1 | input | 입력 diagonal / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00410 | P1 | M1 | input | 입력 diagonal / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00413 | P1 | M1 | input | 입력 diagonal / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00414 | P1 | M1 | input | 입력 primary / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00420 | P1 | M1 | input | 입력 primary / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00423 | P1 | M1 | input | 입력 primary / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00424 | P1 | M1 | input | 입력 secondary / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00430 | P1 | M1 | input | 입력 secondary / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00433 | P1 | M1 | input | 입력 secondary / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00434 | P1 | M1 | input | 입력 ability_q / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00440 | P1 | M1 | input | 입력 ability_q / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00443 | P1 | M1 | input | 입력 ability_q / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00444 | P1 | M1 | input | 입력 ability_w / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00450 | P1 | M1 | input | 입력 ability_w / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00453 | P1 | M1 | input | 입력 ability_w / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00454 | P1 | M1 | input | 입력 ability_e / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00460 | P1 | M1 | input | 입력 ability_e / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00463 | P1 | M1 | input | 입력 ability_e / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00464 | P1 | M1 | input | 입력 ability_r / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00470 | P1 | M1 | input | 입력 ability_r / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00473 | P1 | M1 | input | 입력 ability_r / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00474 | P1 | M1 | input | 입력 ability_f / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00480 | P1 | M1 | input | 입력 ability_f / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00483 | P1 | M1 | input | 입력 ability_f / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00484 | P1 | M1 | input | 입력 dash / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00490 | P1 | M1 | input | 입력 dash / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00493 | P1 | M1 | input | 입력 dash / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00494 | P1 | M1 | input | 입력 ping / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00500 | P1 | M1 | input | 입력 ping / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00503 | P1 | M1 | input | 입력 ping / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00504 | P1 | M1 | input | 입력 pause / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00510 | P1 | M1 | input | 입력 pause / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00513 | P1 | M1 | input | 입력 pause / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00514 | P1 | M1 | input | 입력 restart / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00520 | P1 | M1 | input | 입력 restart / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-COM-00523 | P1 | M1 | input | 입력 restart / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| MT-GD-0027 | P1 | M1 | ai | CPU 반응 지연 | 프로필 min/max 안에서 T 이후 반응, 0틱 완벽반응 0건 |
| MT-GD-0028 | P1 | M1 | ai | CPU 동일 실수 반복 제한 | 같은 치명 실수를 연속 2회 이상 의도 삽입하지 않음 |
| MT-GD-0029 | P1 | M1 | ai | 인간 슬롯 편향 없음 | CPU 목표·지원·공격 확률이 슬롯 평균 허용오차 이내 |
| MT-GD-0031 | P1 | M1 | performance | 렌더 객체 증가 상한 | CanvasItem/Node 수가 설계 상한 이내이며 계속 증가하지 않음 |
| MT-GD-0035 | P1 | M1 | ux | CPU 구분 가독성 | 인간 캐릭터를 1초 내 찾는 성공률 95% 이상 |
| MT-GD-0036 | P1 | M1 | audio | 판정과 오디오 분리 | 상태 해시 동일 |
| MT-GD-0038 | P1 | M1 | save | user:// 쓰기 실패 안전 | 게임은 계속되고 저장 실패 1회만 경고 |
| MT-GD-0055 | P1 | M1 | fun | CPU 과도한 최적화 금지 | 한 전략/한 경로 점유율이 65%를 넘지 않음 |
| MT-GD-0056 | P1 | M1 | fun | CPU 무능 연출 금지 | 실행 가능한 기본 목표를 85% 이상 수행 |
| MT-GD-0057 | P1 | M1 | fun | 인간 개입 가치 | 인간 행동이 사건·결과를 바꾸되 혼자 모든 판을 지배하지 않음 |
| MT-COM-00012 | P1 | M2 | ai | 행동 관성 | CPU가 초당 2회 이상 표적을 왕복하지 않는다 |
| MT-COM-00524 | P1 | M2 | ai-audit | CPU balanced / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00525 | P1 | M2 | ai-audit | CPU balanced / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00532 | P1 | M2 | ai-audit | CPU balanced / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00533 | P1 | M2 | ai-audit | CPU balanced / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00540 | P1 | M2 | ai-audit | CPU balanced / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00541 | P1 | M2 | ai-audit | CPU balanced / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00548 | P1 | M2 | ai-audit | CPU balanced / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00549 | P1 | M2 | ai-audit | CPU balanced / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00556 | P1 | M2 | ai-audit | CPU balanced / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00557 | P1 | M2 | ai-audit | CPU balanced / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00564 | P1 | M2 | ai-audit | CPU balanced / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00565 | P1 | M2 | ai-audit | CPU balanced / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00572 | P1 | M2 | ai-audit | CPU balanced / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00573 | P1 | M2 | ai-audit | CPU balanced / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00580 | P1 | M2 | ai-audit | CPU balanced / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00581 | P1 | M2 | ai-audit | CPU balanced / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00588 | P1 | M2 | ai-audit | CPU balanced / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00589 | P1 | M2 | ai-audit | CPU balanced / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00596 | P1 | M2 | ai-audit | CPU balanced / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00597 | P1 | M2 | ai-audit | CPU balanced / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00604 | P1 | M2 | ai-audit | CPU balanced / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00605 | P1 | M2 | ai-audit | CPU balanced / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00612 | P1 | M2 | ai-audit | CPU balanced / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00613 | P1 | M2 | ai-audit | CPU balanced / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00620 | P1 | M2 | ai-audit | CPU risk_taker / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00621 | P1 | M2 | ai-audit | CPU risk_taker / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00628 | P1 | M2 | ai-audit | CPU risk_taker / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00629 | P1 | M2 | ai-audit | CPU risk_taker / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00636 | P1 | M2 | ai-audit | CPU risk_taker / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00637 | P1 | M2 | ai-audit | CPU risk_taker / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00644 | P1 | M2 | ai-audit | CPU risk_taker / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00645 | P1 | M2 | ai-audit | CPU risk_taker / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00652 | P1 | M2 | ai-audit | CPU risk_taker / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00653 | P1 | M2 | ai-audit | CPU risk_taker / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00660 | P1 | M2 | ai-audit | CPU risk_taker / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00661 | P1 | M2 | ai-audit | CPU risk_taker / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00668 | P1 | M2 | ai-audit | CPU risk_taker / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00669 | P1 | M2 | ai-audit | CPU risk_taker / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00676 | P1 | M2 | ai-audit | CPU risk_taker / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00677 | P1 | M2 | ai-audit | CPU risk_taker / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00684 | P1 | M2 | ai-audit | CPU risk_taker / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00685 | P1 | M2 | ai-audit | CPU risk_taker / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00692 | P1 | M2 | ai-audit | CPU risk_taker / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00693 | P1 | M2 | ai-audit | CPU risk_taker / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00700 | P1 | M2 | ai-audit | CPU risk_taker / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00701 | P1 | M2 | ai-audit | CPU risk_taker / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00708 | P1 | M2 | ai-audit | CPU risk_taker / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00709 | P1 | M2 | ai-audit | CPU risk_taker / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00716 | P1 | M2 | ai-audit | CPU rescuer / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00717 | P1 | M2 | ai-audit | CPU rescuer / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00724 | P1 | M2 | ai-audit | CPU rescuer / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00725 | P1 | M2 | ai-audit | CPU rescuer / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00732 | P1 | M2 | ai-audit | CPU rescuer / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00733 | P1 | M2 | ai-audit | CPU rescuer / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00740 | P1 | M2 | ai-audit | CPU rescuer / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00741 | P1 | M2 | ai-audit | CPU rescuer / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00748 | P1 | M2 | ai-audit | CPU rescuer / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00749 | P1 | M2 | ai-audit | CPU rescuer / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00756 | P1 | M2 | ai-audit | CPU rescuer / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00757 | P1 | M2 | ai-audit | CPU rescuer / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00764 | P1 | M2 | ai-audit | CPU rescuer / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00765 | P1 | M2 | ai-audit | CPU rescuer / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00772 | P1 | M2 | ai-audit | CPU rescuer / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00773 | P1 | M2 | ai-audit | CPU rescuer / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00780 | P1 | M2 | ai-audit | CPU rescuer / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00781 | P1 | M2 | ai-audit | CPU rescuer / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00788 | P1 | M2 | ai-audit | CPU rescuer / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00789 | P1 | M2 | ai-audit | CPU rescuer / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00796 | P1 | M2 | ai-audit | CPU rescuer / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00797 | P1 | M2 | ai-audit | CPU rescuer / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00804 | P1 | M2 | ai-audit | CPU rescuer / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00805 | P1 | M2 | ai-audit | CPU rescuer / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00812 | P1 | M2 | ai-audit | CPU greedy / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00813 | P1 | M2 | ai-audit | CPU greedy / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00820 | P1 | M2 | ai-audit | CPU greedy / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00821 | P1 | M2 | ai-audit | CPU greedy / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00828 | P1 | M2 | ai-audit | CPU greedy / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00829 | P1 | M2 | ai-audit | CPU greedy / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00836 | P1 | M2 | ai-audit | CPU greedy / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00837 | P1 | M2 | ai-audit | CPU greedy / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00844 | P1 | M2 | ai-audit | CPU greedy / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00845 | P1 | M2 | ai-audit | CPU greedy / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00852 | P1 | M2 | ai-audit | CPU greedy / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00853 | P1 | M2 | ai-audit | CPU greedy / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00860 | P1 | M2 | ai-audit | CPU greedy / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00861 | P1 | M2 | ai-audit | CPU greedy / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00868 | P1 | M2 | ai-audit | CPU greedy / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00869 | P1 | M2 | ai-audit | CPU greedy / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00876 | P1 | M2 | ai-audit | CPU greedy / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00877 | P1 | M2 | ai-audit | CPU greedy / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00884 | P1 | M2 | ai-audit | CPU greedy / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00885 | P1 | M2 | ai-audit | CPU greedy / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00892 | P1 | M2 | ai-audit | CPU greedy / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00893 | P1 | M2 | ai-audit | CPU greedy / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00900 | P1 | M2 | ai-audit | CPU greedy / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00901 | P1 | M2 | ai-audit | CPU greedy / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00908 | P1 | M2 | ai-audit | CPU patient / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00909 | P1 | M2 | ai-audit | CPU patient / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00916 | P1 | M2 | ai-audit | CPU patient / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00917 | P1 | M2 | ai-audit | CPU patient / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00924 | P1 | M2 | ai-audit | CPU patient / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00925 | P1 | M2 | ai-audit | CPU patient / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00932 | P1 | M2 | ai-audit | CPU patient / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00933 | P1 | M2 | ai-audit | CPU patient / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00940 | P1 | M2 | ai-audit | CPU patient / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00941 | P1 | M2 | ai-audit | CPU patient / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00948 | P1 | M2 | ai-audit | CPU patient / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00949 | P1 | M2 | ai-audit | CPU patient / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00956 | P1 | M2 | ai-audit | CPU patient / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00957 | P1 | M2 | ai-audit | CPU patient / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00964 | P1 | M2 | ai-audit | CPU patient / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00965 | P1 | M2 | ai-audit | CPU patient / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00972 | P1 | M2 | ai-audit | CPU patient / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00973 | P1 | M2 | ai-audit | CPU patient / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00980 | P1 | M2 | ai-audit | CPU patient / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00981 | P1 | M2 | ai-audit | CPU patient / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00988 | P1 | M2 | ai-audit | CPU patient / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00989 | P1 | M2 | ai-audit | CPU patient / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00996 | P1 | M2 | ai-audit | CPU patient / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-00997 | P1 | M2 | ai-audit | CPU patient / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01004 | P1 | M2 | ai-audit | CPU showman / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01005 | P1 | M2 | ai-audit | CPU showman / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01012 | P1 | M2 | ai-audit | CPU showman / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01013 | P1 | M2 | ai-audit | CPU showman / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01020 | P1 | M2 | ai-audit | CPU showman / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01021 | P1 | M2 | ai-audit | CPU showman / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01028 | P1 | M2 | ai-audit | CPU showman / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01029 | P1 | M2 | ai-audit | CPU showman / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01036 | P1 | M2 | ai-audit | CPU showman / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01037 | P1 | M2 | ai-audit | CPU showman / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01044 | P1 | M2 | ai-audit | CPU showman / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01045 | P1 | M2 | ai-audit | CPU showman / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01052 | P1 | M2 | ai-audit | CPU showman / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01053 | P1 | M2 | ai-audit | CPU showman / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01060 | P1 | M2 | ai-audit | CPU showman / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01061 | P1 | M2 | ai-audit | CPU showman / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01068 | P1 | M2 | ai-audit | CPU showman / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01069 | P1 | M2 | ai-audit | CPU showman / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01076 | P1 | M2 | ai-audit | CPU showman / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01077 | P1 | M2 | ai-audit | CPU showman / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01084 | P1 | M2 | ai-audit | CPU showman / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01085 | P1 | M2 | ai-audit | CPU showman / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01092 | P1 | M2 | ai-audit | CPU showman / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-COM-01093 | P1 | M2 | ai-audit | CPU showman / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| MT-GD-0040 | P1 | M2 | export | GL Compatibility 실행 | 셰이더 없이 회색상자 60 physics FPS |
| MT-GD-0041 | P1 | M2 | accessibility | 화면 흔들림 0 옵션 | Camera2D 위치 흔들림 0, 판정 동일 |
| MT-GD-0042 | P1 | M2 | accessibility | 색상 외 구분 | 아이콘·형태·번호로 소유자와 위험 식별 |
| MT-GD-0044 | P1 | M2 | telemetry | 개인정보 없는 로그 | 시드·행동·지표만 포함, OS 사용자명·경로·IP 없음 |
| MT-GD-0047 | P1 | M2 | package | 체크리스트 ID 유일 | 중복 ID 0건, 필수 열 누락 0건 |
| MT-GD-0048 | P1 | M2 | package | P0/P1 게이트 | 미완료 1건이라도 릴리스 실패 |
| MT-COM-01100 | P1 | M3 | pooling | projectile 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01106 | P1 | M3 | pooling | projectile 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01107 | P1 | M3 | pooling | damage_number 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01113 | P1 | M3 | pooling | damage_number 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01114 | P1 | M3 | pooling | health_bar 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01120 | P1 | M3 | pooling | health_bar 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01121 | P1 | M3 | pooling | warning 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01127 | P1 | M3 | pooling | warning 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01128 | P1 | M3 | pooling | boulder 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01134 | P1 | M3 | pooling | boulder 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01135 | P1 | M3 | pooling | wall 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01141 | P1 | M3 | pooling | wall 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01142 | P1 | M3 | pooling | enemy 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01148 | P1 | M3 | pooling | enemy 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01149 | P1 | M3 | pooling | shipment 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01155 | P1 | M3 | pooling | shipment 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01156 | P1 | M3 | pooling | summon 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01162 | P1 | M3 | pooling | summon 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01163 | P1 | M3 | pooling | corpse_flag 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-01169 | P1 | M3 | pooling | corpse_flag 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| MT-COM-00015 | P1 | M4 | ux | 실패 후 재시작 | 2.5초 이내 새 판에서 조작 가능 |
| MT-COM-00016 | P1 | M4 | audio | 경고 중복 제한 | 80ms 창에서 같은 큐가 최대 1회 재생 |
| MT-COM-00018 | P1 | M4 | accessibility | 색 외 구분 | 형태·아이콘만으로 핵심 상태를 구분 가능 |
| MT-01710 | P1 | MT-M1 | revive | 깃발 1 / 구조자 1 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01711 | P1 | MT-M1 | revive | 깃발 1 / 구조자 1 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01712 | P1 | MT-M1 | revive | 깃발 1 / 구조자 1 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01713 | P1 | MT-M1 | revive | 깃발 1 / 구조자 1 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01714 | P1 | MT-M1 | revive | 깃발 1 / 구조자 1 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01715 | P1 | MT-M1 | revive | 깃발 1 / 구조자 1 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01716 | P1 | MT-M1 | revive | 깃발 1 / 구조자 1 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01717 | P1 | MT-M1 | revive | 깃발 1 / 구조자 1 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01718 | P1 | MT-M1 | revive | 깃발 1 / 구조자 1 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01719 | P1 | MT-M1 | revive | 깃발 1 / 구조자 1 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01735 | P1 | MT-M1 | revive | 깃발 1 / 구조자 2 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01736 | P1 | MT-M1 | revive | 깃발 1 / 구조자 2 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01737 | P1 | MT-M1 | revive | 깃발 1 / 구조자 2 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01738 | P1 | MT-M1 | revive | 깃발 1 / 구조자 2 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01739 | P1 | MT-M1 | revive | 깃발 1 / 구조자 2 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01740 | P1 | MT-M1 | revive | 깃발 1 / 구조자 2 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01741 | P1 | MT-M1 | revive | 깃발 1 / 구조자 2 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01742 | P1 | MT-M1 | revive | 깃발 1 / 구조자 2 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01743 | P1 | MT-M1 | revive | 깃발 1 / 구조자 2 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01744 | P1 | MT-M1 | revive | 깃발 1 / 구조자 2 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01760 | P1 | MT-M1 | revive | 깃발 1 / 구조자 3 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01761 | P1 | MT-M1 | revive | 깃발 1 / 구조자 3 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01762 | P1 | MT-M1 | revive | 깃발 1 / 구조자 3 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01763 | P1 | MT-M1 | revive | 깃발 1 / 구조자 3 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01764 | P1 | MT-M1 | revive | 깃발 1 / 구조자 3 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01765 | P1 | MT-M1 | revive | 깃발 1 / 구조자 3 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01766 | P1 | MT-M1 | revive | 깃발 1 / 구조자 3 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01767 | P1 | MT-M1 | revive | 깃발 1 / 구조자 3 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01768 | P1 | MT-M1 | revive | 깃발 1 / 구조자 3 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01769 | P1 | MT-M1 | revive | 깃발 1 / 구조자 3 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01785 | P1 | MT-M1 | revive | 깃발 2 / 구조자 1 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01786 | P1 | MT-M1 | revive | 깃발 2 / 구조자 1 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01787 | P1 | MT-M1 | revive | 깃발 2 / 구조자 1 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01788 | P1 | MT-M1 | revive | 깃발 2 / 구조자 1 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01789 | P1 | MT-M1 | revive | 깃발 2 / 구조자 1 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01790 | P1 | MT-M1 | revive | 깃발 2 / 구조자 1 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01791 | P1 | MT-M1 | revive | 깃발 2 / 구조자 1 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01792 | P1 | MT-M1 | revive | 깃발 2 / 구조자 1 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01793 | P1 | MT-M1 | revive | 깃발 2 / 구조자 1 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01794 | P1 | MT-M1 | revive | 깃발 2 / 구조자 1 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01810 | P1 | MT-M1 | revive | 깃발 2 / 구조자 2 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01811 | P1 | MT-M1 | revive | 깃발 2 / 구조자 2 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01812 | P1 | MT-M1 | revive | 깃발 2 / 구조자 2 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01813 | P1 | MT-M1 | revive | 깃발 2 / 구조자 2 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01814 | P1 | MT-M1 | revive | 깃발 2 / 구조자 2 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01815 | P1 | MT-M1 | revive | 깃발 2 / 구조자 2 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01816 | P1 | MT-M1 | revive | 깃발 2 / 구조자 2 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01817 | P1 | MT-M1 | revive | 깃발 2 / 구조자 2 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01818 | P1 | MT-M1 | revive | 깃발 2 / 구조자 2 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01819 | P1 | MT-M1 | revive | 깃발 2 / 구조자 2 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01835 | P1 | MT-M1 | revive | 깃발 2 / 구조자 3 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01836 | P1 | MT-M1 | revive | 깃발 2 / 구조자 3 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01837 | P1 | MT-M1 | revive | 깃발 2 / 구조자 3 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01838 | P1 | MT-M1 | revive | 깃발 2 / 구조자 3 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01839 | P1 | MT-M1 | revive | 깃발 2 / 구조자 3 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01840 | P1 | MT-M1 | revive | 깃발 2 / 구조자 3 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01841 | P1 | MT-M1 | revive | 깃발 2 / 구조자 3 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01842 | P1 | MT-M1 | revive | 깃발 2 / 구조자 3 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01843 | P1 | MT-M1 | revive | 깃발 2 / 구조자 3 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01844 | P1 | MT-M1 | revive | 깃발 2 / 구조자 3 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01860 | P1 | MT-M1 | revive | 깃발 3 / 구조자 1 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01861 | P1 | MT-M1 | revive | 깃발 3 / 구조자 1 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01862 | P1 | MT-M1 | revive | 깃발 3 / 구조자 1 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01863 | P1 | MT-M1 | revive | 깃발 3 / 구조자 1 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01864 | P1 | MT-M1 | revive | 깃발 3 / 구조자 1 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01865 | P1 | MT-M1 | revive | 깃발 3 / 구조자 1 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01866 | P1 | MT-M1 | revive | 깃발 3 / 구조자 1 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01867 | P1 | MT-M1 | revive | 깃발 3 / 구조자 1 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01868 | P1 | MT-M1 | revive | 깃발 3 / 구조자 1 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01869 | P1 | MT-M1 | revive | 깃발 3 / 구조자 1 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01885 | P1 | MT-M1 | revive | 깃발 3 / 구조자 2 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01886 | P1 | MT-M1 | revive | 깃발 3 / 구조자 2 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01887 | P1 | MT-M1 | revive | 깃발 3 / 구조자 2 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01888 | P1 | MT-M1 | revive | 깃발 3 / 구조자 2 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01889 | P1 | MT-M1 | revive | 깃발 3 / 구조자 2 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01890 | P1 | MT-M1 | revive | 깃발 3 / 구조자 2 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01891 | P1 | MT-M1 | revive | 깃발 3 / 구조자 2 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01892 | P1 | MT-M1 | revive | 깃발 3 / 구조자 2 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01893 | P1 | MT-M1 | revive | 깃발 3 / 구조자 2 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01894 | P1 | MT-M1 | revive | 깃발 3 / 구조자 2 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01910 | P1 | MT-M1 | revive | 깃발 3 / 구조자 3 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01911 | P1 | MT-M1 | revive | 깃발 3 / 구조자 3 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01912 | P1 | MT-M1 | revive | 깃발 3 / 구조자 3 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01913 | P1 | MT-M1 | revive | 깃발 3 / 구조자 3 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01914 | P1 | MT-M1 | revive | 깃발 3 / 구조자 3 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01915 | P1 | MT-M1 | revive | 깃발 3 / 구조자 3 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01916 | P1 | MT-M1 | revive | 깃발 3 / 구조자 3 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01917 | P1 | MT-M1 | revive | 깃발 3 / 구조자 3 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01918 | P1 | MT-M1 | revive | 깃발 3 / 구조자 3 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01919 | P1 | MT-M1 | revive | 깃발 3 / 구조자 3 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01935 | P1 | MT-M1 | revive | 깃발 4 / 구조자 1 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01936 | P1 | MT-M1 | revive | 깃발 4 / 구조자 1 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01937 | P1 | MT-M1 | revive | 깃발 4 / 구조자 1 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01938 | P1 | MT-M1 | revive | 깃발 4 / 구조자 1 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01939 | P1 | MT-M1 | revive | 깃발 4 / 구조자 1 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01940 | P1 | MT-M1 | revive | 깃발 4 / 구조자 1 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01941 | P1 | MT-M1 | revive | 깃발 4 / 구조자 1 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01942 | P1 | MT-M1 | revive | 깃발 4 / 구조자 1 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01943 | P1 | MT-M1 | revive | 깃발 4 / 구조자 1 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01944 | P1 | MT-M1 | revive | 깃발 4 / 구조자 1 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01960 | P1 | MT-M1 | revive | 깃발 4 / 구조자 2 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01961 | P1 | MT-M1 | revive | 깃발 4 / 구조자 2 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01962 | P1 | MT-M1 | revive | 깃발 4 / 구조자 2 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01963 | P1 | MT-M1 | revive | 깃발 4 / 구조자 2 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01964 | P1 | MT-M1 | revive | 깃발 4 / 구조자 2 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01965 | P1 | MT-M1 | revive | 깃발 4 / 구조자 2 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01966 | P1 | MT-M1 | revive | 깃발 4 / 구조자 2 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01967 | P1 | MT-M1 | revive | 깃발 4 / 구조자 2 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01968 | P1 | MT-M1 | revive | 깃발 4 / 구조자 2 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01969 | P1 | MT-M1 | revive | 깃발 4 / 구조자 2 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01985 | P1 | MT-M1 | revive | 깃발 4 / 구조자 3 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01986 | P1 | MT-M1 | revive | 깃발 4 / 구조자 3 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01987 | P1 | MT-M1 | revive | 깃발 4 / 구조자 3 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01988 | P1 | MT-M1 | revive | 깃발 4 / 구조자 3 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01989 | P1 | MT-M1 | revive | 깃발 4 / 구조자 3 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01990 | P1 | MT-M1 | revive | 깃발 4 / 구조자 3 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01991 | P1 | MT-M1 | revive | 깃발 4 / 구조자 3 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01992 | P1 | MT-M1 | revive | 깃발 4 / 구조자 3 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01993 | P1 | MT-M1 | revive | 깃발 4 / 구조자 3 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-01994 | P1 | MT-M1 | revive | 깃발 4 / 구조자 3 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02010 | P1 | MT-M1 | revive | 깃발 5 / 구조자 1 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02011 | P1 | MT-M1 | revive | 깃발 5 / 구조자 1 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02012 | P1 | MT-M1 | revive | 깃발 5 / 구조자 1 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02013 | P1 | MT-M1 | revive | 깃발 5 / 구조자 1 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02014 | P1 | MT-M1 | revive | 깃발 5 / 구조자 1 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02015 | P1 | MT-M1 | revive | 깃발 5 / 구조자 1 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02016 | P1 | MT-M1 | revive | 깃발 5 / 구조자 1 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02017 | P1 | MT-M1 | revive | 깃발 5 / 구조자 1 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02018 | P1 | MT-M1 | revive | 깃발 5 / 구조자 1 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02019 | P1 | MT-M1 | revive | 깃발 5 / 구조자 1 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02035 | P1 | MT-M1 | revive | 깃발 5 / 구조자 2 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02036 | P1 | MT-M1 | revive | 깃발 5 / 구조자 2 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02037 | P1 | MT-M1 | revive | 깃발 5 / 구조자 2 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02038 | P1 | MT-M1 | revive | 깃발 5 / 구조자 2 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02039 | P1 | MT-M1 | revive | 깃발 5 / 구조자 2 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02040 | P1 | MT-M1 | revive | 깃발 5 / 구조자 2 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02041 | P1 | MT-M1 | revive | 깃발 5 / 구조자 2 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02042 | P1 | MT-M1 | revive | 깃발 5 / 구조자 2 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02043 | P1 | MT-M1 | revive | 깃발 5 / 구조자 2 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02044 | P1 | MT-M1 | revive | 깃발 5 / 구조자 2 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02060 | P1 | MT-M1 | revive | 깃발 5 / 구조자 3 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02061 | P1 | MT-M1 | revive | 깃발 5 / 구조자 3 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02062 | P1 | MT-M1 | revive | 깃발 5 / 구조자 3 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02063 | P1 | MT-M1 | revive | 깃발 5 / 구조자 3 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02064 | P1 | MT-M1 | revive | 깃발 5 / 구조자 3 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02065 | P1 | MT-M1 | revive | 깃발 5 / 구조자 3 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02066 | P1 | MT-M1 | revive | 깃발 5 / 구조자 3 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02067 | P1 | MT-M1 | revive | 깃발 5 / 구조자 3 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02068 | P1 | MT-M1 | revive | 깃발 5 / 구조자 3 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02069 | P1 | MT-M1 | revive | 깃발 5 / 구조자 3 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02085 | P1 | MT-M1 | revive | 깃발 6 / 구조자 1 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02086 | P1 | MT-M1 | revive | 깃발 6 / 구조자 1 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02087 | P1 | MT-M1 | revive | 깃발 6 / 구조자 1 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02088 | P1 | MT-M1 | revive | 깃발 6 / 구조자 1 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02089 | P1 | MT-M1 | revive | 깃발 6 / 구조자 1 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02090 | P1 | MT-M1 | revive | 깃발 6 / 구조자 1 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02091 | P1 | MT-M1 | revive | 깃발 6 / 구조자 1 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02092 | P1 | MT-M1 | revive | 깃발 6 / 구조자 1 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02093 | P1 | MT-M1 | revive | 깃발 6 / 구조자 1 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02094 | P1 | MT-M1 | revive | 깃발 6 / 구조자 1 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02110 | P1 | MT-M1 | revive | 깃발 6 / 구조자 2 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02111 | P1 | MT-M1 | revive | 깃발 6 / 구조자 2 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02112 | P1 | MT-M1 | revive | 깃발 6 / 구조자 2 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02113 | P1 | MT-M1 | revive | 깃발 6 / 구조자 2 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02114 | P1 | MT-M1 | revive | 깃발 6 / 구조자 2 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02115 | P1 | MT-M1 | revive | 깃발 6 / 구조자 2 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02116 | P1 | MT-M1 | revive | 깃발 6 / 구조자 2 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02117 | P1 | MT-M1 | revive | 깃발 6 / 구조자 2 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02118 | P1 | MT-M1 | revive | 깃발 6 / 구조자 2 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02119 | P1 | MT-M1 | revive | 깃발 6 / 구조자 2 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02135 | P1 | MT-M1 | revive | 깃발 6 / 구조자 3 / safe / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02136 | P1 | MT-M1 | revive | 깃발 6 / 구조자 3 / safe / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02137 | P1 | MT-M1 | revive | 깃발 6 / 구조자 3 / safe / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02138 | P1 | MT-M1 | revive | 깃발 6 / 구조자 3 / safe / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02139 | P1 | MT-M1 | revive | 깃발 6 / 구조자 3 / safe / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02140 | P1 | MT-M1 | revive | 깃발 6 / 구조자 3 / arrival_0.7s / S1 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02141 | P1 | MT-M1 | revive | 깃발 6 / 구조자 3 / arrival_0.7s / S2 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02142 | P1 | MT-M1 | revive | 깃발 6 / 구조자 3 / arrival_0.7s / S3 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02143 | P1 | MT-M1 | revive | 깃발 6 / 구조자 3 / arrival_0.7s / S4 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-02144 | P1 | MT-M1 | revive | 깃발 6 / 구조자 3 / arrival_0.7s / S5 | 구조 배율·취소·부활 무적이 정확하고 이중 부활·고아 깃발이 없다 |
| MT-00008 | P1 | MT-M3 | camera | 사망 관전 전환 | 정상에 가장 가까운 생존자에게 부드럽게 전환 |
| MT-00010 | P1 | MT-M3 | stage-sim | S1 1인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00011 | P1 | MT-M3 | stage-sim | S1 1인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00018 | P1 | MT-M3 | stage-sim | S1 1인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00019 | P1 | MT-M3 | stage-sim | S1 1인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00026 | P1 | MT-M3 | stage-sim | S1 1인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00027 | P1 | MT-M3 | stage-sim | S1 1인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00034 | P1 | MT-M3 | stage-sim | S1 1인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00035 | P1 | MT-M3 | stage-sim | S1 1인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00042 | P1 | MT-M3 | stage-sim | S1 1인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00043 | P1 | MT-M3 | stage-sim | S1 1인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00050 | P1 | MT-M3 | stage-sim | S1 2인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00051 | P1 | MT-M3 | stage-sim | S1 2인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00058 | P1 | MT-M3 | stage-sim | S1 2인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00059 | P1 | MT-M3 | stage-sim | S1 2인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00066 | P1 | MT-M3 | stage-sim | S1 2인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00067 | P1 | MT-M3 | stage-sim | S1 2인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00074 | P1 | MT-M3 | stage-sim | S1 2인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00075 | P1 | MT-M3 | stage-sim | S1 2인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00082 | P1 | MT-M3 | stage-sim | S1 2인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00083 | P1 | MT-M3 | stage-sim | S1 2인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00090 | P1 | MT-M3 | stage-sim | S1 3인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00091 | P1 | MT-M3 | stage-sim | S1 3인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00098 | P1 | MT-M3 | stage-sim | S1 3인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00099 | P1 | MT-M3 | stage-sim | S1 3인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00106 | P1 | MT-M3 | stage-sim | S1 3인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00107 | P1 | MT-M3 | stage-sim | S1 3인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00114 | P1 | MT-M3 | stage-sim | S1 3인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00115 | P1 | MT-M3 | stage-sim | S1 3인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00122 | P1 | MT-M3 | stage-sim | S1 3인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00123 | P1 | MT-M3 | stage-sim | S1 3인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00130 | P1 | MT-M3 | stage-sim | S1 4인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00131 | P1 | MT-M3 | stage-sim | S1 4인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00138 | P1 | MT-M3 | stage-sim | S1 4인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00139 | P1 | MT-M3 | stage-sim | S1 4인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00146 | P1 | MT-M3 | stage-sim | S1 4인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00147 | P1 | MT-M3 | stage-sim | S1 4인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00154 | P1 | MT-M3 | stage-sim | S1 4인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00155 | P1 | MT-M3 | stage-sim | S1 4인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00162 | P1 | MT-M3 | stage-sim | S1 4인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00163 | P1 | MT-M3 | stage-sim | S1 4인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00170 | P1 | MT-M3 | stage-sim | S1 5인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00171 | P1 | MT-M3 | stage-sim | S1 5인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00178 | P1 | MT-M3 | stage-sim | S1 5인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00179 | P1 | MT-M3 | stage-sim | S1 5인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00186 | P1 | MT-M3 | stage-sim | S1 5인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00187 | P1 | MT-M3 | stage-sim | S1 5인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00194 | P1 | MT-M3 | stage-sim | S1 5인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00195 | P1 | MT-M3 | stage-sim | S1 5인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00202 | P1 | MT-M3 | stage-sim | S1 5인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00203 | P1 | MT-M3 | stage-sim | S1 5인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00210 | P1 | MT-M3 | stage-sim | S1 6인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00211 | P1 | MT-M3 | stage-sim | S1 6인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00218 | P1 | MT-M3 | stage-sim | S1 6인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00219 | P1 | MT-M3 | stage-sim | S1 6인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00226 | P1 | MT-M3 | stage-sim | S1 6인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00227 | P1 | MT-M3 | stage-sim | S1 6인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00234 | P1 | MT-M3 | stage-sim | S1 6인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00235 | P1 | MT-M3 | stage-sim | S1 6인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00242 | P1 | MT-M3 | stage-sim | S1 6인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00243 | P1 | MT-M3 | stage-sim | S1 6인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00250 | P1 | MT-M3 | stage-sim | S1 7인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00251 | P1 | MT-M3 | stage-sim | S1 7인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00258 | P1 | MT-M3 | stage-sim | S1 7인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00259 | P1 | MT-M3 | stage-sim | S1 7인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00266 | P1 | MT-M3 | stage-sim | S1 7인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00267 | P1 | MT-M3 | stage-sim | S1 7인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00274 | P1 | MT-M3 | stage-sim | S1 7인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00275 | P1 | MT-M3 | stage-sim | S1 7인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00282 | P1 | MT-M3 | stage-sim | S1 7인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00283 | P1 | MT-M3 | stage-sim | S1 7인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00290 | P1 | MT-M3 | stage-sim | S2 1인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00291 | P1 | MT-M3 | stage-sim | S2 1인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00298 | P1 | MT-M3 | stage-sim | S2 1인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00299 | P1 | MT-M3 | stage-sim | S2 1인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00306 | P1 | MT-M3 | stage-sim | S2 1인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00307 | P1 | MT-M3 | stage-sim | S2 1인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00314 | P1 | MT-M3 | stage-sim | S2 1인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00315 | P1 | MT-M3 | stage-sim | S2 1인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00322 | P1 | MT-M3 | stage-sim | S2 1인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00323 | P1 | MT-M3 | stage-sim | S2 1인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00330 | P1 | MT-M3 | stage-sim | S2 2인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00331 | P1 | MT-M3 | stage-sim | S2 2인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00338 | P1 | MT-M3 | stage-sim | S2 2인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00339 | P1 | MT-M3 | stage-sim | S2 2인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00346 | P1 | MT-M3 | stage-sim | S2 2인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00347 | P1 | MT-M3 | stage-sim | S2 2인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00354 | P1 | MT-M3 | stage-sim | S2 2인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00355 | P1 | MT-M3 | stage-sim | S2 2인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00362 | P1 | MT-M3 | stage-sim | S2 2인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00363 | P1 | MT-M3 | stage-sim | S2 2인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00370 | P1 | MT-M3 | stage-sim | S2 3인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00371 | P1 | MT-M3 | stage-sim | S2 3인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00378 | P1 | MT-M3 | stage-sim | S2 3인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00379 | P1 | MT-M3 | stage-sim | S2 3인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00386 | P1 | MT-M3 | stage-sim | S2 3인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00387 | P1 | MT-M3 | stage-sim | S2 3인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00394 | P1 | MT-M3 | stage-sim | S2 3인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00395 | P1 | MT-M3 | stage-sim | S2 3인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00402 | P1 | MT-M3 | stage-sim | S2 3인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00403 | P1 | MT-M3 | stage-sim | S2 3인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00410 | P1 | MT-M3 | stage-sim | S2 4인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00411 | P1 | MT-M3 | stage-sim | S2 4인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00418 | P1 | MT-M3 | stage-sim | S2 4인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00419 | P1 | MT-M3 | stage-sim | S2 4인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00426 | P1 | MT-M3 | stage-sim | S2 4인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00427 | P1 | MT-M3 | stage-sim | S2 4인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00434 | P1 | MT-M3 | stage-sim | S2 4인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00435 | P1 | MT-M3 | stage-sim | S2 4인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00442 | P1 | MT-M3 | stage-sim | S2 4인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00443 | P1 | MT-M3 | stage-sim | S2 4인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00450 | P1 | MT-M3 | stage-sim | S2 5인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00451 | P1 | MT-M3 | stage-sim | S2 5인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00458 | P1 | MT-M3 | stage-sim | S2 5인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00459 | P1 | MT-M3 | stage-sim | S2 5인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00466 | P1 | MT-M3 | stage-sim | S2 5인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00467 | P1 | MT-M3 | stage-sim | S2 5인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00474 | P1 | MT-M3 | stage-sim | S2 5인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00475 | P1 | MT-M3 | stage-sim | S2 5인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00482 | P1 | MT-M3 | stage-sim | S2 5인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00483 | P1 | MT-M3 | stage-sim | S2 5인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00490 | P1 | MT-M3 | stage-sim | S2 6인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00491 | P1 | MT-M3 | stage-sim | S2 6인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00498 | P1 | MT-M3 | stage-sim | S2 6인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00499 | P1 | MT-M3 | stage-sim | S2 6인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00506 | P1 | MT-M3 | stage-sim | S2 6인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00507 | P1 | MT-M3 | stage-sim | S2 6인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00514 | P1 | MT-M3 | stage-sim | S2 6인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00515 | P1 | MT-M3 | stage-sim | S2 6인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00522 | P1 | MT-M3 | stage-sim | S2 6인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00523 | P1 | MT-M3 | stage-sim | S2 6인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00530 | P1 | MT-M3 | stage-sim | S2 7인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00531 | P1 | MT-M3 | stage-sim | S2 7인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00538 | P1 | MT-M3 | stage-sim | S2 7인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00539 | P1 | MT-M3 | stage-sim | S2 7인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00546 | P1 | MT-M3 | stage-sim | S2 7인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00547 | P1 | MT-M3 | stage-sim | S2 7인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00554 | P1 | MT-M3 | stage-sim | S2 7인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00555 | P1 | MT-M3 | stage-sim | S2 7인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00562 | P1 | MT-M3 | stage-sim | S2 7인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00563 | P1 | MT-M3 | stage-sim | S2 7인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00570 | P1 | MT-M3 | stage-sim | S3 1인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00571 | P1 | MT-M3 | stage-sim | S3 1인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00578 | P1 | MT-M3 | stage-sim | S3 1인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00579 | P1 | MT-M3 | stage-sim | S3 1인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00586 | P1 | MT-M3 | stage-sim | S3 1인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00587 | P1 | MT-M3 | stage-sim | S3 1인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00594 | P1 | MT-M3 | stage-sim | S3 1인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00595 | P1 | MT-M3 | stage-sim | S3 1인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00602 | P1 | MT-M3 | stage-sim | S3 1인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00603 | P1 | MT-M3 | stage-sim | S3 1인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00610 | P1 | MT-M3 | stage-sim | S3 2인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00611 | P1 | MT-M3 | stage-sim | S3 2인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00618 | P1 | MT-M3 | stage-sim | S3 2인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00619 | P1 | MT-M3 | stage-sim | S3 2인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00626 | P1 | MT-M3 | stage-sim | S3 2인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00627 | P1 | MT-M3 | stage-sim | S3 2인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00634 | P1 | MT-M3 | stage-sim | S3 2인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00635 | P1 | MT-M3 | stage-sim | S3 2인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00642 | P1 | MT-M3 | stage-sim | S3 2인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00643 | P1 | MT-M3 | stage-sim | S3 2인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00650 | P1 | MT-M3 | stage-sim | S3 3인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00651 | P1 | MT-M3 | stage-sim | S3 3인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00658 | P1 | MT-M3 | stage-sim | S3 3인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00659 | P1 | MT-M3 | stage-sim | S3 3인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00666 | P1 | MT-M3 | stage-sim | S3 3인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00667 | P1 | MT-M3 | stage-sim | S3 3인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00674 | P1 | MT-M3 | stage-sim | S3 3인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00675 | P1 | MT-M3 | stage-sim | S3 3인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00682 | P1 | MT-M3 | stage-sim | S3 3인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00683 | P1 | MT-M3 | stage-sim | S3 3인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00690 | P1 | MT-M3 | stage-sim | S3 4인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00691 | P1 | MT-M3 | stage-sim | S3 4인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00698 | P1 | MT-M3 | stage-sim | S3 4인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00699 | P1 | MT-M3 | stage-sim | S3 4인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00706 | P1 | MT-M3 | stage-sim | S3 4인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00707 | P1 | MT-M3 | stage-sim | S3 4인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00714 | P1 | MT-M3 | stage-sim | S3 4인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00715 | P1 | MT-M3 | stage-sim | S3 4인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00722 | P1 | MT-M3 | stage-sim | S3 4인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00723 | P1 | MT-M3 | stage-sim | S3 4인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00730 | P1 | MT-M3 | stage-sim | S3 5인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00731 | P1 | MT-M3 | stage-sim | S3 5인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00738 | P1 | MT-M3 | stage-sim | S3 5인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00739 | P1 | MT-M3 | stage-sim | S3 5인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00746 | P1 | MT-M3 | stage-sim | S3 5인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00747 | P1 | MT-M3 | stage-sim | S3 5인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00754 | P1 | MT-M3 | stage-sim | S3 5인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00755 | P1 | MT-M3 | stage-sim | S3 5인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00762 | P1 | MT-M3 | stage-sim | S3 5인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00763 | P1 | MT-M3 | stage-sim | S3 5인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00770 | P1 | MT-M3 | stage-sim | S3 6인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00771 | P1 | MT-M3 | stage-sim | S3 6인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00778 | P1 | MT-M3 | stage-sim | S3 6인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00779 | P1 | MT-M3 | stage-sim | S3 6인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00786 | P1 | MT-M3 | stage-sim | S3 6인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00787 | P1 | MT-M3 | stage-sim | S3 6인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00794 | P1 | MT-M3 | stage-sim | S3 6인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00795 | P1 | MT-M3 | stage-sim | S3 6인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00802 | P1 | MT-M3 | stage-sim | S3 6인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00803 | P1 | MT-M3 | stage-sim | S3 6인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00810 | P1 | MT-M3 | stage-sim | S3 7인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00811 | P1 | MT-M3 | stage-sim | S3 7인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00818 | P1 | MT-M3 | stage-sim | S3 7인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00819 | P1 | MT-M3 | stage-sim | S3 7인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00826 | P1 | MT-M3 | stage-sim | S3 7인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00827 | P1 | MT-M3 | stage-sim | S3 7인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00834 | P1 | MT-M3 | stage-sim | S3 7인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00835 | P1 | MT-M3 | stage-sim | S3 7인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00842 | P1 | MT-M3 | stage-sim | S3 7인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00843 | P1 | MT-M3 | stage-sim | S3 7인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00850 | P1 | MT-M3 | stage-sim | S4 1인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00851 | P1 | MT-M3 | stage-sim | S4 1인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00858 | P1 | MT-M3 | stage-sim | S4 1인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00859 | P1 | MT-M3 | stage-sim | S4 1인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00866 | P1 | MT-M3 | stage-sim | S4 1인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00867 | P1 | MT-M3 | stage-sim | S4 1인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00874 | P1 | MT-M3 | stage-sim | S4 1인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00875 | P1 | MT-M3 | stage-sim | S4 1인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00882 | P1 | MT-M3 | stage-sim | S4 1인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00883 | P1 | MT-M3 | stage-sim | S4 1인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00890 | P1 | MT-M3 | stage-sim | S4 2인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00891 | P1 | MT-M3 | stage-sim | S4 2인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00898 | P1 | MT-M3 | stage-sim | S4 2인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00899 | P1 | MT-M3 | stage-sim | S4 2인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00906 | P1 | MT-M3 | stage-sim | S4 2인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00907 | P1 | MT-M3 | stage-sim | S4 2인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00914 | P1 | MT-M3 | stage-sim | S4 2인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00915 | P1 | MT-M3 | stage-sim | S4 2인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00922 | P1 | MT-M3 | stage-sim | S4 2인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00923 | P1 | MT-M3 | stage-sim | S4 2인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00930 | P1 | MT-M3 | stage-sim | S4 3인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00931 | P1 | MT-M3 | stage-sim | S4 3인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00938 | P1 | MT-M3 | stage-sim | S4 3인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00939 | P1 | MT-M3 | stage-sim | S4 3인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00946 | P1 | MT-M3 | stage-sim | S4 3인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00947 | P1 | MT-M3 | stage-sim | S4 3인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00954 | P1 | MT-M3 | stage-sim | S4 3인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00955 | P1 | MT-M3 | stage-sim | S4 3인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00962 | P1 | MT-M3 | stage-sim | S4 3인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00963 | P1 | MT-M3 | stage-sim | S4 3인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00970 | P1 | MT-M3 | stage-sim | S4 4인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00971 | P1 | MT-M3 | stage-sim | S4 4인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00978 | P1 | MT-M3 | stage-sim | S4 4인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00979 | P1 | MT-M3 | stage-sim | S4 4인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00986 | P1 | MT-M3 | stage-sim | S4 4인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00987 | P1 | MT-M3 | stage-sim | S4 4인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00994 | P1 | MT-M3 | stage-sim | S4 4인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00995 | P1 | MT-M3 | stage-sim | S4 4인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01002 | P1 | MT-M3 | stage-sim | S4 4인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01003 | P1 | MT-M3 | stage-sim | S4 4인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01010 | P1 | MT-M3 | stage-sim | S4 5인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01011 | P1 | MT-M3 | stage-sim | S4 5인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01018 | P1 | MT-M3 | stage-sim | S4 5인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01019 | P1 | MT-M3 | stage-sim | S4 5인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01026 | P1 | MT-M3 | stage-sim | S4 5인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01027 | P1 | MT-M3 | stage-sim | S4 5인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01034 | P1 | MT-M3 | stage-sim | S4 5인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01035 | P1 | MT-M3 | stage-sim | S4 5인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01042 | P1 | MT-M3 | stage-sim | S4 5인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01043 | P1 | MT-M3 | stage-sim | S4 5인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01050 | P1 | MT-M3 | stage-sim | S4 6인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01051 | P1 | MT-M3 | stage-sim | S4 6인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01058 | P1 | MT-M3 | stage-sim | S4 6인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01059 | P1 | MT-M3 | stage-sim | S4 6인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01066 | P1 | MT-M3 | stage-sim | S4 6인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01067 | P1 | MT-M3 | stage-sim | S4 6인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01074 | P1 | MT-M3 | stage-sim | S4 6인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01075 | P1 | MT-M3 | stage-sim | S4 6인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01082 | P1 | MT-M3 | stage-sim | S4 6인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01083 | P1 | MT-M3 | stage-sim | S4 6인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01090 | P1 | MT-M3 | stage-sim | S4 7인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01091 | P1 | MT-M3 | stage-sim | S4 7인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01098 | P1 | MT-M3 | stage-sim | S4 7인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01099 | P1 | MT-M3 | stage-sim | S4 7인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01106 | P1 | MT-M3 | stage-sim | S4 7인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01107 | P1 | MT-M3 | stage-sim | S4 7인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01114 | P1 | MT-M3 | stage-sim | S4 7인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01115 | P1 | MT-M3 | stage-sim | S4 7인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01122 | P1 | MT-M3 | stage-sim | S4 7인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01123 | P1 | MT-M3 | stage-sim | S4 7인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01130 | P1 | MT-M3 | stage-sim | S5 1인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01131 | P1 | MT-M3 | stage-sim | S5 1인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01138 | P1 | MT-M3 | stage-sim | S5 1인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01139 | P1 | MT-M3 | stage-sim | S5 1인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01146 | P1 | MT-M3 | stage-sim | S5 1인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01147 | P1 | MT-M3 | stage-sim | S5 1인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01154 | P1 | MT-M3 | stage-sim | S5 1인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01155 | P1 | MT-M3 | stage-sim | S5 1인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01162 | P1 | MT-M3 | stage-sim | S5 1인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01163 | P1 | MT-M3 | stage-sim | S5 1인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01170 | P1 | MT-M3 | stage-sim | S5 2인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01171 | P1 | MT-M3 | stage-sim | S5 2인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01178 | P1 | MT-M3 | stage-sim | S5 2인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01179 | P1 | MT-M3 | stage-sim | S5 2인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01186 | P1 | MT-M3 | stage-sim | S5 2인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01187 | P1 | MT-M3 | stage-sim | S5 2인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01194 | P1 | MT-M3 | stage-sim | S5 2인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01195 | P1 | MT-M3 | stage-sim | S5 2인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01202 | P1 | MT-M3 | stage-sim | S5 2인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01203 | P1 | MT-M3 | stage-sim | S5 2인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01210 | P1 | MT-M3 | stage-sim | S5 3인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01211 | P1 | MT-M3 | stage-sim | S5 3인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01218 | P1 | MT-M3 | stage-sim | S5 3인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01219 | P1 | MT-M3 | stage-sim | S5 3인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01226 | P1 | MT-M3 | stage-sim | S5 3인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01227 | P1 | MT-M3 | stage-sim | S5 3인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01234 | P1 | MT-M3 | stage-sim | S5 3인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01235 | P1 | MT-M3 | stage-sim | S5 3인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01242 | P1 | MT-M3 | stage-sim | S5 3인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01243 | P1 | MT-M3 | stage-sim | S5 3인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01250 | P1 | MT-M3 | stage-sim | S5 4인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01251 | P1 | MT-M3 | stage-sim | S5 4인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01258 | P1 | MT-M3 | stage-sim | S5 4인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01259 | P1 | MT-M3 | stage-sim | S5 4인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01266 | P1 | MT-M3 | stage-sim | S5 4인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01267 | P1 | MT-M3 | stage-sim | S5 4인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01274 | P1 | MT-M3 | stage-sim | S5 4인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01275 | P1 | MT-M3 | stage-sim | S5 4인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01282 | P1 | MT-M3 | stage-sim | S5 4인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01283 | P1 | MT-M3 | stage-sim | S5 4인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01290 | P1 | MT-M3 | stage-sim | S5 5인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01291 | P1 | MT-M3 | stage-sim | S5 5인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01298 | P1 | MT-M3 | stage-sim | S5 5인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01299 | P1 | MT-M3 | stage-sim | S5 5인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01306 | P1 | MT-M3 | stage-sim | S5 5인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01307 | P1 | MT-M3 | stage-sim | S5 5인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01314 | P1 | MT-M3 | stage-sim | S5 5인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01315 | P1 | MT-M3 | stage-sim | S5 5인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01322 | P1 | MT-M3 | stage-sim | S5 5인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01323 | P1 | MT-M3 | stage-sim | S5 5인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01330 | P1 | MT-M3 | stage-sim | S5 6인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01331 | P1 | MT-M3 | stage-sim | S5 6인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01338 | P1 | MT-M3 | stage-sim | S5 6인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01339 | P1 | MT-M3 | stage-sim | S5 6인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01346 | P1 | MT-M3 | stage-sim | S5 6인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01347 | P1 | MT-M3 | stage-sim | S5 6인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01354 | P1 | MT-M3 | stage-sim | S5 6인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01355 | P1 | MT-M3 | stage-sim | S5 6인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01362 | P1 | MT-M3 | stage-sim | S5 6인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01363 | P1 | MT-M3 | stage-sim | S5 6인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01370 | P1 | MT-M3 | stage-sim | S5 7인 single_straight seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01371 | P1 | MT-M3 | stage-sim | S5 7인 single_straight seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01378 | P1 | MT-M3 | stage-sim | S5 7인 two_crossing seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01379 | P1 | MT-M3 | stage-sim | S5 7인 two_crossing seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01386 | P1 | MT-M3 | stage-sim | S5 7인 wall_break seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01387 | P1 | MT-M3 | stage-sim | S5 7인 wall_break seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01394 | P1 | MT-M3 | stage-sim | S5 7인 choke_wave seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01395 | P1 | MT-M3 | stage-sim | S5 7인 choke_wave seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01402 | P1 | MT-M3 | stage-sim | S5 7인 avalanche seed 0 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-01403 | P1 | MT-M3 | stage-sim | S5 7인 avalanche seed 1 | 진행 불가·무예고 확정사망·벽 완전봉쇄 없이 결과가 종료되고 모든 불변식이 유지 |
| MT-00009 | P1 | MT-M4 | fun | 연쇄 사망 태그 | chain_death 1건으로 묶이고 참여자·원인이 연결 |
