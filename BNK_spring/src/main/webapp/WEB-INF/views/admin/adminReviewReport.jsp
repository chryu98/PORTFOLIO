<%@ page contentType="text/html; charset=UTF-8" isELIgnored="true"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<title>관리자 리포트 (가입자/상품)</title>
<meta name="viewport" content="width=device-width,initial-scale=1" />

<style>
/* =========================
   대시보드 공통 팔레트 (영업점 관리 톤)
   ========================= */
:root{
  --bg:#fff;
  --txt:#111;
  --muted:#808089;
  --line:#ececec;
  --card:#f8f9fb;
  --pill:#eef1f7;
  --good:#28a745;
  --bad:#dc3545;
  --neutral:#6c757d;
  --accent:#3b82f6;
  --shadow:0 6px 18px rgba(17,24,39,.06);
  --ring:0 0 0 3px rgba(59,130,246,.18);
  --container:1080px;
  --pad:20px;
  --radius:12px;
}

/* 기본 */
html,body{ height:100% }
body{
  margin:0;
  background:var(--bg);
  color:var(--txt);
  font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, "Apple SD Gothic Neo", "Malgun Gothic", sans-serif;
  -webkit-font-smoothing:antialiased; -moz-osx-font-smoothing:grayscale;
}

.page-offset .container{ max-width:var(--container); margin:0 auto; padding:0 var(--pad); }
@media (min-width:1025px){ .page-offset{ padding-left:20px } } /* 좌측 사이드오프셋이 있다면 여유 */
@media (max-width:768px){ .page-offset{ padding-left:0 } }

h1{
  margin:0 0 12px;
  font-size:28px;
  font-weight:700;
  letter-spacing:-.01em;
  display:flex; align-items:center; gap:10px;
  padding-top: 40px;
}

/* 컨트롤 바 (영업점 ‘filters’ 톤) */
.controls{
  margin:10px 0 8px;
  display:flex; gap:10px; align-items:center; flex-wrap:wrap;
  background:var(--card);
  border:1px solid var(--line);
  border-radius:var(--radius);
  padding:10px 12px;
  box-shadow:var(--shadow);
}
label{ font-size:13px; color:var(--muted); display:flex; gap:8px; align-items:center }
input[type="date"]{
  height:38px; padding:0 10px;
  border:1px solid var(--line); border-radius:8px; background:#fff; outline:none;
}
input[type="date"]:focus{ box-shadow:var(--ring); border-color:var(--accent) }

/* 버튼을 영업점 관리의 .btn 룩으로 */
button{
  height:38px; padding:0 12px;
  border:1px solid var(--line); border-radius:8px;
  background:#fff; color:var(--txt);
  cursor:pointer; transition:.15s ease; box-shadow:var(--shadow);
}
button:hover{ transform:translateY(-1px) }
button:focus-visible{ outline:none; box-shadow:var(--ring) }
button.primary{
  background:var(--accent); color:#fff; border-color:var(--accent); min-width:108px;
}
.actions{ display:flex; gap:8px; align-items:center; flex-wrap:wrap }
.right{ margin-left:auto }
.status{ min-height:18px; color:var(--muted); font-size:12px }

/* 섹션 / 카드 / KPI */
.app-main{ padding:18px 0 24px; }
.section{ margin-top:18px; }
.section h2{ margin:0 0 10px; font-size:18px; letter-spacing:-.01em; }

.card{
  background:#fff; border:1px solid var(--line); border-radius:var(--radius);
  padding:14px; box-shadow:var(--shadow);
}
.kpis{ display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:12px }
.kpi{ text-align:center }
.kpi .label{ color:var(--muted); font-size:12px }
.kpi .value{ font-size:24px; font-weight:800; margin-top:4px }

