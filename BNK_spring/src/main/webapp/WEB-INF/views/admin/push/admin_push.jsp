<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<title>마케팅 푸시 발송</title>

<!-- Spring Security CSRF (사용 중이면 자동 주입됨) -->
<meta name="_csrf" content="${_csrf.token}" />
<meta name="_csrf_header" content="${_csrf.headerName}" />

<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link
	href="https://cdn.jsdelivr.net/npm/suit-font@1.0.0/dynamic-subset.css"
	rel="stylesheet">
<link
	href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;600&display=swap"
	rel="stylesheet">
<style>
:root {
	--bg: #F7F8FA;
	--ink: #111827;
	--muted: #6B7280;
	--card: #FFFFFF;
	--border: #E5E7EB;
	--primary: #2563EB;
	--pass: #10B981;
	--warn: #F59E0B;
}

* {
	box-sizing: border-box
}

html, body {
	margin: 0;
	padding: 0;
	background: var(--bg);
	color: var(--ink);
	font-family: 'SUIT', 'Noto Sans KR', system-ui
}

.container {
	max-width: 1100px;
	margin: 0px auto;
	padding: 0 16px
}

.h1 {
	padding-top:40px;
	font-size: 22px;
	font-weight: 700;
	margin-bottom: 16px
}

.card {
	background: var(--card);
	border: 1px solid var(--border);
	border-radius: 16px;
	box-shadow: 0 2px 8px rgba(0, 0, 0, .04);
	padding: 16px;
	margin-bottom: 16px
}

.row {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 12px
}

.row-1 {
	display: grid;
	grid-template-columns: 1fr;
	gap: 12px
}

label {
	font-weight: 600;
	font-size: 14px;
	margin-bottom: 6px;
	display: block
}

input[type="text"], textarea, select {
	width: 100%;
	padding: 10px 12px;
	border: 1px solid var(--border);
	border-radius: 10px;
	background: #fff;
	font-size: 14px
}

textarea {
	min-height: 90px;
	resize: vertical
}

.radio {
	display: flex;
	gap: 16px;
	align-items: center
}

.btn {
	padding: 10px 14px;
	border-radius: 10px;
	border: 1px solid var(--border);
	background: #fff;
	font-weight: 600;
	cursor: pointer
}

.btn.primary {
	background: var(--primary);
	color: #fff;
	border-color: var(--primary)
}

.btn.ghost {
	background: #fff
}

.btnrow {
	display: flex;
	gap: 8px;
	justify-content: flex-end;
	margin-top: 10px
}

.kpi {
	display: flex;
	gap: 16px;
	align-items: center;
	margin-top: 8px;
	color: var(--muted)
}

.badge {
	padding: 2px 8px;
	border-radius: 999px;
	border: 1px solid var(--border);
	font-size: 12px
}

.table {
	width: 100%;
	border-collapse: separate;
	border-spacing: 0 8px
}

.table th {
	font-size: 12px;
	color: var(--muted);
	text-align: left;
	padding: 6px 8px
}

.table td {
	background: #fff;
	border: 1px solid var(--border);
	border-left: 0;
	border-right: 0;
	padding: 10px 12px
}

.table tr td:first-child {
	border-left: 1px solid var(--border);
	border-top-left-radius: 12px;
	border-bottom-left-radius: 12px
}

.table tr td:last-child {
	border-right: 1px solid var(--border);
	border-top-right-radius: 12px;
	border-bottom-right-radius: 12px
}

.note {
	font-size: 12px;
	color: var(--muted)
}
</style>
 <link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>

<jsp:include page="../../fragments/header.jsp"></jsp:include>
	<div class="container">
		<div class="h1">마케팅 푸시 발송</div>

		<div class="card">
			<div class="row">
				<div>
					<label>제목</label> <input id="title" type="text"
						placeholder="예) 9월 카드 이벤트 안내">
				</div>
				<div>
					<label>대상 유형</label>
					<div class="radio">
						<label><input type="radio" name="targetType" value="ALL"
							checked> 전체(마케팅 동의자)</label> <label><input type="radio"
							name="targetType" value="MEMBER_LIST"> 특정 회원 목록</label>
					</div>
				</div>
			</div>

			<div class="row-1" style="margin-top: 10px;">
				<div>
					<label>본문</label>
					<textarea id="content" placeholder="푸시 메시지 내용을 입력하세요."></textarea>
				</div>
			</div>

			<div class="row-1" id="memberListBox"
				style="display: none; margin-top: 10px;">
				<div>
					<label>회원번호 목록(콤마 또는 줄바꿈 구분)</label>
					<textarea id="memberList"
						placeholder="예) 101, 203, 304 또는 줄바꿈으로 나열"></textarea>
					<div class="note">명단이라도 마케팅 미동의자는 제외됩니다.</div>
				</div>
			</div>

			<div class="btnrow">
				<button class="btn ghost" id="btnPreview">수신자 미리보기</button>
				<button class="btn primary" id="btnSend">발송</button>
			</div>
			<div class="kpi">
				<span class="badge" id="previewBadge">미리보기 전</span> <span
					class="note" id="previewNote"></span>
			</div>
		</div>

		<div class="card">
			<div
				style="display: flex; justify-content: space-between; align-items: center;">
				<div style="font-weight: 700;">최근 발송 이력</div>
				<div>
					<button class="btn" id="btnReload">새로고침</button>
				</div>
			</div>
			<table class="table" id="listTable">
				<thead>
					<tr>
						<th>번호</th>
						<th>제목</th>
						<th>대상</th>
						<th>수신자 수</th>
						<th>작성자</th>
						<th>등록시각</th>
					</tr>
				</thead>
				<tbody></tbody>
			</table>
			<div class="btnrow">
				<button class="btn" id="prev">이전</button>
				<button class="btn" id="next">다음</button>
			</div>
		</div>
	</div>

