import { describe, expect, it, vi, beforeEach } from "vitest";
import { HANDOFF } from "@/lib/hub/config";
import { persistEngineHandoff } from "@/lib/godot/runtime";

describe("persistEngineHandoff", () => {
  const store = new Map<string, string>();

  beforeEach(() => {
    store.clear();
    vi.stubGlobal("localStorage", {
      setItem: (k: string, v: string): void => { store.set(k, v); },
      getItem: (k: string): string | null => store.get(k) ?? null,
      removeItem: (k: string): void => { store.delete(k); },
      clear: (): void => { store.clear(); },
    });
  });

  it("재부팅용 START 본문을 gangup_match 에 다시 심는다", () => {
    persistEngineHandoff("dagul", {
      roomId: "r1",
      name: "호스트",
      slot: 0,
      resumeToken: "tok",
      match: { you: 0, host: true, seed: 7, mode: "full", seats: [] },
    });
    expect(store.get(HANDOFF.MATCH)).toContain("\"seed\":7");
    expect(store.get(HANDOFF.GAME)).toBe("dagul");
    expect(store.get(HANDOFF.RESUME)).toBe("tok");
  });
});
