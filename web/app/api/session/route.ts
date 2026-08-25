import { NextRequest, NextResponse } from "next/server";
import {
  createSession,
  getSession,
  touchSession,
  updateSession,
} from "@/lib/session/session-store";

const COOKIE = "dagul_session";
const MAX_AGE = 86400;

function cookieOpts() {
  return { httpOnly: true, sameSite: "lax" as const, maxAge: MAX_AGE, path: "/" };
}

export async function GET(req: NextRequest) {
  const id = req.cookies.get(COOKIE)?.value;
  if (!id) return NextResponse.json(null);
  const session = getSession(id);
  if (!session) {
    const res = NextResponse.json(null);
    res.cookies.delete(COOKIE);
    return res;
  }
  touchSession(id);
  return NextResponse.json({
    nickname: session.nickname,
    kills: session.kills,
    wins: session.wins,
  });
}

export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => ({}));
  const nickname = String(body.nickname || "").trim().slice(0, 20) || "플레이어";
  const session = createSession(nickname);
  const res = NextResponse.json({
    nickname: session.nickname,
    kills: session.kills,
    wins: session.wins,
  });
  res.cookies.set(COOKIE, session.id, cookieOpts());
  return res;
}

export async function PATCH(req: NextRequest) {
  const id = req.cookies.get(COOKIE)?.value;
  if (!id) return NextResponse.json({ error: "no session" }, { status: 401 });
  const body = await req.json().catch(() => ({}));
  const updated = updateSession(id, {
    kills: typeof body.kills === "number" ? body.kills : undefined,
    wins: typeof body.wins === "number" ? body.wins : undefined,
    nickname: typeof body.nickname === "string" ? body.nickname : undefined,
  });
  if (!updated) return NextResponse.json({ error: "expired" }, { status: 401 });
  return NextResponse.json({
    nickname: updated.nickname,
    kills: updated.kills,
    wins: updated.wins,
  });
}
