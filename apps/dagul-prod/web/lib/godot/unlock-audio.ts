export const AUDIO_UNLOCK_EVENT = "dagul-audio-unlock";

const captured: AudioContext[] = [];

/** vitest 전용 — 캡처 목록을 비운다. */
export function resetAudioUnlockForTests(): void {
  captured.length = 0;
}

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
  let resumed = false;
  for (const ctx of captured) {
    if (ctx.state === "suspended" || ctx.state === "interrupted") {
      void ctx.resume();
      resumed = true;
    }
  }
  // WASD 키 리피트마다 이벤트를 보내면 Godot 가 BGM 을 처음부터 다시 켠다.
  if (!resumed) {return;}
  window.dispatchEvent(new Event(AUDIO_UNLOCK_EVENT));
}

const GESTURES = ["pointerdown", "mousedown", "touchstart", "keydown"] as const;

/** resume 은 제스처 핸들러 안에서만 호출한다. 엔진 start() 직후 비동기 resume 은 거절된다. */
export function bindAudioUnlock(canvas: HTMLCanvasElement): () => void {
  const onGesture = (): void => { unlockGodotAudio(); };
  const opts: AddEventListenerOptions = { capture: true };
  for (const ev of GESTURES) {
    window.addEventListener(ev, onGesture, opts);
    canvas.addEventListener(ev, onGesture);
  }
  return (): void => {
    for (const ev of GESTURES) {
      window.removeEventListener(ev, onGesture, opts);
      canvas.removeEventListener(ev, onGesture);
    }
  };
}
