# 지원하며 버티기 — P0/P1 완료 게이트

- P0: **266개**
- P1: **983개**
- P0 또는 P1 중 하나라도 미완료면 다음 공개 빌드·아트 교체·온라인 확장을 진행하지 않는다.
- 실제 상태 기록은 `CHECKLIST_VIEWER.html`, CSV 또는 팀 이슈 트래커 중 하나를 정답으로 정하고 중복 관리하지 않는다.

| ID | 등급 | 마일스톤 | 영역 | 항목 | 통과 기준 |
|---|---:|---|---|---|---|
| SH-COM-00001 | P0 | M0 | boot | 앱 최초 부팅 | Viewport가 2초 이내 생성되고 Output/Debugger 오류이 비어 있다 |
| SH-COM-00002 | P0 | M0 | loop | 60Hz 고정 틱 | 최종 상태 해시가 모두 동일하다 |
| SH-COM-00003 | P0 | M0 | rng | randf()/randi() 금지 | 시뮬레이션 경로에서 randf()/randi() 호출 0건 |
| SH-COM-00004 | P0 | M0 | input | 포커스 상실 키 해제 | 복귀 시 캐릭터가 계속 이동하지 않는다 |
| SH-COM-00005 | P0 | M0 | input | 우클릭 브라우저 메뉴 차단 | 브라우저 컨텍스트 메뉴가 뜨지 않고 게임 명령만 기록된다 |
| SH-COM-00006 | P0 | M0 | replay | 입력 리플레이 | 300틱 간격 모든 상태 해시가 일치한다 |
| SH-COM-00007 | P0 | M0 | data | 설정 해시 | 정규화된 configHash가 동일하다 |
| SH-COM-00019 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00020 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00021 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00022 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00023 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00059 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00060 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00061 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00062 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00063 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00099 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00100 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00101 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00102 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00103 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00139 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00140 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00141 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00142 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00143 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00179 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00180 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00181 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00182 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00183 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00219 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00220 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00221 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00222 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-COM-00223 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| SH-GD-0001 | P0 | M0 | boot | Godot 4.7.1 프로젝트 import | 스크립트·씬 import 오류 0건, Main Scene 지정 |
| SH-GD-0002 | P0 | M0 | boot | F5 최초 실행 | 2초 안에 회색상자 월드와 HUD가 표시되고 오류 0건 |
| SH-GD-0003 | P0 | M0 | boot | 독립 ZIP 의존성 | 외부 상대경로·공통 저장소 없이 실행 |
| SH-GD-0004 | P0 | M0 | loop | physics tick 60 고정 | 정확히 60 |
| SH-GD-0005 | P0 | M0 | loop | _process 판정 변경 금지 | _process에서 GameWorld의 판정 필드를 직접 변경하는 코드 0건 |
| SH-GD-0006 | P0 | M0 | loop | Godot 물리 콜백 순서 비의존 | 명령 정렬·커스텀 판정 결과 해시 동일 |
| SH-GD-0007 | P0 | M0 | rng | 시뮬레이션 randf/randi 금지 | 시드 RNG 래퍼 외 randf/randi/randomize 호출 0건 |
| SH-GD-0008 | P0 | M0 | rng | 시드 재현 | 300틱 간격 상태 해시 100% 일치 |
| SH-GD-0009 | P0 | M0 | input | edge 입력 1회 소비 | 기술 명령은 1회만 생성 |
| SH-GD-0010 | P0 | M0 | input | 포커스 상실 입력 해제 | 이동·공격 hold가 고착되지 않음 |
| SH-GD-0012 | P0 | M0 | viewport | 1600x900 논리 좌표 | 월드 판정 좌표 동일, 레터박스/확장 정책대로 표시 |
| SH-GD-0013 | P0 | M0 | camera | Camera2D와 HUD 분리 | CanvasLayer HUD는 화면에 고정 |
| SH-GD-0015 | P0 | M0 | render | 렌더 상태 역류 금지 | 다음 physics tick 판정에 영향 0 |
| SH-GD-0017 | P0 | M0 | scene | 씬 reload 없는 매치 재시작 | Node 수·메모리·시그널 연결 수가 기준 ±1% 이내 |
| SH-GD-0018 | P0 | M0 | scene | World 교체 후 이전 참조 제거 | 이전 World의 엔티티·이벤트가 보이지 않음 |
| SH-GD-0019 | P0 | M0 | data | JSON 문법과 스키마 | 파싱 오류·중복 ID·미존재 참조 0건 |
| SH-GD-0020 | P0 | M0 | data | 잘못된 데이터 fail-fast | 명확한 경로·키와 함께 부팅 중단, 조용한 기본값 대체 없음 |
| SH-GD-0021 | P0 | M0 | event-log | EventLog 순번 | event_id가 중복 없이 증가하고 tick/actor/target 포함 |
| SH-GD-0022 | P0 | M0 | invariant | NaN·INF 즉시 검출 | 불변식 오류와 시드·tick 덤프 후 테스트 실패 |
| SH-GD-0023 | P0 | M0 | headless | 헤드리스 smoke 진입 | 종료코드 0과 SMOKE_OK JSON 출력 |
| SH-GD-0024 | P0 | M0 | headless | 헤드리스 시간 독립 | 게임 판정이 렌더 노드 없이 완료 |
| SH-GD-0049 | P0 | M0 | starter | 스타터 조작 계약 | 각 입력의 즉시 피드백과 비용·쿨다운이 HUD/월드에 표시 |
| SH-GD-0050 | P0 | M0 | starter | 인간 1+CPU 구성 | 인간 1명과 CPU 5명이 생성되고 CPU가 목표 행동 시작 |
| SH-GD-0051 | P0 | M0 | starter | R 새 시드 재시작 | 즉시 새 World가 만들어지고 seed가 1씩 증가 |
| SH-COM-00008 | P0 | M1 | collision | NaN 방지 | 위치·속도·체력에 NaN/Infinity가 없다 |
| SH-GD-0025 | P0 | M1 | ai | CPU도 PlayerCommand 사용 | 인간과 동일 명령 스키마·검증·쿨다운 경로 사용 |
| SH-GD-0026 | P0 | M1 | ai-audit | CPU 숨은 상태 접근 감사 | Observation에 없던 값으로 행동이 바뀌지 않음 |
| SH-GD-0030 | P0 | M1 | performance | physics 프레임 예산 | p95 simulation step 8ms 이하 |
| SH-GD-0032 | P0 | M1 | replay | 명령 리플레이 | 최종 결과·중간 해시·중요 EventLog 동일 |
| SH-GD-0033 | P0 | M1 | replay | 리플레이 버전 거부 | 호환 불가 사유 표시 후 실행 거부 |
| SH-GD-0034 | P0 | M1 | ux | 실패 원인 5초 식별 | 80% 이상이 원인 행위자·사건을 5초 내 식별 |
| SH-GD-0037 | P0 | M1 | pause | 일시정지 tick 정지 | World tick·쿨다운·스폰이 증가하지 않음 |
| SH-GD-0053 | P0 | M1 | fun | 핵심 재미 사건 발생률 | 문서의 핵심 재미 사건이 목표 빈도 범위에 들어옴 |
| SH-GD-0054 | P0 | M1 | fun | 실패도 관전 가능 | 매치가 계속 진행되고 중요한 사건·승패 원인이 표시 |
| SH-COM-00010 | P0 | M2 | ai | 숨은 정보 금지 | 비가시 엔티티를 직접 action target으로 선택하지 않는다 |
| SH-COM-00011 | P0 | M2 | ai | 반응 지연 | 130ms 미만 반응 0건, 평균 175~270ms |
| SH-GD-0039 | P0 | M2 | export | Windows export 입력 유지 | 편집기와 조작·판정·결과 동일 |
| SH-GD-0043 | P0 | M2 | cleanup | 결과 확정 후 상태 고정 | 점수·HP·소유권·스폰 변화 0 |
| SH-GD-0045 | P0 | M2 | package | smoke/playability 회귀 검사 | 두 테스트가 오류 없이 종료 |
| SH-GD-0046 | P0 | M2 | package | 문서-코드 경로 정합 | 존재하지 않는 파일 0건 |
| SH-GD-0058 | P0 | M2 | acceptance | 최종 수락 지표 | 기능 오류 없이 핵심 재미가 최소 70% 판에서 체감되고 원인 로그 존재 |
| SH-COM-00013 | P0 | M3 | performance | 풀 누수 | 활성 수가 안정된 뒤 풀 총량이 10% 이상 증가하지 않는다 |
| SH-COM-00014 | P0 | M3 | performance | 시뮬레이션 오버런 | 최대 5틱 실행 후 잔여 누적을 버리고 입력 가능 |
| SH-COM-00017 | P0 | M4 | telemetry | 원인 이벤트 연결 | 손실 이벤트가 최대 6단계 원인으로 역추적 가능 |
| SH-00001 | P0 | SH-M0 | ammo | 탄약 고갈 비상 권총 | 첫 공격 정상, 이후 1.3초 18피해 비상 권총 |
| SH-00002 | P0 | SH-M0 | shipment | 물리 배송 도착 | 실제 엔티티가 경로를 이동해 표식에서 탄약 적용 |
| SH-00003 | P0 | SH-M1 | failure | 병사 동시 전투불능 | 10초 경계에 패배, 그 전 부활하면 패배 취소 |
| SH-00007 | P0 | SH-M2 | shipment | 탄약 상자 / north / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00011 | P0 | SH-M2 | shipment | 탄약 상자 / north / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00015 | P0 | SH-M2 | shipment | 탄약 상자 / north / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00019 | P0 | SH-M2 | shipment | 탄약 상자 / north / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00023 | P0 | SH-M2 | shipment | 탄약 상자 / north / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00027 | P0 | SH-M2 | shipment | 탄약 상자 / north / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00031 | P0 | SH-M2 | shipment | 탄약 상자 / center / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00035 | P0 | SH-M2 | shipment | 탄약 상자 / center / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00039 | P0 | SH-M2 | shipment | 탄약 상자 / center / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00043 | P0 | SH-M2 | shipment | 탄약 상자 / center / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00047 | P0 | SH-M2 | shipment | 탄약 상자 / center / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00051 | P0 | SH-M2 | shipment | 탄약 상자 / center / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00055 | P0 | SH-M2 | shipment | 탄약 상자 / south / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00059 | P0 | SH-M2 | shipment | 탄약 상자 / south / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00063 | P0 | SH-M2 | shipment | 탄약 상자 / south / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00067 | P0 | SH-M2 | shipment | 탄약 상자 / south / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00071 | P0 | SH-M2 | shipment | 탄약 상자 / south / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00075 | P0 | SH-M2 | shipment | 탄약 상자 / south / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00079 | P0 | SH-M2 | shipment | 의료 상자 / north / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00083 | P0 | SH-M2 | shipment | 의료 상자 / north / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00087 | P0 | SH-M2 | shipment | 의료 상자 / north / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00091 | P0 | SH-M2 | shipment | 의료 상자 / north / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00095 | P0 | SH-M2 | shipment | 의료 상자 / north / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00099 | P0 | SH-M2 | shipment | 의료 상자 / north / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00103 | P0 | SH-M2 | shipment | 의료 상자 / center / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00107 | P0 | SH-M2 | shipment | 의료 상자 / center / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00111 | P0 | SH-M2 | shipment | 의료 상자 / center / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00115 | P0 | SH-M2 | shipment | 의료 상자 / center / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00119 | P0 | SH-M2 | shipment | 의료 상자 / center / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00123 | P0 | SH-M2 | shipment | 의료 상자 / center / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00127 | P0 | SH-M2 | shipment | 의료 상자 / south / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00131 | P0 | SH-M2 | shipment | 의료 상자 / south / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00135 | P0 | SH-M2 | shipment | 의료 상자 / south / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00139 | P0 | SH-M2 | shipment | 의료 상자 / south / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00143 | P0 | SH-M2 | shipment | 의료 상자 / south / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00147 | P0 | SH-M2 | shipment | 의료 상자 / south / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00151 | P0 | SH-M2 | shipment | 수리 부품 / north / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00155 | P0 | SH-M2 | shipment | 수리 부품 / north / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00159 | P0 | SH-M2 | shipment | 수리 부품 / north / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00163 | P0 | SH-M2 | shipment | 수리 부품 / north / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00167 | P0 | SH-M2 | shipment | 수리 부품 / north / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00171 | P0 | SH-M2 | shipment | 수리 부품 / north / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00175 | P0 | SH-M2 | shipment | 수리 부품 / center / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00179 | P0 | SH-M2 | shipment | 수리 부품 / center / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00183 | P0 | SH-M2 | shipment | 수리 부품 / center / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00187 | P0 | SH-M2 | shipment | 수리 부품 / center / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00191 | P0 | SH-M2 | shipment | 수리 부품 / center / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00195 | P0 | SH-M2 | shipment | 수리 부품 / center / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00199 | P0 | SH-M2 | shipment | 수리 부품 / south / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00203 | P0 | SH-M2 | shipment | 수리 부품 / south / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00207 | P0 | SH-M2 | shipment | 수리 부품 / south / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00211 | P0 | SH-M2 | shipment | 수리 부품 / south / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00215 | P0 | SH-M2 | shipment | 수리 부품 / south / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00219 | P0 | SH-M2 | shipment | 수리 부품 / south / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00223 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / north / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00227 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / north / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00231 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / north / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00235 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / north / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00239 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / north / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00243 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / north / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00247 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / center / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00251 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / center / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00255 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / center / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00259 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / center / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00263 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / center / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00267 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / center / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00271 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / south / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00275 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / south / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00279 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / south / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00283 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / south / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00287 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / south / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00291 | P0 | SH-M2 | shipment | 혼합 긴급 상자 / south / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00295 | P0 | SH-M2 | shipment | 증원 분대 / north / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00299 | P0 | SH-M2 | shipment | 증원 분대 / north / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00303 | P0 | SH-M2 | shipment | 증원 분대 / north / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00307 | P0 | SH-M2 | shipment | 증원 분대 / north / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00311 | P0 | SH-M2 | shipment | 증원 분대 / north / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00315 | P0 | SH-M2 | shipment | 증원 분대 / north / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00319 | P0 | SH-M2 | shipment | 증원 분대 / center / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00323 | P0 | SH-M2 | shipment | 증원 분대 / center / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00327 | P0 | SH-M2 | shipment | 증원 분대 / center / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00331 | P0 | SH-M2 | shipment | 증원 분대 / center / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00335 | P0 | SH-M2 | shipment | 증원 분대 / center / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00339 | P0 | SH-M2 | shipment | 증원 분대 / center / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00343 | P0 | SH-M2 | shipment | 증원 분대 / south / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00347 | P0 | SH-M2 | shipment | 증원 분대 / south / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00351 | P0 | SH-M2 | shipment | 증원 분대 / south / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00355 | P0 | SH-M2 | shipment | 증원 분대 / south / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00359 | P0 | SH-M2 | shipment | 증원 분대 / south / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00363 | P0 | SH-M2 | shipment | 증원 분대 / south / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00367 | P0 | SH-M2 | shipment | 구조 드론 / north / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00371 | P0 | SH-M2 | shipment | 구조 드론 / north / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00375 | P0 | SH-M2 | shipment | 구조 드론 / north / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00379 | P0 | SH-M2 | shipment | 구조 드론 / north / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00383 | P0 | SH-M2 | shipment | 구조 드론 / north / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00387 | P0 | SH-M2 | shipment | 구조 드론 / north / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00391 | P0 | SH-M2 | shipment | 구조 드론 / center / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00395 | P0 | SH-M2 | shipment | 구조 드론 / center / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00399 | P0 | SH-M2 | shipment | 구조 드론 / center / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00403 | P0 | SH-M2 | shipment | 구조 드론 / center / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00407 | P0 | SH-M2 | shipment | 구조 드론 / center / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00411 | P0 | SH-M2 | shipment | 구조 드론 / center / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00415 | P0 | SH-M2 | shipment | 구조 드론 / south / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00419 | P0 | SH-M2 | shipment | 구조 드론 / south / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00423 | P0 | SH-M2 | shipment | 구조 드론 / south / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00427 | P0 | SH-M2 | shipment | 구조 드론 / south / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00431 | P0 | SH-M2 | shipment | 구조 드론 / south / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00435 | P0 | SH-M2 | shipment | 구조 드론 / south / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00439 | P0 | SH-M2 | shipment | 포탑 키트 / north / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00443 | P0 | SH-M2 | shipment | 포탑 키트 / north / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00447 | P0 | SH-M2 | shipment | 포탑 키트 / north / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00451 | P0 | SH-M2 | shipment | 포탑 키트 / north / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00455 | P0 | SH-M2 | shipment | 포탑 키트 / north / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00459 | P0 | SH-M2 | shipment | 포탑 키트 / north / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00463 | P0 | SH-M2 | shipment | 포탑 키트 / center / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00467 | P0 | SH-M2 | shipment | 포탑 키트 / center / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00471 | P0 | SH-M2 | shipment | 포탑 키트 / center / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00475 | P0 | SH-M2 | shipment | 포탑 키트 / center / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00479 | P0 | SH-M2 | shipment | 포탑 키트 / center / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00483 | P0 | SH-M2 | shipment | 포탑 키트 / center / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00487 | P0 | SH-M2 | shipment | 포탑 키트 / south / safe / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00491 | P0 | SH-M2 | shipment | 포탑 키트 / south / safe / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00495 | P0 | SH-M2 | shipment | 포탑 키트 / south / safe / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00499 | P0 | SH-M2 | shipment | 포탑 키트 / south / fast / safe_delivery | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00503 | P0 | SH-M2 | shipment | 포탑 키트 / south / fast / crate_destroyed | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00507 | P0 | SH-M2 | shipment | 포탑 키트 / south / fast / resource_exact | 자원·ETA·HP·효과가 데이터와 일치하고 복제·소실·잘못된 라인 추적이 없다 |
| SH-00511 | P0 | SH-M2 | role-skill | 선봉병 도발 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00512 | P0 | SH-M2 | role-skill | 선봉병 도발 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00515 | P0 | SH-M2 | role-skill | 선봉병 도발 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00523 | P0 | SH-M2 | role-skill | 선봉병 방패돌진 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00524 | P0 | SH-M2 | role-skill | 선봉병 방패돌진 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00527 | P0 | SH-M2 | role-skill | 선봉병 방패돌진 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00535 | P0 | SH-M2 | role-skill | 선봉병 최후방벽 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00536 | P0 | SH-M2 | role-skill | 선봉병 최후방벽 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00539 | P0 | SH-M2 | role-skill | 선봉병 최후방벽 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00547 | P0 | SH-M2 | role-skill | 소총병 점사 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00548 | P0 | SH-M2 | role-skill | 소총병 점사 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00551 | P0 | SH-M2 | role-skill | 소총병 점사 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00559 | P0 | SH-M2 | role-skill | 소총병 수류탄 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00560 | P0 | SH-M2 | role-skill | 소총병 수류탄 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00563 | P0 | SH-M2 | role-skill | 소총병 수류탄 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00571 | P0 | SH-M2 | role-skill | 소총병 제압사격 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00572 | P0 | SH-M2 | role-skill | 소총병 제압사격 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00575 | P0 | SH-M2 | role-skill | 소총병 제압사격 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00583 | P0 | SH-M2 | role-skill | 제압병 빙결탄 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00584 | P0 | SH-M2 | role-skill | 제압병 빙결탄 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00587 | P0 | SH-M2 | role-skill | 제압병 빙결탄 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00595 | P0 | SH-M2 | role-skill | 제압병 지뢰 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00596 | P0 | SH-M2 | role-skill | 제압병 지뢰 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00599 | P0 | SH-M2 | role-skill | 제압병 지뢰 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00607 | P0 | SH-M2 | role-skill | 제압병 포격표식 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00608 | P0 | SH-M2 | role-skill | 제압병 포격표식 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00611 | P0 | SH-M2 | role-skill | 제압병 포격표식 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00619 | P0 | SH-M2 | role-skill | 보급관 탄약 긴급투하 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00620 | P0 | SH-M2 | role-skill | 보급관 탄약 긴급투하 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00623 | P0 | SH-M2 | role-skill | 보급관 탄약 긴급투하 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00631 | P0 | SH-M2 | role-skill | 보급관 우선 수송로 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00632 | P0 | SH-M2 | role-skill | 보급관 우선 수송로 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00635 | P0 | SH-M2 | role-skill | 보급관 우선 수송로 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00643 | P0 | SH-M2 | role-skill | 보급관 생산가속 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00644 | P0 | SH-M2 | role-skill | 보급관 생산가속 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00647 | P0 | SH-M2 | role-skill | 보급관 생산가속 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00655 | P0 | SH-M2 | role-skill | 의무관 치료팩 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00656 | P0 | SH-M2 | role-skill | 의무관 치료팩 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00659 | P0 | SH-M2 | role-skill | 의무관 치료팩 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00667 | P0 | SH-M2 | role-skill | 의무관 전투부활 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00668 | P0 | SH-M2 | role-skill | 의무관 전투부활 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00671 | P0 | SH-M2 | role-skill | 의무관 전투부활 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00679 | P0 | SH-M2 | role-skill | 의무관 사기주입 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00680 | P0 | SH-M2 | role-skill | 의무관 사기주입 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00683 | P0 | SH-M2 | role-skill | 의무관 사기주입 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00691 | P0 | SH-M2 | role-skill | 공병 바리케이드 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00692 | P0 | SH-M2 | role-skill | 공병 바리케이드 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00695 | P0 | SH-M2 | role-skill | 공병 바리케이드 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00703 | P0 | SH-M2 | role-skill | 공병 수리드론 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00704 | P0 | SH-M2 | role-skill | 공병 수리드론 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00707 | P0 | SH-M2 | role-skill | 공병 수리드론 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00715 | P0 | SH-M2 | role-skill | 공병 임시포탑 / valid | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00716 | P0 | SH-M2 | role-skill | 공병 임시포탑 / no_resource | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00719 | P0 | SH-M2 | role-skill | 공병 임시포탑 / caster_dies | 고정 효과와 일치하고 음수 자원·이중 적용·불가능 대상 적용이 없다 |
| SH-00005 | P0 | SH-M3 | cascade | 연쇄 원인 그래프 | 결과에서 최소 4단계 causeEventId 연결 |
| SH-00006 | P0 | SH-M4 | boss | 핵 맥동 차단 | 전멸기 취소, 누적 증가 없음 |
| SH-GD-0011 | P1 | M0 | input | 키보드 동시입력 정규화 | 대각선 속도가 축 속도와 동일 |
| SH-GD-0014 | P1 | M0 | camera | 마우스 월드 좌표 역변환 | 조준점 오차 1 world unit 이하 |
| SH-GD-0016 | P1 | M0 | render | queue_redraw 호출 상한 | 월드·HUD 각각 physics tick당 최대 1회 |
| SH-GD-0052 | P1 | M0 | starter | 더미 아트 판정 가독성 | 색·형태·번호만으로 객체 역할과 소유자 식별 |
| SH-COM-00009 | P1 | M1 | camera | 레터박스 좌표 | 월드 좌표가 보이는 클릭 마커와 2px 이내 일치 |
| SH-COM-00259 | P1 | M1 | viewport | 960×540 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00260 | P1 | M1 | viewport | 960×540 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00261 | P1 | M1 | viewport | 960×540 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00262 | P1 | M1 | viewport | 960×540 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00263 | P1 | M1 | viewport | 960×540 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00264 | P1 | M1 | viewport | 960×540 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00265 | P1 | M1 | viewport | 960×540 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00266 | P1 | M1 | viewport | 960×540 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00267 | P1 | M1 | viewport | 960×540 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00268 | P1 | M1 | viewport | 960×540 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00269 | P1 | M1 | viewport | 960×540 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00270 | P1 | M1 | viewport | 960×540 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00271 | P1 | M1 | viewport | 960×540 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00272 | P1 | M1 | viewport | 960×540 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00273 | P1 | M1 | viewport | 960×540 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00304 | P1 | M1 | viewport | 1600×900 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00305 | P1 | M1 | viewport | 1600×900 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00306 | P1 | M1 | viewport | 1600×900 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00307 | P1 | M1 | viewport | 1600×900 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00308 | P1 | M1 | viewport | 1600×900 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00309 | P1 | M1 | viewport | 1600×900 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00310 | P1 | M1 | viewport | 1600×900 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00311 | P1 | M1 | viewport | 1600×900 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00312 | P1 | M1 | viewport | 1600×900 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00313 | P1 | M1 | viewport | 1600×900 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00314 | P1 | M1 | viewport | 1600×900 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00315 | P1 | M1 | viewport | 1600×900 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00316 | P1 | M1 | viewport | 1600×900 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00317 | P1 | M1 | viewport | 1600×900 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00318 | P1 | M1 | viewport | 1600×900 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00349 | P1 | M1 | viewport | 3840×2160 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00350 | P1 | M1 | viewport | 3840×2160 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00351 | P1 | M1 | viewport | 3840×2160 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00352 | P1 | M1 | viewport | 3840×2160 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00353 | P1 | M1 | viewport | 3840×2160 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00354 | P1 | M1 | viewport | 3840×2160 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00355 | P1 | M1 | viewport | 3840×2160 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00356 | P1 | M1 | viewport | 3840×2160 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00357 | P1 | M1 | viewport | 3840×2160 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00358 | P1 | M1 | viewport | 3840×2160 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00359 | P1 | M1 | viewport | 3840×2160 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00360 | P1 | M1 | viewport | 3840×2160 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00361 | P1 | M1 | viewport | 3840×2160 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00362 | P1 | M1 | viewport | 3840×2160 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00363 | P1 | M1 | viewport | 3840×2160 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| SH-COM-00364 | P1 | M1 | input | 입력 move_up / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00370 | P1 | M1 | input | 입력 move_up / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00373 | P1 | M1 | input | 입력 move_up / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00374 | P1 | M1 | input | 입력 move_down / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00380 | P1 | M1 | input | 입력 move_down / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00383 | P1 | M1 | input | 입력 move_down / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00384 | P1 | M1 | input | 입력 move_left / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00390 | P1 | M1 | input | 입력 move_left / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00393 | P1 | M1 | input | 입력 move_left / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00394 | P1 | M1 | input | 입력 move_right / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00400 | P1 | M1 | input | 입력 move_right / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00403 | P1 | M1 | input | 입력 move_right / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00404 | P1 | M1 | input | 입력 diagonal / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00410 | P1 | M1 | input | 입력 diagonal / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00413 | P1 | M1 | input | 입력 diagonal / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00414 | P1 | M1 | input | 입력 primary / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00420 | P1 | M1 | input | 입력 primary / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00423 | P1 | M1 | input | 입력 primary / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00424 | P1 | M1 | input | 입력 secondary / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00430 | P1 | M1 | input | 입력 secondary / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00433 | P1 | M1 | input | 입력 secondary / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00434 | P1 | M1 | input | 입력 ability_q / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00440 | P1 | M1 | input | 입력 ability_q / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00443 | P1 | M1 | input | 입력 ability_q / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00444 | P1 | M1 | input | 입력 ability_w / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00450 | P1 | M1 | input | 입력 ability_w / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00453 | P1 | M1 | input | 입력 ability_w / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00454 | P1 | M1 | input | 입력 ability_e / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00460 | P1 | M1 | input | 입력 ability_e / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00463 | P1 | M1 | input | 입력 ability_e / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00464 | P1 | M1 | input | 입력 ability_r / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00470 | P1 | M1 | input | 입력 ability_r / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00473 | P1 | M1 | input | 입력 ability_r / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00474 | P1 | M1 | input | 입력 ability_f / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00480 | P1 | M1 | input | 입력 ability_f / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00483 | P1 | M1 | input | 입력 ability_f / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00484 | P1 | M1 | input | 입력 dash / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00490 | P1 | M1 | input | 입력 dash / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00493 | P1 | M1 | input | 입력 dash / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00494 | P1 | M1 | input | 입력 ping / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00500 | P1 | M1 | input | 입력 ping / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00503 | P1 | M1 | input | 입력 ping / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00504 | P1 | M1 | input | 입력 pause / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00510 | P1 | M1 | input | 입력 pause / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00513 | P1 | M1 | input | 입력 pause / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00514 | P1 | M1 | input | 입력 restart / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00520 | P1 | M1 | input | 입력 restart / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-COM-00523 | P1 | M1 | input | 입력 restart / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| SH-GD-0027 | P1 | M1 | ai | CPU 반응 지연 | 프로필 min/max 안에서 T 이후 반응, 0틱 완벽반응 0건 |
| SH-GD-0028 | P1 | M1 | ai | CPU 동일 실수 반복 제한 | 같은 치명 실수를 연속 2회 이상 의도 삽입하지 않음 |
| SH-GD-0029 | P1 | M1 | ai | 인간 슬롯 편향 없음 | CPU 목표·지원·공격 확률이 슬롯 평균 허용오차 이내 |
| SH-GD-0031 | P1 | M1 | performance | 렌더 객체 증가 상한 | CanvasItem/Node 수가 설계 상한 이내이며 계속 증가하지 않음 |
| SH-GD-0035 | P1 | M1 | ux | CPU 구분 가독성 | 인간 캐릭터를 1초 내 찾는 성공률 95% 이상 |
| SH-GD-0036 | P1 | M1 | audio | 판정과 오디오 분리 | 상태 해시 동일 |
| SH-GD-0038 | P1 | M1 | save | user:// 쓰기 실패 안전 | 게임은 계속되고 저장 실패 1회만 경고 |
| SH-GD-0055 | P1 | M1 | fun | CPU 과도한 최적화 금지 | 한 전략/한 경로 점유율이 65%를 넘지 않음 |
| SH-GD-0056 | P1 | M1 | fun | CPU 무능 연출 금지 | 실행 가능한 기본 목표를 85% 이상 수행 |
| SH-GD-0057 | P1 | M1 | fun | 인간 개입 가치 | 인간 행동이 사건·결과를 바꾸되 혼자 모든 판을 지배하지 않음 |
| SH-COM-00012 | P1 | M2 | ai | 행동 관성 | CPU가 초당 2회 이상 표적을 왕복하지 않는다 |
| SH-COM-00524 | P1 | M2 | ai-audit | CPU balanced / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00525 | P1 | M2 | ai-audit | CPU balanced / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00532 | P1 | M2 | ai-audit | CPU balanced / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00533 | P1 | M2 | ai-audit | CPU balanced / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00540 | P1 | M2 | ai-audit | CPU balanced / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00541 | P1 | M2 | ai-audit | CPU balanced / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00548 | P1 | M2 | ai-audit | CPU balanced / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00549 | P1 | M2 | ai-audit | CPU balanced / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00556 | P1 | M2 | ai-audit | CPU balanced / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00557 | P1 | M2 | ai-audit | CPU balanced / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00564 | P1 | M2 | ai-audit | CPU balanced / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00565 | P1 | M2 | ai-audit | CPU balanced / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00572 | P1 | M2 | ai-audit | CPU balanced / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00573 | P1 | M2 | ai-audit | CPU balanced / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00580 | P1 | M2 | ai-audit | CPU balanced / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00581 | P1 | M2 | ai-audit | CPU balanced / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00588 | P1 | M2 | ai-audit | CPU balanced / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00589 | P1 | M2 | ai-audit | CPU balanced / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00596 | P1 | M2 | ai-audit | CPU balanced / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00597 | P1 | M2 | ai-audit | CPU balanced / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00604 | P1 | M2 | ai-audit | CPU balanced / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00605 | P1 | M2 | ai-audit | CPU balanced / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00612 | P1 | M2 | ai-audit | CPU balanced / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00613 | P1 | M2 | ai-audit | CPU balanced / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00620 | P1 | M2 | ai-audit | CPU risk_taker / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00621 | P1 | M2 | ai-audit | CPU risk_taker / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00628 | P1 | M2 | ai-audit | CPU risk_taker / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00629 | P1 | M2 | ai-audit | CPU risk_taker / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00636 | P1 | M2 | ai-audit | CPU risk_taker / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00637 | P1 | M2 | ai-audit | CPU risk_taker / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00644 | P1 | M2 | ai-audit | CPU risk_taker / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00645 | P1 | M2 | ai-audit | CPU risk_taker / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00652 | P1 | M2 | ai-audit | CPU risk_taker / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00653 | P1 | M2 | ai-audit | CPU risk_taker / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00660 | P1 | M2 | ai-audit | CPU risk_taker / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00661 | P1 | M2 | ai-audit | CPU risk_taker / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00668 | P1 | M2 | ai-audit | CPU risk_taker / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00669 | P1 | M2 | ai-audit | CPU risk_taker / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00676 | P1 | M2 | ai-audit | CPU risk_taker / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00677 | P1 | M2 | ai-audit | CPU risk_taker / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00684 | P1 | M2 | ai-audit | CPU risk_taker / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00685 | P1 | M2 | ai-audit | CPU risk_taker / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00692 | P1 | M2 | ai-audit | CPU risk_taker / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00693 | P1 | M2 | ai-audit | CPU risk_taker / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00700 | P1 | M2 | ai-audit | CPU risk_taker / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00701 | P1 | M2 | ai-audit | CPU risk_taker / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00708 | P1 | M2 | ai-audit | CPU risk_taker / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00709 | P1 | M2 | ai-audit | CPU risk_taker / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00716 | P1 | M2 | ai-audit | CPU rescuer / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00717 | P1 | M2 | ai-audit | CPU rescuer / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00724 | P1 | M2 | ai-audit | CPU rescuer / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00725 | P1 | M2 | ai-audit | CPU rescuer / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00732 | P1 | M2 | ai-audit | CPU rescuer / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00733 | P1 | M2 | ai-audit | CPU rescuer / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00740 | P1 | M2 | ai-audit | CPU rescuer / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00741 | P1 | M2 | ai-audit | CPU rescuer / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00748 | P1 | M2 | ai-audit | CPU rescuer / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00749 | P1 | M2 | ai-audit | CPU rescuer / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00756 | P1 | M2 | ai-audit | CPU rescuer / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00757 | P1 | M2 | ai-audit | CPU rescuer / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00764 | P1 | M2 | ai-audit | CPU rescuer / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00765 | P1 | M2 | ai-audit | CPU rescuer / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00772 | P1 | M2 | ai-audit | CPU rescuer / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00773 | P1 | M2 | ai-audit | CPU rescuer / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00780 | P1 | M2 | ai-audit | CPU rescuer / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00781 | P1 | M2 | ai-audit | CPU rescuer / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00788 | P1 | M2 | ai-audit | CPU rescuer / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00789 | P1 | M2 | ai-audit | CPU rescuer / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00796 | P1 | M2 | ai-audit | CPU rescuer / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00797 | P1 | M2 | ai-audit | CPU rescuer / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00804 | P1 | M2 | ai-audit | CPU rescuer / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00805 | P1 | M2 | ai-audit | CPU rescuer / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00812 | P1 | M2 | ai-audit | CPU greedy / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00813 | P1 | M2 | ai-audit | CPU greedy / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00820 | P1 | M2 | ai-audit | CPU greedy / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00821 | P1 | M2 | ai-audit | CPU greedy / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00828 | P1 | M2 | ai-audit | CPU greedy / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00829 | P1 | M2 | ai-audit | CPU greedy / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00836 | P1 | M2 | ai-audit | CPU greedy / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00837 | P1 | M2 | ai-audit | CPU greedy / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00844 | P1 | M2 | ai-audit | CPU greedy / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00845 | P1 | M2 | ai-audit | CPU greedy / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00852 | P1 | M2 | ai-audit | CPU greedy / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00853 | P1 | M2 | ai-audit | CPU greedy / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00860 | P1 | M2 | ai-audit | CPU greedy / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00861 | P1 | M2 | ai-audit | CPU greedy / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00868 | P1 | M2 | ai-audit | CPU greedy / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00869 | P1 | M2 | ai-audit | CPU greedy / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00876 | P1 | M2 | ai-audit | CPU greedy / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00877 | P1 | M2 | ai-audit | CPU greedy / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00884 | P1 | M2 | ai-audit | CPU greedy / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00885 | P1 | M2 | ai-audit | CPU greedy / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00892 | P1 | M2 | ai-audit | CPU greedy / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00893 | P1 | M2 | ai-audit | CPU greedy / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00900 | P1 | M2 | ai-audit | CPU greedy / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00901 | P1 | M2 | ai-audit | CPU greedy / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00908 | P1 | M2 | ai-audit | CPU patient / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00909 | P1 | M2 | ai-audit | CPU patient / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00916 | P1 | M2 | ai-audit | CPU patient / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00917 | P1 | M2 | ai-audit | CPU patient / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00924 | P1 | M2 | ai-audit | CPU patient / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00925 | P1 | M2 | ai-audit | CPU patient / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00932 | P1 | M2 | ai-audit | CPU patient / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00933 | P1 | M2 | ai-audit | CPU patient / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00940 | P1 | M2 | ai-audit | CPU patient / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00941 | P1 | M2 | ai-audit | CPU patient / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00948 | P1 | M2 | ai-audit | CPU patient / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00949 | P1 | M2 | ai-audit | CPU patient / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00956 | P1 | M2 | ai-audit | CPU patient / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00957 | P1 | M2 | ai-audit | CPU patient / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00964 | P1 | M2 | ai-audit | CPU patient / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00965 | P1 | M2 | ai-audit | CPU patient / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00972 | P1 | M2 | ai-audit | CPU patient / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00973 | P1 | M2 | ai-audit | CPU patient / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00980 | P1 | M2 | ai-audit | CPU patient / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00981 | P1 | M2 | ai-audit | CPU patient / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00988 | P1 | M2 | ai-audit | CPU patient / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00989 | P1 | M2 | ai-audit | CPU patient / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00996 | P1 | M2 | ai-audit | CPU patient / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-00997 | P1 | M2 | ai-audit | CPU patient / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01004 | P1 | M2 | ai-audit | CPU showman / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01005 | P1 | M2 | ai-audit | CPU showman / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01012 | P1 | M2 | ai-audit | CPU showman / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01013 | P1 | M2 | ai-audit | CPU showman / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01020 | P1 | M2 | ai-audit | CPU showman / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01021 | P1 | M2 | ai-audit | CPU showman / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01028 | P1 | M2 | ai-audit | CPU showman / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01029 | P1 | M2 | ai-audit | CPU showman / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01036 | P1 | M2 | ai-audit | CPU showman / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01037 | P1 | M2 | ai-audit | CPU showman / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01044 | P1 | M2 | ai-audit | CPU showman / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01045 | P1 | M2 | ai-audit | CPU showman / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01052 | P1 | M2 | ai-audit | CPU showman / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01053 | P1 | M2 | ai-audit | CPU showman / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01060 | P1 | M2 | ai-audit | CPU showman / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01061 | P1 | M2 | ai-audit | CPU showman / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01068 | P1 | M2 | ai-audit | CPU showman / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01069 | P1 | M2 | ai-audit | CPU showman / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01076 | P1 | M2 | ai-audit | CPU showman / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01077 | P1 | M2 | ai-audit | CPU showman / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01084 | P1 | M2 | ai-audit | CPU showman / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01085 | P1 | M2 | ai-audit | CPU showman / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01092 | P1 | M2 | ai-audit | CPU showman / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-COM-01093 | P1 | M2 | ai-audit | CPU showman / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| SH-GD-0040 | P1 | M2 | export | GL Compatibility 실행 | 셰이더 없이 회색상자 60 physics FPS |
| SH-GD-0041 | P1 | M2 | accessibility | 화면 흔들림 0 옵션 | Camera2D 위치 흔들림 0, 판정 동일 |
| SH-GD-0042 | P1 | M2 | accessibility | 색상 외 구분 | 아이콘·형태·번호로 소유자와 위험 식별 |
| SH-GD-0044 | P1 | M2 | telemetry | 개인정보 없는 로그 | 시드·행동·지표만 포함, OS 사용자명·경로·IP 없음 |
| SH-GD-0047 | P1 | M2 | package | 체크리스트 ID 유일 | 중복 ID 0건, 필수 열 누락 0건 |
| SH-GD-0048 | P1 | M2 | package | P0/P1 게이트 | 미완료 1건이라도 릴리스 실패 |
| SH-COM-01100 | P1 | M3 | pooling | projectile 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01106 | P1 | M3 | pooling | projectile 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01107 | P1 | M3 | pooling | damage_number 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01113 | P1 | M3 | pooling | damage_number 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01114 | P1 | M3 | pooling | health_bar 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01120 | P1 | M3 | pooling | health_bar 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01121 | P1 | M3 | pooling | warning 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01127 | P1 | M3 | pooling | warning 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01128 | P1 | M3 | pooling | boulder 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01134 | P1 | M3 | pooling | boulder 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01135 | P1 | M3 | pooling | wall 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01141 | P1 | M3 | pooling | wall 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01142 | P1 | M3 | pooling | enemy 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01148 | P1 | M3 | pooling | enemy 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01149 | P1 | M3 | pooling | shipment 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01155 | P1 | M3 | pooling | shipment 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01156 | P1 | M3 | pooling | summon 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01162 | P1 | M3 | pooling | summon 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01163 | P1 | M3 | pooling | corpse_flag 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-01169 | P1 | M3 | pooling | corpse_flag 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| SH-COM-00015 | P1 | M4 | ux | 실패 후 재시작 | 2.5초 이내 새 판에서 조작 가능 |
| SH-COM-00016 | P1 | M4 | audio | 경고 중복 제한 | 80ms 창에서 같은 큐가 최대 1회 재생 |
| SH-COM-00018 | P1 | M4 | accessibility | 색 외 구분 | 형태·아이콘만으로 핵심 상태를 구분 가능 |
| SH-00004 | P1 | SH-M2 | request | 자동 탄약 요청 | 25에서 노란 요청 1회, 8초 중복 없음 |
| SH-00727 | P1 | SH-M3 | phase-sim | P1 balanced 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00728 | P1 | SH-M3 | phase-sim | P1 balanced 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00735 | P1 | SH-M3 | phase-sim | P1 balanced 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00736 | P1 | SH-M3 | phase-sim | P1 balanced 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00743 | P1 | SH-M3 | phase-sim | P1 balanced 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00744 | P1 | SH-M3 | phase-sim | P1 balanced 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00751 | P1 | SH-M3 | phase-sim | P1 balanced 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00752 | P1 | SH-M3 | phase-sim | P1 balanced 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00759 | P1 | SH-M3 | phase-sim | P1 balanced 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00760 | P1 | SH-M3 | phase-sim | P1 balanced 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00767 | P1 | SH-M3 | phase-sim | P1 balanced 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00768 | P1 | SH-M3 | phase-sim | P1 balanced 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00775 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00776 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00783 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00784 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00791 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00792 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00799 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00800 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00807 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00808 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00815 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00816 | P1 | SH-M3 | phase-sim | P1 north_collapse 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00823 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00824 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00831 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00832 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00839 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00840 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00847 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00848 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00855 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00856 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00863 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00864 | P1 | SH-M3 | phase-sim | P1 center_low_ammo 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00871 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00872 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00879 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00880 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00887 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00888 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00895 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00896 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00903 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00904 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00911 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00912 | P1 | SH-M3 | phase-sim | P1 south_downed 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00919 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00920 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00927 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00928 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00935 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00936 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00943 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00944 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00951 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00952 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00959 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00960 | P1 | SH-M3 | phase-sim | P1 two_red_requests 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00967 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00968 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00975 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00976 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00983 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00984 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00991 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00992 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-00999 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01000 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01007 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01008 | P1 | SH-M3 | phase-sim | P1 all_support_attacked 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01015 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01016 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01023 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01024 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01031 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01032 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01039 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01040 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01047 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01048 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01055 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01056 | P1 | SH-M3 | phase-sim | P1 shipment_route_blocked 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01063 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01064 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01071 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01072 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01079 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01080 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01087 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01088 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01095 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01096 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01103 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01104 | P1 | SH-M3 | phase-sim | P1 hq_critical 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01111 | P1 | SH-M3 | phase-sim | P1 human_support 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01112 | P1 | SH-M3 | phase-sim | P1 human_support 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01119 | P1 | SH-M3 | phase-sim | P1 human_support 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01120 | P1 | SH-M3 | phase-sim | P1 human_support 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01127 | P1 | SH-M3 | phase-sim | P1 human_support 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01128 | P1 | SH-M3 | phase-sim | P1 human_support 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01135 | P1 | SH-M3 | phase-sim | P1 human_support 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01136 | P1 | SH-M3 | phase-sim | P1 human_support 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01143 | P1 | SH-M3 | phase-sim | P1 human_support 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01144 | P1 | SH-M3 | phase-sim | P1 human_support 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01151 | P1 | SH-M3 | phase-sim | P1 human_support 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01152 | P1 | SH-M3 | phase-sim | P1 human_support 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01159 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01160 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01167 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01168 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01175 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01176 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01183 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01184 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01191 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01192 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01199 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01200 | P1 | SH-M3 | phase-sim | P1 human_soldier 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01207 | P1 | SH-M3 | phase-sim | P2 balanced 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01208 | P1 | SH-M3 | phase-sim | P2 balanced 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01215 | P1 | SH-M3 | phase-sim | P2 balanced 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01216 | P1 | SH-M3 | phase-sim | P2 balanced 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01223 | P1 | SH-M3 | phase-sim | P2 balanced 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01224 | P1 | SH-M3 | phase-sim | P2 balanced 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01231 | P1 | SH-M3 | phase-sim | P2 balanced 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01232 | P1 | SH-M3 | phase-sim | P2 balanced 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01239 | P1 | SH-M3 | phase-sim | P2 balanced 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01240 | P1 | SH-M3 | phase-sim | P2 balanced 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01247 | P1 | SH-M3 | phase-sim | P2 balanced 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01248 | P1 | SH-M3 | phase-sim | P2 balanced 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01255 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01256 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01263 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01264 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01271 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01272 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01279 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01280 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01287 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01288 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01295 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01296 | P1 | SH-M3 | phase-sim | P2 north_collapse 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01303 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01304 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01311 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01312 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01319 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01320 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01327 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01328 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01335 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01336 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01343 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01344 | P1 | SH-M3 | phase-sim | P2 center_low_ammo 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01351 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01352 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01359 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01360 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01367 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01368 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01375 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01376 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01383 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01384 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01391 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01392 | P1 | SH-M3 | phase-sim | P2 south_downed 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01399 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01400 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01407 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01408 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01415 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01416 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01423 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01424 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01431 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01432 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01439 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01440 | P1 | SH-M3 | phase-sim | P2 two_red_requests 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01447 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01448 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01455 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01456 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01463 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01464 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01471 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01472 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01479 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01480 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01487 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01488 | P1 | SH-M3 | phase-sim | P2 all_support_attacked 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01495 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01496 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01503 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01504 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01511 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01512 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01519 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01520 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01527 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01528 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01535 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01536 | P1 | SH-M3 | phase-sim | P2 shipment_route_blocked 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01543 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01544 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01551 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01552 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01559 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01560 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01567 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01568 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01575 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01576 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01583 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01584 | P1 | SH-M3 | phase-sim | P2 hq_critical 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01591 | P1 | SH-M3 | phase-sim | P2 human_support 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01592 | P1 | SH-M3 | phase-sim | P2 human_support 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01599 | P1 | SH-M3 | phase-sim | P2 human_support 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01600 | P1 | SH-M3 | phase-sim | P2 human_support 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01607 | P1 | SH-M3 | phase-sim | P2 human_support 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01608 | P1 | SH-M3 | phase-sim | P2 human_support 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01615 | P1 | SH-M3 | phase-sim | P2 human_support 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01616 | P1 | SH-M3 | phase-sim | P2 human_support 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01623 | P1 | SH-M3 | phase-sim | P2 human_support 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01624 | P1 | SH-M3 | phase-sim | P2 human_support 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01631 | P1 | SH-M3 | phase-sim | P2 human_support 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01632 | P1 | SH-M3 | phase-sim | P2 human_support 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01639 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01640 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01647 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01648 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01655 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01656 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01663 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01664 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01671 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01672 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01679 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01680 | P1 | SH-M3 | phase-sim | P2 human_soldier 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01687 | P1 | SH-M3 | phase-sim | P3 balanced 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01688 | P1 | SH-M3 | phase-sim | P3 balanced 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01695 | P1 | SH-M3 | phase-sim | P3 balanced 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01696 | P1 | SH-M3 | phase-sim | P3 balanced 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01703 | P1 | SH-M3 | phase-sim | P3 balanced 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01704 | P1 | SH-M3 | phase-sim | P3 balanced 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01711 | P1 | SH-M3 | phase-sim | P3 balanced 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01712 | P1 | SH-M3 | phase-sim | P3 balanced 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01719 | P1 | SH-M3 | phase-sim | P3 balanced 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01720 | P1 | SH-M3 | phase-sim | P3 balanced 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01727 | P1 | SH-M3 | phase-sim | P3 balanced 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01728 | P1 | SH-M3 | phase-sim | P3 balanced 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01735 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01736 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01743 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01744 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01751 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01752 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01759 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01760 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01767 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01768 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01775 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01776 | P1 | SH-M3 | phase-sim | P3 north_collapse 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01783 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01784 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01791 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01792 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01799 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01800 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01807 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01808 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01815 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01816 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01823 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01824 | P1 | SH-M3 | phase-sim | P3 center_low_ammo 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01831 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01832 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01839 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01840 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01847 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01848 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01855 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01856 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01863 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01864 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01871 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01872 | P1 | SH-M3 | phase-sim | P3 south_downed 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01879 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01880 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01887 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01888 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01895 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01896 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01903 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01904 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01911 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01912 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01919 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01920 | P1 | SH-M3 | phase-sim | P3 two_red_requests 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01927 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01928 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01935 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01936 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01943 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01944 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01951 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01952 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01959 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01960 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01967 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01968 | P1 | SH-M3 | phase-sim | P3 all_support_attacked 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01975 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01976 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01983 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01984 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01991 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01992 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-01999 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02000 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02007 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02008 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02015 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02016 | P1 | SH-M3 | phase-sim | P3 shipment_route_blocked 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02023 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02024 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02031 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02032 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02039 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02040 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02047 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02048 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02055 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02056 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02063 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02064 | P1 | SH-M3 | phase-sim | P3 hq_critical 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02071 | P1 | SH-M3 | phase-sim | P3 human_support 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02072 | P1 | SH-M3 | phase-sim | P3 human_support 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02079 | P1 | SH-M3 | phase-sim | P3 human_support 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02080 | P1 | SH-M3 | phase-sim | P3 human_support 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02087 | P1 | SH-M3 | phase-sim | P3 human_support 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02088 | P1 | SH-M3 | phase-sim | P3 human_support 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02095 | P1 | SH-M3 | phase-sim | P3 human_support 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02096 | P1 | SH-M3 | phase-sim | P3 human_support 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02103 | P1 | SH-M3 | phase-sim | P3 human_support 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02104 | P1 | SH-M3 | phase-sim | P3 human_support 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02111 | P1 | SH-M3 | phase-sim | P3 human_support 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02112 | P1 | SH-M3 | phase-sim | P3 human_support 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02119 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02120 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02127 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02128 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02135 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02136 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02143 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02144 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02151 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02152 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02159 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02160 | P1 | SH-M3 | phase-sim | P3 human_soldier 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02167 | P1 | SH-M4 | phase-sim | P4 balanced 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02168 | P1 | SH-M4 | phase-sim | P4 balanced 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02175 | P1 | SH-M4 | phase-sim | P4 balanced 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02176 | P1 | SH-M4 | phase-sim | P4 balanced 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02183 | P1 | SH-M4 | phase-sim | P4 balanced 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02184 | P1 | SH-M4 | phase-sim | P4 balanced 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02191 | P1 | SH-M4 | phase-sim | P4 balanced 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02192 | P1 | SH-M4 | phase-sim | P4 balanced 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02199 | P1 | SH-M4 | phase-sim | P4 balanced 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02200 | P1 | SH-M4 | phase-sim | P4 balanced 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02207 | P1 | SH-M4 | phase-sim | P4 balanced 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02208 | P1 | SH-M4 | phase-sim | P4 balanced 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02215 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02216 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02223 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02224 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02231 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02232 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02239 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02240 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02247 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02248 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02255 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02256 | P1 | SH-M4 | phase-sim | P4 north_collapse 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02263 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02264 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02271 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02272 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02279 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02280 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02287 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02288 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02295 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02296 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02303 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02304 | P1 | SH-M4 | phase-sim | P4 center_low_ammo 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02311 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02312 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02319 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02320 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02327 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02328 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02335 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02336 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02343 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02344 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02351 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02352 | P1 | SH-M4 | phase-sim | P4 south_downed 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02359 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02360 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02367 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02368 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02375 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02376 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02383 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02384 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02391 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02392 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02399 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02400 | P1 | SH-M4 | phase-sim | P4 two_red_requests 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02407 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02408 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02415 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02416 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02423 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02424 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02431 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02432 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02439 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02440 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02447 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02448 | P1 | SH-M4 | phase-sim | P4 all_support_attacked 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02455 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02456 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02463 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02464 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02471 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02472 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02479 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02480 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02487 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02488 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02495 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02496 | P1 | SH-M4 | phase-sim | P4 shipment_route_blocked 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02503 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02504 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02511 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02512 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02519 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02520 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02527 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02528 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02535 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02536 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02543 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02544 | P1 | SH-M4 | phase-sim | P4 hq_critical 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02551 | P1 | SH-M4 | phase-sim | P4 human_support 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02552 | P1 | SH-M4 | phase-sim | P4 human_support 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02559 | P1 | SH-M4 | phase-sim | P4 human_support 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02560 | P1 | SH-M4 | phase-sim | P4 human_support 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02567 | P1 | SH-M4 | phase-sim | P4 human_support 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02568 | P1 | SH-M4 | phase-sim | P4 human_support 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02575 | P1 | SH-M4 | phase-sim | P4 human_support 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02576 | P1 | SH-M4 | phase-sim | P4 human_support 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02583 | P1 | SH-M4 | phase-sim | P4 human_support 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02584 | P1 | SH-M4 | phase-sim | P4 human_support 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02591 | P1 | SH-M4 | phase-sim | P4 human_support 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02592 | P1 | SH-M4 | phase-sim | P4 human_support 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02599 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02600 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02607 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02608 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02615 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02616 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02623 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02624 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02631 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02632 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02639 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02640 | P1 | SH-M4 | phase-sim | P4 human_soldier 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02647 | P1 | SH-M4 | phase-sim | P5 balanced 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02648 | P1 | SH-M4 | phase-sim | P5 balanced 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02655 | P1 | SH-M4 | phase-sim | P5 balanced 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02656 | P1 | SH-M4 | phase-sim | P5 balanced 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02663 | P1 | SH-M4 | phase-sim | P5 balanced 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02664 | P1 | SH-M4 | phase-sim | P5 balanced 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02671 | P1 | SH-M4 | phase-sim | P5 balanced 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02672 | P1 | SH-M4 | phase-sim | P5 balanced 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02679 | P1 | SH-M4 | phase-sim | P5 balanced 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02680 | P1 | SH-M4 | phase-sim | P5 balanced 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02687 | P1 | SH-M4 | phase-sim | P5 balanced 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02688 | P1 | SH-M4 | phase-sim | P5 balanced 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02695 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02696 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02703 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02704 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02711 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02712 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02719 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02720 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02727 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02728 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02735 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02736 | P1 | SH-M4 | phase-sim | P5 north_collapse 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02743 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02744 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02751 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02752 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02759 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02760 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02767 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02768 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02775 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02776 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02783 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02784 | P1 | SH-M4 | phase-sim | P5 center_low_ammo 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02791 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02792 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02799 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02800 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02807 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02808 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02815 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02816 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02823 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02824 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02831 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02832 | P1 | SH-M4 | phase-sim | P5 south_downed 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02839 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02840 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02847 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02848 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02855 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02856 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02863 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02864 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02871 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02872 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02879 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02880 | P1 | SH-M4 | phase-sim | P5 two_red_requests 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02887 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02888 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02895 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02896 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02903 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02904 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02911 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02912 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02919 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02920 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02927 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02928 | P1 | SH-M4 | phase-sim | P5 all_support_attacked 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02935 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02936 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02943 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02944 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02951 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02952 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02959 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02960 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02967 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02968 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02975 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02976 | P1 | SH-M4 | phase-sim | P5 shipment_route_blocked 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02983 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02984 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02991 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02992 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-02999 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03000 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03007 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03008 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03015 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03016 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03023 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03024 | P1 | SH-M4 | phase-sim | P5 hq_critical 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03031 | P1 | SH-M4 | phase-sim | P5 human_support 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03032 | P1 | SH-M4 | phase-sim | P5 human_support 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03039 | P1 | SH-M4 | phase-sim | P5 human_support 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03040 | P1 | SH-M4 | phase-sim | P5 human_support 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03047 | P1 | SH-M4 | phase-sim | P5 human_support 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03048 | P1 | SH-M4 | phase-sim | P5 human_support 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03055 | P1 | SH-M4 | phase-sim | P5 human_support 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03056 | P1 | SH-M4 | phase-sim | P5 human_support 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03063 | P1 | SH-M4 | phase-sim | P5 human_support 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03064 | P1 | SH-M4 | phase-sim | P5 human_support 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03071 | P1 | SH-M4 | phase-sim | P5 human_support 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03072 | P1 | SH-M4 | phase-sim | P5 human_support 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03079 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=vanguard seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03080 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=vanguard seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03087 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=rifleman seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03088 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=rifleman seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03095 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=controller seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03096 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=controller seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03103 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=quartermaster seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03104 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=quartermaster seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03111 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=medic seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03112 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=medic seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03119 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=engineer_support seed 0 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03120 | P1 | SH-M4 | phase-sim | P5 human_soldier 인간=engineer_support seed 1 | CPU 역할이 공개 정보로 반응하고 소프트락·완벽 보급·이유 불명 실패 없이 종료 |
| SH-03127 | P1 | SH-M4 | causal-log | ammo_to_marker 인과 깊이 1 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03128 | P1 | SH-M4 | causal-log | ammo_to_marker 인과 깊이 1 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03129 | P1 | SH-M4 | causal-log | ammo_to_marker 인과 깊이 1 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03130 | P1 | SH-M4 | causal-log | ammo_to_marker 인과 깊이 1 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03131 | P1 | SH-M4 | causal-log | ammo_to_marker 인과 깊이 1 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03152 | P1 | SH-M4 | causal-log | ammo_to_marker 인과 깊이 6 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03153 | P1 | SH-M4 | causal-log | ammo_to_marker 인과 깊이 6 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03154 | P1 | SH-M4 | causal-log | ammo_to_marker 인과 깊이 6 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03155 | P1 | SH-M4 | causal-log | ammo_to_marker 인과 깊이 6 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03156 | P1 | SH-M4 | causal-log | ammo_to_marker 인과 깊이 6 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03157 | P1 | SH-M4 | causal-log | heal_to_downed 인과 깊이 1 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03158 | P1 | SH-M4 | causal-log | heal_to_downed 인과 깊이 1 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03159 | P1 | SH-M4 | causal-log | heal_to_downed 인과 깊이 1 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03160 | P1 | SH-M4 | causal-log | heal_to_downed 인과 깊이 1 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03161 | P1 | SH-M4 | causal-log | heal_to_downed 인과 깊이 1 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03182 | P1 | SH-M4 | causal-log | heal_to_downed 인과 깊이 6 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03183 | P1 | SH-M4 | causal-log | heal_to_downed 인과 깊이 6 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03184 | P1 | SH-M4 | causal-log | heal_to_downed 인과 깊이 6 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03185 | P1 | SH-M4 | causal-log | heal_to_downed 인과 깊이 6 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03186 | P1 | SH-M4 | causal-log | heal_to_downed 인과 깊이 6 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03187 | P1 | SH-M4 | causal-log | repair_to_route 인과 깊이 1 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03188 | P1 | SH-M4 | causal-log | repair_to_route 인과 깊이 1 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03189 | P1 | SH-M4 | causal-log | repair_to_route 인과 깊이 1 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03190 | P1 | SH-M4 | causal-log | repair_to_route 인과 깊이 1 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03191 | P1 | SH-M4 | causal-log | repair_to_route 인과 깊이 1 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03212 | P1 | SH-M4 | causal-log | repair_to_route 인과 깊이 6 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03213 | P1 | SH-M4 | causal-log | repair_to_route 인과 깊이 6 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03214 | P1 | SH-M4 | causal-log | repair_to_route 인과 깊이 6 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03215 | P1 | SH-M4 | causal-log | repair_to_route 인과 깊이 6 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03216 | P1 | SH-M4 | causal-log | repair_to_route 인과 깊이 6 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03217 | P1 | SH-M4 | causal-log | soldier_leave_lane 인과 깊이 1 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03218 | P1 | SH-M4 | causal-log | soldier_leave_lane 인과 깊이 1 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03219 | P1 | SH-M4 | causal-log | soldier_leave_lane 인과 깊이 1 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03220 | P1 | SH-M4 | causal-log | soldier_leave_lane 인과 깊이 1 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03221 | P1 | SH-M4 | causal-log | soldier_leave_lane 인과 깊이 1 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03242 | P1 | SH-M4 | causal-log | soldier_leave_lane 인과 깊이 6 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03243 | P1 | SH-M4 | causal-log | soldier_leave_lane 인과 깊이 6 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03244 | P1 | SH-M4 | causal-log | soldier_leave_lane 인과 깊이 6 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03245 | P1 | SH-M4 | causal-log | soldier_leave_lane 인과 깊이 6 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03246 | P1 | SH-M4 | causal-log | soldier_leave_lane 인과 깊이 6 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03247 | P1 | SH-M4 | causal-log | shipment_destroyed 인과 깊이 1 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03248 | P1 | SH-M4 | causal-log | shipment_destroyed 인과 깊이 1 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03249 | P1 | SH-M4 | causal-log | shipment_destroyed 인과 깊이 1 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03250 | P1 | SH-M4 | causal-log | shipment_destroyed 인과 깊이 1 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03251 | P1 | SH-M4 | causal-log | shipment_destroyed 인과 깊이 1 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03272 | P1 | SH-M4 | causal-log | shipment_destroyed 인과 깊이 6 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03273 | P1 | SH-M4 | causal-log | shipment_destroyed 인과 깊이 6 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03274 | P1 | SH-M4 | causal-log | shipment_destroyed 인과 깊이 6 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03275 | P1 | SH-M4 | causal-log | shipment_destroyed 인과 깊이 6 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03276 | P1 | SH-M4 | causal-log | shipment_destroyed 인과 깊이 6 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03277 | P1 | SH-M4 | causal-log | support_killed 인과 깊이 1 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03278 | P1 | SH-M4 | causal-log | support_killed 인과 깊이 1 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03279 | P1 | SH-M4 | causal-log | support_killed 인과 깊이 1 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03280 | P1 | SH-M4 | causal-log | support_killed 인과 깊이 1 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03281 | P1 | SH-M4 | causal-log | support_killed 인과 깊이 1 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03302 | P1 | SH-M4 | causal-log | support_killed 인과 깊이 6 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03303 | P1 | SH-M4 | causal-log | support_killed 인과 깊이 6 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03304 | P1 | SH-M4 | causal-log | support_killed 인과 깊이 6 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03305 | P1 | SH-M4 | causal-log | support_killed 인과 깊이 6 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03306 | P1 | SH-M4 | causal-log | support_killed 인과 깊이 6 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03307 | P1 | SH-M4 | causal-log | vehicle_stall 인과 깊이 1 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03308 | P1 | SH-M4 | causal-log | vehicle_stall 인과 깊이 1 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03309 | P1 | SH-M4 | causal-log | vehicle_stall 인과 깊이 1 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03310 | P1 | SH-M4 | causal-log | vehicle_stall 인과 깊이 1 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03311 | P1 | SH-M4 | causal-log | vehicle_stall 인과 깊이 1 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03332 | P1 | SH-M4 | causal-log | vehicle_stall 인과 깊이 6 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03333 | P1 | SH-M4 | causal-log | vehicle_stall 인과 깊이 6 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03334 | P1 | SH-M4 | causal-log | vehicle_stall 인과 깊이 6 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03335 | P1 | SH-M4 | causal-log | vehicle_stall 인과 깊이 6 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03336 | P1 | SH-M4 | causal-log | vehicle_stall 인과 깊이 6 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03337 | P1 | SH-M4 | causal-log | spawner_buff 인과 깊이 1 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03338 | P1 | SH-M4 | causal-log | spawner_buff 인과 깊이 1 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03339 | P1 | SH-M4 | causal-log | spawner_buff 인과 깊이 1 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03340 | P1 | SH-M4 | causal-log | spawner_buff 인과 깊이 1 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03341 | P1 | SH-M4 | causal-log | spawner_buff 인과 깊이 1 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03362 | P1 | SH-M4 | causal-log | spawner_buff 인과 깊이 6 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03363 | P1 | SH-M4 | causal-log | spawner_buff 인과 깊이 6 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03364 | P1 | SH-M4 | causal-log | spawner_buff 인과 깊이 6 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03365 | P1 | SH-M4 | causal-log | spawner_buff 인과 깊이 6 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03366 | P1 | SH-M4 | causal-log | spawner_buff 인과 깊이 6 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03367 | P1 | SH-M4 | causal-log | boss_pulse 인과 깊이 1 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03368 | P1 | SH-M4 | causal-log | boss_pulse 인과 깊이 1 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03369 | P1 | SH-M4 | causal-log | boss_pulse 인과 깊이 1 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03370 | P1 | SH-M4 | causal-log | boss_pulse 인과 깊이 1 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03371 | P1 | SH-M4 | causal-log | boss_pulse 인과 깊이 1 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03392 | P1 | SH-M4 | causal-log | boss_pulse 인과 깊이 6 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03393 | P1 | SH-M4 | causal-log | boss_pulse 인과 깊이 6 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03394 | P1 | SH-M4 | causal-log | boss_pulse 인과 깊이 6 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03395 | P1 | SH-M4 | causal-log | boss_pulse 인과 깊이 6 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03396 | P1 | SH-M4 | causal-log | boss_pulse 인과 깊이 6 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03397 | P1 | SH-M4 | causal-log | three_downed 인과 깊이 1 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03398 | P1 | SH-M4 | causal-log | three_downed 인과 깊이 1 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03399 | P1 | SH-M4 | causal-log | three_downed 인과 깊이 1 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03400 | P1 | SH-M4 | causal-log | three_downed 인과 깊이 1 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03401 | P1 | SH-M4 | causal-log | three_downed 인과 깊이 1 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03422 | P1 | SH-M4 | causal-log | three_downed 인과 깊이 6 분기 1 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03423 | P1 | SH-M4 | causal-log | three_downed 인과 깊이 6 분기 2 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03424 | P1 | SH-M4 | causal-log | three_downed 인과 깊이 6 분기 3 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03425 | P1 | SH-M4 | causal-log | three_downed 인과 깊이 6 분기 4 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
| SH-03426 | P1 | SH-M4 | causal-log | three_downed 인과 깊이 6 분기 5 | 순환 없이 최대 6단계, 가장 큰 기여 3개가 수치 근거와 함께 표시 |
