/* eslint-disable max-lines -- 계약 스캔은 한 파일에 모은다 */
// 아키텍처 계약 테스트 — lint 규칙과 같은 계약을 소스 스캔으로 이중 검증한다.
// lint 설정이 실수로 풀려도 이 테스트가 지킨다.
import { existsSync, readFileSync, readdirSync, statSync } from "fs";
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

describe("계약: 인트로 모바일 배너", () => {
  it("로고는 배너 안에 겹치고, 픽셀 오프셋으로 잘라내지 않는다", () => {
    const css = sourceOf(join(ROOT, "app/globals.css"));
    expect(css).toContain(".banner-frame .intro-logo");
    expect(css).toMatch(/\.banner-frame \.intro-logo[\s\S]{0,80}position:absolute/);
    expect(css).not.toMatch(/intro-logo-ko[\s\S]{0,120}calc\(6%\s*-\s*30px\)/);
    expect(css).not.toContain("position:static");
    expect(css).toContain(".banner-frame .banner-art");
    expect(sourceOf(join(ROOT, "app/[locale]/layout.tsx"))).toContain("viewportFit");
  });
});

describe("계약: HTML 공유 썸네일", () => {
  it("layout 이 og:image 로 public/og.jpg 를 가리킨다", () => {
    const layout = sourceOf(join(ROOT, "app/[locale]/layout.tsx"));
    expect(existsSync(join(ROOT, "public/og.webp"))).toBe(true);
    expect(layout).toContain('"/og.webp"');
    expect(layout).toContain("openGraph");
    expect(layout).toContain("metadataBase");
    expect(layout).toContain("summary_large_image");
  });
});

