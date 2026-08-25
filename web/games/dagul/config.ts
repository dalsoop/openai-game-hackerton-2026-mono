import type { GameConfig } from "@/lib/game-registry";

const config: GameConfig = {
  id: "dagul",
  name: "다굴",
  description: "8인 탑다운 배틀로얄. 12종 동물 캐릭터, 세이프존 수축, 최후의 1인이 승리.",
  players: "1-8",
  color: "#d4a843",
  wsPath: "/api/ws/dagul",
  godotPath: "/godot/dagul",
};
export default config;
