<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<title>AI 커스텀 로그</title>
<style>
:root {
	--border: #e5e7eb;
	--muted: #6b7280;
	--bg: #f9fafb;
	--ink: #111827;
	--ink2: #374151;
	--pill: #eef2ff;
	--okBg: #ecfdf5;
	--ok: #065f46;
	--badBg: #fef2f2;
	--bad: #7f1d1d;
	--primary: #111827;
	--rowHover: #f9fafb;
	--sel: #eef2ff;
}

* {
	box-sizing: border-box
}

body {
	font-family: system-ui, AppleSDGothicNeo, Segoe UI, Roboto, Arial;
	color: var(--ink)
}

h1 {
	margin: 0 0 16px;
}
.title{
    margin: 0 auto;
    display: block;
    width: 300px;
    padding-top: 20px;
    margin-bottom: 20px;}

.wrap {
	display: flex;
	template-columns: 1fr 380px;
	gap: 16px;
	align-items: start;
	max-width: 1150px;
	margin: 0 auto;
}

.panel {
	border: 1px solid var(--border);
	border-radius: 12px;
	padding: 14px;
	background: #fff
}

.toolbar {
	display: flex;
	gap: 10px;
	flex-wrap: wrap;
	align-items: center
}

label {
	font-size: 12px;
	color: var(--muted);
	margin-right: 6px
}

select, input {
	padding: 8px 10px;
	border: 1px solid var(--border);
	border-radius: 10px;
	background: #fff
}

button {
	padding: 8px 12px;
	border: 1px solid var(--border);
	background: #fff;
	border-radius: 10px;
	cursor: pointer
}

button.primary {
	background: var(--primary);
	color: #fff;
	border-color: var(--primary)
}

button:disabled {
	opacity: .5;
	cursor: not-allowed
}

.table-wrap {
	max-height: 62vh;
	overflow: auto;
	border: 1px solid var(--border);
	border-radius: 10px
}

table {
	width: 100%;
	border-collapse: separate;
	border-spacing: 0;
	font-size: 14px;
	min-width: 700px
}

thead th {
	position: sticky;
	top: 0;
	background: #fff;
	z-index: 1;
	border-bottom: 1px solid var(--border);
	padding: 10px;
	text-align: left;
	font-weight: 700
}

tbody td {
	border-bottom: 1px solid var(--border);
	padding: 10px;
	color: var(--ink2)
}

tbody tr {
	cursor: pointer
}

tbody tr:hover {
	background: var(--rowHover)
}

tbody tr.selected {
	background: var(--sel)
}

.pill {
	display: inline-block;
	padding: 2px 8px;
	border-radius: 999px;
	font-size: 12px;
	border: 1px solid var(--border);
	background: var(--pill)
}

.pill.ok {
	background: var(--okBg);
	color: var(--ok);
	border-color: #10b981
}

.pill.bad {
	background: var(--badBg);
	color: var(--bad);
	border-color: #ef4444
}

.muted {
	color: var(--muted);
	font-size: 12px
}

.right .box {
	border: 1px solid var(--border);
	border-radius: 10px;
	padding: 10px;
	background: #fff
}

.right img {
	width: 100%;
	border-radius: 10px;
	background: #f3f4f6
}

.row-actions {
	display: flex;
	gap: 6px
}

.pagination {
	margin-top: 12px;
	display: flex;
	gap: 8px;
	align-items: center;
    justify-content: center;
}

.inline {
	display: inline-flex;
	align-items: center;
	gap: 6px
}

.kvs {
	display: grid;
	grid-template-columns: 90px 1fr;
	gap: 6px;
	font-size: 13px
}

.kvs dt {
	color: var(--muted)
}

.empty {
	padding: 18px;
	text-align: center;
	color: var(--muted)
}
</style>

