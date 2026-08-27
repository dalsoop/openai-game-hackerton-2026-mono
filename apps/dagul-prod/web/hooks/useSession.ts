"use client";
import { useState, useEffect } from "react";
import { useLocale } from "next-intl";
import { persistableNickname } from "@/lib/session-codec";
import { WEB_STORE } from "@/lib/contract";
import {
  guestNameForLocale,
  isAutoGuestName,
  readOrCreateGuestId,
} from "@/lib/guest-identity";

const NAME_KEY = WEB_STORE.NICKNAME;
const LEGACY_NAME_KEY = "dagul_nickname";

function guestNameNow(locale: string): string {
  const id = readOrCreateGuestId();
  return id === null ? "" : guestNameForLocale(id, locale);
}

export function useSession(): {
  nickname: string;
  guestName: string;
  saveNickname: (name: string) => void;
  clearNickname: () => void;
} {
  const locale = useLocale();
  const [nickname, setNickname] = useState("");
  const [guestName, setGuestName] = useState(() => guestNameNow(locale));

  useEffect(() => {
    const nextGuest = guestNameNow(locale);
    if (nextGuest !== "") {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- 쿠키 ID 는 클라에서만 확정
      setGuestName(nextGuest);
    }
    const stored = localStorage.getItem(NAME_KEY) ?? localStorage.getItem(LEGACY_NAME_KEY);
    if (!stored) {return;}
    if (!localStorage.getItem(NAME_KEY)) {
      localStorage.setItem(NAME_KEY, stored);
      localStorage.removeItem(LEGACY_NAME_KEY);
    }
    const id = readOrCreateGuestId();
    if (id !== null && isAutoGuestName(stored, id)) {
      // 자동 닉은 로케일 번역본을 쓴다. 커스텀으로 고정하지 않는다.
      setNickname("");
      return;
    }
    setNickname(stored);
  }, [locale]);

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
