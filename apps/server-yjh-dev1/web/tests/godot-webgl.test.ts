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

  it("엔진이 없으면 더미 캔버스 webgl2 만 본다 — 게임 캔버스 아님", () => {
    const getContext = vi.fn((id: string) => (id === "webgl2" ? {} : null));
    expect(isWebGL2Available({ createCanvas: () => ({ getContext }) })).toBe(true);
    expect(getContext).toHaveBeenCalledWith("webgl2");
  });

  it("더미 캔버스도 없고 엔진도 없으면 false", () => {
    expect(isWebGL2Available({})).toBe(false);
  });
});
