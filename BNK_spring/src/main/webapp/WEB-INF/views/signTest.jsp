<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>전자서명 테스트</title>
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, 'Noto Sans KR', sans-serif; }
    .box { max-width: 860px; margin: 32px auto; padding: 16px; border:1px solid #e5e7eb; border-radius: 10px; }
    label { display: inline-block; min-width: 130px; color:#374151; }
    input[type="text"] { width: 300px; padding: 6px 10px; border:1px solid #d1d5db; border-radius: 6px; }
    .row { margin: 10px 0; }
    .btn { padding: 8px 14px; border:0; border-radius: 8px; background:#b91111; color:#fff; cursor:pointer; }
    .btn.gray { background:#6b7280; }
    .btn.light { background:#f3f4f6; color:#111827; border:1px solid #e5e7eb; }
    #pad { border:1px dashed #9ca3af; border-radius: 8px; background:#fff; touch-action: none; }
    #preview { max-width: 100%; border:1px solid #e5e7eb; border-radius:8px; }
    small.hint { color:#6b7280; }
  </style>
</head>
<body>
<div class="box">
  <h2>전자서명 테스트 (JSP)</h2>

  <div class="row">
    <label>Application No</label>
    <input type="text" id="appNo" placeholder="예: 123" />
  </div>

  <div class="row">
    <label>JWT Access Token</label>
    <input type="text" id="token" placeholder="Bearer 없이 토큰만 붙여주세요" />
    <div><small class="hint">※ 인증이 걸려있다면 여기 토큰을 넣고 테스트 (로그인 API로 받은 accessToken)</small></div>
  </div>

  <div class="row">
    <label>서명 패드</label><br/>
    <canvas id="pad" width="640" height="220"></canvas>
  </div>

  <div class="row">
    <button class="btn light" id="clearBtn">지우기</button>
    <button class="btn gray" id="existsBtn">서명여부 조회</button>
    <button class="btn gray" id="infoBtn">메타 조회</button>
    <button class="btn" id="saveBtn">저장</button>
  </div>

  <div id="log" class="row"><small class="hint">결과 메시지가 여기에 표시됩니다.</small></div>

  <div class="row">
    <label>서명 이미지 미리보기</label><br/>
    <img id="preview" alt="없음" />
  </div>
</div>

<script>
(function() {
  const pad = document.getElementById('pad');
  const ctx = pad.getContext('2d');
  ctx.lineWidth = 3; ctx.lineCap = 'round'; ctx.strokeStyle = '#111';

  let drawing = false, last = null;

  function pos(e) {
    if (e.touches && e.touches.length) {
      const r = pad.getBoundingClientRect();
      return { x: e.touches[0].clientX - r.left, y: e.touches[0].clientY - r.top };
    } else {
      const r = pad.getBoundingClientRect();
      return { x: e.clientX - r.left, y: e.clientY - r.top };
    }
  }

  function down(e){ drawing = true; last = pos(e); e.preventDefault(); }
  function move(e){
    if (!drawing) return;
    const p = pos(e);
    ctx.beginPath(); ctx.moveTo(last.x, last.y); ctx.lineTo(p.x, p.y); ctx.stroke();
    last = p; e.preventDefault();
  }
  function up(e){ drawing = false; last = null; e.preventDefault(); }

  pad.addEventListener('mousedown', down);
  pad.addEventListener('mousemove', move);
  pad.addEventListener('mouseup', up);
  pad.addEventListener('mouseleave', up);
  pad.addEventListener('touchstart', down, {passive:false});
  pad.addEventListener('touchmove', move, {passive:false});
  pad.addEventListener('touchend', up, {passive:false});

  function log(msg){ document.getElementById('log').innerHTML = '<small>'+msg+'</small>'; }

  document.getElementById('clearBtn').onclick = () => {
    ctx.clearRect(0,0,pad.width,pad.height);
    log('패드를 초기화했습니다.');
  };

  function apiBase(){ return ''; } // 동일 도메인 가정. 필요하면 프리픽스 리턴

  function authHeader() {
    const t = document.getElementById('token').value.trim();
    return t ? { 'Authorization': 'Bearer ' + t } : {};
  }

  function loadPreview() {
    const appNo = document.getElementById('appNo').value.trim();
    if (!appNo) { log('Application No 입력'); return; }
    const url = apiBase() + '/card/apply/sign/' + encodeURIComponent(appNo) + '/image?ts=' + Date.now();
    document.getElementById('preview').src = url;
  }

  document.getElementById('existsBtn').onclick = async () => {
    const appNo = document.getElementById('appNo').value.trim();
    if (!appNo) { log('Application No 입력'); return; }
    try {
      const r = await fetch(apiBase() + '/api/card/apply/sign/' + encodeURIComponent(appNo) + '/exists', {
        headers: { 'Accept': 'application/json', ...authHeader() }
      });
      const j = await r.json();
      log('exists=' + j.exists);
      if (j.exists) loadPreview();
    } catch (e) { log('오류: ' + e); }
  };

  document.getElementById('infoBtn').onclick = async () => {
    const appNo = document.getElementById('appNo').value.trim();
    if (!appNo) { log('Application No 입력'); return; }
    try {
      const r = await fetch(apiBase() + '/api/card/apply/sign/' + encodeURIComponent(appNo), {
        headers: { 'Accept': 'application/json', ...authHeader() }
      });
      const j = await r.json();
      log('info=' + JSON.stringify(j));
      if (j.exists) loadPreview();
    } catch (e) { log('오류: ' + e); }
  };

  document.getElementById('saveBtn').onclick = async () => {
    const appNo = document.getElementById('appNo').value.trim();
    if (!appNo) { log('Application No 입력'); return; }

    const dataUrl = pad.toDataURL('image/png'); // "data:image/png;base64,...."
    try {
      const r = await fetch(apiBase() + '/api/card/apply/sign', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', ...authHeader() },
        body: JSON.stringify({ applicationNo: Number(appNo), imageBase64: dataUrl })
      });
      const j = await r.json();
      log(JSON.stringify(j));
      if (j.ok) loadPreview();
    } catch (e) { log('오류: ' + e); }
  };

})();
</script>
</body>
</html>