<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>

	<jsp:include page="../fragments/header.jsp"></jsp:include>
	<h1 class="title">커스텀 AI 판단 로그</h1>

	<div class="wrap">
		<!-- 좌측: 리스트/필터 -->
		<div class="panel">
			<form id="searchForm" class="toolbar"
				action="<c:url value='/admin/custom-cards'/>" method="get">
				<div class="inline">
					<label>AI 결과</label> <select name="aiResult" id="aiResult">
						<option value=""
							<c:if test="${empty param.aiResult}">selected</c:if>>전체</option>
						<option value="ACCEPT"
							<c:if test="${param.aiResult == 'ACCEPT'}">selected</c:if>>ACCEPT</option>
						<option value="REJECT"
							<c:if test="${param.aiResult == 'REJECT'}">selected</c:if>>REJECT</option>
					</select>
				</div>
				<div class="inline">
					<label>상태</label> <select name="status" id="status">
						<option value=""
							<c:if test="${empty param.status}">selected</c:if>>전체</option>
						<option value="PENDING"
							<c:if test="${param.status == 'PENDING'}">selected</c:if>>PENDING</option>
						<option value="APPROVED"
							<c:if test="${param.status == 'APPROVED'}">selected</c:if>>APPROVED</option>
						<option value="REJECTED"
							<c:if test="${param.status == 'REJECTED'}">selected</c:if>>REJECTED</option>
					</select>
				</div>
				<div class="inline">
					<label>회원번호</label> <input type="text" name="memberNo"
						id="memberNo"
						value="${empty param.memberNo ? '' : param.memberNo}"
						placeholder="예: 1001" />
				</div>
				<div class="inline">
					<label>페이지</label> <select name="size" id="size">
						<option value="10"
							<c:if test="${param.size == '10'}">selected</c:if>>10</option>
						<option value="20"
							<c:if test="${empty param.size or param.size == '20'}">selected</c:if>>20</option>
						<option value="50"
							<c:if test="${param.size == '50'}">selected</c:if>>50</option>
					</select>
				</div>
				<button type="submit" class="primary">검색</button>
				<button type="button" id="resetBtn">초기화</button>
			</form>

			<div class="table-wrap" id="tableWrap">
				<table>
					<thead>
						<tr>
							<th style="width: 90px">번호</th>
							<th style="width: 110px">회원</th>
							<th style="width: 120px">상태</th>
							<th style="width: 120px">AI 결과</th>
							<th>사유</th>
							<th style="width: 170px">생성일</th>
						</tr>
					</thead>
					<tbody id="rows">
						<tr>
							<td colspan="6" class="empty">데이터를 불러오는 중…</td>
						</tr>
					</tbody>
				</table>
			</div>

			<div class="pagination">
				<span class="muted" id="pageInfo">페이지 1 / 1</span>
				<button id="firstBtn">&laquo; 처음</button>
				<button id="prevBtn">&lt; 이전</button>
				<button id="nextBtn">다음 &gt;</button>
				<button id="lastBtn">마지막 &raquo;</button>
			</div>
		</div>

		<!-- 우측: 미리보기/상세 -->
		<div class="panel right">
			<div class="box">
				<div class="muted">선택한 카드 이미지</div>
				<div id="imgWrap" style="margin-top: 8px">
					<img id="preview" alt="행을 선택하면 미리보기가 표시됩니다" src=""
						onerror="this.src='';this.alt='이미지 없음'" />
				</div>
				<div style="display: flex; gap: 8px; margin-top: 10px">
					<a id="downloadBtn" href="#" download class="inline">
						<button type="button">이미지 다운로드</button>
					</a> <a id="openRawBtn" href="#" target="_blank" class="inline">
						<button type="button">원본 새 창</button>
					</a>
				</div>
			</div>

			<div class="box" style="margin-top: 12px">
				<div class="muted" style="margin-bottom: 6px">상세 정보</div>
				<dl class="kvs" id="detailBox">
					<dt>안내</dt>
					<dd class="muted">행을 선택하면 상세정보가 표시됩니다.</dd>
				</dl>
			</div>
		</div>
	</div>

	<c:url value="/admin/api/custom-cards" var="apiBase" />

	<script src="/js/adminHeader.js"></script>
	<script>
  // HTML escape
  function h(s){ s=(s??'').toString(); return s.replace(/&/g,'&amp;').replace(/</g,'&lt;')
    .replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;'); }

  const apiBase = "${apiBase}";
  const qs = new URLSearchParams(location.search);
  let page = parseInt(qs.get('page') || "0", 10);
  let size = parseInt(qs.get('size') || (document.getElementById('size') ? document.getElementById('size').value : "20"), 10);
  let lastSelected = null;
  let total = 0;

  const $rows = document.getElementById('rows');
  const $pageInfo = document.getElementById('pageInfo');

  // 필터 자동적용 (Input change → 250ms 디바운스)
  let timer;
  ['aiResult','status','memberNo','size'].forEach(id=>{
    const el = document.getElementById(id);
    if(!el) return;
    const handler = ()=>{
      clearTimeout(timer);
      timer = setTimeout(()=>{
        page = 0;
        syncQuery();
        fetchList();
      }, 250);
    };
    el.addEventListener(el.tagName==='INPUT' ? 'keyup' : 'change', handler);
  });

  document.getElementById('resetBtn').onclick = ()=>{
    document.getElementById('aiResult').value='';
    document.getElementById('status').value='';
    document.getElementById('memberNo').value='';
    document.getElementById('size').value='20';
    page=0; size=20;
    syncQuery(); fetchList();
  };

  // 주소창 쿼리 반영
  function syncQuery(){
    const aiResult = document.getElementById('aiResult').value;
    const status   = document.getElementById('status').value;
    const memberNo = document.getElementById('memberNo').value.trim();
    const sizeSel  = document.getElementById('size').value;

    const q = new URLSearchParams();
    if (aiResult) q.set('aiResult', aiResult);
    if (status)   q.set('status', status);
    if (memberNo) q.set('memberNo', memberNo);
    q.set('page', page); q.set('size', sizeSel);
    history.replaceState(null, '', location.pathname + '?' + q.toString());
    size = parseInt(sizeSel,10);
  }

  async function fetchList() {
    const aiResult = document.getElementById('aiResult').value;
    const status   = document.getElementById('status').value;
    const memberNo = document.getElementById('memberNo').value.trim();

    const url = new URL(apiBase, location.origin);
    if (aiResult) url.searchParams.set('aiResult', aiResult);
    if (status)   url.searchParams.set('status', status);
    if (memberNo) url.searchParams.set('memberNo', memberNo);
    url.searchParams.set('page', page);
    url.searchParams.set('size', size);

    $rows.innerHTML = '<tr><td colspan="6" class="empty">불러오는 중…</td></tr>';

    const res = await fetch(url);
    if (!res.ok) {
      console.error('list fetch failed', res.status);
      $rows.innerHTML = '<tr><td colspan="6" class="empty">목록 조회 실패</td></tr>';
      return;
    }
    const data = await res.json();
    total = data.total ?? 0;

    $rows.innerHTML = '';
    if (!data.items || data.items.length === 0) {
      $rows.innerHTML = '<tr><td colspan="6" class="empty">데이터 없음</td></tr>';
    } else {
      for (const row of data.items) {
        const tr = document.createElement('tr');
        tr.dataset.cno = row.customNo;

        const aiPill =
          row.aiResult === 'ACCEPT' ? '<span class="pill ok">ACCEPT</span>' :
          row.aiResult === 'REJECT' ? '<span class="pill bad">REJECT</span>' :
          '<span class="pill">-</span>';

        const reason = (row.aiReason || '');
        tr.innerHTML =
          '<td>' + h(row.customNo) + '</td>' +
          '<td>' + h(row.memberNo ?? '') + '</td>' +
          '<td>' + h(row.status ?? '') + '</td>' +
          '<td>' + aiPill + '</td>' +
          '<td title="' + h(reason) + '">' + h(reason.substring(0, 60)) + (reason.length>60?'…':'') + '</td>' +
          '<td>' + h(row.createdAt ?? '') + '</td>';

        tr.onclick = ()=> selectRow(row);
        $rows.appendChild(tr);

        if (lastSelected && lastSelected == row.customNo) {
          tr.classList.add('selected');
        }
      }
    }

    const maxPage = Math.max(Math.ceil(total / size) - 1, 0);
    $pageInfo.textContent = '페이지 ' + (page+1) + ' / ' + (maxPage+1) + ' (총 ' + total + '건)';
    document.getElementById('firstBtn').disabled = page <= 0;
    document.getElementById('prevBtn').disabled  = page <= 0;
    document.getElementById('nextBtn').disabled  = page >= maxPage;
    document.getElementById('lastBtn').disabled  = page >= maxPage;
  }

  function selectRow(row){
    lastSelected = row.customNo;
    // row highlight
    [...$rows.querySelectorAll('tr')].forEach(tr=>{
      tr.classList.toggle('selected', tr.dataset.cno == String(row.customNo));
    });
    // preview
    const imgUrl = apiBase + '/' + encodeURIComponent(row.customNo) + '/image';
    const $img = document.getElementById('preview');
    $img.src = imgUrl;
    $img.alt = 'CUSTOM_NO ' + row.customNo;

    document.getElementById('downloadBtn').href = imgUrl;
    document.getElementById('openRawBtn').href  = imgUrl;

    // detail
    const $detail = document.getElementById('detailBox');
    $detail.innerHTML =
      '<dt>번호</dt><dd>' + h(row.customNo) + '</dd>' +
      '<dt>회원</dt><dd>' + h(row.memberNo ?? '') + '</dd>' +
      '<dt>상태</dt><dd>' + h(row.status ?? '') + '</dd>' +
      '<dt>AI 결과</dt><dd>' + h(row.aiResult ?? '-') + '</dd>' +
      '<dt>사유</dt><dd>' + h(row.aiReason ?? '') + '</dd>' +
      '<dt>생성일</dt><dd>' + h(row.createdAt ?? '') + '</dd>' +
      '<dt>수정일</dt><dd>' + h(row.updatedAt ?? '') + '</dd>';
  }

  // 페이지네이션
  document.getElementById('firstBtn').onclick = ()=>{ page = 0; syncQuery(); fetchList(); };
  document.getElementById('prevBtn').onclick  = ()=>{ page = Math.max(page - 1, 0); syncQuery(); fetchList(); };
  document.getElementById('nextBtn').onclick  = ()=>{ page = page + 1; syncQuery(); fetchList(); };
  document.getElementById('lastBtn').onclick  = ()=>{ const maxPage = Math.max(Math.ceil(total / size) - 1, 0); page = maxPage; syncQuery(); fetchList(); };

  // 폼 submit은 주소창 유지용
  document.getElementById('searchForm').addEventListener('submit', function(e){ /* no-op */ });

  // 첫 로드
  fetchList();
</script>
</body>
</html>
