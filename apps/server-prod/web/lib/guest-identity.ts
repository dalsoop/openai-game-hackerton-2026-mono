// 게스트 표시명 — 십이지신 + 쿠키 숫자 ID. 훅은 쿠키 I/O 만, 규칙은 여기.
import { WEB_STORE } from "./contract/wire";
import { ZODIAC_NAMES } from "./hub/config";

export const GUEST_ID_MIN = 100_000;
export const GUEST_ID_SPAN = 900_000;
const COOKIE_MAX_AGE_SEC = 60 * 60 * 24 * 365 * 2;

export function parseGuestId(raw: string | null | undefined): number | null {
  if (raw == null || raw === "") {return null;}
  const n = Number(raw);
  if (!Number.isInteger(n) || n <= 0) {return null;}
  return n;
}

export function mintGuestId(rand = defaultRand): number {
  return (rand() % GUEST_ID_SPAN) + GUEST_ID_MIN;
}

export function guestNameOf(id: number, names: readonly string[] = ZODIAC_NAMES): string {
  if (names.length === 0) {return `#${id}`;}
  const idx = ((id % names.length) + names.length) % names.length;
  return `${names[idx]}#${id}`;
}

export function readCookie(name: string, cookie: string): string | null {
  const prefix = `${name}=`;
  for (const part of cookie.split(";")) {
    const trimmed = part.trim();
    if (trimmed.startsWith(prefix)) {
      return decodeURIComponent(trimmed.slice(prefix.length));
    }
  }
  return null;
}

export function cookieWritePair(name: string, value: string): string {
  return `${name}=${encodeURIComponent(value)}; Path=/; Max-Age=${COOKIE_MAX_AGE_SEC}; SameSite=Lax`;
}

/** 브라우저에서만. 쿠키가 없으면 숫자 ID 를 발급해 심는다. */
export function readOrCreateGuestId(): number | null {
  if (typeof document === "undefined") {return null;}
  const existing = parseGuestId(readCookie(WEB_STORE.GUEST_ID, document.cookie));
  if (existing !== null) {return existing;}
  const id = mintGuestId();
  document.cookie = cookieWritePair(WEB_STORE.GUEST_ID, String(id));
  return id;
}

function defaultRand(): number {
  const buf = new Uint32Array(1);
  crypto.getRandomValues(buf);
  return buf[0];
}
