// 페이지는 캔버스 포커스와 IME 가드만 한다. 키 해제는 엔진 window.blur 가 맡는다.
import { bindPlayKeyGuard } from "./play-keys";

export function grabCanvasKeyboard(canvas: HTMLCanvasElement): void {
  if (typeof document !== "undefined" && document.visibilityState === "hidden") {return;}
  canvas.tabIndex = 0;
  canvas.focus({ preventScroll: true });
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
