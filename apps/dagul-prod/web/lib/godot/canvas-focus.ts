// 페이지는 캔버스 포커스와 IME 가드만 한다. 키 해제는 엔진 window.blur 가 맡는다.
import { bindPlayKeyGuard } from "./play-keys";

export function grabCanvasKeyboard(canvas: HTMLCanvasElement): void {
  if (typeof document !== "undefined" && document.visibilityState === "hidden") {return;}
  canvas.tabIndex = 0;
  canvas.focus({ preventScroll: true });
}

/** Godot policy=2 가 innerHeight 로 캔버스를 쓸 때 스크롤바가 생기면 크기가 진동한다. */
export function lockPlayViewport(): () => void {
  const html = document.documentElement;
  const body = document.body;
  const prevHtml = html.style.overflow;
  const prevBody = body.style.overflow;
  html.style.overflow = "hidden";
  body.style.overflow = "hidden";
  return (): void => {
    html.style.overflow = prevHtml;
    body.style.overflow = prevBody;
  };
}

export function bindCanvasKeyboardFocus(canvas: HTMLCanvasElement): () => void {
  const show = (): void => { grabCanvasKeyboard(canvas); };
  const onVis = (): void => {
    if (document.visibilityState !== "hidden") {show();}
  };
  window.addEventListener("focus", show);
  document.addEventListener("visibilitychange", onVis);
  canvas.addEventListener("pointerdown", show);
  const stopKeys = bindPlayKeyGuard(canvas);
  return (): void => {
    stopKeys();
    window.removeEventListener("focus", show);
    document.removeEventListener("visibilitychange", onVis);
    canvas.removeEventListener("pointerdown", show);
  };
}
