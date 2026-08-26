import { chromium } from "playwright-core";

export const CHROME = `${process.env.HOME}/Library/Caches/ms-playwright/chromium-1234/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing`;
export const PAGE_URL = process.env.E2E_URL || "http://127.0.0.1:3100/ko";
export const ORIGIN = new URL(PAGE_URL).origin;
export const SHOT = "/tmp/e2e-dagul";

export const results = [];

export function ok(name, cond, extra = "") {
  results.push({ name, pass: !!cond });
  console.log(`${cond ? "  ✓" : "  ✗"} ${name}${extra ? ` — ${extra}` : ""}`);
  if (!cond) process.exitCode = 1;
}

export async function launchPage() {
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_PATH || CHROME,
    headless: true,
    args: [
      "--enable-webgl",
      "--ignore-gpu-blocklist",
      "--use-angle=metal",
      "--autoplay-policy=no-user-gesture-required",
    ],
  });
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await ctx.newPage();
  return { browser, page };
}

export function attachConsole(page) {
  const consoleErrors = [];
  page.on("console", (m) => { if (m.type() === "error") {consoleErrors.push(m.text());} });
  page.on("pageerror", (e) => consoleErrors.push(`PAGEERROR: ${e.message}`));
  return consoleErrors;
}
