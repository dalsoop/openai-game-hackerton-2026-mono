export interface GameConfig {
  id: string;
  name: string;
  description: string;
  players: string;
  color: string;
  wsPath: string;
  godotPath: string;
}

import dagul from "@/games/dagul/config";
import snake from "@/games/snake/config";
import hex from "@/games/hex/config";

export const GAMES: GameConfig[] = [dagul, snake, hex];

export function getGame(id: string): GameConfig | undefined {
  return GAMES.find((g) => g.id === id);
}
