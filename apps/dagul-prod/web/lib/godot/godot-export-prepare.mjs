import { existsSync, readFileSync, unlinkSync, writeFileSync } from "fs";
import path from "path";
import { dropStaleEncodings } from "./encoding-freshness.mjs";

const SIDE_WASM = "'dynamicLibraries': [`${loadPath}.side.wasm`].concat(this.gdextensionLibs)";
const NO_SIDE_WASM = "'dynamicLibraries': [].concat(this.gdextensionLibs)";
const SIDE_LOCATE = "\t\t\t\t} else if (path.endsWith('.side.wasm')) {\n"
  + "\t\t\t\t\treturn `${loadPath}.side.wasm`;\n"
  + "\t\t\t\t} else if (path.endsWith('.wasm')) {";
const NO_SIDE_LOCATE = "\t\t\t\t} else if (path.endsWith('.wasm')) {";
const SIDE_LOCATE_FLEX = /else if \(path\.endsWith\('\.side\.wasm'\)\) \{\s*return `\$\{loadPath\}\.side\.wasm`;\s*\}\s*/g;

export const SIDE_WASM_ARTIFACTS = [
  "index.side.wasm", "index.side.wasm.br", "index.side.wasm.gz",
];

export function glueMentionsSideWasm(src) {
  return src.includes(".side.wasm");
}

export function stripSideWasmLoader(jsPath) {
  if (!existsSync(jsPath)) {return false;}
  const src = readFileSync(jsPath, "utf8");
  let next = src;
  if (next.includes(SIDE_WASM)) {next = next.replaceAll(SIDE_WASM, NO_SIDE_WASM);}
  if (next.includes(SIDE_LOCATE)) {next = next.replaceAll(SIDE_LOCATE, NO_SIDE_LOCATE);}
  next = next.replace(SIDE_LOCATE_FLEX, "");
  next = patchAudioCtxNullGuard(next);
  if (next === src) {return false;}
  writeFileSync(jsPath, next);
  return true;
}

function patchAudioCtxNullGuard(src) {
  return src.replaceAll("GodotAudio.ctx.currentTime", "(GodotAudio.ctx?.currentTime??0)");
}

export function assertNoSideWasmInGlue(dir) {
  const jsPath = path.join(dir, "index.js");
  if (!existsSync(jsPath)) {return;}
  const src = readFileSync(jsPath, "utf8");
  if (!glueMentionsSideWasm(src)) {return;}
  throw new Error("godot-export-prepare: index.js still mentions .side.wasm — strip 패턴이 이 glue 와 맞지 않습니다");
}

export function unlinkSideWasmArtifacts(dir) {
  const gone = [];
  for (const name of SIDE_WASM_ARTIFACTS) {
    const file = path.join(dir, name);
    if (!existsSync(file)) {continue;}
    unlinkSync(file);
    gone.push(name);
  }
  return gone;
}

/** glue 패치 → side.wasm 문구 잔존 시 실패 → 산출물 제거 → 낡은 .br/.gz 삭제.
 * 압축(brotli/gzip)은 이 함수 이후에 돌려야 한다. */
export function prepareGodotExportDir(dir) {
  const stripped = stripSideWasmLoader(path.join(dir, "index.js"));
  assertNoSideWasmInGlue(dir);
  const sideGone = unlinkSideWasmArtifacts(dir);
  const stale = dropStaleEncodings(dir);
  return { stripped, sideGone, stale };
}
