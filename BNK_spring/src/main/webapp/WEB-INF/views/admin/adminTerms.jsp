<%@ page language="java" contentType="text/html; charset=UTF-8"
  pageEncoding="UTF-8" isELIgnored="true"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>상품 약관 관리</title>
<link rel="stylesheet" href="/css/adminstyle.css">
<style>
/* ===== Design tokens ===== */
:root{
  --bg:#fff;
  --txt:#111827;
  --muted:#6b7280;
  --line:#e5e7eb;
  --line-soft:#f1f5f9;
  --thead:#fafbfc;
  --card:#ffffff;
  --accent:#2563eb;
  --shadow:0 6px 18px rgba(17,24,39,.06);
  --radius:12px;
  --radius-lg:14px;
  --container:1100px;
}

/* ===== Base ===== */
*{ box-sizing:border-box }
html,body{ height:100% }
body{
  margin:0; background:var(--bg); color:var(--txt);
  font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;
  -webkit-font-smoothing:antialiased; -moz-osx-font-smoothing:grayscale;
}

/* 중앙 정렬 공통 폭 */
:where(h1,h2,h3,form,table,#editFormWrapper,.toolbar,.pager){
  width:min(var(--container),92vw);
  margin-inline:auto;
}

/* ===== Page titles ===== */
h1{
  padding-top:40px;
  font-size:28px; font-weight:700; letter-spacing:-.01em;
  display:flex; align-items:center; justify-content:center; gap:10px; text-align:center;
}
h3{
  margin:20px auto 10px; text-align:center; font-size:18px; font-weight:600; color:var(--txt);
}

/* =========================================================================
   Toolbar (검색/필터): 3단 카드 레이아웃
   ┌──────── search (2칸) ────────┐
   ├── status (1) ──┬── size (1) ─┤
   └────────── link (2칸) ────────┘
   ========================================================================= */
.toolbar{
  display:grid;
  grid-template-columns: 1fr 1fr;
  grid-template-areas:
    "search search"
    "status size"
    "link   link";
  gap:16px;           /* 가로/세로 간격 */
  align-items:stretch;
  margin:0 auto 12px;
}

/* 각 요소를 영역에 배치 */
#searchInput{ grid-area:search; }
#statusFilter{ grid-area:status; }
#pageSize{ grid-area:size; }
.toolbar .link-btn{ grid-area:link; }

/* 카드처럼 보이도록 공통 스타일 */
.toolbar > input[type="text"],
.toolbar > select,
.toolbar .link-btn{
  height:84px; line-height:84px;         /* 큼직하게 */
  font-size:20px;                         /* 글자도 크게 */
  border:1px solid var(--line);
  border-radius:12px;
  background:#fff;
  box-shadow:var(--shadow);
}

/* 입력/선택은 좌우 패딩, 버튼은 가운데 정렬 */
.toolbar > input[type="text"],
.toolbar > select{
  padding:0 16px;
  width:100%; max-width:none; min-width:0; /* 그리드 셀 가득 */
  outline:none; transition:border-color .18s, box-shadow .18s;
}
.toolbar > input[type="text"]:focus,
.toolbar > select:focus{
  border-color:var(--accent);
  box-shadow:0 0 0 3px rgba(37,99,235,.15);
}

.toolbar .link-btn{
  display:flex; align-items:center; justify-content:center;
  text-decoration:none; color:var(--txt);
  border:1px solid var(--accent);         /* 예시 이미지처럼 테두리 강조 */
  line-height:normal;                     /* flex 중앙정렬이라 필요 없음 */
}

/* ===== Forms ===== */
form{
  background:var(--card); border:1px solid var(--line); border-radius:var(--radius-lg);
  padding:16px; margin:12px auto 20px; box-shadow:var(--shadow);
}
label{ display:inline-block; font-size:13px; color:var(--muted); margin:8px 0 6px; }
input[type="text"], input[type="file"], select, button{
  padding:10px 12px; font-size:14px; border:1px solid var(--line); border-radius:10px;
  background:#fff; color:var(--txt); outline:none;
  transition:border-color .18s, box-shadow .18s, transform .05s, filter .12s;
}
input[type="text"], input[type="file"], select{ width:min(520px,92vw); max-width:100%; }
input:focus, select:focus{ border-color:var(--accent); box-shadow:0 0 0 3px rgba(37,99,235,.15); }

