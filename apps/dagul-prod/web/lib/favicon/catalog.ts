import type { CharacterPortrait } from "../characters/types.js";
import { signForGregorianYear, type ZodiacSign, ZODIAC_SIGNS } from "./signs.js";
import { koreanZodiacYear } from "./lunar-new-year.js";

export type FaviconSheet = {
  readonly src: string;
  readonly cols: number;
  readonly rows: number;
  readonly pixelWidth: number;
  readonly pixelHeight: number;
};

export type FaviconCell = {
  readonly col: number;
  readonly row: number;
  readonly index: number;
  readonly size: number;
};

export type FaviconSpec = {
  readonly sign: ZodiacSign;
  readonly year: number;
  readonly sheet: FaviconSheet;
  readonly cell: FaviconCell;
  readonly portrait: CharacterPortrait;
};

export const ANIMAL_FAVICON_SHEET: FaviconSheet = {
  src: "/characters/animals.png",
  cols: 4,
  rows: 3,
  pixelWidth: 1024,
  pixelHeight: 768,
};

export class KoreanZodiacFavicon {
  constructor(
    private readonly signs: readonly ZodiacSign[],
    private readonly sheet: FaviconSheet,
  ) {}

  signForYear(year: number): ZodiacSign {
    return signForGregorianYear(year);
  }

  at(instant: Date): FaviconSpec {
    const year = koreanZodiacYear(instant);
    const sign = this.signForYear(year);
    const cell = this.cellOf(sign);
    return {
      sign,
      year,
      sheet: this.sheet,
      cell,
      portrait: {
        src: this.sheet.src,
        cols: this.sheet.cols,
        rows: this.sheet.rows,
        index: cell.index,
      },
    };
  }

  cellOf(sign: ZodiacSign): FaviconCell {
    const index = sign.atlasFrame;
    const cols = this.sheet.cols;
    return {
      index,
      col: index % cols,
      row: Math.floor(index / cols),
      size: this.sheet.pixelWidth / cols,
    };
  }

  list(): readonly ZodiacSign[] {
    return this.signs;
  }
}

export const koreanZodiacFavicon = new KoreanZodiacFavicon(ZODIAC_SIGNS, ANIMAL_FAVICON_SHEET);
