// Godot 4.7 공식 WebGL 검사와 같은 계약.
// docs.godotengine.org/en/4.7/tutorials/platform/web/customizing_html5_shell.html
// Engine.isWebGLAvailable(major) — 더미 캔버스에 getContext. 게임 캔버스는 쓰지 않는다.

export interface GodotEngineApi {
  isWebGLAvailable?: (majorVersion?: number) => boolean;
}

export interface WebGLProbeHost {
  Engine?: GodotEngineApi;
  createCanvas?: () => { getContext: (id: string) => unknown };
}

/** Godot 공식: major 2 → getContext("webgl2"). 엔진이 있으면 그 API를 우선한다. */
export function isWebGL2Available(host: WebGLProbeHost = {}): boolean {
  if (typeof host.Engine?.isWebGLAvailable === "function") {
    return host.Engine.isWebGLAvailable(2);
  }
  const canvas = host.createCanvas?.();
  if (!canvas) {return false;}
  return !!canvas.getContext("webgl2");
}
