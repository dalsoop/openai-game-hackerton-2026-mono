// 방 소켓 RTT — 클라가 t 를 보내고 서버가 그대로 돌려준다.

export function parsePingStamp(raw: unknown): number | null {
  if (typeof raw === "number" && Number.isFinite(raw) && raw > 0) {return raw;}
  if (!raw || typeof raw !== "object") {return null;}
  const t = Number((raw as { t?: unknown }).t);
  if (!Number.isFinite(t) || t <= 0) {return null;}
  return t;
}

/** 왕복 ms. 시계가 거꾸로면 버린다. */
export function rttFromPong(sentAt: number, now: number): number | null {
  if (sentAt <= 0 || now < sentAt) {return null;}
  return Math.round(now - sentAt);
}
