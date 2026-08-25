// 브라우저 E2E — 인트로 → 로비 → 방 만들기 → 시작 → Godot 인게임 진입까지.
// 콘솔 에러·화면 단계를 전부 기록한다. 사용법: node scripts/e2e-dagul.mjs
import { chromium } from "playwright-core";

const CHROME = `${process.env.HOME}/Library/Caches/ms-playwright/chromium-1234/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing`;
const URL = process.env.E2E_URL || "http://127.0.0.1:3000";
const SHOT = "/tmp/e2e-dagul";

const results = [];
function ok(name, cond, extra = "") {
  results.push({ name, pass: !!cond });
  console.log(`${cond ? "  ✓" : "  ✗"} ${name}${extra ? ` — ${extra}` : ""}`);
  if (!cond) process.exitCode = 1;
}

const browser = await chromium.launch({ executablePath: CHROME, headless: true });
const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
const page = await ctx.newPage();

const consoleErrors = [];
page.on("console", (m) => { if (m.type() === "error") {consoleErrors.push(m.text());} });
page.on("pageerror", (e) => consoleErrors.push(`PAGEERROR: ${e.message}`));
await page.addInitScript(() => {
  window.__e2eMatchStarted = false;
  window.addEventListener("godot-match-start", () => { window.__e2eMatchStarted = true; }, { once: true });
});

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
ok("1. 인트로 → 이름 입력 → 시작", true);

// 2. 로비 (방 목록)
await createLink.waitFor({ state: "visible", timeout: 45_000 });
await page.screenshot({ path: `${SHOT}-2-lobby.png` });
ok("2. 로비 도착", true);

// 3. 방 만들기 (/create) → 대기실
await createLink.click();
await page.waitForSelector("form.create-form", { timeout: 45_000 });
await page.click("form.create-form button.cta");
await page.waitForURL((u) => !u.pathname.includes("/create"), { timeout: 15_000 });
await page.waitForSelector("text=게임 시작", { timeout: 45_000 });
await page.screenshot({ path: `${SHOT}-3-room.png` });
ok("3. 대기실 도착", true);

// 4. 게임 시작 — Godot 부팅 대기 (사이드카 다운로드 포함, 넉넉히)
await page.click("text=게임 시작");
console.log("  … Godot 부팅 대기 중 (최대 120초)");
const bootOk = await page
  .waitForFunction(() => document.querySelector("canvas") !== null, null, { timeout: 120_000 })
  .then(() => true)
  .catch(() => false);
await page.screenshot({ path: `${SHOT}-4-playing.png` });
ok("4. 시작 → 캔버스 부팅", bootOk);

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

console.log("\n— 콘솔 에러 —");
console.log(consoleErrors.length ? consoleErrors.slice(0, 10).join("\n") : "(없음)");
console.log(`\nE2E: ${results.filter((r) => r.pass).length}/${results.length} 통과`);
await browser.close();
process.exit(process.exitCode ?? 0);
