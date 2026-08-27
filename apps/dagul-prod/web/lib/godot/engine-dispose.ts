import { closeAudioContexts, snapshotCapturedAudioContexts } from "./unlock-audio";

type Quitable = { requestQuit?: () => void };

/** Godot 이 붙인 WebGL 컨텍스트를 버려 다음 부팅이 같은 캔버스·한도 안에서 살게 한다. */
export function loseCanvasWebGL(canvas: HTMLCanvasElement | null): void {
  if (!canvas) {return;}
  try {
    const gl = canvas.getContext("webgl2") ?? canvas.getContext("webgl");
    const ext = gl?.getExtension("WEBGL_lose_context") as { loseContext?: () => void } | null;
    ext?.loseContext?.();
  } catch {
    /* jsdom · 이미 잃은 컨텍스트 */
  }
}

/** requestQuit 뒤에도 엔진은 다음 프레임까지 산다 — 그 전에 컨텍스트를 닫으면
 * SampleNode 가 closed 컨텍스트의 currentTime 을 읽다 크래시하고, teardown 이
 * 끊겨 WASM 힙이 잔존한다. 정리는 exited(onExit) 이후로 미루고, 그 사이 새
 * 엔진이 만든 컨텍스트는 스냅샷 밖이라 건드리지 않는다. */
export function disposeGodotEngine(
  engine: Quitable | null,
  canvas: HTMLCanvasElement | null,
  exited?: Promise<void> | null,
): void {
  const doomed = snapshotCapturedAudioContexts();
  if (engine?.requestQuit) {
    try { engine.requestQuit(); } catch { /* 이미 종료됨 */ }
  }
  const cleanup = (): void => {
    loseCanvasWebGL(canvas);
    closeAudioContexts(doomed);
  };
  if (!engine || !exited) {
    cleanup();
    return;
  }
  const timeout = new Promise<void>((resolve) => { setTimeout(resolve, 1500); });
  void Promise.race([exited, timeout]).then(cleanup);
}
