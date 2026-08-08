# 등산하기 — 조사 근거와 기술 기준

이 문서는 원본 룰에서 확인한 사실과, 실제 독립 게임으로 재현하기 위해 새로 고정한 값을 구분한다. 이 패키지는 스타크래프트 맵·그래픽·사운드·상표 자산을 포함하지 않는다.

## 원본 룰 확인
- 토백 게임이야기, 「스타 유즈맵 - 등산하기」: https://tobaek.com/52
- SCMSCX, `Mount Impossible 1.7Ver`: https://scmscx.com/map/RxV4Dt3c
- 확인 요소: 정상 비콘, 낙석, 파일런, 사망 시 소유 구조물 제거, 깃발 구조, 5개 스테이지.
- 새로 고정한 요소: 정확한 속도·충돌·스테이지 좌표·CPU 의사결정·텔레메트리.


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
