import { chromium } from "playwright-core";

const CHROME = `${process.env.HOME}/Library/Caches/ms-playwright/chromium-1234/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing`;
const URL = process.env.E2E_URL || "https://server-prod.external.kr/ko";

const browser = await chromium.launch({
  executablePath: CHROME,
  headless: true,
  args: ["--enable-webgl", "--ignore-gpu-blocklist", "--use-angle=metal"],
});
const page = await (await browser.newContext({ viewport: { width: 1280, height: 800 } })).newPage();
const logs = [];
const failed = [];
page.on("console", (m) => logs.push(`${m.type()}: ${m.text()}`));
page.on("pageerror", (e) => logs.push(`PAGEERROR: ${e.message}\n${e.stack ?? ""}`));
page.on("requestfailed", (r) => failed.push(`${r.failure()?.errorText} ${r.url()}`));
page.on("response", (r) => {
  if (r.status() >= 400) {failed.push(`HTTP ${r.status()} ${r.url()}`);}
});

await page.goto(URL, { waitUntil: "networkidle" });
const nameBox = page.locator("input[name=player-name]").first();
await nameBox.waitFor({ state: "visible", timeout: 45_000 });
await nameBox.fill("널진단");
await page.click("text=시작하기");
await page.locator("a.lobby-create-link").waitFor({ state: "visible", timeout: 45_000 });
await page.locator("a.lobby-create-link").click();
await page.waitForSelector("form.create-form", { timeout: 45_000 });
await page.click("form.create-form button.cta");
await page.waitForSelector("text=게임 시작", { timeout: 45_000 });
await page.click("text=게임 시작");
await page.waitForSelector(".gc-error-box, #godot-canvas", { timeout: 120_000 });
await page.waitForTimeout(8_000);
const box = await page.locator(".gc-error-box").innerText().catch(() => "");
await page.screenshot({ path: "/tmp/e2e-null-now.png" });
console.log("=== ERROR BOX ===\n" + box);
console.log("=== FAILED ===\n" + (failed.slice(0, 40).join("\n") || "(none)"));
console.log("=== LOGS ===\n" + logs.filter((l) => /null|abort|Error|error|wasm|dylib|fail/i.test(l)).slice(0, 40).join("\n"));
await browser.close();
