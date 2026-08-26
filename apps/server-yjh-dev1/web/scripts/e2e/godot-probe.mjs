export function attachReconnectWatch(page) {
  const reconnectHits = [];
  page.on("request", (req) => {
    if (req.url().includes("/matchmake/reconnect")) {reconnectHits.push(req.url());}
  });
  return reconnectHits;
}

export async function installMatchProbe(page) {
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
}

export function godotOwnedReconnects(reconnectHits, jsReconnect) {
  return reconnectHits.filter((url) => {
    const hit = jsReconnect.find((j) => url.includes(j.u) || j.u.includes(url));
    if (!hit) {return true;}
    return /\/godot\//.test(hit.stack);
  });
}

export async function waitStartEnabled(page, timeout = 90_000) {
  await page.waitForFunction(() => {
    const b = [...document.querySelectorAll("button")].find((el) => el.textContent?.includes("게임 시작"));
    return Boolean(b && !b.disabled);
  }, null, { timeout });
}

export async function waitMatchStart(page, timeout = 90_000) {
  return page.evaluate(
    (ms) => new Promise((resolve) => {
      if (window.__e2eMatchStarted) {resolve(true); return;}
      window.addEventListener("godot-match-start", () => resolve(true), { once: true });
      setTimeout(() => resolve(false), ms);
    }),
    timeout,
  );
}
