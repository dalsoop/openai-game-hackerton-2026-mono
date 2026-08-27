import { describe, expect, it } from "vitest";
import {
  ITEM_WIRE_CASES, packItemField, packItemStack, unpackItemStack, unpackMedkits,
} from "@/lib/hub/match-item-wire";

describe("item 와이어 SSOT", () => {
  it("ITEM_WIRE_CASES 왕복", () => {
    for (const row of ITEM_WIRE_CASES) {
      expect(packItemStack(row.kind, row.count)).toBe(row.wire);
      const unpacked = unpackItemStack(row.wire);
      if (row.wire === "") {
        expect(unpacked).toEqual({ kind: "", count: 0 });
        continue;
      }
      expect(unpacked).toEqual({ kind: row.kind, count: row.count });
    }
  });

  it("packItemField 는 medkit 스택 별칭이다", () => {
    expect(packItemField(0)).toBe("");
    expect(packItemField(1)).toBe("medkit");
    expect(packItemField(3)).toBe("medkit:3");
    expect(unpackMedkits("medkit:3")).toBe(3);
    expect(unpackMedkits("spring")).toBe(0);
  });
});
