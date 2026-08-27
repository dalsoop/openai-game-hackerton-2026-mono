import { describe, expect, it, vi, beforeEach } from "vitest";
import { HANDOFF } from "@/lib/hub/config";
import { persistEngineHandoff, clearEngineHandoff } from "@/lib/godot/runtime";

describe("persistEngineHandoff", () => {
  const store = new Map<string, string>();

  beforeEach(() => {
    store.clear();
    // 핸드오프는 탭 스코프(sessionStorage)가 계약이다 — localStorage 로 되돌리면
    // 다른 탭이 재접속 토큰을 주워 진행 중 게임이 리셋된다 (2026-08-26 버그).
    vi.stubGlobal("sessionStorage", {
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

  it("match 가 없으면 이전 MATCH 잔존을 지운다", () => {
    store.set(HANDOFF.MATCH, "{\"seed\":1}");
    persistEngineHandoff("dagul", {
      roomId: "r1",
      name: "호스트",
      slot: 0,
      resumeToken: "tok",
    });
    expect(store.has(HANDOFF.MATCH)).toBe(false);
    expect(store.get(HANDOFF.FROM_HUB)).toBe("1");
  });

  it("clearEngineHandoff 는 FROM_HUB·MATCH 를 지우고 resume 은 선택이다", () => {
    store.set(HANDOFF.FROM_HUB, "1");
    store.set(HANDOFF.MATCH, "{}");
    store.set(HANDOFF.RESUME, "tok");
    clearEngineHandoff();
    expect(store.has(HANDOFF.FROM_HUB)).toBe(false);
    expect(store.has(HANDOFF.MATCH)).toBe(false);
    expect(store.get(HANDOFF.RESUME)).toBe("tok");
    clearEngineHandoff(true);
    expect(store.has(HANDOFF.RESUME)).toBe(false);
  });
});
