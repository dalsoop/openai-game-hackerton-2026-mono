import { cloneFeel } from "./feel";
import { InputHub } from "./input";
import { bounceWalls, createCar, stepCar, type Car } from "./car";
import { drawTrack, makeCheckpoints } from "./track";
import { mountTunePanel } from "./tunePanel";

const canvas = document.getElementById("game") as HTMLCanvasElement;
const ctx = canvas.getContext("2d")!;
const hud = document.getElementById("hud")!;
const lobby = document.getElementById("lobby")!;
const ready1 = document.getElementById("ready1") as HTMLButtonElement;
const ready2 = document.getElementById("ready2") as HTMLButtonElement;
const startBtn = document.getElementById("start") as HTMLButtonElement;

const feel = cloneFeel();
const input = new InputHub();
const LAPS = 3;

let p1Ready = false;
let p2Ready = false;
let racing = false;
let winner: 0 | 1 | 2 = 0;
let cars: Car[] = [];
const checkpoints = makeCheckpoints(canvas.width, canvas.height);

function resetCars() {
  cars = [
    createCar(1, canvas.width * 0.72, canvas.height * 0.5 - 18, "#ff6b6b"),
    createCar(2, canvas.width * 0.72, canvas.height * 0.5 + 18, "#4ecdc4"),
  ];
  winner = 0;
}

resetCars();

function updateReadyUI() {
  ready1.classList.toggle("on", p1Ready);
  ready2.classList.toggle("on", p2Ready);
  startBtn.disabled = !(p1Ready && p2Ready);
}

ready1.addEventListener("click", () => {
  p1Ready = !p1Ready;
  updateReadyUI();
});
ready2.addEventListener("click", () => {
  p2Ready = !p2Ready;
  updateReadyUI();
});
startBtn.addEventListener("click", () => {
  if (!(p1Ready && p2Ready)) return;
  resetCars();
  racing = true;
  lobby.classList.add("hidden");
});

function hitCheckpoint(car: Car) {
  const need = car.checkpoints % checkpoints.length;
  const cp = checkpoints[need];
  const d = Math.hypot(car.x - cp.x, car.y - cp.y);
  if (d < cp.r + 14) {
    car.checkpoints += 1;
    if (car.checkpoints > 0 && car.checkpoints % checkpoints.length === 0) {
      car.lap += 1;
      if (car.lap >= LAPS && winner === 0) {
        winner = car.id;
        racing = false;
      }
    }
  }
}

function drawCar(car: Car) {
  ctx.save();
  ctx.translate(car.x, car.y);
  ctx.rotate(car.angle);
  ctx.fillStyle = car.color;
  ctx.fillRect(-14, -8, 28, 16);
  ctx.fillStyle = "#111";
  ctx.fillRect(6, -5, 8, 10);
  ctx.restore();
}

function drawCheckpoints() {
  for (const cp of checkpoints) {
    ctx.beginPath();
    ctx.strokeStyle = "#ffffff55";
    ctx.lineWidth = 2;
    ctx.arc(cp.x, cp.y, cp.r, 0, Math.PI * 2);
    ctx.stroke();
    ctx.fillStyle = "#ffffff88";
    ctx.font = "12px sans-serif";
    ctx.fillText(String(cp.index + 1), cp.x - 3, cp.y + 4);
  }
}

let last = performance.now();
function frame(now: number) {
  const dt = Math.min(0.033, (now - last) / 1000);
  last = now;

  if (racing) {
    stepCar(cars[0], input.p1, feel, dt);
    stepCar(cars[1], input.p2, feel, dt);
    for (const c of cars) {
      bounceWalls(c, canvas.width, canvas.height, 24, feel);
      hitCheckpoint(c);
    }
  }

  drawTrack(ctx, canvas.width, canvas.height);
  drawCheckpoints();
  for (const c of cars) drawCar(c);

  if (winner) {
    ctx.fillStyle = "#000a";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = "#fff";
    ctx.font = "bold 36px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(`P${winner} 완주!`, canvas.width / 2, canvas.height / 2);
    ctx.font = "16px sans-serif";
    ctx.fillText("로비로 돌아가 다시 준비하세요", canvas.width / 2, canvas.height / 2 + 36);
    ctx.textAlign = "left";
  }

  hud.innerHTML = racing
    ? `P1 LAP ${cars[0].lap}/${LAPS} · CP ${cars[0].checkpoints}<br/>P2 LAP ${cars[1].lap}/${LAPS} · CP ${cars[1].checkpoints}<br/>목표 ${LAPS}랩`
    : "로비 — 두 명 준비 후 시작";

  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);

// 개발 빌드에서만 튜닝 UI
if (import.meta.env.DEV) {
  mountTunePanel(feel, () => {
    /* live — feel 객체를 물리 루프가 직접 참조 */
  });
}

// 완주 후 클릭으로 로비 복귀
canvas.addEventListener("click", () => {
  if (!winner) return;
  winner = 0;
  p1Ready = false;
  p2Ready = false;
  updateReadyUI();
  lobby.classList.remove("hidden");
  resetCars();
});
