// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import {
  AUDIO_UNLOCK_EVENT, bindAudioUnlock, captureAudioContexts, unlockGodotAudio,
  resetAudioUnlockForTests,
} from "@/lib/godot/unlock-audio";

function stubAudioContext(): void {
  class FakeContext {
    state = "suspended";
    resume = vi.fn().mockResolvedValue(undefined);
  }
  Object.defineProperty(window, "AudioContext", { configurable: true, writable: true, value: FakeContext });
  Object.defineProperty(window, "__dagulAudioPatched", { configurable: true, writable: true, value: false });
}

afterEach(() => {
  resetAudioUnlockForTests();
  vi.restoreAllMocks();
});

describe("unlockGodotAudio", () => {
  it("capture 한 컨텍스트를 resume 하고 이벤트를 보낸다", () => {
    stubAudioContext();
    captureAudioContexts();
    const resume = vi.fn().mockResolvedValue(undefined);
    const Ctx = window.AudioContext as unknown as new () => AudioContext;
    const ctx = new Ctx();
    Object.defineProperty(ctx, "state", { value: "suspended" });
    (ctx as AudioContext).resume = resume;
    const heard: string[] = [];
    window.addEventListener(AUDIO_UNLOCK_EVENT, () => {heard.push("ok");}, { once: true });
    unlockGodotAudio();
    expect(resume).toHaveBeenCalled();
    expect(heard).toEqual(["ok"]);
  });
});

describe("captureAudioContexts", () => {
  it("감싼 뒤에도 instanceof AudioContext 가 유지된다", () => {
    stubAudioContext();
    captureAudioContexts();
    const Ctx = window.AudioContext as unknown as new () => AudioContext;
    const ctx = new Ctx();
    expect(ctx instanceof window.AudioContext).toBe(true);
  });
});

describe("bindAudioUnlock", () => {
  it("pointerdown · mousedown 에서 unlock 한다", () => {
    stubAudioContext();
    const canvas = document.createElement("canvas");
    captureAudioContexts();
    const Ctx = window.AudioContext as unknown as new () => AudioContext;
    const ctx = new Ctx();
    const stop = bindAudioUnlock(canvas);
    canvas.dispatchEvent(new Event("mousedown"));
    expect(ctx.resume).toHaveBeenCalled();
    stop();
  });
});
