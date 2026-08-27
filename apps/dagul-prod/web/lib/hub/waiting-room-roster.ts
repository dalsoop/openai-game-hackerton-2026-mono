import type { Room } from "@colyseus/sdk";
import { lobbyReadySig } from "../domain/match-load-ready";
import { Roster, plainSeatOf, seatListOf, type RosterSnapshot, type Seat } from "../domain/roster";
import type { HubStatus } from "../../types";

export interface WaitingRoomRoster {
  gameId: string;
  mode: string;
  idleUntilSec: number;
  open: boolean;
  players: Seat[];
  you: number;
  isHost: boolean;
  roomId: string;
  resumeToken: string;
  loadHeld: boolean;
  status: HubStatus;
}

/** 전투 스키마를 빼고 로비 필드만. 좌석은 평문 복사 — 매치 종료 후 죽은 ~refId 를 읽지 않는다.
 * 갱신 감지는 readySig + useRoomState 가 decode 때마다 selector 를 다시 돌리는 것에 맡긴다. */
export function lobbyFieldsOf(s: RosterSnapshot): RosterSnapshot {
  try {
    const players = seatListOf(s.players).map(plainSeatOf);
    return {
      gameId: s.gameId,
      mode: s.mode,
      open: s.open,
      createdAtMs: s.createdAtMs,
      idleUntilSec: s.idleUntilSec,
      loadHeld: s.loadHeld,
      readySig: lobbyReadySig(players, Boolean(s.loadHeld)),
      phase: s.phase,
      hostSessionId: s.hostSessionId,
      players,
    };
  } catch {
    return {
      gameId: "",
      mode: "",
      open: true,
      loadHeld: false,
      readySig: "",
      phase: "",
      hostSessionId: "",
      players: [],
    };
  }
}

export function waitingRoomRosterOf(
  room: Room | undefined,
  snap: RosterSnapshot | undefined,
): WaitingRoomRoster | null {
  if (!room || !snap) {return null;}
  const roster = Roster.fromSnapshot(snap, room.sessionId);
  return {
    gameId: snap.gameId ?? "",
    mode: snap.mode ?? "",
    idleUntilSec: Number(snap.idleUntilSec ?? 0),
    open: snap.open !== false,
    players: roster.seats,
    you: roster.you,
    isHost: roster.isHost,
    roomId: room.roomId,
    resumeToken: room.reconnectionToken,
    loadHeld: Boolean(snap.loadHeld),
    status: (roster.playing ? "playing" : "in-room") as HubStatus,
  };
}
