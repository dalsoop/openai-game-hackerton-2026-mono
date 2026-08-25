import type { GamePlugin } from "../plugin.js";

const snake: GamePlugin = {
  id: "snake",
  titleKey: "GAME_SNAKE",
  maxPlayers: 4,
  godotPath: "ingame/snake",
  defaultMode: "classic",
  modes: {
    classic: {
      id: "classic",
      titleKey: "MODE_SNAKE_CLASSIC",
      blurbKey: "MODE_SNAKE_CLASSIC_BLURB",
    },
  },
  relay: {
    snapRelay: true,
    inputRelay: true,
    gameServerNotify: false,
  },
};

export default snake;
