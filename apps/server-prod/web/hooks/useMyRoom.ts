"use client";
// 내 방 멤버십 훅 — 방에 있는 동안 식별자를 localStorage 에 유지한다.
// 값은 렌더마다 동기 읽기(localStorage, 불변 읽기라 무해) — 방 목록 변화 때마다 재판정된다.
// 판정·정렬은 lib/room-membership(순수)이 담당.
import { useEffect } from "react";
import { readMyRoom, saveMyRoom, type MyRoomIdentity } from "@/lib/room-membership";

interface DerivedRoom {
  roomId: string;
  isHost: boolean;
}

export function useMyRoom(derived: DerivedRoom | null): MyRoomIdentity | null {
  useEffect(() => {
    if (derived) {
      saveMyRoom((k, v) => localStorage.setItem(k, v), { roomId: derived.roomId, host: derived.isHost });
    }
  }, [derived]);

  return readMyRoom((k) => localStorage.getItem(k));
}
