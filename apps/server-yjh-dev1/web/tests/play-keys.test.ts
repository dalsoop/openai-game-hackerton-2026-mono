// @vitest-environment jsdom
import { describe, expect, it, vi } from "vitest";
import { bindPlayKeyGuard, PLAY_KEY_CODES, shouldBlockIme } from "@/lib/godot/play-keys";

describe("shouldBlockIme", () => {
  it("자리 KeyW 는 글자가 w 여도 막는다", () => {
    expect(shouldBlockIme({ code: "KeyW", key: "w" })).toBe(true);
  });

  it("자리 KeyW 는 한글 ㅈ이어도 막는다", () => {
    expect(shouldBlockIme({ code: "KeyW", key: "ㅈ" })).toBe(true);
  });

  it("AZERTY 자리 KeyW(글자 z) 는 막는다", () => {
    expect(shouldBlockIme({ code: "KeyW", key: "z" })).toBe(true);
  });

  it("AZERTY 글자 w(자리 KeyZ) 는 이동 키가 아니다", () => {
    expect(shouldBlockIme({ code: "KeyZ", key: "w" })).toBe(false);
  });

  it("IME 조합 중이면 자리와 무관하게 막는다", () => {
    expect(shouldBlockIme({ code: "KeyK", isComposing: true })).toBe(true);
    expect(shouldBlockIme({ code: "Unidentified", keyCode: 229 })).toBe(true);
    expect(shouldBlockIme({ code: "Unidentified", key: "Process" })).toBe(true);
  });

  it("채팅 입력창은 막지 않는다", () => {
    const input = document.createElement("input");
    expect(shouldBlockIme({ code: "KeyW", key: "w", target: input })).toBe(false);
  });

  it("게임 자리 목록은 WASD·QERF·Shift·Space·Tab 이다", () => {
    for (const code of ["KeyW", "KeyA", "KeyS", "KeyD", "KeyQ", "KeyE", "KeyR", "KeyF", "ShiftLeft", "Space", "Tab"]) {
      expect(PLAY_KEY_CODES.has(code)).toBe(true);
    }
  });
});

describe("bindPlayKeyGuard", () => {
  it("window 캡처에서 KeyW 의 keydown 을 preventDefault 한다", () => {
    const canvas = document.createElement("canvas");
    document.body.appendChild(canvas);
    canvas.tabIndex = 0;
    canvas.focus();
    const stop = bindPlayKeyGuard(canvas);
    const ev = new KeyboardEvent("keydown", { code: "KeyW", key: "ㅈ", bubbles: true, cancelable: true });
    window.dispatchEvent(ev);
    expect(ev.defaultPrevented).toBe(true);
    stop();
    canvas.remove();
  });

  it("Tab 은 막고 캔버스로 포커스를 되돌린다", () => {
    const canvas = document.createElement("canvas");
    canvas.focus = vi.fn();
    document.body.appendChild(canvas);
    const stop = bindPlayKeyGuard(canvas);
    const ev = new KeyboardEvent("keydown", { code: "Tab", key: "Tab", bubbles: true, cancelable: true });
    window.dispatchEvent(ev);
    expect(ev.defaultPrevented).toBe(true);
    expect(canvas.focus).toHaveBeenCalledWith({ preventScroll: true });
    stop();
    canvas.remove();
  });

  it("다른 자리 글자는 막지 않는다", () => {
    const canvas = document.createElement("canvas");
    document.body.appendChild(canvas);
    const stop = bindPlayKeyGuard(canvas);
    const ev = new KeyboardEvent("keydown", { code: "KeyK", key: "k", bubbles: true, cancelable: true });
    window.dispatchEvent(ev);
    expect(ev.defaultPrevented).toBe(false);
    stop();
    canvas.remove();
  });
});
