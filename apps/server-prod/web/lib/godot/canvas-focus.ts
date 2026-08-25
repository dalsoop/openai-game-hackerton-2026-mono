// Godot 웹은 캔버스 포커스가 있어야 키를 받는다(공식 셸 주석).
// 알탭은 그 포커스를 깨므로, 복귀 때 캔버스를 다시 잡고 엔진에 숨김/복귀를 알린다.
import { DOM_EVT } from "@/lib/contract";
import { bindPlayKeyGuard } from "@/lib/godot/play-keys";

export function grabCanvasKeyboard(canvas: HTMLCanvasElement): void {
  if (typeof document !== "undefined" && document.visibilityState === "hidden") {return;}
  canvas.tabIndex = 0;
  canvas.focus({ preventScroll: true });
}

function emit(name: string): void {
  window.dispatchEvent(new Event(name));
}

/** 창 포커스·가시성·클릭. 숨김이면 키 상태를 비우라고 엔진에 알린다. */
export function bindCanvasKeyboardFocus(canvas: HTMLCanvasElement): () => void {
  const hide = (): void => { emit(DOM_EVT.PAGE_HIDDEN); };
  const show = (): void => {
    grabCanvasKeyboard(canvas);
    emit(DOM_EVT.PAGE_VISIBLE);
  };
  const onVis = (): void => {
    if (document.visibilityState === "hidden") {hide();}
    else {show();}
  };
  window.addEventListener("blur", hide);
  window.addEventListener("focus", show);
  document.addEventListener("visibilitychange", onVis);
  canvas.addEventListener("pointerdown", show);
  const stopKeys = bindPlayKeyGuard(canvas);
  return (): void => {
    stopKeys();
    window.removeEventListener("blur", hide);
    window.removeEventListener("focus", show);
    document.removeEventListener("visibilitychange", onVis);
    canvas.removeEventListener("pointerdown", show);
  };
}
