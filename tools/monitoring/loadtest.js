import WebSocket from "ws";

const URL = process.argv[2] || "ws://127.0.0.1:9120";
const COUNT = Number(process.argv[3] || 8);
const DURATION_S = Number(process.argv[4] || 15);

const clients = [];

function connect(i) {
  return new Promise((resolve) => {
    const ws = new WebSocket(URL);
    const c = { ws, id: null, name: `bot${i}`, rtt: 0, pings: 0 };

    ws.on("open", () => {
      ws.send(JSON.stringify({ t: "hello", name: c.name, mode: "classic" }));
    });

    ws.on("message", (raw) => {
      const msg = JSON.parse(String(raw));
      if (msg.t === "welcome") {
        c.id = msg.id;
        resolve(c);
      }
      if (msg.t === "ping") {
        ws.send(JSON.stringify({ t: "pong", ts: msg.ts }));
        c.pings++;
      }
      if (msg.t === "pong" && typeof msg.ts === "number") {
        c.rtt = Date.now() - msg.ts;
      }
    });

    ws.on("error", () => resolve(null));
    clients.push(c);
  });
}

async function run() {
  console.log(`connecting ${COUNT} bots to ${URL}...`);
  const results = await Promise.all(Array.from({ length: COUNT }, (_, i) => connect(i)));
  const connected = results.filter(Boolean);
  console.log(`${connected.length}/${COUNT} connected`);

  if (connected.length === 0) { process.exit(1); }

  const host = connected[0];
  host.ws.send(JSON.stringify({ t: "create" }));
  await new Promise((r) => setTimeout(r, 300));

  for (let i = 1; i < connected.length; i++) {
    connected[i].ws.send(JSON.stringify({ t: "rooms" }));
    await new Promise((r) => setTimeout(r, 100));
    connected[i].ws.send(JSON.stringify({ t: "join", roomId: "r1" }));
    await new Promise((r) => setTimeout(r, 100));
  }

  console.log(`all in room, starting game...`);
  host.ws.send(JSON.stringify({ t: "start" }));
  await new Promise((r) => setTimeout(r, 500));

  const pingInterval = setInterval(() => {
    for (const c of connected) {
      if (c.ws.readyState === 1) {
        c.ws.send(JSON.stringify({ t: "ping", ts: Date.now() }));
        c.ws.send(JSON.stringify({
          t: "input",
          mx: Math.random() > 0.5 ? 1 : -1,
          my: Math.random() > 0.5 ? 1 : -1,
          fire: Math.random() > 0.3,
          dash: false, use: false,
          aimX: 400 + Math.random() * 800,
          aimY: 200 + Math.random() * 500,
        }));
      }
    }
  }, 200);

  console.log(`running for ${DURATION_S}s with random inputs...`);
  await new Promise((r) => setTimeout(r, DURATION_S * 1000));
  clearInterval(pingInterval);

  console.log(`\n=== results ===`);
  for (const c of connected) {
    console.log(`  ${c.name}: rtt=${c.rtt}ms  pongs=${c.pings}`);
  }

  const rtts = connected.map((c) => c.rtt).filter((r) => r > 0);
  if (rtts.length) {
    console.log(`\n  avg: ${Math.round(rtts.reduce((a, b) => a + b, 0) / rtts.length)}ms`);
    console.log(`  min: ${Math.min(...rtts)}ms`);
    console.log(`  max: ${Math.max(...rtts)}ms`);
  }

  console.log(`\nchecking /status...`);
  const httpUrl = URL.replace("ws://", "http://").replace("wss://", "https://");
  const res = await fetch(`${httpUrl}/status`);
  const status = await res.json();
  console.log(`  clients: ${status.clients.total}  playing: ${status.clients.playing}`);
  console.log(`  rooms: ${status.rooms.length}  ping avg: ${status.ping.avg}ms`);
  console.log(`  players:`);
  for (const p of status.players) {
    console.log(`    ${p.name}: ${p.rtt}ms (${p.phase})`);
  }

  for (const c of connected) c.ws.close();
  console.log(`\ndone.`);
  process.exit(0);
}

run();
