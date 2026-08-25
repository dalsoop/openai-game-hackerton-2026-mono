export const CONFIG = {
  port: Number(process.env.PORT || 9120),
  slot: process.env.SLOT_FOLDER || "server-yjh-dev1",
  graceLobbyMs: 60_000,
  gracePlayMs: 60_000,
  maxPayload: 256 * 1024,
  defaultName: "손님",
  defaultMode: "full",
  gameServerUrl: process.env.GAME_SERVER_URL || "http://127.0.0.1:9122",
  maxNameLength: 12,
  maxTitleLength: 24,
  maxChatLength: 120,
  chatCooldownMs: 400,
  rateBudget: 60,
  rateRefillPerMs: 0.04,
  snapDeltaLogInterval: 100,
  resetToLobbyDelayMs: 5_000,
  hostBootTimeoutMs: 45_000,
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

export const ROUTES = {
  health: ["/health", "/gang-up/health"] as readonly string[],
  metrics: ["/metrics", "/gang-up/metrics"] as readonly string[],
  status: ["/status", "/gang-up/status"] as readonly string[],
  prefix: "/gang-up",
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
