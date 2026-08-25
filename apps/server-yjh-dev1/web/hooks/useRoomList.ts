"use client";
// 방 목록 훅 — 내장 리스트 룸 구독(실시간, 폴링 없음).
// useLobbyRoom 은 핸들러 등록이 passive effect 로 늦어져, 서버가 join 직후
// 보내는 첫 전체 목록(MSG.ROOMS)이 등록 전에 도착하면 놓친다 — 그래서
// join 프로미스 resolve 시점에 직접 등록한다 (마이크로태스크라 다음 WS 프레임보다 먼저).
import { useMemo, useState } from "react";
import type { Room, RoomAvailable } from "@colyseus/sdk";
import { useRoom } from "@colyseus/react";
import { MSG, LIST_ROOM_NAME } from "@/lib/hub/config";
import { toHubRoom, replaceList, upsertRoom, removeRoom } from "@/lib/hub/room-mapper";
import type { HubRoom } from "@/types";
import type { Client } from "@colyseus/sdk";

export function useRoomList(active: boolean, getClient: () => Client): {
  rooms: HubRoom[];
  lobbyErr: Error | undefined;
  lobbyConnecting: boolean;
} {
  const [roomList, setRoomList] = useState<RoomAvailable[]>([]);
  const { error: lobbyErr, isConnecting: lobbyConnecting } = useRoom(
    active
      ? async (): Promise<Room> => {
          const list = await getClient().joinOrCreate(LIST_ROOM_NAME);
          list.onMessage(MSG.ROOMS, (r: RoomAvailable[]) => {setRoomList((prev) => replaceList(prev, r));});
          list.onMessage("+", ([roomId, room]: [string, RoomAvailable]) => {
            setRoomList((prev) => upsertRoom(prev, roomId, room));
          });
          list.onMessage("-", (roomId: string) => {
            setRoomList((prev) => removeRoom(prev, roomId));
          });
          return list;
        }
      : null,
    [active],
  );

  const rooms: HubRoom[] = useMemo(() => roomList.map(toHubRoom), [roomList]);
  return { rooms, lobbyErr, lobbyConnecting };
}
