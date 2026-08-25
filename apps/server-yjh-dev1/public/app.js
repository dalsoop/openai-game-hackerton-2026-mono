/* ===================== I18N ===================== */
const I18N = {
  appTitle: "다굴 같이하기",
  tagline: "8명 \xb7 한 판 \xb7 마지막 한 명",
  connecting: "서버 연결 중…",
  connected: "접속됨",
  prefetchReady: "게임 준비 완료",
  prefetchProgress: (pct) => `게임 다운로드 ${pct}%`,
  prefetchInit: "게임 다운로드 준비 중",
  namePlaceholder: "내 이름",
  modeSelect: "모드 선택",
  openRooms: "열린 방",
  createRoom: "방 만들기",
  waitingRoom: "대기실",
  leave: "나가기",
  copyLink: "링크 복사",
  share: "공유",
  chatPlaceholder: "채팅...",
  chatSend: "전송",
  gameStart: "게임으로 이동",
  emptySlot: "빈자리",
  cpuSlot: "시작 시 CPU",
  host: "호스트",
  me: "나",
  dropped: "끌김",
  noRooms: "아직 열린 방이 없습니다. 모드를 골라 방을 만들어보세요.",
  linkCopied: "초대 링크가 복사되었습니다.",
  kicked: "방에서 내보내졌습니다.",
  reconnecting: (n) => `연결이 끊겼습니다. 다시 연결하는 중… (${n}번째 시도)`,
  gameLoading: (pct) => `게임 로딩 중… ${pct}%`,
  victory: "VICTORY",
  draw: "무승부",
  kills: "킬",
  alive: "생존",
  eliminated: "탈락",
  backToLobby: "로비로",
  scoreCols: { rank: "#", player: "플레이어", kills: "킬", status: "상태" },
  enter: "입장 →",
  defaultName: "웹",
};

/* ===================== CONSTANTS ===================== */
const NET = {
  PING_INTERVAL_MS: 5000,
  RECONNECT_BASE_MS: 500,
  RECONNECT_MAX_MS: 30000,
  RECONNECT_JITTER_MS: 250,
  PING_UPDATE_INTERVAL_MS: 2000,
};

const MODE_TITLES = {
  classic: "클래식",
  "gun-semi": "무기 \xb7 단발",
  "gun-auto": "무기 \xb7 연발",
  item: "아이템",
  full: "합본",
};

const MODE_IMAGES = {};
for (const key of Object.keys(MODE_TITLES)) {
  MODE_IMAGES[key] = `assets/mode-${key}.png`;
}
const MODE_IMAGE_FALLBACK = "assets/mode-classic.png";

const MAX_PLAYERS = 8;

/* ===================== VISUAL ASSETS ===================== */
const PLAYER_COLORS = ['var(--p1)','var(--p2)','var(--p3)','var(--p4)','var(--p5)','var(--p6)','var(--p7)','var(--p8)'];
const AVATAR_SHAPES = [
  '<circle cx="16" cy="13" r="8"/>',
  '<rect x="8" y="5" width="16" height="16" rx="3"/>',
  '<path d="M16 4 L25 20 L7 20 Z"/>',
  '<path d="M16 4 L26 13 L16 22 L6 13 Z"/>',
  '<path d="M16 4 L25 10 L22 21 L10 21 L7 10 Z"/>',
  '<path d="M16 4 L24 8 L24 18 L16 22 L8 18 L8 8 Z"/>',
  '<path d="M16 3 L19 11 L27 11 L21 16 L23 24 L16 19 L9 24 L11 16 L5 11 L13 11 Z"/>',
  '<path d="M8 20 A8 8 0 1 1 24 20 L24 14 A8 8 0 0 0 8 14 Z"/>',
];
function avatarSVG(i, size=32) {
  const idx = ((i % 8) + 8) % 8;
  return `<svg viewBox="0 0 32 32" width="${size}" height="${size}"><g fill="${PLAYER_COLORS[idx]}">${AVATAR_SHAPES[idx]}</g><rect x="9" y="23" width="14" height="5" rx="2.5" fill="${PLAYER_COLORS[idx]}" opacity=".55"/></svg>`;
}
const CROWN_SVG = '<svg viewBox="0 0 16 12" width="14" height="10" style="vertical-align:middle;margin-right:2px"><path d="M1 11 h14 L14 3 L10.5 6.5 L8 1 L5.5 6.5 L2 3 Z" fill="var(--acc)"/></svg>';

