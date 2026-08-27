// 게스트 표시명 — 십이지신 + 쿠키 숫자 ID. 훅은 쿠키 I/O 만, 규칙은 여기.
import { WEB_STORE } from "./contract/wire";
import { DEFAULT_LOCALE } from "../i18n/locales";
import { allZodiacNameTables, zodiacNamesOf } from "./i18n/message-packs";

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

export function guestNameOf(
  id: number,
  names: readonly string[] = zodiacNamesOf(DEFAULT_LOCALE),
): string {
  if (names.length === 0) {return `#${id}`;}
  const idx = ((id % names.length) + names.length) % names.length;
  return `${names[idx]}#${id}`;
}

export function zodiacNamesFor(locale: string): readonly string[] {
  return zodiacNamesOf(locale);
}

export function guestNameForLocale(id: number, locale: string): string {
  return guestNameOf(id, zodiacNamesFor(locale));
}

/** 저장본이 자동 게스트 닉이면 로케일을 따라가게 한다. 커스텀 닉은 건드리지 않는다. */
export function isAutoGuestName(name: string, id: number): boolean {
  return allZodiacNameTables().some((names) => guestNameOf(id, names) === name);
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

// ── 좌석 이어받기(takeover) 증명 ─────────────────────────────────
// GUEST_ID 는 닉네임("쥐#123456")에 공개되므로 그것만으로 좌석을 넘기면
// 타인이 남의 좌석을 뺏을 수 있다. 비공개 키가 함께 일치할 때만 이어받는다.

export const GUEST_KEY_LEN = 32;

export interface SeatClaim {
  readonly guestId: number;
  readonly guestKey: string;
}

export function mintGuestKey(): string {
  const buf = new Uint8Array(GUEST_KEY_LEN / 2);
  crypto.getRandomValues(buf);
  return Array.from(buf, (b) => b.toString(16).padStart(2, "0")).join("");
}

export function readOrCreateGuestKey(): string | null {
  if (typeof document === "undefined") {return null;}
  const existing = readCookie(WEB_STORE.GUEST_KEY, document.cookie);
  if (existing !== null && existing.length >= GUEST_KEY_LEN) {return existing;}
  const key = mintGuestKey();
  document.cookie = cookieWritePair(WEB_STORE.GUEST_KEY, key);
  return key;
}

/** join 옵션에 실을 이어받기 증명 — 쿠키가 없는 환경이면 null (이어받기 없이 입장). */
export function seatClaimNow(): SeatClaim | null {
  const guestId = readOrCreateGuestId();
  const guestKey = readOrCreateGuestKey();
  if (guestId === null || guestKey === null) {return null;}
  return { guestId, guestKey };
}

/** 신뢰할 수 없는 join 옵션에서 증명을 파싱 — 키가 짧으면 증명으로 취급하지 않는다. */
export function parseSeatClaim(raw: { guestId?: unknown; guestKey?: unknown }): SeatClaim | null {
  const guestId = parseGuestId(typeof raw.guestId === "number" ? String(raw.guestId) : (raw.guestId as string | undefined));
  const guestKey = typeof raw.guestKey === "string" ? raw.guestKey : "";
  if (guestId === null || guestKey.length < GUEST_KEY_LEN) {return null;}
  return { guestId, guestKey };
}

export function sameSeatClaim(a: SeatClaim | undefined, b: SeatClaim | null): boolean {
  if (!a || !b) {return false;}
  return a.guestId === b.guestId && a.guestKey === b.guestKey;
}

function defaultRand(): number {
  const buf = new Uint32Array(1);
  crypto.getRandomValues(buf);
  return buf[0];
}
