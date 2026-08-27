import { describe, expect, it } from "vitest";
import { BootTicket } from "@/lib/godot/boot-ticket";

describe("BootTicket", () => {
  it("issue 한 세대만 live 다", () => {
    const boots = new BootTicket();
    const first = boots.issue();
    expect(boots.isLive(first)).toBe(true);
    const second = boots.issue();
    expect(boots.isLive(first)).toBe(false);
    expect(boots.isLive(second)).toBe(true);
  });

  it("invalidate 는 진행 중 부팅을 버린다", () => {
    const boots = new BootTicket();
    const gen = boots.issue();
    boots.invalidate();
    expect(boots.isLive(gen)).toBe(false);
  });
});
