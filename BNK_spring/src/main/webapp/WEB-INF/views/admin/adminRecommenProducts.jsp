<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>추천 상품 관리</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
/* ===== 기본 · 레이아웃 ===== */
* { box-sizing: border-box; }
html, body { height: 100%; }
body {
  margin: 0;
  background: #fff;                 /* 전체 화이트 */
  color: #111827;
  font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
}

/* 페이지 폭(가운데 정렬) */
body > .box {
  width: min(1100px, 92vw);         /* 필요 시 1000px/90vw 등으로 조절 */
  margin: 0 auto;
}

/* 제목 */
h1 {
  margin: 0px auto 16px;
  font-size: 24px;
  font-weight: 700;
  text-align: center;
}
h2 { margin: 28px 0 12px; font-size: 16px; }

/* ===== 카드/컨테이너 ===== */
.box {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  padding: 16px;
  margin: 16px auto 18px;
  box-shadow: 0 4px 12px rgba(0,0,0,.05);
}

/* ===== 폼/컨트롤 ===== */
.row { display: flex; gap: 12px; flex-wrap: wrap; align-items: end; }
label { font-size: 12px; color: #6b7280; display: block; margin-bottom: 6px; }

input, select, button {
  padding: 8px 10px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  background: #fff;
  color: #111827;
  outline: none;
  transition: border-color .18s, box-shadow .18s, filter .12s, transform .04s;
}
input:focus, select:focus {
  border-color: #2563eb;
  box-shadow: 0 0 0 3px rgba(37,99,235,.15);
}

button { cursor: pointer; }
button:hover { filter: brightness(0.98); }
button:active { transform: translateY(1px); }
button#btnLoadKpi,
button#btnLoadPopular,
button#btnLoadSimilar,
button#btnLoadLogs {
  background: #2563eb;
  border-color: #2563eb;
  color: #fff;
}

