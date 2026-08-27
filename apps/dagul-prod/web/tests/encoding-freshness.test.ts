import {
  mkdtempSync, rmSync, writeFileSync, existsSync, utimesSync, readFileSync,
} from "fs";
import { tmpdir } from "os";
import { join } from "path";
import { afterEach, describe, expect, it } from "vitest";
import {
  dropStaleEncodings,
  encodingIsCurrent,
  listStaleEncodings,
  rawNameFromEncoded,
  shouldCopyName,
  shouldPublishEncoding,
  staleEncodingReason,
} from "@/lib/godot/encoding-freshness.mjs";
import { encodingIsCurrent as serveEncodingIsCurrent } from "@/lib/godot/serve-encoding";
import { prepareGodotExportDir } from "@/lib/godot/godot-export-prepare.mjs";
import { publishPack } from "../scripts/publish-godot-assets.mjs";

describe("encodingIsCurrent 정본 일치", () => {
  it("serve 와 pipeline 이 같은 판정이다", () => {
    expect(encodingIsCurrent(null, 100)).toBe(serveEncodingIsCurrent(null, 100));
    expect(encodingIsCurrent(200, 100)).toBe(serveEncodingIsCurrent(200, 100));
    expect(encodingIsCurrent(100, 100)).toBe(serveEncodingIsCurrent(100, 100));
    expect(encodingIsCurrent(100, 150)).toBe(serveEncodingIsCurrent(100, 150));
  });
});

describe("shouldPublishEncoding", () => {
  it("원본이 없으면 고아라서 발행하지 않는다", () => {
    expect(shouldPublishEncoding(null, 100)).toBe(false);
  });

  it("압축본이 원본보다 오래되면 발행하지 않는다", () => {
    expect(shouldPublishEncoding(200, 100)).toBe(false);
    expect(shouldPublishEncoding(100, 100)).toBe(true);
    expect(shouldPublishEncoding(100, 150)).toBe(true);
  });
});

describe("rawNameFromEncoded", () => {
  it("br/gz 접미사만 벗긴다", () => {
    expect(rawNameFromEncoded("index.js.br")).toBe("index.js");
    expect(rawNameFromEncoded("index.wasm.gz")).toBe("index.wasm");
    expect(rawNameFromEncoded("index.js")).toBeNull();
  });
});

describe("디렉터리 스캔", () => {
  const dirs: string[] = [];
  afterEach(() => {
    for (const dir of dirs) {rmSync(dir, { recursive: true, force: true });}
    dirs.length = 0;
  });

  function scratch(): string {
    const dir = mkdtempSync(join(tmpdir(), "enc-fresh-"));
    dirs.push(dir);
    return dir;
  }

  function touch(file: string, body: string, at: Date): void {
    writeFileSync(file, body);
    utimesSync(file, at, at);
  }

  it("낡은 .br 를 stale 로 표시하고 지운다", () => {
    const dir = scratch();
    const old = new Date("2026-01-01T00:00:00Z");
    const now = new Date("2026-08-27T12:00:00Z");
    touch(join(dir, "index.js"), "new glue", now);
    touch(join(dir, "index.js.br"), "old glue", old);
    expect(staleEncodingReason(dir, "index.js.br")).toBe("stale");
    expect(listStaleEncodings(dir)).toEqual(["index.js.br"]);
    expect(shouldCopyName(dir, "index.js.br")).toBe(false);
    expect(dropStaleEncodings(dir)).toEqual(["index.js.br"]);
    expect(existsSync(join(dir, "index.js.br"))).toBe(false);
    expect(existsSync(join(dir, "index.js"))).toBe(true);
  });

  it("원본과 같거나 더 새면 유지한다", () => {
    const dir = scratch();
    const t = new Date("2026-08-27T12:00:00Z");
    touch(join(dir, "index.wasm"), "wasm", t);
    touch(join(dir, "index.wasm.br"), "br", t);
    expect(staleEncodingReason(dir, "index.wasm.br")).toBeNull();
    expect(shouldCopyName(dir, "index.wasm.br")).toBe(true);
    expect(dropStaleEncodings(dir)).toEqual([]);
    expect(existsSync(join(dir, "index.wasm.br"))).toBe(true);
  });

  it("원본 없는 압축본은 고아로 지운다", () => {
    const dir = scratch();
    writeFileSync(join(dir, "index.side.wasm.br"), "orphan");
    expect(staleEncodingReason(dir, "index.side.wasm.br")).toBe("orphan");
    dropStaleEncodings(dir);
    expect(existsSync(join(dir, "index.side.wasm.br"))).toBe(false);
  });
});

