#!/usr/bin/env node
// Godot 산출물 버전 매니페스트 생성.
// version = 빌드 시각(yymmddhhmmss). 단, 산출물 내용(filesHash)이 이전과
// 같으면 버전을 유지한다 — 재빌드가 돌아도 결과가 같으면 ?v= URL 이
// 바뀌지 않아 브라우저 불변 캐시가 그대로 살아 있다(빌드 1회 효과).
// 내용이 달라진 경우에만 새 타임스탬프로 버전이 올라간다.
import { createHash } from "crypto";
import { existsSync, readFileSync, writeFileSync } from "fs";
import path from "path";

const outDir = process.argv[2];
const sourceHash = process.argv[3] || "";
if (!outDir) {
  console.error("사용법: gen-godot-manifest.mjs <godot-export-dir> [sourceHash]");
  process.exit(1);
}

const files = ["index.js", "index.wasm", "index.pck"].filter((f) =>
  existsSync(path.join(outDir, f)),
);
if (files.length < 3) {
  console.error("gen-godot-manifest: index.js/wasm/pck 이 없습니다 (side.wasm 은 쓰지 않습니다)");
  process.exit(1);
}
const hash = createHash("sha1");
for (const f of files) hash.update(readFileSync(path.join(outDir, f)));
const filesHash = hash.digest("hex").slice(0, 12);

const stamp = (d) =>
  [d.getFullYear() % 100, d.getMonth() + 1, d.getDate(), d.getHours(), d.getMinutes(), d.getSeconds()]
    .map((n) => String(n).padStart(2, "0"))
    .join("");

// 이전 매니페스트와 내용이 같으면 버전(타임스탬프)을 그대로 계승한다.
let prev = null;
try {
  prev = JSON.parse(readFileSync(path.join(outDir, "manifest.json"), "utf8"));
} catch { /* 첫 빌드 */ }

let version;
if (prev && prev.filesHash === filesHash && prev.version) {
  version = prev.version; // 산출물 동일 — 캐시 유지
} else {
  version = stamp(new Date());
  // 같은 초에 내용이 다른 재빌드면 버전이 겹친다 — 1초씩 밀어서 유일성 확보.
  while (prev && prev.version === version && prev.filesHash !== filesHash) {
    version = stamp(new Date(Date.now() + 1000));
    prev = { ...prev, version }; // 가드 1회면 충분하다 (연속 재빌드는 드묾)
  }
}

const body = { version, filesHash, files };
if (sourceHash) {
  body.sourceHash = sourceHash;
} else if (prev && prev.sourceHash) {
  body.sourceHash = prev.sourceHash;
}
writeFileSync(
  path.join(outDir, "manifest.json"),
  JSON.stringify(body, null, 2) + "\n",
);
console.log(`manifest: version=${version} filesHash=${filesHash}${sourceHash ? ` sourceHash=${sourceHash}` : ""}${prev && prev.filesHash === filesHash ? " (변경 없음 — 버전 유지)" : ""}`);
