class_name WebContract
extends RefCounted
## React ↔ Godot 핸드오프 계약의 GD 거울.
## 정본: web/lib/contract/wire.ts (HANDOFF / DOM_EVT / MSG)
## 기본 게임·모드: web/lib/games/catalog.ts DEFAULT_GAME_ID · defaultMode
## 대조 게이트: web/scripts/check-contract.mjs — 정본과 어긋나면 실패한다.

const KEY_FROM_HUB := "gangup_from_hub"
const KEY_GAME := "gangup_game"
const KEY_NAME := "gangup_name"
const KEY_ROOM_ID := "gangup_room_id"
const KEY_SLOT := "gangup_you"
const KEY_RESUME := "gangup_resume"
const KEY_MATCH := "gangup_match"

const MSG_START := "start"
const MSG_INPUT := "input"
const MSG_SNAP := "snap"
const MSG_GUN_FIRE := "gun_fire"
const MSG_ERROR := "error"
const MSG_SET_CHARACTER := "set_character"
const MSG_STATE := "state"
const MSG_LEAVE := "leave"

const EVT_MATCH_START := "godot-match-start"
const EVT_MATCH_END := "godot-match-end"
const EVT_TO_ENGINE := "gangup-to-engine"
const EVT_FROM_ENGINE := "gangup-from-engine"

const DEFAULT_GAME := "dagul"
const DEFAULT_MODE := "full"
