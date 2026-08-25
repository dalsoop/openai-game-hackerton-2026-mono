import tseslint from "typescript-eslint";

export default tseslint.config(
  {
    ignores: ["src/_legacy/**", "src/i18n/i18n-*.ts", "src/i18n/formatters.ts", "src/i18n/i18n-node.ts"],
  },
  ...tseslint.configs.recommended,
  {
    files: ["src/**/*.ts"],
    rules: {
      "no-console": "error",
      "no-restricted-syntax": [
        "error",
        {
          selector: ":not(IfStatement, ConditionalExpression, WhileStatement, ForStatement, DoWhileStatement) > LogicalExpression[operator='||']:not([parent.type='LogicalExpression'])",
          message: "|| 폴백 금지 — 삼항 또는 함수로 처리합니다. 조건문(if/while/for/삼항)은 허용.",
        },
        {
          selector: ":not(IfStatement, ConditionalExpression) > LogicalExpression[operator='??']",
          message: "?? 금지 — 삼항 또는 함수로 처리합니다.",
        },
      ],
    },
  },
  {
    files: ["src/index.ts"],
    rules: {
      "no-console": "off",
    },
  },
);
