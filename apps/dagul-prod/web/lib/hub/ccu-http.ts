import { admissionCcu, congestionOf, type CcuSnapshot } from "./ccu-plan.js";

export function ccuHttpBody(ccu: number, cap = admissionCcu()): CcuSnapshot {
  return congestionOf(ccu, cap);
}
