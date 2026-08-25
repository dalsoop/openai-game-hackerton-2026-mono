"use client";
import { useState, useEffect } from "react";

const NAME_KEY = "dagul_nickname";

export function useSession() {
  const [nickname, setNickname] = useState("");

  useEffect(() => {
    const stored = localStorage.getItem(NAME_KEY);
    if (stored) setNickname(stored);
  }, []);

  function saveNickname(name: string) {
    const trimmed = name.trim();
    if (trimmed) {
      localStorage.setItem(NAME_KEY, trimmed);
      setNickname(trimmed);
    }
  }

  return { nickname, saveNickname };
}
