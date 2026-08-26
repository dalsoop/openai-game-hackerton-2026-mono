export const AUDIO_UNLOCK_EVENT = "dagul-audio-unlock";

const captured: AudioContext[] = [];

type AudioWindow = Window & {
  AudioContext: typeof AudioContext;
  webkitAudioContext?: typeof AudioContext;
  __dagulAudioPatched?: boolean;
};

function wrapCtor(Orig: typeof AudioContext): typeof AudioContext {
  const Wrapped = function AudioContextWrapped(
    this: AudioContext,
    opts?: AudioContextOptions,
  ): AudioContext {
    const ctx = new Orig(opts);
    captured.push(ctx);
    return ctx;
  };
  Wrapped.prototype = Orig.prototype;
  return Wrapped as unknown as typeof AudioContext;
}

/** Godot 이 만드는 AudioContext 를 잡는다. init 보다 먼저 호출한다. */
export function captureAudioContexts(): void {
  if (typeof window === "undefined") {return;}
  const w = window as AudioWindow;
  if (w.__dagulAudioPatched) {return;}
  w.__dagulAudioPatched = true;
  if (typeof w.AudioContext === "function") {
    w.AudioContext = wrapCtor(w.AudioContext);
  }
  if (typeof w.webkitAudioContext === "function") {
    w.webkitAudioContext = wrapCtor(w.webkitAudioContext);
  }
}

export function unlockGodotAudio(): void {
  if (typeof window === "undefined") {return;}
  for (const ctx of captured) {
    if (ctx.state === "suspended") {void ctx.resume();}
  }
  window.dispatchEvent(new Event(AUDIO_UNLOCK_EVENT));
}

export function bindAudioUnlock(canvas: HTMLCanvasElement): () => void {
  const onGesture = (): void => { unlockGodotAudio(); };
  const opts: AddEventListenerOptions = { capture: true };
  window.addEventListener("pointerdown", onGesture, opts);
  window.addEventListener("keydown", onGesture, opts);
  canvas.addEventListener("pointerdown", onGesture);
  return (): void => {
    window.removeEventListener("pointerdown", onGesture, opts);
    window.removeEventListener("keydown", onGesture, opts);
    canvas.removeEventListener("pointerdown", onGesture);
  };
}