describe("prepareGodotExportDir", () => {
  const dirs: string[] = [];
  afterEach(() => {
    for (const dir of dirs) {rmSync(dir, { recursive: true, force: true });}
    dirs.length = 0;
  });

  it("glue 를 끊고 side.wasm 과 낡은 압축본을 같이 지운다", () => {
    const dir = mkdtempSync(join(tmpdir(), "godot-prep-"));
    dirs.push(dir);
    const old = new Date("2026-01-01T00:00:00Z");
    const glue = "'dynamicLibraries': [`${loadPath}.side.wasm`].concat(this.gdextensionLibs);\n"
      + "\t\t\t\t} else if (path.endsWith('.side.wasm')) {\n"
      + "\t\t\t\t\treturn `${loadPath}.side.wasm`;\n"
      + "\t\t\t\t} else if (path.endsWith('.wasm')) {";
    writeFileSync(join(dir, "index.js"), glue);
    writeFileSync(join(dir, "index.side.wasm"), "side");
    writeFileSync(join(dir, "index.side.wasm.br"), "side-br");
    writeFileSync(join(dir, "index.js.br"), "old-js-br");
    utimesSync(join(dir, "index.js.br"), old, old);
    const result = prepareGodotExportDir(dir);
    expect(result.stripped).toBe(true);
    expect(result.sideGone).toEqual(["index.side.wasm", "index.side.wasm.br"]);
    expect(result.stale).toContain("index.js.br");
    const js = readFileSync(join(dir, "index.js"), "utf8");
    expect(js).not.toContain("[`${loadPath}.side.wasm`]");
    expect(js).not.toContain("path.endsWith('.side.wasm')");
    expect(existsSync(join(dir, "index.js.br"))).toBe(false);
    expect(existsSync(join(dir, "index.side.wasm"))).toBe(false);
  });

  it("strip 이 못 지운 .side.wasm 문구가 남으면 실패하고 산출물은 남긴다", () => {
    const dir = mkdtempSync(join(tmpdir(), "godot-prep-fail-"));
    dirs.push(dir);
    writeFileSync(join(dir, "index.js"), "Module.fetch('index.side.wasm')");
    writeFileSync(join(dir, "index.side.wasm"), "side");
    expect(() => prepareGodotExportDir(dir)).toThrow(/side\.wasm/);
    expect(existsSync(join(dir, "index.side.wasm"))).toBe(true);
  });
});

describe("publishPack", () => {
  const dirs: string[] = [];
  afterEach(() => {
    for (const dir of dirs) {rmSync(dir, { recursive: true, force: true });}
    dirs.length = 0;
  });

  it("낡은 .br 를 dest 에 복사하지 않는다", () => {
    const src = mkdtempSync(join(tmpdir(), "godot-src-"));
    const dest = mkdtempSync(join(tmpdir(), "godot-dest-"));
    dirs.push(src, dest);
    const old = new Date("2026-01-01T00:00:00Z");
    const now = new Date("2026-08-27T12:00:00Z");
    writeFileSync(join(src, "index.js"), "patched");
    writeFileSync(join(src, "index.wasm"), "wasm");
    writeFileSync(join(src, "index.pck"), "pck");
    writeFileSync(join(src, "manifest.json"), "{}");
    writeFileSync(join(src, "index.js.br"), "stale-glue");
    utimesSync(join(src, "index.js"), now, now);
    utimesSync(join(src, "index.js.br"), old, old);
    publishPack(src, dest, { link: false });
    expect(existsSync(join(dest, "index.js"))).toBe(true);
    expect(existsSync(join(dest, "index.js.br"))).toBe(false);
    expect(readFileSync(join(dest, "index.js"), "utf8")).toBe("patched");
  });
});
