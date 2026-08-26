// 브라우저 E2E 시나리오 — 인트로 → 로비 → 방 만들기 → 시작 → Godot 인게임.
// 런처·프로브는 scripts/e2e/ 가 맡는다. 사용법: node scripts/e2e-dagul.mjs
import {
  ORIGIN, PAGE_URL, SHOT, attachConsole, launchPage, ok, results,
} from "./e2e/harness.mjs";
import {
  attachReconnectWatch, godotOwnedReconnects, installMatchProbe, waitMatchStart, waitStartEnabled,
} from "./e2e/godot-probe.mjs";
import { audioSnapshot, installAudioProbe, stripNextOverlay } from "./e2e/audio-probe.mjs";

const { browser, page } = await launchPage();
const consoleErrors = attachConsole(page);
const reconnectHits = attachReconnectWatch(page);
await installMatchProbe(page);
await installAudioProbe(page);

const versionResp = await fetch(`${ORIGIN}/api/version`, { cache: "no-store" });
let versionBody = {};
try { versionBody = await versionResp.json(); } catch { versionBody = {}; }
ok("0. /api/version", versionResp.ok && typeof versionBody.id === "string", JSON.stringify(versionBody));

await page.goto(PAGE_URL, { waitUntil: "domcontentloaded" });
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

await createLink.waitFor({ state: "visible", timeout: 45_000 });
await page.getByText("접속됨").waitFor({ timeout: 45_000 });
await page.screenshot({ path: `${SHOT}-2-lobby.png` });
ok("2. 로비 도착", await createLink.isVisible());

await createLink.click();
await page.waitForURL((u) => u.pathname.includes("/create"), { timeout: 15_000 });
await page.waitForSelector("form.create-form", { timeout: 45_000 });
await page.click("form.create-form button.cta");
await page.waitForURL((u) => !u.pathname.includes("/create"), { timeout: 15_000 });
await page.waitForSelector("text=게임 시작", { timeout: 45_000 });
const startBtn = page.locator("button.cta", { hasText: "게임 시작" });
await startBtn.waitFor({ state: "visible", timeout: 45_000 });
await waitStartEnabled(page);
await page.screenshot({ path: `${SHOT}-3-room.png` });
ok("3. 대기실 도착", true);

await startBtn.click();
console.log("  … Godot 부팅 대기 중 (최대 120초)");
const canvasOk = await page
  .waitForFunction(() => document.getElementById("canvas") !== null, null, { timeout: 120_000 })
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

const matchStarted = await waitMatchStart(page);
await page.screenshot({ path: `${SHOT}-5-match.png` });
ok("5. Godot 매치 합류 (godot-match-start)", matchStarted);
const jsReconnect = await page.evaluate(() => window.__e2eJsReconnect ?? []);
const godotOwned = godotOwnedReconnects(reconnectHits, jsReconnect);
ok(
  "5b. Godot 는 matchmake/reconnect 를 치지 않는다",
  godotOwned.length === 0,
  godotOwned[0] ?? (reconnectHits[0] ? `react-sdk ${reconnectHits.length}` : ""),
);

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
await stripNextOverlay(page);
const audioBefore = await audioSnapshot(page);
await page.locator("#canvas.gc-canvas").click({ position: { x: 640, y: 360 } });
const before = await page.evaluate(() => window.__dagulPlay);
await page.keyboard.down("KeyW");
await page.waitForTimeout(900);
await page.keyboard.up("KeyW");
const after = await page.evaluate(() => window.__dagulPlay);
const moved = before && after && Math.hypot(after.x - before.x, after.y - before.y) > 8;
await page.screenshot({ path: `${SHOT}-6-moved.png` });
ok("8. WASD 이동", moved, before && after ? `${before.x.toFixed(0)},${before.y.toFixed(0)} → ${after.x.toFixed(0)},${after.y.toFixed(0)}` : "probe 없음");

await page.mouse.down();
await page.waitForTimeout(2800);
await page.mouse.up();
const audioAfter = await audioSnapshot(page);
const gunStarts = audioAfter.starts - audioBefore.starts;
ok(
  "8b. 인게임 Sample 총성",
  audioAfter.running && gunStarts >= 3 && audioAfter.maxPeak >= 8,
  `deltaStarts=${gunStarts} maxPeak=${audioAfter.maxPeak} ctxs=${audioAfter.ctxs}`,
);

const autoloadLeak = consoleErrors.some((line) => /non-existent singleton '(GameState|Audio)'/.test(line));
ok("9. 오토로드는 엔진 싱글톤이 아님", !autoloadLeak);

const pageFocusEvents = await page.evaluate(() => {
  document.getElementById("canvas")?.blur();
  window.dispatchEvent(new Event("focus"));
  return { canvas: document.activeElement?.id === "canvas" };
});
ok("10. 창 포커스 복귀 시 캔버스 키 포커스", pageFocusEvents.canvas);

console.log("\n— 콘솔 에러 —");
console.log(consoleErrors.length ? consoleErrors.slice(0, 10).join("\n") : "(없음)");
console.log(`\nE2E: ${results.filter((r) => r.pass).length}/${results.length} 통과`);
await browser.close();
process.exit(process.exitCode ?? 0);
