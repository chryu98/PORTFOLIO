<%@ page contentType="text/html; charset=UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<title>카드별 약관</title>
<link rel="stylesheet" href="/css/adminstyle.css">
<style>
/* ========= 공통 팔레트 ========= */
:root{
  --bg:#ffffff;
  --txt:#111827;
  --muted:#6b7280;
  --line:#e5e7eb;
  --line-soft:#f3f4f6;
  --thead:#fafbfc;
  --card:#ffffff;
  --accent:#2563eb;
  --shadow:0 6px 18px rgba(17,24,39,.06);
  --radius:12px;
  --radius-lg:14px;
  --container:1100px;
}

*{ box-sizing:border-box }
html,body{ height:100% }
body{
  margin:0;
  background:var(--bg);
  color:var(--txt);
  font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;
  -webkit-font-smoothing:antialiased; -moz-osx-font-smoothing:grayscale;
}

/* ========= 가운데 정렬 컨테이너 ========= */
.container{
  width:min(var(--container),92vw);
  margin:0 auto;
}

/* ========= 제목/뒤로가기 ========= */
.title{
  margin:0 0 8px;
  font-size:28px; font-weight:700; letter-spacing:-.01em;
  text-align:center;
  padding-top:40px;
}
.back{ margin:6px 0 16px; text-align:center; }
.back a{
  display:inline-block; padding:8px 12px;
  border:1px solid var(--line); border-radius:10px;
  background:#fff; color:var(--txt); text-decoration:none;
  transition:background .15s, transform .05s;
}
.back a:hover{ background:#f3f4f6 }
.back a:active{ transform:translateY(1px) }

/* ========= 본문 레이아웃 ========= */
.grid{
  display:grid;
  grid-template-columns:360px 1fr;
  gap:16px;
  align-items:start;
}
@media (max-width: 900px){
  .grid{ grid-template-columns:1fr; }
}

/* ========= 카드 박스 ========= */
.box{
  border:1px solid var(--line);
  border-radius:var(--radius-lg);
  padding:12px;
  background:var(--card);
  box-shadow:var(--shadow);
}

/* ========= 공통 폼 요소 ========= */
.row{ display:flex; gap:8px; align-items:center; }
input,select,button{
  padding:10px 12px;
  border-radius:10px; border:1px solid var(--line);
  font-size:14px; background:#fff; color:var(--txt);
  outline:none;
  transition:border-color .18s, box-shadow .18s, transform .05s, filter .12s;
}
input:focus, select:focus{
  border-color:var(--accent);
  box-shadow:0 0 0 3px rgba(37,99,235,.15);
}

/* 버튼 */
.btn{ cursor:pointer; background:#fff; color:var(--txt); border-color:var(--line); }
.btn:hover{ filter:brightness(.98) }
.btn:active{ transform:translateY(1px) }
.btn.primary{ background:var(--accent); color:#fff; border-color:var(--accent) }

/* ========= 표 ========= */
table{
  width:100%;
  border-collapse:separate; border-spacing:0;
  margin-top:6px;
  background:#fff;
  border:1px solid var(--line); border-radius:var(--radius);
  overflow:hidden; box-shadow:var(--shadow);
}
thead th{
  background:var(--thead); color:#374151;
  font-weight:600; text-align:left;
  padding:10px 12px; font-size:14px;
  border-bottom:1px solid var(--line);
}
tbody td{
  padding:10px 12px; font-size:14px;
  border-bottom:1px solid var(--line-soft); vertical-align:middle;
}
tbody tr:hover{ background:#fdfefe }

/* ========= 텍스트/뱃지 ========= */
.muted{ color:var(--muted) }
.pill{
  padding:2px 8px; border-radius:999px;
  background:#f3f4f6; border:1px solid var(--line);
  font-size:12px;
}

/* ========= 스크롤 영역 ========= */
#card-list, #pdf-list{ margin-top:10px; max-height:70vh; overflow:auto; }
#pdf-list{ max-height:40vh }

/* ========= 접근성 ========= */
:focus-visible{ outline:3px solid rgba(37,99,235,.35); outline-offset:2px }
</style>
</head>
<body>
  <jsp:include page="../fragments/header.jsp"></jsp:include>

  <div class="container">
    <h2 class="title">카드별 약관 관리</h2>
    <div class="back"><a href="/admin/productTerms">← 뒤로가기</a></div>

    <div class="grid">
      <!-- 좌: 카드 검색/선택 -->
      <div class="box">
        <div class="row">
          <input id="card-q" placeholder="카드명/브랜드/타입 검색" onkeyup="if(event.key==='Enter') searchCards()" />
          <button class="btn" onclick="searchCards()">검색</button>
        </div>
        <div id="card-list"></div>
      </div>

      <!-- 우: 매핑 목록 + PDF 검색 -->
      <div class="box">
        <div class="row" style="justify-content:space-between;">
          <div>
            <div class="muted">선택된 카드</div>
            <div id="sel-card" style="font-weight:700;">(미선택)</div>
          </div>
        </div>

        <h3 style="margin:12px 0 6px;">연결된 약관</h3>
        <table>
          <thead>
            <tr>
              <th>PDF_NO</th>
              <th>PDF명</th>
              <th>범위</th>
              <th>코드</th>
              <th>필수</th>
              <th>수정/삭제</th>
            </tr>
          </thead>
          <tbody id="terms"></tbody>
        </table>

        <h3 style="margin:16px 0 6px;">PDF 검색 → 연결</h3>
        <div class="row">
          <input id="pdf-q" placeholder="PDF명/코드 검색" onkeyup="if(event.key==='Enter') searchPdfs()" />
          <select id="pdf-scope">
            <option value="">범위 전체</option>
            <option value="common">공통</option>
            <option value="specific">개별</option>
            <option value="select">선택</option>
          </select>
          <select id="pdf-active">
            <option value="">상태 전체</option>
            <option value="Y">사용</option>
            <option value="N">미사용</option>
          </select>
          <button class="btn" onclick="searchPdfs()">검색</button>
        </div>
        <div id="pdf-list"></div>
      </div>
    </div>
  </div>

  <script src="/js/adminHeader.js"></script>
  <script>
  /* ===== 유틸 ===== */
  function h(s){ return String(s==null?'':s).replace(/[&<>"']/g, m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m])); }
  function jsStr(s){ return JSON.stringify(String(s==null?'':s)); }

  const API = '/admin/api';

  async function api(url, options){
    const res = await fetch(url, Object.assign({ headers: { 'Content-Type': 'application/json' } }, options||{}));
    if(!res.ok){
      const text = await res.text();
      throw new Error('['+res.status+'] ' + text);
    }
    const ct = res.headers.get('content-type')||'';
    return ct.indexOf('application/json')!==-1 ? res.json() : res.text();
  }

  /* ============== 카드 검색/선택 ============== */
  async function searchCards(){
    const q = document.getElementById('card-q').value;
    const url = API + '/cards' + (q ? ('?q=' + encodeURIComponent(q)) : '');
    const list = await api(url);
    document.getElementById('card-list').innerHTML = list.map(function(c){
      return ''
        + '<div class="row" style="padding:8px; border-bottom:1px solid #f3f4f6; cursor:pointer;"'
        + ' onclick=\'selectCard(' + c.cardNo + ', ' + jsStr(c.cardName) + ', ' + jsStr(c.cardBrand||"") + ', ' + jsStr(c.cardType||"") + ')\'>' 
        +   '<div style="flex:1;">'
        +     '<div style="font-weight:600;">' + h(c.cardName) + '</div>'
        +     '<div class="muted">' + h(c.cardBrand||'') + ' · ' + h(c.cardType||'') + '</div>'
        +   '</div>'
        +   '<span class="muted">#' + c.cardNo + '</span>'
        + '</div>';
    }).join('');
  }
  searchCards();

  let currentCard = null;
  function selectCard(cardNo, name, brand, type){
    currentCard = cardNo;
    document.getElementById('sel-card').innerText = name + ' (#' + cardNo + ') — ' + brand + ' · ' + type;
    loadTerms();
  }

  /* ============== 선택 카드의 약관 목록 ============== */
  async function loadTerms(){
    if(!currentCard) return;
    const list = await api(API + '/cards/' + currentCard + '/terms');
    document.getElementById('terms').innerHTML = list.map(function(t){
      return ''
        + '<tr>'
        +   '<td>' + t.pdfNo + '</td>'
        +   '<td>' + h(t.pdfName||'') + '</td>'
        +   '<td><span class="pill">' + h(t.termScope||'') + '</span></td>'
        +   '<td>' + h(t.pdfCode||'') + '</td>'
        +   '<td>'
        +     '<select id="req-' + t.pdfNo + '">'
        +       '<option value="Y"' + (t.isRequired==='Y'?' selected':'') + '>Y</option>'
        +       '<option value="N"' + (t.isRequired==='N'?' selected':'') + '>N</option>'
        +     '</select>'
        +   '</td>'
        +   '<td>'
        +     '<button class="btn" onclick="updateReq(' + t.pdfNo + ')">수정</button> '
        +     '<button class="btn" onclick="delTerm(' + t.pdfNo + ')">삭제</button>'
        +   '</td>'
        + '</tr>';
    }).join('');
  }

  /* ============== PDF 검색/연결(등록) ============== */
  async function searchPdfs(){
    const q = document.getElementById('pdf-q').value;
    const scope = document.getElementById('pdf-scope').value;
    const active = document.getElementById('pdf-active').value;

    const url = new URL(location.origin + API + '/pdfs');
    if(q)     url.searchParams.set('q', q);
    if(scope) url.searchParams.set('scope', scope);
    if(active)url.searchParams.set('active', active);

    const list = await api(url.toString());
    document.getElementById('pdf-list').innerHTML = list.map(function(p){
      return ''
        + '<div class="row" style="padding:8px; border-bottom:1px solid #f3f4f6;">'
        +   '<div style="flex:1;">'
        +     '<div style="font-weight:600;">' + h(p.pdfName) + '</div>'
        +     '<div class="muted">#' + p.pdfNo + ' · ' + h(p.termScope) + ' · '
        +       (p.isActive==='Y'?'사용':'미사용') + (p.pdfCode? (' · ' + h(p.pdfCode)) : '') + '</div>'
        +   '</div>'
        +   '<button class="btn primary" onclick="connectPdf(' + p.pdfNo + ')">연결</button>'
        + '</div>';
    }).join('');
  }
  searchPdfs();

  async function connectPdf(pdfNo){
    if(!currentCard) { alert('카드를 먼저 선택하세요.'); return; }
    await api(API + '/cards/' + currentCard + '/terms', {
      method: 'POST',
      body: JSON.stringify({ pdfNo: pdfNo, isRequired: 'Y' })
    });
    await loadTerms();
    alert('연결되었습니다.');
  }

  /* ============== 수정/삭제 ============== */
  async function updateReq(pdfNo){
    const sel = document.getElementById('req-' + pdfNo);
    const val = sel ? sel.value : 'Y';
    await api(API + '/cards/' + currentCard + '/terms/' + pdfNo, {
      method: 'PUT',
      body: JSON.stringify({ isRequired: val })
    });
    alert('수정했습니다.');
  }

  async function delTerm(pdfNo){
    if(!confirm('삭제하시겠습니까?')) return;
    await api(API + '/cards/' + currentCard + '/terms/' + pdfNo, { method: 'DELETE' });
    await loadTerms();
    alert('삭제했습니다.');
  }
  </script>
</body>
</html>
