// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  applyDevicePixelRatioCap,
  DPR_CAP_STORAGE_KEY,
  restoreDevicePixelRatio,
} from "@/lib/godot/dpr-cap";

const store = new Map<string, string>();

function setNativeDpr(value: number): void {
  Object.defineProperty(window, "devicePixelRatio", {
    configurable: true,
    enumerable: true,
    writable: true,
    value,
  });
}

beforeEach(() => {
  store.clear();
  vi.stubGlobal("sessionStorage", {
    setItem: (k: string, v: string): void => { store.set(k, v); },
    getItem: (k: string): string | null => store.get(k) ?? null,
    removeItem: (k: string): void => { store.delete(k); },
    clear: (): void => { store.clear(); },
  });
  setNativeDpr(2);
});

afterEach(() => {
  restoreDevicePixelRatio();
  restoreDevicePixelRatio();
  vi.unstubAllGlobals();
});

describe("devicePixelRatio cap", () => {
  it("기본 cap 1 이면 레티나 2 를 1 로 묶는다", () => {
    applyDevicePixelRatioCap();
    expect(window.devicePixelRatio).toBe(1);
  });

  it("sessionStorage dagul.dprCap=2 면 원상 복귀 실험이 된다", () => {
    store.set(DPR_CAP_STORAGE_KEY, "2");
    applyDevicePixelRatioCap();
    expect(window.devicePixelRatio).toBe(2);
  });

  it("해제하면 원래 게터(값)를 되돌린다", () => {
    applyDevicePixelRatioCap();
    expect(window.devicePixelRatio).toBe(1);
    restoreDevicePixelRatio();
    expect(window.devicePixelRatio).toBe(2);
  });

  it("숫자가 아닌 저장 값은 기본 1 로 본다", () => {
    store.set(DPR_CAP_STORAGE_KEY, "nope");
    applyDevicePixelRatioCap();
    expect(window.devicePixelRatio).toBe(1);
  });
});
