// @vitest-environment jsdom
import { act, renderHook } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { DOM_EVT } from "@/lib/contract";
import { lastInboundSnapOf, rememberInboundSnap, resetInboundSnapForTests } from "@/lib/hub/page-bridge";
import { useGodotMatch } from "@/hooks/useGodotMatch";

vi.mock("@/lib/godot/runtime", () => ({
  GodotRuntime: {
    for: (): {
      snapshot: { state: string; progress: number; bytesLoaded: number; bytesTotal: number; error: string | null };
      subscribe: (cb: (s: unknown) => void) => () => void;
      boot: () => Promise<void>;
      quit: () => void;
    } => ({
      snapshot: { state: "idle", progress: 0, bytesLoaded: 0, bytesTotal: 0, error: null },
      subscribe: () => (): void => {},
      boot: vi.fn(async () => {}),
      quit: vi.fn(),
    }),
  },
}));

vi.mock("@/lib/godot/canvas-focus", () => ({
  lockPlayViewport: (): (() => void) => (): void => {},
}));

afterEach(() => {
  resetInboundSnapForTests();
});

describe("useGodotMatch MATCH_END", () => {
  it("종료 상세를 고정한 뒤 lastInboundSnap 을 비운다", () => {
    rememberInboundSnap({ tick: 4, winner: 1, result: "won" });
    const onMatchEnd = vi.fn();
    renderHook(() => useGodotMatch({
      game: "dagul",
      matchInfo: { roomId: "r1", name: "host", slot: 0, resumeToken: "t" },
      visible: false,
      onMatchEnd,
    }));
    act(() => {
      window.dispatchEvent(new CustomEvent(DOM_EVT.MATCH_END, { detail: {} }));
    });
    expect(onMatchEnd).toHaveBeenCalledWith({
      winner: 1,
      result: "won",
      snap: { tick: 4, winner: 1, result: "won" },
    });
    expect(lastInboundSnapOf()).toBeNull();
  });
});
