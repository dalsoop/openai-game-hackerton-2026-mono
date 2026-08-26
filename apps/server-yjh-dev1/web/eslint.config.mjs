// 네이티브 flat config — eslint-config-next v16 은 flat 배열을 바로 내보낸다.
// FlatCompat(eslintrc 호환) 경로는 v16 과 순환 참조로 깨지니 쓰지 않는다.
import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import nextTypescript from "eslint-config-next/typescript";
import i18nextPlugin from "eslint-plugin-i18next";

// 허브 계약 리터럴 — 값은 lib/hub/config.ts 정본만 쓴다 (한글 규칙과 같이 묶음).
const CONTRACT_SYNTAX = [
  {
    selector: "Literal[value=/^gangup_/]",
    message: "핸드오프 키 리터럴 금지 — lib/contract HANDOFF 상수로.",
  },
  {
    selector: "CallExpression[callee.property.name=/^(send|onMessage|broadcast)$/] > Literal[value=/^(welcome|hello|rooms|create|join|leave|start|kick|input|host_snap|snap|peer_input|peer_parked|peer_reclaimed|joined|peers|left|kicked|room_toggle|lobby|error|ping|pong|dropped|resume|mode)$/]",
    message: "메시지 타입 리터럴 금지 — lib/contract MSG 또는 LIST_MSG 상수로.",
  },
  {
    selector: "CallExpression[callee.property.name='onMessage'] > Literal[value=/^[+-]$/]",
    message: "리스트 룸 프로토콜 리터럴 금지 — lib/hub/config.ts LIST_MSG 상수로.",
  },
  {
    selector: "CallExpression[callee.property.name='leave'] > Literal[value=4000]",
    message: "종료 코드 리터럴 금지 — lib/hub/config.ts CLOSE_CODE 상수로.",
  },
];

const KOREAN_SYNTAX = {
  selector: "Literal[value=/[가-힣]/]",
  message: "하드코딩 한글 금지 — messages/*.json(i18n) 또는 lib/hub/config.ts KO 상수로. 예외는 eslint-disable + 사유.",
};

const GODOT_PACK_SYNTAX = [
  {
    selector: "TemplateLiteral[quasis.0.value.raw='/godot/'][expressions.0.name=/^(game|gameId)$/]",
    message: "/godot/${game} 금지 — packOf 결과만 경로에 넣는다.",
  },
  {
    selector: "TemplateLiteral[quasis.0.value.raw='/godot/'][expressions.0.property.name='id']",
    message: "/godot/${*.id} 금지 — packOf 결과만 경로에 넣는다.",
  },
  {
    selector: "Literal[value=/^\\/godot\\/[a-z0-9-]+/]",
    message: "팩 경로 리터럴 금지 — godotAssetUrl 또는 catalog pack 필드.",
  },
];

const JPEG_SYNTAX = [
  {
    selector: "Literal[value=/\\.jpe?g(\\b|[?#\"']|$)/i]",
    message: "JPEG 금지 — 정적 이미지는 webp 이상(webp/avif). 자리 표시도 jpg/jpeg 를 쓰지 않는다.",
  },
  {
    selector: "TemplateElement[value.cooked=/\\.jpe?g/i]",
    message: "JPEG 금지 — 정적 이미지는 webp 이상(webp/avif). 자리 표시도 jpg/jpeg 를 쓰지 않는다.",
  },
];

const PAGE_HOOK_SYNTAX = {
  selector: "CallExpression > MemberExpression > Identifier[name='useEffect'], CallExpression > MemberExpression > Identifier[name='useState'], CallExpression > MemberExpression > Identifier[name='useRef'], CallExpression > MemberExpression > Identifier[name='useCallback']",
  message: "page.tsx 렌더 전용 — 로직/상태/이펙트는 hooks/ 로. 페이즈 판단도 컴포넌트 밖에서.",
};

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
      // || 폴스티 삼킴 방지 — 널 병합은 ?? 로만 (문자열 ""·숫자 0·false 오용 차단)
      "@typescript-eslint/prefer-nullish-coalescing": "error",
      // 하드코딩 한글·계약 리터럴 금지 — 문구는 i18n/KO, 프로토콜은 config 상수
      "no-restricted-syntax": ["error", KOREAN_SYNTAX, ...CONTRACT_SYNTAX, ...GODOT_PACK_SYNTAX, ...JPEG_SYNTAX],

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
    rules: {
      "no-console": "off",
      "no-restricted-syntax": ["error", ...GODOT_PACK_SYNTAX, ...JPEG_SYNTAX],
    },
  },

  // next.config.ts — Next API 계약상 headers/rewrites 는 async 시그니처를 요구한다
  {
    files: ["next.config.ts"],
    rules: { "require-await": "off" },
  },

  // 한글 리터럴 예외 — 테스트 설명문은 제품 문구가 아니다.
  // lib/hub/config.ts KO 는 서버→클라 안내문의 지정 SSOT다.
  {
    files: ["tests/**/*.{ts,tsx}", "lib/hub/config.ts", "lib/contract/**/*.ts"],
    rules: { "no-restricted-syntax": "off" },
  },

  // page.tsx·components 는 렌더 전용 — 상태·이펙트·페이즈 판단 로직이 새어들어오면
  // 이 규칙이 막는다. 수명주기·구독은 hooks/(어댑터)나 lib/(클래스)로 가야 한다.
  // 컴포넌트 국소 입력 상태도 금지 — 비제어 폼(FormData)으로 해소한다.
  {
    files: ["app/**/page.tsx", "components/**/*.tsx"],
    rules: {
      "no-restricted-syntax": ["error", PAGE_HOOK_SYNTAX, KOREAN_SYNTAX, ...CONTRACT_SYNTAX, ...GODOT_PACK_SYNTAX, ...JPEG_SYNTAX],
    },
  },

  // 조합 루트 훅(hooks/) — 분해 후에도 콜백 수만으로 분기가 몰린다: 상한 완화.
  // 순수 로직 기준(15)은 lib/·components/ 에 그대로 적용된다.
  {
    files: ["hooks/**/*.ts"],
    rules: { "complexity": ["error", 18] },
  },

  // 에러 경계 — 프로바이더/CSS 를 신뢰할 수 없는 최후 폴백이므로
  // console.error 와 인라인 스타일이 정당하다 (Next 공식 패턴).
  {
    files: ["lib/**/*.ts"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: ["@/*"],
              message: "lib/ 는 상대 경로만 쓴다. @/ 는 컴포넌트·훅 전용이다.",
            },
          ],
        },
      ],
    },
  },

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
