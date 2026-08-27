// @vitest-environment jsdom
import { act, renderHook, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import { NextIntlClientProvider } from "next-intl";
import type { ReactNode } from "react";
import { useSession } from "@/hooks/useSession";
import { WEB_STORE } from "@/lib/contract";
import { cookieWritePair, guestNameForLocale } from "@/lib/guest-identity";
import { MESSAGE_PACKS } from "@/lib/i18n/message-packs";
import type { AppLocale } from "@/i18n/locales";

const GUEST_ID = 7;

function wrap(locale: AppLocale) {
  return function Wrapper({ children }: { children: ReactNode }): ReactNode {
    return (
      <NextIntlClientProvider locale={locale} messages={MESSAGE_PACKS[locale]}>
        {children}
      </NextIntlClientProvider>
    );
  };
}

function setGuestCookie(id: number): void {
  document.cookie = cookieWritePair(WEB_STORE.GUEST_ID, String(id));
}

function clearCookies(): void {
  for (const part of document.cookie.split(";")) {
    const name = part.split("=")[0]?.trim();
    if (name) {document.cookie = `${name}=; Path=/; Max-Age=0`;}
  }
}

afterEach(() => {
  localStorage.clear();
  clearCookies();
});

describe("useSession 게스트 닉", () => {
  it("저장본이 없으면 로케일 게스트 닉을 쓴다", () => {
    setGuestCookie(GUEST_ID);
    const { result } = renderHook(() => useSession(), { wrapper: wrap("ko") });
    expect(result.current.nickname).toBe("");
    expect(result.current.guestName).toBe(guestNameForLocale(GUEST_ID, "ko"));
    expect(result.current.guestName).toBe("다굴맨#7");
  });

  it("영어 로케일은 영어 게스트 닉을 쓴다", () => {
    setGuestCookie(GUEST_ID);
    const { result } = renderHook(() => useSession(), { wrapper: wrap("en") });
    expect(result.current.guestName).toBe(guestNameForLocale(GUEST_ID, "en"));
    expect(result.current.guestName).toBe("DagulMan#7");
  });

  it("저장된 자동 닉은 커스텀으로 고정하지 않는다", async () => {
    setGuestCookie(GUEST_ID);
    localStorage.setItem(WEB_STORE.NICKNAME, guestNameForLocale(GUEST_ID, "ko"));
    const { result } = renderHook(() => useSession(), { wrapper: wrap("en") });
    await waitFor(() => {
      expect(result.current.guestName).toBe("DagulMan#7");
    });
    expect(result.current.nickname).toBe("");
  });

  it("커스텀 닉은 로케일과 무관하게 유지한다", async () => {
    setGuestCookie(GUEST_ID);
    localStorage.setItem(WEB_STORE.NICKNAME, "한스");
    const { result } = renderHook(() => useSession(), { wrapper: wrap("en") });
    await waitFor(() => {
      expect(result.current.nickname).toBe("한스");
    });
    expect(result.current.guestName).toBe("DagulMan#7");
  });

  it("옛 키에 있는 닉을 현재 키로 옮긴다", async () => {
    setGuestCookie(GUEST_ID);
    localStorage.setItem("dagul_nickname", "한스");
    const { result } = renderHook(() => useSession(), { wrapper: wrap("ko") });
    await waitFor(() => {
      expect(result.current.nickname).toBe("한스");
    });
    expect(localStorage.getItem(WEB_STORE.NICKNAME)).toBe("한스");
    expect(localStorage.getItem("dagul_nickname")).toBeNull();
  });

  it("saveNickname 은 공백 이름이면 저장하지 않는다", () => {
    setGuestCookie(GUEST_ID);
    const { result } = renderHook(() => useSession(), { wrapper: wrap("ko") });
    act(() => {result.current.saveNickname("   ");});
    expect(localStorage.getItem(WEB_STORE.NICKNAME)).toBeNull();
    expect(result.current.nickname).toBe("");
  });
});
