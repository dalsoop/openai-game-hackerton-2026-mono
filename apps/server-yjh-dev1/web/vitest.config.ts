import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "node:path";

// @/ 별칭은 tsconfig 와 동일하게 web 루트를 가리킨다.
export default defineConfig({
  plugins: [react()], // tsconfig(js: preserve)와 무관하게 JSX 변환 보장
  test: {
    environment: "node",
    include: ["tests/**/*.test.{ts,tsx}"],
  },
  // tsconfig 은 Next 관례상 jsx: preserve — 테스트 변환기는 automatic 으로 직접 지정.
  // (vite 루트 옵션이다 — test 안에 두면 무시된다)
  esbuild: { jsx: "automatic", tsconfigRaw: { compilerOptions: { jsx: "react-jsx" } } },
  resolve: {
    alias: { "@": path.resolve(import.meta.dirname, ".") },
  },
});
