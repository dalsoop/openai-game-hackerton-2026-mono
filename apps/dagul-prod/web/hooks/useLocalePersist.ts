"use client";
import { useEffect } from "react";

/** 선택한 로케일을 sessionStorage 에 남겨, 새로고침 후에도 같은 언어로 뜨게 한다. */
export function useLocalePersist(locale: string): void {
  useEffect(() => {
    try {sessionStorage.setItem("dagul_locale", locale);} catch { /* quota */ }
  }, [locale]);
}
