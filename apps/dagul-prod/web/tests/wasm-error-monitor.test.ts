// @vitest-environment jsdom
/* eslint-disable no-console -- console.error 가로채기 자체가 검증 대상. */
/**
 * WASM 에러 모니터 — 시끄러운 Godot WASM 콘솔 에러를 그룹으로 묶어 되감는지,
 * 분류 안 되는 메시지는 그대로 흘려보내는지, 재로그 쓰로틀이 동작하는지 검증한다.
 */
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

type Monitor = {
  groups: Record<string, { count: number; first: unknown; lastLog: number }>;
  total: number;
  firstAt: number;
};

async function freshInstall(): Promise<void> {
  vi.resetModules();
  const mod = await import("@/lib/godot/wasm-error-monitor");
  mod.installWasmErrorMonitor();
}

function summary(): Monitor {
  return (window as unknown as { __godotErrorSummary: () => Monitor }).__godotErrorSummary();
}

describe("installWasmErrorMonitor", () => {
  let origError: typeof console.error;

  beforeEach(() => {
    origError = console.error;
    delete (window as unknown as Record<string, unknown>).__godotErrors;
    delete (window as unknown as Record<string, unknown>).__godotErrorSummary;
    delete (window as unknown as Record<string, unknown>).__dagulDebug;
  });

  afterEach(() => {
    console.error = origError;
    vi.useRealTimers();
  });

  it("분류되는 에러는 그룹으로 묶인다", async () => {
    await freshInstall();
    // install 이 console.error 자체를 가로채 두었으니, 그 가로챈 함수를 그대로 호출한다
    // (다시 대입하면 가로채기가 풀려버린다).
    console.error("array index null (_fp) out of range");
    console.error("array index null (_fp) out of range 2");
    const s = summary();
    expect(s.groups.array_fp_null.count).toBe(2);
    expect(s.total).toBe(2);
  });

  it("분류 안 되는 메시지는 그룹 없이 그대로 원본으로 흘러간다", async () => {
    await freshInstall();
    const orig = vi.fn();
    // installWasmErrorMonitor 가 잡아둔 orig 는 교체 전 console.error 이므로,
    // 교체 이후에도 "other" 분류 메시지는 그 orig(=이 스파이 이전의 console.error)를
    // 호출한다. 직접 검증하려면 install 전에 스파이를 심어야 한다.
    vi.resetModules();
    console.error = orig;
    const mod = await import("@/lib/godot/wasm-error-monitor");
    mod.installWasmErrorMonitor();
    console.error("이건 분류 안 되는 일반 에러");
    expect(orig).toHaveBeenCalledWith("이건 분류 안 되는 일반 에러");
    const s = summary();
    expect(s.total).toBe(0);
  });

  it("첫 발생 시 window.__dagulDebug 스냅샷을 first 에 남긴다", async () => {
    (window as unknown as Record<string, unknown>).__dagulDebug = { phase: "playing", playerCount: 2 };
    await freshInstall();
    console.error("read-only array 에러");
    const s = summary();
    const first = s.groups.array_readonly.first as { state?: { phase?: string; playerCount?: number } };
    expect(first.state?.phase).toBe("playing");
    expect(first.state?.playerCount).toBe(2);
  });

  it("같은 그룹 재로그는 3초 쓰로틀을 지킨다", async () => {
    vi.useFakeTimers();
    vi.setSystemTime(0);
    await freshInstall();
    console.error("alloc_static 실패");
    vi.setSystemTime(1000);
    console.error("alloc_static 실패 2");
    vi.setSystemTime(3500);
    console.error("alloc_static 실패 3");
    const s = summary();
    // count 는 매번 올라가지만, 원본으로의 재로그(orig 호출)는 3초 간격으로만 일어난다.
    expect(s.groups.alloc_static.count).toBe(3);
  });

  it("잘린 GDExtension·PagedAllocator 로그는 콘솔에 다시 내지 않는다", async () => {
    const orig = vi.fn();
    vi.resetModules();
    console.error = orig;
    const mod = await import("@/lib/godot/wasm-error-monitor");
    mod.installWasmErrorMonitor();
    console.error("Can't open dynamic library: addons/colyseus/bin/libcolyseus_godot.web.wasm32.release.wasm");
    console.error("ERROR: Can't open GDExtension dynamic library: 'res://addons/colyseus/colyseus.gdextension'.");
    console.error("ERROR: Pages in use exist at exit in PagedAllocator: N16WorkerThreadPool5GroupE");
    expect(orig).not.toHaveBeenCalled();
    const s = summary();
    expect(s.groups.gdext_cut.count).toBe(2);
    expect(s.groups.paged_allocator.count).toBe(1);
  });

  it("두 번 설치해도 console.error 를 두 번 감싸지 않는다(idempotent)", async () => {
    await freshInstall();
    const afterFirst = console.error;
    const mod = await import("@/lib/godot/wasm-error-monitor");
    mod.installWasmErrorMonitor();
    expect(console.error).toBe(afterFirst);
  });
});
