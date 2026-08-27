// 방 공유 링크 — QR·복사가 쓰는 URL. 비밀번호가 있으면 쿼리에 실어 바로 입장한다.
export interface RoomShare {
  readonly roomId: string;
  readonly password: string;
}

export function parseRoomShare(search: string): RoomShare | null {
  const q = new URLSearchParams(search.startsWith("?") ? search.slice(1) : search);
  const roomId = (q.get("room") ?? "").trim();
  if (!roomId) {return null;}
  return { roomId, password: (q.get("pw") ?? "").trim() };
}

export function buildRoomSharePath(share: RoomShare): string {
  const q = new URLSearchParams();
  q.set("room", share.roomId);
  if (share.password) {q.set("pw", share.password);}
  return `/?${q.toString()}`;
}

export function buildRoomShareUrl(origin: string, share: RoomShare): string {
  const base = origin.replace(/\/$/, "");
  return `${base}${buildRoomSharePath(share)}`;
}

export function savePendingJoin(store: Pick<Storage, "setItem">, key: string, share: RoomShare): void {
  store.setItem(key, JSON.stringify(share));
}

function parsePendingRaw(raw: string | null): RoomShare | null {
  if (!raw) {return null;}
  try {
    const parsed = JSON.parse(raw) as { roomId?: unknown; password?: unknown };
    const roomId = typeof parsed.roomId === "string" ? parsed.roomId.trim() : "";
    if (!roomId) {return null;}
    return { roomId, password: typeof parsed.password === "string" ? parsed.password : "" };
  } catch {
    return null;
  }
}

export function peekPendingJoin(store: Pick<Storage, "getItem">, key: string): RoomShare | null {
  return parsePendingRaw(store.getItem(key));
}

export function takePendingJoin(store: Pick<Storage, "getItem" | "removeItem">, key: string): RoomShare | null {
  const share = parsePendingRaw(store.getItem(key));
  store.removeItem(key);
  return share;
}
