import { defineConfig } from "vitest/config";
import path from "node:path";

// @/ 별칭은 tsconfig 와 동일하게 web 루트를 가리킨다.
export default defineConfig({
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
  },
  resolve: {
    alias: { "@": path.resolve(import.meta.dirname, ".") },
  },
});
