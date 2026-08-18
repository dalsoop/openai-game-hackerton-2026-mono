import { defineConfig } from "vite";

// GitHub Pages: https://dalsoop.github.io/openai-game-hackerton-2026-mono/
// 로컬 dev 는 base `/` 유지 (command === 'serve')
export default defineConfig(({ command }) => ({
  base: command === "build" ? "/openai-game-hackerton-2026-mono/" : "/",
  server: {
    host: true,
    port: 5173,
  },
  build: {
    target: "es2022",
  },
}));
