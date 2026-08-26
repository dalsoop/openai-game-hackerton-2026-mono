import type { RoomAvailable } from "@colyseus/sdk";
import { listableRoom } from "./room-mapper";

export function roomsHttpBody(rooms: Array<RoomAvailable & { locked?: boolean }>): { rooms: RoomAvailable[] } {
  return { rooms: rooms.filter(listableRoom) };
}

/** matchMaker.query 가 멈추면 /rooms 가 영구 대기가 된다. */
export function withDeadline<T>(work: Promise<T>, ms: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("deadline")), ms);
    work.then(
      (value) => { clearTimeout(timer); resolve(value); },
      (err: unknown) => { clearTimeout(timer); reject(err); },
    );
  });
}