const proto = location.protocol === "https:" ? "wss" : "ws";
const wsPath = location.pathname.replace(/\/[^/]*$/, "") || "";
const params = new URLSearchParams(location.search);
let modes = {};
let rooms = [];
let players = [];
let you = 0;
let myId = "";
let phase = "hub";
let selectedMode = params.get("mode") || "classic";
let roomInfo = null;
let myPing = 0;
let resultShown = false;
const nameIn = document.getElementById("name");
nameIn.value = params.get("name") || (I18N.defaultName + Math.floor(10 + Math.random() * 89));

let ws = null;
let reconnectAttempt = 0;
let intentionalClose = false;
// Unified resume token key: gangup_resume
let resumeToken = sessionStorage.getItem("gangup_resume") || localStorage.getItem("gangup_resume") || "";
// Migrate legacy key
(function migrateLegacyResumeKey() {
  const legacy = sessionStorage.getItem("gangup.resume");
  if (legacy && !sessionStorage.getItem("gangup_resume")) {
    sessionStorage.setItem("gangup_resume", legacy);
    if (!resumeToken) resumeToken = legacy;
  }
  sessionStorage.removeItem("gangup.resume");
  const legacyLocal = localStorage.getItem("gangup.resume");
  if (legacyLocal) {
    if (!localStorage.getItem("gangup_resume")) localStorage.setItem("gangup_resume", legacyLocal);
    localStorage.removeItem("gangup.resume");
  }
})();
let welcomed = false;

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));

function send(msg) {
  if (ws && ws.readyState === 1) ws.send(JSON.stringify(msg));
}

function setPhase(next) {
  phase = next;
  document.body.className = next === "wait" ? "wait" : "";
}

let wantResume = false;
function hello() {
  send({ t: "hello", name: nameIn.value || I18N.defaultName, mode: selectedMode, resume: resumeToken, wantResume });
  send({ t: "rooms" });
  wantResume = false;
}

/* --- toast --- */
function toast(msg, kind='') {
  const el = document.createElement('div');
  el.className = 'toast ' + kind;
  el.textContent = msg;
  document.getElementById('toasts').appendChild(el);
  setTimeout(() => { el.classList.add('out'); setTimeout(() => el.remove(), 300); }, 3200);
}

/* --- banner --- */
function showBanner(text) {
  const conn = document.getElementById("connStatus");
  conn.className = "conn bad";
  document.getElementById("status").textContent = text;
  let el = document.getElementById("reconnect-banner");
  if (!el) {
    el = document.createElement("div");
    el.id = "reconnect-banner";
    el.className = "reconnect-banner";
    document.body.appendChild(el);
  }
  el.textContent = text;
  el.style.display = "block";
}

function hideBanner() {
  const el = document.getElementById("reconnect-banner");
  if (el) el.style.display = "none";
  const conn = document.getElementById("connStatus");
  conn.className = "conn ok";
  updatePingDisplay();
}

function updatePingDisplay() {
  const st = document.getElementById("status");
  const pd = document.getElementById("pingDisplay");
  st.textContent = I18N.connected;
  pd.textContent = myPing > 0 ? myPing + "ms" : "";
}

/* --- chat --- */
function addChat(name, text, slot, sys) {
  const log = document.getElementById("chatLog");
  const div = document.createElement("div");
  div.className = sys ? "chat-msg sys" : "chat-msg";
  if (sys) {
    div.textContent = text;
  } else {
    div.innerHTML = `<b style="color:${PLAYER_COLORS[slot % 8]}">${esc(name)}</b>${esc(text)}`;
  }
  log.appendChild(div);
  log.scrollTop = log.scrollHeight;
}

