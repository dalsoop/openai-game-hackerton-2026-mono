// Godot 웹 캔버스 백킹을 CSS 픽셀에 가깝게 묶는다.
// 레티나(devicePixelRatio 2)에서 2400×1620 을 Compatibility GL 이 채우면
// 설계 해상도 대비 fill-rate 가 수 배가 된다. 픽셀아트라 1x 가 시각적으로 무해하다.
// Godot canvasResizePolicy=2 는 리사이즈마다 window.devicePixelRatio 를 다시 읽으므로
// 게터를 덮어쓰면 유지되고, 페이지 UI 는 매치 종료 때 원래 게터로 돌아온다.

export const DPR_CAP_STORAGE_KEY = "dagul.dprCap";
const DEFAULT_DPR_CAP = 1;

let holdCount = 0;
let nativeDpr = 1;
let nativeOwnDesc: PropertyDescriptor | undefined;

function readDprCap(): number {
  try {
    const raw = sessionStorage.getItem(DPR_CAP_STORAGE_KEY);
    if (raw == null) {
      return DEFAULT_DPR_CAP;
    }
    const parsed = Number(raw);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      return DEFAULT_DPR_CAP;
    }
    return parsed;
  } catch {
    return DEFAULT_DPR_CAP;
  }
}

function restoreNativeDpr(): void {
  if (nativeOwnDesc !== undefined) {
    Object.defineProperty(window, "devicePixelRatio", nativeOwnDesc);
    nativeOwnDesc = undefined;
    return;
  }
  Reflect.deleteProperty(window, "devicePixelRatio");
}

/** 엔진 생성 전에 호출. 중첩 hold 는 네이티브 값을 다시 읽지 않는다. */
export function applyDevicePixelRatioCap(): void {
  if (holdCount === 0) {
    nativeOwnDesc = Object.getOwnPropertyDescriptor(window, "devicePixelRatio");
    nativeDpr = window.devicePixelRatio;
    const cap = readDprCap();
    Object.defineProperty(window, "devicePixelRatio", {
      configurable: true,
      get: (): number => Math.min(nativeDpr, cap),
    });
  }
  holdCount += 1;
}

/** 매치 종료·캔버스 해제 때 호출. hold 가 0 이 되면 원래 게터를 되돌린다. */
export function restoreDevicePixelRatio(): void {
  if (holdCount === 0) {
    return;
  }
  holdCount -= 1;
  if (holdCount > 0) {
    return;
  }
  restoreNativeDpr();
}
