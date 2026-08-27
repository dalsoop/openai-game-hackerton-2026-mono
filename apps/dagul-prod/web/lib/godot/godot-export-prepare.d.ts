export const SIDE_WASM_ARTIFACTS: readonly string[];
export function glueMentionsSideWasm(src: string): boolean;
export function stripSideWasmLoader(jsPath: string): boolean;
export function assertNoSideWasmInGlue(dir: string): void;
export function unlinkSideWasmArtifacts(dir: string): string[];
export function prepareGodotExportDir(dir: string): {
  stripped: boolean;
  sideGone: string[];
  stale: string[];
};
