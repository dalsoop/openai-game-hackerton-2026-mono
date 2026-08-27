import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import {
  ANIMAL_ATLAS_FRAME, cropPngCell, koreanZodiacFavicon, koreanZodiacYear, pngRgba, seollalOf,
  signForGregorianYear,
} from "@/lib/favicon";

describe("한국 띠 파비콘", () => {
  it("서기 연도는 쥐=2020, 용=2024, 말=2026 이다", () => {
    expect(signForGregorianYear(2020).id).toBe("rat");
    expect(signForGregorianYear(2024).id).toBe("dragon");
    expect(signForGregorianYear(2025).id).toBe("snake");
    expect(signForGregorianYear(2026).id).toBe("horse");
  });

  it("용·뱀은 시트 칸이 12지 순서와 다르다", () => {
    expect(ANIMAL_ATLAS_FRAME[4]).toBe(5);
    expect(ANIMAL_ATLAS_FRAME[5]).toBe(4);
    expect(koreanZodiacFavicon.cellOf(signForGregorianYear(2024)).index).toBe(5);
    expect(koreanZodiacFavicon.cellOf(signForGregorianYear(2025)).index).toBe(4);
  });

  it("2026 설날 전에는 뱀, 당일부터 말이다", () => {
    expect(seollalOf(2026)).toEqual({ year: 2026, month: 2, day: 17 });
    expect(koreanZodiacYear(new Date("2026-02-16T14:59:00Z"))).toBe(2025);
    expect(koreanZodiacYear(new Date("2026-02-16T15:00:00Z"))).toBe(2026);
    expect(koreanZodiacFavicon.at(new Date("2026-02-16T14:59:00Z")).sign.id).toBe("snake");
    expect(koreanZodiacFavicon.at(new Date("2026-08-27T03:00:00Z")).sign.id).toBe("horse");
  });

  it("시트 칸은 4열이고 말은 2행 3열이다", () => {
    const spec = koreanZodiacFavicon.at(new Date("2026-08-27T03:00:00Z"));
    expect(spec.cell).toEqual({ index: 6, col: 2, row: 1, size: 256 });
    expect(spec.portrait.src).toBe("/characters/animals.png");
    expect(spec.portrait.index).toBe(6);
  });

  it("12지 객체가 12개이고 titleKey 를 가진다", () => {
    expect(koreanZodiacFavicon.list()).toHaveLength(12);
    expect(signForGregorianYear(2026).titleKey).toBe("favicon.zodiac.horse");
  });

  it("잘라 낸 파비콘 모서리는 투명하다", () => {
    const spec = koreanZodiacFavicon.at(new Date("2026-08-27T03:00:00Z"));
    const sheet = readFileSync(join(process.cwd(), "public", "characters", "animals.png"));
    const png = cropPngCell(sheet, spec.sheet, spec.cell);
    const decoded = pngRgba(png);
    expect(decoded.width).toBe(256);
    expect(decoded.height).toBe(256);
    expect(decoded.rgba[3]).toBe(0);
    expect(decoded.rgba[decoded.rgba.length - 1]).toBe(0);
  });
});
