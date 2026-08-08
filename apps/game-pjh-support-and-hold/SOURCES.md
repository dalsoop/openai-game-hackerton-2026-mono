# 지원하며 버티기 — 조사 근거와 기술 기준

이 문서는 원본 룰에서 확인한 사실과, 실제 독립 게임으로 재현하기 위해 새로 고정한 값을 구분한다. 이 패키지는 스타크래프트 맵·그래픽·사운드·상표 자산을 포함하지 않는다.

## 원본 룰 확인
- SCMSCX, `지원하며 버티기`: https://scmscx.com/map/DRs7642y
- 공개 플레이 영상 「3명의 보급병과 3명의 병사들」: https://www.youtube.com/watch?v=em7BQYKGdUI
- 확인 요소: 보급 3명·전선 병사 3명, 장기 생존, 적 Hive 파괴, 여러 페이즈.
- 새로 고정한 요소: 역할 스킬·자원, 물리 배송·파괴, 3개 전선·5페이즈, 요청·ETA·연쇄 실패 로그.


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
