import { matchMaker } from "colyseus";
import promClient from "prom-client";
import { CONFIG } from "../config.js";

const register = new promClient.Registry();
register.setDefaultLabels({ slot: CONFIG.slot });
promClient.collectDefaultMetrics({ register });

const gaugeRooms = new promClient.Gauge({ name: "gangup_rooms_total", help: "Total rooms", registers: [register] });
const gaugeClients = new promClient.Gauge({ name: "gangup_clients_total", help: "Connected clients", registers: [register] });
const gaugeUptime = new promClient.Gauge({ name: "gangup_uptime_seconds", help: "Server uptime", registers: [register] });

const SERVER_START = Date.now();

export function setupMetrics() {
  setInterval(() => {
    gaugeUptime.set(Math.floor((Date.now() - SERVER_START) / 1000));
    matchMaker.query({}).then((rooms) => {
      gaugeRooms.set(rooms.length);
      const totalClients = rooms.reduce((sum, r) => sum + r.clients, 0);
      gaugeClients.set(totalClients);
    }).catch(() => {
      gaugeRooms.set(0);
      gaugeClients.set(0);
    });
  }, CONFIG.metricsIntervalMs);
}

export { register as promRegister };
