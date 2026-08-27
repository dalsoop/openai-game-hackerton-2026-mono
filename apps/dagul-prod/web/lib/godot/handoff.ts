import { HANDOFF } from "../contract";
import type { StartPayload } from "../hub/start-payload";

export interface HandoffInfo {
  roomId: string;
  name: string;
  slot: number;
  resumeToken: string;
  match?: StartPayload;
  /** KEY_GAME — 팩 id 가 아니라 모듈 id */
  game?: string;
}

// 핸드오프는 반드시 sessionStorage(탭 스코프) — localStorage 에 쓰면 다른 탭이
// 재접속 토큰을 주워 자동 reconnect 를 시도하고, 그 실패 처리가 원래 탭의 토큰을
// 지워 진행 중 게임이 로비로 리셋된다 (2026-08-26 재시작 버그의 근본 원인).
export function persistEngineHandoff(game: string, info: HandoffInfo): void {
  sessionStorage.setItem(HANDOFF.FROM_HUB, "1");
  sessionStorage.setItem(HANDOFF.GAME, game);
  sessionStorage.setItem(HANDOFF.NAME, info.name);
  sessionStorage.setItem(HANDOFF.ROOM_ID, info.roomId);
  sessionStorage.setItem(HANDOFF.SLOT, String(info.slot));
  if (info.resumeToken) {sessionStorage.setItem(HANDOFF.RESUME, info.resumeToken);}
  if (info.match) {
    sessionStorage.setItem(HANDOFF.MATCH, JSON.stringify(info.match));
    return;
  }
  sessionStorage.removeItem(HANDOFF.MATCH);
}

export function clearEngineHandoff(dropResume = false): void {
  sessionStorage.removeItem(HANDOFF.FROM_HUB);
  sessionStorage.removeItem(HANDOFF.MATCH);
  if (dropResume) {sessionStorage.removeItem(HANDOFF.RESUME);}
}
