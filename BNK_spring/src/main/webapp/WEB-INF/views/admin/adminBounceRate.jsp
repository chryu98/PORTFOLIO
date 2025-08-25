<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <title>카드별 구간 이탈 현황 (LEGACY API)</title>
  <style>
    body{font-family:'Noto Sans KR',sans-serif;background:#f7f8fb;margin:0;padding:24px;color:#111}
    h2{margin:0 0 16px}
    .panel{background:#fff;border:1px solid #e5e7eb;border-radius:12px;padding:16px;margin-bottom:16px;box-shadow:0 4px 16px rgba(0,0,0,.04)}
    .row{display:flex;gap:12px;align-items:center;flex-wrap:wrap}
    label{font-size:13px;color:#374151;display:flex;align-items:center;gap:8px}
    input,select,button{height:36px;padding:0 10px;border:1px solid #d1d5db;border-radius:8px;background:#fff}
    button{cursor:pointer}
    table{width:100%;border-collapse:separate;border-spacing:0;margin-top:8px}
    th,td{padding:12px 10px;border-bottom:1px solid #eef2f7;font-size:13px;text-align:center}
    thead th{background:#f3f4f6;font-weight:700}
    .num{text-align:right}
    .bar{height:8px;background:#e5e7eb;border-radius:6px;overflow:hidden}
    .bar > i{display:block;height:100%;background:#ef4444}
    .muted{color:#6b7280;font-size:12px}
    .btn-link{background:none;border:none;color:#2563eb;text-decoration:underline;cursor:pointer}
  </style>
</head>
<body>
  <h2>카드별 구간 이탈 현황 (LEGACY API)</h2>

  <div class="panel">
    <form id="q" class="row" onsubmit="return false;">
      <label>카드
        <select id="cardNo" required>
          <option value="">카드 선택</option>
        </select>
      </label>
      <label>기간
        <input type="date" id="from" />
        ~
        <input type="date" id="to" />
      </label>
      <label>카드 종류
        <select id="isCredit">
          <option value="">전체</option>
          <option value="Y">신용(Y)</option>
          <option value="N">체크(N)</option>
        </select>
      </label>
      <label>표시 구간 수
        <input type="number" id="limitPerCard" min="1" max="50" value="20" />
      </label>
      <label>발급/취소 구간 제외
        <select id="excludeTerminals">
          <option value="Y" selected>예 (권장)</option>
          <option value="N">아니오</option>
        </select>
      </label>
      <button id="btn">조회</button>
      <span class="muted" id="status"></span>
    </form>
  </div>

  <div class="panel">
    <div id="cardTitle" class="muted" style="margin-bottom:8px"></div>
    <table id="tbl">
      <thead>
        <tr>
          <th>이탈 구간 (현재 단계 → 다음 단계)</th>
          <th>이탈 수</th>
          <th>이탈률(%)</th>
          <th>상세</th>
        </tr>
      </thead>
      <tbody id="tbody">
        <tr><td colspan="4" class="muted">카드를 선택하고 조회하세요.</td></tr>
      </tbody>
    </table>
  </div>

  <div class="panel" id="detailPanel" style="display:none">
    <h3 style="margin:0 0 8px">이탈자 상세</h3>
    <div id="detailMeta" class="muted" style="margin-bottom:8px"></div>
    <table>
      <thead>
        <tr>
          <th>신청번호</th><th>회원번호</th><th>이름</th><th>아이디</th>
          <th>최종상태</th><th>신청일</th><th>갱신일</th>
        </tr>
      </thead>
      <tbody id="detailBody">
        <tr><td colspan="7" class="muted">상세를 선택하세요.</td></tr>
      </tbody>
    </table>
  </div>

<script>
(function(){
  const $ = (id)=>document.getElementById(id);
  const fmt = (n)=> n==null ? '' : Number(n).toLocaleString();
  const fmtPct = (n)=> n==null ? '' : Number(n).toFixed(1);
  const dateStr = (s)=> s ? new Date(s).toLocaleString() : '';
  const pad = (x)=> String(x).padStart(2,'0');
  const toISO = (d)=> d.getFullYear()+"-"+pad(d.getMonth()+1)+"-"+pad(d.getDate());

  // 기본 날짜: 오늘/30일 전
  const today = new Date();
  const monthAgo = new Date(); monthAgo.setDate(today.getDate()-30);
  $('from').value = toISO(monthAgo);
  $('to').value = toISO(today);

  // 카드 목록 로드 후 자동 조회
  loadCards().then(loadSummary);

  async function loadCards(){
    const res = await fetch('/admin/api/journey/cards?activeOnly=Y', { headers: { 'Accept': 'application/json' } });
    const list = await res.json();
    $('cardNo').innerHTML = '<option value="">카드 선택</option>' + list.map(c =>
      `<option value="${c.cardNo}">[${c.cardNo}] ${c.cardName || ''}</option>`
    ).join('');
  }

  $('btn').addEventListener('click', loadSummary);
  $('cardNo').addEventListener('change', loadSummary);

  async function loadSummary(){
    const cardNo = $('cardNo').value;
    const from = $('from').value.trim();
    const to = $('to').value.trim();
    const isCredit = $('isCredit').value.trim();
    const limitPerCard = $('limitPerCard').value.trim();
    const excludeTerminals = $('excludeTerminals').value;

    if(!cardNo){
      $('tbody').innerHTML = '<tr><td colspan="4" class="muted">카드를 선택하세요.</td></tr>';
      $('cardTitle').textContent = '';
      return;
    }

    const params = new URLSearchParams({ cardNo, excludeTerminals, limitPerCard });
    if(from) params.set('from', from);
    if(to) params.set('to', to);
    if(isCredit) params.set('isCredit', isCredit);

    const url = '/admin/api/journey/drop-legacy/by-card?' + params.toString();
    $('status').textContent = url;

    const tbody = $('tbody');
    tbody.innerHTML = '<tr><td colspan="4" class="muted">불러오는 중…</td></tr>';

    try {
      const res = await fetch(url, { headers: { 'Accept': 'application/json' } });
      if(!res.ok) throw new Error('HTTP '+res.status);
      const data = await res.json();

      if(!Array.isArray(data) || data.length===0){
        tbody.innerHTML = '<tr><td colspan="4" class="muted">데이터가 없습니다.</td></tr>';
        $('cardTitle').textContent = '';
        return;
      }

      const cardName = data[0].cardName || '';
      $('cardTitle').textContent = `선택 카드: [${cardNo}] ${cardName}`;

      tbody.innerHTML = data.map((r)=> {
        const dropPct = r.dropPct==null ? 0 : r.dropPct;
        const gap = `${r.fromStepName || ''} → ${r.toStepName || ''}`;
        const btn = `<button class="btn-link" data-card="${r.cardNo}" data-cardname="${r.cardName}"
                       data-from="${r.fromStepCode}" data-gap="${gap}">상세보기</button>`;
        return `
          <tr>
            <td>${gap}</td>
            <td class="num"><strong>${fmt(r.droppedBetween)}</strong></td>
            <td class="num">
              <strong>${fmtPct(dropPct)}</strong>
              <div class="bar" title="${fmtPct(dropPct)}%"><i style="width:${dropPct}%;"></i></div>
            </td>
            <td>${btn}</td>
          </tr>`;
      }).join('');

      // 상세보기 핸들러
      [...document.querySelectorAll('button.btn-link')].forEach(btn=>{
        btn.addEventListener('click', ()=>{
          loadDetail({
            cardNo,
            cardName,
            atStep: btn.getAttribute('data-from'),
            gap: btn.getAttribute('data-gap'),
            from, to, isCredit
          });
        });
      });

    } catch(err){
      tbody.innerHTML = `<tr><td colspan="4" style="color:#b91c1c">에러: ${err.message}</td></tr>`;
    }
  }

  async function loadDetail({from, to, isCredit, cardNo, cardName, atStep, gap}){
	  const params = new URLSearchParams({ cardNo, fromStepCode: atStep });
    if(from) params.set('from', from);
    if(to) params.set('to', to);
    if(isCredit) params.set('isCredit', isCredit);

    const url = '/admin/api/journey/drop-legacy/by-card/details?' + params.toString();
    document.getElementById('detailPanel').style.display = 'block';
    document.getElementById('detailMeta').textContent =
      `[${cardNo}] ${cardName} — 이탈 구간: ${gap} (현재=${atStep} → 다음 단계 이탈) — API: ${url}`;

    const tbody = document.getElementById('detailBody');
    tbody.innerHTML = '<tr><td colspan="7" class="muted">불러오는 중…</td></tr>';

    try {
      const res = await fetch(url, { headers: { 'Accept': 'application/json' } });
      if(!res.ok) throw new Error('HTTP '+res.status);
      const data = await res.json();

      if(!Array.isArray(data) || data.length===0){
        tbody.innerHTML = '<tr><td colspan="7" class="muted">이탈자가 없습니다.</td></tr>';
        return;
      }

      tbody.innerHTML = data.map(d => `
        <tr>
          <td class="num">${d.applicationNo}</td>
          <td class="num">${d.memberNo}</td>
          <td>${d.name || ''}</td>
          <td>${d.username || ''}</td>
          <td>${d.lastStatus}</td>
          <td>${dateStr(d.createdAt)}</td>
          <td>${dateStr(d.updatedAt)}</td>
        </tr>
      `).join('');

    } catch(err){
      tbody.innerHTML = `<tr><td colspan="7" style="color:#b91c1c">에러: ${err.message}</td></tr>`;
    }
  }
})();
</script>

</body>
</html>
