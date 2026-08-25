// 리스트 룸 → 로비 방 목록 매핑·델타 적용 — 순수 함수 (tests 대상).
import type { RoomAvailable } from "@colyseus/sdk";
import type { HubRoom } from "@/types";

/** RoomAvailable 1건 → HubRoom 뷰 모델. */
export function toHubRoom(r: RoomAvailable): HubRoom {
  const meta = (r.metadata ?? {}) as Record<string, unknown>;
  return {
    id: r.roomId,
    gameId: String(meta.gameId ?? ""),
    title: String(meta.title ?? r.roomId),
    players: r.clients,
    mode: String(meta.mode ?? ""),
    playing: meta.phase === "playing",
  };
}

/** 전체 목록 수신(MSG.ROOMS). */
export function replaceList(prev: RoomAvailable[], next: RoomAvailable[]): RoomAvailable[] {
  return next;
}

/** 단방 추가/갱신(+) — 있으면 교체, 없으면 append. */
export function upsertRoom(prev: RoomAvailable[], roomId: string, room: RoomAvailable): RoomAvailable[] {
  const idx = prev.findIndex((x) => x.roomId === roomId);
  if (idx === -1) {return [...prev, room];}
  const next = [...prev];
  next[idx] = room;
  return next;
}

/** 단방 제거(-). */
export function removeRoom(prev: RoomAvailable[], roomId: string): RoomAvailable[] {
  return prev.filter((x) => x.roomId !== roomId);
}
