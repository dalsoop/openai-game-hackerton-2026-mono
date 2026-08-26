// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { bindCanvasKeyboardFocus, grabCanvasKeyboard } from "@/lib/godot/canvas-focus";

afterEach(() => {
  vi.restoreAllMocks();
  Object.defineProperty(document, "visibilityState", { configurable: true, value: "visible" });
});

function fakeCanvas(): HTMLCanvasElement {
  const canvas = document.createElement("canvas");
  canvas.focus = vi.fn();
  return canvas;
}

describe("grabCanvasKeyboard", () => {
  it("보이는 탭에서는 tabIndex 를 주고 포커스한다", () => {
    const canvas = fakeCanvas();
    grabCanvasKeyboard(canvas);
    expect(canvas.tabIndex).toBe(0);
    expect(canvas.focus).toHaveBeenCalledWith({ preventScroll: true });
  });

  it("숨은 탭에서는 포커스하지 않는다", () => {
    Object.defineProperty(document, "visibilityState", { configurable: true, value: "hidden" });
    const canvas = fakeCanvas();
    grabCanvasKeyboard(canvas);
    expect(canvas.focus).not.toHaveBeenCalled();
  });
});

describe("bindCanvasKeyboardFocus", () => {
  it("window focus · visibilitychange(visible) · pointerdown 에 캔버스만 되돌린다", () => {
    const canvas = fakeCanvas();
    const stop = bindCanvasKeyboardFocus(canvas);
    (canvas.focus as ReturnType<typeof vi.fn>).mockClear();
    window.dispatchEvent(new Event("focus"));
    expect(canvas.focus).toHaveBeenCalled();
    (canvas.focus as ReturnType<typeof vi.fn>).mockClear();
    document.dispatchEvent(new Event("visibilitychange"));
    expect(canvas.focus).toHaveBeenCalled();
    (canvas.focus as ReturnType<typeof vi.fn>).mockClear();
    canvas.dispatchEvent(new Event("pointerdown"));
    expect(canvas.focus).toHaveBeenCalled();
    stop();
    (canvas.focus as ReturnType<typeof vi.fn>).mockClear();
    window.dispatchEvent(new Event("focus"));
    expect(canvas.focus).not.toHaveBeenCalled();
  });

  it("숨김 visibilitychange 에서는 포커스하지 않는다", () => {
    const canvas = fakeCanvas();
    const stop = bindCanvasKeyboardFocus(canvas);
    (canvas.focus as ReturnType<typeof vi.fn>).mockClear();
    Object.defineProperty(document, "visibilityState", { configurable: true, value: "hidden" });
    document.dispatchEvent(new Event("visibilitychange"));
    expect(canvas.focus).not.toHaveBeenCalled();
    stop();
  });
});
