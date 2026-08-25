"use client";
import { useState, useEffect } from "react";
import { persistableNickname } from "@/lib/session-codec";

const NAME_KEY = "dagul_nickname";

export function useSession(): { nickname: string; saveNickname: (name: string) => void } {
  const [nickname, setNickname] = useState("");

  useEffect(() => {
    const stored = localStorage.getItem(NAME_KEY);
    // eslint-disable-next-line react-hooks/set-state-in-effect -- SSR 하이드레이션 후 localStorage(외부 저장소) 1회 동기화
    if (stored) {setNickname(stored);}
  }, []);

  function saveNickname(name: string): void {
    const trimmed = persistableNickname(name);
    if (trimmed !== null) {
      localStorage.setItem(NAME_KEY, trimmed);
      setNickname(trimmed);
    }
  }

  return { nickname, saveNickname };
}
