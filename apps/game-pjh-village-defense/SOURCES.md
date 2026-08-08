# 신 마을 지키기 — 조사 근거와 기술 기준

이 문서는 원본 룰에서 확인한 사실과, 실제 독립 게임으로 재현하기 위해 새로 고정한 값을 구분한다. 이 패키지는 스타크래프트 맵·그래픽·사운드·상표 자산을 포함하지 않는다.

## 원본 룰 확인
- 여우아조씨TV 맵 정보: https://kkmg2012.tistory.com/1368
- GEMLOG 맵 정보: https://gemlog.tistory.com/335
- 알론소의 백과사전 맵 소개: https://presentlife.tistory.com/entry/%EC%8A%A4%ED%83%801-%EC%9C%A0%EC%A6%88%EB%A7%B5-EUD-%EC%8B%A0-%EB%A7%88%EC%9D%84%EC%A7%80%ED%82%A4%EA%B8%B0-%EC%86%8C%EA%B0%9C%EB%8B%A4%EC%9A%B4-EUD%EB%A7%88%EC%9D%84%EC%A7%80%ED%82%A4%EA%B8%B0%EC%BB%B4%EA%B9%8C%EA%B8%B0
- 확인 요소: 1~6인, 랜덤 직업, 웨이브, 킬 진화, 2000킬 패시브, 스테이시스, 막타 경쟁.
- 새로 고정한 요소: 압축 12웨이브 모드, 직업/적/보스 상세 수치, CPU 라인 이동과 막타 성향.


## Godot 기술 기준

- Godot 4.7.1 공식 다운로드: https://godotengine.org/download/
- Godot 4.7 공식 문서: https://docs.godotengine.org/en/4.7/
- 고정 프레임/물리 보간: https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/physics_interpolation_introduction.html
- 결정론 주의사항: https://docs.godotengine.org/en/4.7/tutorials/physics/large_world_coordinates.html#limitations
- 명령행·헤드리스 실행: https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html
- 커스텀 2D 드로잉: https://docs.godotengine.org/en/4.7/tutorials/2d/custom_drawing_in_2d.html

## 라이선스·출시 주의

- 원본 유즈맵의 구체적 맵 파일·그래픽·사운드를 배포물에 복사하지 않는다.
- 고유 명칭은 프로토타입 식별용이다. 상용 출시 전 독자 명칭과 시각 자산으로 교체한다.
- 룰과 수치의 출처 상태는 체크리스트의 `source_status` 열에서 `원본 확인`, `복원 추정`, `프로토타입 고정`, `Godot 고정`으로 구분한다.
