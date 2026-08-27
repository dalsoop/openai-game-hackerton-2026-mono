// @vitest-environment jsdom
/** 로케일 접두사와 무관하게 WASM·워크릿·오류 문구가 붙는 계약. ko/en 하드코딩이 재발하면 깨진다. */
import { createRef, type RefObject } from "react";
import { readdirSync, readFileSync } from "fs";
import { join } from "path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, render, screen } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import type koMessages from "../messages/ko.json";
import {
  godotAssetUrl, godotPageRelativeName, godotWorkletAssetPath,
} from "@/lib/godot/asset-store";
import { ConnectionLostModal } from "@/components/ConnectionLostModal";
import GodotCanvas from "@/components/GodotCanvas";

vi.mock("@/hooks/useGodotMatch", () => ({
  useGodotMatch: (): {
    canvasRef: RefObject<HTMLCanvasElement | null>;
    snap: { state: string; progress: number; bytesLoaded: number; bytesTotal: number; error: string | null };
  } => ({
    canvasRef: createRef<HTMLCanvasElement>(),
    snap: {
      state: "error",
      progress: 0,
      bytesLoaded: 0,
      bytesTotal: 0,
      error: "match-signal-missing",
    },
  }),
}));

vi.mock("@/lib/godot/runtime", () => ({
  GodotRuntime: { for: (): { resetError: () => void } => ({ resetError: vi.fn() }) },
}));

const ROOT = process.cwd();
const PREFIXES = [
  "",
  "/en",
  "/ko",
  "/ja",
  "/zh-CN",
  "/pt-BR",
  "/en/create",
  "/ja/room/wait",
] as const;

function sourceOf(rel: string): string {
  return readFileSync(join(ROOT, rel), "utf8");
}

function sliceFn(src: string, start: string, end: string): string {
  const from = src.indexOf(start);
  const to = src.indexOf(end, from + 1);
  expect(from).toBeGreaterThanOrEqual(0);
  expect(to).toBeGreaterThan(from);
  return src.slice(from, to);
}

function messageLocales(): { locale: string; messages: typeof koMessages }[] {
  return readdirSync(join(ROOT, "messages"))
    .filter((name) => name.endsWith(".json"))
    .map((name) => ({
      locale: name.replace(/\.json$/, ""),
      messages: JSON.parse(readFileSync(join(ROOT, "messages", name), "utf8")),
    }));
}

afterEach(cleanup);

describe("로케일 무관 정적 에셋 경로", () => {
  const file = "index.audio.worklet.js";

  it("godotPageRelativeName 이 접두사·중첩 경로를 버리고 파일명만 남긴다", () => {
    expect(godotPageRelativeName("/")).toBeNull();
    expect(godotPageRelativeName("/godot/dagul/index.wasm")).toBeNull();
    for (const prefix of PREFIXES) {
      expect(godotPageRelativeName(`${prefix}/${file}`), prefix || "/").toBe(file);
    }
  });

  it("워크릿 매퍼는 그 이름만 소비한다", () => {
    expect(godotWorkletAssetPath(`/${file}`)).toBe(godotAssetUrl("dagul", file));
    for (const prefix of PREFIXES.filter((p) => p !== "")) {
      expect(godotWorkletAssetPath(`${prefix}/${file}`), prefix).toBe(godotAssetUrl("dagul", file));
    }
    expect(godotWorkletAssetPath(`/godot/dagul/${file}`)).toBeNull();
  });

  it("매퍼는 godotPageRelativeName 에 위임하고 로케일 코드를 하드코딩하지 않는다", () => {
    const src = sourceOf("lib/godot/asset-store.ts");
    const nameFn = sliceFn(src, "export function godotPageRelativeName", "export function godotWorkletAssetPath");
    const workletFn = sliceFn(src, "export function godotWorkletAssetPath", "type ProgressFn");
    expect(nameFn).toContain(".pop()");
    expect(nameFn).not.toMatch(/["'`]\/(?:ko|en)(?:\/|$)/);
    expect(workletFn).toContain("godotPageRelativeName");
    expect(workletFn).toContain("packOf");
    expect(workletFn).not.toContain(".pop()");
    expect(workletFn).not.toMatch(/pack = "dagul"/);
    expect(src).not.toContain("libcolyseus");
  });
});

describe("미들웨어는 로케일 접두사 파일을 가로채지 않는다", () => {
  it("(ko|en) 경로 매처가 없고, 확장자 요청은 제외한다", () => {
    const src = sourceOf("middleware.ts");
    expect(src).not.toMatch(/\/\(ko\|en\)\/:path\*/);
    const matcher = sliceFn(src, "matcher:", "],");
    expect(matcher).toContain("godot");
    expect(matcher).toContain("favicon.ico");
    expect(matcher).toContain(".*\\\\..*");
    expect(matcher).not.toContain(":path*");
  });
});

describe("허브·정적 서버가 같은 매퍼를 쓴다", () => {
  it("servePackAssets 와 startStatic 둘 다 servePageRelativeGodotAssets 를 부른다", () => {
    const src = sourceOf("server.ts");
    const helper = sliceFn(src, "function servePageRelativeGodotAssets", "function servePackAssets");
    expect(helper).toContain("godotWorkletAssetPath");
    expect(helper).not.toContain("servePageRootWasm");
    expect(src).not.toContain("libcolyseus");
    const pack = sliceFn(src, "function servePackAssets", "type RequestHandle");
    expect(pack).toContain("servePageRelativeGodotAssets");
    expect(pack).not.toContain("godotWorkletAssetPath");
    const stat = sliceFn(src, "function startStatic", "function startHub");
    expect(stat).toContain("servePageRelativeGodotAssets");
    expect(stat).not.toContain("godotWorkletAssetPath");
    expect(src).not.toContain("public/godot/dagul/libcolyseus");
  });
});

describe("화면 문구는 메시지 로케일마다 나온다", () => {
  it("로딩 타임아웃 모달과 로비로 돌아가기가 전 메시지 로케일에 있다", () => {
    const locales = messageLocales();
    expect(locales.map((row) => row.locale)).toEqual(expect.arrayContaining(["en", "ko"]));
    expect(locales.length).toBeGreaterThanOrEqual(2);
    for (const { locale, messages } of locales) {
      expect(messages.game.loadWaitTitle.length, locale).toBeGreaterThan(0);
      expect(messages.game.loadWaitBody.length, locale).toBeGreaterThan(0);
      expect(messages.godot.backToLobby.length, locale).toBeGreaterThan(0);
      cleanup();
      render(
        <NextIntlClientProvider locale={locale} messages={messages}>
          <ConnectionLostModal reason="load-wait" onReconnect={vi.fn()} onExit={vi.fn()} />
        </NextIntlClientProvider>,
      );
      expect(screen.getByText(messages.game.loadWaitTitle)).toBeTruthy();
      expect(screen.getByText(messages.game.loadWaitBody)).toBeTruthy();
      cleanup();
      render(
        <NextIntlClientProvider locale={locale} messages={messages}>
          <GodotCanvas
            visible
            game="dagul"
            matchInfo={{ roomId: "r1", name: "p", slot: 0, resumeToken: "" }}
            onError={vi.fn()}
          />
        </NextIntlClientProvider>,
      );
      expect(screen.getByText(messages.godot.backToLobby)).toBeTruthy();
      expect(screen.getByText(messages.game.errors.matchSignalMissing)).toBeTruthy();
    }
  });
});
