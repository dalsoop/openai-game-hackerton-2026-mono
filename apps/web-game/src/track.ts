/** 단순 타원 트랙 + 체크포인트 4개 */
export type Checkpoint = { x: number; y: number; r: number; index: number };

export function makeCheckpoints(w: number, h: number): Checkpoint[] {
  const cx = w / 2;
  const cy = h / 2;
  const rx = w * 0.32;
  const ry = h * 0.28;
  return [
    { index: 0, x: cx + rx, y: cy, r: 36 },
    { index: 1, x: cx, y: cy - ry, r: 36 },
    { index: 2, x: cx - rx, y: cy, r: 36 },
    { index: 3, x: cx, y: cy + ry, r: 36 },
  ];
}

export function drawTrack(ctx: CanvasRenderingContext2D, w: number, h: number) {
  ctx.fillStyle = "#152033";
  ctx.fillRect(0, 0, w, h);

  const cx = w / 2;
  const cy = h / 2;

  // outer grass-ish
  ctx.fillStyle = "#1a3d2e";
  ctx.beginPath();
  ctx.ellipse(cx, cy, w * 0.46, h * 0.42, 0, 0, Math.PI * 2);
  ctx.fill();

  // road
  ctx.strokeStyle = "#2a3344";
  ctx.lineWidth = 78;
  ctx.beginPath();
  ctx.ellipse(cx, cy, w * 0.32, h * 0.28, 0, 0, Math.PI * 2);
  ctx.stroke();

  // lane line
  ctx.strokeStyle = "#c9d4e8";
  ctx.setLineDash([14, 12]);
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.ellipse(cx, cy, w * 0.32, h * 0.28, 0, 0, Math.PI * 2);
  ctx.stroke();
  ctx.setLineDash([]);

  // start line
  ctx.strokeStyle = "#fff";
  ctx.lineWidth = 4;
  ctx.beginPath();
  ctx.moveTo(cx + w * 0.32 - 36, cy - 28);
  ctx.lineTo(cx + w * 0.32 - 36, cy + 28);
  ctx.stroke();
}
