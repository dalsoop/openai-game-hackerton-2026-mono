import { describe, expect, it } from "vitest";
import { runtimeErrorKey, runtimeErrorText } from "@/lib/godot/runtime-errors";

describe("runtimeErrorKey", () => {
  it("엔진 코드는 game.errors.* 루트 키로 바꾼다 — godot 네임스페이스가 아니다", () => {
    expect(runtimeErrorKey("engine-missing")).toBe("game.errors.engineMissing");
    expect(runtimeErrorKey("engine-load-failed")).toBe("game.errors.engineLoadFailed");
    expect(runtimeErrorKey("match-signal-missing")).toBe("game.errors.matchSignalMissing");
    expect(runtimeErrorKey("webgl2-missing")).toBe("game.errors.webgl2Missing");
  });

  it("모르는 코드는 번역 키로 쓰지 않는다", () => {
    expect(runtimeErrorKey("boom")).toBe("boom");
  });
});

describe("runtimeErrorText", () => {
  const t = (key: string): string => ({
    "game.errors.matchSignalMissing": "매치 신호 없음",
    "godot.startError": "게임을 시작할 수 없습니다",
  }[key] ?? key);

  it("알려진 코드는 매핑 문구 한 줄만 쓴다", () => {
    expect(runtimeErrorText("match-signal-missing", t)).toBe("매치 신호 없음");
  });

  it("빈 코드는 startError 한 줄만 쓴다 — 중복 접두 없음", () => {
    expect(runtimeErrorText("", t)).toBe("게임을 시작할 수 없습니다");
  });

  it("모르는 코드는 원문을 그대로 보여 준다", () => {
    expect(runtimeErrorText("boom", t)).toBe("boom");
  });
});
