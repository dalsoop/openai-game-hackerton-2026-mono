/** Colyseus publicAddress — 프로토콜 없이 host/path. */
export function hubPublicAddress(prefix?: string, pod?: string): string | undefined {
  const host = prefix?.trim() ?? "";
  const name = pod?.trim() ?? "";
  if (!host || !name) {return undefined;}
  return `${host}/${name}`;
}

/** 방 주인 Pod. 생성·목록만 입구, 이후 HTTP 는 이 핀. Godot 계약 밖. */
export const HUB_PIN_KEY = "hub_room_pin";

export type HubPinRecord = { roomId: string; pin: string };

export function hubPinFromWsUrl(href?: string): string | undefined {
  if (!href) {return undefined;}
  try {
    const parsed = new URL(href);
    const hit = parsed.pathname.match(/^\/hubp\/([A-Za-z0-9-]+)/);
    if (!hit) {return undefined;}
    return `${parsed.host}/hubp/${hit[1]}`;
  } catch {
    return undefined;
  }
}

export function hubHttpEndpoint(origin: string, pin?: string | null): string {
  const trimmed = pin?.trim() ?? "";
  if (!trimmed) {return origin;}
  const proto = origin.startsWith("https:") ? "https:" : "http:";
  return `${proto}//${trimmed}`;
}

function pinRecordFromJson(text: string): HubPinRecord | null {
  try {
    const body = JSON.parse(text) as { roomId?: unknown; pin?: unknown };
    if (typeof body.pin === "string" && body.pin && typeof body.roomId === "string") {
      return { roomId: body.roomId, pin: body.pin };
    }
  } catch {
    return null;
  }
  return null;
}

export function parseHubPinRecord(raw: string | null): HubPinRecord | null {
  if (!raw) {return null;}
  const text = raw.trim();
  if (!text) {return null;}
  if (text.startsWith("{")) {return pinRecordFromJson(text);}
  if (text.includes("/hubp/")) {return { roomId: "", pin: text };}
  return null;
}

/** create 는 입구. resume 은 마지막 핀. join 은 같은 roomId 일 때만 핀. */
export function pinForMatchmake(
  kind: "create" | "join" | "resume",
  roomId: string | undefined,
  stored: HubPinRecord | null,
): string | null {
  if (kind === "create" || !stored?.pin) {return null;}
  if (kind === "resume") {return stored.pin;}
  if (!roomId || !stored.roomId || stored.roomId !== roomId) {return null;}
  return stored.pin;
}

export function rememberHubPin(wsUrl?: string, roomId?: string): void {
  const pin = hubPinFromWsUrl(wsUrl);
  if (!pin || !roomId) {return;}
  try {localStorage.setItem(HUB_PIN_KEY, JSON.stringify({ roomId, pin }));} catch { /* quota */ }
}

export function forgetHubPin(): void {
  try {localStorage.removeItem(HUB_PIN_KEY);} catch { /* */ }
}

export function storedHubPinRecord(): HubPinRecord | null {
  try {return parseHubPinRecord(localStorage.getItem(HUB_PIN_KEY));} catch {return null;}
}

export function storedHubPin(): string | null {
  return storedHubPinRecord()?.pin ?? null;
}

export function matchmakePin(kind: "create" | "join" | "resume", roomId?: string): string | null {
  return pinForMatchmake(kind, roomId, storedHubPinRecord());
}
