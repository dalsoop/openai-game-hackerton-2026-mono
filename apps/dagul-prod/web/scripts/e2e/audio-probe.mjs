/** Godot 웹 Sample 재생을 AudioBufferSourceNode.start · 시간축 피크로 잰다. */

export async function installAudioProbe(page) {
  await page.addInitScript(() => {
    window.__audioProbe = { starts: 0, peaks: [], states: [], ctxs: 0 };
    const Orig = window.AudioContext || window.webkitAudioContext;
    if (!Orig) {return;}
    const tap = (ctx) => {
      window.__audioProbe.ctxs += 1;
      window.__audioProbe.states.push(ctx.state);
      ctx.addEventListener("statechange", () => {
        window.__audioProbe.states.push(ctx.state);
      });
      try {
        const analyser = ctx.createAnalyser();
        analyser.fftSize = 2048;
        const dest = ctx.destination;
        const connect = AudioNode.prototype.connect;
        AudioNode.prototype.connect = function (...args) {
          const out = connect.apply(this, args);
          if (args[0] === dest && this !== analyser) {
            try { connect.call(this, analyser); } catch { /* already */ }
          }
          return out;
        };
        const data = new Uint8Array(analyser.fftSize);
        const tick = () => {
          analyser.getByteTimeDomainData(data);
          let peak = 0;
          for (let i = 0; i < data.length; i++) {
            peak = Math.max(peak, Math.abs(data[i] - 128));
          }
          if (peak > 2) {window.__audioProbe.peaks.push(peak);}
          requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
      } catch (e) {
        window.__audioProbe.tapError = String(e);
      }
    };
    class Wrapped extends Orig {
      constructor(opts) {
        super(opts);
        tap(this);
      }
    }
    window.AudioContext = Wrapped;
    if (window.webkitAudioContext) {window.webkitAudioContext = Wrapped;}
    const proto = AudioBufferSourceNode.prototype;
    const origStart = proto.start;
    proto.start = function (...args) {
      window.__audioProbe.starts += 1;
      return origStart.apply(this, args);
    };
  });
}

export async function audioSnapshot(page) {
  return page.evaluate(() => {
    const p = window.__audioProbe || {};
    const peaks = p.peaks || [];
    let maxPeak = 0;
    for (const n of peaks) {maxPeak = Math.max(maxPeak, n);}
    return {
      starts: p.starts || 0,
      ctxs: p.ctxs || 0,
      running: (p.states || []).includes("running"),
      maxPeak,
      tapError: p.tapError || "",
    };
  });
}

export async function stripNextOverlay(page) {
  await page.evaluate(() => {
    document.querySelector("nextjs-portal")?.remove();
    for (const n of document.querySelectorAll("[data-nextjs-toast], [data-nextjs-dialog-overlay]")) {
      n.remove();
    }
  });
}
