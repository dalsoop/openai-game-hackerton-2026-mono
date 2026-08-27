export type EngineInstance = {
  init: (basePath: string) => Promise<unknown>;
  copyToFS: (path: string, buffer: ArrayBuffer) => void;
  start: (override: Record<string, unknown>) => Promise<void>;
  requestQuit?: () => void;
};

export function godotEngineConfig(
  canvas: HTMLCanvasElement,
  engineBase: string,
  extLibFile: string,
  wasmModule: WebAssembly.Module | null,
): Record<string, unknown> {
  const config: Record<string, unknown> = {
    canvas,
    canvasResizePolicy: 2,
    focusCanvas: true,
    executable: engineBase,
    args: ["--main-pack", "index.pck"],
    gdextensionLibs: [extLibFile],
  };
  if (!wasmModule) {return config;}
  config.instantiateWasm = (
    imports: WebAssembly.Imports,
    onDone: (inst: WebAssembly.Instance, mod: WebAssembly.Module) => void,
  ): Record<string, unknown> => {
    void WebAssembly.instantiate(wasmModule, imports).then((inst) => onDone(inst, wasmModule));
    return {};
  };
  return config;
}
