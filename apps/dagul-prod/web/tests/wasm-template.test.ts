import { describe, expect, it } from "vitest";
import { wasmHasDylinkSection } from "@/lib/godot/wasm-template.mjs";

describe("wasmHasDylinkSection", () => {
  it("선두에 dylink custom section 이 있으면 dlink 템플릿이다", () => {
    const head = Buffer.concat([
      Buffer.from([0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x00, 0x0c]),
      Buffer.from("dylink.0"),
    ]);
    expect(wasmHasDylinkSection(head)).toBe(true);
  });

  it("type section 으로 시작하면 dlink 가 아니다", () => {
    const head = Buffer.from([0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0xba]);
    expect(wasmHasDylinkSection(head)).toBe(false);
  });
});
