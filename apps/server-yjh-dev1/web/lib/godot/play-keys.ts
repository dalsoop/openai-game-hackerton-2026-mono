// 플레이 중 한글 IME 가 캔버스에서 조합을 시작하면 Godot 웹은 키 콜백을 버린다.
// Godot 는 window 캡처에서 키를 받으므로 가드도 같은 단계에 둔다.

export const PLAY_KEY_CODES: ReadonlySet<string> = new Set([
  "KeyW", "KeyA", "KeyS", "KeyD",
  "KeyQ", "KeyE", "KeyR", "KeyF",
  "ShiftLeft", "ShiftRight", "Space", "Tab",
]);

export type PlayKeyLike = {
  code: string;
  key?: string;
  isComposing?: boolean;
  keyCode?: number;
  target?: EventTarget | null;
};

export function isTypingField(target: EventTarget | null | undefined): boolean {
  if (!(target instanceof HTMLElement)) {return false;}
  const tag = target.tagName;
  if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") {return true;}
  return target.isContentEditable;
}

export function shouldBlockIme(ev: PlayKeyLike): boolean {
  if (isTypingField(ev.target ?? null)) {return false;}
  if (ev.isComposing || ev.keyCode === 229 || ev.key === "Process") {return true;}
  return PLAY_KEY_CODES.has(ev.code);
}

export function bindPlayKeyGuard(canvas: HTMLCanvasElement): () => void {
  const onKey = (event: KeyboardEvent): void => {
    if (isTypingField(event.target) || isTypingField(document.activeElement)) {return;}
    if (!shouldBlockIme(event)) {return;}
    event.preventDefault();
    if (event.code === "Tab") {canvas.focus({ preventScroll: true });}
  };
  window.addEventListener("keydown", onKey, true);
  window.addEventListener("keyup", onKey, true);
  return (): void => {
    window.removeEventListener("keydown", onKey, true);
    window.removeEventListener("keyup", onKey, true);
  };
}
