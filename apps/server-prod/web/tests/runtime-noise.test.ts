import { describe, expect, it, vi } from "vitest";
import {
  installRuntimeNoiseFilter,
  isUncheckedRuntimeLastError,
} from "@/lib/helpers/runtime-noise";

describe("isUncheckedRuntimeLastError", () => {
  it("Chrome lastError 문구만 잡는다", () => {
    expect(isUncheckedRuntimeLastError(
      "Unchecked runtime.lastError: The message port closed before a response was received.",
    )).toBe(true);
    expect(isUncheckedRuntimeLastError(
      "The message port closed before a response was received.",
    )).toBe(true);
    expect(isUncheckedRuntimeLastError("WebSocket is closed")).toBe(false);
    expect(isUncheckedRuntimeLastError("engine-missing")).toBe(false);
  });
});

describe("installRuntimeNoiseFilter", () => {
  it("해당 문구는 error·warn 을 삼킨다", () => {
    const error = vi.fn();
    const warn = vi.fn();
    const c = { error, warn } as unknown as Console;
    const listeners = new Map<string, EventListener>();
    const target = {
      addEventListener: (type: string, cb: EventListener): void => {
        listeners.set(type, cb);
      },
      removeEventListener: (type: string): void => {
        listeners.delete(type);
      },
    };
    const undo = installRuntimeNoiseFilter(c, target);
    c.error("Unchecked runtime.lastError: The message port closed before a response was received.");
    c.warn("The message port closed before a response was received.");
    c.error("engine-missing");
    expect(error).toHaveBeenCalledTimes(1);
    expect(error).toHaveBeenCalledWith("engine-missing");
    expect(warn).not.toHaveBeenCalled();

    const ev = {
      message: "Unchecked runtime.lastError",
      error: "",
      preventDefault: vi.fn(),
      stopImmediatePropagation: vi.fn(),
    };
    listeners.get("error")?.(ev as unknown as Event);
    expect(ev.preventDefault).toHaveBeenCalled();
    undo();
    expect(c.error).toBe(error);
  });
});
