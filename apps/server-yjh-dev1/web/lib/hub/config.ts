export const HUB_CONFIG = {
  graceLobbyMs: 60_000,
  gracePlayMs: 180_000,
  maxPayload: 256 * 1024,
  defaultName: "손님",
  defaultMode: "full",
  gameServerUrl: process.env.GAME_SERVER_URL ?? "http://127.0.0.1:9122",
  maxNameLength: 12,
  maxTitleLength: 24,
  rateBudget: 60,
  rateRefillPerMs: 0.04,
  resetToLobbyDelayMs: 5_000,
  hostBootTimeoutMs: 180_000,
  maxPlayers: 8,
  seedMax: 999_999,
  gameServerTimeoutMs: 5_000,
} as const;

export const MSG = {
  WELCOME: "welcome", HELLO: "hello", ROOMS: "rooms", CREATE: "create",
  JOIN: "join", LEAVE: "leave", START: "start", KICK: "kick",
  INPUT: "input", HOST_SNAP: "host_snap", SNAP: "snap",
  PEER_INPUT: "peer_input", PEER_PARKED: "peer_parked", PEER_RECLAIMED: "peer_reclaimed",
  JOINED: "joined", PEERS: "peers", LEFT: "left", KICKED: "kicked",
  ROOM_TOGGLE: "room_toggle",
  LOBBY: "lobby", ERROR: "error", PING: "ping", PONG: "pong",
  DROPPED: "dropped", RESUME: "resume", MODE: "mode",
} as const;

// React ↔ Godot 핸드오프 계약의 정본.
// Godot 거울: apps/server-yjh-dev1/project/scripts/net/web_contract.gd
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

export const DOM_EVT = {
  MATCH_START: "godot-match-start",
  MATCH_END: "godot-match-end",
} as const;

// 게임 정체성의 정본은 lib/games/catalog — 여기선 하위 모듈 재수출만.
export { DEFAULT_GAME_ID, GAME_CATALOG, asGameId } from "@/lib/games/catalog";
// Colyseus 방 타입 이름 (매치메이킹 식별자)
export const ROOM_NAME = "lobby";
// 방 목록 전용 내장 LobbyRoom (공식 실시간 리스팅 — useLobbyRoom 이 구독)
export const LIST_ROOM_NAME = "room_list";

export const KO = {
  DEFAULT_NAME: "손님",
  MODE_FULL: "합본",
  MODE_FULL_BLURB: "단발 권총 시작. 총과 아이템을 같이 줍는다.",
  ROOM_NOT_FOUND: "방을 찾을 수 없습니다",
  WRONG_PIN: "방 비밀번호가 틀렸습니다",
  PIN_CREATE_PROMPT: "방 비밀번호 (숫자 4~8자리) — 없이 만들려면 취소",
  PIN_JOIN_PROMPT: "🔒 잠긴 방입니다 — 비밀번호를 입력하세요",
  ROOM_FULL: `방이 가득 찼습니다 (${HUB_CONFIG.maxPlayers})`,
  CANNOT_CHANGE_MODE: "지금은 게임을 바꿀 수 없습니다",
  HOST_ONLY_MODE: "호스트만 게임을 바꿀 수 있습니다",
  HOST_ONLY_START: "호스트만 시작할 수 있습니다",
  CANNOT_KICK: "지금은 내보낼 수 없습니다",
  HOST_ONLY_KICK: "호스트만 내보낼 수 있습니다",
  KICKED_MSG: "호스트가 방에서 내보냈습니다.",
  ROOM_CLOSED: "방이 닫혔습니다.",
  HOST_ONLY_TOGGLE: "호스트만 방을 열고 닫을 수 있습니다.",
  HOST_BOOT_FAIL: "호스트가 게임을 시작하지 못했습니다.",
  GAME_END_LOBBY: "게임이 끝났습니다. 대기실로 돌아왔습니다.",
  RESUME_NOT_FOUND: "이전 자리를 찾지 못했습니다. 로비로 갑니다.",
  playerJoined: (name: string) => `${name} 이(가) 들어왔습니다.`,
  playerKicked: (name: string) => `${name} 이(가) 내보내졌습니다.`,
  playerLeft: (name: string) => `${name} 이(가) 나갔습니다.`,
  playerReconnected: (name: string) => `${name} 이(가) 다시 연결되었습니다.`,
  hostLeftEnd: (name: string) => `호스트(${name})가 나가서 게임이 종료됩니다.`,
  playerDropped: (name: string, sec: number) =>
    `${name} 연결이 끊겼습니다. ${sec}초 안에 다시 들어오면 자리가 유지됩니다.`,
} as const;

export const MODES: Record<string, { id: string; title: string; blurb: string }> = {
  full: { id: "full", title: KO.MODE_FULL, blurb: KO.MODE_FULL_BLURB },
};
