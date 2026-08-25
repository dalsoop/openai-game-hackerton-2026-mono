import type { RoomAvailable } from "@colyseus/sdk";
import { listableRoom } from "./room-mapper";

export function roomsHttpBody(rooms: Array<RoomAvailable & { locked?: boolean }>): { rooms: RoomAvailable[] } {
  return { rooms: rooms.filter(listableRoom) };
}
