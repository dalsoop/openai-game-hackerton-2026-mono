// 방 PIN — 넷플릭스처럼 4자리 숫자. 호스트가 토글로 켜면 서버가 부여한다.

export const PIN_LENGTH = 4;

export function generateRoomPin(rand: () => number = Math.random): string {
  return String(Math.floor(rand() * 10 ** PIN_LENGTH)).padStart(PIN_LENGTH, "0");
}

/** 숫자만 모아 4자리. 모자라면 빈 문자열(불량). */
export function parseRoomPassword(raw: unknown): string {
  const digits = (typeof raw === "string" ? raw : String(raw ?? "")).replace(/\D/g, "");
  if (digits.length !== PIN_LENGTH) {return "";}
  return digits;
}

export function hasRoomPassword(password: string): boolean {
  return parseRoomPassword(password) === password && password.length === PIN_LENGTH;
}

export function parseLockFlag(raw: unknown): boolean {
  return raw === true || raw === "true" || raw === "on" || raw === 1 || raw === "1";
}

/** 방 만들기 — 잠금 토글이 켜져 있을 때만 PIN 을 붙인다. */
export function resolveCreatePassword(
  raw: { lock?: unknown; password?: unknown },
  generate: () => string = generateRoomPin,
): string {
  if (!parseLockFlag(raw.lock) && !hasRoomPassword(parseRoomPassword(raw.password))) {return "";}
  return parseRoomPassword(raw.password) || generate();
}

/** 호스트가 PIN 을 켜거나 끄거나 다시 뽑는다. */
export function resolveSetPassword(
  data: { enabled?: unknown; password?: unknown },
  generate: () => string = generateRoomPin,
): string {
  if (data.enabled === false) {return "";}
  const parsed = parseRoomPassword(data.password);
  if (parsed) {return parsed;}
  if (data.enabled === true) {return generate();}
  return "";
}

export function passwordMatches(stored: string, provided: unknown): boolean {
  if (!hasRoomPassword(stored)) {return false;}
  return stored === parseRoomPassword(provided);
}

/** 공개 방·방 만든 사람·좌석 이어받기는 PIN 없이 들어온다. */
export function joinPasswordOk(
  stored: string,
  provided: unknown,
  opts: { isCreator: boolean; takeover: boolean },
): boolean {
  if (opts.takeover || opts.isCreator) {return true;}
  if (!hasRoomPassword(stored)) {return true;}
  return passwordMatches(stored, provided);
}
