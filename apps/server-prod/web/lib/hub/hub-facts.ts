import type { Room } from "@colyseus/sdk";
import { Roster, type RosterSnapshot } from "../domain/roster";
import type { HubPlayer, HubStatus } from "@/types";

export interface HubFacts {
  gameId: string;
  idleUntilSec: number;
  open: boolean;
  players: HubPlayer[];
  you: number;
  isHost: boolean;
  roomId: string;
  resumeToken: string;
  status: HubStatus;
}

export function deriveHubFacts(room: Room | undefined, snap: RosterSnapshot | undefined): HubFacts | null {
  if (!room || !snap) {return null;}
  const roster = Roster.fromSnapshot(snap, room.sessionId);
  const players: HubPlayer[] = roster.seats.map((seat) => ({
    slot: seat.slot, id: seat.playerId, name: seat.name,
    host: seat.isHost, dropped: !seat.connected, dlPct: seat.dlPct,
  }));
  return {
    gameId: snap.gameId ?? "",
    idleUntilSec: Number(snap.idleUntilSec ?? 0),
    open: snap.open !== false,
    players,
    you: roster.you,
    isHost: roster.isHost,
    roomId: room.roomId,
    resumeToken: room.reconnectionToken,
    status: (roster.playing ? "playing" : "in-room") as HubStatus,
  };
}
