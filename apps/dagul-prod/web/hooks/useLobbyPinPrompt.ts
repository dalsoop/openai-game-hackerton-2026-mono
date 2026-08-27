import { useEffect, useState } from "react";
import type { HubRoom } from "@/types";

export function useLobbyPinPrompt(): {
  query: string;
  setQuery: (q: string) => void;
  pwRoom: HubRoom | null;
  pwDraft: string;
  setPwDraft: (pin: string) => void;
  openPin: (room: HubRoom) => void;
  closePin: () => void;
  takePin: () => { id: string; password: string } | null;
} {
  const [query, setQuery] = useState("");
  const [pwRoom, setPwRoom] = useState<HubRoom | null>(null);
  const [pwDraft, setPwDraft] = useState("");

  useEffect(() => {
    if (!pwRoom) {return;}
    const onKey = (e: KeyboardEvent): void => {
      if (e.key === "Escape") {
        setPwRoom(null);
        setPwDraft("");
      }
    };
    window.addEventListener("keydown", onKey);
    return (): void => {window.removeEventListener("keydown", onKey);};
  }, [pwRoom]);

  return {
    query,
    setQuery,
    pwRoom,
    pwDraft,
    setPwDraft,
    openPin: (room: HubRoom): void => {
      setPwRoom(room);
      setPwDraft("");
    },
    closePin: (): void => {
      setPwRoom(null);
      setPwDraft("");
    },
    takePin: (): { id: string; password: string } | null => {
      if (!pwRoom) {return null;}
      const next = { id: pwRoom.id, password: pwDraft };
      setPwRoom(null);
      setPwDraft("");
      return next;
    },
  };
}
