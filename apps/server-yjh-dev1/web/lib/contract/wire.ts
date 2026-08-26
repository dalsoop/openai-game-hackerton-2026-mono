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
  /** React → Godot 인게임 수송. 허브 소켓은 React 만 연다. */
  TO_ENGINE: "gangup-to-engine",
  /** Godot → React. 엔진은 matchmake/reconnect 를 치지 않는다. */
  FROM_ENGINE: "gangup-from-engine",
} as const;

export const MSG = {
  START: "start",
  INPUT: "input",
  HOST_SNAP: "host_snap",
  SNAP: "snap",
  PEER_INPUT: "peer_input",
  ERROR: "error",
  ROOM_TOGGLE: "room_toggle",
  /** 방장만. 대기실에서 유즈맵을 바꾼다. */
  SET_GAME: "set_game",
  /** 자기 좌석의 대기실 팩 진행률 0..100. Godot 수송이 아니다. */
  PACK_PCT: "pack_pct",
  KICKED: "kicked",
  /** React → Godot 방 state. 허브 메시지 타입이 아니다. */
  STATE: "state",
  /** Godot → React 퇴장 요청. 허브 메시지 타입이 아니다. */
  LEAVE: "leave",
  /** 방 소켓 RTT. 클라가 t 를 보내면 서버가 그대로 돌려준다. */
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
