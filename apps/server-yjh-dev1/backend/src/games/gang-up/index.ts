import type { GamePlugin } from "../plugin.js";

const gangUp: GamePlugin = {
  id: "gang-up",
  titleKey: "GAME_GANG_UP",
  maxPlayers: 8,
  godotPath: "ingame/gang-up",
  defaultMode: "full",
  modes: {
    full: {
      id: "full",
      titleKey: "MODE_FULL",
      blurbKey: "MODE_FULL_BLURB",
    },
  },
  relay: {
    snapRelay: true,
    inputRelay: true,
    gameServerNotify: true,
  },
};

export default gangUp;
