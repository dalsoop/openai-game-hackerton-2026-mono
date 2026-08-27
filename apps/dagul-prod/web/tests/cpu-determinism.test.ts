// CPU 결정론 — "봇이 안 움직인다"류 버그의 재현 가능성을 담보한다.
// 같은 시드면 항상 같은 배치·같은 판단이어야 리플레이·회귀 비교가 가능하다.
import { describe, expect, it } from "vitest";
import { MatchSim } from "@/lib/hub/match-sim";
import { assignSeatIdentity, seedSeatIdentities } from "@/lib/characters";

function cpuSeats(n: number): Array<{ slot: number; name: string; cpu: boolean }> {
  return Array.from({ length: n }, (_, i) => ({ slot: i, name: `CPU${i + 1}`, cpu: true }));
}

describe("CPU 결정론 — 같은 시드는 같은 결과", () => {
  it("같은 시드로 두 번 만든 매치는 CPU 초기 위치·동물이 완전히 같다", () => {
    const a = new MatchSim(cpuSeats(8), 12345, "full");
    const b = new MatchSim(cpuSeats(8), 12345, "full");
    for (let i = 0; i < 8; i += 1) {
      const ha = a.heroes.get(i);
      const hb = b.heroes.get(i);
      expect(ha?.x).toBe(hb?.x);
      expect(ha?.y).toBe(hb?.y);
      expect(ha?.characterId).toBe(hb?.characterId);
    }
  });

  it("같은 시드로 30틱을 굴리면 CPU 위치가 완전히 같다 — 판단 로직도 결정적이다", () => {
    const a = new MatchSim(cpuSeats(4), 777, "full");
    const b = new MatchSim(cpuSeats(4), 777, "full");
    a.countdown = 0;
    b.countdown = 0;
    for (let i = 0; i < 30; i += 1) {
      a.step(1 / 60);
      b.step(1 / 60);
    }
    for (let slot = 0; slot < 4; slot += 1) {
      const ha = a.heroes.get(slot);
      const hb = b.heroes.get(slot);
      expect(ha?.x).toBe(hb?.x);
      expect(ha?.y).toBe(hb?.y);
      expect(ha?.action).toBe(hb?.action);
    }
  });

  it("다른 시드는 30틱 뒤 적어도 한 CPU 의 위치가 달라진다 — 스폰은 slot 결정, 판단은 시드 결정", () => {
    const a = new MatchSim(cpuSeats(8), 1, "full");
    const b = new MatchSim(cpuSeats(8), 2, "full");
    a.countdown = 0;
    b.countdown = 0;
    for (let i = 0; i < 30; i += 1) {
      a.step(1 / 60);
      b.step(1 / 60);
    }
    const same = [...a.heroes.entries()].every(([slot, ha]) => {
      const hb = b.heroes.get(slot);
      return ha.x === hb?.x && ha.y === hb.y;
    });
    expect(same).toBe(false);
  });
});

describe("CPU 캐릭터 풀 배정", () => {
  it("동물 바인딩 풀이 있으면 slot 결정론으로 고른다 — 매번 같은 slot 은 같은 동물", () => {
    const a = assignSeatIdentity(undefined, { cpu: true, slot: 3 });
    const b = assignSeatIdentity(undefined, { cpu: true, slot: 3 });
    expect(a.characterId).toBe(b.characterId);
    expect(a.animal).toBe(b.animal);
  });

  it("이미 쓰인 id 는 피해서 고른다 — 사람 좌석과 CPU 가 겹치지 않는다", () => {
    const seats = [
      { slot: 0, characterId: "a2", cpu: false },
      { slot: 1, cpu: true },
      { slot: 2, cpu: true },
    ];
    const identities = seedSeatIdentities(seats);
    const ids = [...identities.values()].map((v) => v.characterId);
    expect(new Set(ids).size).toBe(ids.length); // 전부 서로 다르다
  });

  it("풀이 사람 좌석으로 전부 소진돼도 CPU 는 중복 폴백으로 배정받는다 — 빈 캐릭터가 되지 않는다", () => {
    const humanSeats = Array.from({ length: 8 }, (_, i) => ({ slot: i, characterId: `a${i}`, cpu: false }));
    const identities = seedSeatIdentities([
      ...humanSeats,
      { slot: 8, cpu: true },
    ]);
    const cpuIdentity = identities.get(8);
    expect(cpuIdentity?.characterId, "폴백 실패 — CPU 가 빈 캐릭터로 남았다").not.toBe("");
  });
});
