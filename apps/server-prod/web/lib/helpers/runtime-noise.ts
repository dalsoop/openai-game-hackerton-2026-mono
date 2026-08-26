// Chrome 확장이 sendMessage 응답 전에 포트를 닫으면 페이지 콘솔에 찍힌다.
// 앱 코드가 아니므로 UI·콘솔 파이프라인에 올리지 않는다.

const UNCHECKED_LAST_ERROR = /Unchecked runtime\.lastError/i;
const MESSAGE_PORT_CLOSED = /message port closed before a response was received/i;

export function isUncheckedRuntimeLastError(text: string): boolean {
  return UNCHECKED_LAST_ERROR.test(text) || MESSAGE_PORT_CLOSED.test(text);
}

function textOf(value: unknown): string {
  if (typeof value === "string") {return value;}
  if (value instanceof Error) {return `${value.name} ${value.message}`;}
  try {return String(value);} catch {return "";}
}

function isNoiseArgs(args: readonly unknown[]): boolean {
  return args.some((arg) => isUncheckedRuntimeLastError(textOf(arg)));
}

export function installRuntimeNoiseFilter(
  c: Console = console,
  target: Pick<Window, "addEventListener" | "removeEventListener"> | null =
    typeof window === "undefined" ? null : window,
): () => void {
  const prevError = c.error;
  const prevWarn = c.warn;
  const origError = prevError.bind(c);
  const origWarn = prevWarn.bind(c);
  c.error = (...args: unknown[]): void => {
    if (isNoiseArgs(args)) {return;}
    origError(...args);
  };
  c.warn = (...args: unknown[]): void => {
    if (isNoiseArgs(args)) {return;}
    origWarn(...args);
  };

  const onError = (ev: Event): void => {
    const err = ev as ErrorEvent;
    if (!isUncheckedRuntimeLastError(`${err.message ?? ""} ${err.error ?? ""}`)) {return;}
    ev.preventDefault();
    ev.stopImmediatePropagation();
  };
  const onReject = (ev: Event): void => {
    const rej = ev as PromiseRejectionEvent;
    if (!isUncheckedRuntimeLastError(textOf(rej.reason))) {return;}
    ev.preventDefault();
    ev.stopImmediatePropagation();
  };
  target?.addEventListener("error", onError, true);
  target?.addEventListener("unhandledrejection", onReject, true);

  return (): void => {
    c.error = prevError;
    c.warn = prevWarn;
    target?.removeEventListener("error", onError, true);
    target?.removeEventListener("unhandledrejection", onReject, true);
  };
}
