"use client";
// 방 목록 — 리스트 룸 대신 GET /rooms 를 짧게 폴링한다.
import { useEffect, useMemo, useState } from "react";
import type { RoomAvailable } from "@colyseus/sdk";
import { HUB_CONFIG } from "@/lib/hub/config";
import { roomsHttpBody } from "@/lib/hub/rooms-http";
import { toHubRoom } from "@/lib/hub/room-mapper";
import type { HubRoom } from "@/types";

export async function fetchJoinableRooms(fetchImpl: typeof fetch = fetch): Promise<RoomAvailable[]> {
  const res = await fetchImpl("/rooms", { cache: "no-store" });
  if (!res.ok) {throw new Error("rooms");}
  const body = roomsHttpBody((await res.json() as { rooms?: RoomAvailable[] }).rooms ?? []);
  return body.rooms;
}

export function useRoomList(active: boolean): {
  rooms: HubRoom[];
  lobbyErr: Error | undefined;
  lobbyConnecting: boolean;
} {
  const [roomList, setRoomList] = useState<RoomAvailable[]>([]);
  const [lobbyErr, setLobbyErr] = useState<Error | undefined>();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!active) {return;}
    let alive = true;
    const tick = (): void => {
      void fetchJoinableRooms()
        .then((next) => {
          if (!alive) {return;}
          setRoomList(next);
          setLobbyErr(undefined);
          setReady(true);
        })
        .catch((err: unknown) => {
          if (!alive) {return;}
          setLobbyErr(err instanceof Error ? err : new Error(String(err)));
          setReady(true);
        });
    };
    tick();
    const id = setInterval(tick, HUB_CONFIG.listPollMs);
    return (): void => {alive = false; clearInterval(id);};
  }, [active]);

  const rooms: HubRoom[] = useMemo(
    () => (active ? roomList.map(toHubRoom) : []),
    [active, roomList],
  );
  return { rooms, lobbyErr: active ? lobbyErr : undefined, lobbyConnecting: active && !ready };
}
