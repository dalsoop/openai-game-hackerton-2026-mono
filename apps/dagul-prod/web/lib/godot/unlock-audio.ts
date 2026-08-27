export const AUDIO_UNLOCK_EVENT = "dagul-audio-unlock";

const captured: AudioContext[] = [];
const resumeIssued = new WeakSet<AudioContext>();

/** vitest 전용 — 캡처 목록을 비운다. */
export function resetAudioUnlockForTests(): void {
  captured.length = 0;
}

/** 지금까지 잡힌 컨텍스트의 스냅샷 — 종료 지연 정리 때 "옛 엔진 몫"을 고정한다. */
export function snapshotCapturedAudioContexts(): AudioContext[] {
  return [...captured];
}

/** 스냅샷만 잠재운다 — 그 사이 새 엔진이 만든 컨텍스트는 건드리지 않는다.
 * close 는 금지: StrictMode 이중 이펙트로 산 엔진의 컨텍스트가 닫히면, Godot 이
 * 총성 샘플을 pause 하는 순간 null 참조로 메인 루프가 통째로 죽는다(실측).
 * suspend 는 처리 정지 효과는 같고, 산 엔진이 잡아도 resume 으로 복구된다. */
export function closeAudioContexts(list: readonly AudioContext[]): void {
  for (const ctx of list) {
    const at = captured.indexOf(ctx);
    if (at >= 0) {captured.splice(at, 1);}
    if (ctx.state === "closed") {continue;}
    try { void ctx.suspend(); } catch { /* 이미 닫힘 */ }
  }
}

/** 엔진 종료 때 컨텍스트를 잠재워 WASD·제스처마다 쌓이던 resume 대상을 비운다. */
export function closeCapturedAudioContexts(): void {
  closeAudioContexts(snapshotCapturedAudioContexts());
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
  let firstResume = false;
  for (const ctx of captured) {
    if (ctx.state !== "suspended" && ctx.state !== "interrupted") {continue;}
    // resume 은 제스처마다 다시 걸 수 있다. Godot 재시작 이벤트는 컨텍스트당 1회.
    void ctx.resume();
    if (!resumeIssued.has(ctx)) {
      resumeIssued.add(ctx);
      firstResume = true;
    }
  }
  if (!firstResume) {return;}
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
