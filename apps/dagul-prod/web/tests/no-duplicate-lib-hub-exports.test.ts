/**
 * 회귀: match-gun-geom.ts 가 match-gun.ts 의 hopLift·wantsFire·
 * weaponPassiveDamageMul·equipmentSkillTable 을 글자 하나까지 그대로 복제해
 * 두고 있었다 — 심지어 equipmentSkillTable 은 `implemented` 값이 서로
 * 달라서, 잘못 import 하면 조용히 다른 동작을 낸다.
 *
 * 이름만으로 비교하면 seed/tick/apply/pack 처럼 "모듈마다 같은 이름의
 * 어댑터를 구현하는" 의도된 컨벤션까지 걸려서 쓸모가 없어진다 — 이름이
 * 같고 **본문도 거의 그대로 같은** 경우만 "복붙 중복"으로 본다.
 */
import { readdirSync, readFileSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";

const ROOT = process.cwd();
const HUB_DIR = join(ROOT, "lib/hub");

function hubSources(): string[] {
  return readdirSync(HUB_DIR)
    .filter((name) => name.endsWith(".ts") && !name.endsWith(".test.ts"))
    .map((name) => join(HUB_DIR, name));
}

type Entry = { file: string; name: string; body: string };

// 다음 최상위 export/함수 시작 전까지를 본문으로 본다 — 완벽한 파서는 아니지만
// "복붙 그대로"를 잡는 데는 충분하다(ssot-mirror.test.ts 의 gdReturnDicts 와 같은 절충).
function topLevelExports(src: string): Array<{ name: string; body: string }> {
  const starts = [...src.matchAll(/^export (?:function|const) (\w+)/gm)];
  return starts.map((m, i) => {
    const from = m.index;
    const to = i + 1 < starts.length ? starts[i + 1].index : src.length;
    return { name: m[1], body: src.slice(from, to).replace(/\s+/g, " ").trim() };
  });
}

// 본문 첫 200자가 같으면 복붙 중복으로 본다 — 이름만 같고 구현이 다른
// 모듈별 어댑터(seed/tick/apply/pack 등)는 여기서 걸러진다.
function pairDuplicates(group: Entry[]): string[] {
  return group.slice(1)
    .filter((e) => e.body.slice(0, 200) === group[0].body.slice(0, 200))
    .map((e) => `${group[0].name}: ${group[0].file} ≈ ${e.file}`);
}

describe("계약: lib/hub export 이름 중복 금지", () => {
  it("같은 이름 + 거의 같은 본문의 최상위 export 가 두 파일에 없다", () => {
    const entries: Entry[] = hubSources().flatMap((file) =>
      topLevelExports(readFileSync(file, "utf8")).map((e) => ({ ...e, file: file.slice(ROOT.length + 1) })));
    const byName = new Map<string, Entry[]>();
    for (const e of entries) {
      const arr = byName.get(e.name) ?? [];
      arr.push(e);
      byName.set(e.name, arr);
    }
    const duplicates = [...byName.values()].filter((group) => group.length > 1).flatMap(pairDuplicates);
    expect(duplicates, "같은 이름·같은 본문이 두 파일에 export 됨 — 복붙 중복이거나 동작이 갈릴 쌍둥이 함수").toEqual([]);
  });
});
