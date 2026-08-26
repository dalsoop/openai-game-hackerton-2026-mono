// 브라우저 E2E — 인트로 → 로비 → 방 만들기 → 시작 → Godot 인게임 진입까지.
// 콘솔 에러·화면 단계를 전부 기록한다. 사용법: node scripts/e2e-dagul.mjs
import { chromium } from "playwright-core";

const CHROME = `${process.env.HOME}/Library/Caches/ms-playwright/chromium-1234/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing`;
const URL = process.env.E2E_URL || "http://127.0.0.1:3100/ko";
const ORIGIN = new URL(URL).origin;
const SHOT = "/tmp/e2e-dagul";

const results = [];
function ok(name, cond, extra = "") {
  results.push({ name, pass: !!cond });
  console.log(`${cond ? "  ✓" : "  ✗"} ${name}${extra ? ` — ${extra}` : ""}`);
  if (!cond) process.exitCode = 1;
}

// Playwright: channel "chromium" 은 신규 헤드리스(GPU 포함). playwright-core 만
// 쓰는 이 레포는 번들 Chrome for Testing 경로를 넘긴다 (공식 executablePath 주의).
const browser = await chromium.launch({
  executablePath: process.env.CHROME_PATH || CHROME,
  headless: true,
  args: ["--enable-webgl", "--ignore-gpu-blocklist", "--use-angle=metal"],
});
const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
const page = await ctx.newPage();

const consoleErrors = [];
const reconnectHits = [];
page.on("console", (m) => { if (m.type() === "error") {consoleErrors.push(m.text());} });
page.on("pageerror", (e) => consoleErrors.push(`PAGEERROR: ${e.message}`));
page.on("request", (req) => {
  if (req.url().includes("/matchmake/reconnect")) {reconnectHits.push(req.url());}
});
await page.addInitScript(() => {
  window.__e2eMatchStarted = false;
  window.__e2eJsReconnect = [];
  window.addEventListener("godot-match-start", () => { window.__e2eMatchStarted = true; }, { once: true });
  const note = (url, via) => {
    const u = String(url ?? "");
    if (!u.includes("/matchmake/reconnect")) {return;}
    window.__e2eJsReconnect.push({ u, via, stack: new Error().stack ?? "" });
  };
  const origFetch = window.fetch.bind(window);
  window.fetch = (input, init) => {
    note(typeof input === "string" ? input : input && input.url, "fetch");
    return origFetch(input, init);
  };
  const origOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url, ...rest) {
    note(url, "xhr");
    return origOpen.call(this, method, url, ...rest);
  };
});

const versionResp = await fetch(`${ORIGIN}/api/version`, { cache: "no-store" });
let versionBody = {};
try { versionBody = await versionResp.json(); } catch { versionBody = {}; }
ok("0. /api/version", versionResp.ok && typeof versionBody.id === "string", JSON.stringify(versionBody));

// 1. 인트로 — 개발 서버 첫 컴파일·HMR 리로드가 있어도 로비까지 다시 누른다.
await page.goto(URL, { waitUntil: "domcontentloaded" });
await page.waitForSelector("input[name=player-name]", { timeout: 45_000 });
await page.locator("input[name=player-name]").fill("E2E호스트");
await page.screenshot({ path: `${SHOT}-1-intro.png` });
await page.click("text=시작하기");
const createLink = page.locator("a.lobby-create-link");
for (let i = 0; i < 3 && !(await createLink.isVisible().catch(() => false)); i++) {
  if (await page.locator("text=시작하기").isVisible().catch(() => false)) {
    await page.locator("input[name=player-name]").fill("E2E호스트");
    await page.click("text=시작하기");
  }
  await createLink.waitFor({ state: "visible", timeout: 20_000 }).catch(() => {});
}
ok("1. 인트로 → 이름 입력 → 시작", await createLink.isVisible().catch(() => false));

// 2. 로비 (방 목록) — /create 게이트는 오프라인이면 홈으로 보낸다.
await createLink.waitFor({ state: "visible", timeout: 45_000 });
await page.getByText("접속됨").waitFor({ timeout: 45_000 });
await page.screenshot({ path: `${SHOT}-2-lobby.png` });
ok("2. 로비 도착", await createLink.isVisible());

// 3. 방 만들기 (/create) → 대기실
await createLink.click();
await page.waitForURL((u) => u.pathname.includes("/create"), { timeout: 15_000 });
await page.waitForSelector("form.create-form", { timeout: 45_000 });
await page.click("form.create-form button.cta");
await page.waitForURL((u) => !u.pathname.includes("/create"), { timeout: 15_000 });
await page.waitForSelector("text=게임 시작", { timeout: 45_000 });
await page.screenshot({ path: `${SHOT}-3-room.png` });
ok("3. 대기실 도착", true);

