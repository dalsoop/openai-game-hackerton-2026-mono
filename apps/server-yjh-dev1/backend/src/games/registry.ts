import type { GamePlugin } from "./plugin.js";
import gangUp from "./gang-up/index.js";
import hexclash from "./hexclash/index.js";
import snake from "./snake/index.js";

const ALL_GAMES: GamePlugin[] = [gangUp, hexclash, snake];

const registry = new Map<string, GamePlugin>();
for (const game of ALL_GAMES) {
  if (registry.has(game.id)) {
    throw new Error(`duplicate game id: ${game.id}`);
  }
  registry.set(game.id, game);
}

export function getGame(id: string): GamePlugin | undefined {
  return registry.get(id);
}

export function allGames(): GamePlugin[] {
  return ALL_GAMES;
}

export function defaultGame(): GamePlugin {
  return ALL_GAMES[0]!;
}
