export const AUDIO_UNLOCK_EVENT = "dagul-audio-unlock";

const captured: AudioContext[] = [];

type AudioWindow = Window & {
  AudioContext: typeof AudioContext;
  webkitAudioContext?: typeof AudioContext;
  __dagulAudioPatched?: boolean;
};

function wrapCtor(Orig: typeof AudioContext): typeof AudioContext {
  // Godot 은 `ctx instanceof AudioContext` 를 본다. 새 인스턴스를 다른
  // 생성자로 바꿔 주면 그 검사가 깨져 웹에서 소리가 전부 죽는다.
  class Wrapped extends Orig {
    constructor(opts?: AudioContextOptions) {
      super(opts);
      captured.push(this);
    }
  }
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
