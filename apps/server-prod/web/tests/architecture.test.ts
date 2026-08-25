// 아키텍처 계약 테스트 — lint 규칙과 같은 계약을 소스 스캔으로 이중 검증한다.
// lint 설정이 실수로 풀려도 이 테스트가 지킨다.
import { readFileSync, readdirSync, statSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";

const ROOT = process.cwd();

function walk(dir: string, pred: (name: string) => boolean, out: string[] = []): string[] {
  for (const name of readdirSync(dir)) {
    if (name === "node_modules" || name === ".next" || name === "dist" || name === "public" || name.startsWith(".")) {continue;}
    const full = join(dir, name);
    let st;
    try {st = statSync(full);} catch {continue;} // CI 산출물 깨진 링크 — 소스 스캔 대상 아님
    if (st.isDirectory()) {walk(full, pred, out);}
    else if (pred(name)) {out.push(full);}
  }
  return out;
}

const tsSources = walk(ROOT, (n) => /\.(ts|tsx)$/.test(n));
const rel = (p: string): string => p.slice(ROOT.length + 1);
const sourceOf = (p: string): string => readFileSync(p, "utf8");

const HOOK_CALL = /\buse(?:Effect|State|Ref|Callback|Memo)\s*\(/;

describe("계약: 렌더 전용 계층", () => {
  it("components·page.tsx 에는 상태/이펙트 훅이 없다", () => {
    const renderLayer = tsSources.filter((p) => rel(p).startsWith("components/") || /app\/.*page\.tsx$/.test(rel(p)));
    const offenders = renderLayer.filter((p) => HOOK_CALL.test(sourceOf(p)));
    expect(offenders.map(rel), "뷰 계층에 훅 발견 — hooks/ 어댑터로 이동").toEqual([]);
  });

  it("상태/이펙트 훅은 hooks/ 에서만 호출한다", () => {
    // 예외: Next 에러 경계는 프레임워크가 useEffect 로깅을 요구한다(공식 패턴)
    const frameworkException = (r: string): boolean =>
      r.startsWith("app/") && (r.endsWith("error.tsx") || r.endsWith("global-error.tsx"));
    const offenders = tsSources.filter((p) => {
      const r = rel(p);
      if (r.startsWith("hooks/") || r.startsWith("tests/") || frameworkException(r)) {return false;}
      return HOOK_CALL.test(sourceOf(p));
    });
    expect(offenders.map(rel), "hooks/ 밖에서 훅 호출").toEqual([]);
  });
});

describe("계약: 문구 SSOT", () => {
  const HANGUL = /["'`][^"'`]*[가-힣][^"'`]*["'`]/;

  it("한글 리터럴은 config(KO)·서버 안내문 정본 외에 없다", () => {
    const allowed = (r: string): boolean =>
      r.startsWith("tests/") || r === "lib/hub/config.ts" || r.startsWith("messages/");
    const offenders = tsSources.filter((p) => {
      const r = rel(p);
      if (allowed(r)) {return false;}
      return sourceOf(p).split("\n").some((line) => {
        const trimmed = line.trimStart();
        if (trimmed.startsWith("//") || trimmed.startsWith("*") || trimmed.startsWith("/*")) {return false;}
        return HANGUL.test(line.split("//")[0]);
      });
    });
    expect(offenders.map(rel), "하드코딩 한글 — messages/*.json 또는 KO 상수로").toEqual([]);
  });
});

describe("계약: i18n 키 전수 실존", () => {
  const ko = JSON.parse(readFileSync(join(ROOT, "messages/ko.json"), "utf8")) as Record<string, unknown>;

  const flatten = (obj: Record<string, unknown>, prefix = ""): string[] =>
    Object.entries(obj).flatMap(([k, v]) =>
      typeof v === "object" && v !== null ? flatten(v as Record<string, unknown>, `${prefix}${k}.`) : [`${prefix}${k}`],
    );
  const known = new Set(flatten(ko));

  const isDynamicKey = (key: string): boolean => key.includes("${");
  const resolveKey = (key: string, namespaces: string[]): string[] =>
    [key, ...namespaces.filter(Boolean).map((ns) => `${ns}.${key}`)];

  it("소스의 t(\"...\") 키는 전부 ko.json 에 실재한다", () => {
    // useTranslations("ns") 네임스페이스 상대 키를 반영해 판정한다
    const missingKeysOfFile = (p: string): string[] => {
      const src = sourceOf(p);
      if (!/\bt\(/.test(src)) {return [];}
      const namespaces = [
        ...src.matchAll(/useTranslations\(\s*["']([^"']*)["']\s*\)/g),
        ...src.matchAll(/getTranslations\(\s*\{[^}]*namespace:\s*["']([^"']*)["']/g),
      ].map((m) => m[1]);
      return missingKeysOfSource(src, namespaces).map((key) => `${rel(p)}: ${key}`);
    };
    const missingKeysOfSource = (src: string, namespaces: string[]): string[] =>
      [...src.matchAll(/\bt\(\s*["']([^"']+)["']/g)]
        .map((m) => m[1])
        .filter((key) => !isDynamicKey(key))
        .filter((key) => !resolveKey(key, namespaces).some((k) => known.has(k)));
    const missing = tsSources.flatMap(missingKeysOfFile);
    expect(missing, "ko.json 에 없는 키 — 런타임에서 깨진다").toEqual([]);
  });
});

describe("계약: 방 만들기는 별도 페이지", () => {
  const createPage = join(ROOT, "app/[locale]/create/page.tsx");
  const lobbySrc = sourceOf(join(ROOT, "components/Lobby.tsx"));

  it("create 라우트가 있다", () => {
    expect(tsSources.some((p) => rel(p) === "app/[locale]/create/page.tsx")).toBe(true);
    expect(sourceOf(createPage)).toContain("CreateRoom");
  });

  it("로비는 생성 폼을 두지 않고 /create 로만 보낸다", () => {
    expect(lobbySrc).toContain('href="/create"');
    expect(lobbySrc).not.toMatch(/name=["']game["']/);
    expect(lobbySrc).not.toMatch(/name=["']title["']/);
    expect(lobbySrc).not.toMatch(/\bonCreate\b/);
  });
});

describe("계약: E2E 는 Godot 공식 WebGL2 검사를 한다", () => {
  it("e2e-dagul 은 Engine.isWebGLAvailable(2) 를 쓰고 게임 캔버스에 getContext 하지 않는다", () => {
    const e2e = sourceOf(join(ROOT, "scripts/e2e-dagul.mjs"));
    expect(e2e).toContain("isWebGLAvailable(2)");
    expect(e2e).not.toMatch(/getElementById\(['"]godot-canvas['"]\)[\s\S]{0,80}getContext\(['"]webgl2['"]\)/);
  });
});

describe("계약: GameId 는 웹 산출물 경로가 아니다", () => {
  const banned = /\/godot\/\$\{(?:game|gameId|game\.id)/;

  it("lib·hooks·scripts 는 GameId 로 /godot/ 경로를 만들지 않는다", () => {
    const listing = sourceOf(join(ROOT, "lib/games/listing.ts"));
    const runtime = sourceOf(join(ROOT, "lib/godot/runtime.ts"));
    expect(listing).toContain("packOf");
    expect(runtime).toContain("packOf");
    expect(runtime).not.toMatch(/assetPlanOf\(game\)/);
    const roots = ["lib/", "hooks/", "scripts/"];
    const offenders = tsSources
      .concat(walk(ROOT, (n) => /\.(mjs|sh)$/.test(n)))
      .filter((p) => roots.some((r) => rel(p).startsWith(r)))
      .filter((p) => banned.test(sourceOf(p)));
    expect(offenders.map(rel)).toEqual([]);
  });

  it("배치 스크립트는 카탈로그 pack 리더를 쓴다", () => {
    const publish = sourceOf(join(ROOT, "scripts/publish-godot-assets.mjs"));
    const prepare = sourceOf(join(ROOT, "scripts/prepare-godot-assets.sh"));
    expect(publish).toContain("readCatalogPacks");
    expect(publish).not.toMatch(/public\/godot\/dagul/);
    expect(prepare).toContain("publish-godot-assets.mjs");
    expect(prepare).not.toMatch(/godot\/dagul/);
    const devSh = sourceOf(join(ROOT, "..", "dev.sh"));
    expect(devSh).toContain("publish-godot-assets.mjs");
    expect(devSh).not.toMatch(/godot\/dagul/);
  });
});
