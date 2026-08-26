import { readFileSync } from "fs";
import { join } from "path";

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
