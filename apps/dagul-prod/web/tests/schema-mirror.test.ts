// Colyseus 스키마 거울 계약 테스트.
// Colyseus 델타는 필드 인덱스 기반 디코드다. 서버 @type 선언과 GD 거울이
// 클래스 하나라도 어긋나면 "refId not found" 연발로 월드가 멈춘다 (2026-08-27 운영 사고).
import { readFileSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";

const ROOT = process.cwd();
const sourceOf = (p: string): string => readFileSync(p, "utf8");

const matchSrc = sourceOf(join(ROOT, "lib/hub/match-schema.ts"));
const lobbySrc = sourceOf(join(ROOT, "lib/hub/lobby-state.ts"));
const mirror = sourceOf(join(ROOT, "..", "project", "core/net/lobby_state_schema.gd"));

/** 서버 TS 클래스 → GD 거울 클래스 대응. 새 스키마 클래스는 여기에 반드시 등록한다. */
const CLASS_MAP: ReadonlyArray<[src: string, ts: string, gd: string]> = [
  ["match", "MatchHeroHudSchema", "MatchHeroHud"],
  ["match", "MatchHeroSchema", "MatchHero"],
  ["match", "MatchBulletSchema", "MatchBullet"],
  ["match", "MatchCoverSchema", "MatchCover"],
  ["match", "MatchCrateSchema", "MatchCrate"],
  ["match", "MatchCrateOrbSchema", "MatchCrateOrb"],
  ["match", "MatchMidTowerSchema", "MatchMidTower"],
  ["match", "MatchLootSchema", "MatchLoot"],
  ["match", "MatchDeployableSchema", "MatchDeployable"],
  ["match", "MatchZoneSchema", "MatchZone"],
  ["match", "MatchKnockoutSchema", "MatchKnockout"],
  ["match", "MatchFinishCineSchema", "MatchFinishCine"],
  ["match", "MatchCoreSchema", "MatchCore"],
  ["match", "MatchEffectSchema", "MatchEffect"],
  ["match", "MatchEventSchema", "MatchEvent"],
  ["match", "MatchStateSchema", "MatchState"],
  ["lobby", "PlayerSchema", "PlayerRow"],
  ["lobby", "HeroSchema", "LobbyHero"],
  ["lobby", "BulletSchema", "LobbyBullet"],
  ["lobby", "LobbyState", "LobbyState"],
];

function gdChildName(tsClass: string): string {
  const hit = CLASS_MAP.find(([, ts]) => ts === tsClass);
  return hit ? hit[2] : tsClass.replace(/Schema$/, "");
}

/** @type(...) 인자를 GD 거울 표기(`타입:자식클래스`)로 정규화한다. */
function normalizeTsType(raw: string): string {
  const t = raw.trim();
  const quoted = /^"(\w+)"$/.exec(t);
  if (quoted) {return `${quoted[1].toUpperCase()}:`;}
  const arr = /^\[\s*(\w+)\s*\]$/.exec(t);
  if (arr) {return `ARRAY:${gdChildName(arr[1])}`;}
  const map = /^\{\s*map:\s*(\w+)\s*\}$/.exec(t);
  if (map) {return `MAP:${gdChildName(map[1])}`;}
  return `REF:${gdChildName(t)}`;
}

function tsFieldDefs(source: string, className: string): string[] {
  const block = source.split(new RegExp(`class\\s+${className}\\s+extends`))[1]
    ?.split(/class\s+\w+\s+extends/)[0] ?? "";
  return [...block.matchAll(/@type\(([^)]+)\)\s+(\w+)/g)]
    .map((m) => `${m[2]}=${normalizeTsType(m[1])}`);
}

function gdFieldDefs(className: string): string[] {
  const block = mirror.split(`class ${className} extends`)[1]?.split(/\nclass /)[0] ?? "";
  const fieldRe = /f\("(\w+)",\s*Colyseus\.Schema\.(\w+)(?:,\s*LobbyColyseus\.(\w+))?\)/g;
  return [...block.matchAll(fieldRe)]
    .map((m: RegExpMatchArray) => `${m[1]}=${m[2]}:${(m[3] as string | undefined) ?? ""}`);
}

describe("계약: Colyseus 스키마 거울", () => {
  it.each(CLASS_MAP)("%s %s ↔ GD %s 필드 이름·순서·타입이 일치한다", (src, tsClass, gdClass) => {
    const serverFields = tsFieldDefs(src === "match" ? matchSrc : lobbySrc, tsClass);
    expect(serverFields.length, `${tsClass} 파싱 실패`).toBeGreaterThan(0);
    expect(gdFieldDefs(gdClass), `${tsClass} ↔ ${gdClass} 거울 불일치`).toEqual(serverFields);
  });

  it("서버의 모든 Schema 파생 클래스가 거울 대조(CLASS_MAP)에 등록되어 있다", () => {
    const declared = new Set(CLASS_MAP.map(([, ts]) => ts));
    for (const source of [matchSrc, lobbySrc]) {
      for (const m of source.matchAll(/class\s+(\w+)\s+extends\s+Schema\b/g)) {
        expect(declared.has(m[1]), `${m[1]} 이 CLASS_MAP 에 등록되지 않았다`).toBe(true);
      }
    }
  });

  it("모든 스키마 클래스는 Colyseus 64필드 한도 아래에 있다 — 넘치면 hud 처럼 중첩으로 뺀다", () => {
    // 인코더가 (index | operation) 한 바이트 패킹이라 인덱스 64 이상은
    // DELETE(64)/ADD(128) 연산 비트와 충돌한다. 65번째 필드가 곧 붕괴다.
    for (const [src, tsClass] of CLASS_MAP) {
      const count = tsFieldDefs(src === "match" ? matchSrc : lobbySrc, tsClass).length;
      expect(count, `${tsClass} 필드 ${count}개 — 64개 초과`).toBeLessThanOrEqual(64);
    }
  });

  it("hud 중첩 필드는 GD 어댑터가 전부 평탄화한다", () => {
    const adapter = sourceOf(join(ROOT, "..", "project", "core/net/match_snap_adapter.gd"));
    const hudFields = [...matchSrc.split("class MatchHeroHudSchema")[1].split(/class\s+\w+\s+extends/)[0]
      .matchAll(/@type\([^)]+\)\s+(\w+)/g)].map((m) => m[1]);
    expect(hudFields.length).toBeGreaterThan(0);
    const playerCopy = adapter.split("PLAYER_COPY := [")[1]?.split("]")[0] ?? "";
    const mergeHud = adapter.split("func _merge_hud")[1] ?? "";
    for (const field of hudFields) {
      expect(playerCopy, `PLAYER_COPY 에 "${field}" 누락`).toContain(`"${field}"`);
      expect(mergeHud, `_merge_hud 에 "${field}" 누락`).toContain(`"${field}"`);
    }
  });
});
