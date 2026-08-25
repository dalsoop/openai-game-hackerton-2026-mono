// 플레이 중 한글 IME 가 캔버스에서 조합을 시작하면 Godot 웹은 키 콜백을 버린다.
// event.code(자리)만 게임 키로 보고, 그 자리의 keydown 은 preventDefault 한다.

export const PLAY_KEY_CODES: ReadonlySet<string> = new Set([
  "KeyW", "KeyA", "KeyS", "KeyD",
  "KeyQ", "KeyE", "KeyR", "KeyF",
  "ShiftLeft", "ShiftRight", "Space",
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
    if (document.activeElement !== canvas && event.target !== canvas) {return;}
    if (!shouldBlockIme(event)) {return;}
    event.preventDefault();
  };
  canvas.addEventListener("keydown", onKey);
  canvas.addEventListener("keyup", onKey);
  return (): void => {
    canvas.removeEventListener("keydown", onKey);
    canvas.removeEventListener("keyup", onKey);
  };
}
