function env(key: string): string {
  const v = process.env[key];
  if (v === undefined || v === "") throw new Error(`missing env: ${key}`);
  return v;
}

function envInt(key: string): number {
  return Number(env(key));
}

export const CONFIG = {
  port: envInt("PORT"),
  slot: env("SLOT_FOLDER"),
  frontendDir: env("FRONTEND_DIR"),
  gameServerUrl: env("GAME_SERVER_URL"),
  graceLobbyMs: 60_000,
  gracePlayMs: 180_000,
  maxPayload: 256 * 1024,
  maxNameLength: 12,
  maxTitleLength: 24,
  maxChatLength: 120,
  chatCooldownMs: 400,
  rateBudget: 60,
  rateRefillPerMs: 0.04,
  snapDeltaLogInterval: 100,
  resetToLobbyDelayMs: 5_000,
  hostBootTimeoutMs: 180_000,
  seedMax: 999_999,
  gameServerTimeoutMs: 5_000,
  logLevel: env("LOG_LEVEL") as "debug" | "info" | "warn" | "error",
  pingIntervalMs: 10_000,
  metricsIntervalMs: 5_000,
} as const;

export const Phase = { LOBBY: "lobby", PLAYING: "playing" } as const;
export type Phase = (typeof Phase)[keyof typeof Phase];

export const MSG = {
  WELCOME: "welcome", HELLO: "hello", ROOMS: "rooms", CREATE: "create",
  JOIN: "join", LEAVE: "leave", START: "start", KICK: "kick", CHAT: "chat",
  INPUT: "input", HOST_SNAP: "host_snap", SNAP: "snap",
  PEER_INPUT: "peer_input", PEER_PARKED: "peer_parked", PEER_RECLAIMED: "peer_reclaimed",
  JOINED: "joined", PEERS: "peers", LEFT: "left", KICKED: "kicked",
  LOBBY: "lobby", ERROR: "error", PING: "ping", PONG: "pong",
  DROPPED: "dropped", RESUME: "resume", MODE: "mode",
} as const;

const pathPrefix = env("PATH_PREFIX");

export const ROUTES = {
  health: ["/health", `${pathPrefix}/health`] as readonly string[],
  metrics: ["/metrics", `${pathPrefix}/metrics`] as readonly string[],
  status: ["/status", `${pathPrefix}/status`] as readonly string[],
  prefix: pathPrefix,
} as const;

export const API_HEADERS = {
  "access-control-allow-origin": "*",
  "cache-control": "no-store",
} as const;

export const JSON_HEADERS = {
  "content-type": "application/json",
  ...API_HEADERS,
} as const;

export const MIME_TYPES: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript",
  ".css": "text/css",
  ".json": "application/json",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
};