/* --- connect --- */
function connect() {
  ws = new WebSocket(`${proto}://${location.host}${wsPath}`);
  ws.onopen = () => {
    wantResume = reconnectAttempt > 0;
    reconnectAttempt = 0;
    hideBanner();
  };
  ws.onmessage = onMessage;
  ws.onclose = () => {
    if (intentionalClose) return;
    showBanner(I18N.reconnecting(reconnectAttempt + 1));
    const delay = Math.min(NET.RECONNECT_BASE_MS * Math.pow(2, reconnectAttempt) + Math.random() * NET.RECONNECT_JITTER_MS, NET.RECONNECT_MAX_MS);
    reconnectAttempt++;
    setTimeout(connect, delay);
  };
  ws.onerror = () => {};
}

window.addEventListener("beforeunload", () => { intentionalClose = true; });

function storeToken(token) {
  if (token) {
    resumeToken = token;
    sessionStorage.setItem("gangup_resume", resumeToken);
    localStorage.setItem("gangup_resume", resumeToken);
  }
}

// --- Prefetch Godot engine in background ---
const GAME_FILES = ["/index.js", "/index.wasm", "/index.pck"];
let prefetchDone = false;
let prefetchFailed = false;
let prefetchPct = 0;

async function prefetchGame() {
  if (navigator.connection && navigator.connection.saveData) return;
  let loaded = 0;
  let totalEstimate = 40 * 1024 * 1024;
  try {
    for (const url of GAME_FILES) {
      const res = await fetch(url, { credentials: "same-origin" });
      if (!res.ok || !res.body) continue;
      const len = +(res.headers.get("Content-Length") || 0);
      if (len > 0) totalEstimate = Math.max(totalEstimate, loaded + len);
      const reader = res.body.getReader();
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        loaded += value.length;
        prefetchPct = Math.min(99, Math.round(loaded / totalEstimate * 100));
        updatePrefetchUI(prefetchPct);
      }
    }
    prefetchDone = true;
    prefetchPct = 100;
    updatePrefetchUI(100);
  } catch {
    prefetchFailed = true;
    prefetchPct = 0;
    updatePrefetchUI(0);
  }
}

function updatePrefetchUI(pct) {
  const el = document.getElementById("prefetch-bar");
  if (el) el.style.width = (prefetchFailed ? 0 : pct) + "%";
  const txt = document.getElementById("prefetch-text");
  if (!txt) return;
  if (prefetchFailed) {
    txt.textContent = I18N.prefetchInit;
  } else {
    txt.textContent = pct >= 100 ? I18N.prefetchReady : I18N.prefetchProgress(pct);
  }
}

function goToGame() {
  localStorage.setItem("gangup_resume", resumeToken);
  localStorage.setItem("gangup_from_hub", "1");
  localStorage.setItem("gangup_name", nameIn.value || I18N.defaultName);
  localStorage.setItem("gangup_mode", selectedMode);
  intentionalClose = true;
  location.href = "/";
}

setTimeout(prefetchGame, 2000);

function resetRoom() {
  players = []; roomInfo = null;
  resultShown = false;
  document.getElementById("result").classList.remove("show");
  history.replaceState({}, "", `?mode=${encodeURIComponent(selectedMode)}`);
}

