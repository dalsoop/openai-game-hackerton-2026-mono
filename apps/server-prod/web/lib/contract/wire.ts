import { CloseCode } from "@colyseus/sdk";

// React ↔ Godot 핸드오프·인게임 수송 계약의 정본.
// Godot 거울: project/core/contract/web_contract.gd
// 대조 게이트: web/scripts/check-contract.mjs (어긋나면 빌드 실패)

export const HANDOFF = {
  FROM_HUB: "gangup_from_hub",
  GAME: "gangup_game",
  NAME: "gangup_name",
  ROOM_ID: "gangup_room_id",
  SLOT: "gangup_you",
  RESUME: "gangup_resume",
  MATCH: "gangup_match",
} as const;

export const WEB_STORE = {
  MY_ROOM: "gangup_my_room",
  NICKNAME: "gangup_nickname",
} as const;

export const DOM_EVT = {
  MATCH_START: "godot-match-start",
  MATCH_END: "godot-match-end",
  TO_ENGINE: "gangup-to-engine",
  FROM_ENGINE: "gangup-from-engine",
} as const;

export const MSG = {
  START: "start",
  INPUT: "input",
  HOST_SNAP: "host_snap",
  SNAP: "snap",
  PEER_INPUT: "peer_input",
  GUN_FIRE: "gun_fire",
  ERROR: "error",
  ROOM_TOGGLE: "room_toggle",
  SET_GAME: "set_game",
  PACK_PCT: "pack_pct",
  KICKED: "kicked",
  STATE: "state",
  LEAVE: "leave",
  PING: "ping",
  PONG: "pong",
} as const;

export const CLOSE_CODE = {
  CONSENTED: CloseCode.CONSENTED,
  KICKED: CloseCode.CONSENTED,
} as const;

export const ROOM_LEAVE = {
  CONSENTED: true,
  HANDOFF: false,
} as const;
