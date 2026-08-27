import { closeCapturedAudioContexts } from "./unlock-audio";

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

export function disposeGodotEngine(
  engine: Quitable | null,
  canvas: HTMLCanvasElement | null,
): void {
  if (engine?.requestQuit) {
    try { engine.requestQuit(); } catch { /* 이미 종료됨 */ }
  }
  loseCanvasWebGL(canvas);
  closeCapturedAudioContexts();
}
