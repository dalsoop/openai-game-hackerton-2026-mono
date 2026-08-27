/**
 * 전역 동접 입장 게이트 — Colyseus matchMaker.stats.getGlobalCCU().
 * https://docs.colyseus.io/matchmaker
 */
import { matchMaker } from "colyseus";
import { KO } from "./config.js";
import { admissionCcu, congestionOf } from "./ccu-plan.js";

export type CcuReader = () => Promise<number> | number;

export async function readGlobalCcu(): Promise<number> {
  try {
    return await matchMaker.stats.getGlobalCCU();
  } catch {
    return Number(matchMaker.stats.local.ccu);
  }
}

export async function assertCanAdmitCcu(
  readCcu: CcuReader = readGlobalCcu,
  cap = admissionCcu(),
): Promise<void> {
  const snap = congestionOf(await readCcu(), cap);
  if (!snap.admit) {
    throw new Error(KO.SERVER_FULL);
  }
}
