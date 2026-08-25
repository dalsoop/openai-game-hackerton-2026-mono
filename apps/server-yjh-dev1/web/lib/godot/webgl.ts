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

/** Godot 공식과 같이 webgl2 를 묻되, 더미 컨텍스트는 바로 버린다. */
export function isWebGL2Available(host: WebGLProbeHost = {}): boolean {
  if (host.createCanvas) {
    const canvas = host.createCanvas();
    const ctx = canvas.getContext("webgl2") as
      | { getExtension?: (name: string) => { loseContext?: () => void } | null }
      | null;
    ctx?.getExtension?.("WEBGL_lose_context")?.loseContext?.();
    return !!ctx;
  }
  if (typeof host.Engine?.isWebGLAvailable === "function") {
    return host.Engine.isWebGLAvailable(2);
  }
  return false;
}
