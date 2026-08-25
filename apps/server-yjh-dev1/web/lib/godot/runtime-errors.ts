// Godot 런타임 오류 코드 — 문구는 messages/*.json 이 정본.
// 런타임은 코드만 던지고, UI 가 이 매핑으로 i18n 키를 얻는다.
export type RuntimeErrorCode =
  | "engine-missing"
  | "engine-load-failed"
  | "match-signal-missing";

const KEYS: Record<RuntimeErrorCode, string> = {
  "engine-missing": "game.errors.engineMissing",
  "engine-load-failed": "game.errors.engineLoadFailed",
  "match-signal-missing": "game.errors.matchSignalMissing",
};

/** 알려진 코드면 i18n 키, 아니면 원문 그대로(외부 예외 메시지 등). */
export function runtimeErrorKey(code: string): string {
  return (code in KEYS) ? KEYS[code as RuntimeErrorCode] : code;
}
