/**
 * 운영·서비스·비즈니스 메트릭 — Prometheus text exposition.
 * ccu-metrics(접속)·play-metrics(방) 와 같은 관례로 /metrics 에 합류한다.
 */

function labelSlot(slot: string): string {
  return slot.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"");
}

// ── counters ──

let wsConnTotal = 0;
let wsErrTotal = 0;
let wsDisconnTotal = 0;
let gamesStartedTotal = 0;
let gamesFinishedTotal = 0;
let playerKickTotal = 0;
let matchFailTotal = 0;
let tickOverrunTotal = 0;

// ── histograms (bucket 대신 합계+카운트로 평균을 낸다 — 경량) ──

let sessionDurSum = 0;
let sessionDurCount = 0;
let tickDurSum = 0;
let tickDurCount = 0;
let tickDurMax = 0;
let tickDurMaxResetAt = Date.now();
const TICK_MAX_WINDOW_MS = 5 * 60 * 1000;
let matchWaitSum = 0;
let matchWaitCount = 0;
let roundDurSum = 0;
let roundDurCount = 0;

// ── gauges ──

let wsQueueDepth = 0;

// ── session tracking (DAU 근사) ──

const dailySessions = new Map<string, Set<string>>();

function todayKey(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

// ── public record API ──

export function recordWsConnect(): void { wsConnTotal++; }
export function recordWsError(): void { wsErrTotal++; }
export function recordWsDisconnect(): void { wsDisconnTotal++; }
export function recordGameStarted(): void { gamesStartedTotal++; }
export function recordGameFinished(): void { gamesFinishedTotal++; }
export function recordPlayerKick(): void { playerKickTotal++; }
export function recordMatchFail(): void { matchFailTotal++; }

export function recordTickOverrun(): void { tickOverrunTotal++; }

export function recordSessionDuration(ms: number): void {
  if (ms <= 0) { return; }
  sessionDurSum += ms / 1000;
  sessionDurCount++;
}

export function recordTickDuration(ms: number): void {
  tickDurSum += ms;
  tickDurCount++;
  const now = Date.now();
  if (now - tickDurMaxResetAt > TICK_MAX_WINDOW_MS) {
    tickDurMax = ms;
    tickDurMaxResetAt = now;
  } else if (ms > tickDurMax) {
    tickDurMax = ms;
  }
}

export function recordMatchWait(ms: number): void {
  if (ms <= 0) { return; }
  matchWaitSum += ms / 1000;
  matchWaitCount++;
}

export function recordRoundDuration(ms: number): void {
  if (ms <= 0) { return; }
  roundDurSum += ms / 1000;
  roundDurCount++;
}

export function setWsQueueDepth(depth: number): void { wsQueueDepth = depth; }

export function recordPlayerSession(playerId: string): void {
  const key = todayKey();
  let set = dailySessions.get(key);
  if (!set) {
    set = new Set();
    dailySessions.set(key, set);
    pruneOldDays(key);
  }
  set.add(playerId);
}

function pruneOldDays(keepKey: string): void {
  for (const k of dailySessions.keys()) {
    if (k !== keepKey) { dailySessions.delete(k); }
  }
}

// ── Prometheus text ──

export function opsMetricsText(slot = process.env.SLOT_FOLDER ?? ""): string {
  const s = labelSlot(slot || "unknown");
  const dau = dailySessions.get(todayKey())?.size ?? 0;

  return [
    "# HELP dagul_ws_connections_total WebSocket connections since start.",
    "# TYPE dagul_ws_connections_total counter",
    `dagul_ws_connections_total{slot="${s}"} ${wsConnTotal}`,

    "# HELP dagul_ws_errors_total WebSocket errors since start.",
    "# TYPE dagul_ws_errors_total counter",
    `dagul_ws_errors_total{slot="${s}"} ${wsErrTotal}`,

    "# HELP dagul_ws_disconnects_total WebSocket disconnections since start.",
    "# TYPE dagul_ws_disconnects_total counter",
    `dagul_ws_disconnects_total{slot="${s}"} ${wsDisconnTotal}`,

    "# HELP dagul_games_started_total Games started since process start.",
    "# TYPE dagul_games_started_total counter",
    `dagul_games_started_total{slot="${s}"} ${gamesStartedTotal}`,

    "# HELP dagul_games_finished_total Games finished since process start.",
    "# TYPE dagul_games_finished_total counter",
    `dagul_games_finished_total{slot="${s}"} ${gamesFinishedTotal}`,

    "# HELP dagul_player_kicks_total Players kicked since process start.",
    "# TYPE dagul_player_kicks_total counter",
    `dagul_player_kicks_total{slot="${s}"} ${playerKickTotal}`,

    "# HELP dagul_match_failures_total Room join / match failures.",
    "# TYPE dagul_match_failures_total counter",
    `dagul_match_failures_total{slot="${s}"} ${matchFailTotal}`,

    "# HELP dagul_tick_overruns_total Ticks that exceeded budget (>16.7ms).",
    "# TYPE dagul_tick_overruns_total counter",
    `dagul_tick_overruns_total{slot="${s}"} ${tickOverrunTotal}`,

    "# HELP dagul_session_duration_seconds_sum Total session duration (seconds).",
    "# TYPE dagul_session_duration_seconds_sum counter",
    `dagul_session_duration_seconds_sum{slot="${s}"} ${sessionDurSum.toFixed(3)}`,

    "# HELP dagul_session_duration_seconds_count Number of completed sessions.",
    "# TYPE dagul_session_duration_seconds_count counter",
    `dagul_session_duration_seconds_count{slot="${s}"} ${sessionDurCount}`,

    "# HELP dagul_tick_duration_ms_sum Total tick processing time (ms).",
    "# TYPE dagul_tick_duration_ms_sum counter",
    `dagul_tick_duration_ms_sum{slot="${s}"} ${tickDurSum.toFixed(3)}`,

    "# HELP dagul_tick_duration_ms_count Number of ticks measured.",
    "# TYPE dagul_tick_duration_ms_count counter",
    `dagul_tick_duration_ms_count{slot="${s}"} ${tickDurCount}`,

    "# HELP dagul_tick_duration_ms_max Max tick duration (ms) since start.",
    "# TYPE dagul_tick_duration_ms_max gauge",
    `dagul_tick_duration_ms_max{slot="${s}"} ${tickDurMax.toFixed(3)}`,

    "# HELP dagul_match_wait_seconds_sum Total match wait time (seconds).",
    "# TYPE dagul_match_wait_seconds_sum counter",
    `dagul_match_wait_seconds_sum{slot="${s}"} ${matchWaitSum.toFixed(3)}`,

    "# HELP dagul_match_wait_seconds_count Number of match waits measured.",
    "# TYPE dagul_match_wait_seconds_count counter",
    `dagul_match_wait_seconds_count{slot="${s}"} ${matchWaitCount}`,

    "# HELP dagul_round_duration_seconds_sum Total round duration (seconds).",
    "# TYPE dagul_round_duration_seconds_sum counter",
    `dagul_round_duration_seconds_sum{slot="${s}"} ${roundDurSum.toFixed(3)}`,

    "# HELP dagul_round_duration_seconds_count Number of rounds completed.",
    "# TYPE dagul_round_duration_seconds_count counter",
    `dagul_round_duration_seconds_count{slot="${s}"} ${roundDurCount}`,

    "# HELP dagul_ws_send_queue_length Current WS send queue depth.",
    "# TYPE dagul_ws_send_queue_length gauge",
    `dagul_ws_send_queue_length{slot="${s}"} ${wsQueueDepth}`,

    "# HELP dagul_dau Unique players today (in-process approximation).",
    "# TYPE dagul_dau gauge",
    `dagul_dau{slot="${s}"} ${dau}`,

    "",
  ].join("\n");
}

// ── reset (test support) ──

export function resetOpsMetrics(): void {
  wsConnTotal = 0;
  wsErrTotal = 0;
  wsDisconnTotal = 0;
  gamesStartedTotal = 0;
  gamesFinishedTotal = 0;
  playerKickTotal = 0;
  matchFailTotal = 0;
  tickOverrunTotal = 0;
  sessionDurSum = 0;
  sessionDurCount = 0;
  tickDurSum = 0;
  tickDurCount = 0;
  tickDurMax = 0;
  tickDurMaxResetAt = Date.now();
  matchWaitSum = 0;
  matchWaitCount = 0;
  roundDurSum = 0;
  roundDurCount = 0;
  wsQueueDepth = 0;
  dailySessions.clear();
}
