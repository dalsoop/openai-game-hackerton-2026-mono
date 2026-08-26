// 방 종료 분류 — 훅·모달·서버 강퇴가 같이 쓰는 SSOT.
// React 의존 없음. 동의 퇴장과 튕김을 코드·메시지로 나눈다.

import { CLOSE_CODE } from "../contract/wire";
import type { GamePhase, HubStatus } from "@/types";

/** 모달 문구·재접속 가능 여부. 자발적 퇴장은 여기에 넣지 않는다. */
export type DropReason = "offline" | "kicked" | "dropped" | "idle";

/** onLeave 가 남기는 종료 종류. 핸드오프는 방이 살아 있다. */
export type RoomEndKind = "handoff" | "consented" | "drop";

export function roomEndKindFromCode(code: number | undefined): RoomEndKind {
  if (code === CLOSE_CODE.CONSENTED) {return "consented";}
  return "drop";
}

/** 강제 퇴장만 dropReason 을 남긴다. 동의 퇴장·양도는 모달을 띄우지 않는다. */
export function shouldMarkRoomDropped(kind: RoomEndKind): boolean {
  return kind === "drop";
}

export function dropReasonFromKick(raw: unknown): DropReason {
  if (raw && typeof raw === "object" && "reason" in raw) {
    if ((raw as { reason?: unknown }).reason === "idle") {return "idle";}
  }
  return "kicked";
}

/** 끊김·오프라인만 같은 방으로 다시 들어간다. 강퇴·유휴는 방이 없다. */
export function canOfferReconnect(reason: DropReason | null): boolean {
  return reason === "dropped" || reason === "offline";
}

export function reconnectJoinId(reason: DropReason | null, lastRoomId: string): string | null {
  if (!canOfferReconnect(reason) || lastRoomId === "") {return null;}
  return lastRoomId;
}

/** 회색 화면 대신 안내 모달. 자발적 퇴장은 dropReason 이 없다. */
export function shouldShowReconnect(
  status: HubStatus,
  phase: GamePhase,
  dropReason: DropReason | null,
): boolean {
  if (dropReason) {return true;}
  return status === "offline" && phase !== "intro";
}
