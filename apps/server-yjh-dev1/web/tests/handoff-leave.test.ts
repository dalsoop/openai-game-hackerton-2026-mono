import { describe, expect, it, vi } from "vitest";
import { leaveOnceForHandoff } from "@/lib/hub/handoff-leave";

describe("leaveOnceForHandoff", () => {
  it("재접속을 끄고 consent=false 로 한 번만 떠난다", () => {
    const leave = vi.fn();
    const room = { reconnection: { enabled: true }, leave };
    leaveOnceForHandoff(room);
    expect(room.reconnection.enabled).toBe(false);
    expect(leave).toHaveBeenCalledTimes(1);
    expect(leave).toHaveBeenCalledWith(false);
  });

  it("이후 leave 는 소켓을 다시 건드리지 않는다", () => {
    const leave = vi.fn();
    const room = { reconnection: { enabled: true }, leave };
    leaveOnceForHandoff(room);
    room.leave(true);
    room.leave(false);
    expect(leave).toHaveBeenCalledTimes(1);
  });
});
