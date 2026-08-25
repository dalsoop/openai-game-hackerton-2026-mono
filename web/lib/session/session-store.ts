import { randomUUID } from "crypto";

export interface Session {
  id: string;
  nickname: string;
  kills: number;
  wins: number;
  createdAt: number;
  lastActive: number;
}

const EXPIRY_MS = 24 * 60 * 60 * 1000;
const sessions = new Map<string, Session>();

let cleanupStarted = false;
function ensureCleanup() {
  if (cleanupStarted) return;
  cleanupStarted = true;
  setInterval(() => {
    const now = Date.now();
    for (const [id, s] of sessions) {
      if (now - s.lastActive > EXPIRY_MS) sessions.delete(id);
    }
  }, 60_000);
}

export function createSession(nickname: string): Session {
  ensureCleanup();
  const session: Session = {
    id: randomUUID(),
    nickname,
    kills: 0,
    wins: 0,
    createdAt: Date.now(),
    lastActive: Date.now(),
  };
  sessions.set(session.id, session);
  return session;
}

export function getSession(id: string): Session | null {
  const s = sessions.get(id);
  if (!s) return null;
  if (Date.now() - s.lastActive > EXPIRY_MS) {
    sessions.delete(id);
    return null;
  }
  return s;
}

export function touchSession(id: string): void {
  const s = sessions.get(id);
  if (s) s.lastActive = Date.now();
}

export function updateSession(
  id: string,
  patch: Partial<Pick<Session, "nickname" | "kills" | "wins">>
): Session | null {
  const s = sessions.get(id);
  if (!s) return null;
  if (patch.nickname !== undefined) s.nickname = patch.nickname;
  if (patch.kills !== undefined) s.kills += patch.kills;
  if (patch.wins !== undefined) s.wins += patch.wins;
  s.lastActive = Date.now();
  return s;
}
