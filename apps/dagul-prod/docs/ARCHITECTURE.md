# dagul-prod Architecture Documents (v2)

8-document series covering the dagul-prod game architecture.
Each document is published as a Claude Artifact and linked below.

## Onboarding Path

New to the project? Read in this order:

1. **Controller Map** — what exists and where
2. **Core Flows** — how the three main flows work
7. **Local Dev** — how to set up and run locally

## Document Index

| # | Title | Description | Link |
|---|-------|-------------|------|
| 01 | Controller Map | Server, client, frontend controller inventory + quick-reference table | [Open](https://claude.ai/code/artifact/60f3b45d-0b72-49d6-8c9b-200142d2d01d) |
| 02 | Core Flows | Room creation → game start, one combat tick, reconnection — 3 sequence diagrams | [Open](https://claude.ai/code/artifact/8eadbd44-24e9-4334-8ee2-bd810356483b) |
| 03 | Server: Colyseus Hub | server.ts single-hub structure, tick pipeline (default 60Hz), Redis roles | [Open](https://claude.ai/code/artifact/60e88ced-e080-4f2e-be1d-624737baf474) |
| 04 | Godot Client | Autoload chain, scene tree, signal wiring, core↔games dependency direction | [Open](https://claude.ai/code/artifact/ea0b72b5-a1b4-4162-9fd9-0cb624bdd645) |
| 05 | Godot-React Bridge | wire contract, page-bridge, dual i18n, check-contract.mjs build gate | [Open](https://claude.ai/code/artifact/ac04b820-4362-4b86-bd95-24ea3f9146b9) |
| 06 | Deploy & Infra | CI workflows, Godot build pipeline, Helm deploy, Cloudflare, monitoring | [Open](https://claude.ai/code/artifact/e9a2dd74-6a9a-43a2-b828-9c7bd53e554a) |
| 07 | Local Dev Handover | dev.sh setup, npm scripts, prod differences, troubleshooting | [Open](https://claude.ai/code/artifact/2aa23ca9-87ff-476e-b6fa-f2c3c445eac8) |
| 08 | Characters, Combat & Reconnect | Character catalog, ultimate system (66 functions), combat balance, CPU bot AI, reconnection flow | [Open](https://claude.ai/code/artifact/b8dca18d-f4f9-489c-89d1-d03f4bba5bc3) |

**Full index with visual cards**: [Architecture Index v2](https://claude.ai/code/artifact/6de695d7-b654-4c43-9750-bfbbb5208cbd)

## v1 Deprecation

The previous 16-document series (v1) is superseded by this 8-document set.
v1 artifact links remain accessible but will not be updated.

## Baseline

Verified against commit `fe81c54` (PR #170 merge) and subsequent corrections.
