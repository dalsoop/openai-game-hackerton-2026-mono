# 8원 모으기 — P0/P1 완료 게이트

- P0: **118개**
- P1: **547개**
- P0 또는 P1 중 하나라도 미완료면 다음 공개 빌드·아트 교체·온라인 확장을 진행하지 않는다.
- 실제 상태 기록은 `CHECKLIST_VIEWER.html`, CSV 또는 팀 이슈 트래커 중 하나를 정답으로 정하고 중복 관리하지 않는다.

| ID | 등급 | 마일스톤 | 영역 | 항목 | 통과 기준 |
|---|---:|---|---|---|---|
| 8W-00001 | P0 | 8W-M0 | crystal | 한 번 채취로 광물 획득 | carried 상태로 전환되고 운반자 표식 표시 |
| 8W-00002 | P0 | 8W-M0 | bank | 자기 은행 예치 | delivered와 승자 확정 |
| 8W-00003 | P0 | 8W-M2 | drop | 사망 광물 드롭 | 같은 틱 현장 dropped, 7초 복귀 타이머 |
| 8W-00004 | P0 | 8W-M2 | pickup | 동시 줍기 우선순위 | 거리→미보유 시간→ID 순서로 단일 소유 |
| 8W-01607 | P0 | 8W-M2 | crystal-lifecycle | carried + death / 슬롯 1 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01608 | P0 | 8W-M2 | crystal-lifecycle | carried + death / 슬롯 2 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01609 | P0 | 8W-M2 | crystal-lifecycle | carried + death / 슬롯 3 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01610 | P0 | 8W-M2 | crystal-lifecycle | carried + death / 슬롯 4 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01611 | P0 | 8W-M2 | crystal-lifecycle | carried + death / 슬롯 5 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01612 | P0 | 8W-M2 | crystal-lifecycle | carried + death / 슬롯 6 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01613 | P0 | 8W-M2 | crystal-lifecycle | carried + death / 슬롯 7 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01614 | P0 | 8W-M2 | crystal-lifecycle | carried + death / 슬롯 8 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01663 | P0 | 8W-M2 | crystal-lifecycle | carried + two_interactors / 슬롯 1 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01664 | P0 | 8W-M2 | crystal-lifecycle | carried + two_interactors / 슬롯 2 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01665 | P0 | 8W-M2 | crystal-lifecycle | carried + two_interactors / 슬롯 3 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01666 | P0 | 8W-M2 | crystal-lifecycle | carried + two_interactors / 슬롯 4 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01667 | P0 | 8W-M2 | crystal-lifecycle | carried + two_interactors / 슬롯 5 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01668 | P0 | 8W-M2 | crystal-lifecycle | carried + two_interactors / 슬롯 6 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01669 | P0 | 8W-M2 | crystal-lifecycle | carried + two_interactors / 슬롯 7 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01670 | P0 | 8W-M2 | crystal-lifecycle | carried + two_interactors / 슬롯 8 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01687 | P0 | 8W-M2 | crystal-lifecycle | dropped + death / 슬롯 1 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01688 | P0 | 8W-M2 | crystal-lifecycle | dropped + death / 슬롯 2 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01689 | P0 | 8W-M2 | crystal-lifecycle | dropped + death / 슬롯 3 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01690 | P0 | 8W-M2 | crystal-lifecycle | dropped + death / 슬롯 4 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01691 | P0 | 8W-M2 | crystal-lifecycle | dropped + death / 슬롯 5 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01692 | P0 | 8W-M2 | crystal-lifecycle | dropped + death / 슬롯 6 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01693 | P0 | 8W-M2 | crystal-lifecycle | dropped + death / 슬롯 7 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01694 | P0 | 8W-M2 | crystal-lifecycle | dropped + death / 슬롯 8 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01743 | P0 | 8W-M2 | crystal-lifecycle | dropped + two_interactors / 슬롯 1 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01744 | P0 | 8W-M2 | crystal-lifecycle | dropped + two_interactors / 슬롯 2 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01745 | P0 | 8W-M2 | crystal-lifecycle | dropped + two_interactors / 슬롯 3 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01746 | P0 | 8W-M2 | crystal-lifecycle | dropped + two_interactors / 슬롯 4 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01747 | P0 | 8W-M2 | crystal-lifecycle | dropped + two_interactors / 슬롯 5 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01748 | P0 | 8W-M2 | crystal-lifecycle | dropped + two_interactors / 슬롯 6 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01749 | P0 | 8W-M2 | crystal-lifecycle | dropped + two_interactors / 슬롯 7 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-01750 | P0 | 8W-M2 | crystal-lifecycle | dropped + two_interactors / 슬롯 8 | 광물 소유자는 최대 1명이고 소실·복제·음수 타이머가 없다 |
| 8W-00006 | P0 | 8W-M4 | overtime | 8분 규칙 | 문 전부 개방, 예치 0.4초, 속도 페널티 제거 |
| 8W-COM-00001 | P0 | M0 | boot | 앱 최초 부팅 | Viewport가 2초 이내 생성되고 Output/Debugger 오류이 비어 있다 |
| 8W-COM-00002 | P0 | M0 | loop | 60Hz 고정 틱 | 최종 상태 해시가 모두 동일하다 |
| 8W-COM-00003 | P0 | M0 | rng | randf()/randi() 금지 | 시뮬레이션 경로에서 randf()/randi() 호출 0건 |
| 8W-COM-00004 | P0 | M0 | input | 포커스 상실 키 해제 | 복귀 시 캐릭터가 계속 이동하지 않는다 |
| 8W-COM-00005 | P0 | M0 | input | 우클릭 브라우저 메뉴 차단 | 브라우저 컨텍스트 메뉴가 뜨지 않고 게임 명령만 기록된다 |
| 8W-COM-00006 | P0 | M0 | replay | 입력 리플레이 | 300틱 간격 모든 상태 해시가 일치한다 |
| 8W-COM-00007 | P0 | M0 | data | 설정 해시 | 정규화된 configHash가 동일하다 |
| 8W-COM-00019 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00020 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00021 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00022 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00023 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00059 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00060 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00061 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00062 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00063 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00099 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00100 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00101 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00102 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00103 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00139 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00140 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00141 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00142 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00143 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00179 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00180 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00181 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00182 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00183 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00219 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00220 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00221 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00222 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-COM-00223 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| 8W-GD-0001 | P0 | M0 | boot | Godot 4.7.1 프로젝트 import | 스크립트·씬 import 오류 0건, Main Scene 지정 |
| 8W-GD-0002 | P0 | M0 | boot | F5 최초 실행 | 2초 안에 회색상자 월드와 HUD가 표시되고 오류 0건 |
| 8W-GD-0003 | P0 | M0 | boot | 독립 ZIP 의존성 | 외부 상대경로·공통 저장소 없이 실행 |
| 8W-GD-0004 | P0 | M0 | loop | physics tick 60 고정 | 정확히 60 |
| 8W-GD-0005 | P0 | M0 | loop | _process 판정 변경 금지 | _process에서 GameWorld의 판정 필드를 직접 변경하는 코드 0건 |
| 8W-GD-0006 | P0 | M0 | loop | Godot 물리 콜백 순서 비의존 | 명령 정렬·커스텀 판정 결과 해시 동일 |
| 8W-GD-0007 | P0 | M0 | rng | 시뮬레이션 randf/randi 금지 | 시드 RNG 래퍼 외 randf/randi/randomize 호출 0건 |
| 8W-GD-0008 | P0 | M0 | rng | 시드 재현 | 300틱 간격 상태 해시 100% 일치 |
| 8W-GD-0009 | P0 | M0 | input | edge 입력 1회 소비 | 기술 명령은 1회만 생성 |
| 8W-GD-0010 | P0 | M0 | input | 포커스 상실 입력 해제 | 이동·공격 hold가 고착되지 않음 |
| 8W-GD-0012 | P0 | M0 | viewport | 1600x900 논리 좌표 | 월드 판정 좌표 동일, 레터박스/확장 정책대로 표시 |
| 8W-GD-0013 | P0 | M0 | camera | Camera2D와 HUD 분리 | CanvasLayer HUD는 화면에 고정 |
| 8W-GD-0015 | P0 | M0 | render | 렌더 상태 역류 금지 | 다음 physics tick 판정에 영향 0 |
| 8W-GD-0017 | P0 | M0 | scene | 씬 reload 없는 매치 재시작 | Node 수·메모리·시그널 연결 수가 기준 ±1% 이내 |
| 8W-GD-0018 | P0 | M0 | scene | World 교체 후 이전 참조 제거 | 이전 World의 엔티티·이벤트가 보이지 않음 |
| 8W-GD-0019 | P0 | M0 | data | JSON 문법과 스키마 | 파싱 오류·중복 ID·미존재 참조 0건 |
| 8W-GD-0020 | P0 | M0 | data | 잘못된 데이터 fail-fast | 명확한 경로·키와 함께 부팅 중단, 조용한 기본값 대체 없음 |
| 8W-GD-0021 | P0 | M0 | event-log | EventLog 순번 | event_id가 중복 없이 증가하고 tick/actor/target 포함 |
| 8W-GD-0022 | P0 | M0 | invariant | NaN·INF 즉시 검출 | 불변식 오류와 시드·tick 덤프 후 테스트 실패 |
| 8W-GD-0023 | P0 | M0 | headless | 헤드리스 smoke 진입 | 종료코드 0과 SMOKE_OK JSON 출력 |
| 8W-GD-0024 | P0 | M0 | headless | 헤드리스 시간 독립 | 게임 판정이 렌더 노드 없이 완료 |
| 8W-GD-0049 | P0 | M0 | starter | 스타터 조작 계약 | 각 입력의 즉시 피드백과 비용·쿨다운이 HUD/월드에 표시 |
| 8W-GD-0050 | P0 | M0 | starter | 인간 1+CPU 구성 | 인간 1명과 CPU 5명이 생성되고 CPU가 목표 행동 시작 |
| 8W-GD-0051 | P0 | M0 | starter | R 새 시드 재시작 | 즉시 새 World가 만들어지고 seed가 1씩 증가 |
| 8W-COM-00008 | P0 | M1 | collision | NaN 방지 | 위치·속도·체력에 NaN/Infinity가 없다 |
| 8W-GD-0025 | P0 | M1 | ai | CPU도 PlayerCommand 사용 | 인간과 동일 명령 스키마·검증·쿨다운 경로 사용 |
| 8W-GD-0026 | P0 | M1 | ai-audit | CPU 숨은 상태 접근 감사 | Observation에 없던 값으로 행동이 바뀌지 않음 |
| 8W-GD-0030 | P0 | M1 | performance | physics 프레임 예산 | p95 simulation step 8ms 이하 |
| 8W-GD-0032 | P0 | M1 | replay | 명령 리플레이 | 최종 결과·중간 해시·중요 EventLog 동일 |
| 8W-GD-0033 | P0 | M1 | replay | 리플레이 버전 거부 | 호환 불가 사유 표시 후 실행 거부 |
| 8W-GD-0034 | P0 | M1 | ux | 실패 원인 5초 식별 | 80% 이상이 원인 행위자·사건을 5초 내 식별 |
| 8W-GD-0037 | P0 | M1 | pause | 일시정지 tick 정지 | World tick·쿨다운·스폰이 증가하지 않음 |
| 8W-GD-0053 | P0 | M1 | fun | 핵심 재미 사건 발생률 | 문서의 핵심 재미 사건이 목표 빈도 범위에 들어옴 |
| 8W-GD-0054 | P0 | M1 | fun | 실패도 관전 가능 | 매치가 계속 진행되고 중요한 사건·승패 원인이 표시 |
| 8W-COM-00010 | P0 | M2 | ai | 숨은 정보 금지 | 비가시 엔티티를 직접 action target으로 선택하지 않는다 |
| 8W-COM-00011 | P0 | M2 | ai | 반응 지연 | 130ms 미만 반응 0건, 평균 175~270ms |
| 8W-GD-0039 | P0 | M2 | export | Windows export 입력 유지 | 편집기와 조작·판정·결과 동일 |
| 8W-GD-0043 | P0 | M2 | cleanup | 결과 확정 후 상태 고정 | 점수·HP·소유권·스폰 변화 0 |
| 8W-GD-0045 | P0 | M2 | package | smoke/playability 회귀 검사 | 두 테스트가 오류 없이 종료 |
| 8W-GD-0046 | P0 | M2 | package | 문서-코드 경로 정합 | 존재하지 않는 파일 0건 |
| 8W-GD-0058 | P0 | M2 | acceptance | 최종 수락 지표 | 기능 오류 없이 핵심 재미가 최소 70% 판에서 체감되고 원인 로그 존재 |
| 8W-COM-00013 | P0 | M3 | performance | 풀 누수 | 활성 수가 안정된 뒤 풀 총량이 10% 이상 증가하지 않는다 |
| 8W-COM-00014 | P0 | M3 | performance | 시뮬레이션 오버런 | 최대 5틱 실행 후 잔여 누적을 버리고 입력 가능 |
| 8W-COM-00017 | P0 | M4 | telemetry | 원인 이벤트 연결 | 손실 이벤트가 최대 6단계 원인으로 역추적 가능 |
| 8W-00005 | P1 | 8W-M3 | ai | 공개 위치 지연 | CPU가 0.25초 지연 위치와 관측 속도만 사용 |
| 8W-00007 | P1 | 8W-M3 | chase-sim | north / full_hp / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00008 | P1 | 8W-M3 | chase-sim | north / full_hp / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00019 | P1 | 8W-M3 | chase-sim | north / full_hp / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00020 | P1 | 8W-M3 | chase-sim | north / full_hp / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00031 | P1 | 8W-M3 | chase-sim | north / full_hp / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00032 | P1 | 8W-M3 | chase-sim | north / full_hp / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00043 | P1 | 8W-M3 | chase-sim | north / full_hp / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00044 | P1 | 8W-M3 | chase-sim | north / full_hp / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00055 | P1 | 8W-M3 | chase-sim | north / full_hp / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00056 | P1 | 8W-M3 | chase-sim | north / full_hp / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00067 | P1 | 8W-M3 | chase-sim | north / low_hp / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00068 | P1 | 8W-M3 | chase-sim | north / low_hp / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00079 | P1 | 8W-M3 | chase-sim | north / low_hp / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00080 | P1 | 8W-M3 | chase-sim | north / low_hp / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00091 | P1 | 8W-M3 | chase-sim | north / low_hp / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00092 | P1 | 8W-M3 | chase-sim | north / low_hp / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00103 | P1 | 8W-M3 | chase-sim | north / low_hp / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00104 | P1 | 8W-M3 | chase-sim | north / low_hp / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00115 | P1 | 8W-M3 | chase-sim | north / low_hp / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00116 | P1 | 8W-M3 | chase-sim | north / low_hp / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00127 | P1 | 8W-M3 | chase-sim | north / dash_ready / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00128 | P1 | 8W-M3 | chase-sim | north / dash_ready / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00139 | P1 | 8W-M3 | chase-sim | north / dash_ready / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00140 | P1 | 8W-M3 | chase-sim | north / dash_ready / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00151 | P1 | 8W-M3 | chase-sim | north / dash_ready / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00152 | P1 | 8W-M3 | chase-sim | north / dash_ready / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00163 | P1 | 8W-M3 | chase-sim | north / dash_ready / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00164 | P1 | 8W-M3 | chase-sim | north / dash_ready / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00175 | P1 | 8W-M3 | chase-sim | north / dash_ready / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00176 | P1 | 8W-M3 | chase-sim | north / dash_ready / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00187 | P1 | 8W-M3 | chase-sim | north / dash_down / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00188 | P1 | 8W-M3 | chase-sim | north / dash_down / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00199 | P1 | 8W-M3 | chase-sim | north / dash_down / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00200 | P1 | 8W-M3 | chase-sim | north / dash_down / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00211 | P1 | 8W-M3 | chase-sim | north / dash_down / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00212 | P1 | 8W-M3 | chase-sim | north / dash_down / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00223 | P1 | 8W-M3 | chase-sim | north / dash_down / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00224 | P1 | 8W-M3 | chase-sim | north / dash_down / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00235 | P1 | 8W-M3 | chase-sim | north / dash_down / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00236 | P1 | 8W-M3 | chase-sim | north / dash_down / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00247 | P1 | 8W-M3 | chase-sim | north / near_bank / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00248 | P1 | 8W-M3 | chase-sim | north / near_bank / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00259 | P1 | 8W-M3 | chase-sim | north / near_bank / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00260 | P1 | 8W-M3 | chase-sim | north / near_bank / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00271 | P1 | 8W-M3 | chase-sim | north / near_bank / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00272 | P1 | 8W-M3 | chase-sim | north / near_bank / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00283 | P1 | 8W-M3 | chase-sim | north / near_bank / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00284 | P1 | 8W-M3 | chase-sim | north / near_bank / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00295 | P1 | 8W-M3 | chase-sim | north / near_bank / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00296 | P1 | 8W-M3 | chase-sim | north / near_bank / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00307 | P1 | 8W-M3 | chase-sim | north / near_mine / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00308 | P1 | 8W-M3 | chase-sim | north / near_mine / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00319 | P1 | 8W-M3 | chase-sim | north / near_mine / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00320 | P1 | 8W-M3 | chase-sim | north / near_mine / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00331 | P1 | 8W-M3 | chase-sim | north / near_mine / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00332 | P1 | 8W-M3 | chase-sim | north / near_mine / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00343 | P1 | 8W-M3 | chase-sim | north / near_mine / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00344 | P1 | 8W-M3 | chase-sim | north / near_mine / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00355 | P1 | 8W-M3 | chase-sim | north / near_mine / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00356 | P1 | 8W-M3 | chase-sim | north / near_mine / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00367 | P1 | 8W-M3 | chase-sim | north / door_closing / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00368 | P1 | 8W-M3 | chase-sim | north / door_closing / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00379 | P1 | 8W-M3 | chase-sim | north / door_closing / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00380 | P1 | 8W-M3 | chase-sim | north / door_closing / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00391 | P1 | 8W-M3 | chase-sim | north / door_closing / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00392 | P1 | 8W-M3 | chase-sim | north / door_closing / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00403 | P1 | 8W-M3 | chase-sim | north / door_closing / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00404 | P1 | 8W-M3 | chase-sim | north / door_closing / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00415 | P1 | 8W-M3 | chase-sim | north / door_closing / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00416 | P1 | 8W-M3 | chase-sim | north / door_closing / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00427 | P1 | 8W-M3 | chase-sim | north / two_chasers / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00428 | P1 | 8W-M3 | chase-sim | north / two_chasers / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00439 | P1 | 8W-M3 | chase-sim | north / two_chasers / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00440 | P1 | 8W-M3 | chase-sim | north / two_chasers / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00451 | P1 | 8W-M3 | chase-sim | north / two_chasers / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00452 | P1 | 8W-M3 | chase-sim | north / two_chasers / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00463 | P1 | 8W-M3 | chase-sim | north / two_chasers / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00464 | P1 | 8W-M3 | chase-sim | north / two_chasers / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00475 | P1 | 8W-M3 | chase-sim | north / two_chasers / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00476 | P1 | 8W-M3 | chase-sim | north / two_chasers / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00487 | P1 | 8W-M3 | chase-sim | center / full_hp / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00488 | P1 | 8W-M3 | chase-sim | center / full_hp / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00499 | P1 | 8W-M3 | chase-sim | center / full_hp / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00500 | P1 | 8W-M3 | chase-sim | center / full_hp / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00511 | P1 | 8W-M3 | chase-sim | center / full_hp / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00512 | P1 | 8W-M3 | chase-sim | center / full_hp / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00523 | P1 | 8W-M3 | chase-sim | center / full_hp / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00524 | P1 | 8W-M3 | chase-sim | center / full_hp / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00535 | P1 | 8W-M3 | chase-sim | center / full_hp / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00536 | P1 | 8W-M3 | chase-sim | center / full_hp / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00547 | P1 | 8W-M3 | chase-sim | center / low_hp / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00548 | P1 | 8W-M3 | chase-sim | center / low_hp / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00559 | P1 | 8W-M3 | chase-sim | center / low_hp / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00560 | P1 | 8W-M3 | chase-sim | center / low_hp / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00571 | P1 | 8W-M3 | chase-sim | center / low_hp / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00572 | P1 | 8W-M3 | chase-sim | center / low_hp / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00583 | P1 | 8W-M3 | chase-sim | center / low_hp / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00584 | P1 | 8W-M3 | chase-sim | center / low_hp / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00595 | P1 | 8W-M3 | chase-sim | center / low_hp / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00596 | P1 | 8W-M3 | chase-sim | center / low_hp / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00607 | P1 | 8W-M3 | chase-sim | center / dash_ready / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00608 | P1 | 8W-M3 | chase-sim | center / dash_ready / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00619 | P1 | 8W-M3 | chase-sim | center / dash_ready / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00620 | P1 | 8W-M3 | chase-sim | center / dash_ready / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00631 | P1 | 8W-M3 | chase-sim | center / dash_ready / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00632 | P1 | 8W-M3 | chase-sim | center / dash_ready / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00643 | P1 | 8W-M3 | chase-sim | center / dash_ready / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00644 | P1 | 8W-M3 | chase-sim | center / dash_ready / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00655 | P1 | 8W-M3 | chase-sim | center / dash_ready / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00656 | P1 | 8W-M3 | chase-sim | center / dash_ready / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00667 | P1 | 8W-M3 | chase-sim | center / dash_down / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00668 | P1 | 8W-M3 | chase-sim | center / dash_down / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00679 | P1 | 8W-M3 | chase-sim | center / dash_down / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00680 | P1 | 8W-M3 | chase-sim | center / dash_down / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00691 | P1 | 8W-M3 | chase-sim | center / dash_down / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00692 | P1 | 8W-M3 | chase-sim | center / dash_down / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00703 | P1 | 8W-M3 | chase-sim | center / dash_down / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00704 | P1 | 8W-M3 | chase-sim | center / dash_down / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00715 | P1 | 8W-M3 | chase-sim | center / dash_down / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00716 | P1 | 8W-M3 | chase-sim | center / dash_down / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00727 | P1 | 8W-M3 | chase-sim | center / near_bank / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00728 | P1 | 8W-M3 | chase-sim | center / near_bank / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00739 | P1 | 8W-M3 | chase-sim | center / near_bank / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00740 | P1 | 8W-M3 | chase-sim | center / near_bank / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00751 | P1 | 8W-M3 | chase-sim | center / near_bank / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00752 | P1 | 8W-M3 | chase-sim | center / near_bank / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00763 | P1 | 8W-M3 | chase-sim | center / near_bank / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00764 | P1 | 8W-M3 | chase-sim | center / near_bank / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00775 | P1 | 8W-M3 | chase-sim | center / near_bank / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00776 | P1 | 8W-M3 | chase-sim | center / near_bank / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00787 | P1 | 8W-M3 | chase-sim | center / near_mine / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00788 | P1 | 8W-M3 | chase-sim | center / near_mine / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00799 | P1 | 8W-M3 | chase-sim | center / near_mine / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00800 | P1 | 8W-M3 | chase-sim | center / near_mine / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00811 | P1 | 8W-M3 | chase-sim | center / near_mine / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00812 | P1 | 8W-M3 | chase-sim | center / near_mine / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00823 | P1 | 8W-M3 | chase-sim | center / near_mine / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00824 | P1 | 8W-M3 | chase-sim | center / near_mine / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00835 | P1 | 8W-M3 | chase-sim | center / near_mine / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00836 | P1 | 8W-M3 | chase-sim | center / near_mine / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00847 | P1 | 8W-M3 | chase-sim | center / door_closing / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00848 | P1 | 8W-M3 | chase-sim | center / door_closing / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00859 | P1 | 8W-M3 | chase-sim | center / door_closing / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00860 | P1 | 8W-M3 | chase-sim | center / door_closing / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00871 | P1 | 8W-M3 | chase-sim | center / door_closing / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00872 | P1 | 8W-M3 | chase-sim | center / door_closing / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00883 | P1 | 8W-M3 | chase-sim | center / door_closing / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00884 | P1 | 8W-M3 | chase-sim | center / door_closing / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00895 | P1 | 8W-M3 | chase-sim | center / door_closing / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00896 | P1 | 8W-M3 | chase-sim | center / door_closing / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00907 | P1 | 8W-M3 | chase-sim | center / two_chasers / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00908 | P1 | 8W-M3 | chase-sim | center / two_chasers / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00919 | P1 | 8W-M3 | chase-sim | center / two_chasers / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00920 | P1 | 8W-M3 | chase-sim | center / two_chasers / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00931 | P1 | 8W-M3 | chase-sim | center / two_chasers / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00932 | P1 | 8W-M3 | chase-sim | center / two_chasers / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00943 | P1 | 8W-M3 | chase-sim | center / two_chasers / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00944 | P1 | 8W-M3 | chase-sim | center / two_chasers / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00955 | P1 | 8W-M3 | chase-sim | center / two_chasers / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00956 | P1 | 8W-M3 | chase-sim | center / two_chasers / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00967 | P1 | 8W-M3 | chase-sim | south / full_hp / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00968 | P1 | 8W-M3 | chase-sim | south / full_hp / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00979 | P1 | 8W-M3 | chase-sim | south / full_hp / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00980 | P1 | 8W-M3 | chase-sim | south / full_hp / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00991 | P1 | 8W-M3 | chase-sim | south / full_hp / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-00992 | P1 | 8W-M3 | chase-sim | south / full_hp / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01003 | P1 | 8W-M3 | chase-sim | south / full_hp / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01004 | P1 | 8W-M3 | chase-sim | south / full_hp / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01015 | P1 | 8W-M3 | chase-sim | south / full_hp / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01016 | P1 | 8W-M3 | chase-sim | south / full_hp / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01027 | P1 | 8W-M3 | chase-sim | south / low_hp / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01028 | P1 | 8W-M3 | chase-sim | south / low_hp / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01039 | P1 | 8W-M3 | chase-sim | south / low_hp / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01040 | P1 | 8W-M3 | chase-sim | south / low_hp / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01051 | P1 | 8W-M3 | chase-sim | south / low_hp / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01052 | P1 | 8W-M3 | chase-sim | south / low_hp / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01063 | P1 | 8W-M3 | chase-sim | south / low_hp / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01064 | P1 | 8W-M3 | chase-sim | south / low_hp / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01075 | P1 | 8W-M3 | chase-sim | south / low_hp / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01076 | P1 | 8W-M3 | chase-sim | south / low_hp / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01087 | P1 | 8W-M3 | chase-sim | south / dash_ready / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01088 | P1 | 8W-M3 | chase-sim | south / dash_ready / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01099 | P1 | 8W-M3 | chase-sim | south / dash_ready / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01100 | P1 | 8W-M3 | chase-sim | south / dash_ready / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01111 | P1 | 8W-M3 | chase-sim | south / dash_ready / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01112 | P1 | 8W-M3 | chase-sim | south / dash_ready / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01123 | P1 | 8W-M3 | chase-sim | south / dash_ready / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01124 | P1 | 8W-M3 | chase-sim | south / dash_ready / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01135 | P1 | 8W-M3 | chase-sim | south / dash_ready / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01136 | P1 | 8W-M3 | chase-sim | south / dash_ready / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01147 | P1 | 8W-M3 | chase-sim | south / dash_down / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01148 | P1 | 8W-M3 | chase-sim | south / dash_down / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01159 | P1 | 8W-M3 | chase-sim | south / dash_down / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01160 | P1 | 8W-M3 | chase-sim | south / dash_down / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01171 | P1 | 8W-M3 | chase-sim | south / dash_down / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01172 | P1 | 8W-M3 | chase-sim | south / dash_down / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01183 | P1 | 8W-M3 | chase-sim | south / dash_down / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01184 | P1 | 8W-M3 | chase-sim | south / dash_down / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01195 | P1 | 8W-M3 | chase-sim | south / dash_down / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01196 | P1 | 8W-M3 | chase-sim | south / dash_down / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01207 | P1 | 8W-M3 | chase-sim | south / near_bank / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01208 | P1 | 8W-M3 | chase-sim | south / near_bank / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01219 | P1 | 8W-M3 | chase-sim | south / near_bank / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01220 | P1 | 8W-M3 | chase-sim | south / near_bank / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01231 | P1 | 8W-M3 | chase-sim | south / near_bank / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01232 | P1 | 8W-M3 | chase-sim | south / near_bank / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01243 | P1 | 8W-M3 | chase-sim | south / near_bank / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01244 | P1 | 8W-M3 | chase-sim | south / near_bank / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01255 | P1 | 8W-M3 | chase-sim | south / near_bank / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01256 | P1 | 8W-M3 | chase-sim | south / near_bank / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01267 | P1 | 8W-M3 | chase-sim | south / near_mine / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01268 | P1 | 8W-M3 | chase-sim | south / near_mine / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01279 | P1 | 8W-M3 | chase-sim | south / near_mine / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01280 | P1 | 8W-M3 | chase-sim | south / near_mine / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01291 | P1 | 8W-M3 | chase-sim | south / near_mine / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01292 | P1 | 8W-M3 | chase-sim | south / near_mine / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01303 | P1 | 8W-M3 | chase-sim | south / near_mine / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01304 | P1 | 8W-M3 | chase-sim | south / near_mine / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01315 | P1 | 8W-M3 | chase-sim | south / near_mine / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01316 | P1 | 8W-M3 | chase-sim | south / near_mine / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01327 | P1 | 8W-M3 | chase-sim | south / door_closing / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01328 | P1 | 8W-M3 | chase-sim | south / door_closing / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01339 | P1 | 8W-M3 | chase-sim | south / door_closing / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01340 | P1 | 8W-M3 | chase-sim | south / door_closing / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01351 | P1 | 8W-M3 | chase-sim | south / door_closing / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01352 | P1 | 8W-M3 | chase-sim | south / door_closing / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01363 | P1 | 8W-M3 | chase-sim | south / door_closing / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01364 | P1 | 8W-M3 | chase-sim | south / door_closing / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01375 | P1 | 8W-M3 | chase-sim | south / door_closing / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01376 | P1 | 8W-M3 | chase-sim | south / door_closing / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01387 | P1 | 8W-M3 | chase-sim | south / two_chasers / 추격 1 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01388 | P1 | 8W-M3 | chase-sim | south / two_chasers / 추격 1 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01399 | P1 | 8W-M3 | chase-sim | south / two_chasers / 추격 2 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01400 | P1 | 8W-M3 | chase-sim | south / two_chasers / 추격 2 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01411 | P1 | 8W-M3 | chase-sim | south / two_chasers / 추격 3 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01412 | P1 | 8W-M3 | chase-sim | south / two_chasers / 추격 3 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01423 | P1 | 8W-M3 | chase-sim | south / two_chasers / 추격 4 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01424 | P1 | 8W-M3 | chase-sim | south / two_chasers / 추격 4 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01435 | P1 | 8W-M3 | chase-sim | south / two_chasers / 추격 5 / seed 0 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01436 | P1 | 8W-M3 | chase-sim | south / two_chasers / 추격 5 / seed 1 | 경로 이탈·벽 관통·완벽 포위 고정 없이 결과가 나고 추격자 역할 예약이 중복되지 않는다 |
| 8W-01847 | P1 | 8W-M3 | door | gate_a 닫힘 기준 -700ms / human | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01848 | P1 | 8W-M3 | door | gate_a 닫힘 기준 -700ms / cpu | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01849 | P1 | 8W-M3 | door | gate_a 닫힘 기준 -700ms / carrier | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01850 | P1 | 8W-M3 | door | gate_a 닫힘 기준 -700ms / dropped_crystal | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01875 | P1 | 8W-M3 | door | gate_a 닫힘 기준 0ms / human | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01876 | P1 | 8W-M3 | door | gate_a 닫힘 기준 0ms / cpu | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01877 | P1 | 8W-M3 | door | gate_a 닫힘 기준 0ms / carrier | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01878 | P1 | 8W-M3 | door | gate_a 닫힘 기준 0ms / dropped_crystal | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01903 | P1 | 8W-M3 | door | gate_a 닫힘 기준 700ms / human | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01904 | P1 | 8W-M3 | door | gate_a 닫힘 기준 700ms / cpu | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01905 | P1 | 8W-M3 | door | gate_a 닫힘 기준 700ms / carrier | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01906 | P1 | 8W-M3 | door | gate_a 닫힘 기준 700ms / dropped_crystal | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01907 | P1 | 8W-M3 | door | gate_b 닫힘 기준 -700ms / human | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01908 | P1 | 8W-M3 | door | gate_b 닫힘 기준 -700ms / cpu | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01909 | P1 | 8W-M3 | door | gate_b 닫힘 기준 -700ms / carrier | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01910 | P1 | 8W-M3 | door | gate_b 닫힘 기준 -700ms / dropped_crystal | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01935 | P1 | 8W-M3 | door | gate_b 닫힘 기준 0ms / human | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01936 | P1 | 8W-M3 | door | gate_b 닫힘 기준 0ms / cpu | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01937 | P1 | 8W-M3 | door | gate_b 닫힘 기준 0ms / carrier | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01938 | P1 | 8W-M3 | door | gate_b 닫힘 기준 0ms / dropped_crystal | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01963 | P1 | 8W-M3 | door | gate_b 닫힘 기준 700ms / human | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01964 | P1 | 8W-M3 | door | gate_b 닫힘 기준 700ms / cpu | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01965 | P1 | 8W-M3 | door | gate_b 닫힘 기준 700ms / carrier | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-01966 | P1 | 8W-M3 | door | gate_b 닫힘 기준 700ms / dropped_crystal | 끼임·벽 통과·광물 소실 없이 정의된 쪽으로 밀려나고 예고와 판정이 일치 |
| 8W-GD-0011 | P1 | M0 | input | 키보드 동시입력 정규화 | 대각선 속도가 축 속도와 동일 |
| 8W-GD-0014 | P1 | M0 | camera | 마우스 월드 좌표 역변환 | 조준점 오차 1 world unit 이하 |
| 8W-GD-0016 | P1 | M0 | render | queue_redraw 호출 상한 | 월드·HUD 각각 physics tick당 최대 1회 |
| 8W-GD-0052 | P1 | M0 | starter | 더미 아트 판정 가독성 | 색·형태·번호만으로 객체 역할과 소유자 식별 |
| 8W-COM-00009 | P1 | M1 | camera | 레터박스 좌표 | 월드 좌표가 보이는 클릭 마커와 2px 이내 일치 |
| 8W-COM-00259 | P1 | M1 | viewport | 960×540 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00260 | P1 | M1 | viewport | 960×540 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00261 | P1 | M1 | viewport | 960×540 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00262 | P1 | M1 | viewport | 960×540 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00263 | P1 | M1 | viewport | 960×540 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00264 | P1 | M1 | viewport | 960×540 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00265 | P1 | M1 | viewport | 960×540 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00266 | P1 | M1 | viewport | 960×540 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00267 | P1 | M1 | viewport | 960×540 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00268 | P1 | M1 | viewport | 960×540 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00269 | P1 | M1 | viewport | 960×540 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00270 | P1 | M1 | viewport | 960×540 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00271 | P1 | M1 | viewport | 960×540 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00272 | P1 | M1 | viewport | 960×540 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00273 | P1 | M1 | viewport | 960×540 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00304 | P1 | M1 | viewport | 1600×900 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00305 | P1 | M1 | viewport | 1600×900 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00306 | P1 | M1 | viewport | 1600×900 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00307 | P1 | M1 | viewport | 1600×900 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00308 | P1 | M1 | viewport | 1600×900 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00309 | P1 | M1 | viewport | 1600×900 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00310 | P1 | M1 | viewport | 1600×900 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00311 | P1 | M1 | viewport | 1600×900 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00312 | P1 | M1 | viewport | 1600×900 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00313 | P1 | M1 | viewport | 1600×900 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00314 | P1 | M1 | viewport | 1600×900 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00315 | P1 | M1 | viewport | 1600×900 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00316 | P1 | M1 | viewport | 1600×900 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00317 | P1 | M1 | viewport | 1600×900 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00318 | P1 | M1 | viewport | 1600×900 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00349 | P1 | M1 | viewport | 3840×2160 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00350 | P1 | M1 | viewport | 3840×2160 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00351 | P1 | M1 | viewport | 3840×2160 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00352 | P1 | M1 | viewport | 3840×2160 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00353 | P1 | M1 | viewport | 3840×2160 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00354 | P1 | M1 | viewport | 3840×2160 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00355 | P1 | M1 | viewport | 3840×2160 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00356 | P1 | M1 | viewport | 3840×2160 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00357 | P1 | M1 | viewport | 3840×2160 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00358 | P1 | M1 | viewport | 3840×2160 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00359 | P1 | M1 | viewport | 3840×2160 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00360 | P1 | M1 | viewport | 3840×2160 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00361 | P1 | M1 | viewport | 3840×2160 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00362 | P1 | M1 | viewport | 3840×2160 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00363 | P1 | M1 | viewport | 3840×2160 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| 8W-COM-00364 | P1 | M1 | input | 입력 move_up / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00370 | P1 | M1 | input | 입력 move_up / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00373 | P1 | M1 | input | 입력 move_up / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00374 | P1 | M1 | input | 입력 move_down / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00380 | P1 | M1 | input | 입력 move_down / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00383 | P1 | M1 | input | 입력 move_down / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00384 | P1 | M1 | input | 입력 move_left / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00390 | P1 | M1 | input | 입력 move_left / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00393 | P1 | M1 | input | 입력 move_left / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00394 | P1 | M1 | input | 입력 move_right / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00400 | P1 | M1 | input | 입력 move_right / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00403 | P1 | M1 | input | 입력 move_right / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00404 | P1 | M1 | input | 입력 diagonal / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00410 | P1 | M1 | input | 입력 diagonal / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00413 | P1 | M1 | input | 입력 diagonal / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00414 | P1 | M1 | input | 입력 primary / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00420 | P1 | M1 | input | 입력 primary / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00423 | P1 | M1 | input | 입력 primary / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00424 | P1 | M1 | input | 입력 secondary / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00430 | P1 | M1 | input | 입력 secondary / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00433 | P1 | M1 | input | 입력 secondary / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00434 | P1 | M1 | input | 입력 ability_q / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00440 | P1 | M1 | input | 입력 ability_q / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00443 | P1 | M1 | input | 입력 ability_q / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00444 | P1 | M1 | input | 입력 ability_w / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00450 | P1 | M1 | input | 입력 ability_w / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00453 | P1 | M1 | input | 입력 ability_w / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00454 | P1 | M1 | input | 입력 ability_e / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00460 | P1 | M1 | input | 입력 ability_e / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00463 | P1 | M1 | input | 입력 ability_e / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00464 | P1 | M1 | input | 입력 ability_r / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00470 | P1 | M1 | input | 입력 ability_r / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00473 | P1 | M1 | input | 입력 ability_r / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00474 | P1 | M1 | input | 입력 ability_f / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00480 | P1 | M1 | input | 입력 ability_f / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00483 | P1 | M1 | input | 입력 ability_f / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00484 | P1 | M1 | input | 입력 dash / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00490 | P1 | M1 | input | 입력 dash / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00493 | P1 | M1 | input | 입력 dash / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00494 | P1 | M1 | input | 입력 ping / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00500 | P1 | M1 | input | 입력 ping / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00503 | P1 | M1 | input | 입력 ping / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00504 | P1 | M1 | input | 입력 pause / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00510 | P1 | M1 | input | 입력 pause / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00513 | P1 | M1 | input | 입력 pause / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00514 | P1 | M1 | input | 입력 restart / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00520 | P1 | M1 | input | 입력 restart / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-COM-00523 | P1 | M1 | input | 입력 restart / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| 8W-GD-0027 | P1 | M1 | ai | CPU 반응 지연 | 프로필 min/max 안에서 T 이후 반응, 0틱 완벽반응 0건 |
| 8W-GD-0028 | P1 | M1 | ai | CPU 동일 실수 반복 제한 | 같은 치명 실수를 연속 2회 이상 의도 삽입하지 않음 |
| 8W-GD-0029 | P1 | M1 | ai | 인간 슬롯 편향 없음 | CPU 목표·지원·공격 확률이 슬롯 평균 허용오차 이내 |
| 8W-GD-0031 | P1 | M1 | performance | 렌더 객체 증가 상한 | CanvasItem/Node 수가 설계 상한 이내이며 계속 증가하지 않음 |
| 8W-GD-0035 | P1 | M1 | ux | CPU 구분 가독성 | 인간 캐릭터를 1초 내 찾는 성공률 95% 이상 |
| 8W-GD-0036 | P1 | M1 | audio | 판정과 오디오 분리 | 상태 해시 동일 |
| 8W-GD-0038 | P1 | M1 | save | user:// 쓰기 실패 안전 | 게임은 계속되고 저장 실패 1회만 경고 |
| 8W-GD-0055 | P1 | M1 | fun | CPU 과도한 최적화 금지 | 한 전략/한 경로 점유율이 65%를 넘지 않음 |
| 8W-GD-0056 | P1 | M1 | fun | CPU 무능 연출 금지 | 실행 가능한 기본 목표를 85% 이상 수행 |
| 8W-GD-0057 | P1 | M1 | fun | 인간 개입 가치 | 인간 행동이 사건·결과를 바꾸되 혼자 모든 판을 지배하지 않음 |
| 8W-COM-00012 | P1 | M2 | ai | 행동 관성 | CPU가 초당 2회 이상 표적을 왕복하지 않는다 |
| 8W-COM-00524 | P1 | M2 | ai-audit | CPU balanced / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00525 | P1 | M2 | ai-audit | CPU balanced / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00532 | P1 | M2 | ai-audit | CPU balanced / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00533 | P1 | M2 | ai-audit | CPU balanced / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00540 | P1 | M2 | ai-audit | CPU balanced / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00541 | P1 | M2 | ai-audit | CPU balanced / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00548 | P1 | M2 | ai-audit | CPU balanced / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00549 | P1 | M2 | ai-audit | CPU balanced / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00556 | P1 | M2 | ai-audit | CPU balanced / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00557 | P1 | M2 | ai-audit | CPU balanced / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00564 | P1 | M2 | ai-audit | CPU balanced / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00565 | P1 | M2 | ai-audit | CPU balanced / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00572 | P1 | M2 | ai-audit | CPU balanced / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00573 | P1 | M2 | ai-audit | CPU balanced / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00580 | P1 | M2 | ai-audit | CPU balanced / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00581 | P1 | M2 | ai-audit | CPU balanced / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00588 | P1 | M2 | ai-audit | CPU balanced / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00589 | P1 | M2 | ai-audit | CPU balanced / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00596 | P1 | M2 | ai-audit | CPU balanced / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00597 | P1 | M2 | ai-audit | CPU balanced / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00604 | P1 | M2 | ai-audit | CPU balanced / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00605 | P1 | M2 | ai-audit | CPU balanced / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00612 | P1 | M2 | ai-audit | CPU balanced / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00613 | P1 | M2 | ai-audit | CPU balanced / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00620 | P1 | M2 | ai-audit | CPU risk_taker / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00621 | P1 | M2 | ai-audit | CPU risk_taker / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00628 | P1 | M2 | ai-audit | CPU risk_taker / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00629 | P1 | M2 | ai-audit | CPU risk_taker / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00636 | P1 | M2 | ai-audit | CPU risk_taker / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00637 | P1 | M2 | ai-audit | CPU risk_taker / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00644 | P1 | M2 | ai-audit | CPU risk_taker / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00645 | P1 | M2 | ai-audit | CPU risk_taker / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00652 | P1 | M2 | ai-audit | CPU risk_taker / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00653 | P1 | M2 | ai-audit | CPU risk_taker / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00660 | P1 | M2 | ai-audit | CPU risk_taker / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00661 | P1 | M2 | ai-audit | CPU risk_taker / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00668 | P1 | M2 | ai-audit | CPU risk_taker / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00669 | P1 | M2 | ai-audit | CPU risk_taker / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00676 | P1 | M2 | ai-audit | CPU risk_taker / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00677 | P1 | M2 | ai-audit | CPU risk_taker / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00684 | P1 | M2 | ai-audit | CPU risk_taker / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00685 | P1 | M2 | ai-audit | CPU risk_taker / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00692 | P1 | M2 | ai-audit | CPU risk_taker / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00693 | P1 | M2 | ai-audit | CPU risk_taker / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00700 | P1 | M2 | ai-audit | CPU risk_taker / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00701 | P1 | M2 | ai-audit | CPU risk_taker / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00708 | P1 | M2 | ai-audit | CPU risk_taker / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00709 | P1 | M2 | ai-audit | CPU risk_taker / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00716 | P1 | M2 | ai-audit | CPU rescuer / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00717 | P1 | M2 | ai-audit | CPU rescuer / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00724 | P1 | M2 | ai-audit | CPU rescuer / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00725 | P1 | M2 | ai-audit | CPU rescuer / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00732 | P1 | M2 | ai-audit | CPU rescuer / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00733 | P1 | M2 | ai-audit | CPU rescuer / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00740 | P1 | M2 | ai-audit | CPU rescuer / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00741 | P1 | M2 | ai-audit | CPU rescuer / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00748 | P1 | M2 | ai-audit | CPU rescuer / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00749 | P1 | M2 | ai-audit | CPU rescuer / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00756 | P1 | M2 | ai-audit | CPU rescuer / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00757 | P1 | M2 | ai-audit | CPU rescuer / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00764 | P1 | M2 | ai-audit | CPU rescuer / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00765 | P1 | M2 | ai-audit | CPU rescuer / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00772 | P1 | M2 | ai-audit | CPU rescuer / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00773 | P1 | M2 | ai-audit | CPU rescuer / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00780 | P1 | M2 | ai-audit | CPU rescuer / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00781 | P1 | M2 | ai-audit | CPU rescuer / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00788 | P1 | M2 | ai-audit | CPU rescuer / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00789 | P1 | M2 | ai-audit | CPU rescuer / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00796 | P1 | M2 | ai-audit | CPU rescuer / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00797 | P1 | M2 | ai-audit | CPU rescuer / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00804 | P1 | M2 | ai-audit | CPU rescuer / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00805 | P1 | M2 | ai-audit | CPU rescuer / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00812 | P1 | M2 | ai-audit | CPU greedy / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00813 | P1 | M2 | ai-audit | CPU greedy / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00820 | P1 | M2 | ai-audit | CPU greedy / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00821 | P1 | M2 | ai-audit | CPU greedy / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00828 | P1 | M2 | ai-audit | CPU greedy / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00829 | P1 | M2 | ai-audit | CPU greedy / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00836 | P1 | M2 | ai-audit | CPU greedy / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00837 | P1 | M2 | ai-audit | CPU greedy / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00844 | P1 | M2 | ai-audit | CPU greedy / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00845 | P1 | M2 | ai-audit | CPU greedy / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00852 | P1 | M2 | ai-audit | CPU greedy / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00853 | P1 | M2 | ai-audit | CPU greedy / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00860 | P1 | M2 | ai-audit | CPU greedy / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00861 | P1 | M2 | ai-audit | CPU greedy / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00868 | P1 | M2 | ai-audit | CPU greedy / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00869 | P1 | M2 | ai-audit | CPU greedy / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00876 | P1 | M2 | ai-audit | CPU greedy / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00877 | P1 | M2 | ai-audit | CPU greedy / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00884 | P1 | M2 | ai-audit | CPU greedy / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00885 | P1 | M2 | ai-audit | CPU greedy / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00892 | P1 | M2 | ai-audit | CPU greedy / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00893 | P1 | M2 | ai-audit | CPU greedy / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00900 | P1 | M2 | ai-audit | CPU greedy / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00901 | P1 | M2 | ai-audit | CPU greedy / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00908 | P1 | M2 | ai-audit | CPU patient / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00909 | P1 | M2 | ai-audit | CPU patient / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00916 | P1 | M2 | ai-audit | CPU patient / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00917 | P1 | M2 | ai-audit | CPU patient / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00924 | P1 | M2 | ai-audit | CPU patient / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00925 | P1 | M2 | ai-audit | CPU patient / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00932 | P1 | M2 | ai-audit | CPU patient / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00933 | P1 | M2 | ai-audit | CPU patient / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00940 | P1 | M2 | ai-audit | CPU patient / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00941 | P1 | M2 | ai-audit | CPU patient / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00948 | P1 | M2 | ai-audit | CPU patient / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00949 | P1 | M2 | ai-audit | CPU patient / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00956 | P1 | M2 | ai-audit | CPU patient / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00957 | P1 | M2 | ai-audit | CPU patient / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00964 | P1 | M2 | ai-audit | CPU patient / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00965 | P1 | M2 | ai-audit | CPU patient / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00972 | P1 | M2 | ai-audit | CPU patient / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00973 | P1 | M2 | ai-audit | CPU patient / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00980 | P1 | M2 | ai-audit | CPU patient / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00981 | P1 | M2 | ai-audit | CPU patient / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00988 | P1 | M2 | ai-audit | CPU patient / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00989 | P1 | M2 | ai-audit | CPU patient / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00996 | P1 | M2 | ai-audit | CPU patient / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-00997 | P1 | M2 | ai-audit | CPU patient / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01004 | P1 | M2 | ai-audit | CPU showman / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01005 | P1 | M2 | ai-audit | CPU showman / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01012 | P1 | M2 | ai-audit | CPU showman / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01013 | P1 | M2 | ai-audit | CPU showman / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01020 | P1 | M2 | ai-audit | CPU showman / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01021 | P1 | M2 | ai-audit | CPU showman / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01028 | P1 | M2 | ai-audit | CPU showman / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01029 | P1 | M2 | ai-audit | CPU showman / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01036 | P1 | M2 | ai-audit | CPU showman / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01037 | P1 | M2 | ai-audit | CPU showman / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01044 | P1 | M2 | ai-audit | CPU showman / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01045 | P1 | M2 | ai-audit | CPU showman / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01052 | P1 | M2 | ai-audit | CPU showman / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01053 | P1 | M2 | ai-audit | CPU showman / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01060 | P1 | M2 | ai-audit | CPU showman / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01061 | P1 | M2 | ai-audit | CPU showman / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01068 | P1 | M2 | ai-audit | CPU showman / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01069 | P1 | M2 | ai-audit | CPU showman / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01076 | P1 | M2 | ai-audit | CPU showman / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01077 | P1 | M2 | ai-audit | CPU showman / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01084 | P1 | M2 | ai-audit | CPU showman / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01085 | P1 | M2 | ai-audit | CPU showman / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01092 | P1 | M2 | ai-audit | CPU showman / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-COM-01093 | P1 | M2 | ai-audit | CPU showman / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| 8W-GD-0040 | P1 | M2 | export | GL Compatibility 실행 | 셰이더 없이 회색상자 60 physics FPS |
| 8W-GD-0041 | P1 | M2 | accessibility | 화면 흔들림 0 옵션 | Camera2D 위치 흔들림 0, 판정 동일 |
| 8W-GD-0042 | P1 | M2 | accessibility | 색상 외 구분 | 아이콘·형태·번호로 소유자와 위험 식별 |
| 8W-GD-0044 | P1 | M2 | telemetry | 개인정보 없는 로그 | 시드·행동·지표만 포함, OS 사용자명·경로·IP 없음 |
| 8W-GD-0047 | P1 | M2 | package | 체크리스트 ID 유일 | 중복 ID 0건, 필수 열 누락 0건 |
| 8W-GD-0048 | P1 | M2 | package | P0/P1 게이트 | 미완료 1건이라도 릴리스 실패 |
| 8W-COM-01100 | P1 | M3 | pooling | projectile 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01106 | P1 | M3 | pooling | projectile 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01107 | P1 | M3 | pooling | damage_number 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01113 | P1 | M3 | pooling | damage_number 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01114 | P1 | M3 | pooling | health_bar 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01120 | P1 | M3 | pooling | health_bar 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01121 | P1 | M3 | pooling | warning 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01127 | P1 | M3 | pooling | warning 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01128 | P1 | M3 | pooling | boulder 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01134 | P1 | M3 | pooling | boulder 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01135 | P1 | M3 | pooling | wall 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01141 | P1 | M3 | pooling | wall 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01142 | P1 | M3 | pooling | enemy 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01148 | P1 | M3 | pooling | enemy 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01149 | P1 | M3 | pooling | shipment 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01155 | P1 | M3 | pooling | shipment 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01156 | P1 | M3 | pooling | summon 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01162 | P1 | M3 | pooling | summon 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01163 | P1 | M3 | pooling | corpse_flag 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-01169 | P1 | M3 | pooling | corpse_flag 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| 8W-COM-00015 | P1 | M4 | ux | 실패 후 재시작 | 2.5초 이내 새 판에서 조작 가능 |
| 8W-COM-00016 | P1 | M4 | audio | 경고 중복 제한 | 80ms 창에서 같은 큐가 최대 1회 재생 |
| 8W-COM-00018 | P1 | M4 | accessibility | 색 외 구분 | 형태·아이콘만으로 핵심 상태를 구분 가능 |