describe("계약: 문구 SSOT", () => {
  const HANGUL = /["'`][^"'`]*[가-힣][^"'`]*["'`]/;

  it("한글 리터럴은 config(KO)·서버 안내문 정본 외에 없다", () => {
    const allowed = (r: string): boolean =>
      r.startsWith("tests/") || r === "lib/hub/config.ts" || r.startsWith("messages/")
      || r === "lib/hub/match-score.ts" || r === "lib/hub/match-wanted.ts";
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

  it("소스의 t(\"...\") 키는 messages/*.json 전 로케일에 실재한다", () => {
    const dir = join(ROOT, "messages");
    const files = readdirSync(dir).filter((name) => name.endsWith(".json"));
    expect(files).toEqual(expect.arrayContaining(["ko.json", "en.json"]));
    const missingKeysOfFileForLocale = (p: string, knownLoc: Set<string>): string[] => {
      const src = sourceOf(p);
      if (!/\bt\(/.test(src)) {return [];}
      const namespaces = [
        ...src.matchAll(/useTranslations\(\s*["']([^"']*)["']\s*\)/g),
        ...src.matchAll(/getTranslations\(\s*\{[^}]*namespace:\s*["']([^"']*)["']/g),
      ].map((m) => m[1]);
      return [...src.matchAll(/\bt\(\s*["']([^"']+)["']/g)].map((m) => m[1])
        .filter((key) => !isDynamicKey(key))
        .filter((key) => !resolveKey(key, namespaces).some((k) => knownLoc.has(k)))
        .map((key) => `${rel(p)}: ${key}`);
    };
    const missingKeysOfLocale = (file: string): string[] => {
      const knownLoc = new Set(flatten(
        JSON.parse(readFileSync(join(dir, file), "utf8")) as Record<string, unknown>,
      ));
      return tsSources.flatMap((p) => missingKeysOfFileForLocale(p, knownLoc))
        .map((entry) => `${file}: ${entry}`);
    };
    const missing = files.flatMap(missingKeysOfLocale);
    expect(missing, "메시지 로케일에 없는 키 — 그 언어 화면에서 깨진다").toEqual([]);
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

describe("계약: 홈 화면은 homeSurface", () => {
  it("page.tsx 는 phase×status AND 게이트 대신 homeSurface 를 쓴다", () => {
    const src = sourceOf(join(ROOT, "app/[locale]/page.tsx"));
    expect(src).toContain("homeSurface");
    expect(src).not.toContain("phase === \"lobby\" && hub.status !== \"in-room\"");
    expect(src).not.toContain("phase === \"room\" && hub.status === \"in-room\"");
  });
});

describe("계약: 방 만들기 네비게이션", () => {
  it("제출 직후 홈으로 보내지 않는다 — 방이 생길 때까지 /create 에 머문다", () => {
    const src = sourceOf(join(ROOT, "hooks/useCreateRoomPage.ts"));
    const submit = src.slice(src.indexOf("const onSubmit"), src.indexOf("const onBack"));
    expect(src).toContain("createSurface");
    expect(submit).toContain("createRoom");
    expect(submit).not.toContain("router.push");
    expect(submit).not.toContain("router.replace");
  });
});

describe("계약: 웹 캔버스 키 포커스", () => {
  it("런타임은 알탭 복귀용 bindCanvasKeyboardFocus 를 붙인다", () => {
    const runtime = sourceOf(join(ROOT, "lib/godot/runtime.ts"));
    expect(runtime).toContain("bindCanvasKeyboardFocus");
    expect(runtime).toContain("applyManifest");
    expect(runtime).not.toContain("this.manifest ??=");
    expect(runtime).toContain("this.store.assetUrl(this.plan.files.engineJs)");
    expect(runtime).toContain("captureAudioContexts");
    expect(runtime).toContain("bindAudioUnlock");
    expect(runtime).not.toContain("unlockGodotAudioAfterBoot");
    expect(sourceOf(join(ROOT, "lib/godot/unlock-audio.ts"))).not.toContain("setTimeout");
    expect(sourceOf(join(ROOT, "components/GodotCanvas.tsx"))).toContain('id="canvas"');
    expect(sourceOf(join(ROOT, "lib/godot/engine-config.ts"))).toContain("focusCanvas: true");
    expect(sourceOf(join(ROOT, "lib/godot/engine-config.ts"))).toContain("canvasResizePolicy: 2");
    expect(sourceOf(join(ROOT, "lib/godot/canvas-focus.ts"))).toContain("visibilitychange");
    expect(sourceOf(join(ROOT, "lib/godot/canvas-focus.ts"))).toContain("pointerdown");
    expect(sourceOf(join(ROOT, "lib/godot/canvas-focus.ts"))).not.toContain("godot-page-");
    expect(sourceOf(join(ROOT, "lib/godot/canvas-focus.ts"))).toContain("bindPlayKeyGuard");
    expect(sourceOf(join(ROOT, "..", "project", "core/shell/match_shell.gd"))).toContain("HeldInputScript");
    expect(sourceOf(join(ROOT, "lib/godot/play-keys.ts"))).toContain("event.code");
    expect(sourceOf(join(ROOT, "lib/godot/play-keys.ts"))).toContain('addEventListener("keydown", onKey, true)');
    expect(sourceOf(join(ROOT, "lib/godot/play-keys.ts"))).toContain('"Tab"');
    expect(sourceOf(join(ROOT, "..", "project", "core/input/layout_keys.gd"))).toContain("is_physical_key_pressed");
    expect(sourceOf(join(ROOT, "..", "project", "core/input/layout_keys.gd"))).not.toContain("is_key_pressed");
  });
});

describe("계약: 나가기 확인은 목록에 보이는 내 방만", () => {
  it("Lobby 는 목록을 넘기고, 훅은 listedMyRoom 으로 유령 id 를 버린다", () => {
    const lobby = sourceOf(join(ROOT, "components/Lobby.tsx"));
    expect(lobby).toContain("needsLeaveConfirm(myRoom, undefined, rooms)");
    expect(lobby).toContain("needsLeaveConfirm(myRoom, room.id, rooms)");
    const membership = sourceOf(join(ROOT, "lib/room-membership.ts"));
    expect(membership).toContain("export function listedMyRoom");
    const hook = sourceOf(join(ROOT, "hooks/useMyRoom.ts"));
    expect(hook).toContain("listedMyRoom");
    expect(hook).toContain("clearMyRoom");
    const hub = sourceOf(join(ROOT, "hooks/useHub.ts"));
    expect(hub).toContain("useMyRoom(derived, rooms, listActive && !lobbyConnecting)");
  });
});

describe("계약: 캐릭터 초상은 시트를 칸 안에서 자른다", () => {
  it("클립은 인라인 래퍼에 있고 시트는 마진이 아니라 절대 위치로 민다", () => {
    const portrait = sourceOf(join(ROOT, "lib/characters/portrait.ts"));
    expect(portrait).toContain("overflow: \"hidden\"");
    expect(portrait).toContain("position: \"absolute\"");
    expect(portrait).toContain("maxWidth: \"none\"");
    expect(portrait).not.toMatch(/marginLeft/);
    expect(portrait).not.toMatch(/marginTop/);
    const css = sourceOf(join(ROOT, "app/globals.css"));
    expect(css).toMatch(/\.char-portrait\s*\{[^}]*overflow:\s*hidden/);
    expect(css).toContain(".char-portrait img { display:block; }");
    const view = sourceOf(join(ROOT, "components/CharacterPortrait.tsx"));
    expect(view).toContain("portraitFrameStyle");
    expect(view).toContain("portraitImageStyle");
    expect(view).toContain("className=\"char-portrait\"");
  });
});

describe("계약: Godot 웹 캔버스는 policy=2 와 CSS 가 싸우지 않는다", () => {
  it("gc-canvas 는 100% 가 아니라 공식 템플릿처럼 absolute 이고, 오버레이는 overflow hidden", () => {
    const css = sourceOf(join(ROOT, "app/globals.css"));
    const canvasRule = css.slice(css.indexOf(".gc-canvas"), css.indexOf(".gc-booting"));
    expect(canvasRule).toContain("position:absolute");
    expect(canvasRule).not.toMatch(/width:\s*100%/);
    expect(canvasRule).not.toMatch(/height:\s*100%/);
    const overlayRule = css.slice(css.indexOf(".gc-overlay"), css.indexOf(".gc-canvas"));
    expect(overlayRule).toContain("overflow:hidden");
    expect(sourceOf(join(ROOT, "lib/godot/engine-config.ts"))).toContain("canvasResizePolicy: 2");
    expect(sourceOf(join(ROOT, "hooks/useGodotMatch.ts"))).toContain("lockPlayViewport");
  });
});

describe("계약: E2E 는 Godot 공식 WebGL2 검사를 한다", () => {
  const e2e = [
    "scripts/e2e-dagul.mjs",
    "scripts/e2e/harness.mjs",
    "scripts/e2e/godot-probe.mjs",
    "scripts/e2e/audio-probe.mjs",
  ].map((p) => sourceOf(join(ROOT, p))).join("\n");

  it("e2e-dagul 은 Engine.isWebGLAvailable(2) 를 쓰고 게임 캔버스에 getContext 하지 않는다", () => {
    expect(e2e).toContain("isWebGLAvailable(2)");
    expect(e2e).not.toMatch(/getElementById\(['"]godot-canvas['"]\)[\s\S]{0,80}getContext\(['"]webgl2['"]\)/);
    expect(e2e).not.toMatch(/const URL\s*=/);
    expect(e2e).toContain("new URL(PAGE_URL)");
  });

  it("e2e 는 인게임 Sample 총성을 AudioBufferSourceNode.start 로 잰다", () => {
    const probe = sourceOf(join(ROOT, "scripts/e2e/audio-probe.mjs"));
    const dagul = sourceOf(join(ROOT, "scripts/e2e-dagul.mjs"));
    expect(probe).toContain("AudioBufferSourceNode.prototype");
    expect(probe).toContain("proto.start");
    expect(dagul).toContain("installAudioProbe");
    expect(dagul).toContain("인게임 Sample 총성");
    expect(sourceOf(join(ROOT, "scripts/e2e/harness.mjs"))).toContain("autoplay-policy=no-user-gesture-required");
  });

  it("e2e 는 Godot 의 matchmake/reconnect 를 감시한다", () => {
    expect(e2e).toContain("/matchmake/reconnect");
    expect(e2e).toContain("reconnectHits");
    expect(e2e).toContain("__e2eJsReconnect");
    expect(e2e).toContain("godotOwned");
  });
});

describe("계약: 좌석·팩 정본은 web/lib/domain", () => {
  it("roster·waiting-room-pack 이 앱 안에 있다", () => {
    const dir = join(ROOT, "lib", "domain");
    const domain = existsSync(dir) ? walk(dir, (n) => n.endsWith(".ts")).map(rel) : [];
    expect(domain.some((p) => p.endsWith("roster.ts"))).toBe(true);
    expect(domain.some((p) => p.endsWith("waiting-room-pack.ts"))).toBe(true);
    expect(domain.some((p) => p.endsWith("match-load-ready.ts"))).toBe(true);
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
    expect(src).toContain("send_ready");
    expect(src).toContain("MSG_READY");
    expect(src).toContain("_ready_repeat");
    expect(src).toContain("_ready_sent");
    expect(src).toContain("READY_RETRY_SEC");
  });

  it("LobbyRoom 본체에 테스트 시계 API 가 없다", () => {
    const src = sourceOf(join(ROOT, "lib/hub/LobbyRoom.ts"));
    expect(src).not.toContain("testClock");
  });

  it("매치 셸은 모듈 start 뒤에 ready 를 보낸다", () => {
    const src = sourceOf(join(ROOT, "..", "project", "core/shell/match_shell.gd"));
    const startAt = src.indexOf("module.start(");
    const readyAt = src.indexOf("_notify_match_loaded()");
    expect(startAt).toBeGreaterThanOrEqual(0);
    expect(readyAt).toBeGreaterThan(startAt);
    expect(src).toContain("send_ready");
    expect(src).toContain("_try_send_match_ready");
    expect(src).toContain("_world_has_heroes");
  });

  // Godot 스키마 거울 전 클래스 대조는 tests/schema-mirror.test.ts 가 담당한다.

  it("게임 모듈은 상주 스냅을 사본으로만 push 한다 — 공유 참조는 보간을 죽인다", () => {
    const src = sourceOf(join(ROOT, "..", "project", "games/dagul/game.gd"));
    expect(src).toMatch(/push_snap\(snap\.duplicate\(true\)\)/);
  });

  it("미니맵은 사각 풀맵을 그린다 — 옛 원형 섬 그리기 금지", () => {
    const hud = sourceOf(join(ROOT, "..", "project", "games/dagul/hud/hud.gd"));
    expect(hud).not.toMatch(/ARENA_SIZE\.y \* 0\.47/);
    expect(hud).toContain("_draw_minimap_zone");
    expect(hud).toContain("_minimap_offset");
  });

  it("HUD 리셋은 킬 피드 커서를 함께 지운다 — 2회차 킬이 전부 걸러진다", () => {
    const hud = sourceOf(join(ROOT, "..", "project", "games/dagul/hud/hud.gd"));
    const reset = hud.slice(hud.indexOf("func reset_match_visuals"), hud.indexOf("func _zodiac_name"));
    expect(reset).toContain("_kill_feed.clear()");
    expect(reset).toContain("_last_kill_event_id = 0");
  });

  it("카운트다운은 하드코딩 없이 첫 SNAP 의 startCountdown 을 따른다", () => {
    const src = sourceOf(join(ROOT, "..", "project", "games/dagul/game.gd"));
    expect(src).toMatch(/start_countdown\s*=\s*0\.0/);
    expect(src).not.toMatch(/start_countdown\s*=\s*3\.0/);
    const snap = sourceOf(join(ROOT, "lib/hub/match-authority-snap.ts"));
    expect(snap).toContain("startCountdown");
  });

  it("READY 는 시뮬 틱을 기다리지 않고 장벽을 연다", () => {
    const src = sourceOf(join(ROOT, "lib/hub/LobbyRoom.ts"));
    expect(src).toContain("tryReleaseLoadBarrier");
    const reconn = src.slice(src.indexOf("onReconnect"), src.indexOf("onLeave"));
    expect(reconn).not.toContain("matchReady = false");
    expect(reconn).toContain("resumePlayingSeat");
    expect(reconn).toContain("snapOptOut.delete");
    const resume = src.slice(src.indexOf("resumePlayingSeat"), src.indexOf("resendStart"));
    expect(resume).toContain("parkSeat");
    expect(src).toContain("this.resendStart(client, player)");
    const joinSrc = src.slice(src.indexOf("onJoin("), src.indexOf("private takeOverSeat"));
    expect(joinSrc).toContain("resumePlayingSeat");
  });

  it("반전: START 경로가 leaveOnceForHandoff 로 좌석을 넘기면 실패한다", () => {
    const src = sourceOf(join(ROOT, "hooks/useGameRoom.ts"));
    expect(src).not.toContain("leaveOnceForHandoff");
    expect(src).toContain("HANDOFF.MATCH");
    expect(src).toContain("HANDOFF.FROM_HUB");
  });

  it("로비 목록은 리스트 룸이 아니라 GET /rooms 다", () => {
    const src = sourceOf(join(ROOT, "hooks/useRoomList.ts"));
    expect(src).toContain("/rooms");
    expect(src).toContain("AbortSignal.timeout");
    expect(src).not.toContain("joinOrCreate");
    expect(sourceOf(join(ROOT, "server.ts"))).toContain('pathname === "/rooms"');
    expect(sourceOf(join(ROOT, "server.ts"))).not.toContain("RoomListRoom");
  });

  it("페이지 루트 WASM 은 로케일 상대도 붙이고, 팩 경로(/godot)로는 두지 않는다", () => {
    const server = sourceOf(join(ROOT, "server.ts"));
    expect(server).not.toContain("isExtLibPath");
    expect(server).toContain("servePageRelativeGodotAssets");
    expect(server).toContain("shouldServeEncoding");
    expect(server).toContain("godotWorkletAssetPath(pathname)");
    expect(server).not.toMatch(/servePack && godotWorkletAssetPath/);
    expect(server).not.toContain("libcolyseus");
    expect(server).not.toContain("servePageRootWasm");
  });

  it("브릿지 부착은 onMessage 를 쌓지 않는다", () => {
    expect(sourceOf(join(ROOT, "lib/hub/page-bridge.ts"))).not.toContain("onMessage");
    expect(sourceOf(join(ROOT, "hooks/usePageBridge.ts"))).toContain("useRoomMessage");
  });
});

describe("계약: 로케일 표시 문자열은 메시지 팩이다", () => {
  it("게스트 닉·인트로 로고에 locale === 분기가 없다", () => {
    const guest = sourceOf(join(ROOT, "lib/guest-identity.ts"));
    const intro = sourceOf(join(ROOT, "components/phases/OfflinePhase.tsx"));
    const config = sourceOf(join(ROOT, "lib/hub/config.ts"));
    expect(guest).not.toMatch(/locale\s*===\s*["']en["']/);
    expect(guest).not.toMatch(/ZODIAC_NAMES/);
    expect(config).not.toContain("ZODIAC_NAMES");
    expect(intro).not.toMatch(/locale\s*===\s*["']ko["']/);
    expect(intro).toContain('t("logo.src")');
    expect(guest).toContain("zodiacNamesOf");
  });
});

describe("계약: 캐릭터 목록은 JSON 정본이다", () => {
  it("TS 캐릭터 모듈에 십이지 고유명을 쓰지 않는다", () => {
    const dir = join(ROOT, "lib", "characters");
    const files = existsSync(dir) ? walk(dir, (n) => n.endsWith(".ts")) : [];
    const banned = /\b(rat|ox|tiger|rabbit|dragon|snake|horse|sheep|monkey|rooster|dog|pig|쥐|호랑이)\b/i;
    const offenders = files.filter((p) => banned.test(sourceOf(p)));
    expect(offenders.map(rel)).toEqual([]);
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

describe("계약: 배포 신원은 /health 와 분리한다", () => {
  it("서버는 /api/version 을 no-store 로 열고 health 에 id 를 넣지 않는다", () => {
    const server = sourceOf(join(ROOT, "server.ts"));
    const health = sourceOf(join(ROOT, "lib/hub/health.ts"));
    expect(server).toContain('pathname === "/api/version"');
    expect(server).toContain("revisionBody(liveRevisionId())");
    expect(health).not.toContain("BUILD_ID");
    expect(health).not.toContain("revisionBody");
    expect(sourceOf(join(ROOT, "middleware.ts"))).toContain("api");
  });
});

describe("계약: 웹 인게임 오디오는 Sample + Master", () => {
  const audio = (): string => sourceOf(join(ROOT, "..", "project/core/autoload/game_audio.gd"));

  it("웹은 Stream 강제와 add_bus 우회가 없다", () => {
    const src = audio();
    expect(src).toContain("OS.has_feature(\"web\")");
    expect(src).toContain("_ensure_impact");
    expect(src).toContain("_pool_bus");
    expect(src).not.toContain("PLAYBACK_TYPE_STREAM");
    expect(src).not.toContain("_web_stream");
    expect(src).toContain("_play_stream(stream, volume_db, pitch_variance, _pool_bus())");
    expect(sourceOf(join(ROOT, "..", "project/project.godot"))).toContain("default_playback_type.web=1");
  });

  it("웹 플레이어는 Sample 이고 위치 2D 풀을 만들지 않는다", () => {
    const src = audio();
    expect(src).toContain("PLAYBACK_TYPE_SAMPLE");
    expect(src).toContain("if not OS.has_feature(\"web\"):\n\t\t_build_world_pool()");
    expect(src).toContain("OS.has_feature(\"web\") or _world_players.is_empty()");
  });

  it("제스처 unlock 은 트랙을 비우지 않는다", () => {
    const src = audio();
    const unlock = src.slice(src.indexOf("_on_web_audio_unlock"), src.indexOf("func _stream_for"));
    expect(unlock).toContain("_music_a.playing");
    expect(unlock).not.toContain("_current_track = \"\"");
    const js = sourceOf(join(ROOT, "lib/godot/unlock-audio.ts"));
    expect(js).toContain("resumeIssued");
    expect(js).toContain("if (!firstResume) {return;}");
  });
});

const GD_SCHEMA = join(ROOT, "..", "project/core/net/lobby_state_schema.gd");

describe("계약: Colyseus GD 스키마 생성본 금지", () => {
  it("lobby_state_schema.gd 가 없고 codegen 도 그 경로에 쓰지 않는다", () => {
    expect(existsSync(GD_SCHEMA)).toBe(false);
    const gen = sourceOf(join(ROOT, "scripts/generate-lobby-schema.mjs"));
    expect(gen).not.toContain("writeFileSync(outPath");
    expect(gen).toContain("lobby_state_schema.gd 가 있습니다");
  });
});

describe("계약: 히어로 배열 칸은 ArraySchema", () => {
  it("timedBuffs·clones 가 JSON 문자열이 아니다", () => {
    const ts = sourceOf(join(ROOT, "lib/hub/match-schema/hero.ts"))
      + sourceOf(join(ROOT, "lib/hub/match-schema/event.ts"));
    const write = sourceOf(join(ROOT, "lib/hub/match-schema-write.ts"));
    expect(ts).toContain("@type([MatchTimedBuffSchema]) timedBuffs");
    expect(ts).toContain("@type([MatchCloneSchema]) clones");
    expect(ts).not.toContain('@type("string") timedBuffs');
    expect(ts).not.toContain('@type("string") clones');
    expect(write).toContain("writeTimedBuffs");
    expect(write).toContain("writeClones");
    expect(write).not.toContain("row.timedBuffs = JSON.stringify");
    expect(write).not.toContain("row.clones = JSON.stringify");
    expect(write).not.toContain("row.data = JSON.stringify");
    expect(ts).toContain("@type(MatchEventDataSchema) data");
  });
});

describe("계약: 매치 events 는 Map 이다", () => {
  it("TS·GD 스키마가 ARRAY+shift 가 아니라 MAP 이다", () => {
    const ts = sourceOf(join(ROOT, "lib/hub/match-schema/state.ts"));
    const write = sourceOf(join(ROOT, "lib/hub/match-schema-write.ts"));
    expect(ts).toContain("@type({ map: MatchEventSchema }) events");
    expect(ts).not.toContain("@type([MatchEventSchema]) events");
    expect(write).toContain("match.events.set(String(match.eventSeq)");
    expect(write).toContain("match.events.delete");
    expect(write).not.toContain("match.events.shift()");
  });
});

describe("계약: 빈 events 스냅도 탄으로 gun_fire 를 추정한다", () => {
  it("NetWorld 는 이번 틱 gun_fire 가 없을 때만 탄 역추정을 한다", () => {
    const src = sourceOf(join(ROOT, "..", "project/games/dagul/net/net_world.gd"));
    expect(src).toContain("var _snap_had_gun_fire");
    expect(src).toContain("if _bullets_ready and not _snap_had_gun_fire:");
    expect(src).not.toContain("if _bullets_ready and not _server_events_active:");
    const tests = sourceOf(join(ROOT, "..", "project/tests/test_net_world.gd"));
    expect(tests).toContain("_empty_events_still_infer_gun_fire");
    expect(tests).toContain("_events_and_bullet_do_not_double");
  });
});

describe("계약: 로컬 기동은 죽은 포트와 낡은 팩을 버린다", () => {
  it("dev.sh 가 팩 신선도와 health 를 본다", () => {
    const dev = sourceOf(join(ROOT, "..", "dev.sh"));
    expect(dev).toContain("ensure_godot_fresh");
    expect(dev).toContain("free_stale_port");
    expect(dev).toContain("port_healthy");
  });
});

describe("계약: GameId 는 웹 산출물 경로가 아니다", () => {
  const banned = /\/godot\/\$\{(?:game|gameId|game\.id)/;

  it("lib·hooks·scripts 는 GameId 로 /godot/ 경로를 만들지 않는다", () => {
    const listing = sourceOf(join(ROOT, "lib/games/listing.ts"));
    const runtime = sourceOf(join(ROOT, "lib/godot/runtime.ts"));
    expect(listing).toContain("packOf");
    expect(runtime).toContain("packOf");
    expect(runtime).toContain("applyManifest");
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

describe("계약: item 와이어 SSOT", () => {
  it("개수 문법은 match-item-wire 만 정하고 loot 는 위임한다", () => {
    const wire = sourceOf(join(ROOT, "lib/hub/match-item-wire.ts"));
    const loot = sourceOf(join(ROOT, "lib/hub/match-loot.ts"));
    const gd = sourceOf(join(ROOT, "..", "project/games/dagul/net/snap_player_codec.gd"));
    expect(wire).toContain("export function packItemStack");
    expect(wire).toContain("export function unpackItemStack");
    expect(loot).toContain('from "./match-item-wire.js"');
    expect(loot).not.toContain("return `medkit:${medkits}`");
    expect(gd).toContain("pack_item_wire");
    expect(gd).toContain("unpack_item_wire");
    expect(gd).toContain('return pack_item_wire("medkit", medkits)');
    expect(gd).toContain("_unpack_medkits");
    expect(gd).toContain("P_MEDKITS");
  });
});

describe("계약: 엔진 소켓은 defineInput 만 보낸다", () => {
  it("engine_socket 이 MSG.INPUT 폴백을 쓰지 않는다", () => {
    const socket = sourceOf(join(ROOT, "..", "project/core/autoload/engine_socket.gd"));
    expect(socket).toContain("_input.flush(_room)");
    expect(socket).not.toContain("send_message(WebContract.MSG_INPUT");
  });
});
