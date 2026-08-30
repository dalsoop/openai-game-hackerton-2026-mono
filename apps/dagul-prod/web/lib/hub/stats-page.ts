/**
 * /stats — 자체 내장 대시보드 HTML. Grafana 없이 dagul-prod.external.kr/stats 로 접근.
 * /api/stats JSON 을 5초마다 폴링해 갱신한다.
 */

export function statsPageHtml(): string {
  return `<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>다굴즈 서버 대시보드</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,system-ui,sans-serif;background:#0d1117;color:#c9d1d9;padding:20px}
h1{font-size:1.4rem;margin-bottom:16px;color:#58a6ff}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:12px;margin-bottom:24px}
.card{background:#161b22;border:1px solid #30363d;border-radius:8px;padding:16px}
.card .label{font-size:.75rem;color:#8b949e;text-transform:uppercase;letter-spacing:.5px}
.card .value{font-size:1.8rem;font-weight:700;margin-top:4px}
.card .sub{font-size:.8rem;color:#8b949e;margin-top:2px}
.section{font-size:1rem;font-weight:600;color:#58a6ff;margin:20px 0 10px;border-bottom:1px solid #30363d;padding-bottom:6px}
.green{color:#3fb950}.yellow{color:#d29922}.red{color:#f85149}.gray{color:#8b949e}
.bar{height:8px;background:#30363d;border-radius:4px;margin-top:8px;overflow:hidden}
.bar-fill{height:100%;border-radius:4px;transition:width .5s}
.updated{font-size:.7rem;color:#484f58;margin-top:16px;text-align:right}
</style>
</head>
<body>
<h1>🎮 다굴즈 서버 대시보드</h1>
<div id="app">로딩 중...</div>
<script>
const $ = document.getElementById.bind(document);
function c(v,t){return v>=t?'red':v>=t*.75?'yellow':v>=t*.5?'yellow':'green'}
function pct(a,b){return b?Math.round(a/b*100):0}
function fmt(v){return v!=null?v:'—'}
function render(d){
  const cap=d.ccu_cap||100;
  const usage=pct(d.ccu,cap);
  const avgTick=d.tick_count?d.tick_sum/d.tick_count:0;
  const avgSession=d.session_count?(d.session_sum/d.session_count).toFixed(0):0;
  const avgWait=d.match_wait_count?(d.match_wait_sum/d.match_wait_count).toFixed(0):0;
  const avgRound=d.round_count?(d.round_sum/d.round_count).toFixed(0):0;
  const avgLoad=d.asset_count?(d.asset_sum/d.asset_count).toFixed(1):0;
  $('app').innerHTML=\`
<div class="section">접속 현황</div>
<div class="grid">
  <div class="card">
    <div class="label">동접 / 정원</div>
    <div class="value \${c(d.ccu,cap)}">\${d.ccu} <span class="gray" style="font-size:1rem">/ \${cap}</span></div>
    <div class="bar"><div class="bar-fill" style="width:\${usage}%;background:\${usage>=100?'#f85149':usage>=75?'#d29922':'#3fb950'}"></div></div>
  </div>
  <div class="card">
    <div class="label">입장</div>
    <div class="value \${d.admit?'green':'red'}">\${d.admit?'가능':'꽉참'}</div>
  </div>
  <div class="card">
    <div class="label">DAU (오늘)</div>
    <div class="value">\${d.dau}</div>
  </div>
  <div class="card">
    <div class="label">방 / 플레이 중</div>
    <div class="value">\${d.rooms} <span class="gray" style="font-size:1rem">/ \${d.rooms_playing}</span></div>
  </div>
  <div class="card">
    <div class="label">플레이어</div>
    <div class="value">\${d.players}</div>
  </div>
</div>

<div class="section">게임 통계</div>
<div class="grid">
  <div class="card">
    <div class="label">게임 시작 / 완료</div>
    <div class="value">\${d.games_started} <span class="gray" style="font-size:1rem">/ \${d.games_finished}</span></div>
  </div>
  <div class="card">
    <div class="label">평균 대기 시간</div>
    <div class="value">\${avgWait}<span class="gray" style="font-size:1rem">초</span></div>
  </div>
  <div class="card">
    <div class="label">평균 라운드</div>
    <div class="value">\${avgRound}<span class="gray" style="font-size:1rem">초</span></div>
  </div>
  <div class="card">
    <div class="label">평균 세션</div>
    <div class="value">\${avgSession}<span class="gray" style="font-size:1rem">초</span></div>
  </div>
  <div class="card">
    <div class="label">에셋 로딩</div>
    <div class="value">\${avgLoad}<span class="gray" style="font-size:1rem">초</span></div>
  </div>
</div>

<div class="section">서버 성능</div>
<div class="grid">
  <div class="card">
    <div class="label">평균 틱</div>
    <div class="value \${avgTick>10?'red':avgTick>5?'yellow':'green'}">\${avgTick.toFixed(2)}<span class="gray" style="font-size:1rem">ms</span></div>
  </div>
  <div class="card">
    <div class="label">틱 최대</div>
    <div class="value \${d.tick_max>16.7?'red':d.tick_max>10?'yellow':'green'}">\${d.tick_max.toFixed(1)}<span class="gray" style="font-size:1rem">ms</span></div>
  </div>
  <div class="card">
    <div class="label">틱 초과</div>
    <div class="value">\${d.tick_overruns}</div>
  </div>
  <div class="card">
    <div class="label">WS 큐</div>
    <div class="value \${d.ws_queue>200?'red':d.ws_queue>50?'yellow':'green'}">\${d.ws_queue}</div>
  </div>
  <div class="card">
    <div class="label">WS 에러</div>
    <div class="value \${d.ws_errors>0?'red':'green'}">\${d.ws_errors}</div>
  </div>
  <div class="card">
    <div class="label">킥 / 입장실패</div>
    <div class="value">\${d.kicks} <span class="gray" style="font-size:1rem">/ \${d.match_failures}</span></div>
  </div>
</div>

\${d.d1!=null||d.d7!=null?\`
<div class="section">리텐션</div>
<div class="grid">
  \${d.d1!=null?\`<div class="card"><div class="label">D1 리텐션</div><div class="value">\${(d.d1*100).toFixed(0)}<span class="gray" style="font-size:1rem">%</span></div></div>\`:''}
  \${d.d7!=null?\`<div class="card"><div class="label">D7 리텐션</div><div class="value">\${(d.d7*100).toFixed(0)}<span class="gray" style="font-size:1rem">%</span></div></div>\`:''}
</div>
\`:''}

<div class="updated">마지막 갱신: \${new Date().toLocaleTimeString('ko-KR')} · 5초마다 자동 갱신</div>
\`;
}
async function poll(){
  try{
    const r=await fetch('/api/stats');
    if(r.ok){render(await r.json())}
  }catch{}
}
poll();
setInterval(poll,5000);
</script>
</body>
</html>`;
}
