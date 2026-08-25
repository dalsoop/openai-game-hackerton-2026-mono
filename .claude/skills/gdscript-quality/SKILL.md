---
name: gdscript-quality
description: GDScript 코드 품질 검사. 700줄 게이트, 모듈화 규칙, 린트 실행. 트리거 — "린트 돌려", "코드 품질", "gdscript-quality".
---

# GDScript 품질 검사

GDScript 파일의 코드 품질을 검사하고 위반을 보고한다.

## 사용 시점
- GDScript 파일을 수정한 후
- PR 리뷰 시
- "린트 돌려" / "코드 품질 체크" 요청 시

## 규칙 (AGENTS.md 정본)

1. 파일 700줄 이하 — 초과 시 모듈 분리
2. 함수 40줄 이하 — 초과 시 헬퍼 추출
3. 중첩 3단 이하 — early return으로 평탄화
4. 매직 컬러 금지 — `UiTheme.상수` 사용
5. SSOT — 정본 1곳 + 위임 래퍼
6. 모듈 패턴 — RefCounted 분리 + 파사드 조합

## 실행

```bash
python3 lint_gd.py apps/server-yjh-dev1/project/scripts
```

exit 0이면 통과, exit 1이면 위반 목록이 출력된다.

700줄 초과 파일이 있으면:
1. 파일의 함수 목록을 나열
2. 기능별로 그룹핑
3. RefCounted 모듈로 분리하는 방안 제시
4. 파사드에 위임 래퍼 추가

Godot 파싱도 함께 확인:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path apps/server-yjh-dev1/project --headless --quit 2>&1 | grep 'Parse Error'
```
