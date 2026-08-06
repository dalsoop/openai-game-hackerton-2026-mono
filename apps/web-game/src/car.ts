import type { FeelParams } from "./feel";
import type { InputState } from "./input";

export type Car = {
  id: 1 | 2;
  x: number;
  y: number;
  vx: number;
  vy: number;
  angle: number;
  color: string;
  lap: number;
  checkpoints: number;
};

export function createCar(id: 1 | 2, x: number, y: number, color: string): Car {
  return { id, x, y, vx: 0, vy: 0, angle: -Math.PI / 2, color, lap: 0, checkpoints: 0 };
}

export function stepCar(car: Car, input: InputState, feel: FeelParams, dt: number) {
  // 가속 / 후진
  const forwardX = Math.cos(car.angle);
  const forwardY = Math.sin(car.angle);
  if (input.up) {
    car.vx += forwardX * feel.accel * dt * 60;
    car.vy += forwardY * feel.accel * dt * 60;
  }
  if (input.down) {
    car.vx -= forwardX * feel.accel * feel.reverseFactor * dt * 60;
    car.vy -= forwardY * feel.accel * feel.reverseFactor * dt * 60;
  }

  // 속도
  const speed = Math.hypot(car.vx, car.vy);
  if (speed > feel.maxSpeed) {
    const s = feel.maxSpeed / speed;
    car.vx *= s;
    car.vy *= s;
  }

  // 조향: 빠를수록 덜 돌고, 정지 시 거의 안 돎
  const steer = (input.left ? -1 : 0) + (input.right ? 1 : 0);
  const steerPower = Math.min(1, speed / (feel.maxSpeed * 0.35));
  car.angle += steer * feel.turnRate * steerPower * dt * 60;

  // 드리프트: 옆으로 미끄러지는 속도 유지
  const fx = Math.cos(car.angle);
  const fy = Math.sin(car.angle);
  const forward = car.vx * fx + car.vy * fy;
  const rightX = -fy;
  const rightY = fx;
  const lateral = car.vx * rightX + car.vy * rightY;
  const newForward = forward;
  const newLateral = lateral * feel.drift;
  car.vx = fx * newForward + rightX * newLateral;
  car.vy = fy * newForward + rightY * newLateral;

  // 마찰
  car.vx *= Math.pow(feel.friction, dt * 60);
  car.vy *= Math.pow(feel.friction, dt * 60);

  car.x += car.vx * dt * 60;
  car.y += car.vy * dt * 60;
}

export function bounceWalls(
  car: Car,
  w: number,
  h: number,
  pad: number,
  feel: FeelParams,
) {
  if (car.x < pad) {
    car.x = pad;
    car.vx = Math.abs(car.vx) * feel.wallBounce;
    car.vx *= feel.wallFriction;
    car.vy *= feel.wallFriction;
  }
  if (car.x > w - pad) {
    car.x = w - pad;
    car.vx = -Math.abs(car.vx) * feel.wallBounce;
    car.vx *= feel.wallFriction;
    car.vy *= feel.wallFriction;
  }
  if (car.y < pad) {
    car.y = pad;
    car.vy = Math.abs(car.vy) * feel.wallBounce;
    car.vx *= feel.wallFriction;
    car.vy *= feel.wallFriction;
  }
  if (car.y > h - pad) {
    car.y = h - pad;
    car.vy = -Math.abs(car.vy) * feel.wallBounce;
    car.vx *= feel.wallFriction;
    car.vy *= feel.wallFriction;
  }
}
