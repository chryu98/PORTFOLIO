<%@ page contentType="text/html; charset=UTF-8" isELIgnored="true"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<title>관리자 리포트 (가입자/상품)</title>
<meta name="viewport" content="width=device-width,initial-scale=1" />

<style>
:root{
  --bg:#f5f7fb; --fg:#0f172a; --muted:#667085; --line:#e5e7eb; --accent:#0ea5e9; --card:#fff;
  --good:#16a34a; --warn:#f59e0b; --bad:#ef4444; --radius:14px; --shadow:0 6px 20px rgba(2,6,23,.06);
  --container:1200px; --pad:20px; --sidenav-w:260px; --sidenav-gap:24px;
}
.page-offset .container{max-width:var(--container);margin:0 auto;padding:0 var(--pad);}
*{box-sizing:border-box} html,body{height:100%}
body{margin:0;background:var(--bg);color:var(--fg);font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,"Apple SD Gothic Neo","Malgun Gothic",sans-serif;-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale;}
@media (min-width:1025px){.page-offset{padding-left:calc(var(--sidenav-w)+var(--sidenav-gap));}}
@media (max-width:768px){.page-offset{padding-left:0;}}
h1{margin:0;font-size:22px;font-weight:800;letter-spacing:-.01em;display:flex;align-items:center;gap:10px}
.controls{margin:10px auto 8px;display:flex;gap:10px;align-items:center;flex-wrap:wrap;background:linear-gradient(180deg,#fff,#fbfcff);border:1px solid var(--line);border-radius:12px;padding:10px 12px;box-shadow:var(--shadow);}
label{font-size:13px;color:var(--muted);display:flex;gap:8px;align-items:center}
input[type="date"]{height:36px;padding:8px 10px;border:1px solid var(--line);border-radius:10px;background:#fff}
button{height:36px;padding:0 14px;border-radius:10px;border:1px solid var(--line);background:#fff;cursor:pointer;transition:transform .15s ease,box-shadow .15s ease,background .15s ease;box-shadow:var(--shadow);}
button:hover{transform:translateY(-1px)} button:active{transform:translateY(0)}
button.primary{background:linear-gradient(180deg,#20b0f3,#0ea5e9);color:#fff;border-color:#0ea5e9;box-shadow:0 10px 24px rgba(14,165,233,.28);}
.app-main{padding:18px 0 24px;} .section{margin-top:18px;} .section h2{margin:0 0 10px 0;font-size:18px;letter-spacing:-.01em;}
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px}
.card{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);padding:14px;box-shadow:var(--shadow);}
.kpi{text-align:center}.kpi .label{color:var(--muted);font-size:12px}.kpi .value{font-size:24px;font-weight:800;margin-top:4px}
.muted{color:var(--muted);font-size:12px}.status{min-height:18px}.actions{display:flex;gap:8px;align-items:center;flex-wrap:wrap}.right{margin-left:auto}
.spark{width:100%;height:72px;background:#fff;border:1px solid var(--line);border-radius:var(--radius);display:block;}
.table-wrap{border:1px solid var(--line);border-radius:var(--radius);overflow:auto;background:#fff;box-shadow:var(--shadow);}
table.table{width:100%;border-collapse:separate;border-spacing:0;min-width:560px}
table.table th,table.table td{padding:12px 14px;font-size:13px;border-bottom:1px solid var(--line);white-space:nowrap;text-align:center;vertical-align:middle;}
table.table thead th{background:#f5f7fb;color:#1f2937;position:sticky;top:0;z-index:0;font-weight:700;}
table.table tbody tr:nth-child(odd){background:#fbfdff} table.table tbody tr:hover{background:#eef7ff}
table.table th.left,table.table td.left{text-align:left}
.table td.num{font-variant-numeric:tabular-nums;font-weight:700}
.table-wrap>table.table thead th:first-child{border-top-left-radius:var(--radius)}
.table-wrap>table.table thead th:last-child{border-top-right-radius:var(--radius)}
.table-wrap::-webkit-scrollbar{height:10px;width:10px}.table-wrap::-webkit-scrollbar-thumb{background:#cfe1f7;border-radius:999px}.table-wrap::-webkit-scrollbar-track{background:#f5f7fb}
.cell-card{display:flex;align-items:center;gap:10px}
.card-thumb{width:48px;height:30px;object-fit:contain;background:#fff;border:1px solid var(--line);border-radius:8px;flex:0 0 auto;}
.card-thumb.placeholder{background:linear-gradient(135deg,#f3f4f6,#e5e7eb);display:flex;align-items:center;justify-content:center;font-size:10px;color:#94a3b8;}
.card-meta{display:flex;flex-direction:column;line-height:1.2}.card-name{font-weight:700;font-size:13px}.card-no{font-size:12px}
.preview-backdrop{position:fixed;inset:0;background:rgba(2,6,23,.42);display:none;align-items:center;justify-content:center;z-index:9999;}
.preview-modal{background:#fff;width:min(1100px,96vw);height:min(80vh,900px);border-radius:14px;box-shadow:var(--shadow);display:flex;flex-direction:column;overflow:hidden;}
.preview-head{display:flex;align-items:center;gap:8px;padding:10px 12px;border-bottom:1px solid var(--line);}
.preview-title{font-weight:800;font-size:14px}.preview-body{flex:1;overflow:auto;background:#f8fafc;}
.preview-body iframe{width:100%;height:100%;border:0;background:#fff;}
.preview-body .inner{padding:16px}.preview-close{margin-left:auto;height:30px;padding:0 12px;border-radius:8px;}
@media (max-width:768px){:root{--container:100%} h1{font-size:20px} .kpi .value{font-size:20px} input[type="date"]{width:140px}}
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/adminstyle.css">

<!-- PDF 라이브러리 (글꼴 없이 이미지 방식으로 생성) -->
<script src="https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js" defer></script>
<script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js" defer></script>
<!-- ExcelJS (스타일 가능) -->
<script src="https://cdn.jsdelivr.net/npm/exceljs@4.4.0/dist/exceljs.min.js" defer></script>
</head>
<body>
  <!-- 상단 공용 헤더 -->
  <jsp:include page="../fragments/header.jsp"></jsp:include>

  <!-- 미리보기 모달 -->
  <div class="preview-backdrop" id="previewWrap" aria-hidden="true">
    <div class="preview-modal" role="dialog" aria-modal="true" aria-label="파일 미리보기">
      <div class="preview-head">
        <div class="preview-title" id="previewTitle">미리보기</div>
        <button class="preview-close" id="btnPreviewClose">닫기</button>
      </div>
      <div class="preview-body" id="previewBody"></div>
    </div>
  </div>

  <div class="page-offset">
    <div class="container">
      <h1>관리자 리포트</h1>

      <div class="controls">
        <label>시작일 <input id="start" type="date"></label>
        <label>종료일 <input id="end" type="date"></label>
        <button id="btnLoad" class="primary">조회</button>

        <!-- 전체 내보내기 버튼 -->
        <div class="right actions" style="margin-left:auto">
          <button id="btnPreviewAllPdf">전체 PDF 미리보기</button>
          <button id="btnDownloadAllPdf" class="primary">전체 PDF 다운로드</button>
          <button id="btnPreviewAllXlsx">전체 엑셀 미리보기</button>
          <button id="btnDownloadAllXlsx" class="primary">전체 엑셀 다운로드</button>
        </div>

        <div class="status muted" id="status"></div>
      </div>

      <div class="app-main" role="main">
        <div class="section">
          <h2>요약 KPI</h2>
          <div class="kpis" id="kpis"></div>
          <div class="muted">※ 조회 기간은 최대 31일까지 지원합니다.</div>
        </div>

        <div class="section">
          <div style="display:flex;align-items:center;gap:12px;">
            <h2 style="margin:0">가입자 현황 (인구통계)</h2>
          </div>
          <div class="card" style="margin-top:8px">
            <div class="muted">신규 신청 (나이대 × 성별)</div>
            <div id="tblDemoStarts" style="margin-top:6px"></div>
          </div>
          <div class="card" style="margin-top:12px">
            <div class="muted">발급 완료 (나이대 × 성별)</div>
            <div id="tblDemoIssued" style="margin-top:6px"></div>
          </div>
        </div>

        <div class="section">
          <h2>일별 추이</h2>
          <div class="card">
            <div class="muted">신규 신청 (일별)</div>
            <svg id="sparkNew" class="spark" viewBox="0 0 500 70" preserveAspectRatio="none"></svg>
          </div>
          <div class="card" style="margin-top:12px">
            <div class="muted">발급 완료 (일별)</div>
            <svg id="sparkIssued" class="spark" viewBox="0 0 500 70" preserveAspectRatio="none"></svg>
          </div>
        </div>

        <div class="section">
          <h2>상품판매 현황</h2>
          <div id="tblProducts" style="margin-top:8px"></div>
        </div>

        <div class="section">
          <h2>세부 분해</h2>
          <h3 class="muted" style="margin-top:8px">신용/체크별</h3>
          <div id="tblCreditKind"></div>
        </div>
      </div>
    </div>
  </div>

  <script src="<%=request.getContextPath()%>/js/adminHeader.js"></script>
  <script>
  // ================= 공통/유틸 =================
  const CTX  = '<%=request.getContextPath()%>';
  const BASE = CTX + '/admin/api/review-report';

  async function jget(url){
    const r = await fetch(url, {headers:{'Accept':'application/json'}});
    if(!r.ok) throw new Error('HTTP '+r.status+' '+url);
    return r.json();
  }
  function fmt(n){ if(n===null||n===undefined) return '-'; if(typeof n==='number') return n.toLocaleString(); return String(n); }
  function setStatus(msg){ document.getElementById('status').textContent = msg || ''; }
  function downloadBlob(filename, blob){
    const url = URL.createObjectURL(blob); const a = document.createElement('a');
    a.href = url; a.download = filename; a.click(); URL.revokeObjectURL(url);
  }
  function openIframePreview(title, blob){
    const url = URL.createObjectURL(blob);
    const wrap = document.getElementById('previewWrap'); const body = document.getElementById('previewBody'); const titleEl = document.getElementById('previewTitle');
    body.innerHTML = '<iframe src="'+url+'"></iframe>'; titleEl.textContent = title || '미리보기'; wrap.style.display = 'flex'; wrap.dataset.url = url;
  }
  function openHTMLPreview(title, html){
    const wrap = document.getElementById('previewWrap'); const body = document.getElementById('previewBody'); const titleEl = document.getElementById('previewTitle');
    body.innerHTML = '<div class="inner">'+html+'</div>'; titleEl.textContent = title || '미리보기'; wrap.style.display = 'flex'; wrap.dataset.url = '';
  }
  function closePreview(){
    const wrap = document.getElementById('previewWrap'); const url = wrap.dataset.url;
    if(url) URL.revokeObjectURL(url); document.getElementById('previewBody').innerHTML = ''; wrap.style.display='none'; wrap.dataset.url='';
  }

  // 컨텍스트 경로 + 이미지 URL 보정
  function resolveImg(u){
    if(!u) return '';
    if (u.startsWith('data:')) return u;
    if (/^https?:\/\//i.test(u)) return u; // 절대 URL
    if (u.startsWith('/')) return u;       // 서버 루트 기준
    return (CTX + '/' + u).replace(/\/+/g,'/'); // 상대경로 → 절대경로
  }
  // 외부 이미지는 서버 프록시로
  function toProxied(url){
    if(!url) return '';
    if (url.startsWith('data:')) return url;
    if (/^https?:\/\//i.test(url)) {
      return (CTX + '/admin/proxy-img?url=' + encodeURIComponent(url));
    }
    if (url.startsWith('/')) return url;
    return (CTX + '/' + url).replace(/\/+/g,'/');
  }

  // 다양한 키에서 이미지 추출
  function pickCardImg(r){
    const cand = r.cardImg || r.imageUrl || r.imgUrl || r.img || r.card_image || r.cardImgUrl;
    return resolveImg(cand);
  }

  // ===== jsPDF 로딩 대기 =====
  async function ensureJsPDFReady(maxWaitMs = 5000) {
    const start = performance.now();
    while (performance.now() - start < maxWaitMs) {
      if (window.jspdf && window.jspdf.jsPDF) return true;
      await new Promise(r => setTimeout(r, 50));
    }
    throw new Error('jsPDF가 아직 로드되지 않았습니다.');
  }

  // ================= 날짜 표준화(YYYY-MM-DD) =================
  function normDate(s){
    if(!s) return '';
    if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
    const d = new Date(s);
    if (isNaN(d)) return String(s);
    const p = n => String(n).padStart(2,'0');
    return d.getFullYear()+'-'+p(d.getMonth()+1)+'-'+p(d.getDate());
  }

  // ================= 데이터/표 렌더 =================
  function toKoGender(v){ const s=String(v||'').trim().toUpperCase(); if(s==='M')return'남자'; if(s==='F')return'여자'; return'미상'; }
  function toKoCredit(v){ const s=String(v||'').trim().toUpperCase(); if(s==='Y')return'신용카드'; if(s==='N')return'체크카드'; return'기타'; }

  function renderTable(elId, headers, rows){
    const el = document.getElementById(elId);
    if(!rows || rows.length===0){ el.innerHTML = `<div class="muted">데이터 없음</div>`; return; }
    const thead = `<thead><tr>${headers.map(h=>`<th class="${h.align||'center'}">${h.label}</th>`).join('')}</tr></thead>`;
    const tbody = `<tbody>${
      rows.map(r=>`<tr>${
        headers.map(h=>{
          const align = h.align||'center';
          if(typeof h.render==='function') return `<td class="${align}">${h.render(r)}</td>`;
          const isNum = typeof r[h.key] === 'number';
          return `<td class="${align}${isNum?' num':''}">${fmt(r[h.key])}</td>`;
        }).join('')
      }</tr>`).join('')
    }</tbody>`;
    el.innerHTML = `<div class="table-wrap"><table class="table">${thead}${tbody}</table></div>`;
  }

  // === 스파크라인 ===
  function renderSpark(svgId, series){
    const svg = document.getElementById(svgId);
    const w=500,h=70,pad=6;
    svg.setAttribute('viewBox',`0 0 ${w} ${h}`);
    svg.innerHTML='';
    const ns='http://www.w3.org/2000/svg';

    if(!series || series.length===0){
      svg.innerHTML = `<text x="8" y="40" font-size="12" fill="#9ca3af">데이터 없음</text>`;
      return;
    }

    const ys = series.map(d=>d.cnt||0);
    const max = Math.max(...ys,1);
    const dx = (w-2*pad)/Math.max(series.length-1,1);
    const toX = i => pad + i*dx;
    const toY = v => h - pad - (v/max)*(h-2*pad);

    const pts = series.map((d,i)=>`${toX(i)},${toY(d.cnt||0)}`).join(' ');
    const area = `M ${toX(0)} ${h-pad} L ${pts.replace(/ /g,' L ')} L ${toX(series.length-1)} ${h-pad} Z`;

    const g = document.createElementNS(ns,'g');

    const pathArea = document.createElementNS(ns,'path');
    pathArea.setAttribute('d', area);
    pathArea.setAttribute('fill', '#e0f2fe');

    const line = document.createElementNS(ns,'polyline');
    line.setAttribute('points', pts);
    line.setAttribute('fill','none');
    line.setAttribute('stroke', '#0ea5e9');
    line.setAttribute('stroke-width','2');

    g.appendChild(pathArea);
    g.appendChild(line);

    // 날짜 라벨
    const first = series[0]?.date || '';
    const last  = series[series.length-1]?.date || '';
    const mid   = series[Math.floor(series.length/2)]?.date || '';
    const labelY = h - 2;

    if (first){
      const t1 = document.createElementNS(ns,'text');
      t1.setAttribute('x', pad);
      t1.setAttribute('y', labelY);
      t1.setAttribute('font-size','10');
      t1.setAttribute('fill','#64748b');
      t1.setAttribute('text-anchor','start');
      t1.textContent = first;
      g.appendChild(t1);
    }
    if (mid && series.length > 2){
      const t2 = document.createElementNS(ns,'text');
      t2.setAttribute('x', w/2);
      t2.setAttribute('y', labelY);
      t2.setAttribute('font-size','10');
      t2.setAttribute('fill','#94a3b8');
      t2.setAttribute('text-anchor','middle');
      t2.textContent = mid;
      g.appendChild(t2);
    }
    if (last){
      const t3 = document.createElementNS(ns,'text');
      t3.setAttribute('x', w - pad);
      t3.setAttribute('y', labelY);
      t3.setAttribute('font-size','10');
      t3.setAttribute('fill','#64748b');
      t3.setAttribute('text-anchor','end');
      t3.textContent = last;
      g.appendChild(t3);
    }

    svg.appendChild(g);
  }

  // ================= 전역 캐시 =================
  let cacheKpi=null, cacheProducts=[], cacheCredit=[], cacheTrends=null;
  let cacheDemoStarts=[], cacheDemoIssued=[];
  let cacheProductsEnriched=[];

  // ================= 데이터 로드 =================
  async function loadAll(){
    try{
      setStatus('불러오는 중...');
      const start = document.getElementById('start').value;
      const end   = document.getElementById('end').value;
      const q = `startDt=${start}&endDt=${end}`;

      const [kpi, trends, products, breakdowns, demog] = await Promise.all([
        jget(`${BASE}/kpi?${q}`),
        jget(`${BASE}/trends?${q}`),
        jget(`${BASE}/products?${q}`),
        jget(`${BASE}/breakdowns?${q}`),
        jget(`${BASE}/demography?${q}`)
      ]);

      trends.newApps  = (trends?.newApps  || []).map(d => ({...d, date: normDate(d.date)}));
      trends.issued   = (trends?.issued   || []).map(d => ({...d, date: normDate(d.date)}));

      cacheKpi = kpi;
      cacheTrends = trends;
      cacheProducts = products || [];
      cacheCredit = (breakdowns && breakdowns.creditKind) || [];
      cacheDemoStarts = (demog && demog.starts) || [];
      cacheDemoIssued = (demog && demog.issued) || [];

      cacheProductsEnriched = cacheProducts.map(p => ({
        ...p,
        cardName: p.cardName || `#${p.cardNo}`,
        cardImg:  pickCardImg(p)
      }));

      const demoStartsKo = cacheDemoStarts.map(r => ({...r, gender: toKoGender(r.gender)}));
      const demoIssuedKo = cacheDemoIssued.map(r => ({...r, gender: toKoGender(r.gender)}));

      renderKpis(kpi);
      renderSpark('sparkNew',   trends.newApps || []);
      renderSpark('sparkIssued',trends.issued  || []);

      renderTable('tblDemoStarts', [
        {key:'ageBand', label:'나이대', align:'left'},
        {key:'gender',  label:'성별',   align:'left'},
        {key:'cnt',     label:'건수',   align:'right'}
      ], demoStartsKo);

      renderTable('tblDemoIssued', [
        {key:'ageBand', label:'나이대', align:'left'},
        {key:'gender',  label:'성별',   align:'left'},
        {key:'cnt',     label:'건수',   align:'right'}
      ], demoIssuedKo);

      renderTable('tblProducts', [
        {
          key:'cardNo', label:'카드', align:'left',
          render:(r)=>{
            const nm = r.cardName || `#${r.cardNo}`;
            const src = r.cardImg;
            const imgTag = src
              ? `<img class="card-thumb" loading="lazy"
                       src="${src}"
                       alt="${nm}"
                       referrerpolicy="no-referrer"
                       onerror="this.outerHTML='<div class=&quot;card-thumb placeholder&quot;>NO IMG</div>'">`
              : `<div class="card-thumb placeholder">NO IMG</div>`;
            return `
              <div class="cell-card">
                ${imgTag}
                <div class="card-meta">
                  <div class="card-name">${nm}</div>
                  <div class="card-no muted">#${r.cardNo}</div>
                </div>
              </div>`;
          }
        },
        {key:'starts', label:'신청', align:'right'},
        {key:'issued', label:'발급', align:'right'},
        {key:'conversionPct', label:'전환율(%)', align:'right'}
      ], cacheProductsEnriched);

      renderTable('tblCreditKind', [
        {label:'카드 유형', align:'left', render:(r)=>toKoCredit(r.isCreditCard)},
        {key:'starts', label:'신청', align:'right'},
        {key:'issued', label:'발급', align:'right'},
        {key:'conversionPct', label:'전환율(%)', align:'right'}
      ], cacheCredit);

      setStatus('완료');
    }catch(e){
      console.error(e); setStatus(''); alert('로딩 오류: '+e.message);
    }
  }

  function renderKpis(k){
    const el = document.getElementById('kpis');
    const convColor = (k.cohortConversionPct >= 50) ? 'var(--good)' : (k.cohortConversionPct >= 20) ? 'var(--warn)' : 'var(--bad)';
    el.innerHTML = `
      <div class="card kpi"><div class="label">신규 신청</div><div class="value">${fmt(k.newApps)}</div></div>
      <div class="card kpi"><div class="label">발급 완료</div><div class="value">${fmt(k.issuedApps)}</div></div>
      <div class="card kpi"><div class="label">현재 진행중</div><div class="value">${fmt(k.inProgress)}</div></div>
      <div class="card kpi"><div class="label">코호트 전환율</div><div class="value" style="color:${convColor}">${fmt(k.cohortConversionPct)}%</div></div>
      <div class="card kpi"><div class="label">평균 발급일</div><div class="value">${fmt(k.avgIssueDays)}일</div></div>`;
  }

  // ================== 내보내기용 데이터 정리 ==================
  function periodLabel(){ return `${document.getElementById('start').value} ~ ${document.getElementById('end').value}`; }
  function generatedAt(){ const d=new Date(); const p=n=>String(n).padStart(2,'0'); return `${d.getFullYear()}-${p(d.getMonth()+1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`; }

  function rowsKpi(){
    if(!cacheKpi) return [];
    return [
      {지표:'신규 신청', 값: cacheKpi.newApps ?? 0},
      {지표:'발급 완료', 값: cacheKpi.issuedApps ?? 0},
      {지표:'현재 진행중', 값: cacheKpi.inProgress ?? 0},
      {지표:'코호트 전환율(%)', 값: cacheKpi.cohortConversionPct ?? 0},
      {지표:'평균 발급일(일)', 값: cacheKpi.avgIssueDays ?? 0},
    ];
  }
  function rowsDemographyStarts(){
    return (cacheDemoStarts||[]).map(r=>({나이대:r.ageBand, 성별:toKoGender(r.gender), 건수:r.cnt||0}));
  }
  function rowsDemographyIssued(){
    return (cacheDemoIssued||[]).map(r=>({나이대:r.ageBand, 성별:toKoGender(r.gender), 건수:r.cnt||0}));
  }
  function rowsTrendsDaily(){
    const mapByDate = {};
    (cacheTrends?.newApps||[]).forEach(d=>{ const dd=normDate(d.date); mapByDate[dd]=mapByDate[dd]||{날짜:dd, 신규:0, 발급:0}; mapByDate[dd].신규=(d.cnt||0); });
    (cacheTrends?.issued ||[]).forEach(d=>{ const dd=normDate(d.date); mapByDate[dd]=mapByDate[dd]||{날짜:dd, 신규:0, 발급:0}; mapByDate[dd].발급=(d.cnt||0); });
    return Object.values(mapByDate).sort((a,b)=>a.날짜.localeCompare(b.날짜));
  }
  function rowsProducts(){
    const src = (cacheProductsEnriched.length?cacheProductsEnriched:cacheProducts) || [];
    return src.map(r=>({카드번호:r.cardNo, 카드명:(r.cardName||`#${r.cardNo}`), 신청:r.starts||0, 발급:r.issued||0, '전환율(%)':r.conversionPct||0, _이미지:r.cardImg||''}));
  }
  function rowsCreditKind(){
    return (cacheCredit||[]).map(r=>({유형:toKoCredit(r.isCreditCard), 신청:r.starts||0, 발급:r.issued||0, '전환율(%)':r.conversionPct||0}));
  }

  // ================== PDF 생성 (html2canvas → 이미지 분할) ==================
  async function inlineAllImages(root){
    const imgs = Array.from(root.querySelectorAll('img'));
    await Promise.all(imgs.map(async img=>{
      const src = img.getAttribute('src');
      if(!src || src.startsWith('data:')) return;
      try{
        const res = await fetch(src, {mode:'cors', credentials:'omit'});
        if(!res.ok) throw new Error('image fetch '+res.status);
        const blob = await res.blob();
        const dataUrl = await new Promise(r=>{
          const fr = new FileReader();
          fr.onload = ()=>r(fr.result);
          fr.readAsDataURL(blob);
        });
        img.setAttribute('src', dataUrl);
      }catch(e){
        img.outerHTML = '<div style="width:48px;height:30px;border:1px solid #e5e7eb;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:10px;color:#94a3b8">NO IMG</div>';
      }
    }));
  }

  async function buildAllPDFBlob(){
    await ensureJsPDFReady();
    const { jsPDF } = window.jspdf;

    const html = buildAllPreviewHTML();

    const temp = document.createElement('div');
    temp.id = 'pdfTemp';
    temp.style.position = 'fixed';
    temp.style.left = '-10000px';
    temp.style.top = '0';
    temp.style.width = '794px';
    temp.style.background = '#ffffff';

    const style = `
      #pdfTemp .table-wrap{overflow:visible;border:0;box-shadow:none;}
      #pdfTemp .card{box-shadow:none;border:1px solid #e5e7eb;border-radius:0;}
      #pdfTemp .kpi.card{border:1px solid #e5e7eb}
      #pdfTemp .muted{color:#334155}
      #pdfTemp table{border-collapse:collapse !important; width:100%;}
      #pdfTemp thead th{position:static !important; background:#f5f7fb !important;}
      #pdfTemp th,#pdfTemp td{border:1px solid #e5e7eb !important;}
      #pdfTemp .export-section{margin: 14px 0;}
      #pdfTemp h3{margin:16px 0 8px 0;}
      #pdfTemp .export-keep{page-break-inside: avoid;}
      /* PDF는 고정 크기 */
      #pdfTemp td img{display:block; width:60px; height:36px; object-fit:contain; border:1px solid #e5e7eb; border-radius:6px;}
    `;
    temp.innerHTML = `<style>${style}</style>${html}`;
    document.body.appendChild(temp);

    temp.querySelectorAll('img').forEach(img => {
      const s = img.getAttribute('src') || '';
      if (!s.startsWith('data:')) img.setAttribute('src', toProxied(s));
    });

    await inlineAllImages(temp);

    const canvas = await html2canvas(temp, { scale: 2, useCORS: true, backgroundColor:'#ffffff' });

    const pdf = new jsPDF('p','pt','a4');
    const pageW = pdf.internal.pageSize.getWidth();
    const pageH = pdf.internal.pageSize.getHeight();
    const margin = 20;
    const imgW = pageW - margin*2;
    const pxPerPage = Math.floor((pageH - margin*2) * canvas.width / imgW);
    const pageCanvas = document.createElement('canvas');
    const ctx = pageCanvas.getContext('2d');

    let y = 0;
    while (y < canvas.height) {
      const sliceH = Math.min(pxPerPage, canvas.height - y);
      pageCanvas.width = canvas.width;
      pageCanvas.height = sliceH;
      ctx.clearRect(0,0,pageCanvas.width,pageCanvas.height);
      ctx.drawImage(canvas, 0, y, canvas.width, sliceH, 0, 0, canvas.width, sliceH);

      const imgData = pageCanvas.toDataURL('image/jpeg', 0.95);
      const imgH = sliceH * imgW / canvas.width;

      pdf.addImage(imgData, 'JPEG', margin, margin, imgW, imgH);
      y += sliceH;
      if (y < canvas.height) pdf.addPage();
    }

    document.body.removeChild(temp);
    return pdf.output('blob');
  }

  // ================== 엑셀 생성 (ExcelJS) ==================
  async function buildAllXlsxBlob(){
    if(!window.ExcelJS){ alert('엑셀 라이브러리가 아직 로드되지 않았습니다.'); throw new Error('ExcelJS not ready'); }
    const wb = new ExcelJS.Workbook();
    wb.creator = 'Admin';
    wb.created = new Date();

    const addSheet = (name, rows, headerOrder) => {
      const ws = wb.addWorksheet(name, {properties:{defaultRowHeight:18}});
      const headers = headerOrder || (rows[0] ? Object.keys(rows[0]) : []);
      ws.columns = headers.map(h => ({ header: h, key: h, width: Math.max(10, String(h).length + 2) }));
      rows.forEach(r => ws.addRow(headers.map(h => r[h])));
      ws.getRow(1).eachCell(c=>{
        c.font = { bold:true };
        c.alignment = { vertical:'middle', horizontal:'center' };
        c.fill = { type:'pattern', pattern:'solid', fgColor:{argb:'FFF5F7FB'} };
        c.border = { top:{style:'thin',color:{argb:'FFE5E7EB'}}, left:{style:'thin',color:{argb:'FFE5E7EB'}}, bottom:{style:'thin',color:{argb:'FFE5E7EB'}}, right:{style:'thin',color:{argb:'FFE5E7EB'}} };
      });
      for(let r=2; r<=ws.rowCount; r++){
        ws.getRow(r).eachCell((c, idx)=>{
          const isNum = typeof c.value === 'number';
          c.alignment = { vertical:'middle', horizontal: isNum ? 'right' : (idx===1 ? 'center' : 'left') };
          c.border = { top:{style:'thin',color:{argb:'FFE5E7EB'}}, left:{style:'thin',color:{argb:'FFE5E7EB'}}, bottom:{style:'thin',color:{argb:'FFE5E7EB'}}, right:{style:'thin',color:{argb:'FFE5E7EB'}} };
        });
        if (r % 2 === 0) {
          ws.getRow(r).eachCell(c=>{
            c.fill = { type:'pattern', pattern:'solid', fgColor:{argb:'FFFBFDFF'} };
          });
        }
      }
      ws.columns.forEach(col => { col.width = Math.max(col.width, 12); });
      return ws;
    };

    addSheet('KPI', rowsKpi(), ['지표','값']);
    addSheet('Demography_New', rowsDemographyStarts(), ['나이대','성별','건수']);
    addSheet('Demography_Issued', rowsDemographyIssued(), ['나이대','성별','건수']);
    addSheet('Trends_Daily', rowsTrendsDaily(), ['날짜','신규','발급']);

    // 엑셀 파일 자체에는 이미지를 넣지 않음(표만)
    addSheet('Products', rowsProducts().map(({_이미지, ...rest})=>rest), ['카드번호','카드명','신청','발급','전환율(%)']);
    addSheet('CreditKind', rowsCreditKind(), ['유형','신청','발급','전환율(%)']);

    const meta = wb.addWorksheet('Meta');
    meta.columns = [{header:'항목', key:'항목', width:10},{header:'값', key:'값', width:30}];
    meta.addRow({항목:'기간', 값:periodLabel()});
    meta.addRow({항목:'생성', 값:generatedAt()});
    meta.getRow(1).eachCell(c=>{ c.font={bold:true}; c.alignment={horizontal:'center'}; c.fill={type:'pattern',pattern:'solid',fgColor:{argb:'FFF5F7FB'}}; });

    const buffer = await wb.xlsx.writeBuffer();
    return new Blob([buffer], {type:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'});
  }

  // ================== 미리보기(HTML) ==================
  function buildAllPreviewHTML(){
    const styleCell = 'padding:8px 10px;'; // 보더는 PDF 전용 스타일에서 통일
    const headCell  = styleCell + 'text-align:center;font-weight:700;background:#f5f7fb;';
    const td = (val, align) => `<td style="${styleCell}text-align:${align||'left'};">${val}</td>`;
    const th = (val) => `<th style="${headCell}">${val}</th>`;

    // 미리보기 전용 스타일: 60×36 고정
    const previewCSS = `
      <style>
        .preview-export td .card-img{
          display:block; width:60px; height:36px;
          object-fit:contain; border:1px solid #e5e7eb; border-radius:6px;
        }
        .preview-export td .noimg{
          width:60px; height:36px;
          border:1px solid #e5e7eb; border-radius:6px;
          display:flex; align-items:center; justify-content:center;
          font-size:10px; color:#94a3b8;
        }
      </style>
    `;

    const buildTable = (title, head, rows, renderRow) => {
      const thead = `<tr>${head.map(th).join('')}</tr>`;
      const tbody = rows.map(r => renderRow ? renderRow(r) : (
        `<tr>${
          head.map(h=>{
            const v = r[h];
            const align = (typeof v === 'number') ? 'right' : 'left';
            return td(fmt(v), align);
          }).join('')
        }</tr>`
      )).join('');
      return `
        <div class="export-section export-keep">
          <h3>${title}</h3>
          <div style="color:#667085;font-size:12px;margin:-4px 0 8px 0">기간: ${periodLabel()} · 생성: ${generatedAt()}</div>
          <div class="table-wrap">
            <table class="table">
              <thead>${thead}</thead><tbody>${tbody}</tbody>
            </table>
          </div>
        </div>`;
    };

    const productsRows = rowsProducts();
    const productsTable = buildTable(
      '상품판매 현황',
      ['이미지','카드번호','카드명','신청','발급','전환율(%)'],
      productsRows,
      (r)=>{
        const img = r._이미지
          ? `<img class="card-img" src="${toProxied(r._이미지)}" alt="${r.카드명}">`
          : `<div class="noimg">NO IMG</div>`;
        return `<tr>
          ${td(img)}
          ${td('#'+r.카드번호)}
          ${td(r.카드명)}
          ${td(fmt(r.신청),'right')}
          ${td(fmt(r.발급),'right')}
          ${td(fmt(r['전환율(%)']),'right')}
        </tr>`;
      }
    );

    return (
      previewCSS + `<div class="preview-export">` +
      buildTable('요약 KPI', ['지표','값'], rowsKpi()) +
      buildTable('가입자 현황 — 신규 신청', ['나이대','성별','건수'], rowsDemographyStarts()) +
      buildTable('가입자 현황 — 발급 완료', ['나이대','성별','건수'], rowsDemographyIssued()) +
      buildTable('일별 추이', ['날짜','신규','발급'], rowsTrendsDaily()) +
      productsTable +
      buildTable('세부 분해 — 신용/체크별', ['유형','신청','발급','전환율(%)'], rowsCreditKind()) +
      `</div>`
    );
  }

  // ================== 이벤트 ==================
  document.addEventListener('click', async (e)=>{
    if(e.target.id==='btnLoad'){ loadAll(); }

    if(e.target.id==='btnPreviewClose' || e.target.id==='previewWrap'){ closePreview(); }

    if(e.target.id==='btnPreviewAllPdf'){
      try{
        const blob = await buildAllPDFBlob();
        openIframePreview('전체 PDF 미리보기', blob);
      }catch(err){
        console.error(err);
        alert('PDF 미리보기 생성 실패:\n' + (err && err.message ? err.message : err));
      }
    }
    if(e.target.id==='btnDownloadAllPdf'){
      try{
        const blob = await buildAllPDFBlob();
        downloadBlob(`report_${periodLabel().replace(/\s+/g,'')}.pdf`, blob);
      }catch(err){
        console.error(err);
        alert('PDF 다운로드 생성 실패:\n' + (err && err.message ? err.message : err));
      }
    }
    if(e.target.id==='btnPreviewAllXlsx'){
      try{
        const html = buildAllPreviewHTML();
        openHTMLPreview('전체 엑셀 미리보기', html);
      }catch(err){
        console.error(err);
        alert('엑셀 미리보기 실패:\n' + (err && err.message ? err.message : err));
      }
    }
    if(e.target.id==='btnDownloadAllXlsx'){
      try{
        const blob = await buildAllXlsxBlob();
        downloadBlob(`report_${periodLabel().replace(/\s+/g,'')}.xlsx`, blob);
      }catch(err){
        console.error(err);
        alert('엑셀 다운로드 실패:\n' + (err && err.message ? err.message : err));
      }
    }
  });

  (function init(){
    const end = new Date(); const start = new Date(); start.setDate(end.getDate()-6);
    const toIso = d => new Date(d.getTime()-(d.getTimezoneOffset()*60000)).toISOString().slice(0,10);
    document.getElementById('start').value = toIso(start);
    document.getElementById('end').value   = toIso(end);

    document.getElementById('btnLoad').addEventListener('click', loadAll);
    document.getElementById('previewWrap').addEventListener('click', (evt)=>{ if(evt.target.id==='previewWrap') closePreview(); });

    loadAll();
  })();
  </script>
</body>
</html>
