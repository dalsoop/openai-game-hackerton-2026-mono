"use client";
import { useState, useEffect } from "react";
import { persistableNickname } from "@/lib/session-codec";
import { WEB_STORE } from "@/lib/contract";

const NAME_KEY = WEB_STORE.NICKNAME;
const LEGACY_NAME_KEY = "dagul_nickname";

export function useSession(): { nickname: string; saveNickname: (name: string) => void; clearNickname: () => void } {
  const [nickname, setNickname] = useState("");

  useEffect(() => {
    const stored = localStorage.getItem(NAME_KEY) ?? localStorage.getItem(LEGACY_NAME_KEY);
    if (stored) {
      if (!localStorage.getItem(NAME_KEY)) {
        localStorage.setItem(NAME_KEY, stored);
        localStorage.removeItem(LEGACY_NAME_KEY);
      }
      // eslint-disable-next-line react-hooks/set-state-in-effect -- SSR 하이드레이션 후 localStorage 1회 동기화
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

  return { nickname, saveNickname, clearNickname };
}