// 4. 게임 시작 — Godot 공식은 캔버스가 아니라 WebGL2 (Engine.isWebGLAvailable(2)).
// https://docs.godotengine.org/en/4.7/tutorials/platform/web/customizing_html5_shell.html
await page.click("text=게임 시작");
console.log("  … Godot 부팅 대기 중 (최대 120초)");
const canvasOk = await page
  .waitForFunction(() => document.getElementById("godot-canvas") !== null, null, { timeout: 120_000 })
  .then(() => true)
  .catch(() => false);
const engineOk = canvasOk && await page
  .waitForFunction(() => typeof window.Engine?.isWebGLAvailable === "function", null, { timeout: 120_000 })
  .then(() => true)
  .catch(() => false);
const webgl2Ok = engineOk && await page.evaluate(() => window.Engine.isWebGLAvailable(2));
await page.screenshot({ path: `${SHOT}-4-playing.png` });
ok("4. 시작 → 캔버스 부팅", canvasOk);
ok("4b. Godot Engine.isWebGLAvailable(2)", webgl2Ok);

// 5. 매치 시작 이벤트 (워치독이 기다리는 DOM 이벤트)
const matchStarted = await page.evaluate(
  () => new Promise((resolve) => {
    if (window.__e2eMatchStarted) {resolve(true); return;}
    window.addEventListener("godot-match-start", () => resolve(true), { once: true });
    setTimeout(() => resolve(false), 90_000);
  }),
);
await page.screenshot({ path: `${SHOT}-5-match.png` });
ok("5. Godot 매치 합류 (godot-match-start)", matchStarted);
const jsReconnect = await page.evaluate(() => window.__e2eJsReconnect ?? []);
const godotOwned = reconnectHits.filter((url) => {
  const hit = jsReconnect.find((j) => url.includes(j.u) || j.u.includes(url));
  if (!hit) {return true;}
  return /\/godot\//.test(hit.stack);
});
ok(
  "5b. Godot 는 matchmake/reconnect 를 치지 않는다",
  godotOwned.length === 0,
  godotOwned[0] ?? (reconnectHits[0] ? `react-sdk ${reconnectHits.length}` : ""),
);

// 6. 시뮬이 돌고 카운트다운이 끝난 뒤 WASD 로 좌표가 바뀐다.
const simOk = await page
  .waitForFunction(
    () => window.__dagulPlay && window.__dagulPlay.t > 20 && window.__dagulPlay.h === 1,
    null,
    { timeout: 20_000 },
  )
  .then(() => true)
  .catch(() => false);
ok("6. 호스트 시뮬 틱", simOk);
const combatOk = await page
  .waitForFunction(() => window.__dagulPlay && window.__dagulPlay.c <= 0, null, { timeout: 15_000 })
  .then(() => true)
  .catch(() => false);
ok("7. 카운트다운 종료", combatOk);
await page.locator("#godot-canvas").click({ position: { x: 640, y: 360 } });
const before = await page.evaluate(() => window.__dagulPlay);
await page.keyboard.down("KeyW");
await page.waitForTimeout(900);
await page.keyboard.up("KeyW");
const after = await page.evaluate(() => window.__dagulPlay);
const moved = before && after && Math.hypot(after.x - before.x, after.y - before.y) > 8;
await page.screenshot({ path: `${SHOT}-6-moved.png` });
ok("8. WASD 이동", moved, before && after ? `${before.x.toFixed(0)},${before.y.toFixed(0)} → ${after.x.toFixed(0)},${after.y.toFixed(0)}` : "probe 없음");

const autoloadLeak = consoleErrors.some((line) => /non-existent singleton '(GameState|Audio)'/.test(line));
ok("9. 오토로드는 엔진 싱글톤이 아님", !autoloadLeak);

const pageFocusEvents = await page.evaluate(() => {
  document.getElementById("godot-canvas")?.blur();
  window.dispatchEvent(new Event("focus"));
  return { canvas: document.activeElement?.id === "godot-canvas" };
});
ok("10. 창 포커스 복귀 시 캔버스 키 포커스", pageFocusEvents.canvas);

console.log("\n— 콘솔 에러 —");
console.log(consoleErrors.length ? consoleErrors.slice(0, 10).join("\n") : "(없음)");
console.log(`\nE2E: ${results.filter((r) => r.pass).length}/${results.length} 통과`);
await browser.close();
process.exit(process.exitCode ?? 0);
