/** 한국 설날(양력 월·일). 값 = month * 100 + day. 서울 날짜 기준으로 쓴다. */
const SEOLLAL_MD: Readonly<Record<number, number>> = {
  2000: 205, 2001: 124, 2002: 212, 2003: 201, 2004: 122,
  2005: 209, 2006: 129, 2007: 218, 2008: 207, 2009: 126,
  2010: 214, 2011: 203, 2012: 123, 2013: 210, 2014: 131,
  2015: 219, 2016: 208, 2017: 128, 2018: 216, 2019: 205,
  2020: 125, 2021: 212, 2022: 201, 2023: 122, 2024: 210,
  2025: 129, 2026: 217, 2027: 206, 2028: 126, 2029: 213,
  2030: 203, 2031: 123, 2032: 211, 2033: 131, 2034: 219,
  2035: 208, 2036: 128, 2037: 215, 2038: 204, 2039: 124,
  2040: 212,
};

export const SEOUL_TZ = "Asia/Seoul";

export type CivilDate = { readonly year: number; readonly month: number; readonly day: number };

export function seoulCivilDate(instant: Date): CivilDate {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: SEOUL_TZ,
    year: "numeric",
    month: "numeric",
    day: "numeric",
  }).formatToParts(instant);
  const num = (type: Intl.DateTimeFormatPartTypes): number => {
    const raw = parts.find((p) => p.type === type)?.value ?? "0";
    return Number(raw);
  };
  return { year: num("year"), month: num("month"), day: num("day") };
}

export function seollalOf(year: number): CivilDate | undefined {
  if (!Object.hasOwn(SEOLLAL_MD, year)) {return undefined;}
  const packed = SEOLLAL_MD[year];
  return { year, month: Math.floor(packed / 100), day: packed % 100 };
}

export function isBeforeSeollal(date: CivilDate, seollal: CivilDate): boolean {
  if (date.month !== seollal.month) {return date.month < seollal.month;}
  return date.day < seollal.day;
}

/** 그 시각의 한국 띠 연도. 설날 전이면 이전 해. 표 밖 연도는 그 해 1월 1일부터. */
export function koreanZodiacYear(instant: Date): number {
  const date = seoulCivilDate(instant);
  const seollal = seollalOf(date.year);
  if (seollal !== undefined && isBeforeSeollal(date, seollal)) {return date.year - 1;}
  return date.year;
}