/* 라디오 그룹 */
input[type="radio"]{ margin-right:6px }
input[type="radio"]+label{ margin:0 16px 0 2px }

/* Buttons */
button{ cursor:pointer; background:var(--accent); border-color:var(--accent); color:#fff; }
button:hover{ filter:brightness(.98) } button:active{ transform:translateY(1px) }
button[type="button"]{ background:#fff; color:var(--txt); border-color:var(--line); }

/* ===== Edit card ===== */
#editFormWrapper{
  border:1px solid var(--line) !important; border-radius:var(--radius-lg);
  padding:16px !important; margin-top:20px !important;
  background:#fff; box-shadow:0 6px 18px rgba(17,24,39,.08);
}
#editFormWrapper h3{ margin:0 0 10px; font-size:18px; font-weight:700; color:var(--txt); }

/* ===== Tables ===== */
table{
  width:min(var(--container),92vw); border-collapse:separate; border-spacing:0;
  background:#fff; border:1px solid var(--line) !important; border-radius:var(--radius);
  overflow:hidden; margin:10px auto 24px; box-shadow:var(--shadow);
}
thead th{
  background:var(--thead); color:#374151; font-weight:600; font-size:14px;
  text-align:left; padding:12px 14px; border-bottom:1px solid var(--line); user-select:none;
}
tbody td{ padding:11px 14px; font-size:14px; vertical-align:middle; border-bottom:1px solid var(--line-soft); }
tbody tr:nth-child(odd){ background:#fcfdff } tbody tr:hover{ background:#f7fbff }
thead th[title*="정렬"]{ cursor:pointer } thead th[title*="정렬"]:hover{ filter:brightness(.98) }
td button{ padding:6px 10px; font-size:13px; border-radius:8px; }
a{ color:var(--accent); text-decoration:none } a:hover{ text-decoration:underline }
.js-active-toggle{ accent-color:var(--accent) }

/* ===== A11y ===== */
:focus-visible{ outline:3px solid rgba(37,99,235,.35); outline-offset:2px }

/* ===== Responsive ===== */
@media (max-width:720px){
  /* 툴바를 1열로 쌓기 */
  .toolbar{
    grid-template-columns: 1fr;
    grid-template-areas:
      "search"
      "status"
      "size"
      "link";
  }
  .toolbar > input[type="text"],
  .toolbar > select,
  .toolbar .link-btn{ height:70px; font-size:18px; }

  h1{ font-size:24px }
  thead th, tbody td{ padding:10px 12px; font-size:13px }
  form{ padding:14px }
  input[type="text"], input[type="file"], select{ width:100% }
}

/* ===== Print ===== */
@media print{
  form, #editFormWrapper{ box-shadow:none; border-color:#ddd }
  button{ display:none !important }
}

/* ===== Pager ===== */
.pager{
  margin:-6px auto 22px; display:flex; justify-content:center; align-items:center;
  gap:8px; flex-wrap:wrap; color:#374151;
}
.pager button{
  padding:6px 10px; font-size:13px; border-radius:8px; cursor:pointer;
  border:1px solid var(--line); background:#fff; color:var(--txt);
  transition:background .15s, border-color .15s, transform .05s;
}
.pager button:hover:not([disabled]){ background:#f3f4f6 }
.pager button:active:not([disabled]){ transform:translateY(1px) }
.pager button[disabled]{ opacity:.45; cursor:default; pointer-events:none }
.pager button.is-active{ background:var(--accent); border-color:var(--accent); color:#fff; }
.pager .meta{ flex:0 0 100%; text-align:center; font-size:12px; color:var(--muted); margin-top:4px; }
.pager .ellipsis{ padding:0 4px; color:#9ca3af } .pager .spacer{ display:none }
</style>
</head>

<body>
  <jsp:include page="../fragments/header.jsp"></jsp:include>
  <h1>상품 약관 관리</h1>

  <!-- 검색/필터 바 -->
  <div class="toolbar">
    <input id="searchInput" type="text" placeholder="파일명/관리자/범위/코드 검색…">
    <select id="statusFilter">
      <option value="">전체 상태</option>
      <option value="Y">사용중</option>
      <option value="N">미사용</option>
    </select>
    <select id="pageSize">
      <option value="10" selected>10개씩</option>
      <option value="20">20개씩</option>
      <option value="50">50개씩</option>
    </select>
    <a href="/admin/cardTerms" class="link-btn">카드별 상품 약관 한눈에 보기</a>
  </div>

  <!-- 업로드 폼 -->
  <form id="uploadForm">
    <label>파일명:</label><br>
    <input type="text" id="pdfName" name="pdfName" required /><br><br>

    <label>사용 여부:</label><br>
    <select id="isActive" name="isActive" required>
      <option value="Y">사용</option>
      <option value="N">미사용</option>
    </select><br><br>

    <label>약관 범위:</label><br>
    <input type="radio" id="scopeCommon" name="termScope" value="common" required>
    <label for="scopeCommon">공통약관</label>
    <input type="radio" id="scopeSpecific" name="termScope" value="specific">
    <label for="scopeSpecific">개별약관</label>
    <input type="radio" id="scopeSelect" name="termScope" value="select">
    <label for="scopeSelect">선택약관</label><br><br>

    <label>약관 PDF 파일 업로드:</label><br>
    <input type="file" id="file" name="file" accept="application/pdf" required /><br><br>

    <button type="submit">업로드</button>
  </form>

  <!-- 수정 모달 -->
  <div id="editFormWrapper" style="display:none;">
    <h3>PDF 수정</h3>
    <form id="editForm">
      <input type="hidden" id="editPdfNo" />
      <label>파일명:</label><br>
      <input type="text" id="editPdfName" required /><br><br>

      <label>사용 여부:</label><br>
      <select id="editIsActive" required>
        <option value="Y">사용</option>
        <option value="N">미사용</option>
      </select><br><br>

      <label>약관 범위:</label><br>
      <input type="radio" id="editScopeCommon" name="editTermScope" value="common" required>
      <label for="editScopeCommon">공통약관</label>
      <input type="radio" id="editScopeSpecific" name="editTermScope" value="specific">
      <label for="editScopeSpecific">개별약관</label>
      <input type="radio" id="editScopeSelect" name="editTermScope" value="select">
      <label for="editScopeSelect">선택약관</label><br><br>

      <label>새 PDF 파일 (선택):</label><br>
      <input type="file" id="editFile" accept="application/pdf" /><br><br>

      <button type="submit">수정 완료</button>
      <button type="button" onclick="cancelEdit()">취소</button>
    </form>
  </div>

  <h3>공통약관</h3>
  <table>
    <thead>
      <tr>
        <th style="width:80px;">번호</th>
        <th>파일명</th>
        <th style="width:110px;">약관 범위</th>
        <th style="width:160px;">업로드 날짜</th>
        <th style="width:130px;">관리자 이름</th>
        <th style="width:100px;">상태</th>
        <th style="width:80px;">다운로드</th>
        <th style="width:70px;">수정</th>
        <th style="width:70px;">삭제</th>
      </tr>
    </thead>
    <tbody id="tbody-common"></tbody>
  </table>
  <div id="pager-common" class="pager"></div>

  <h3>개별약관</h3>
  <table>
    <thead>
      <tr>
        <th style="width:80px;">번호</th>
        <th>파일명</th>
        <th style="width:110px;">약관 범위</th>
        <th style="width:160px;">업로드 날짜</th>
        <th style="width:130px;">관리자 이름</th>
        <th style="width:100px;">상태</th>
        <th style="width:80px;">다운로드</th>
        <th style="width:70px;">수정</th>
        <th style="width:70px;">삭제</th>
      </tr>
    </thead>
    <tbody id="tbody-specific"></tbody>
  </table>
  <div id="pager-specific" class="pager"></div>

  <h3>선택약관</h3>
  <table>
    <thead>
      <tr>
        <th style="width:80px;">번호</th>
        <th>파일명</th>
        <th style="width:110px;">약관 범위</th>
        <th style="width:160px;">업로드 날짜</th>
        <th style="width:130px;">관리자 이름</th>
        <th style="width:100px;">상태</th>
        <th style="width:80px;">다운로드</th>
        <th style="width:70px;">수정</th>
        <th style="width:70px;">삭제</th>
      </tr>
    </thead>
    <tbody id="tbody-select"></tbody>
  </table>
  <div id="pager-select" class="pager"></div>

  <!-- PDF 미리보기 모달 -->
  <div id="pdfModal" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,.45); z-index:9999;">
    <div style="width:min(1000px,92vw); height:80vh; margin:6vh auto; background:#fff; border-radius:12px; overflow:hidden; position:relative; box-shadow:0 20px 50px rgba(0,0,0,.25);">
      <button id="pdfClose" style="position:absolute; right:12px; top:10px; z-index:2; border:1px solid var(--line); background:#fff; border-radius:10px; padding:8px 12px; cursor:pointer;">닫기</button>
      <iframe id="pdfFrame" src="" style="width:100%; height:100%; border:0;"></iframe>
    </div>
  </div>

  <script src="/js/adminHeader.js"></script>
  <script>
  // ---------- 공통 유틸 ----------
  const debounce = (fn, ms)=>{ let t; return (...a)=>{ clearTimeout(t); t=setTimeout(()=>fn(...a), ms); }; };
  const $ = sel => document.querySelector(sel);
  const $$ = sel => Array.from(document.querySelectorAll(sel));

  // ---------- 상태 ----------
  let pdfCache = [];

  const scopeTbodyMap = {
    common: document.getElementById("tbody-common"),
    specific: document.getElementById("tbody-specific"),
    select: document.getElementById("tbody-select")
  };
  const scopePagerMap = {
    common: document.getElementById("pager-common"),
    specific: document.getElementById("pager-specific"),
    select: document.getElementById("pager-select")
  };

  let sortKey = 'uploadDate';
  let sortDir = 'desc';
  let pageSize = parseInt(document.getElementById('pageSize').value, 10) || 10;
  const pageState = { common:1, specific:1, select:1 };

  function scopeLabel(scope){
    switch(scope){
      case 'common': return '공통약관';
      case 'specific': return '개별약관';
      case 'select': return '선택약관';
      default: return scope || '-';
    }
  }
  function formatKoDate(iso){
    if (!iso) return '';
    const d=new Date(iso);
    return d.toLocaleString("ko-KR",{year:"numeric",month:"2-digit",day:"2-digit",hour:"2-digit",minute:"2-digit",hour12:false,timeZone:"Asia/Seoul"});
  }
  function escapeHtml(s){ return (s+'').replace(/[&<>"']/g, m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m])); }

  function rowHtml(pdf){
    const date = pdf.uploadDate ? formatKoDate(pdf.uploadDate) : '';
    const isY = pdf.isActive === 'Y';
    return ''
      + '<tr data-pdf-no="'+pdf.pdfNo+'">'
      +   '<td>'+pdf.pdfNo+'</td>'
      +   '<td><a href="/admin/pdf/view/'+pdf.pdfNo+'" class="js-open-preview" data-id="'+pdf.pdfNo+'">'+escapeHtml(pdf.pdfName||'')+'</a></td>'
      +   '<td>'+scopeLabel(pdf.termScope)+'</td>'
      +   '<td>'+date+'</td>'
      +   '<td>'+escapeHtml(pdf.adminName||'')+'</td>'
      +   '<td><label style="display:inline-flex;align-items:center;gap:8px;cursor:pointer;"><input type="checkbox" class="js-active-toggle" data-id="'+pdf.pdfNo+'"'+(isY?' checked':'')+'><span>'+(isY?'사용중':'미사용')+'</span></label></td>'
      +   '<td><a href="/admin/pdf/download/'+pdf.pdfNo+'">다운로드</a></td>'
      +   '<td><button onclick="editPdf('+pdf.pdfNo+')">수정</button></td>'
      +   '<td><button onclick="deletePdf('+pdf.pdfNo+')">삭제</button></td>'
      + '</tr>';
  }

  async function loadPdfList(){
    try{
      Object.values(scopeTbodyMap).forEach(tb=>tb.innerHTML='<tr><td colspan="9" style="padding:16px;color:#6b7280;">불러오는 중…</td></tr>');
      const res = await fetch("/admin/pdf/list",{credentials:"include"});
      const list = await res.json();
      pdfCache = Array.isArray(list) ? list : [];
      applyFiltersAndRender();
    }catch(err){
      console.error("목록 불러오기 실패",err);
      Object.values(scopeTbodyMap).forEach(tb=>tb.innerHTML='<tr><td colspan="9" style="padding:16px;color:#991B1B;">목록을 불러오지 못했습니다.</td></tr>');
    }
  }

  function applyFiltersAndRender(){
    const q = ($('#searchInput')?.value || '').trim().toLowerCase();
    const status = $('#statusFilter')?.value || '';

    let filtered = pdfCache.filter(p=>{
      const hit = (p.pdfName||'').toLowerCase().includes(q)
              || (p.adminName||'').toLowerCase().includes(q)
              || (p.termScope||'').toLowerCase().includes(q)
              || (p.pdfCode||'').toLowerCase().includes(q);
      const stOk = !status || p.isActive === status;
      return hit && stOk;
    });

    filtered.sort((a,b)=>{
      let va = a[sortKey] ?? '', vb = b[sortKey] ?? '';
      let r = (sortKey==='uploadDate') ? (new Date(va)) - (new Date(vb))
                                       : (''+va).localeCompare(''+vb,'ko');
      return (sortDir==='asc') ? r : -r;
    });

    const grouped = { common:[], specific:[], select:[] };
    filtered.forEach(p=>{ if(grouped[p.termScope]) grouped[p.termScope].push(p); });

    ['common','specific','select'].forEach(scope=>{
      const tb = scopeTbodyMap[scope];
      const pg = scopePagerMap[scope];
      tb.innerHTML = ''; pg.innerHTML = '';

      const total = grouped[scope].length;
      if(total===0){ tb.innerHTML = '<tr><td colspan="9" style="padding:16px;color:#6b7280;">항목이 없습니다.</td></tr>'; return; }

      const pageCount = Math.max(1, Math.ceil(total / pageSize));
      if(!pageState[scope]) pageState[scope] = 1;
      pageState[scope] = Math.min(Math.max(1,pageState[scope]), pageCount);

      const start = (pageState[scope]-1)*pageSize;
      const rows = grouped[scope].slice(start, start+pageSize);
      rows.forEach(pdf=>tb.insertAdjacentHTML('beforeend', rowHtml(pdf)));

      renderPager(scope,total,pageCount);
    });
  }

  function renderPager(scope,total,pageCount){
    const pg = scopePagerMap[scope];
    const cur = pageState[scope];
    const parts = [];
    parts.push(`<button data-scope="${scope}" data-page="first" ${cur===1?'disabled':''}>« 처음</button>`);
    parts.push(`<button data-scope="${scope}" data-page="prev"  ${cur===1?'disabled':''}>‹ 이전</button>`);
    const makeBtn = (n,active=false)=> `<button data-scope="${scope}" data-page="${n}" class="${active?'is-active':''}">${n}</button>`;
    const range = []; const windowSize=5;
    let from = Math.max(1, cur-Math.floor(windowSize/2));
    let to   = Math.min(pageCount, from+windowSize-1);
    if (to-from+1 < windowSize) from = Math.max(1, to-windowSize+1);
    if (from>1){ range.push(1); if(from>2) range.push('...'); }
    for(let i=from;i<=to;i++) range.push(i);
    if (to<pageCount){ if(to<pageCount-1) range.push('...'); range.push(pageCount); }
    range.forEach(v=>{ parts.push(v==='...' ? '<span style="padding:0 4px;">…</span>' : makeBtn(v, v===cur)); });
    parts.push(`<button data-scope="${scope}" data-page="next"  ${cur===pageCount?'disabled':''}>다음 ›</button>`);
    parts.push(`<button data-scope="${scope}" data-page="last"  ${cur===pageCount?'disabled':''}>마지막 »</button>`);
    parts.push(`<span class="spacer"></span><span>총 ${total}개 · ${cur}/${pageCount}페이지</span>`);
    pg.innerHTML = parts.join('');
  }

  document.addEventListener('click',(e)=>{
    const btn = e.target.closest('.pager button[data-scope][data-page]');
    if(!btn) return;
    const scope = btn.dataset.scope;
    const action = btn.dataset.page;
    const cur = pageState[scope] || 1;
    switch(action){
      case 'first': pageState[scope]=1; break;
      case 'prev':  pageState[scope]=Math.max(1,cur-1); break;
      case 'next':  pageState[scope]=cur+1; break;
      case 'last':  pageState[scope]=Number.MAX_SAFE_INTEGER; break;
      default:      pageState[scope]=parseInt(action,10)||1;
    }
    applyFiltersAndRender();
  });

  document.getElementById('pageSize').addEventListener('change',(e)=>{
    pageSize = parseInt(e.target.value,10)||10;
    pageState.common = pageState.specific = pageState.select = 1;
    applyFiltersAndRender();
  });

  function getPdfFromCache(pdfNo){ return pdfCache.find(p=>String(p.pdfNo)===String(pdfNo)); }

  document.getElementById("uploadForm").addEventListener("submit", async (event)=>{
    event.preventDefault();
    const file = document.getElementById("file").files[0];
    if(!file){ alert("파일을 선택하세요."); return; }
    if(!/\.pdf$/i.test(file.name)){ alert("PDF 파일만 업로드 가능합니다."); return; }
    if(file.size>20*1024*1024){ alert("20MB 이하 파일만 업로드 가능합니다."); return; }
    const formData = new FormData();
    formData.append("file", file);
    formData.append("pdfName", document.getElementById("pdfName").value);
    formData.append("isActive", document.getElementById("isActive").value);
    formData.append("termScope", document.querySelector('input[name="termScope"]:checked').value);
    try{
      const res = await fetch("/admin/pdf/upload",{method:"POST",body:formData,credentials:"include"});
      const text = await res.text(); alert(text);
      await loadPdfList(); event.target.reset();
    }catch(e){ console.error(e); alert("업로드 중 오류 발생"); }
  });

  document.getElementById('searchInput').addEventListener('input', debounce(applyFiltersAndRender,150));
  document.getElementById('statusFilter').addEventListener('change', applyFiltersAndRender);

  function bindSortHeaders(){
    document.querySelectorAll('table thead th').forEach(th=>{
      const label = th.textContent.trim();
      if(label==='파일명' || label==='업로드 날짜'){
        th.style.cursor='pointer'; th.title='클릭하여 정렬';
        th.addEventListener('click',()=>{
          const key = (label==='파일명') ? 'pdfName' : 'uploadDate';
          if(sortKey===key){ sortDir = (sortDir==='asc') ? 'desc' : 'asc'; }
          else { sortKey=key; sortDir='desc'; }
          applyFiltersAndRender();
        });
      }
    });
  }

  document.addEventListener('change', async (e)=>{
    const el=e.target;
    if(!el.classList.contains('js-active-toggle')) return;
    const id=el.dataset.id;
    const item=getPdfFromCache(id); if(!item) return;
    const prev=item.isActive;
    const next=el.checked?'Y':'N';
    item.isActive=next; applyFiltersAndRender(); // optimistic
    try{
      const fd=new FormData();
      fd.append('pdfNo',item.pdfNo); fd.append('pdfName',item.pdfName);
      fd.append('isActive',next); fd.append('termScope',item.termScope);
      const res=await fetch('/admin/pdf/edit',{method:'POST',body:fd,credentials:'include'});
      if(!res.ok) throw new Error(await res.text());
      toast('상태가 업데이트 됐습니다.');
    }catch(err){
      console.error(err); item.isActive=prev; applyFiltersAndRender(); alert('상태 변경 실패');
    }
  });

  document.addEventListener('click',(e)=>{
    const a=e.target.closest('a.js-open-preview[href^="/admin/pdf/view/"]');
    if(!a) return; e.preventDefault();
    document.getElementById('pdfFrame').src=a.href;
    document.getElementById('pdfModal').style.display='block';
  });
  document.getElementById('pdfClose').addEventListener('click',()=>{
    document.getElementById('pdfModal').style.display='none';
    document.getElementById('pdfFrame').src='';
  });
  document.getElementById('pdfModal').addEventListener('click',(e)=>{
    if(e.target.id==='pdfModal') document.getElementById('pdfClose').click();
  });

  function editPdf(pdfNo){
    const pdf=getPdfFromCache(pdfNo);
    if(!pdf){ alert("대상 약관을 찾을 수 없습니다."); return; }
    document.getElementById("editPdfNo").value=pdf.pdfNo;
    document.getElementById("editPdfName").value=pdf.pdfName;
    document.getElementById("editIsActive").value=pdf.isActive;
    const scopeRadio=document.querySelector('input[name="editTermScope"][value="'+pdf.termScope+'"]');
    if(scopeRadio) scopeRadio.checked=true;
    document.getElementById("editFormWrapper").style.display="block";
  }
  window.editPdf = editPdf;

  document.getElementById("editForm").addEventListener("submit", async (e)=>{
    e.preventDefault();
    const fd=new FormData();
    fd.append("pdfNo", document.getElementById("editPdfNo").value);
    fd.append("pdfName", document.getElementById("editPdfName").value);
    fd.append("isActive", document.getElementById("editIsActive").value);
    const scopeEl=document.querySelector('input[name="editTermScope"]:checked');
    if(!scopeEl){ alert("약관 범위를 선택하세요."); return; }
    fd.append("termScope", scopeEl.value);
    const file=document.getElementById("editFile").files[0];
    if(file){
      if(!/\.pdf$/i.test(file.name)){ alert("PDF 파일만 업로드 가능합니다."); return; }
      if(file.size > 20*1024*1024){ alert("20MB 이하 파일만 업로드 가능합니다."); return; }
      fd.append("file", file);
    }
    try{
      const res=await fetch("/admin/pdf/edit",{method:"POST",body:fd,credentials:"include"});
      if(!res.ok) throw new Error(await res.text());
      toast("수정 완료"); document.getElementById("editForm").reset(); cancelEdit(); await loadPdfList();
    }catch(err){ console.error(err); alert("수정 중 오류: "+err.message); }
  });

  function cancelEdit(){ document.getElementById("editFormWrapper").style.display="none"; document.getElementById("editForm").reset(); }
  window.cancelEdit = cancelEdit;

  async function deletePdf(pdfNo){
    if(!confirm("정말 삭제하시겠습니까?")) return;
    const fd=new FormData(); fd.append("pdfNo", pdfNo);
    try{
      const res=await fetch("/admin/pdf/delete",{method:"POST",body:fd,credentials:"include"});
      const text=await res.text(); if(!res.ok) throw new Error(text);
      toast("삭제 완료"); await loadPdfList();
    }catch(err){ console.error(err); alert("삭제 중 오류: "+err.message); }
  }
  window.deletePdf = deletePdf;

  function toast(msg){
    const el=document.createElement('div');
    el.textContent=msg;
    el.style.cssText='position:fixed;right:16px;top:16px;background:#111;color:#fff;padding:10px 12px;border-radius:8px;opacity:.95;z-index:10000';
    document.body.appendChild(el);
    setTimeout(()=>el.remove(),2200);
  }

  window.addEventListener("DOMContentLoaded", async ()=>{
    bindSortHeaders();
    await loadPdfList();
  });
  </script>
</body>
</html>