<script src="/js/adminHeader.js"></script>

	<script>
// ---------- URL & CSRF ----------
const URLS = {
  preview: '<c:url value="/admin/push/api/preview"/>',
  send:    '<c:url value="/admin/push/api/send"/>',
  list:    '<c:url value="/admin/push/api/list"/>'
};
const CSRF_TOKEN  = document.querySelector('meta[name="_csrf]') ? document.querySelector('meta[name="_csrf"]').content : document.querySelector('meta[name="_csrf"]')?.content;
const CSRF_HEADER = document.querySelector('meta[name="_csrf_header"]')?.content;
function withCsrf(headers){ headers = headers || {}; if (CSRF_TOKEN && CSRF_HEADER) headers[CSRF_HEADER] = CSRF_TOKEN; return headers; }

// ---------- DOM ----------
function qs(s){ return document.querySelector(s); }
function qsa(s){ return Array.prototype.slice.call(document.querySelectorAll(s)); }
var $title = qs('#title');
var $content = qs('#content');
var $memberListBox = qs('#memberListBox');
var $memberList = qs('#memberList');
var $previewBadge = qs('#previewBadge');
var $previewNote  = qs('#previewNote');

function getTargetType(){
  var r = qsa('input[name="targetType"]').find(function(x){ return x.checked; });
  return r ? r.value : 'ALL';
}
qsa('input[name="targetType"]').forEach(function(r){
  r.addEventListener('change', function(){
    $memberListBox.style.display = (getTargetType()==='MEMBER_LIST') ? 'block' : 'none';
  });
});

function parseMemberList(){
  var raw = $memberList.value;
  if(!raw) return [];
  return raw.split(/[\s,]+/)
            .map(function(s){ return s.trim(); })
            .filter(function(s){ return !!s; })
            .map(function(n){ return Number(n); })
            .filter(function(n){ return !Number.isNaN(n); });
}

// ---------- API ----------
async function preview(){
  var payload = { targetType: getTargetType(), memberList: parseMemberList() };
  var res = await fetch(URLS.preview, {
    method:'POST',
    headers: withCsrf({'Content-Type':'application/json'}),
    body: JSON.stringify(payload)
  });
  var data = await res.json();
  $previewBadge.textContent = '수신 가능: ' + data.eligible + ' 명';
  $previewNote.textContent  = (payload.targetType==='ALL')
    ? '현재 마케팅 동의자 전원에게 발송됩니다.'
    : '명단 중 마케팅 동의자에게만 발송됩니다.';
}

async function send(){
  var title = $title.value.trim();
  var content = $content.value.trim();
  var targetType = getTargetType();
  if(!title || !content){ alert('제목/본문을 입력하세요.'); return; }

  var payload = { title: title, content: content, targetType: targetType, memberList: parseMemberList() };
  var res = await fetch(URLS.send, {
    method:'POST',
    headers: withCsrf({'Content-Type':'application/json','X-Admin-Id':'admin'}),
    body: JSON.stringify(payload)
  });
  var data = await res.json();
  if(data.status === 'OK'){
    alert('발송 완료 (PUSH_NO=' + data.pushNo + ')');
    await preview();
    await loadList();
  } else {
    alert('발송 실패');
  }
}

var page=0, size=10;
async function loadList(){
  var res = await fetch(URLS.list + '?page=' + page + '&size=' + size);
  var data = await res.json();
  var tbody = qs('#listTable tbody');
  var rows = data.rows || [];

  var html = '';
  rows.forEach(function(r){
    var pushNo = (r.PUSHNO ?? r.pushNo);
    var title  = escapeHtml(r.TITLE ?? r.title);
    var target = (r.TARGETTYPE ?? r.targetType);
    var count  = (r.RECIPIENTCOUNT ?? r.recipientCount);
    var author = escapeHtml(r.CREATEDBY ?? r.createdBy);
    var when   = formatDate(r.CREATEDAT ?? r.createdAt);

    html += '<tr>'
      + '<td>' + pushNo + '</td>'
      + '<td>' + title  + '</td>'
      + '<td>' + target + '</td>'
      + '<td>' + count  + '</td>'
      + '<td>' + author + '</td>'
      + '<td>' + when   + '</td>'
      + '</tr>';
  });
  tbody.innerHTML = html;
}

function formatDate(s){
  if(!s) return '';
  return String(s).replace('T',' ').slice(0,19);
}
function escapeHtml(v){
  return String(v ?? '').replace(/[&<>"']/g, function(m){
    return ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' })[m];
  });
}

qs('#btnPreview').addEventListener('click', preview);
qs('#btnSend').addEventListener('click', send);
qs('#btnReload').addEventListener('click', loadList);
qs('#prev').addEventListener('click', function(){ page = Math.max(0, page-1); loadList(); });
qs('#next').addEventListener('click', function(){ page = page+1; loadList(); });

window.addEventListener('load', function(){ preview(); loadList(); });
</script>
</body>
</html>
