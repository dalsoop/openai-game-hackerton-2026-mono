export type InputState = {
  up: boolean;
  down: boolean;
  left: boolean;
  right: boolean;
};

const p1Map: Record<string, keyof InputState> = {
  KeyW: "up",
  KeyS: "down",
  KeyA: "left",
  KeyD: "right",
};

const p2Map: Record<string, keyof InputState> = {
  ArrowUp: "up",
  ArrowDown: "down",
  ArrowLeft: "left",
  ArrowRight: "right",
};

export class InputHub {
  p1: InputState = empty();
  p2: InputState = empty();

  constructor() {
    window.addEventListener("keydown", (e) => this.set(e.code, true, e));
    window.addEventListener("keyup", (e) => this.set(e.code, false, e));
  }

  private set(code: string, pressed: boolean, e: KeyboardEvent) {
    const a = p1Map[code];
    const b = p2Map[code];
    if (a) {
      this.p1[a] = pressed;
      e.preventDefault();
    }
    if (b) {
      this.p2[b] = pressed;
      e.preventDefault();
    }
  }
}

function empty(): InputState {
  return { up: false, down: false, left: false, right: false };
}
