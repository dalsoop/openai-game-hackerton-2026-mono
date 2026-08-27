// 로케일 → 메시지 팩. routing.locales 와 1:1 이어야 한다.
// 언어를 늘리면 messages/{locale}.json 을 만들고 여기 import 를 한 줄 추가한다.
import ko from "../../messages/ko.json";
import en from "../../messages/en.json";
import { DEFAULT_LOCALE, type AppLocale } from "../../i18n/locales";
import { ZODIAC_SIGNS } from "../favicon/signs";

export type MessagePack = typeof ko;
export type { AppLocale };

export const MESSAGE_PACKS = {
  ko,
  en,
} as const satisfies Record<AppLocale, MessagePack>;

export function messagePackOf(locale: string): MessagePack {
  if (locale in MESSAGE_PACKS) {
    return MESSAGE_PACKS[locale as AppLocale];
  }
  return MESSAGE_PACKS[DEFAULT_LOCALE];
}

function namesFromBag(bag: Record<string, string>): readonly string[] {
  return ZODIAC_SIGNS.map((sign) => bag[sign.id]);
}

/** 게스트 닉 — 캐릭터/파비콘 동물명과 분리. */
export function zodiacNamesOf(locale: string): readonly string[] {
  return messagePackOf(locale).guest.nicks;
}

/** 현재 닉 + 옛 동물명 닉. 자동 닉 판정에 쓴다. */
export function allZodiacNameTables(): readonly (readonly string[])[] {
  return Object.values(MESSAGE_PACKS).flatMap((pack) => [
    pack.guest.nicks,
    namesFromBag(pack.favicon.zodiac),
  ]);
}
