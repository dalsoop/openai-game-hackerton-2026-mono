import { DEFAULT_FEEL, type FeelParams } from "./feel";

type Field = { key: keyof FeelParams; label: string; min: number; max: number; step: number };

const FIELDS: Field[] = [
  { key: "accel", label: "가속", min: 0.05, max: 0.5, step: 0.01 },
  { key: "maxSpeed", label: "최고속", min: 2, max: 12, step: 0.1 },
  { key: "friction", label: "마찰(1=없음)", min: 0.95, max: 0.999, step: 0.001 },
  { key: "turnRate", label: "조향", min: 0.01, max: 0.12, step: 0.001 },
  { key: "drift", label: "드리프트 유지", min: 0.7, max: 0.99, step: 0.01 },
  { key: "reverseFactor", label: "후진 배율", min: 0.2, max: 1, step: 0.05 },
  { key: "wallBounce", label: "벽 반발", min: 0.1, max: 0.9, step: 0.05 },
  { key: "wallFriction", label: "벽 마찰", min: 0.3, max: 1, step: 0.05 },
];

/** DEV only — production build 에서는 main 이 마운트하지 않음 */
export function mountTunePanel(feel: FeelParams, onChange: () => void): void {
  const btn = document.createElement("button");
  btn.id = "tune-toggle";
  btn.type = "button";
  btn.title = "조작감 조율 (개발 전용)";
  btn.textContent = "☰";
  document.querySelector(".stage")?.appendChild(btn);

  const panel = document.createElement("div");
  panel.id = "tune-panel";
  panel.className = "hidden";
  panel.innerHTML = `<h3>Feel 튜닝</h3><p class="hint">최종 빌드에서 제거됩니다. 좋은 값은 docs/FEEL-TUNING.md 에 적으세요.</p>`;

  for (const f of FIELDS) {
    const lab = document.createElement("label");
    const val = document.createElement("span");
    val.textContent = String(feel[f.key]);
    const input = document.createElement("input");
    input.type = "range";
    input.min = String(f.min);
    input.max = String(f.max);
    input.step = String(f.step);
    input.value = String(feel[f.key]);
    input.addEventListener("input", () => {
      feel[f.key] = Number(input.value);
      val.textContent = String(feel[f.key]);
      onChange();
    });
    lab.append(f.label, val, input);
    panel.appendChild(lab);
  }

  const reset = document.createElement("button");
  reset.type = "button";
  reset.textContent = "기본값 복원";
  reset.addEventListener("click", () => {
    Object.assign(feel, DEFAULT_FEEL);
    panel.querySelectorAll("input[type=range]").forEach((el, i) => {
      const field = FIELDS[i];
      const input = el as HTMLInputElement;
      input.value = String(feel[field.key]);
      const span = input.previousElementSibling as HTMLSpanElement;
      if (span) span.textContent = String(feel[field.key]);
    });
    onChange();
  });
  panel.appendChild(reset);

  document.querySelector(".stage")?.appendChild(panel);
  btn.addEventListener("click", () => panel.classList.toggle("hidden"));
}