/* ===== KPI ===== */
.kpi { display: flex; gap: 12px; flex-wrap: wrap; }
.kpi .k {
  flex: 1 1 180px;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 12px 14px;
  background: #fff;
  box-shadow: 0 3px 8px rgba(0,0,0,.04);
}
.kpi .muted { font-size: 12px; color: #6b7280; margin-bottom: 4px; }

/* ===== 테이블 ===== */
table {
  width: 100%;
  border-collapse: collapse;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
}
th, td {
  padding: 10px 12px;
  border-bottom: 1px solid #f1f5f9;
  text-align: left;
  vertical-align: top;
  font-size: 14px;
}
th {
  background: #f9fafb;
  font-weight: 600;
  color: #374151;
}
tbody tr:hover { background: #fafafa; }
.right { text-align: right; }
.muted { color: #6b7280; font-size: 12px; }

/* ===== 카드/회원 셀 ===== */
.cardcell { display: flex; align-items: center; gap: 10px; min-width: 240px; }
.thumb {
  width: 48px; height: 30px;
  border-radius: 6px; object-fit: cover;
  background: #f2f2f2; border: 1px solid #eee;
}
.cardname { font-weight: 600; }
.cardno { color: #6b7280; font-size: 12px; }

.memberwrap { display: flex; align-items: center; gap: 10px; min-width: 200px; }
.membername { font-weight: 600; }
.memberno { color: #6b7280; font-size: 12px; }
.avatar {
  width: 30px; height: 30px; border-radius: 50%;
  background: #f2f2f2; border: 1px solid #eee;
  display: inline-flex; align-items: center; justify-content: center;
  font-size: 12px; color: #9ca3af;
}

/* ===== 하단 페이지 버튼 영역 정렬 ===== */
.row[style*="justify-content:flex-end"] { gap: 8px; }

/* ===== 반응형 ===== */
@media (max-width: 720px) {
  h1 { font-size: 20px; }
  th, td { padding: 9px 10px; font-size: 13px; }
  .cardcell { min-width: 200px; }
  .memberwrap { min-width: 160px; }
}

/* ===== 프린트 ===== */
@media print {
  .box { box-shadow: none; border-color: #ddd; page-break-inside: avoid; }
  button { display: none !important; }
}

  </style>

<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
<jsp:include page="../fragments/header.jsp"></jsp:include>
  <h1>추천 상품 관리</h1>

  <!-- KPI -->
  <div class="box">
    <h2>요약 KPI</h2>
    <div class="row">
      <div>
        <label>조회 기간(일)</label>
        <input type="number" id="kpiDays" value="30" min="1" />
      </div>
      <button id="btnLoadKpi">KPI 조회</button>
      <div class="muted" id="kpiRange"></div>
    </div>
    <div class="kpi" id="kpiWrap"></div>
  </div>

  <!-- 인기 카드 -->
  <div class="box">
    <h2>인기 카드 TOP N</h2>
    <div class="row">
      <div>
        <label>조회 기간(일)</label>
        <input type="number" id="popularDays" value="30" min="1" />
      </div>
      <div>
        <label>개수</label>
        <input type="number" id="popularLimit" value="10" min="1" />
      </div>
      <button id="btnLoadPopular">인기 조회</button>
    </div>
    <table>
      <thead>
        <tr>
          <th>카드</th>
          <th class="right">VIEW</th>
          <th class="right">CLICK</th>
          <th class="right">APPLY</th>
          <th class="right">점수</th>
          <th class="right">클릭률</th>
          <th class="right">전환율</th>
        </tr>
      </thead>
      <tbody id="popularTbody"></tbody>
    </table>
  </div>

  <!-- 유사 카드 -->
  <div class="box">
    <h2>유사 혜택 카드 추천</h2>
    <div class="row">
      <div>
        <label>기준 카드(번호 또는 이름)</label>
        <input type="text" id="similarKey" placeholder="예) 1001 또는 커피 혜택 카드" />
      </div>
      <div>
        <label>조회 기간(일)</label>
        <input type="number" id="similarDays" value="30" min="1" />
      </div>
      <div>
        <label>개수</label>
        <input type="number" id="similarLimit" value="10" min="1" />
      </div>
      <button id="btnLoadSimilar">유사카드 조회</button>
    </div>
    <table>
      <thead>
        <tr>
          <th>기준 카드</th>
          <th>유사 카드</th>
          <th class="right">유사도 점수</th>
        </tr>
      </thead>
      <tbody id="similarTbody"></tbody>
    </table>
  </div>

  <!-- 로그 -->
  <div class="box">
    <h2>행동 로그</h2>
    <div class="row">
      <!-- 번호 또는 이름 + 자동완성 -->
      <div>
        <label>회원(번호 또는 이름)</label>
        <input type="text" id="logMemberKey" placeholder="예) 1001 또는 홍길동" list="memberHints" />
        <datalist id="memberHints"></datalist>
      </div>
      <div>
        <label>카드(번호 또는 이름)</label>
        <input type="text" id="logCardKey" placeholder="예) 2002 또는 커피 혜택 카드" list="cardHints" />
        <datalist id="cardHints"></datalist>
      </div>
      <div>
        <label>타입</label>
        <select id="logType">
          <option value="">(전체)</option>
          <option value="VIEW">VIEW</option>
          <option value="CLICK">CLICK</option>
          <option value="APPLY">APPLY</option>
        </select>
      </div>
      <div>
        <label>시작일</label>
        <input type="date" id="logFrom" />
      </div>
      <div>
        <label>종료일</label>
        <input type="date" id="logTo" />
      </div>
      <div class="controls">
        <label>페이지</label>
        <input type="number" id="logPage" value="1" min="1" style="width:80px"/>
        <label>사이즈</label>
        <input type="number" id="logSize" value="20" min="1" style="width:80px"/>
      </div>
      <button id="btnLoadLogs">로그 조회</button>
    </div>
    <table>
      <thead>
        <tr>
          <th>LOG_NO</th>
          <th>회원</th>
          <th>카드</th>
          <th>TYPE</th>
          <th>TIME</th>
          <th>DEVICE</th>
          <th>IP</th>
          <th>USER_AGENT</th>
        </tr>
      </thead>
      <tbody id="logsTbody"></tbody>
    </table>
    <div class="row" style="justify-content:flex-end; margin-top:10px;">
      <button id="prevPage">이전</button>
      <button id="nextPage">다음</button>
    </div>
  </div>

<script src="/js/adminHeader.js"></script>
  <script>
    const ctx = '<%= request.getContextPath() %>';
    const API = ctx + '/admin/reco';

    // 숫자/비율 포맷
    const fmt = (n) => n == null ? '-' : Number(n).toLocaleString();
    const pct = (n) => (n == null ? '-' : (Number(n) * 100).toFixed(1) + '%');
    const cut10 = (s) => (s ? String(s).substring(0,10) : '');

    // === 이미지/플레이스홀더 유틸 ===
    const PH = "data:image/svg+xml;utf8,\
<svg xmlns='http://www.w3.org/2000/svg' width='96' height='60'>\
<rect width='100%' height='100%' fill='%23f2f2f2'/>\
<text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' fill='%23999' font-size='12'>no image</text>\
</svg>";

    function isImageUrl(u){
      if(!u) return false;
      try{
        const url = new URL(u, location.origin);
        const path = url.pathname.toLowerCase();
        if (/\.(png|jpe?g|webp|gif|bmp|svg)$/.test(path)) return true;
        const fmtQ = url.searchParams.get('format') || url.searchParams.get('ext');
        return !!(fmtQ && /png|jpe?g|webp|gif|bmp|svg/i.test(fmtQ));
      }catch{ return false; }
    }
    function normalizeUrl(u){
      try{
        if(!u) return u;
        const url = new URL(u, location.origin);
        if(location.protocol === 'https:' && url.protocol === 'http:'){
          url.protocol = 'https:';
        }
        return url.toString();
      }catch{ return u; }
    }
    function pickImageSrcFromRecord(r){
      const first = r?.cardImageUrl;
      const fallback = isImageUrl(r?.cardProductUrl) ? r.cardProductUrl : null;
      return normalizeUrl(first || fallback);
    }
    function imgTag(src, altText){
      return src
        ? `<img class="thumb" src="${src}" alt="${altText || ''}" referrerpolicy="no-referrer" loading="lazy"
                 decoding="async" onerror="this.onerror=null; this.src='${PH}'">`
        : `<div class="thumb" role="img" aria-label="no image"></div>`;
    }

    // 공통 fetch
    async function jfetch(url){
      const res = await fetch(url, { headers: { 'Accept': 'application/json' } });
      if(!res.ok){
        const text = await res.text().catch(()=> '');
        throw new Error('HTTP '+res.status+' '+res.statusText+' :: '+text);
      }
      return res.json();
    }

    // KPI
    async function loadKpi(){
      try {
        const days = document.getElementById('kpiDays').value || 30;
        const data = await jfetch(`${API}/kpi?days=${days}`);
        const kpi = Array.isArray(data) && data.length ? data[0] : null;

        const wrap = document.getElementById('kpiWrap');
        const rng  = document.getElementById('kpiRange');
        wrap.innerHTML = '';
        if(!kpi){
          wrap.innerHTML = '<div class="muted">데이터 없음</div>';
          rng.textContent = '';
          return;
        }
        rng.textContent = '기간: ' + cut10(kpi.fromDate) + ' ~ ' + cut10(kpi.toDate);

        wrap.innerHTML = ''
          + `<div class="k"><div class="muted">VIEW</div><div style="font-size:20px;font-weight:700;">${fmt(kpi.views)}</div></div>`
          + `<div class="k"><div class="muted">CLICK</div><div style="font-size:20px;font-weight:700;">${fmt(kpi.clicks)}</div></div>`
          + `<div class="k"><div class="muted">APPLY</div><div style="font-size:20px;font-weight:700;">${fmt(kpi.applies)}</div></div>`
          + `<div class="k"><div class="muted">클릭률</div><div style="font-size:20px;font-weight:700;">${pct(kpi.ctr)}</div></div>`
          + `<div class="k"><div class="muted">전환율</div><div style="font-size:20px;font-weight:700;">${pct(kpi.cvr)}</div></div>`;
      } catch (e){
        alert('KPI 조회 실패: ' + e.message);
      }
    }

    // 인기
    async function loadPopular(){
      try {
        const days  = document.getElementById('popularDays').value || 30;
        const limit = document.getElementById('popularLimit').value || 10;
        const data  = await jfetch(`${API}/popular?days=${days}&limit=${limit}`);

        const tb = document.getElementById('popularTbody');
        tb.innerHTML = (data||[]).map(r => {
          const src = pickImageSrcFromRecord(r);
          const img = imgTag(src, r.cardName || '카드 이미지');

          const name = r.cardName || '(이름없음)';
          const num  = r.cardNo ? `#${r.cardNo}` : '';
          const a1 = r.cardProductUrl ? `<a href="${r.cardProductUrl}" target="_blank" style="text-decoration:none;color:inherit">` : '';
          const a2 = r.cardProductUrl ? `</a>` : '';

          return `
            <tr>
              <td>
                ${a1}
                <div class="cardcell">
                  ${img}
                  <div>
                    <div class="cardname">${name}</div>
                    <div class="cardno">${num}</div>
                  </div>
                </div>
                ${a2}
              </td>
              <td class="right">${fmt(r.views)}</td>
              <td class="right">${fmt(r.clicks)}</td>
              <td class="right">${fmt(r.applies)}</td>
              <td class="right">${fmt(r.score)}</td>
              <td class="right">${pct(r.ctr)}</td>
              <td class="right">${pct(r.cvr)}</td>
            </tr>
          `;
        }).join('') || `<tr><td colspan="7" class="muted">데이터 없음</td></tr>`;
      } catch (e){
        alert('인기 카드 조회 실패: ' + e.message);
      }
    }

    // 유사
    async function loadSimilar(){
      try {
        const key   = (document.getElementById('similarKey').value || '').trim();
        const days  = document.getElementById('similarDays').value || 30;
        const limit = document.getElementById('similarLimit').value || 10;
        if(!key){ alert('기준 카드(번호 또는 이름)를 입력해주세요.'); return; }

        const url = `${API}/similar/${encodeURIComponent(key)}?days=${days}&limit=${limit}`;
        const data = await jfetch(url);

        const tb = document.getElementById('similarTbody');
        tb.innerHTML = (data||[]).map(r => {
          const bImg = imgTag(pickImageSrcFromRecord(r), r.cardName || '기준 카드');
          const bName = r.cardName || '(이름없음)';
          const bNum  = r.cardNo ? `#${r.cardNo}` : '';
          const b1 = r.cardProductUrl ? `<a href="${r.cardProductUrl}" target="_blank" style="text-decoration:none;color:inherit">` : '';
          const b2 = r.cardProductUrl ? `</a>` : '';

          const sImg = imgTag(pickImageSrcFromRecord({
            cardImageUrl: r.otherCardImageUrl,
            cardProductUrl: r.otherCardProductUrl
          }), r.otherCardName || '유사 카드');
          const sName = r.otherCardName || '(이름없음)';
          const sNum  = r.otherCardNo ? `#${r.otherCardNo}` : '';
          const s1 = r.otherCardProductUrl ? `<a href="${r.otherCardProductUrl}" target="_blank" style="text-decoration:none;color:inherit">` : '';
          const s2 = r.otherCardProductUrl ? `</a>` : '';

          return `
            <tr>
              <td>
                ${b1}
                <div class="cardcell">${bImg}<div><div class="cardname">${bName}</div><div class="cardno">${bNum}</div></div></div>
                ${b2}
              </td>
              <td>
                ${s1}
                <div class="cardcell">${sImg}<div><div class="cardname">${sName}</div><div class="cardno">${sNum}</div></div></div>
                ${s2}
              </td>
              <td class="right">${fmt(r.simScore)}</td>
            </tr>
          `;
        }).join('') || `<tr><td colspan="3" class="muted">데이터 없음</td></tr>`;
      } catch (e){
        alert('유사 카드 조회 실패: ' + e.message);
      }
    }

    // ====== 이름/번호 동시 입력 & 자동완성 ======
    const isNum = (v) => /^\d+$/.test(String(v||'').trim());
    function debounce(fn, ms){ let t; return (...a)=>{ clearTimeout(t); t=setTimeout(()=>fn(...a), ms); }; }

    async function searchCards(q){
      const res = await fetch(`${API}/search/cards?q=${encodeURIComponent(q)}`, {headers:{'Accept':'application/json'}});
      return res.ok ? res.json() : [];
    }
    async function searchMembers(q){
      const res = await fetch(`${API}/search/members?q=${encodeURIComponent(q)}`, {headers:{'Accept':'application/json'}});
      return res.ok ? res.json() : [];
    }
    function fillDatalist(el, items, type){
      el.innerHTML = items.map(it=>{
        if(type==='card'){
          const label = `${it.cardName||'(이름없음)'} #${it.cardNo}`;
          return `<option value="${label}" data-id="${it.cardNo}"></option>`;
        }else{
          const label = `${it.memberName||'(이름없음)'} #${it.memberNo}`;
          return `<option value="${label}" data-id="${it.memberNo}"></option>`;
        }
      }).join('');
    }
    function pickIdFromDatalist(inputEl, datalistEl){
      const val = inputEl.value.trim();
      const hash = /#(\d+)\s*$/.exec(val);
      if(hash) return hash[1];
      const opt = Array.from(datalistEl.options).find(o => o.value === val);
      return opt ? opt.getAttribute('data-id') : null;
    }
    async function resolveCardNo(){
      const input = document.getElementById('logCardKey');
      const list  = document.getElementById('cardHints');
      const raw   = (input.value||'').trim();
      if(!raw) return null;
      if(isNum(raw)) return raw;
      const picked = pickIdFromDatalist(input, list);
      if(picked) return picked;
      const results = await searchCards(raw);
      if(results.length === 1) return results[0].cardNo;
      return null;
    }
    async function resolveMemberNo(){
      const input = document.getElementById('logMemberKey');
      const list  = document.getElementById('memberHints');
      const raw   = (input.value||'').trim();
      if(!raw) return null;
      if(isNum(raw)) return raw;
      const picked = pickIdFromDatalist(input, list);
      if(picked) return picked;
      const results = await searchMembers(raw);
      if(results.length === 1) return results[0].memberNo;
      return null;
    }
    function bindTypeahead(){
      const $card   = document.getElementById('logCardKey');
      const $cardL  = document.getElementById('cardHints');
      const $member = document.getElementById('logMemberKey');
      const $memL   = document.getElementById('memberHints');

      $card.addEventListener('input', debounce(async (e)=>{
        const q = e.target.value.trim();
        if(!q || isNum(q)) { $cardL.innerHTML=''; return; }
        const items = await searchCards(q);
        fillDatalist($cardL, items, 'card');
      }, 200));

      $member.addEventListener('input', debounce(async (e)=>{
        const q = e.target.value.trim();
        if(!q || isNum(q)) { $memL.innerHTML=''; return; }
        const items = await searchMembers(q);
        fillDatalist($memL, items, 'member');
      }, 200));
    }

    // ====== 로그 테이블용 메타(카드/회원) 캐시 & 하이드레이션 ======
    const CardCache = new Map();   // cardNo -> {cardNo, cardName, cardImageUrl, cardProductUrl}
    const MemberCache = new Map(); // memberNo -> {memberNo, memberName}

    async function fetchCardMetaOne(id){
      const url = `${API}/cards/${id}`; // 단건 폴백 엔드포인트(없으면 404→무시)
      try{ const r = await jfetch(url); return r; }catch{ return null; }
    }
    async function fetchMemberMetaOne(id){
      const url = `${API}/members/${id}`; // 단건 폴백 엔드포인트(없으면 404→무시)
      try{ const r = await jfetch(url); return r; }catch{ return null; }
    }

    async function hydrateCardMeta(ids){
      const need = ids.filter(id => id && !CardCache.has(id));
      if(need.length === 0) return;

      // 1) 배치 시도
      try{
        const q = need.join(',');
        const arr = await jfetch(`${API}/cards/meta?ids=${encodeURIComponent(q)}`);
        if(Array.isArray(arr)){
          arr.forEach(x => { if(x?.cardNo) CardCache.set(String(x.cardNo), x); });
        }
      }catch{/* ignore */}

      // 2) 폴백: 단건 조회
      const still = need.filter(id => !CardCache.has(id));
      await Promise.all(still.map(async id=>{
        const meta = await fetchCardMetaOne(id);
        if(meta?.cardNo) CardCache.set(String(meta.cardNo), meta);
      }));
    }

    async function hydrateMemberMeta(ids){
      const need = ids.filter(id => id && !MemberCache.has(id));
      if(need.length === 0) return;

      // 1) 배치 시도
      try{
        const q = need.join(',');
        const arr = await jfetch(`${API}/members/meta?ids=${encodeURIComponent(q)}`);
        if(Array.isArray(arr)){
          arr.forEach(x => { if(x?.memberNo) MemberCache.set(String(x.memberNo), x); });
        }
      }catch{/* ignore */}

      // 2) 폴백: 단건 조회
      const still = need.filter(id => !MemberCache.has(id));
      await Promise.all(still.map(async id=>{
        const meta = await fetchMemberMetaOne(id);
        if(meta?.memberNo) MemberCache.set(String(meta.memberNo), meta);
      }));
    }

    function memberAvatarMarkup(name){
      const initial = (name||'').trim()[0] || '?';
      return `<div class="avatar" aria-hidden="true">${initial}</div>`;
    }

    function renderMemberCell(r){
      const meta = MemberCache.get(String(r.memberNo)) || {};
      const name = meta.memberName || '(이름없음)';
      const no   = r.memberNo ? `#${r.memberNo}` : '';
      return `
        <div class="memberwrap">
          ${memberAvatarMarkup(name)}
          <div>
            <div class="membername">${name}</div>
            <div class="memberno">${no}</div>
          </div>
        </div>
      `;
    }

    function renderCardCell(r){
      const meta = CardCache.get(String(r.cardNo)) || {};
      const src  = pickImageSrcFromRecord(meta);
      const img  = imgTag(src, meta.cardName || '카드');
      const name = meta.cardName || '(이름없음)';
      const no   = r.cardNo ? `#${r.cardNo}` : '';
      const a1 = meta.cardProductUrl ? `<a href="${meta.cardProductUrl}" target="_blank" style="text-decoration:none;color:inherit">` : '';
      const a2 = meta.cardProductUrl ? `</a>` : '';
      return `
        ${a1}
        <div class="cardcell">
          ${img}
          <div>
            <div class="cardname">${name}</div>
            <div class="cardno">${no}</div>
          </div>
        </div>
        ${a2}
      `;
    }

    // ====== 로그 ======
    let state = { page: 1, size: 20 };
    async function loadLogs(opt){
      try {
        if(opt && opt.delta){
          state.page = Math.max(1, state.page + opt.delta);
          document.getElementById('logPage').value = state.page;
        }else{
          state.page = parseInt(document.getElementById('logPage').value || '1', 10);
          state.size = parseInt(document.getElementById('logSize').value || '20', 10);
        }

        // 필터 파라미터
        const type = document.getElementById('logType').value;
        const from = document.getElementById('logFrom').value;
        const to   = document.getElementById('logTo').value;

        const memberNo = await resolveMemberNo();
        const cardNo   = await resolveCardNo();

        const p = new URLSearchParams();
        if(memberNo) p.set('memberNo', memberNo);
        if(cardNo)   p.set('cardNo', cardNo);
        if(type)     p.set('type', type);
        if(from)     p.set('from', from);
        if(to)       p.set('to', to);
        p.set('page', state.page);
        p.set('size', state.size);

        // 1) 로그 데이터 조회
        const rows = await jfetch(`${API}/logs?` + p.toString());

        // 2) 필요한 카드/회원 meta 미리 하이드레이트(캐시 채우기)
        const cardIds   = [...new Set((rows||[]).map(r=> String(r.cardNo||'')).filter(Boolean))];
        const memberIds = [...new Set((rows||[]).map(r=> String(r.memberNo||'')).filter(Boolean))];
        await Promise.all([hydrateCardMeta(cardIds), hydrateMemberMeta(memberIds)]);

        // 3) 렌더링(이미지/이름 포함)
        const tb = document.getElementById('logsTbody');
        tb.innerHTML = (rows||[]).map(r => `
          <tr>
            <td>${r.logNo ?? ''}</td>
            <td>${renderMemberCell(r)}</td>
            <td>${renderCardCell(r)}</td>
            <td>${r.behaviorType ?? ''}</td>
            <td>${(r.behaviorTime||'').toString().replace('T',' ').substring(0,19)}</td>
            <td>${r.deviceType ?? ''}</td>
            <td>${r.ipAddress ?? ''}</td>
            <td>${(r.userAgent||'').substring(0,120)}</td>
          </tr>
        `).join('') || `<tr><td colspan="8" class="muted">데이터 없음</td></tr>`;
      } catch (e){
        alert('로그 조회 실패: ' + e.message);
      }
    }

    // 이벤트
    document.getElementById('btnLoadKpi').addEventListener('click', loadKpi);
    document.getElementById('btnLoadPopular').addEventListener('click', loadPopular);
    document.getElementById('btnLoadSimilar').addEventListener('click', loadSimilar);
    document.getElementById('btnLoadLogs').addEventListener('click', () => loadLogs());
    document.getElementById('prevPage').addEventListener('click', () => loadLogs({delta:-1}));
    document.getElementById('nextPage').addEventListener('click', () => loadLogs({delta:+1}));

    // 초기 로드
    bindTypeahead();
    loadKpi();
    loadPopular();
  </script>
</body>
</html>
