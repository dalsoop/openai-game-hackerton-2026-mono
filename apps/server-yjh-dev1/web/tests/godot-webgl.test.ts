import { describe, expect, it, vi } from "vitest";
import { isWebGL2Available } from "@/lib/godot/webgl";

describe("isWebGL2Available — Godot 공식 Engine.isWebGLAvailable(2)", () => {
  it("엔진 API가 있으면 major 2 만 묻는다", () => {
    const isWebGLAvailable = vi.fn((major?: number) => major === 2);
    expect(isWebGL2Available({ Engine: { isWebGLAvailable } })).toBe(true);
    expect(isWebGLAvailable).toHaveBeenCalledWith(2);
  });

  it("엔진이 WebGL2 없다고 하면 false", () => {
    expect(isWebGL2Available({
      Engine: { isWebGLAvailable: () => false },
    })).toBe(false);
  });

  it("더미 캔버스가 있으면 엔진 API보다 더미를 쓰고 컨텍스트를 버린다", () => {
    const loseContext = vi.fn();
    const getExtension = vi.fn(() => ({ loseContext }));
    const getContext = vi.fn((id: string) => (id === "webgl2" ? { getExtension } : null));
    const isWebGLAvailable = vi.fn(() => true);
    expect(isWebGL2Available({
      Engine: { isWebGLAvailable },
      createCanvas: () => ({ getContext }),
    })).toBe(true);
    expect(isWebGLAvailable).not.toHaveBeenCalled();
    expect(getContext).toHaveBeenCalledWith("webgl2");
    expect(loseContext).toHaveBeenCalled();
  });

  it("더미 캔버스도 없고 엔진도 없으면 false", () => {
    expect(isWebGL2Available({})).toBe(false);
  });
});
