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

describe("계약: 오토로드는 /root 노드", () => {
  it("셸·게임 모듈은 엔진 싱글톤 API 로 오토로드를 찾지 않는다", () => {
    const files = [
      join(ROOT, "..", "project", "core/shell/match_shell.gd"),
      join(ROOT, "..", "project", "games/dagul/game.gd"),
    ];
    const code = files.map((p) => sourceOf(p).split("\n").filter((line) => !line.trimStart().startsWith("#")).join("\n")).join("\n");
    expect(code).toContain('get_node_or_null("/root/GameState")');
    expect(code).toContain('get_node_or_null("/root/Audio")');
    expect(code).not.toMatch(/Engine\.get_singleton\("(GameState|Audio|NetworkManager)"\)/);
  });
});

describe("계약: 웹 캔버스 키 포커스", () => {
  it("런타임은 알탭 복귀용 bindCanvasKeyboardFocus 를 붙인다", () => {
    const runtime = sourceOf(join(ROOT, "lib/godot/runtime.ts"));
    expect(runtime).toContain("bindCanvasKeyboardFocus");
    expect(runtime).toContain("focusCanvas: true");
    expect(sourceOf(join(ROOT, "lib/godot/canvas-focus.ts"))).toContain("visibilitychange");
    expect(sourceOf(join(ROOT, "lib/godot/canvas-focus.ts"))).toContain("PAGE_HIDDEN");
    expect(sourceOf(join(ROOT, "lib/godot/canvas-focus.ts"))).toContain("bindPlayKeyGuard");
    expect(sourceOf(join(ROOT, "lib/godot/play-keys.ts"))).toContain("event.code");
    expect(sourceOf(join(ROOT, "..", "project", "core/input/layout_keys.gd"))).toContain("is_physical_key_pressed");
    expect(sourceOf(join(ROOT, "..", "project", "core/input/layout_keys.gd"))).not.toContain("is_key_pressed");
    expect(sourceOf(join(ROOT, "..", "project", "core/shell/match_shell.gd"))).toContain("HeldInputScript.release_all");
  });
});

describe("계약: E2E 는 Godot 공식 WebGL2 검사를 한다", () => {
  it("e2e-dagul 은 Engine.isWebGLAvailable(2) 를 쓰고 게임 캔버스에 getContext 하지 않는다", () => {
    const e2e = sourceOf(join(ROOT, "scripts/e2e-dagul.mjs"));
    expect(e2e).toContain("isWebGLAvailable(2)");
    expect(e2e).not.toMatch(/getElementById\(['"]godot-canvas['"]\)[\s\S]{0,80}getContext\(['"]webgl2['"]\)/);
  });

  it("e2e 는 Godot 의 matchmake/reconnect 를 감시한다", () => {
    const e2e = sourceOf(join(ROOT, "scripts/e2e-dagul.mjs"));
    expect(e2e).toContain("/matchmake/reconnect");
    expect(e2e).toContain("reconnectHits");
    expect(e2e).toContain("__e2eJsReconnect");
    expect(e2e).toContain("godotOwned");
  });
});

describe("계약: 허브 소켓 주인은 React", () => {
  it("Godot NetworkManager 는 Colyseus reconnect 를 호출하지 않는다", () => {
    const src = sourceOf(join(ROOT, "..", "project", "core/autoload/network_manager.gd"))
      .split("\n")
      .filter((line) => !line.trimStart().startsWith("#"))
      .join("\n");
    expect(src).not.toMatch(/\.reconnect\s*\(/);
    expect(src).not.toContain("Colyseus.Client");
    expect(src).toContain("EVT_FROM_ENGINE");
    expect(src).toContain("EVT_TO_ENGINE");
  });

  it("반전: START 경로가 leaveOnceForHandoff 로 좌석을 넘기면 실패한다", () => {
    const src = sourceOf(join(ROOT, "hooks/useGameRoom.ts"));
    expect(src).not.toContain("leaveOnceForHandoff");
    expect(src).toContain("HANDOFF.MATCH");
    expect(src).toContain("HANDOFF.FROM_HUB");
  });

  it("브릿지 부착은 onMessage 를 쌓지 않는다", () => {
    expect(sourceOf(join(ROOT, "lib/hub/page-bridge.ts"))).not.toContain("onMessage");
    expect(sourceOf(join(ROOT, "hooks/usePageBridge.ts"))).toContain("useRoomMessage");
  });
});

describe("계약: 정적 이미지는 JPEG 금지", () => {
  const JPEG_REF = /\.(?:jpg|jpeg)(?:\?|#|"|'|`|\s|$)/i;
  const skipPublic = (name: string): boolean =>
    name === "godot" || name === "node_modules" || name.startsWith(".");

  function walkPublic(dir: string, out: string[] = []): string[] {
    for (const name of readdirSync(dir)) {
      if (skipPublic(name)) {continue;}
      const full = join(dir, name);
      let st;
      try {st = statSync(full);} catch {continue;}
      if (st.isDirectory()) {walkPublic(full, out);}
      else {out.push(full);}
    }
    return out;
  }

  it("소스·스타일은 .jpg/.jpeg 경로를 가리키지 않는다", () => {
    const texts = walk(ROOT, (n) => /\.(ts|tsx|css|mjs|js)$/.test(n));
    const offenders = texts.filter((p) => {
      if (rel(p).startsWith("tests/")) {return false;}
      return JPEG_REF.test(sourceOf(p));
    });
    expect(offenders.map(rel), "JPEG 경로 — webp/avif 로").toEqual([]);
  });

  it("public 산출물(godot 제외)에 jpg/jpeg 파일이 없다", () => {
    const files = walkPublic(join(ROOT, "public"));
    const jpegs = files.filter((p) => /\.(?:jpg|jpeg)$/i.test(p));
    expect(jpegs.map(rel), "JPEG 파일 — webp/avif 로 변환").toEqual([]);
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
