class_name WebContract
extends RefCounted
## React ↔ Godot 핸드오프 계약의 GD 거울.
## 정본: web/lib/hub/config.ts 의 HANDOFF / DOM_EVT / wsPath / HUB_CONFIG.defaultMode
## 대조 게이트: web/scripts/check-contract.mjs — 정본과 어긋나면 실패한다.
## 이 파일의 값을 바꿀 때는 반드시 정본을 먼저 바꾸고 게이트를 통과시킨다.

# localStorage 키 (React가 쓰고 Godot가 읽는다)
const KEY_FROM_HUB := "gangup_from_hub"
const KEY_GAME := "gangup_game"
const KEY_NAME := "gangup_name"
const KEY_ROOM_ID := "gangup_room_id"
const KEY_SLOT := "gangup_you"
const KEY_RESUME := "gangup_resume"
# 매치 시작 정보(START payload) — React 가 남기고 Godot 가 읽고 지운다
const KEY_MATCH := "gangup_match"

# 커스텀 메시지 타입 (web/lib/hub/config.ts MSG 와 1:1 거울 — check-contract 대조)
const MSG_START := "start"
const MSG_INPUT := "input"
const MSG_HOST_SNAP := "host_snap"
const MSG_SNAP := "snap"
const MSG_PEER_INPUT := "peer_input"
const MSG_ERROR := "error"

# DOM CustomEvent (Godot가 쏘고 React가 받는다)
const EVT_MATCH_START := "godot-match-start"
const EVT_MATCH_END := "godot-match-end"

# 기본 모드
const DEFAULT_MODE := "full"