/* 표 (영업점 관리 테이블 톤) */
.table-wrap{
  border:1px solid var(--line); border-radius:var(--radius);
  overflow:auto; background:#fff; box-shadow:var(--shadow);
}
table.table{
  width:100%; border-collapse:separate; border-spacing:0; min-width:560px;
}
table.table thead th{
  background:#fafbfc; color:var(--txt);
  font-weight:700; text-align:left;
  border-bottom:1px solid var(--line);
  padding:12px 14px;
}
table.table td{
  padding:12px 14px; border-bottom:1px solid var(--line);
  vertical-align:middle; color:var(--txt);
  text-align:left; white-space:nowrap;
}
table.table tbody tr:hover{ background:#fdfefe }
.table td.num{ font-variant-numeric:tabular-nums; font-weight:700 }
.table-wrap>table.table thead th:first-child{ border-top-left-radius:var(--radius) }
.table-wrap>table.table thead th:last-child{ border-top-right-radius:var(--radius) }

/* 카드 셀 */
.cell-card{ display:flex; align-items:center; gap:10px }
.card-thumb{
  width:48px; height:30px; object-fit:contain; background:#fff;
  border:1px solid var(--line); border-radius:8px; flex:0 0 auto;
}
.card-thumb.placeholder{
  background:linear-gradient(135deg,#f3f4f6,#e5e7eb);
  display:flex; align-items:center; justify-content:center;
  font-size:10px; color:#94a3b8;
}
.card-meta{ display:flex; flex-direction:column; line-height:1.2 }
.card-name{ font-weight:700; font-size:13px }
.card-no{ font-size:12px; color:var(--muted) }

/* 미리보기 모달 */
.preview-backdrop{
  position:fixed; inset:0; background:rgba(17,24,39,.42);
  display:none; align-items:center; justify-content:center; z-index:9999;
}
.preview-modal{
  background:#fff; width:min(1100px,96vw); height:min(80vh,900px);
  border-radius:14px; box-shadow:var(--shadow);
  display:flex; flex-direction:column; overflow:hidden;
}
.preview-head{
  display:flex; align-items:center; gap:8px;
  padding:10px 12px; border-bottom:1px solid var(--line); background:var(--card);
}
.preview-title{ font-weight:800; font-size:14px }
.preview-body{ flex:1; overflow:auto; background:#fff; }
.preview-body iframe{ width:100%; height:100%; border:0; background:#fff; }
.preview-body .inner{ padding:16px }
.preview-close{ margin-left:auto; height:32px; }

/* 반응형 */
@media (max-width:768px){
  :root{ --container:100% }
  h1{ font-size:22px }
  .kpi .value{ font-size:20px }
  input[type="date"]{ width:140px }
}
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/adminstyle.css">
<!-- PDF / Excel -->
<script src="https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js" defer></script>
<script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js" defer></script>
<script src="https://cdn.jsdelivr.net/npm/exceljs@4.4.0/dist/exceljs.min.js" defer></script>
</head>
<body>
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

        <div class="right actions" style="margin-left:auto">
          <button id="btnPreviewAllPdf">전체 PDF 미리보기</button>
          <button id="btnDownloadAllPdf" class="primary">전체 PDF 다운로드</button>
          <button id="btnPreviewAllXlsx">전체 엑셀 미리보기</button>
          <button id="btnDownloadAllXlsx" class="primary">전체 엑셀 다운로드</button>
        </div>

        <div class="status" id="status"></div>
      </div>

      <div class="app-main" role="main">
        <!-- 요약 -->
        <div class="section">
          <h2>요약</h2>
          <div class="kpis" id="kpis"></div>
          <div class="muted">※ 조회 기간은 최대 31일까지 지원합니다.</div>
        </div>

        <!-- 카드별 통합 -->
        <div class="section">
          <div style="display:flex;align-items:center;gap:12px;">
            <h2 style="margin:0">카드별 통합 현황 (작성 단계 × 발급 완료)</h2>
            <div class="muted">작성 단계 / 발급 완료</div>
          </div>
          <div id="tblCardSummary" style="margin-top:8px"></div>
        </div>

        <!-- 가입자 인구통계 -->
        <div class="section">
          <div style="display:flex;align-items:center;gap:12px;">
            <h2 style="margin:0">가입자 현황 (인구통계)</h2>
          </div>
          <div class="card" style="margin-top:8px">
            <div class="muted">신청서 작성 — 나이대 × 성별</div>
            <div id="tblDemoStarts" style="margin-top:6px"></div>
          </div>
          <div class="card" style="margin-top:12px">
            <div class="muted">발급 완료 — 나이대 × 성별</div>
            <div id="tblDemoIssued" style="margin-top:6px"></div>
          </div>
        </div>

        <!-- 상품판매 현황 -->
        <div class="section">
          <h2>상품판매 현황</h2>
          <div id="tblProducts" style="margin-top:8px"></div>
        </div>
      </div>
    </div>
  </div>

  <script src="<%=request.getContextPath()%>/js/adminHeader.js"></script>
  <!-- 아래 JS 로직은 기존 코드 그대로 두세요 -->
  <script>
  const CTX  = '<%=request.getContextPath()%>';
  const BASE = CTX + '/admin/api/review-report';

  async function jget(url){ const r=await fetch(url,{headers:{'Accept':'application/json'}}); if(!r.ok) throw new Error('HTTP '+r.status); return r.json(); }
  function fmt(n){ if(n===null||n===undefined) return '-'; if(typeof n==='number') return n.toLocaleString(); return String(n); }
  function setStatus(msg){ document.getElementById('status').textContent = msg || ''; }
  function downloadBlob(filename, blob){ const url=URL.createObjectURL(blob); const a=document.createElement('a'); a.href=url; a.download=filename; a.click(); URL.revokeObjectURL(url); }
  function openIframePreview(title, blob){ const url=URL.createObjectURL(blob); const wrap=document.getElementById('previewWrap'); document.getElementById('previewBody').innerHTML='<iframe src="'+url+'"></iframe>'; document.getElementById('previewTitle').textContent=title||'미리보기'; wrap.style.display='flex'; wrap.dataset.url=url; }
  function openHTMLPreview(title, html){ const wrap=document.getElementById('previewWrap'); document.getElementById('previewBody').innerHTML='<div class="inner">'+html+'</div>'; document.getElementById('previewTitle').textContent=title||'미리보기'; wrap.style.display='flex'; wrap.dataset.url=''; }
  function closePreview(){ const wrap=document.getElementById('previewWrap'); const url=wrap.dataset.url; if(url) URL.revokeObjectURL(url); document.getElementById('previewBody').innerHTML=''; wrap.style.display='none'; wrap.dataset.url=''; }

  function resolveImg(u){ if(!u) return ''; if(u.startsWith('data:')) return u; if(/^https?:\/\//i.test(u)) return u; if(u.startsWith('/')) return u; return (CTX+'/'+u).replace(/\/+/g,'/'); }
  function toProxied(url){
    if(!url) return '';
    if(url.startsWith('data:')) return url;
    if(/^https?:\/\//i.test(url)) return (CTX + '/admin/api/proxy-img?url=' + encodeURIComponent(url));
    if(url.startsWith('/')) return url;
    return (CTX+'/'+url).replace(/\/+/g,'/');
  }
  function toKoGender(v){ const s=String(v||'').trim().toUpperCase(); if(s==='M')return'남자'; if(s==='F')return'여자'; return'미상'; }
  function toKoCredit(v){ const s=String(v||'').trim().toUpperCase(); if(s==='Y')return'신용카드'; if(s==='N')return'체크카드'; return'-'; }

  function renderTable(elId, headers, rows){
    const el=document.getElementById(elId);
    if(!rows||rows.length===0){ el.innerHTML='<div class="muted">데이터 없음</div>'; return; }
    const thead='<thead><tr>'+headers.map(h=>`<th class="${h.align||'left'}">${h.label}</th>`).join('')+'</tr></thead>';
    const tbody='<tbody>'+rows.map(r=>'<tr>'+headers.map(h=>{
      const align=h.align||'left';
      if(typeof h.render==='function') return `<td class="${align}">${h.render(r)}</td>`;
      const isNum=typeof r[h.key]==='number';
      return `<td class="${align}${isNum?' num':''}">${fmt(r[h.key])}</td>`;
    }).join('')+'</tr>').join('')+'</tbody>';
    el.innerHTML=`<div class="table-wrap"><table class="table">${thead}${tbody}</table></div>`;
  }

  // 캐시
  let cacheSummary=null, cacheProducts=[], cacheDemoStarts=[], cacheDemoIssued=[];
  let cacheProductsEnriched=[], cacheCardSummary=[], cacheCardDemo=[];
  let imgByCardNo = {};

  async function loadAll(){
    try{
      setStatus('불러오는 중...');
      const start=document.getElementById('start').value;
      const end=document.getElementById('end').value;
      const q=`startDt=${start}&endDt=${end}`;

      const [summary, products, demog, combined, cardDemo] = await Promise.all([
        jget(`${BASE}/summary?${q}`),
        jget(`${BASE}/products?${q}`),
        jget(`${BASE}/demography?${q}`),
        jget(`${BASE}/combined?${q}`),
        jget(`${BASE}/cards/demography?${q}`)
      ]);

      cacheSummary=summary;
      cacheProducts=products||[];
      cacheDemoStarts=(demog&&demog.starts)||[];
      cacheDemoIssued=(demog&&demog.issued)||[];
      cacheCardDemo = cardDemo || [];

      cacheProductsEnriched=cacheProducts.map(p=>({
        ...p,
        cardName: p.cardName||`#${p.cardNo}`,
        cardImg:  (p.cardImg||p.imageUrl||''),
        isCreditCard: p.isCreditCard
      }));
      cacheCardSummary=(combined||[]).map(r=>({
        ...r,
        cardName:r.cardName||`#${r.cardNo}`,
        cardImg:(r.cardImg||r.imageUrl||'')
      }));

      imgByCardNo = {};
      cacheProductsEnriched.forEach(p=>{ if(p.cardNo!=null) imgByCardNo[p.cardNo]=p.cardImg||imgByCardNo[p.cardNo]||''; });
      cacheCardSummary.forEach(c=>{ if(c.cardNo!=null) imgByCardNo[c.cardNo]=imgByCardNo[c.cardNo]||c.cardImg||''; });

      renderSummary(cacheSummary);
      renderCardSummaryTable(cacheCardSummary);

      const demoStartsKo=cacheDemoStarts.map(r=>({...r, genderCode:r.gender, gender: toKoGender(r.gender)}));
      const demoIssuedKo=cacheDemoIssued.map(r=>({...r, genderCode:r.gender, gender: toKoGender(r.gender)}));

      renderDemoStarts(demoStartsKo);
      renderDemoIssued(demoIssuedKo);

      renderTable('tblProducts', [
        { key:'cardNo', label:'카드', align:'left',
          render:(r)=>{
            const nm=r.cardName||`#${r.cardNo}`;
            const src=r.cardImg;
            const imgTag= src ? `<img class="card-thumb" loading="lazy" src="${src}" alt="${nm}" referrerpolicy="no-referrer"
                                onerror="this.outerHTML='<div class=&quot;card-thumb placeholder&quot;>NO IMG</div>'">`
                               : `<div class="card-thumb placeholder">NO IMG</div>`;
            return `<div class="cell-card">${imgTag}<div class="card-meta"><div class="card-name">${nm}</div><div class="card-no">#${r.cardNo}</div></div></div>`;
        }},
        {key:'isCreditCard', label:'유형', align:'left', render:(r)=>toKoCredit(r.isCreditCard)},
        {key:'starts', label:'신청서 작성', align:'right'},
        {key:'issued', label:'발급 완료', align:'right'},
        {key:'conversionPct', label:'발급 전환율(%)', align:'right'}
      ], cacheProductsEnriched);

      setStatus('완료');
    }catch(e){ console.error(e); setStatus(''); alert('로딩 오류: '+e.message); }
  }

  function renderSummary(k){
    const inflow    = k?.tempInflow ?? 0;
    const confirmed = k?.finalConfirmed ?? 0;
    let convPct = (typeof k?.cohortConversionPct === 'number') ? k.cohortConversionPct : NaN;
    if (!isFinite(convPct) || convPct <= 0) convPct = (inflow > 0) ? Math.round((confirmed * 1000) / inflow) / 10 : 0;
    const convColor = convPct>=50?'var(--good)':convPct>=20?'#f59e0b':'var(--bad)';

    document.getElementById('kpis').innerHTML = `
      <div class="card kpi"><div class="label">신청서 작성</div><div class="value">${fmt(inflow)}</div></div>
      <div class="card kpi"><div class="label">발급 완료</div><div class="value">${fmt(confirmed)}</div></div>
      <div class="card kpi"><div class="label">발급 전환율</div><div class="value" style="color:${convColor}">${fmt(convPct)}%</div></div>`;
  }

  function renderCardSummaryTable(rows){
    renderTable('tblCardSummary', [
      { key:'cardNo', label:'카드', align:'left', render:(r)=>{
          const nm=r.cardName||`#${r.cardNo}`; const src=r.cardImg?resolveImg(r.cardImg):'';
          const imgTag= src? `<img class="card-thumb" loading="lazy" src="${src}" alt="${nm}" referrerpolicy="no-referrer"
                               onerror="this.outerHTML='<div class=&quot;card-thumb placeholder&quot;>NO IMG</div>'">`
                            : `<div class="card-thumb placeholder">NO IMG</div>`;
          return `<div class="cell-card">${imgTag}<div class="card-meta"><div class="card-name">${nm}</div><div class="card-no">#${r.cardNo}</div></div></div>`;
      }},
      { key:'startsTemp',    label:'신청서 작성',    align:'right' },
      { key:'confirmed',     label:'발급 완료',      align:'right' },
      { key:'conversionPct', label:'발급 전환율(%)', align:'right' }
    ], rows);
  }

  function renderDemoStarts(rows){
    const headers = [
      {key:'ageBand', label:'나이대', align:'left'},
      {key:'gender',  label:'성별',   align:'left'},
      {key:'cnt',     label:'건수(작성)', align:'right'},
      {key:'more',    label:'', align:'left',
        render:(r)=>`<button data-seg="S|${r.ageBand}|${r.genderCode}">자세히</button>`}
    ];
    renderTable('tblDemoStarts', headers, rows);
  }
  function renderDemoIssued(rows){
    const headers = [
      {key:'ageBand', label:'나이대', align:'left'},
      {key:'gender',  label:'성별',   align:'left'},
      {key:'cnt',     label:'건수(발급)', align:'right'},
      {key:'more',    label:'', align:'left',
        render:(r)=>`<button data-seg="I|${r.ageBand}|${r.genderCode}">자세히</button>`}
    ];
    renderTable('tblDemoIssued', headers, rows);
  }

  function periodLabel(){ return `${document.getElementById('start').value} ~ ${document.getElementById('end').value}`; }
  function generatedAt(){ const d=new Date(); const p=n=>String(n).padStart(2,'0'); return `${d.getFullYear()}-${p(d.getMonth()+1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`; }

  function rowsSummary(){
    if(!cacheSummary) return [];
    const inflow=cacheSummary.tempInflow??0;
    const confirmed=cacheSummary.finalConfirmed??0;
    const conv=(inflow>0?Math.round(confirmed*1000/inflow)/10:0);
    return [
      {지표:'신청서 작성', 값:inflow},
      {지표:'발급 완료',   값:confirmed},
      {지표:'발급 전환율(%)', 값:conv}
    ];
  }
  function rowsDemographyStarts(){ return (cacheDemoStarts||[]).map(r=>({나이대:r.ageBand,성별:toKoGender(r.gender),건수:r.cnt||0})); }
  function rowsDemographyIssued(){ return (cacheDemoIssued||[]).map(r=>({나이대:r.ageBand,성별:toKoGender(r.gender),건수:r.cnt||0})); }
  function rowsProducts(){
    const src=(cacheProductsEnriched.length?cacheProductsEnriched:cacheProducts)||[];
    return src.map(r=>({
      카드번호:r.cardNo,
      카드명:(r.cardName||`#${r.cardNo}`),
      유형:toKoCredit(r.isCreditCard),
      '신청서 작성':r.starts||0,
      '발급 완료':r.issued||0,
      '발급 전환율(%)':r.conversionPct||0,
      _이미지:r.cardImg||''
    }));
  }
  function rowsCardSummary(){
    return (cacheCardSummary||[]).map(r=>{
      const img = r.cardImg || imgByCardNo[r.cardNo] || '';
      return {
        카드번호: r.cardNo,
        카드명: r.cardName,
        '신청서 작성': r.startsTemp || 0,
        '발급 완료': r.confirmed || 0,
        '발급 전환율(%)': r.conversionPct || 0,
        _이미지: img
      };
    });
  }

  async function inlineAllImages(root){
    const imgs = [...root.querySelectorAll('img')];
    await Promise.all(imgs.map(async img=>{
      const src = img.getAttribute('src');
      if(!src || src.startsWith('data:')) return;
      try{
        const res = await fetch(src,{credentials:'include',mode:'same-origin',headers:{'X-Requested-With':'XMLHttpRequest'}});
        if(!res.ok) throw new Error('image fetch '+res.status);
        const blob = await res.blob();
        const dataUrl = await new Promise(r=>{ const fr=new FileReader(); fr.onload=()=>r(fr.result); fr.readAsDataURL(blob); });
        img.setAttribute('src', dataUrl);
      }catch(e){
        img.outerHTML = '<div style="width:60px;height:36px;border:1px solid var(--line);border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:10px;color:#94a3b8">NO IMG</div>';
      }
    }));
  }
  async function waitAllImgsLoaded(root){
    const imgs = [...root.querySelectorAll('img')];
    await Promise.all(imgs.map(img=>{
      if (img.complete) return;
      return new Promise(res=>{ img.onload = img.onerror = res; });
    }));
  }

  function buildAllPreviewHTML(){
    const styleCell='padding:8px 10px;', headCell=styleCell+'text-align:left;font-weight:700;background:#fafbfc;';
    const td=(v,align)=>`<td style="${styleCell}text-align:${align||'left'};border-bottom:1px solid #ececec;">${v}</td>`;
    const th=v=>`<th style="${headCell}border-bottom:1px solid #ececec;">${v}</th>`;
    const previewCSS=`<style>.preview-export td .card-img{display:block;width:60px;height:36px;object-fit:contain;border:1px solid #ececec;border-radius:8px}.preview-export td .noimg{width:60px;height:36px;border:1px solid #ececec;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:10px;color:#94a3b8}</style>`;
    const buildTable=(title, head, rows, renderRow)=>{
      const thead=`<tr>${head.map(th).join('')}</tr>`;
      const tbody=rows.map(r=>renderRow?renderRow(r):(`<tr>${head.map(h=>{const v=r[h]; const align=(typeof v==='number')?'right':'left'; return td(fmt(v),align);}).join('')}</tr>`)).join('');
      return `<div class="export-section export-keep"><h3>${title}</h3><div style="color:#808089;font-size:12px;margin:-4px 0 8px 0">기간: ${periodLabel()} · 생성: ${generatedAt()}</div><div class="table-wrap" style="box-shadow:none;border:1px solid #ececec;border-radius:12px"><table class="table" style="width:100%;border-collapse:separate;border-spacing:0">${thead}${tbody}</table></div></div>`;
    };

    const cardRows=rowsCardSummary();
    const cardSummaryTable=(()=>{
      const head=['이미지','카드번호','카드명','신청서 작성','발급 완료','발급 전환율(%)'];
      const body=cardRows.map(r=>{
        const img=r._이미지?`<img class="card-img" src="${toProxied(r._이미지)}" alt="${r.카드명}">`:`<div class="noimg">NO IMG</div>`;
        return `<tr>${td(img)}${td('#'+r.카드번호)}${td(r.카드명)}${td(fmt(r['신청서 작성']),'right')}${td(fmt(r['발급 완료']),'right')}${td(fmt(r['발급 전환율(%)']),'right')}</tr>`;
      }).join('');
      return `<div class="export-section export-keep"><h3>카드별 통합 현황</h3><div class="table-wrap" style="box-shadow:none;border:1px solid #ececec;border-radius:12px"><table class="table" style="width:100%"><thead><tr>${head.map(th).join('')}</tr></thead><tbody>${body}</tbody></table></div></div>`;
    })();

    const productsRows=rowsProducts();
    const productsTable=(()=>{
      const head=['이미지','카드번호','카드명','유형','신청서 작성','발급 완료','발급 전환율(%)'];
      const body=productsRows.map(r=>{
        const img=r._이미지?`<img class="card-img" src="${toProxied(r._이미지)}" alt="${r.카드명}">`:`<div class="noimg">NO IMG</div>`;
        return `<tr>${td(img)}${td('#'+r.카드번호)}${td(r.카드명)}${td(r.유형)}${td(fmt(r['신청서 작성']),'right')}${td(fmt(r['발급 완료']),'right')}${td(fmt(r['발급 전환율(%)']),'right')}</tr>`;
      }).join('');
      return `<div class="export-section export-keep"><h3>상품판매 현황</h3><div class="table-wrap" style="box-shadow:none;border:1px solid #ececec;border-radius:12px"><table class="table" style="width:100%"><thead><tr>${head.map(th).join('')}</tr></thead><tbody>${body}</tbody></table></div></div>`;
    })();

    return previewCSS+`<div class="preview-export">`+
      buildTable('요약',['지표','값'],rowsSummary())+
      cardSummaryTable+
      buildTable('가입자 현황 — 신청서 작성',['나이대','성별','건수'],rowsDemographyStarts())+
      buildTable('가입자 현황 — 발급 완료',['나이대','성별','건수'],rowsDemographyIssued())+
      productsTable+
      `</div>`;
  }

  async function ensureJsPDFReady(maxWaitMs=5000){
    const t0=performance.now();
    while(performance.now()-t0<maxWaitMs){
      if(window.jspdf&&window.jspdf.jsPDF) return true;
      await new Promise(r=>setTimeout(r,50));
    }
    throw new Error('jsPDF 로드 지연');
  }

  async function buildAllPDFBlob(){
    await ensureJsPDFReady(); const {jsPDF}=window.jspdf;
    const html=buildAllPreviewHTML();
    const temp=document.createElement('div'); temp.id='pdfTemp'; temp.style.position='fixed'; temp.style.left='-10000px'; temp.style.top='0'; temp.style.width='794px'; temp.style.background='#fff';
    const style=`#pdfTemp .table-wrap{overflow:visible;border:0;box-shadow:none;}
#pdfTemp .card{box-shadow:none;border:1px solid #ececec;border-radius:12px;}
#pdfTemp .kpi.card{border:1px solid #ececec}
#pdfTemp .muted{color:#4b5563}
#pdfTemp table{border-collapse:collapse !important;width:100%;}
#pdfTemp thead th{position:static !important;background:#fafbfc !important;}
#pdfTemp th,#pdfTemp td{border:1px solid #ececec !important;}
#pdfTemp .export-section{margin:14px 0;}
#pdfTemp h3{margin:16px 0 8px 0;}
#pdfTemp .export-keep{page-break-inside:avoid;}
#pdfTemp td img{display:block;width:60px;height:36px;object-fit:contain;border:1px solid #ececec;border-radius:8px;}`;
    temp.innerHTML=`<style>${style}</style>${html}`; document.body.appendChild(temp);
    temp.querySelectorAll('img').forEach(img=>{ const s=img.getAttribute('src')||''; if(!s.startsWith('data:')) img.setAttribute('src', toProxied(s)); });
    await inlineAllImages(temp);
    await waitAllImgsLoaded(temp);
    const canvas=await html2canvas(temp,{scale:2,useCORS:true,backgroundColor:'#ffffff'});
    const pdf=new jsPDF('p','pt','a4'); const pageW=pdf.internal.pageSize.getWidth(); const pageH=pdf.internal.pageSize.getHeight(); const margin=20; const imgW=pageW-margin*2; const pxPerPage=Math.floor((pageH-margin*2)*canvas.width/imgW); const pageCanvas=document.createElement('canvas'); const ctx=pageCanvas.getContext('2d');
    let y=0; while(y<canvas.height){
      const sliceH=Math.min(pxPerPage, canvas.height-y);
      pageCanvas.width=canvas.width; pageCanvas.height=sliceH;
      ctx.clearRect(0,0,pageCanvas.width,pageCanvas.height);
      ctx.drawImage(canvas,0,y,canvas.width,sliceH,0,0,canvas.width,sliceH);
      const imgData=pageCanvas.toDataURL('image/jpeg',0.95);
      const imgH=sliceH*imgW/canvas.width;
      pdf.addImage(imgData,'JPEG',margin,margin,imgW,imgH);
      y+=sliceH; if(y<canvas.height) pdf.addPage();
    }
    document.body.removeChild(temp);
    return pdf.output('blob');
  }

  async function buildAllXlsxBlob(){
    if(!window.ExcelJS){ alert('엑셀 라이브러리가 아직 로드되지 않았습니다.'); throw new Error('ExcelJS not ready'); }
    const wb=new ExcelJS.Workbook(); wb.creator='Admin'; wb.created=new Date();

    const addSheet=(name, rows, headerOrder)=>{
      const ws=wb.addWorksheet(name,{properties:{defaultRowHeight:18}});
      const headers=headerOrder||(rows[0]?Object.keys(rows[0]):[]);
      ws.columns=headers.map(h=>({header:h,key:h,width:Math.max(10,String(h).length+2)}));
      rows.forEach(r=>ws.addRow(headers.map(h=>r[h])));
      ws.getRow(1).eachCell(c=>{
        c.font={bold:true}; c.alignment={vertical:'middle',horizontal:'center'};
        c.fill={type:'pattern',pattern:'solid',fgColor:{argb:'FFFAFBFC'}};
        c.border={top:{style:'thin',color:{argb:'FFECECEC'}},left:{style:'thin',color:{argb:'FFECECEC'}},bottom:{style:'thin',color:{argb:'FFECECEC'}},right:{style:'thin',color:{argb:'FFECECEC'}}};
      });
      for(let r=2;r<=ws.rowCount;r++){
        ws.getRow(r).eachCell((c,idx)=>{
          const isNum=typeof c.value==='number';
          c.alignment={vertical:'middle',horizontal:isNum?'right':(idx===1?'center':'left')};
          c.border={top:{style:'thin',color:{argb:'FFECECEC'}},left:{style:'thin',color:{argb:'FFECECEC'}},bottom:{style:'thin',color:{argb:'FFECECEC'}},right:{style:'thin',color:{argb:'FFECECEC'}}};
        });
        if(r%2===0){ ws.getRow(r).eachCell(c=>{ c.fill={type:'pattern',pattern:'solid',fgColor:{argb:'FFFEFEFE'}}; }); }
      }
      ws.columns.forEach(col=>{ col.width=Math.max(col.width,12); });
      return ws;
    };

    addSheet('Summary', rowsSummary(), ['지표','값']);
    addSheet('Card_Summary', rowsCardSummary().map(({_이미지,...rest})=>rest), ['카드번호','카드명','신청서 작성','발급 완료','발급 전환율(%)']);
    addSheet('Demography_작성', rowsDemographyStarts(), ['나이대','성별','건수']);
    addSheet('Demography_발급', rowsDemographyIssued(), ['나이대','성별','건수']);
    addSheet('Products', rowsProducts().map(({_이미지,...rest})=>rest), ['카드번호','카드명','유형','신청서 작성','발급 완료','발급 전환율(%)']);

    const meta=wb.addWorksheet('Meta');
    meta.columns=[{header:'항목',key:'항목',width:10},{header:'값',key:'값',width:30}];
    meta.addRow({항목:'기간',값:periodLabel()});
    meta.addRow({항목:'생성',값:generatedAt()});
    meta.getRow(1).eachCell(c=>{
      c.font={bold:true}; c.alignment={horizontal:'center'};
      c.fill={type:'pattern',pattern:'solid',fgColor:{argb:'FFFAFBFC'}};
    });

    const buffer=await wb.xlsx.writeBuffer();
    return new Blob([buffer],{type:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'});
  }

  document.addEventListener('click', async (e)=>{
    if(e.target.id==='btnLoad'){ loadAll(); }
    if(e.target.id==='btnPreviewClose' || e.target.id==='previewWrap'){ closePreview(); }
    if(e.target.id==='btnPreviewAllPdf'){
      try{ const b=await buildAllPDFBlob(); openIframePreview('전체 PDF 미리보기', b);}
      catch(err){ console.error(err); alert('PDF 미리보기 실패: '+(err?.message||err)); }
    }
    if(e.target.id==='btnDownloadAllPdf'){
      try{ const b=await buildAllPDFBlob(); downloadBlob(`report_${periodLabel().replace(/\s+/g,'')}.pdf`, b);}
      catch(err){ console.error(err); alert('PDF 다운로드 실패: '+(err?.message||err)); }
    }
    if(e.target.id==='btnPreviewAllXlsx'){
      try{ const html=buildAllPreviewHTML(); openHTMLPreview('전체 엑셀 미리보기', html);}
      catch(err){ console.error(err); alert('엑셀 미리보기 실패: '+(err?.message||err)); }
    }
    if(e.target.id==='btnDownloadAllXlsx'){
      try{ const b=await buildAllXlsxBlob(); downloadBlob(`report_${periodLabel().replace(/\s+/g,'')}.xlsx`, b);}
      catch(err){ console.error(err); alert('엑셀 다운로드 실패: '+(err?.message||err)); }
    }

    const btn = e.target.closest && e.target.closest('button[data-seg]');
    if(btn){
      const [kind, ageBand, gender] = btn.dataset.seg.split('|');
      const segMap = (function(arr){ const map={}; for(const r of (arr||[])){ const k=`${r.ageBand}|${r.gender}`; (map[k] ||= {rows:[]}).rows.push(r); } return map; })(cacheCardDemo);
      const key = `${ageBand}|${gender}`;
      const rows = (segMap[key]?.rows)||[];
      const list = {};
      for(const r of rows){
        const k = r.cardNo; if(k==null) continue;
        const nm = r.cardName || ('#'+k);
        (list[k] ||= { cardNo:k, cardName:nm, starts:0, issued:0, img: imgByCardNo[k]||'' });
        list[k].starts += (r.startsTemp||0);
        list[k].issued += (r.confirmed||0);
      }
      const arr = Object.values(list).sort((a,b)=>(kind==='S'? (b.starts-a.starts):(b.issued-a.issued)));
      const html = `
        <div class="inner">
          <h3 style="margin:0 0 10px 0">${ageBand} · ${toKoGender(gender)} — 카드별 상세</h3>
          <div class="table-wrap" style="box-shadow:none">
            <table class="table">
              <thead><tr><th>카드</th><th>신청서 작성</th><th>발급 완료</th></tr></thead>
              <tbody>
                ${arr.map(r=>`
                  <tr>
                    <td>
                      <div class="cell-card">
                        ${r.img ? `<img class="card-thumb" src="${resolveImg(r.img)}" alt="${r.cardName}" onerror="this.outerHTML='<div class=&quot;card-thumb placeholder&quot;>NO IMG</div>'">` : `<div class="card-thumb placeholder">NO IMG</div>`}
                        <div class="card-meta"><div class="card-name">${r.cardName}</div><div class="card-no">#${r.cardNo}</div></div>
                      </div>
                    </td>
                    <td class="num">${fmt(r.starts)}</td>
                    <td class="num">${fmt(r.issued)}</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
        </div>`;
      openHTMLPreview('세그먼트 상세', html);
    }
  });

  (function init(){
    const end=new Date(); const start=new Date(); start.setDate(end.getDate()-6);
    const toIso=d=>new Date(d.getTime()-(d.getTimezoneOffset()*60000)).toISOString().slice(0,10);
    document.getElementById('start').value=toIso(start);
    document.getElementById('end').value=toIso(end);
    document.getElementById('btnLoad').addEventListener('click', loadAll);
    document.getElementById('previewWrap').addEventListener('click', (evt)=>{ if(evt.target.id==='previewWrap') closePreview(); });
    loadAll();
  })();
  </script>
</body>
</html>
