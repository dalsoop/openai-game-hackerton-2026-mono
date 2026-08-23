import client from "prom-client";

export function createMetrics(slot) {
  const register = new client.Registry();
  register.setDefaultLabels({ slot });
  client.collectDefaultMetrics({ register });

  const startTime = Date.now();

  const gauges = {
    clients: new client.Gauge({ name: "gangup_clients_total", help: "Connected clients", registers: [register] }),
    clientsPlaying: new client.Gauge({ name: "gangup_clients_playing", help: "Clients in active matches", registers: [register] }),
    rooms: new client.Gauge({ name: "gangup_rooms_total", help: "Total rooms", registers: [register] }),
    roomsPlaying: new client.Gauge({ name: "gangup_rooms_playing", help: "Rooms in playing phase", registers: [register] }),
    roomsLobby: new client.Gauge({ name: "gangup_rooms_lobby", help: "Rooms in lobby phase", registers: [register] }),
    uptime: new client.Gauge({ name: "gangup_uptime_seconds", help: "Server uptime in seconds", registers: [register] }),
  };
  const histRtt = new client.Histogram({
    name: "gangup_rtt_ms",
    help: "Player RTT in ms",
    buckets: [5, 10, 25, 50, 100, 200, 500, 1000],
    registers: [register],
  });

  function update(clientsMap, roomsMap) {
    const alive = [...clientsMap.values()].filter((c) => !c.dead);
    gauges.clients.set(alive.length);
    gauges.clientsPlaying.set(alive.filter((c) => roomsMap.get(c.roomId)?.phase === "playing").length);
    gauges.rooms.set(roomsMap.size);
    gauges.roomsPlaying.set([...roomsMap.values()].filter((r) => r.phase === "playing").length);
    gauges.roomsLobby.set([...roomsMap.values()].filter((r) => r.phase === "lobby").length);
    gauges.uptime.set(Math.floor((Date.now() - startTime) / 1000));
    for (const c of alive) {
      if (c.rtt > 0) histRtt.observe(c.rtt);
    }
  }

  function statusJson(clientsMap, roomsMap, livingIdsFn) {
    const alive = [...clientsMap.values()].filter((c) => !c.dead);
    const rtts = alive.map((c) => c.rtt).filter((r) => r > 0);
    return {
      ok: true,
      slot,
      uptime: Math.floor((Date.now() - startTime) / 1000),
      tickHz: 20,
      clients: {
        total: alive.length,
        playing: alive.filter((c) => roomsMap.get(c.roomId)?.phase === "playing").length,
      },
      ping: {
        avg: rtts.length ? Math.round(rtts.reduce((a, b) => a + b, 0) / rtts.length) : 0,
        min: rtts.length ? Math.min(...rtts) : 0,
        max: rtts.length ? Math.max(...rtts) : 0,
      },
      players: alive.map((c) => ({
        id: c.id,
        name: c.name,
        rtt: c.rtt,
        roomId: c.roomId,
        phase: c.roomId ? roomsMap.get(c.roomId)?.phase ?? null : null,
      })),
      rooms: [...roomsMap.values()].map((r) => ({
        id: r.id,
        mode: r.mode,
        title: r.title,
        phase: r.phase,
        playerCount: livingIdsFn ? livingIdsFn(r).length : r.members.length,
      })),
    };
  }

  async function handleMetricsRequest(res) {
    const metrics = await register.metrics();
    res.writeHead(200, {
      "content-type": register.contentType,
      "access-control-allow-origin": "*",
      "cache-control": "no-store",
    });
    res.end(metrics);
  }

  function handleStatusRequest(res, clientsMap, roomsMap, livingIdsFn) {
    res.writeHead(200, {
      "content-type": "application/json",
      "access-control-allow-origin": "*",
      "cache-control": "no-store",
    });
    res.end(JSON.stringify(statusJson(clientsMap, roomsMap, livingIdsFn)));
  }

  return { register, update, handleMetricsRequest, handleStatusRequest, statusJson };
}
