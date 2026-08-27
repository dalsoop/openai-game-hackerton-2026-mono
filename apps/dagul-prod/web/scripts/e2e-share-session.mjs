// 로그인 세션이 있는 손님이 공유 링크만으로 방에 들어가는지 검증한다.
// 사용법: 로컬 서버(:3100)가 떠 있는 상태에서 node scripts/e2e-share-session.mjs
import { chromium } from "playwright-core";

const CHROME = `${process.env.HOME}/Library/Caches/ms-playwright/chromium-1234/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing`;
const ORIGIN = process.env.E2E_URL ? new URL(process.env.E2E_URL).origin : "http://127.0.0.1:3100";
const SHOT = "/tmp/e2e-share-session";
const results = [];

function ok(name, cond, extra = "") {
  results.push({ name, pass: !!cond });
  console.log(`${cond ? "  ✓" : "  ✗"} ${name}${extra ? ` — ${extra}` : ""}`);
  if (!cond) process.exitCode = 1;
}

async function browser() {
  return chromium.launch({
    executablePath: process.env.CHROME_PATH || CHROME,
    headless: true,
    args: ["--enable-webgl", "--ignore-gpu-blocklist", "--use-angle=metal", "--autoplay-policy=no-user-gesture-required"],
  });
}

async function newPage(b) {
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  page.setDefaultTimeout(25000);
  return { ctx, page };
}

async function introStart(page, name) {
  const input = page.locator("input[name=player-name]");
  await input.waitFor({ timeout: 45000 });
  await input.fill("");
  await input.fill(name);
  await page.waitForFunction((n) => {
    const el = document.querySelector("input[name=player-name]");
    return el instanceof HTMLInputElement && el.value === n;
  }, name);
  await page.evaluate(() => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r))));
  await page.getByRole("button", { name: "시작하기" }).click();
  await page.waitForFunction((n) => window.localStorage.getItem("gangup_nickname") === n, name, { timeout: 10000 }).catch(() => {});
}

async function hostCreateLocked(page, title) {
  await page.goto(`${ORIGIN}/ko`, { waitUntil: "domcontentloaded" });
  await introStart(page, "세션호스트");
  await page.locator("a.lobby-create-link").waitFor({ state: "visible", timeout: 45000 });
  await page.getByText("접속됨").waitFor({ timeout: 45000 });
  await page.locator("a.lobby-create-link").click();
  await page.waitForSelector("form.create-form");
  await page.locator("input[name=title]").fill(title);
  await page.locator(".option-card").filter({ hasText: "비밀번호" }).click();
  await page.locator("form.create-form button.cta").click();
  await page.getByRole("button", { name: /게임 시작|초 후 시작/ }).waitFor({ timeout: 45000 });
  await page.getByRole("button", { name: "방 공유" }).click();
  await page.waitForSelector("[role=dialog] .share-url");
  return (await page.locator("[role=dialog] .share-url").textContent()) ?? "";
}

function nickStored(page) {
  return page.evaluate(() => window.localStorage.getItem("gangup_nickname"));
}

const b = await browser();

try {
  const { page: host } = await newPage(b);
  const shareUrl = await hostCreateLocked(host, "세션공유방");
  await host.screenshot({ path: `${SHOT}-1-host.png` });
  ok("1. 호스트 공유 URL", /room=/.test(shareUrl) && /pw=\d{4}/.test(shareUrl), shareUrl);

  // 2) 세션 없는 첫 방문 — 인트로가 남는다 (시작하기는 누르지 않는다)
  const { ctx: freshCtx, page: fresh } = await newPage(b);
  await fresh.goto(shareUrl, { waitUntil: "domcontentloaded" });
  const introVisible = await fresh.getByRole("button", { name: "시작하기" }).waitFor({ timeout: 20000 }).then(() => true).catch(() => false);
  const storedFresh = await nickStored(fresh);
  await fresh.screenshot({ path: `${SHOT}-2-fresh-intro.png` });
  ok("2. 세션 없으면 인트로(시작하기)가 남는다", introVisible === true, `stored=${storedFresh}`);
  await freshCtx.close();

  // 3) 다른 컨텍스트에서 먼저 로그인(로비)해 닉을 저장한다 — 공유 링크는 아직 안 연다
  const { ctx: sessionCtx, page: guest } = await newPage(b);
  await guest.goto(`${ORIGIN}/ko`, { waitUntil: "domcontentloaded" });
  await introStart(guest, "세션게스트");
  await guest.locator("a.lobby-create-link").waitFor({ state: "visible", timeout: 45000 });
  await guest.getByText("접속됨").waitFor({ timeout: 45000 });
  const storedAfterLogin = await nickStored(guest);
  await guest.screenshot({ path: `${SHOT}-3-logged-lobby.png` });
  ok("3. 인트로 한 번 지나면 닉이 저장된다", storedAfterLogin === "세션게스트", storedAfterLogin ?? "null");

  // 4) 이미 로그인된 탭에서 공유 링크만 연다 — 시작하기를 누르지 않는다
  await guest.goto(shareUrl, { waitUntil: "domcontentloaded" });
  const joined = await guest.getByText("대기실").waitFor({ timeout: 45000 }).then(() => true).catch(() => false);
  const startLeft = await guest.getByRole("button", { name: "시작하기" }).count();
  const body = await guest.locator("body").innerText();
  const seesHost = body.includes("세션호스트");
  const seesGuest = body.includes("세션게스트");
  await guest.screenshot({ path: `${SHOT}-4-session-link.png` });
  ok("4. 로그인 세션은 링크만으로 대기실에 들어간다", joined === true);
  ok("4b. 시작하기 화면에 머물지 않는다", startLeft === 0, `startButtons=${startLeft}`);
  ok("4c. 호스트와 게스트가 서로 보인다", seesHost && seesGuest, `host=${seesHost} guest=${seesGuest}`);

  await host.getByRole("button", { name: "닫기" }).first().click().catch(() => {});
  const hostBody = await host.locator("body").innerText();
  await host.screenshot({ path: `${SHOT}-5-host-sees-guest.png` });
  ok("5. 호스트 대기실에 세션 게스트가 나타난다", hostBody.includes("세션게스트"), hostBody.slice(0, 240));

  await sessionCtx.close();
  await host.context().close();
} finally {
  await b.close();
}

const passed = results.filter((r) => r.pass).length;
console.log(`\n${passed}/${results.length} passed`);
if (passed !== results.length) process.exit(1);
