# 신 마을 지키기 — P0/P1 완료 게이트

- P0: **161개**
- P1: **660개**
- P0 또는 P1 중 하나라도 미완료면 다음 공개 빌드·아트 교체·온라인 확장을 진행하지 않는다.
- 실제 상태 기록은 `CHECKLIST_VIEWER.html`, CSV 또는 팀 이슈 트래커 중 하나를 정답으로 정하고 중복 관리하지 않는다.

| ID | 등급 | 마일스톤 | 영역 | 항목 | 통과 기준 |
|---|---:|---|---|---|---|
| VD-COM-00001 | P0 | M0 | boot | 앱 최초 부팅 | Viewport가 2초 이내 생성되고 Output/Debugger 오류이 비어 있다 |
| VD-COM-00002 | P0 | M0 | loop | 60Hz 고정 틱 | 최종 상태 해시가 모두 동일하다 |
| VD-COM-00003 | P0 | M0 | rng | randf()/randi() 금지 | 시뮬레이션 경로에서 randf()/randi() 호출 0건 |
| VD-COM-00004 | P0 | M0 | input | 포커스 상실 키 해제 | 복귀 시 캐릭터가 계속 이동하지 않는다 |
| VD-COM-00005 | P0 | M0 | input | 우클릭 브라우저 메뉴 차단 | 브라우저 컨텍스트 메뉴가 뜨지 않고 게임 명령만 기록된다 |
| VD-COM-00006 | P0 | M0 | replay | 입력 리플레이 | 300틱 간격 모든 상태 해시가 일치한다 |
| VD-COM-00007 | P0 | M0 | data | 설정 해시 | 정규화된 configHash가 동일하다 |
| VD-COM-00019 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00020 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00021 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00022 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00023 | P0 | M0 | determinism | 프레임 일정 steady_60, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00059 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00060 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00061 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00062 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00063 | P0 | M0 | determinism | 프레임 일정 steady_120, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00099 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00100 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00101 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00102 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00103 | P0 | M0 | determinism | 프레임 일정 steady_144, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00139 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00140 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00141 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00142 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00143 | P0 | M0 | determinism | 프레임 일정 jitter_8_24ms, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00179 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00180 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00181 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00182 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00183 | P0 | M0 | determinism | 프레임 일정 stall_180ms_every_10s, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00219 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 0 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00220 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 1 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00221 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 2 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00222 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 3 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-COM-00223 | P0 | M0 | determinism | 프레임 일정 background_resume, 시드 4 결정론 | 모든 300틱 상태 해시와 최종 결과가 일치한다 |
| VD-GD-0001 | P0 | M0 | boot | Godot 4.7.1 프로젝트 import | 스크립트·씬 import 오류 0건, Main Scene 지정 |
| VD-GD-0002 | P0 | M0 | boot | F5 최초 실행 | 2초 안에 회색상자 월드와 HUD가 표시되고 오류 0건 |
| VD-GD-0003 | P0 | M0 | boot | 독립 ZIP 의존성 | 외부 상대경로·공통 저장소 없이 실행 |
| VD-GD-0004 | P0 | M0 | loop | physics tick 60 고정 | 정확히 60 |
| VD-GD-0005 | P0 | M0 | loop | _process 판정 변경 금지 | _process에서 GameWorld의 판정 필드를 직접 변경하는 코드 0건 |
| VD-GD-0006 | P0 | M0 | loop | Godot 물리 콜백 순서 비의존 | 명령 정렬·커스텀 판정 결과 해시 동일 |
| VD-GD-0007 | P0 | M0 | rng | 시뮬레이션 randf/randi 금지 | 시드 RNG 래퍼 외 randf/randi/randomize 호출 0건 |
| VD-GD-0008 | P0 | M0 | rng | 시드 재현 | 300틱 간격 상태 해시 100% 일치 |
| VD-GD-0009 | P0 | M0 | input | edge 입력 1회 소비 | 기술 명령은 1회만 생성 |
| VD-GD-0010 | P0 | M0 | input | 포커스 상실 입력 해제 | 이동·공격 hold가 고착되지 않음 |
| VD-GD-0012 | P0 | M0 | viewport | 1600x900 논리 좌표 | 월드 판정 좌표 동일, 레터박스/확장 정책대로 표시 |
| VD-GD-0013 | P0 | M0 | camera | Camera2D와 HUD 분리 | CanvasLayer HUD는 화면에 고정 |
| VD-GD-0015 | P0 | M0 | render | 렌더 상태 역류 금지 | 다음 physics tick 판정에 영향 0 |
| VD-GD-0017 | P0 | M0 | scene | 씬 reload 없는 매치 재시작 | Node 수·메모리·시그널 연결 수가 기준 ±1% 이내 |
| VD-GD-0018 | P0 | M0 | scene | World 교체 후 이전 참조 제거 | 이전 World의 엔티티·이벤트가 보이지 않음 |
| VD-GD-0019 | P0 | M0 | data | JSON 문법과 스키마 | 파싱 오류·중복 ID·미존재 참조 0건 |
| VD-GD-0020 | P0 | M0 | data | 잘못된 데이터 fail-fast | 명확한 경로·키와 함께 부팅 중단, 조용한 기본값 대체 없음 |
| VD-GD-0021 | P0 | M0 | event-log | EventLog 순번 | event_id가 중복 없이 증가하고 tick/actor/target 포함 |
| VD-GD-0022 | P0 | M0 | invariant | NaN·INF 즉시 검출 | 불변식 오류와 시드·tick 덤프 후 테스트 실패 |
| VD-GD-0023 | P0 | M0 | headless | 헤드리스 smoke 진입 | 종료코드 0과 SMOKE_OK JSON 출력 |
| VD-GD-0024 | P0 | M0 | headless | 헤드리스 시간 독립 | 게임 판정이 렌더 노드 없이 완료 |
| VD-GD-0049 | P0 | M0 | starter | 스타터 조작 계약 | 각 입력의 즉시 피드백과 비용·쿨다운이 HUD/월드에 표시 |
| VD-GD-0050 | P0 | M0 | starter | 인간 1+CPU 구성 | 인간 1명과 CPU 5명이 생성되고 CPU가 목표 행동 시작 |
| VD-GD-0051 | P0 | M0 | starter | R 새 시드 재시작 | 즉시 새 World가 만들어지고 seed가 1씩 증가 |
| VD-COM-00008 | P0 | M1 | collision | NaN 방지 | 위치·속도·체력에 NaN/Infinity가 없다 |
| VD-GD-0025 | P0 | M1 | ai | CPU도 PlayerCommand 사용 | 인간과 동일 명령 스키마·검증·쿨다운 경로 사용 |
| VD-GD-0026 | P0 | M1 | ai-audit | CPU 숨은 상태 접근 감사 | Observation에 없던 값으로 행동이 바뀌지 않음 |
| VD-GD-0030 | P0 | M1 | performance | physics 프레임 예산 | p95 simulation step 8ms 이하 |
| VD-GD-0032 | P0 | M1 | replay | 명령 리플레이 | 최종 결과·중간 해시·중요 EventLog 동일 |
| VD-GD-0033 | P0 | M1 | replay | 리플레이 버전 거부 | 호환 불가 사유 표시 후 실행 거부 |
| VD-GD-0034 | P0 | M1 | ux | 실패 원인 5초 식별 | 80% 이상이 원인 행위자·사건을 5초 내 식별 |
| VD-GD-0037 | P0 | M1 | pause | 일시정지 tick 정지 | World tick·쿨다운·스폰이 증가하지 않음 |
| VD-GD-0053 | P0 | M1 | fun | 핵심 재미 사건 발생률 | 문서의 핵심 재미 사건이 목표 빈도 범위에 들어옴 |
| VD-GD-0054 | P0 | M1 | fun | 실패도 관전 가능 | 매치가 계속 진행되고 중요한 사건·승패 원인이 표시 |
| VD-COM-00010 | P0 | M2 | ai | 숨은 정보 금지 | 비가시 엔티티를 직접 action target으로 선택하지 않는다 |
| VD-COM-00011 | P0 | M2 | ai | 반응 지연 | 130ms 미만 반응 0건, 평균 175~270ms |
| VD-GD-0039 | P0 | M2 | export | Windows export 입력 유지 | 편집기와 조작·판정·결과 동일 |
| VD-GD-0043 | P0 | M2 | cleanup | 결과 확정 후 상태 고정 | 점수·HP·소유권·스폰 변화 0 |
| VD-GD-0045 | P0 | M2 | package | smoke/playability 회귀 검사 | 두 테스트가 오류 없이 종료 |
| VD-GD-0046 | P0 | M2 | package | 문서-코드 경로 정합 | 존재하지 않는 파일 0건 |
| VD-GD-0058 | P0 | M2 | acceptance | 최종 수락 지표 | 기능 오류 없이 핵심 재미가 최소 70% 판에서 체감되고 원인 로그 존재 |
| VD-COM-00013 | P0 | M3 | performance | 풀 누수 | 활성 수가 안정된 뒤 풀 총량이 10% 이상 증가하지 않는다 |
| VD-COM-00014 | P0 | M3 | performance | 시뮬레이션 오버런 | 최대 5틱 실행 후 잔여 누적을 버리고 입력 가능 |
| VD-COM-00017 | P0 | M4 | telemetry | 원인 이벤트 연결 | 손실 이벤트가 최대 6단계 원인으로 역추적 가능 |
| VD-00001 | P0 | VD-M0 | flow-field | 일반 적 흐름장 | 모든 적이 A* 개별 호출 없이 성문 도달, NaN 0 |
| VD-00002 | P0 | VD-M2 | kill | 막타 킬 귀속 | 초과량 큰 피해 이벤트 소유자에게 킬 1 |
| VD-00003 | P0 | VD-M2 | evolution | 2000킬 패시브 | 5단계·1.72 배율·직업 패시브가 같은 틱 적용 |
| VD-00004 | P0 | VD-M2 | upgrade | 무사망 255 상한 | 255 성공, 추가 구매 실패 |
| VD-00005 | P0 | VD-M2 | upgrade | 사망 후 180 상한 | 자원 미소모·레벨 유지·상한 UI 표시 |
| VD-00006 | P0 | VD-M3 | stasis | 전멸기 스테이시스 차단 | 시전 취소·12초 방어 -20%, 스테이시스 쿨다운 소비 |
| VD-00009 | P0 | VD-M3 | class-skill | 수호자 도발 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00012 | P0 | VD-M3 | class-skill | 수호자 도발 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00018 | P0 | VD-M3 | class-skill | 수호자 도발 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00021 | P0 | VD-M3 | class-skill | 수호자 방패벽 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00024 | P0 | VD-M3 | class-skill | 수호자 방패벽 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00030 | P0 | VD-M3 | class-skill | 수호자 방패벽 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00033 | P0 | VD-M3 | class-skill | 수호자 대지충격 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00036 | P0 | VD-M3 | class-skill | 수호자 대지충격 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00042 | P0 | VD-M3 | class-skill | 수호자 대지충격 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00045 | P0 | VD-M3 | class-skill | 광전사 도약 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00048 | P0 | VD-M3 | class-skill | 광전사 도약 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00054 | P0 | VD-M3 | class-skill | 광전사 도약 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00057 | P0 | VD-M3 | class-skill | 광전사 처형 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00060 | P0 | VD-M3 | class-skill | 광전사 처형 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00066 | P0 | VD-M3 | class-skill | 광전사 처형 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00069 | P0 | VD-M3 | class-skill | 광전사 광분 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00072 | P0 | VD-M3 | class-skill | 광전사 광분 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00078 | P0 | VD-M3 | class-skill | 광전사 광분 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00081 | P0 | VD-M3 | class-skill | 사냥꾼 관통사격 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00084 | P0 | VD-M3 | class-skill | 사냥꾼 관통사격 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00090 | P0 | VD-M3 | class-skill | 사냥꾼 관통사격 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00093 | P0 | VD-M3 | class-skill | 사냥꾼 덫 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00096 | P0 | VD-M3 | class-skill | 사냥꾼 덫 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00102 | P0 | VD-M3 | class-skill | 사냥꾼 덫 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00105 | P0 | VD-M3 | class-skill | 사냥꾼 연사 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00108 | P0 | VD-M3 | class-skill | 사냥꾼 연사 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00114 | P0 | VD-M3 | class-skill | 사냥꾼 연사 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00117 | P0 | VD-M3 | class-skill | 마법사 폭발구 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00120 | P0 | VD-M3 | class-skill | 마법사 폭발구 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00126 | P0 | VD-M3 | class-skill | 마법사 폭발구 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00129 | P0 | VD-M3 | class-skill | 마법사 스테이시스 필드 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00132 | P0 | VD-M3 | class-skill | 마법사 스테이시스 필드 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00138 | P0 | VD-M3 | class-skill | 마법사 스테이시스 필드 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00141 | P0 | VD-M3 | class-skill | 마법사 점멸 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00144 | P0 | VD-M3 | class-skill | 마법사 점멸 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00150 | P0 | VD-M3 | class-skill | 마법사 점멸 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00153 | P0 | VD-M3 | class-skill | 사제 치유 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00156 | P0 | VD-M3 | class-skill | 사제 치유 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00162 | P0 | VD-M3 | class-skill | 사제 치유 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00165 | P0 | VD-M3 | class-skill | 사제 보호막 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00168 | P0 | VD-M3 | class-skill | 사제 보호막 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00174 | P0 | VD-M3 | class-skill | 사제 보호막 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00177 | P0 | VD-M3 | class-skill | 사제 전투부활 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00180 | P0 | VD-M3 | class-skill | 사제 전투부활 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00186 | P0 | VD-M3 | class-skill | 사제 전투부활 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00189 | P0 | VD-M3 | class-skill | 기술자 포탑 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00192 | P0 | VD-M3 | class-skill | 기술자 포탑 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00198 | P0 | VD-M3 | class-skill | 기술자 포탑 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00201 | P0 | VD-M3 | class-skill | 기술자 바리케이드 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00204 | P0 | VD-M3 | class-skill | 기술자 바리케이드 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00210 | P0 | VD-M3 | class-skill | 기술자 바리케이드 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00213 | P0 | VD-M3 | class-skill | 기술자 과충전 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00216 | P0 | VD-M3 | class-skill | 기술자 과충전 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00222 | P0 | VD-M3 | class-skill | 기술자 과충전 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00225 | P0 | VD-M3 | class-skill | 창기병 돌진 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00228 | P0 | VD-M3 | class-skill | 창기병 돌진 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00234 | P0 | VD-M3 | class-skill | 창기병 돌진 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00237 | P0 | VD-M3 | class-skill | 창기병 회전베기 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00240 | P0 | VD-M3 | class-skill | 창기병 회전베기 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00246 | P0 | VD-M3 | class-skill | 창기병 회전베기 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00249 | P0 | VD-M3 | class-skill | 창기병 전투깃발 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00252 | P0 | VD-M3 | class-skill | 창기병 전투깃발 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00258 | P0 | VD-M3 | class-skill | 창기병 전투깃발 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00261 | P0 | VD-M3 | class-skill | 소환술사 소환 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00264 | P0 | VD-M3 | class-skill | 소환술사 소환 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00270 | P0 | VD-M3 | class-skill | 소환술사 소환 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00273 | P0 | VD-M3 | class-skill | 소환술사 희생폭발 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00276 | P0 | VD-M3 | class-skill | 소환술사 희생폭발 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00282 | P0 | VD-M3 | class-skill | 소환술사 희생폭발 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00285 | P0 | VD-M3 | class-skill | 소환술사 군단강화 / valid_pack | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00288 | P0 | VD-M3 | class-skill | 소환술사 군단강화 / caster_dies | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00294 | P0 | VD-M3 | class-skill | 소환술사 군단강화 / boss | 데이터 효과와 일치하고 아군·이장에 비의도 피해, 중복 적용, 성능 폭증이 없다 |
| VD-00007 | P0 | VD-M4 | boss | 보스 3페이즈 전환 | 65%, 28%에서 한 번만 전환하고 패턴 중복 없음 |
| VD-00008 | P0 | VD-M4 | performance | 1200 적 프레임 | 95퍼센타일 프레임 18ms 이하, 입력 1틱 |
| VD-GD-0011 | P1 | M0 | input | 키보드 동시입력 정규화 | 대각선 속도가 축 속도와 동일 |
| VD-GD-0014 | P1 | M0 | camera | 마우스 월드 좌표 역변환 | 조준점 오차 1 world unit 이하 |
| VD-GD-0016 | P1 | M0 | render | queue_redraw 호출 상한 | 월드·HUD 각각 physics tick당 최대 1회 |
| VD-GD-0052 | P1 | M0 | starter | 더미 아트 판정 가독성 | 색·형태·번호만으로 객체 역할과 소유자 식별 |
| VD-COM-00009 | P1 | M1 | camera | 레터박스 좌표 | 월드 좌표가 보이는 클릭 마커와 2px 이내 일치 |
| VD-COM-00259 | P1 | M1 | viewport | 960×540 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00260 | P1 | M1 | viewport | 960×540 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00261 | P1 | M1 | viewport | 960×540 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00262 | P1 | M1 | viewport | 960×540 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00263 | P1 | M1 | viewport | 960×540 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00264 | P1 | M1 | viewport | 960×540 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00265 | P1 | M1 | viewport | 960×540 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00266 | P1 | M1 | viewport | 960×540 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00267 | P1 | M1 | viewport | 960×540 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00268 | P1 | M1 | viewport | 960×540 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00269 | P1 | M1 | viewport | 960×540 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00270 | P1 | M1 | viewport | 960×540 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00271 | P1 | M1 | viewport | 960×540 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00272 | P1 | M1 | viewport | 960×540 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00273 | P1 | M1 | viewport | 960×540 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00304 | P1 | M1 | viewport | 1600×900 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00305 | P1 | M1 | viewport | 1600×900 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00306 | P1 | M1 | viewport | 1600×900 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00307 | P1 | M1 | viewport | 1600×900 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00308 | P1 | M1 | viewport | 1600×900 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00309 | P1 | M1 | viewport | 1600×900 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00310 | P1 | M1 | viewport | 1600×900 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00311 | P1 | M1 | viewport | 1600×900 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00312 | P1 | M1 | viewport | 1600×900 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00313 | P1 | M1 | viewport | 1600×900 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00314 | P1 | M1 | viewport | 1600×900 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00315 | P1 | M1 | viewport | 1600×900 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00316 | P1 | M1 | viewport | 1600×900 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00317 | P1 | M1 | viewport | 1600×900 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00318 | P1 | M1 | viewport | 1600×900 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00349 | P1 | M1 | viewport | 3840×2160 DPR 1.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00350 | P1 | M1 | viewport | 3840×2160 DPR 1.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00351 | P1 | M1 | viewport | 3840×2160 DPR 1.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00352 | P1 | M1 | viewport | 3840×2160 DPR 1.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00353 | P1 | M1 | viewport | 3840×2160 DPR 1.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00354 | P1 | M1 | viewport | 3840×2160 DPR 1.5 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00355 | P1 | M1 | viewport | 3840×2160 DPR 1.5 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00356 | P1 | M1 | viewport | 3840×2160 DPR 1.5 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00357 | P1 | M1 | viewport | 3840×2160 DPR 1.5 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00358 | P1 | M1 | viewport | 3840×2160 DPR 1.5 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00359 | P1 | M1 | viewport | 3840×2160 DPR 2.0 menu 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00360 | P1 | M1 | viewport | 3840×2160 DPR 2.0 playing 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00361 | P1 | M1 | viewport | 3840×2160 DPR 2.0 paused 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00362 | P1 | M1 | viewport | 3840×2160 DPR 2.0 result 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00363 | P1 | M1 | viewport | 3840×2160 DPR 2.0 debug 레이아웃 | 핵심 UI가 잘리지 않고 포인터 오차 2px 이하, 가로 비율이 찌그러지지 않는다 |
| VD-COM-00364 | P1 | M1 | input | 입력 move_up / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00370 | P1 | M1 | input | 입력 move_up / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00373 | P1 | M1 | input | 입력 move_up / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00374 | P1 | M1 | input | 입력 move_down / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00380 | P1 | M1 | input | 입력 move_down / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00383 | P1 | M1 | input | 입력 move_down / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00384 | P1 | M1 | input | 입력 move_left / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00390 | P1 | M1 | input | 입력 move_left / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00393 | P1 | M1 | input | 입력 move_left / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00394 | P1 | M1 | input | 입력 move_right / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00400 | P1 | M1 | input | 입력 move_right / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00403 | P1 | M1 | input | 입력 move_right / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00404 | P1 | M1 | input | 입력 diagonal / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00410 | P1 | M1 | input | 입력 diagonal / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00413 | P1 | M1 | input | 입력 diagonal / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00414 | P1 | M1 | input | 입력 primary / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00420 | P1 | M1 | input | 입력 primary / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00423 | P1 | M1 | input | 입력 primary / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00424 | P1 | M1 | input | 입력 secondary / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00430 | P1 | M1 | input | 입력 secondary / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00433 | P1 | M1 | input | 입력 secondary / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00434 | P1 | M1 | input | 입력 ability_q / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00440 | P1 | M1 | input | 입력 ability_q / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00443 | P1 | M1 | input | 입력 ability_q / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00444 | P1 | M1 | input | 입력 ability_w / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00450 | P1 | M1 | input | 입력 ability_w / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00453 | P1 | M1 | input | 입력 ability_w / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00454 | P1 | M1 | input | 입력 ability_e / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00460 | P1 | M1 | input | 입력 ability_e / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00463 | P1 | M1 | input | 입력 ability_e / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00464 | P1 | M1 | input | 입력 ability_r / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00470 | P1 | M1 | input | 입력 ability_r / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00473 | P1 | M1 | input | 입력 ability_r / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00474 | P1 | M1 | input | 입력 ability_f / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00480 | P1 | M1 | input | 입력 ability_f / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00483 | P1 | M1 | input | 입력 ability_f / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00484 | P1 | M1 | input | 입력 dash / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00490 | P1 | M1 | input | 입력 dash / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00493 | P1 | M1 | input | 입력 dash / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00494 | P1 | M1 | input | 입력 ping / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00500 | P1 | M1 | input | 입력 ping / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00503 | P1 | M1 | input | 입력 ping / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00504 | P1 | M1 | input | 입력 pause / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00510 | P1 | M1 | input | 입력 pause / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00513 | P1 | M1 | input | 입력 pause / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00514 | P1 | M1 | input | 입력 restart / 상태 normal | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00520 | P1 | M1 | input | 입력 restart / 상태 focus_lost | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-COM-00523 | P1 | M1 | input | 입력 restart / 상태 sim_overrun | 정의된 우선순위와 버퍼 규칙대로 정확히 한 명령만 시뮬레이션에 반영되고 유실·중복이 없다 |
| VD-GD-0027 | P1 | M1 | ai | CPU 반응 지연 | 프로필 min/max 안에서 T 이후 반응, 0틱 완벽반응 0건 |
| VD-GD-0028 | P1 | M1 | ai | CPU 동일 실수 반복 제한 | 같은 치명 실수를 연속 2회 이상 의도 삽입하지 않음 |
| VD-GD-0029 | P1 | M1 | ai | 인간 슬롯 편향 없음 | CPU 목표·지원·공격 확률이 슬롯 평균 허용오차 이내 |
| VD-GD-0031 | P1 | M1 | performance | 렌더 객체 증가 상한 | CanvasItem/Node 수가 설계 상한 이내이며 계속 증가하지 않음 |
| VD-GD-0035 | P1 | M1 | ux | CPU 구분 가독성 | 인간 캐릭터를 1초 내 찾는 성공률 95% 이상 |
| VD-GD-0036 | P1 | M1 | audio | 판정과 오디오 분리 | 상태 해시 동일 |
| VD-GD-0038 | P1 | M1 | save | user:// 쓰기 실패 안전 | 게임은 계속되고 저장 실패 1회만 경고 |
| VD-GD-0055 | P1 | M1 | fun | CPU 과도한 최적화 금지 | 한 전략/한 경로 점유율이 65%를 넘지 않음 |
| VD-GD-0056 | P1 | M1 | fun | CPU 무능 연출 금지 | 실행 가능한 기본 목표를 85% 이상 수행 |
| VD-GD-0057 | P1 | M1 | fun | 인간 개입 가치 | 인간 행동이 사건·결과를 바꾸되 혼자 모든 판을 지배하지 않음 |
| VD-COM-00012 | P1 | M2 | ai | 행동 관성 | CPU가 초당 2회 이상 표적을 왕복하지 않는다 |
| VD-COM-00524 | P1 | M2 | ai-audit | CPU balanced / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00525 | P1 | M2 | ai-audit | CPU balanced / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00532 | P1 | M2 | ai-audit | CPU balanced / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00533 | P1 | M2 | ai-audit | CPU balanced / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00540 | P1 | M2 | ai-audit | CPU balanced / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00541 | P1 | M2 | ai-audit | CPU balanced / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00548 | P1 | M2 | ai-audit | CPU balanced / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00549 | P1 | M2 | ai-audit | CPU balanced / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00556 | P1 | M2 | ai-audit | CPU balanced / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00557 | P1 | M2 | ai-audit | CPU balanced / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00564 | P1 | M2 | ai-audit | CPU balanced / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00565 | P1 | M2 | ai-audit | CPU balanced / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00572 | P1 | M2 | ai-audit | CPU balanced / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00573 | P1 | M2 | ai-audit | CPU balanced / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00580 | P1 | M2 | ai-audit | CPU balanced / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00581 | P1 | M2 | ai-audit | CPU balanced / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00588 | P1 | M2 | ai-audit | CPU balanced / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00589 | P1 | M2 | ai-audit | CPU balanced / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00596 | P1 | M2 | ai-audit | CPU balanced / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00597 | P1 | M2 | ai-audit | CPU balanced / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00604 | P1 | M2 | ai-audit | CPU balanced / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00605 | P1 | M2 | ai-audit | CPU balanced / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00612 | P1 | M2 | ai-audit | CPU balanced / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00613 | P1 | M2 | ai-audit | CPU balanced / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00620 | P1 | M2 | ai-audit | CPU risk_taker / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00621 | P1 | M2 | ai-audit | CPU risk_taker / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00628 | P1 | M2 | ai-audit | CPU risk_taker / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00629 | P1 | M2 | ai-audit | CPU risk_taker / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00636 | P1 | M2 | ai-audit | CPU risk_taker / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00637 | P1 | M2 | ai-audit | CPU risk_taker / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00644 | P1 | M2 | ai-audit | CPU risk_taker / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00645 | P1 | M2 | ai-audit | CPU risk_taker / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00652 | P1 | M2 | ai-audit | CPU risk_taker / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00653 | P1 | M2 | ai-audit | CPU risk_taker / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00660 | P1 | M2 | ai-audit | CPU risk_taker / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00661 | P1 | M2 | ai-audit | CPU risk_taker / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00668 | P1 | M2 | ai-audit | CPU risk_taker / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00669 | P1 | M2 | ai-audit | CPU risk_taker / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00676 | P1 | M2 | ai-audit | CPU risk_taker / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00677 | P1 | M2 | ai-audit | CPU risk_taker / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00684 | P1 | M2 | ai-audit | CPU risk_taker / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00685 | P1 | M2 | ai-audit | CPU risk_taker / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00692 | P1 | M2 | ai-audit | CPU risk_taker / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00693 | P1 | M2 | ai-audit | CPU risk_taker / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00700 | P1 | M2 | ai-audit | CPU risk_taker / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00701 | P1 | M2 | ai-audit | CPU risk_taker / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00708 | P1 | M2 | ai-audit | CPU risk_taker / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00709 | P1 | M2 | ai-audit | CPU risk_taker / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00716 | P1 | M2 | ai-audit | CPU rescuer / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00717 | P1 | M2 | ai-audit | CPU rescuer / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00724 | P1 | M2 | ai-audit | CPU rescuer / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00725 | P1 | M2 | ai-audit | CPU rescuer / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00732 | P1 | M2 | ai-audit | CPU rescuer / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00733 | P1 | M2 | ai-audit | CPU rescuer / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00740 | P1 | M2 | ai-audit | CPU rescuer / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00741 | P1 | M2 | ai-audit | CPU rescuer / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00748 | P1 | M2 | ai-audit | CPU rescuer / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00749 | P1 | M2 | ai-audit | CPU rescuer / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00756 | P1 | M2 | ai-audit | CPU rescuer / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00757 | P1 | M2 | ai-audit | CPU rescuer / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00764 | P1 | M2 | ai-audit | CPU rescuer / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00765 | P1 | M2 | ai-audit | CPU rescuer / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00772 | P1 | M2 | ai-audit | CPU rescuer / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00773 | P1 | M2 | ai-audit | CPU rescuer / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00780 | P1 | M2 | ai-audit | CPU rescuer / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00781 | P1 | M2 | ai-audit | CPU rescuer / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00788 | P1 | M2 | ai-audit | CPU rescuer / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00789 | P1 | M2 | ai-audit | CPU rescuer / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00796 | P1 | M2 | ai-audit | CPU rescuer / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00797 | P1 | M2 | ai-audit | CPU rescuer / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00804 | P1 | M2 | ai-audit | CPU rescuer / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00805 | P1 | M2 | ai-audit | CPU rescuer / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00812 | P1 | M2 | ai-audit | CPU greedy / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00813 | P1 | M2 | ai-audit | CPU greedy / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00820 | P1 | M2 | ai-audit | CPU greedy / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00821 | P1 | M2 | ai-audit | CPU greedy / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00828 | P1 | M2 | ai-audit | CPU greedy / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00829 | P1 | M2 | ai-audit | CPU greedy / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00836 | P1 | M2 | ai-audit | CPU greedy / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00837 | P1 | M2 | ai-audit | CPU greedy / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00844 | P1 | M2 | ai-audit | CPU greedy / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00845 | P1 | M2 | ai-audit | CPU greedy / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00852 | P1 | M2 | ai-audit | CPU greedy / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00853 | P1 | M2 | ai-audit | CPU greedy / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00860 | P1 | M2 | ai-audit | CPU greedy / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00861 | P1 | M2 | ai-audit | CPU greedy / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00868 | P1 | M2 | ai-audit | CPU greedy / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00869 | P1 | M2 | ai-audit | CPU greedy / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00876 | P1 | M2 | ai-audit | CPU greedy / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00877 | P1 | M2 | ai-audit | CPU greedy / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00884 | P1 | M2 | ai-audit | CPU greedy / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00885 | P1 | M2 | ai-audit | CPU greedy / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00892 | P1 | M2 | ai-audit | CPU greedy / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00893 | P1 | M2 | ai-audit | CPU greedy / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00900 | P1 | M2 | ai-audit | CPU greedy / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00901 | P1 | M2 | ai-audit | CPU greedy / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00908 | P1 | M2 | ai-audit | CPU patient / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00909 | P1 | M2 | ai-audit | CPU patient / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00916 | P1 | M2 | ai-audit | CPU patient / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00917 | P1 | M2 | ai-audit | CPU patient / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00924 | P1 | M2 | ai-audit | CPU patient / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00925 | P1 | M2 | ai-audit | CPU patient / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00932 | P1 | M2 | ai-audit | CPU patient / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00933 | P1 | M2 | ai-audit | CPU patient / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00940 | P1 | M2 | ai-audit | CPU patient / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00941 | P1 | M2 | ai-audit | CPU patient / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00948 | P1 | M2 | ai-audit | CPU patient / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00949 | P1 | M2 | ai-audit | CPU patient / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00956 | P1 | M2 | ai-audit | CPU patient / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00957 | P1 | M2 | ai-audit | CPU patient / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00964 | P1 | M2 | ai-audit | CPU patient / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00965 | P1 | M2 | ai-audit | CPU patient / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00972 | P1 | M2 | ai-audit | CPU patient / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00973 | P1 | M2 | ai-audit | CPU patient / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00980 | P1 | M2 | ai-audit | CPU patient / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00981 | P1 | M2 | ai-audit | CPU patient / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00988 | P1 | M2 | ai-audit | CPU patient / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00989 | P1 | M2 | ai-audit | CPU patient / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00996 | P1 | M2 | ai-audit | CPU patient / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-00997 | P1 | M2 | ai-audit | CPU patient / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01004 | P1 | M2 | ai-audit | CPU showman / single_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01005 | P1 | M2 | ai-audit | CPU showman / single_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01012 | P1 | M2 | ai-audit | CPU showman / two_equal_threats / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01013 | P1 | M2 | ai-audit | CPU showman / two_equal_threats / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01020 | P1 | M2 | ai-audit | CPU showman / hidden_threat / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01021 | P1 | M2 | ai-audit | CPU showman / hidden_threat / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01028 | P1 | M2 | ai-audit | CPU showman / stale_memory / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01029 | P1 | M2 | ai-audit | CPU showman / stale_memory / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01036 | P1 | M2 | ai-audit | CPU showman / conflicting_ping / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01037 | P1 | M2 | ai-audit | CPU showman / conflicting_ping / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01044 | P1 | M2 | ai-audit | CPU showman / own_core_danger / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01045 | P1 | M2 | ai-audit | CPU showman / own_core_danger / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01052 | P1 | M2 | ai-audit | CPU showman / ally_down / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01053 | P1 | M2 | ai-audit | CPU showman / ally_down / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01060 | P1 | M2 | ai-audit | CPU showman / resource_low / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01061 | P1 | M2 | ai-audit | CPU showman / resource_low / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01068 | P1 | M2 | ai-audit | CPU showman / path_blocked / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01069 | P1 | M2 | ai-audit | CPU showman / path_blocked / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01076 | P1 | M2 | ai-audit | CPU showman / target_vanishes / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01077 | P1 | M2 | ai-audit | CPU showman / target_vanishes / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01084 | P1 | M2 | ai-audit | CPU showman / simultaneous_events / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01085 | P1 | M2 | ai-audit | CPU showman / simultaneous_events / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01092 | P1 | M2 | ai-audit | CPU showman / high_pressure / seed 0 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-COM-01093 | P1 | M2 | ai-audit | CPU showman / high_pressure / seed 1 | 선택 행동이 공개 정보·성격·유틸리티 상위 후보로 설명되며 숨은 정보 참조가 없다 |
| VD-GD-0040 | P1 | M2 | export | GL Compatibility 실행 | 셰이더 없이 회색상자 60 physics FPS |
| VD-GD-0041 | P1 | M2 | accessibility | 화면 흔들림 0 옵션 | Camera2D 위치 흔들림 0, 판정 동일 |
| VD-GD-0042 | P1 | M2 | accessibility | 색상 외 구분 | 아이콘·형태·번호로 소유자와 위험 식별 |
| VD-GD-0044 | P1 | M2 | telemetry | 개인정보 없는 로그 | 시드·행동·지표만 포함, OS 사용자명·경로·IP 없음 |
| VD-GD-0047 | P1 | M2 | package | 체크리스트 ID 유일 | 중복 ID 0건, 필수 열 누락 0건 |
| VD-GD-0048 | P1 | M2 | package | P0/P1 게이트 | 미완료 1건이라도 릴리스 실패 |
| VD-COM-01100 | P1 | M3 | pooling | projectile 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01106 | P1 | M3 | pooling | projectile 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01107 | P1 | M3 | pooling | damage_number 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01113 | P1 | M3 | pooling | damage_number 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01114 | P1 | M3 | pooling | health_bar 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01120 | P1 | M3 | pooling | health_bar 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01121 | P1 | M3 | pooling | warning 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01127 | P1 | M3 | pooling | warning 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01128 | P1 | M3 | pooling | boulder 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01134 | P1 | M3 | pooling | boulder 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01135 | P1 | M3 | pooling | wall 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01141 | P1 | M3 | pooling | wall 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01142 | P1 | M3 | pooling | enemy 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01148 | P1 | M3 | pooling | enemy 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01149 | P1 | M3 | pooling | shipment 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01155 | P1 | M3 | pooling | shipment 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01156 | P1 | M3 | pooling | summon 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01162 | P1 | M3 | pooling | summon 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01163 | P1 | M3 | pooling | corpse_flag 풀 생성/회수 1개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-01169 | P1 | M3 | pooling | corpse_flag 풀 생성/회수 1000개 | 활성 수와 뷰 수가 일치하고 2회차부터 신규 할당이 기준의 5% 이하 |
| VD-COM-00015 | P1 | M4 | ux | 실패 후 재시작 | 2.5초 이내 새 판에서 조작 가능 |
| VD-COM-00016 | P1 | M4 | audio | 경고 중복 제한 | 80ms 창에서 같은 큐가 최대 1회 재생 |
| VD-COM-00018 | P1 | M4 | accessibility | 색 외 구분 | 형태·아이콘만으로 핵심 상태를 구분 가능 |
| VD-02217 | P1 | VD-M2 | upgrade | attack Lv0 / 사망0 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02218 | P1 | VD-M2 | upgrade | attack Lv0 / 사망0 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02219 | P1 | VD-M2 | upgrade | attack Lv0 / 사망0 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02220 | P1 | VD-M2 | upgrade | attack Lv0 / 사망1 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02221 | P1 | VD-M2 | upgrade | attack Lv0 / 사망1 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02222 | P1 | VD-M2 | upgrade | attack Lv0 / 사망1 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02223 | P1 | VD-M2 | upgrade | attack Lv0 / 사망3 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02224 | P1 | VD-M2 | upgrade | attack Lv0 / 사망3 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02225 | P1 | VD-M2 | upgrade | attack Lv0 / 사망3 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02271 | P1 | VD-M2 | upgrade | attack Lv180 / 사망0 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02272 | P1 | VD-M2 | upgrade | attack Lv180 / 사망0 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02273 | P1 | VD-M2 | upgrade | attack Lv180 / 사망0 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02274 | P1 | VD-M2 | upgrade | attack Lv180 / 사망1 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02275 | P1 | VD-M2 | upgrade | attack Lv180 / 사망1 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02276 | P1 | VD-M2 | upgrade | attack Lv180 / 사망1 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02277 | P1 | VD-M2 | upgrade | attack Lv180 / 사망3 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02278 | P1 | VD-M2 | upgrade | attack Lv180 / 사망3 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02279 | P1 | VD-M2 | upgrade | attack Lv180 / 사망3 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02298 | P1 | VD-M2 | upgrade | attack Lv255 / 사망0 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02299 | P1 | VD-M2 | upgrade | attack Lv255 / 사망0 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02300 | P1 | VD-M2 | upgrade | attack Lv255 / 사망0 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02301 | P1 | VD-M2 | upgrade | attack Lv255 / 사망1 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02302 | P1 | VD-M2 | upgrade | attack Lv255 / 사망1 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02303 | P1 | VD-M2 | upgrade | attack Lv255 / 사망1 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02304 | P1 | VD-M2 | upgrade | attack Lv255 / 사망3 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02305 | P1 | VD-M2 | upgrade | attack Lv255 / 사망3 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02306 | P1 | VD-M2 | upgrade | attack Lv255 / 사망3 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02307 | P1 | VD-M2 | upgrade | defense Lv0 / 사망0 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02308 | P1 | VD-M2 | upgrade | defense Lv0 / 사망0 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02309 | P1 | VD-M2 | upgrade | defense Lv0 / 사망0 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02310 | P1 | VD-M2 | upgrade | defense Lv0 / 사망1 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02311 | P1 | VD-M2 | upgrade | defense Lv0 / 사망1 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02312 | P1 | VD-M2 | upgrade | defense Lv0 / 사망1 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02313 | P1 | VD-M2 | upgrade | defense Lv0 / 사망3 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02314 | P1 | VD-M2 | upgrade | defense Lv0 / 사망3 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02315 | P1 | VD-M2 | upgrade | defense Lv0 / 사망3 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02361 | P1 | VD-M2 | upgrade | defense Lv180 / 사망0 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02362 | P1 | VD-M2 | upgrade | defense Lv180 / 사망0 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02363 | P1 | VD-M2 | upgrade | defense Lv180 / 사망0 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02364 | P1 | VD-M2 | upgrade | defense Lv180 / 사망1 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02365 | P1 | VD-M2 | upgrade | defense Lv180 / 사망1 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02366 | P1 | VD-M2 | upgrade | defense Lv180 / 사망1 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02367 | P1 | VD-M2 | upgrade | defense Lv180 / 사망3 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02368 | P1 | VD-M2 | upgrade | defense Lv180 / 사망3 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02369 | P1 | VD-M2 | upgrade | defense Lv180 / 사망3 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02388 | P1 | VD-M2 | upgrade | defense Lv255 / 사망0 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02389 | P1 | VD-M2 | upgrade | defense Lv255 / 사망0 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02390 | P1 | VD-M2 | upgrade | defense Lv255 / 사망0 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02391 | P1 | VD-M2 | upgrade | defense Lv255 / 사망1 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02392 | P1 | VD-M2 | upgrade | defense Lv255 / 사망1 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02393 | P1 | VD-M2 | upgrade | defense Lv255 / 사망1 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02394 | P1 | VD-M2 | upgrade | defense Lv255 / 사망3 / 구매1 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02395 | P1 | VD-M2 | upgrade | defense Lv255 / 사망3 / 구매10 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-02396 | P1 | VD-M2 | upgrade | defense Lv255 / 사망3 / 구매999 | 비용식·상한·일괄 구매가 정확하고 점수 음수·레벨 255 초과가 없다 |
| VD-00297 | P1 | VD-M4 | wave-sim | W1 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00298 | P1 | VD-M4 | wave-sim | W1 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00299 | P1 | VD-M4 | wave-sim | W1 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00317 | P1 | VD-M4 | wave-sim | W1 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00318 | P1 | VD-M4 | wave-sim | W1 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00319 | P1 | VD-M4 | wave-sim | W1 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00337 | P1 | VD-M4 | wave-sim | W1 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00338 | P1 | VD-M4 | wave-sim | W1 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00339 | P1 | VD-M4 | wave-sim | W1 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00357 | P1 | VD-M4 | wave-sim | W1 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00358 | P1 | VD-M4 | wave-sim | W1 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00359 | P1 | VD-M4 | wave-sim | W1 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00377 | P1 | VD-M4 | wave-sim | W1 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00378 | P1 | VD-M4 | wave-sim | W1 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00379 | P1 | VD-M4 | wave-sim | W1 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00397 | P1 | VD-M4 | wave-sim | W1 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00398 | P1 | VD-M4 | wave-sim | W1 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00399 | P1 | VD-M4 | wave-sim | W1 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00417 | P1 | VD-M4 | wave-sim | W1 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00418 | P1 | VD-M4 | wave-sim | W1 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00419 | P1 | VD-M4 | wave-sim | W1 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00437 | P1 | VD-M4 | wave-sim | W1 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00438 | P1 | VD-M4 | wave-sim | W1 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00439 | P1 | VD-M4 | wave-sim | W1 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00457 | P1 | VD-M4 | wave-sim | W2 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00458 | P1 | VD-M4 | wave-sim | W2 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00459 | P1 | VD-M4 | wave-sim | W2 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00477 | P1 | VD-M4 | wave-sim | W2 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00478 | P1 | VD-M4 | wave-sim | W2 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00479 | P1 | VD-M4 | wave-sim | W2 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00497 | P1 | VD-M4 | wave-sim | W2 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00498 | P1 | VD-M4 | wave-sim | W2 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00499 | P1 | VD-M4 | wave-sim | W2 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00517 | P1 | VD-M4 | wave-sim | W2 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00518 | P1 | VD-M4 | wave-sim | W2 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00519 | P1 | VD-M4 | wave-sim | W2 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00537 | P1 | VD-M4 | wave-sim | W2 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00538 | P1 | VD-M4 | wave-sim | W2 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00539 | P1 | VD-M4 | wave-sim | W2 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00557 | P1 | VD-M4 | wave-sim | W2 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00558 | P1 | VD-M4 | wave-sim | W2 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00559 | P1 | VD-M4 | wave-sim | W2 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00577 | P1 | VD-M4 | wave-sim | W2 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00578 | P1 | VD-M4 | wave-sim | W2 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00579 | P1 | VD-M4 | wave-sim | W2 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00597 | P1 | VD-M4 | wave-sim | W2 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00598 | P1 | VD-M4 | wave-sim | W2 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00599 | P1 | VD-M4 | wave-sim | W2 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00617 | P1 | VD-M4 | wave-sim | W3 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00618 | P1 | VD-M4 | wave-sim | W3 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00619 | P1 | VD-M4 | wave-sim | W3 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00637 | P1 | VD-M4 | wave-sim | W3 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00638 | P1 | VD-M4 | wave-sim | W3 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00639 | P1 | VD-M4 | wave-sim | W3 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00657 | P1 | VD-M4 | wave-sim | W3 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00658 | P1 | VD-M4 | wave-sim | W3 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00659 | P1 | VD-M4 | wave-sim | W3 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00677 | P1 | VD-M4 | wave-sim | W3 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00678 | P1 | VD-M4 | wave-sim | W3 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00679 | P1 | VD-M4 | wave-sim | W3 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00697 | P1 | VD-M4 | wave-sim | W3 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00698 | P1 | VD-M4 | wave-sim | W3 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00699 | P1 | VD-M4 | wave-sim | W3 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00717 | P1 | VD-M4 | wave-sim | W3 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00718 | P1 | VD-M4 | wave-sim | W3 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00719 | P1 | VD-M4 | wave-sim | W3 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00737 | P1 | VD-M4 | wave-sim | W3 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00738 | P1 | VD-M4 | wave-sim | W3 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00739 | P1 | VD-M4 | wave-sim | W3 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00757 | P1 | VD-M4 | wave-sim | W3 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00758 | P1 | VD-M4 | wave-sim | W3 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00759 | P1 | VD-M4 | wave-sim | W3 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00777 | P1 | VD-M4 | wave-sim | W4 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00778 | P1 | VD-M4 | wave-sim | W4 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00779 | P1 | VD-M4 | wave-sim | W4 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00797 | P1 | VD-M4 | wave-sim | W4 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00798 | P1 | VD-M4 | wave-sim | W4 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00799 | P1 | VD-M4 | wave-sim | W4 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00817 | P1 | VD-M4 | wave-sim | W4 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00818 | P1 | VD-M4 | wave-sim | W4 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00819 | P1 | VD-M4 | wave-sim | W4 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00837 | P1 | VD-M4 | wave-sim | W4 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00838 | P1 | VD-M4 | wave-sim | W4 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00839 | P1 | VD-M4 | wave-sim | W4 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00857 | P1 | VD-M4 | wave-sim | W4 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00858 | P1 | VD-M4 | wave-sim | W4 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00859 | P1 | VD-M4 | wave-sim | W4 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00877 | P1 | VD-M4 | wave-sim | W4 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00878 | P1 | VD-M4 | wave-sim | W4 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00879 | P1 | VD-M4 | wave-sim | W4 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00897 | P1 | VD-M4 | wave-sim | W4 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00898 | P1 | VD-M4 | wave-sim | W4 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00899 | P1 | VD-M4 | wave-sim | W4 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00917 | P1 | VD-M4 | wave-sim | W4 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00918 | P1 | VD-M4 | wave-sim | W4 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00919 | P1 | VD-M4 | wave-sim | W4 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00937 | P1 | VD-M4 | wave-sim | W5 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00938 | P1 | VD-M4 | wave-sim | W5 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00939 | P1 | VD-M4 | wave-sim | W5 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00957 | P1 | VD-M4 | wave-sim | W5 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00958 | P1 | VD-M4 | wave-sim | W5 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00959 | P1 | VD-M4 | wave-sim | W5 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00977 | P1 | VD-M4 | wave-sim | W5 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00978 | P1 | VD-M4 | wave-sim | W5 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00979 | P1 | VD-M4 | wave-sim | W5 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00997 | P1 | VD-M4 | wave-sim | W5 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00998 | P1 | VD-M4 | wave-sim | W5 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-00999 | P1 | VD-M4 | wave-sim | W5 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01017 | P1 | VD-M4 | wave-sim | W5 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01018 | P1 | VD-M4 | wave-sim | W5 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01019 | P1 | VD-M4 | wave-sim | W5 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01037 | P1 | VD-M4 | wave-sim | W5 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01038 | P1 | VD-M4 | wave-sim | W5 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01039 | P1 | VD-M4 | wave-sim | W5 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01057 | P1 | VD-M4 | wave-sim | W5 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01058 | P1 | VD-M4 | wave-sim | W5 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01059 | P1 | VD-M4 | wave-sim | W5 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01077 | P1 | VD-M4 | wave-sim | W5 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01078 | P1 | VD-M4 | wave-sim | W5 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01079 | P1 | VD-M4 | wave-sim | W5 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01097 | P1 | VD-M4 | wave-sim | W6 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01098 | P1 | VD-M4 | wave-sim | W6 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01099 | P1 | VD-M4 | wave-sim | W6 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01117 | P1 | VD-M4 | wave-sim | W6 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01118 | P1 | VD-M4 | wave-sim | W6 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01119 | P1 | VD-M4 | wave-sim | W6 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01137 | P1 | VD-M4 | wave-sim | W6 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01138 | P1 | VD-M4 | wave-sim | W6 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01139 | P1 | VD-M4 | wave-sim | W6 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01157 | P1 | VD-M4 | wave-sim | W6 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01158 | P1 | VD-M4 | wave-sim | W6 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01159 | P1 | VD-M4 | wave-sim | W6 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01177 | P1 | VD-M4 | wave-sim | W6 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01178 | P1 | VD-M4 | wave-sim | W6 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01179 | P1 | VD-M4 | wave-sim | W6 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01197 | P1 | VD-M4 | wave-sim | W6 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01198 | P1 | VD-M4 | wave-sim | W6 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01199 | P1 | VD-M4 | wave-sim | W6 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01217 | P1 | VD-M4 | wave-sim | W6 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01218 | P1 | VD-M4 | wave-sim | W6 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01219 | P1 | VD-M4 | wave-sim | W6 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01237 | P1 | VD-M4 | wave-sim | W6 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01238 | P1 | VD-M4 | wave-sim | W6 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01239 | P1 | VD-M4 | wave-sim | W6 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01257 | P1 | VD-M4 | wave-sim | W7 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01258 | P1 | VD-M4 | wave-sim | W7 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01259 | P1 | VD-M4 | wave-sim | W7 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01277 | P1 | VD-M4 | wave-sim | W7 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01278 | P1 | VD-M4 | wave-sim | W7 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01279 | P1 | VD-M4 | wave-sim | W7 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01297 | P1 | VD-M4 | wave-sim | W7 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01298 | P1 | VD-M4 | wave-sim | W7 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01299 | P1 | VD-M4 | wave-sim | W7 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01317 | P1 | VD-M4 | wave-sim | W7 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01318 | P1 | VD-M4 | wave-sim | W7 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01319 | P1 | VD-M4 | wave-sim | W7 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01337 | P1 | VD-M4 | wave-sim | W7 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01338 | P1 | VD-M4 | wave-sim | W7 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01339 | P1 | VD-M4 | wave-sim | W7 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01357 | P1 | VD-M4 | wave-sim | W7 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01358 | P1 | VD-M4 | wave-sim | W7 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01359 | P1 | VD-M4 | wave-sim | W7 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01377 | P1 | VD-M4 | wave-sim | W7 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01378 | P1 | VD-M4 | wave-sim | W7 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01379 | P1 | VD-M4 | wave-sim | W7 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01397 | P1 | VD-M4 | wave-sim | W7 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01398 | P1 | VD-M4 | wave-sim | W7 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01399 | P1 | VD-M4 | wave-sim | W7 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01417 | P1 | VD-M4 | wave-sim | W8 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01418 | P1 | VD-M4 | wave-sim | W8 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01419 | P1 | VD-M4 | wave-sim | W8 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01437 | P1 | VD-M4 | wave-sim | W8 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01438 | P1 | VD-M4 | wave-sim | W8 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01439 | P1 | VD-M4 | wave-sim | W8 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01457 | P1 | VD-M4 | wave-sim | W8 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01458 | P1 | VD-M4 | wave-sim | W8 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01459 | P1 | VD-M4 | wave-sim | W8 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01477 | P1 | VD-M4 | wave-sim | W8 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01478 | P1 | VD-M4 | wave-sim | W8 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01479 | P1 | VD-M4 | wave-sim | W8 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01497 | P1 | VD-M4 | wave-sim | W8 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01498 | P1 | VD-M4 | wave-sim | W8 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01499 | P1 | VD-M4 | wave-sim | W8 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01517 | P1 | VD-M4 | wave-sim | W8 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01518 | P1 | VD-M4 | wave-sim | W8 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01519 | P1 | VD-M4 | wave-sim | W8 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01537 | P1 | VD-M4 | wave-sim | W8 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01538 | P1 | VD-M4 | wave-sim | W8 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01539 | P1 | VD-M4 | wave-sim | W8 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01557 | P1 | VD-M4 | wave-sim | W8 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01558 | P1 | VD-M4 | wave-sim | W8 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01559 | P1 | VD-M4 | wave-sim | W8 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01577 | P1 | VD-M4 | wave-sim | W9 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01578 | P1 | VD-M4 | wave-sim | W9 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01579 | P1 | VD-M4 | wave-sim | W9 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01597 | P1 | VD-M4 | wave-sim | W9 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01598 | P1 | VD-M4 | wave-sim | W9 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01599 | P1 | VD-M4 | wave-sim | W9 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01617 | P1 | VD-M4 | wave-sim | W9 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01618 | P1 | VD-M4 | wave-sim | W9 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01619 | P1 | VD-M4 | wave-sim | W9 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01637 | P1 | VD-M4 | wave-sim | W9 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01638 | P1 | VD-M4 | wave-sim | W9 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01639 | P1 | VD-M4 | wave-sim | W9 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01657 | P1 | VD-M4 | wave-sim | W9 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01658 | P1 | VD-M4 | wave-sim | W9 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01659 | P1 | VD-M4 | wave-sim | W9 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01677 | P1 | VD-M4 | wave-sim | W9 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01678 | P1 | VD-M4 | wave-sim | W9 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01679 | P1 | VD-M4 | wave-sim | W9 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01697 | P1 | VD-M4 | wave-sim | W9 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01698 | P1 | VD-M4 | wave-sim | W9 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01699 | P1 | VD-M4 | wave-sim | W9 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01717 | P1 | VD-M4 | wave-sim | W9 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01718 | P1 | VD-M4 | wave-sim | W9 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01719 | P1 | VD-M4 | wave-sim | W9 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01737 | P1 | VD-M4 | wave-sim | W10 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01738 | P1 | VD-M4 | wave-sim | W10 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01739 | P1 | VD-M4 | wave-sim | W10 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01757 | P1 | VD-M4 | wave-sim | W10 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01758 | P1 | VD-M4 | wave-sim | W10 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01759 | P1 | VD-M4 | wave-sim | W10 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01777 | P1 | VD-M4 | wave-sim | W10 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01778 | P1 | VD-M4 | wave-sim | W10 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01779 | P1 | VD-M4 | wave-sim | W10 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01797 | P1 | VD-M4 | wave-sim | W10 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01798 | P1 | VD-M4 | wave-sim | W10 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01799 | P1 | VD-M4 | wave-sim | W10 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01817 | P1 | VD-M4 | wave-sim | W10 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01818 | P1 | VD-M4 | wave-sim | W10 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01819 | P1 | VD-M4 | wave-sim | W10 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01837 | P1 | VD-M4 | wave-sim | W10 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01838 | P1 | VD-M4 | wave-sim | W10 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01839 | P1 | VD-M4 | wave-sim | W10 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01857 | P1 | VD-M4 | wave-sim | W10 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01858 | P1 | VD-M4 | wave-sim | W10 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01859 | P1 | VD-M4 | wave-sim | W10 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01877 | P1 | VD-M4 | wave-sim | W10 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01878 | P1 | VD-M4 | wave-sim | W10 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01879 | P1 | VD-M4 | wave-sim | W10 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01897 | P1 | VD-M4 | wave-sim | W11 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01898 | P1 | VD-M4 | wave-sim | W11 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01899 | P1 | VD-M4 | wave-sim | W11 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01917 | P1 | VD-M4 | wave-sim | W11 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01918 | P1 | VD-M4 | wave-sim | W11 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01919 | P1 | VD-M4 | wave-sim | W11 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01937 | P1 | VD-M4 | wave-sim | W11 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01938 | P1 | VD-M4 | wave-sim | W11 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01939 | P1 | VD-M4 | wave-sim | W11 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01957 | P1 | VD-M4 | wave-sim | W11 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01958 | P1 | VD-M4 | wave-sim | W11 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01959 | P1 | VD-M4 | wave-sim | W11 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01977 | P1 | VD-M4 | wave-sim | W11 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01978 | P1 | VD-M4 | wave-sim | W11 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01979 | P1 | VD-M4 | wave-sim | W11 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01997 | P1 | VD-M4 | wave-sim | W11 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01998 | P1 | VD-M4 | wave-sim | W11 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-01999 | P1 | VD-M4 | wave-sim | W11 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02017 | P1 | VD-M4 | wave-sim | W11 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02018 | P1 | VD-M4 | wave-sim | W11 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02019 | P1 | VD-M4 | wave-sim | W11 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02037 | P1 | VD-M4 | wave-sim | W11 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02038 | P1 | VD-M4 | wave-sim | W11 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02039 | P1 | VD-M4 | wave-sim | W11 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02057 | P1 | VD-M4 | wave-sim | W12 balanced seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02058 | P1 | VD-M4 | wave-sim | W12 balanced seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02059 | P1 | VD-M4 | wave-sim | W12 balanced seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02077 | P1 | VD-M4 | wave-sim | W12 north_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02078 | P1 | VD-M4 | wave-sim | W12 north_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02079 | P1 | VD-M4 | wave-sim | W12 north_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02097 | P1 | VD-M4 | wave-sim | W12 south_heavy seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02098 | P1 | VD-M4 | wave-sim | W12 south_heavy seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02099 | P1 | VD-M4 | wave-sim | W12 south_heavy seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02117 | P1 | VD-M4 | wave-sim | W12 one_gate_down seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02118 | P1 | VD-M4 | wave-sim | W12 one_gate_down seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02119 | P1 | VD-M4 | wave-sim | W12 one_gate_down seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02137 | P1 | VD-M4 | wave-sim | W12 two_gates_low seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02138 | P1 | VD-M4 | wave-sim | W12 two_gates_low seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02139 | P1 | VD-M4 | wave-sim | W12 two_gates_low seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02157 | P1 | VD-M4 | wave-sim | W12 chief_exposed seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02158 | P1 | VD-M4 | wave-sim | W12 chief_exposed seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02159 | P1 | VD-M4 | wave-sim | W12 chief_exposed seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02177 | P1 | VD-M4 | wave-sim | W12 militia_high_kill seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02178 | P1 | VD-M4 | wave-sim | W12 militia_high_kill seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02179 | P1 | VD-M4 | wave-sim | W12 militia_high_kill seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02197 | P1 | VD-M4 | wave-sim | W12 all_players_one_lane seed 0 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02198 | P1 | VD-M4 | wave-sim | W12 all_players_one_lane seed 1 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02199 | P1 | VD-M4 | wave-sim | W12 all_players_one_lane seed 2 | 웨이브 종료·패배가 결정되고 스폰 누락, 적 고립, 영구 무적, 성문 상태 오류가 없다 |
| VD-02398 | P1 | VD-M4 | performance | 적 100 / open_lane / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02399 | P1 | VD-M4 | performance | 적 100 / open_lane / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02401 | P1 | VD-M4 | performance | 적 100 / four_lanes / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02402 | P1 | VD-M4 | performance | 적 100 / four_lanes / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02404 | P1 | VD-M4 | performance | 적 100 / gate_rebuild / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02405 | P1 | VD-M4 | performance | 적 100 / gate_rebuild / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02407 | P1 | VD-M4 | performance | 적 100 / barricades / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02408 | P1 | VD-M4 | performance | 적 100 / barricades / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02410 | P1 | VD-M4 | performance | 적 100 / boss_plus_mobs / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02411 | P1 | VD-M4 | performance | 적 100 / boss_plus_mobs / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02413 | P1 | VD-M4 | performance | 적 100 / mass_death / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02414 | P1 | VD-M4 | performance | 적 100 / mass_death / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02470 | P1 | VD-M4 | performance | 적 1200 / open_lane / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02471 | P1 | VD-M4 | performance | 적 1200 / open_lane / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02473 | P1 | VD-M4 | performance | 적 1200 / four_lanes / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02474 | P1 | VD-M4 | performance | 적 1200 / four_lanes / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02476 | P1 | VD-M4 | performance | 적 1200 / gate_rebuild / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02477 | P1 | VD-M4 | performance | 적 1200 / gate_rebuild / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02479 | P1 | VD-M4 | performance | 적 1200 / barricades / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02480 | P1 | VD-M4 | performance | 적 1200 / barricades / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02482 | P1 | VD-M4 | performance | 적 1200 / boss_plus_mobs / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02483 | P1 | VD-M4 | performance | 적 1200 / boss_plus_mobs / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02485 | P1 | VD-M4 | performance | 적 1200 / mass_death / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02486 | P1 | VD-M4 | performance | 적 1200 / mass_death / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02488 | P1 | VD-M4 | performance | 적 1600 / open_lane / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02489 | P1 | VD-M4 | performance | 적 1600 / open_lane / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02491 | P1 | VD-M4 | performance | 적 1600 / four_lanes / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02492 | P1 | VD-M4 | performance | 적 1600 / four_lanes / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02494 | P1 | VD-M4 | performance | 적 1600 / gate_rebuild / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02495 | P1 | VD-M4 | performance | 적 1600 / gate_rebuild / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02497 | P1 | VD-M4 | performance | 적 1600 / barricades / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02498 | P1 | VD-M4 | performance | 적 1600 / barricades / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02500 | P1 | VD-M4 | performance | 적 1600 / boss_plus_mobs / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02501 | P1 | VD-M4 | performance | 적 1600 / boss_plus_mobs / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02503 | P1 | VD-M4 | performance | 적 1600 / mass_death / 60s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
| VD-02504 | P1 | VD-M4 | performance | 적 1600 / mass_death / 300s | 정의된 엔티티 한도와 메모리 예산 안이며 입력 지연이 2틱을 넘지 않는다 |
