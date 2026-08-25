// 네이티브 flat config — eslint-config-next v16 은 flat 배열을 바로 내보낸다.
// FlatCompat(eslintrc 호환) 경로는 v16 과 순환 참조로 깨지니 쓰지 않는다.
import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import nextTypescript from "eslint-config-next/typescript";
import i18nextPlugin from "eslint-plugin-i18next";

const config = [
  // public/godot 는 Godot 빌드 산출물(wasm glue) — 생성물은 lint 하지 않는다.
  { ignores: ["dist/", ".next/", "node_modules/", "styles/", "public/"] },

  ...nextCoreWebVitals,
  ...nextTypescript,

  {
    files: ["**/*.{ts,tsx}"],
    languageOptions: {
      parserOptions: {
        projectService: {
          allowDefaultProject: ["server.ts"], // tsconfig.server.json 소관 — 루트 tsconfig 밖
        },
        tsconfigRootDir: import.meta.dirname,
      },
    },
    plugins: { i18next: i18nextPlugin },
    rules: {
      // JSX 텍스트 하드코딩 금지 — 모든 사용자 문구는 messages/*.json 로.
      "i18next/no-literal-string": [
        "error",
        {
          mode: "jsx-text-only",
          ignorePattern: "^(→|←|·|👑|\\s)+$",
        },
      ],
    },
  },

  {
    files: ["**/*.{ts,tsx}"],
    rules: {
      // TypeScript 엄격 — 경고 없이 전부 에러
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "@typescript-eslint/explicit-function-return-type": "error",
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/no-misused-promises": "error",
      "@typescript-eslint/await-thenable": "error",
      "@typescript-eslint/no-inferrable-types": "error",
      "@typescript-eslint/consistent-type-imports": ["error", { prefer: "type-imports" }],
      // enum switch 완전성 — GamePhase/HubStatus 분기 누락 방지
      "@typescript-eslint/switch-exhaustiveness-check": "error",
      // non-null 단정(!) 금지 — 런타임 크래시 원천 봉쇄
      "@typescript-eslint/no-non-null-assertion": "error",
      // 항상 참/거짓 조건·불필요한 선택체인 제거 (타입 정보 기반)
      "@typescript-eslint/no-unnecessary-condition": "error",
      // 불필요한 async·else-return 금지 — 평탄한 제어흐름 유지
      "require-await": "error",
      "no-else-return": "error",

      // React — 인라인 스타일 전면 금지 (동적 값은 eslint-disable + 사유 주석)
      // no-inline-styles 규칙은 이 버전에 없어서 DOM+컴포넌트 양쪽 style prop 을 차단한다.
      "react/forbid-dom-props": ["error", { forbid: ["style"] }],
      "react/forbid-component-props": ["error", { forbid: ["style"] }],
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "error",
      "react/no-array-index-key": "error",
      "react/no-unescaped-entities": "error",
      "react/jsx-key": "error",
      "react/react-in-jsx-scope": "off", // React 17+ 불필요
      "react/prop-types": "off", // TypeScript 사용
      "react/no-unstable-nested-components": "error",

      // Next.js
      "@next/next/no-html-link-for-pages": "error",
      "@next/next/no-img-element": "error",

      // 코드 품질 — 크기 경질화 (GD "파일 700줄" 규칙의 웹 버전)
      "max-lines": ["error", { max: 300, skipBlankLines: true, skipComments: true }],
      "complexity": ["error", 15],
      "max-depth": ["error", 2], // if/for/while 중첩 2단 초과 금지 — GD MAX_NESTING 와 동일 기준
      "max-nested-callbacks": ["error", 4],
      "no-console": "error",
      "prefer-const": "error",
      "no-var": "error",
      "eqeqeq": ["error", "always", { null: "ignore" }],
      "curly": ["error", "all"],
      "no-constant-condition": "error",
      "no-empty": ["error", { allowEmptyCatch: false }],

      // 접근성
      "jsx-a11y/alt-text": "error",
      "jsx-a11y/click-events-have-key-events": "error",
      "jsx-a11y/no-static-element-interactions": "error",
      "jsx-a11y/anchor-is-valid": "error",

      // 보안
      "react/jsx-no-target-blank": "error",
    },
  },

  // 서버·스크립트 — console 은 정상 도구
  {
    files: ["server.ts", "scripts/**/*.{mjs,ts,js}"],
    rules: { "no-console": "off" },
  },

  // next.config.ts — Next API 계약상 headers/rewrites 는 async 시그니처를 요구한다
  {
    files: ["next.config.ts"],
    rules: { "require-await": "off" },
  },

  // 에러 경계 — 프로바이더/CSS 를 신뢰할 수 없는 최후 폴백이므로
  // console.error 와 인라인 스타일이 정당하다 (Next 공식 패턴).
  {
    files: ["app/**/error.tsx", "app/global-error.tsx"],
    rules: {
      "no-console": "off",
      "react/forbid-dom-props": "off",
      "react/forbid-component-props": "off",
    },
  },
];

export default config;
