import type { Room } from "@colyseus/sdk";
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
  status: HubStatus;
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
    status: (roster.playing ? "playing" : "in-room") as HubStatus,
  };
}
