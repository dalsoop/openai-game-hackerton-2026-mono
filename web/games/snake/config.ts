import type { GameConfig } from "@/lib/game-registry";

const config: GameConfig = {
  id: "snake",
  name: "Snake Arena",
  description: "50인 멀티플레이어 뱀 게임. 먹이를 먹고 성장, 충돌하면 사망.",
  players: "1-50",
  color: "#1f9d55",
  wsPath: "/api/ws/snake",
  godotPath: "/godot/snake",
};
export default config;