const msgHandlers = {
  welcome(msg) {
    if (msg.id) myId = msg.id;
    const prevToken = resumeToken;
    storeToken(msg.resume);
    modes = msg.modes || {};
    if (!welcomed) {
      welcomed = true;
      setInterval(() => {
        if (myPing > 0 && !document.getElementById("reconnect-banner")?.style.display?.includes("block")) {
          updatePingDisplay();
        }
      }, NET.PING_UPDATE_INTERVAL_MS);
      const roomId = params.get("room");
      if (roomId) setTimeout(() => send({ t: "join", roomId }), 80);
    }
    hideBanner();
    renderModes();
    send({ t: "hello", name: nameIn.value || I18N.defaultName, mode: selectedMode, resume: prevToken, wantResume: !!prevToken && wantResume });
    send({ t: "rooms" });
  },
  resume(msg) {
    if (msg.id) myId = msg.id;
    you = msg.you;
    players = msg.players || [];
    roomInfo = msg.room;
    storeToken(msg.resume);
    if (msg.playing) {
      goToGame();
    } else {
      setPhase("wait"); renderWait();
    }
    hideBanner();
  },
  dropped(msg) {
    storeToken(msg.resume);
    setPhase("hub"); hello();
  },
  kicked(msg) {
    resetRoom();
    setPhase("hub"); hello();
    toast(msg.msg || I18N.kicked, "leave");
  },
  lobby() {
    resultShown = false;
    document.getElementById("result").classList.remove("show");
    setPhase("wait"); renderWait();
  },
  rooms(msg) { rooms = msg.rooms || []; renderRooms(); },
  joined(msg) {
    you = msg.you;
    players = msg.players || [];
    roomInfo = msg.room;
    selectedMode = msg.room.mode;
    history.replaceState({}, "", `?mode=${encodeURIComponent(selectedMode)}&room=${encodeURIComponent(msg.room.id)}`);
    document.getElementById("chatLog").innerHTML = "";
    setPhase("wait"); renderWait();
  },
  peers(msg) {
    players = msg.players || [];
    if (msg.room) roomInfo = msg.room;
    const me = players.find(p => p.id === myId);
    if (me) you = me.slot;
    if (msg.notice) addChat("", msg.notice, 0, true);
    renderWait();
  },
  chat(msg) { addChat(msg.from, msg.text, msg.slot, false); },
  start(msg) {
    you = msg.you;
    if (prefetchDone || prefetchFailed) {
      goToGame();
      return;
    }
    showBanner(I18N.gameLoading(prefetchPct));
    const checkInterval = setInterval(() => {
      if (prefetchDone || prefetchFailed) {
        clearInterval(checkInterval);
        hideBanner();
        goToGame();
      } else {
        showBanner(I18N.gameLoading(prefetchPct));
      }
    }, 300);
  },
  left() { resetRoom(); setPhase("hub"); hello(); },
  error(msg) { toast(msg.msg, "leave"); },
};

function onMessage(ev) {
  let msg;
  try {
    msg = JSON.parse(ev.data);
  } catch {
    return;
  }
  if (msg.t === "ping") { send({ t: "pong", ts: msg.ts }); return; }
  if (msg.t === "pong") { if (typeof msg.ts === "number") myPing = Date.now() - msg.ts; return; }
  const handler = msgHandlers[msg.t];
  if (handler) handler(msg);
}

/* ===================== RENDER FUNCTIONS ===================== */

function modeImageSrc(modeId) {
  return MODE_IMAGES[modeId] || MODE_IMAGE_FALLBACK;
}

function renderModes() {
  const el = document.getElementById("modes");
  el.innerHTML = Object.values(modes).map(m => {
    const imgSrc = modeImageSrc(m.id);
    return `<button class="mode-card ${m.id === selectedMode ? "on" : ""}" data-id="${esc(m.id)}">
      <img class="mode-art" src="${esc(imgSrc)}" alt="" onerror="this.src='${MODE_IMAGE_FALLBACK}'" />
      <b>${esc(m.title)}</b><span>${esc(m.blurb)}</span>
      <div class="mode-check"><svg viewBox="0 0 20 20" width="14"><path d="M4 10 l4 4 l8-8" stroke="var(--bg-0)" stroke-width="2.5" fill="none" stroke-linecap="round"/></svg></div>
    </button>`;
  }).join("");
  el.querySelectorAll(".mode-card").forEach(btn => {
    btn.onclick = () => {
      selectedMode = btn.dataset.id;
      renderModes();
    };
  });
  renderModeSelect();
}

function renderModeSelect() {
  const sel = document.getElementById("modeChange");
  sel.innerHTML = Object.values(modes).map(m =>
    `<option value="${esc(m.id)}" ${m.id === selectedMode ? "selected" : ""}>${esc(m.title)}</option>`
  ).join("");
}

