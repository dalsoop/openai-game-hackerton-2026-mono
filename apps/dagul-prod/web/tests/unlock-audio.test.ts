// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import {
  AUDIO_UNLOCK_EVENT, bindAudioUnlock, captureAudioContexts, closeCapturedAudioContexts,
  unlockGodotAudio, resetAudioUnlockForTests,
} from "@/lib/godot/unlock-audio";

function stubAudioContext(): void {
  class FakeContext {
    state = "suspended";
    resume = vi.fn().mockResolvedValue(undefined);
    close = vi.fn().mockResolvedValue(undefined);
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

  it("이미 running 이면 이벤트를 다시 보내지 않는다", () => {
    stubAudioContext();
    captureAudioContexts();
    const Ctx = window.AudioContext as unknown as new () => AudioContext;
    const ctx = new Ctx();
    Object.defineProperty(ctx, "state", { value: "running" });
    const heard: string[] = [];
    window.addEventListener(AUDIO_UNLOCK_EVENT, () => {heard.push("ok");});
    unlockGodotAudio();
    expect(heard).toEqual([]);
  });

  it("suspended 가 유지돼도 Godot 이벤트는 컨텍스트당 1회다", () => {
    stubAudioContext();
    captureAudioContexts();
    const resume = vi.fn().mockResolvedValue(undefined);
    const Ctx = window.AudioContext as unknown as new () => AudioContext;
    const ctx = new Ctx();
    Object.defineProperty(ctx, "state", { value: "suspended" });
    (ctx as AudioContext).resume = resume;
    const heard: string[] = [];
    window.addEventListener(AUDIO_UNLOCK_EVENT, () => {heard.push("ok");});
    unlockGodotAudio();
    unlockGodotAudio();
    expect(resume).toHaveBeenCalledTimes(2);
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

describe("closeCapturedAudioContexts", () => {
  it("캡처한 컨텍스트를 suspend 하고 목록을 비운다 — close 는 산 엔진을 죽인다", () => {
    stubAudioContext();
    captureAudioContexts();
    const Ctx = window.AudioContext as unknown as new () => AudioContext
      & { close: ReturnType<typeof vi.fn>; suspend: ReturnType<typeof vi.fn> };
    const ctx = new Ctx();
    ctx.close = vi.fn().mockResolvedValue(undefined);
    ctx.suspend = vi.fn().mockResolvedValue(undefined);
    closeCapturedAudioContexts();
    expect(ctx.suspend).toHaveBeenCalled();
    expect(ctx.close).not.toHaveBeenCalled();
    unlockGodotAudio();
    expect(ctx.resume).not.toHaveBeenCalled();
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
