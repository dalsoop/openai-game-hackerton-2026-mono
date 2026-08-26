import type { Room } from "@colyseus/sdk";
import { lobbyReadySig } from "../domain/match-load-ready";
import { Roster, seatListOf, type RosterSnapshot, type Seat } from "../domain/roster";
import type { HubStatus } from "../../types";

export interface WaitingRoomRoster {
  gameId: string;
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

/** 전투 스키마를 빼고 로비 필드만. readySig 로 중첩 matchReady 변이를 드러낸다. */
export function lobbyFieldsOf(s: RosterSnapshot): RosterSnapshot {
  // players 는 스키마 참조를 그대로 반환해야 한다 — useRoomState 는 selector 결과에 담긴
  // 스키마 ref 로 변경을 추적하므로, 파생 배열로 바꾸면 이후 좌석 갱신이 감지되지 않아
  // 대기실 명단이 빈 채로 고정된다 (readySig 계산용 나열은 추적에 영향 없음).
  return {
    gameId: s.gameId,
    open: s.open,
    createdAtMs: s.createdAtMs,
    idleUntilSec: s.idleUntilSec,
    loadHeld: s.loadHeld,
    readySig: lobbyReadySig(seatListOf(s.players), Boolean(s.loadHeld)),
    phase: s.phase,
    hostSessionId: s.hostSessionId,
    players: s.players,
  };
}

export function waitingRoomRosterOf(
  room: Room | undefined,
  snap: RosterSnapshot | undefined,
): WaitingRoomRoster | null {
  if (!room || !snap) {return null;}
  const roster = Roster.fromSnapshot(snap, room.sessionId);
  return {
    gameId: snap.gameId ?? "",
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
