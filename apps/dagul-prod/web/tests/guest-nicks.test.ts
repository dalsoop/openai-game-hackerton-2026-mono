import { describe, expect, it } from "vitest";
import { HUB_CONFIG } from "@/lib/hub/config";
import { parsePlayerName } from "@/lib/hub/room-options";
import { MESSAGE_PACKS, zodiacNamesOf } from "@/lib/i18n/message-packs";
import { DEFAULT_LOCALE, LOCALES } from "@/i18n/locales";
import {
  guestNameForLocale,
  guestNameOf,
  isAutoGuestName,
  zodiacNamesFor,
} from "@/lib/guest-identity";

const KO_NICKS = [
  "다굴맨",
  "실망한 중대장",
  "너굴맨",
  "댕댕이",
  "마포구 오함마",
  "화성갈꺼니까",
  "옥황상제",
] as const;

const EN_NICKS = [
  "DagulMan",
  "Sad Major",
  "NurglMan",
  "Doge",
  "Mapo Hammer",
  "OffToMars",
  "JadeEmperor",
] as const;

const FULL = (nick: string, id: number): string => `${nick}#${id}`;

describe("게스트 닉 목록 정본", () => {
  it("한국어 일곱 개가 메시지 팩과 같다", () => {
    expect(MESSAGE_PACKS.ko.guest.nicks).toEqual([...KO_NICKS]);
  });

  it("영어 일곱 개가 메시지 팩과 같다", () => {
    expect(MESSAGE_PACKS.en.guest.nicks).toEqual([...EN_NICKS]);
  });

  it("로케일마다 개수가 같고 중복·빈 값이 없다", () => {
    expect(KO_NICKS).toHaveLength(EN_NICKS.length);
    for (const locale of LOCALES) {
      const nicks = MESSAGE_PACKS[locale].guest.nicks;
      expect(nicks.length, locale).toBe(KO_NICKS.length);
      expect(new Set(nicks).size, locale).toBe(nicks.length);
      for (const nick of nicks) {
        expect(nick.trim(), locale).toBe(nick);
        expect(nick.length, `${locale} ${nick}`).toBeGreaterThan(0);
      }
    }
  });

  it("zodiacNamesOf 는 그 목록을 그대로 돌려준다", () => {
    expect(zodiacNamesOf("ko")).toEqual([...KO_NICKS]);
    expect(zodiacNamesFor("en")).toEqual([...EN_NICKS]);
    expect(zodiacNamesOf("ja")).toEqual(zodiacNamesOf(DEFAULT_LOCALE));
  });
});

describe("게스트 닉 순환", () => {
  it("쿠키 ID 나머지로 한국어 목록을 한 바퀴 돈다", () => {
    KO_NICKS.forEach((nick, i) => {
      expect(guestNameOf(i)).toBe(FULL(nick, i));
    });
    expect(guestNameOf(KO_NICKS.length)).toBe(FULL(KO_NICKS[0], KO_NICKS.length));
  });

  it("영어 로케일은 같은 칸의 영어 별명을 붙인다", () => {
    EN_NICKS.forEach((nick, i) => {
      expect(guestNameForLocale(i, "en")).toBe(FULL(nick, i));
    });
    expect(guestNameForLocale(1, "ko")).toBe("실망한 중대장#1");
    expect(guestNameForLocale(5, "ko")).toBe("화성갈꺼니까#5");
    expect(guestNameForLocale(6, "en")).toBe("JadeEmperor#6");
  });

  it("없는 로케일은 기본 로케일로 폴백한다", () => {
    expect(guestNameForLocale(0, "ja")).toBe(guestNameForLocale(0, DEFAULT_LOCALE));
  });

  it("목록이 비면 숫자만 남긴다", () => {
    expect(guestNameOf(3, [])).toBe("#3");
  });

  it("음수 ID 도 목록 안에서 고른다", () => {
    expect(guestNameOf(-1)).toBe(FULL(KO_NICKS[KO_NICKS.length - 1], -1));
  });
});

describe("자동 닉 판정", () => {
  it("현재 별명은 그 ID 칸과 맞을 때만 자동이다", () => {
    KO_NICKS.forEach((nick, i) => {
      expect(isAutoGuestName(FULL(nick, i), i)).toBe(true);
    });
    EN_NICKS.forEach((nick, i) => {
      expect(isAutoGuestName(FULL(nick, i), i)).toBe(true);
    });
  });

  it("옛 동물명 닉도 같은 ID 면 자동이다", () => {
    expect(isAutoGuestName("쥐#12", 12)).toBe(true);
    expect(isAutoGuestName("Rat#12", 12)).toBe(true);
  });

  it("칸이 다른 별명·커스텀은 자동이 아니다", () => {
    expect(isAutoGuestName(FULL(KO_NICKS[0], 1), 1)).toBe(false);
    expect(isAutoGuestName("Alice", 0)).toBe(false);
    expect(isAutoGuestName("쥐#99", 12)).toBe(false);
    expect(isAutoGuestName("", 0)).toBe(false);
  });
});

describe("게스트 닉 길이", () => {
  it("모든 로케일 별명+#999999 가 이름 한도 안이다", () => {
    for (const locale of LOCALES) {
      for (const nick of MESSAGE_PACKS[locale].guest.nicks) {
        const full = FULL(nick, 999_999);
        expect(full.length, `${locale} ${full}`).toBeLessThanOrEqual(HUB_CONFIG.maxNameLength);
        expect(parsePlayerName(full, HUB_CONFIG.maxNameLength, "x")).toBe(full);
      }
    }
  });
});
