import type { GameConfig } from "@/lib/game-registry";

const config: GameConfig = {
  id: "hex",
  name: "Hex Clash",
  description: "6인 실시간 영토 전쟁. 헥스 그리드 위에서 에너지로 점령, 3분 후 최다 승리.",
  players: "1-6",
  color: "#2f6bff",
  wsPath: "/api/ws/hex",
  godotPath: "/godot/hex",
};
export default config;
