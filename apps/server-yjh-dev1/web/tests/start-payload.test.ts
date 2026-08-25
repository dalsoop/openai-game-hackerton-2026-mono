// START 페이로드 경계 — 서버·React·Godot 가 같은 형태로만 핸드오프한다.
import { describe, expect, it } from "vitest";
import { parseStartPayload } from "@/lib/hub/start-payload";

const valid = {
  you: 0,
  host: true,
  seed: 42,
  mode: "full",
  seats: [
    { slot: 0, name: "호스트", connected: true },
    { slot: 1, name: "게스트", connected: false },
  ],
};

describe("parseStartPayload", () => {
  it("정상 본문은 필드가 확정된 타입으로 나온다", () => {
    const p = parseStartPayload(valid);
    expect(p).toEqual(valid);
  });

  it("시드·좌석 번호가 없으면 거절한다 — 매치 시작으로 쓸 수 없다", () => {
    expect(parseStartPayload(null)).toBeNull();
    expect(parseStartPayload("start")).toBeNull();
    expect(parseStartPayload({ you: 0, host: true, mode: "full" })).toBeNull();
    expect(parseStartPayload({ ...valid, seed: 0 })).toBeNull();
    expect(parseStartPayload({ ...valid, you: "x" })).toBeNull();
  });

  it("불량 좌석은 버리고, connected 생략은 접속 중으로 본다", () => {
    const p = parseStartPayload({
      ...valid,
      seats: [{ slot: 2, name: "둘" }, { name: "번호없음" }, null],
    });
    expect(p?.seats).toEqual([{ slot: 2, name: "둘", connected: true }]);
  });
});
