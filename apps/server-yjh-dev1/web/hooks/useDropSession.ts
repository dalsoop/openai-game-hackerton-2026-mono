"use client";
// 강퇴·튕김 재접속 — useHub 분기 수를 늘리지 않기 위해 분리한다.
import { useCallback, useState } from "react";
import { dropReasonFromKick, reconnectJoinId, type DropReason } from "@/lib/hub/room-end";

export function useDropSession(): {
  dropReason: DropReason | null;
  lastRoomId: string;
  rememberRoomId: (id: string) => void;
  onRoomDropped: () => void;
  onKicked: (raw?: unknown) => void;
  clearDrop: () => void;
  takeReconnectId: () => string | null;
} {
  const [dropReason, setDropReason] = useState<DropReason | null>(null);
  const [lastRoomId, setLastRoomId] = useState("");

  const rememberRoomId = useCallback((id: string) => {
    if (id !== "") {setLastRoomId(id);}
  }, []);
  const onRoomDropped = useCallback(() => {
    setDropReason((prev) => prev ?? "dropped");
  }, []);
  const onKicked = useCallback((raw?: unknown) => {
    setDropReason(dropReasonFromKick(raw));
  }, []);
  const clearDrop = useCallback(() => {
    setDropReason(null);
  }, []);
  const takeReconnectId = useCallback((): string | null => {
    const id = reconnectJoinId(dropReason, lastRoomId);
    setDropReason(null);
    return id;
  }, [dropReason, lastRoomId]);

  return { dropReason, lastRoomId, rememberRoomId, onRoomDropped, onKicked, clearDrop, takeReconnectId };
}
