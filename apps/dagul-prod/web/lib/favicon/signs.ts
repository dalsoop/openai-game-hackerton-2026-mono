/** 한국 12지 띠. animal 은 게임 12지 인덱스, atlasFrame 은 시트 칸. */

export type ZodiacId =
  | "rat" | "ox" | "tiger" | "rabbit"
  | "dragon" | "snake" | "horse" | "goat"
  | "monkey" | "rooster" | "dog" | "pig";

export type ZodiacSign = {
  readonly id: ZodiacId;
  readonly animal: number;
  readonly atlasFrame: number;
  readonly titleKey: string;
};

/**
 * 아틀라스 칸 — 원본 hud_pjh.gd ANIMAL_ATLAS_FRAME.
 * 용·뱀만 시트 순서와 12지가 뒤바뀌어 있다.
 */
export const ANIMAL_ATLAS_FRAME = [0, 1, 2, 3, 5, 4, 6, 7, 8, 9, 10, 11] as const;

const IDS: readonly ZodiacId[] = [
  "rat", "ox", "tiger", "rabbit", "dragon", "snake",
  "horse", "goat", "monkey", "rooster", "dog", "pig",
];

export const ZODIAC_SIGNS: readonly ZodiacSign[] = IDS.map((id, animal) => ({
  id,
  animal,
  atlasFrame: ANIMAL_ATLAS_FRAME[animal],
  titleKey: `favicon.zodiac.${id}`,
}));

export const ZODIAC_COUNT = 12;

/** 서기 연도 → 띠. 쥐해 기준 연도 4 (2020=쥐, 2026=말). */
export function signForGregorianYear(year: number): ZodiacSign {
  const animal = ((year - 4) % ZODIAC_COUNT + ZODIAC_COUNT) % ZODIAC_COUNT;
  return ZODIAC_SIGNS[animal];
}
