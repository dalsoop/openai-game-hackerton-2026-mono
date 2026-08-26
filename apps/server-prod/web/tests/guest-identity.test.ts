import { describe, expect, it } from "vitest";
import { ZODIAC_NAMES } from "@/lib/hub/config";
import {
  cookieWritePair,
  guestNameOf,
  mintGuestId,
  parseGuestId,
  readCookie,
} from "@/lib/guest-identity";
import { WEB_STORE } from "@/lib/contract";

describe("parseGuestId", () => {
  it("양의 정수만 받는다", () => {
    expect(parseGuestId("482193")).toBe(482193);
    expect(parseGuestId("0")).toBeNull();
    expect(parseGuestId("-3")).toBeNull();
    expect(parseGuestId("12.5")).toBeNull();
    expect(parseGuestId("")).toBeNull();
    expect(parseGuestId(undefined)).toBeNull();
  });
});

describe("guestNameOf", () => {
  it("십이지신을 쿠키 ID 로 고른다", () => {
    expect(guestNameOf(0)).toBe("쥐#0");
    expect(guestNameOf(2)).toBe("호랑이#2");
    expect(guestNameOf(12)).toBe("쥐#12");
    expect(guestNameOf(8)).toBe("원숭이#8");
  });

  it("목록 길이는 12", () => {
    expect(ZODIAC_NAMES).toHaveLength(12);
  });
});

describe("mintGuestId", () => {
  it("6자리 구간", () => {
    expect(mintGuestId(() => 0)).toBe(100_000);
    expect(mintGuestId(() => 899_999)).toBe(999_999);
  });
});

describe("cookie read/write", () => {
  it("해당 키만 읽는다", () => {
    expect(readCookie(WEB_STORE.GUEST_ID, "a=1; gangup_uid=482193; b=2")).toBe("482193");
    expect(readCookie(WEB_STORE.GUEST_ID, "other=1")).toBeNull();
  });

  it("쓰기 쌍에 Path 와 Max-Age 가 있다", () => {
    const pair = cookieWritePair(WEB_STORE.GUEST_ID, "482193");
    expect(pair.startsWith("gangup_uid=482193")).toBe(true);
    expect(pair.includes("Path=/")).toBe(true);
    expect(pair.includes("Max-Age=")).toBe(true);
  });
});
