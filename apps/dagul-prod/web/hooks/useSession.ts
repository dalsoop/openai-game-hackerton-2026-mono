"use client";
import { useState, useEffect } from "react";
import { persistableNickname } from "@/lib/session-codec";
import { WEB_STORE } from "@/lib/contract";
import { guestNameOf, readOrCreateGuestId } from "@/lib/guest-identity";

const NAME_KEY = WEB_STORE.NICKNAME;
const LEGACY_NAME_KEY = "dagul_nickname";

function guestNameNow(): string {
  const id = readOrCreateGuestId();
  return id === null ? "" : guestNameOf(id);
}

export function useSession(): {
  nickname: string;
  guestName: string;
  saveNickname: (name: string) => void;
  clearNickname: () => void;
} {
  const [nickname, setNickname] = useState("");
  const [guestName, setGuestName] = useState(guestNameNow);

  useEffect(() => {
    const nextGuest = guestNameNow();
    if (nextGuest !== "") {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- 쿠키 ID 는 클라에서만 확정
      setGuestName(nextGuest);
    }
    const stored = localStorage.getItem(NAME_KEY) ?? localStorage.getItem(LEGACY_NAME_KEY);
    if (stored) {
      if (!localStorage.getItem(NAME_KEY)) {
        localStorage.setItem(NAME_KEY, stored);
        localStorage.removeItem(LEGACY_NAME_KEY);
      }
      setNickname(stored);
    }
  }, []);

  function saveNickname(name: string): void {
    const trimmed = persistableNickname(name);
    if (trimmed !== null) {
      localStorage.setItem(NAME_KEY, trimmed);
      setNickname(trimmed);
    }
  }

  function clearNickname(): void {
    localStorage.removeItem(NAME_KEY);
    localStorage.removeItem(LEGACY_NAME_KEY);
    setNickname("");
  }

  return { nickname, guestName, saveNickname, clearNickname };
}
