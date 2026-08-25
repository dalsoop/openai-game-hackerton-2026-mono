import { describe, expect, it } from "vitest";
import { runtimeErrorKey } from "@/lib/godot/runtime-errors";

describe("runtimeErrorKey", () => {
  it("엔진 코드는 game.errors.* 루트 키로 바꾼다 — godot 네임스페이스가 아니다", () => {
    expect(runtimeErrorKey("engine-missing")).toBe("game.errors.engineMissing");
    expect(runtimeErrorKey("engine-load-failed")).toBe("game.errors.engineLoadFailed");
    expect(runtimeErrorKey("match-signal-missing")).toBe("game.errors.matchSignalMissing");
  });

  it("모르는 코드는 번역 키로 쓰지 않는다", () => {
    expect(runtimeErrorKey("boom")).toBe("boom");
  });
});
