import { readFileSync } from "fs";
import { join } from "path";
import { DEFAULT_GAME_ID, packOf } from "../games/catalog.js";

/** next build 가 남긴 BUILD_ID. 없으면 Next dev 와 같이 development. */
export function deployedBuildId(
  cwd = process.cwd(),
  env = process.env.NODE_ENV,
): string {
  try {
    const id = readFileSync(join(cwd, ".next", "BUILD_ID"), "utf8").trim();
    if (id !== "") {return id;}
  } catch {
    // next build 전이면 파일이 없다
  }
  return env === "production" ? "" : "development";
}

/** 웹에 물린 Godot 팩 해시. 없으면 빈 문자열. */
export function godotFilesHash(cwd = process.cwd(), pack = packOf(DEFAULT_GAME_ID)): string {
  try {
    const raw = readFileSync(join(cwd, "public", "godot", pack, "manifest.json"), "utf8");
    const body = JSON.parse(raw) as { filesHash?: unknown; version?: unknown };
    if (typeof body.filesHash === "string" && body.filesHash !== "") {return body.filesHash;}
    if (typeof body.version === "string") {return body.version;}
  } catch {
    // 익스포트 전이면 매니페스트가 없다
  }
  return "";
}

/** 셸(Next) + 팩(Godot) 을 한 id 로. 탭이 옛 엔진을 들고 있으면 이 값이 갈라진다. */
export function liveRevisionId(
  cwd = process.cwd(),
  env = process.env.NODE_ENV,
  pack = packOf(DEFAULT_GAME_ID),
): string {
  return [deployedBuildId(cwd, env), godotFilesHash(cwd, pack)].filter((p) => p !== "").join(":");
}
