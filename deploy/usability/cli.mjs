#!/usr/bin/env node
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { runLoad } from "./cmds/load.mjs";
import { runSmoke } from "./cmds/smoke.mjs";
import { defaultWsUrl, parseArgs } from "./lib/hub.mjs";

const args = parseArgs(process.argv.slice(2));
const cmd = args._[0] || "smoke";
const root = dirname(fileURLToPath(import.meta.url));

if (args.help || args.h) {
  console.log(`Usage:
  node cli.mjs smoke [--url wss://...] [--hold 2200]
  node cli.mjs load [--url wss://...] [--rooms 2] [--players 2] [--seconds 6]
                    [--dry-run] [--force] [--allow-prod]

Default URL: ${defaultWsUrl()}
`);
  process.exit(0);
}

let report;
if (cmd === "smoke") report = await runSmoke(args);
else if (cmd === "load") report = await runLoad(args);
else {
  console.error(`unknown command: ${cmd}`);
  process.exit(2);
}

const out = args.out || join(root, "last-report.json");
writeFileSync(out, `${JSON.stringify(report, null, 2)}\n`);
console.log(`report ${out}`);
process.exit(report.ok ? 0 : 1);
