import type { Room } from "@colyseus/sdk";
import { lobbyReadySig } from "../domain/match-load-ready";
import { Roster, type RosterSnapshot, type Seat } from "../domain/roster";
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
  const players = Array.isArray(s.players) ? s.players : [];
  return {
    gameId: s.gameId,
    open: s.open,
    createdAtMs: s.createdAtMs,
    idleUntilSec: s.idleUntilSec,
    loadHeld: s.loadHeld,
    readySig: lobbyReadySig(players, Boolean(s.loadHeld)),
    phase: s.phase,
    hostSessionId: s.hostSessionId,
    players,
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
