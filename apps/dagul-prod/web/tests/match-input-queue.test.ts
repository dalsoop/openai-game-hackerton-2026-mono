import { describe, expect, it } from "vitest";
import {
  INPUT_QUEUE_CAP, SlotInputBuffer, idleHoldInput,
} from "@/lib/hub/match-input-queue";

describe("SlotInputBuffer — Colyseus 고정 틱 next()", () => {
  it("쌓인 프레임은 한 틱에 최신으로 접힌다 — 적체가 지연이 되지 않는다", () => {
    const buf = new SlotInputBuffer();
    buf.enqueue({ mx: 1, firePressed: true, seq: 1 });
    buf.enqueue({ mx: 0.5, seq: 2 });
    const a = buf.next();
    expect(a?.seq).toBe(2);
    expect(a?.mx).toBe(0.5);
    expect(a?.firePressed).toBe(true);
    expect(buf.q).toHaveLength(0);
    const idle = buf.next();
    expect(idle?.firePressed).toBe(false);
  });

  it("빈 틱은 last 의 mx·fire 를 홀드하고 firePressed 는 끈다", () => {
    const buf = new SlotInputBuffer();
    buf.enqueue({ mx: 1, my: 0, fire: true, firePressed: true, aimX: 9, seq: 1 });
    buf.next();
    const idle = buf.next();
    expect(idle?.mx).toBe(1);
    expect(idle?.fire).toBe(true);
    expect(idle?.aimX).toBe(9);
    expect(idle?.firePressed).toBe(false);
    expect(idle?.dash).toBe(false);
    expect(idle?.emote).toBe(-1);
  });

  it("한 번도 없으면 next 는 undefined", () => {
    expect(new SlotInputBuffer().next()).toBeUndefined();
  });

  it("캡을 넘기면 가장 오래된 프레임을 버린다", () => {
    const buf = new SlotInputBuffer();
    for (let i = 0; i < INPUT_QUEUE_CAP + 3; i += 1) {
      buf.enqueue({ seq: i + 1 });
    }
    expect(buf.q).toHaveLength(INPUT_QUEUE_CAP);
    expect(buf.next()?.seq).toBe(INPUT_QUEUE_CAP + 3);
  });

  it("캡에서 버린 프레임의 firePressed 는 다음 머리에 붙는다", () => {
    const buf = new SlotInputBuffer();
    buf.enqueue({ seq: 1, firePressed: true, dash: true });
    for (let i = 0; i < INPUT_QUEUE_CAP; i += 1) {
      buf.enqueue({ seq: i + 2, mx: 1 });
    }
    const first = buf.next();
    expect(first?.seq).toBe(INPUT_QUEUE_CAP + 1);
    expect(first?.firePressed).toBe(true);
    expect(first?.dash).toBe(true);
    expect(first?.mx).toBe(1);
  });

  it("flushToIdle 은 큐를 비우고 에지를 끈다", () => {
    const buf = new SlotInputBuffer();
    buf.enqueue({ mx: 1, fire: true, firePressed: true, dash: true, seq: 1 });
    buf.enqueue({ mx: 0.5, fire: true, seq: 2 });
    const held = buf.flushToIdle();
    expect(buf.q).toHaveLength(0);
    expect(held?.mx).toBe(0.5);
    expect(held?.fire).toBe(true);
    expect(held?.firePressed).toBe(false);
    expect(held?.dash).toBe(false);
    expect(buf.next()?.firePressed).toBe(false);
  });

  it("idleHoldInput 은 last 를 변이시키지 않는다", () => {
    const last = { mx: 1, firePressed: true, dash: true };
    const held = idleHoldInput(last);
    expect(last.firePressed).toBe(true);
    expect(held.firePressed).toBe(false);
    expect(held.mx).toBe(1);
  });
});
