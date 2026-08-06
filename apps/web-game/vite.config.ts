import { defineConfig } from "vite";

// GitHub Pages project site: https://dalsoop.github.io/wasd-co-op-racing-mono/
// 로컬 dev 는 base `/` 유지 (command === 'serve')
export default defineConfig(({ command }) => ({
  base: command === "build" ? "/wasd-co-op-racing-mono/" : "/",
  server: {
    host: true,
    port: 5173,
  },
  build: {
    target: "es2022",
  },
}));
