// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { DOM_EVT } from "@/lib/contract";
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
  it("window focus · visibilitychange(visible) · pointerdown 에 캔버스를 되돌리고 PAGE_VISIBLE 을 낸다", () => {
    const canvas = fakeCanvas();
    const visible = vi.fn();
    window.addEventListener(DOM_EVT.PAGE_VISIBLE, visible);
    const stop = bindCanvasKeyboardFocus(canvas);
    (canvas.focus as ReturnType<typeof vi.fn>).mockClear();
    window.dispatchEvent(new Event("focus"));
    expect(canvas.focus).toHaveBeenCalled();
    expect(visible).toHaveBeenCalled();
    (canvas.focus as ReturnType<typeof vi.fn>).mockClear();
    document.dispatchEvent(new Event("visibilitychange"));
    expect(canvas.focus).toHaveBeenCalled();
    (canvas.focus as ReturnType<typeof vi.fn>).mockClear();
    canvas.dispatchEvent(new Event("pointerdown"));
    expect(canvas.focus).toHaveBeenCalled();
    stop();
    window.removeEventListener(DOM_EVT.PAGE_VISIBLE, visible);
    (canvas.focus as ReturnType<typeof vi.fn>).mockClear();
    window.dispatchEvent(new Event("focus"));
    expect(canvas.focus).not.toHaveBeenCalled();
  });

  it("window blur 와 숨김은 PAGE_HIDDEN 을 내고 포커스하지 않는다", () => {
    const canvas = fakeCanvas();
    const hidden = vi.fn();
    window.addEventListener(DOM_EVT.PAGE_HIDDEN, hidden);
    const stop = bindCanvasKeyboardFocus(canvas);
    (canvas.focus as ReturnType<typeof vi.fn>).mockClear();
    window.dispatchEvent(new Event("blur"));
    expect(hidden).toHaveBeenCalled();
    expect(canvas.focus).not.toHaveBeenCalled();
    hidden.mockClear();
    Object.defineProperty(document, "visibilityState", { configurable: true, value: "hidden" });
    document.dispatchEvent(new Event("visibilitychange"));
    expect(hidden).toHaveBeenCalled();
    expect(canvas.focus).not.toHaveBeenCalled();
    stop();
    window.removeEventListener(DOM_EVT.PAGE_HIDDEN, hidden);
  });
});
