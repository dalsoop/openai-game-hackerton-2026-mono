export { HANDOFF, DOM_EVT, MSG, CLOSE_CODE, ROOM_LEAVE } from "../contract/wire";

/** 스키마 델타라 60Hz 가 가볍다. 0/NaN 은 60. 20으로 낮추면 Colyseus 기본(50ms) 원복. */
export function parsePatchHz(raw: string | undefined): number {
  const n = Number(raw ?? 60);
  return n === 0 || Number.isNaN(n) ? 60 : n;
}

export const HUB_CONFIG = {
  graceLobbyMs: 60_000,
  gracePlayMs: 180_000,
  maxPayload: 32 * 1024,
  maxSnapBytes: 24 * 1024,
  defaultName: "손님",
  gameServerUrl: process.env.GAME_SERVER_URL ?? "http://127.0.0.1:9122",
  maxNameLength: 12,
  maxTitleLength: 24,
  rateBudget: 60,
  rateRefillPerMs: 0.04,
  resetToLobbyDelayMs: 10_000,
  // 호스트가 순간적으로 사라져도 곧바로 로비 리셋하지 않고, 재접속/재선정을 기다리는 유예.
  hostLossGraceMs: 3_000,
  hostBootTimeoutMs: 180_000,
  idleStartMs: 5 * 60 * 1000,
  maxPlayers: 8,
  seedMax: 999_999,
  gameServerTimeoutMs: 5_000,
  matchWatchdogMs: 30_000,
  /** 전원 ready 를 이 시간 안에 못 받으면 카운트다운을 강제 해제한다. */
  loadReadyTimeoutMs: 20_000,
  rttIntervalMs: 2_000,
  listPollMs: 4_000,
  roomsFetchMs: 3_000,
  lobbyHealthRttMs: 0,
  perProcessCcu: 500,
  targetCcu: 1_000,
  // 스키마 델타 + 엔진 직결이라 60Hz 가 가볍다. HUB_PATCH_HZ=20 이면 Colyseus 기본(50ms)으로 원복.
  patchHz: parsePatchHz(process.env.HUB_PATCH_HZ),
} as const;

export const LIST_MSG = { ADD: "+", REMOVE: "-", ROOMS: "rooms" } as const;

/** 이 앱 폴더의 기본 슬롯. 브라우저 번들은 SLOT_FOLDER 가 없으므로 여기로 맞춘다. */
export const DEFAULT_SLOT = "dagul-prod";

/** 핸들러 이름에 슬롯을 붙인다. presence 격리는 REDIS_URL logical DB 가 한다.
 * ioredis keyPrefix 는 쓰지 않는다 (pub/sub·예약 키가 갈라져 4002). */
export function slotId(slot = process.env.SLOT_FOLDER ?? ""): string {
  const trimmed = slot.trim();
  return trimmed || DEFAULT_SLOT;
}

export function slotRoomName(base: string, slot = slotId()): string {
  return `${slotId(slot)}-${base}`;
}

export const ROOM_NAME = slotRoomName("lobby");

/** 게스트 기본 닉 — 십이지신. {이름}#{쿠키ID} 에 쓴다. */
export const ZODIAC_NAMES = [
  "쥐", "소", "호랑이", "토끼", "용", "뱀", "말", "양", "원숭이", "닭", "개", "돼지",
] as const;

export const KO = {
  DEFAULT_NAME: "손님",
  WEAPON_PISTOL: "권총",
  ROOM_NOT_FOUND: "방을 찾을 수 없습니다",
  ROOM_FULL: `방이 가득 찼습니다 (${HUB_CONFIG.maxPlayers})`,
  HOST_ONLY_START: "호스트만 시작할 수 있습니다",
  HOST_ONLY_GAME: "호스트만 게임을 바꿀 수 있습니다",
  IDLE_START: "방장이 제한 시간 안에 시작하지 않아 방이 닫혔습니다.",
  CANNOT_KICK: "지금은 내보낼 수 없습니다",
  HOST_ONLY_KICK: "호스트만 내보낼 수 있습니다",
  KICKED_MSG: "호스트가 방에서 내보냈습니다.",
  TAKEOVER_MSG: "다른 창에서 접속하여 이 화면은 비활성화되었습니다.",
  ROOM_CLOSED: "방이 닫혔습니다.",
  HOST_ONLY_TOGGLE: "호스트만 방을 열고 닫을 수 있습니다.",
  HOST_BOOT_FAIL: "호스트가 게임을 시작하지 못했습니다.",
  GAME_END_LOBBY: "게임이 끝났습니다. 대기실로 돌아왔습니다.",
  RESUME_NOT_FOUND: "이전 자리를 찾지 못했습니다. 로비로 갑니다.",
  roomTitleFallback: (roomId: string) => `방 #${roomId}`,
  playerJoined: (name: string) => `${name} 이(가) 들어왔습니다.`,
  playerKicked: (name: string) => `${name} 이(가) 내보내졌습니다.`,
  playerLeft: (name: string) => `${name} 이(가) 나갔습니다.`,
  playerReconnected: (name: string) => `${name} 이(가) 다시 연결되었습니다.`,
  hostLeftEnd: (name: string) => `호스트(${name})가 나가서 게임이 종료됩니다.`,
  playerDropped: (name: string, sec: number) =>
    `${name} 연결이 끊겼습니다. ${sec}초 안에 다시 들어오면 자리가 유지됩니다.`,
} as const;
