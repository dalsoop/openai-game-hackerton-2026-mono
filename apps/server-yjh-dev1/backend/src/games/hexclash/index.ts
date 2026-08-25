import type { GamePlugin } from "../plugin.js";

const hexclash: GamePlugin = {
  id: "hexclash",
  titleKey: "GAME_HEXCLASH",
  maxPlayers: 6,
  godotPath: "ingame/hexclash",
  defaultMode: "standard",
  modes: {
    standard: {
      id: "standard",
      titleKey: "MODE_HEXCLASH_STANDARD",
      blurbKey: "MODE_HEXCLASH_STANDARD_BLURB",
    },
  },
  relay: {
    snapRelay: true,
    inputRelay: true,
    gameServerNotify: false,
  },
};

export default hexclash;