function renderRooms() {
  const titles = MODE_TITLES;
  document.getElementById("roomCount").textContent = rooms.length;
  const el = document.getElementById("rooms");
  if (!rooms.length) {
    el.innerHTML = `<div class="empty-rooms">${I18N.noRooms}</div>`;
    return;
  }
  el.innerHTML = rooms.map(r => {
    let pips = '';
    for (let i = 0; i < MAX_PLAYERS; i++) pips += `<i${i < r.count ? ` style="background:${PLAYER_COLORS[i]}"` : ''}></i>`;
    return `<div class="room-card" data-id="${esc(r.id)}">
      <div class="room-info"><b>${esc(r.title)}</b><div class="room-pips">${pips}</div></div>
      <span class="room-mode-badge">${esc(titles[r.mode] || r.mode)}</span>
      <span class="room-count">${r.count}/${MAX_PLAYERS}</span>
      <span class="room-enter">${I18N.enter}</span>
    </div>`;
  }).join("");
  el.querySelectorAll(".room-card[data-id]").forEach(c => c.onclick = () => send({ t: "join", roomId: c.dataset.id }));
}

function renderWait() {
  const titles = MODE_TITLES;
  const modeName = titles[roomInfo?.mode] || "";
  document.getElementById("waitTitle").textContent = roomInfo?.title || I18N.waitingRoom;
  document.getElementById("waitMode").textContent = modeName;
  document.getElementById("invite").value = location.href;

  const amHost = players.some(p => p.id === myId && p.host);
  const hostBar = document.getElementById("hostBar");
  hostBar.style.display = amHost ? "flex" : "none";

  if (navigator.share) {
    const sb = document.getElementById("shareBtn");
    sb.style.display = "inline-block";
    sb.onclick = () => navigator.share({ title: I18N.appTitle, url: location.href });
  }

  const cells = [];
  for (let i = 0; i < MAX_PLAYERS; i++) {
    const p = players.find(x => x.slot === i);
    if (p) {
      const isMe = p.id === myId;
      cells.push(`<div class="slot-card filled${p.host ? ' host' : ''}${isMe ? ' me' : ''}" style="border-color:${PLAYER_COLORS[i]}">
        ${avatarSVG(i, 40)}
        <div class="slot-name">${esc(p.name)}</div>
        <div class="slot-tag">${p.host ? CROWN_SVG + I18N.host + ' \xb7 ' : ''}P${i+1}${isMe ? ' \xb7 ' + I18N.me : ''}${p.dropped ? ' \xb7 ' + I18N.dropped : ''}</div>
      </div>`);
    } else {
      cells.push(`<div class="slot-card">
        ${avatarSVG(i, 40)}
        <div class="slot-cpu">${I18N.emptySlot}</div>
        <div class="slot-tag">${I18N.cpuSlot}</div>
      </div>`);
    }
  }
  document.getElementById("slots").innerHTML = cells.join("");
}

/* ===================== EVENT BINDINGS ===================== */

nameIn.onchange = () => {
  document.getElementById("avatarPreview").innerHTML = avatarSVG(0, 44);
  hello();
};

document.getElementById("createRoom").onclick = () => {
  hello();
  send({ t: "create" });
};

document.getElementById("copy").onclick = async () => {
  const url = document.getElementById("invite").value;
  try {
    await navigator.clipboard.writeText(url);
    toast(I18N.linkCopied);
  } catch { document.getElementById("invite").select(); }
};

document.getElementById("leave").onclick = () => send({ t: "leave" });
document.getElementById("start").onclick = () => {
  send({ t: "start" });
};

document.getElementById("modeChange").onchange = (e) => {
  send({ t: "mode", mode: e.target.value });
};

document.getElementById("chatForm").onsubmit = (e) => {
  e.preventDefault();
  const inp = document.getElementById("chatInput");
  const text = inp.value.trim();
  if (!text) return;
  send({ t: "chat", text });
  inp.value = "";
};

document.getElementById("resultLobby").onclick = () => {
  send({ t: "leave" });
};

setInterval(() => { send({ t: "ping", ts: Date.now() }); }, NET.PING_INTERVAL_MS);

/* ===================== INIT ===================== */
document.getElementById("avatarPreview").innerHTML = avatarSVG(0, 44);
connect();
