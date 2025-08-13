<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>추천 상품 관리</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; margin: 24px; color:#222;}
    h1 { margin-bottom: 16px; }
    h2 { margin: 32px 0 12px; }
    .box { border:1px solid #e5e7eb; border-radius:12px; padding:16px; margin-bottom:18px; }
    .row { display:flex; gap:12px; flex-wrap:wrap; align-items:end; }
    label { font-size:12px; color:#666; display:block; margin-bottom:6px; }
    input, select, button { padding:8px 10px; border:1px solid #d1d5db; border-radius:8px; font-size:14px; }
    button { cursor:pointer; }
    table { width:100%; border-collapse:collapse; margin-top:10px; font-size:14px; }
    th, td { border-bottom:1px solid #eee; padding:8px 10px; text-align:left; vertical-align:top; }
    th { background:#fafafa; }
    .kpi { display:flex; gap:12px; flex-wrap:wrap; }
    .kpi .k { flex:1 1 160px; border:1px solid #e5e7eb; border-radius:10px; padding:12px; }
    .muted { color:#666; font-size:12px; }
    .right { text-align:right; }
    .controls { display:flex; gap:8px; align-items:center; }

    /* 카드 셀 UI */
    .cardcell{display:flex;align-items:center;gap:10px;min-width:240px}
    .thumb{width:48px;height:30px;border-radius:6px;object-fit:cover;background:#f2f2f2;border:1px solid #eee}
    .cardname{font-weight:600}
    .cardno{color:#666;font-size:12px}
  </style>
</head>
<body>
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
    <div class="kpi" id="kpiWrap">
      <!-- 동적 -->
    </div>
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
      <tbody id="popularTbody">
        <!-- 동적 -->
      </tbody>
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
      <tbody id="similarTbody">
        <!-- 동적 -->
      </tbody>
    </table>
  </div>

  <!-- 로그 -->
  <div class="box">
    <h2>행동 로그</h2>
    <div class="row">
      <div>
        <label>회원번호</label>
        <input type="number" id="logMemberNo" />
      </div>
      <div>
        <label>카드번호</label>
        <input type="number" id="logCardNo" />
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
          <th>MEMBER_NO</th>
          <th>CARD_NO</th>
          <th>TYPE</th>
          <th>TIME</th>
          <th>DEVICE</th>
          <th>IP</th>
          <th>USER_AGENT</th>
        </tr>
      </thead>
      <tbody id="logsTbody">
        <!-- 동적 -->
      </tbody>
    </table>
    <div class="row" style="justify-content:flex-end; margin-top:10px;">
      <button id="prevPage">이전</button>
      <button id="nextPage">다음</button>
    </div>
  </div>

  <script>
    const ctx = '<%= request.getContextPath() %>';
    const API = ctx + '/admin/reco';

    // 숫자/비율 포맷
    const fmt = (n) => n == null ? '-' : Number(n).toLocaleString();
    const pct = (n) => (n == null ? '-' : (Number(n) * 100).toFixed(1) + '%');
    const cut10 = (s) => (s ? String(s).substring(0,10) : '');

    // === 이미지 보강 유틸 시작 ===

    // 심플 placeholder (에러시 표시)
    const PH = "data:image/svg+xml;utf8,\
<svg xmlns='http://www.w3.org/2000/svg' width='96' height='60'>\
<rect width='100%' height='100%' fill='%23f2f2f2'/>\
<text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' fill='%23999' font-size='12'>no image</text>\
</svg>";

    // URL이 이미지로 보이는지 간단 판별
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

    // HTTPS 페이지에서 HTTP 이미지면 https로 바꿔 시도(서버가 지원해야 성공)
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

    // 레코드에서 사용하는 대표 이미지 고르기: cardImageUrl -> (없으면) cardProductUrl(이미지일 때만)
    function pickImageSrcFromRecord(r){
      const first = r?.cardImageUrl;
      const fallback = isImageUrl(r?.cardProductUrl) ? r.cardProductUrl : null;
      return normalizeUrl(first || fallback);
    }
    // otherCard용
    function pickOtherImageSrcFromRecord(r){
      const first = r?.otherCardImageUrl;
      const fallback = isImageUrl(r?.otherCardProductUrl) ? r.otherCardProductUrl : null;
      return normalizeUrl(first || fallback);
    }

    // 공통 <img> 태그 생성 (리퍼러 제거 + 오류시 placeholder)
    function imgTag(src, altText){
      return src
        ? `<img class="thumb" src="${src}" alt="${altText || ''}" referrerpolicy="no-referrer" loading="lazy"
                 decoding="async" onerror="this.onerror=null; this.src='${PH}'">`
        : `<div class="thumb" role="img" aria-label="no image"></div>`;
    }
    // === 이미지 보강 유틸 끝 ===

    // 공통 fetch 헬퍼 (에러 핸들링)
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

    const isNumber = /^\d+$/.test(key);
    const url = `${API}/similar/${encodeURIComponent(key)}?days=${days}&limit=${limit}`;

    const data = await jfetch(url);

    const tb = document.getElementById('similarTbody');
    tb.innerHTML = (data||[]).map(r => {
      const bImg = imgTag(pickImageSrcFromRecord(r), r.cardName || '기준 카드');
      const bName = r.cardName || '(이름없음)';
      const bNum  = r.cardNo ? `#${r.cardNo}` : '';
      const b1 = r.cardProductUrl ? `<a href="${r.cardProductUrl}" target="_blank" style="text-decoration:none;color:inherit">` : '';
      const b2 = r.cardProductUrl ? `</a>` : '';

      const sImg = imgTag(pickOtherImageSrcFromRecord(r), r.otherCardName || '유사 카드');
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


    // 로그
    let state = { page: 1, size: 20 };
    async function loadLogs(opt){
      try {
        const memberNo = document.getElementById('logMemberNo').value;
        const cardNo   = document.getElementById('logCardNo').value;
        const type     = document.getElementById('logType').value;
        const from     = document.getElementById('logFrom').value;
        const to       = document.getElementById('logTo').value;

        if(opt && opt.delta){
          state.page = Math.max(1, state.page + opt.delta);
          document.getElementById('logPage').value = state.page;
        }else{
          state.page = parseInt(document.getElementById('logPage').value || '1', 10);
          state.size = parseInt(document.getElementById('logSize').value || '20', 10);
        }

        const p = new URLSearchParams();
        if(memberNo) p.set('memberNo', memberNo);
        if(cardNo)   p.set('cardNo', cardNo);
        if(type)     p.set('type', type);
        if(from)     p.set('from', from);
        if(to)       p.set('to', to);
        p.set('page', state.page);
        p.set('size', state.size);

        const data = await jfetch(`${API}/logs?` + p.toString());
        const tb = document.getElementById('logsTbody');
        tb.innerHTML = (data||[]).map(r => `
          <tr>
            <td>${r.logNo ?? ''}</td>
            <td>${r.memberNo ?? ''}</td>
            <td>${r.cardNo ?? ''}</td>
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
    loadKpi();
    loadPopular();
  </script>
</body>
</html>
