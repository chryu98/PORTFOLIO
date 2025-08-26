<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<fmt:requestEncoding value="UTF-8" />

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<title>인증 로그</title>

<style>
:root {
	--bg: #F7F8FA;
	--ink: #111827;
	--muted: #6B7280;
	--border: #E5E7EB;
	--card: #FFFFFF;
	--primary: #2563EB;
	--primary-ink: #FFFFFF;
	--pass: #10B981;
	--fail: #EF4444;
	--review: #F59E0B;
}

* {
	box-sizing: border-box
}

html, body {
	margin: 0;
	padding: 0;
	background: var(--bg);
	color: var(--ink);
	font: 14px/1.5 system-ui, -apple-system, Segoe UI, Roboto, Helvetica,
		Arial, sans-serif
}

.wrap {
	max-width: 1100px;
	margin: 0 auto;
	padding-top: 50px;
}

.title {
	font-weight: 700;
	font-size: 22px;
	margin-bottom: 30px;
}

.toolbar {
	background: var(--card);
	border: 1px solid var(--border);
	border-radius: 12px;
	padding: 14px;
	display: grid;
	gap: 10px;
	grid-template-columns: 1fr;
	align-items: end
}

@media ( min-width :900px) {
	.toolbar {
		grid-template-columns: 1fr auto auto auto auto
	}
}

.group {
	display: flex;
	gap: 8px;
	align-items: center;
	flex-wrap: wrap
}

.label {
	font-size: 12px;
	color: var(--muted)
}

.input, .select {
	height: 36px;
	border: 1px solid var(--border);
	border-radius: 8px;
	background: #fff;
	padding: 0 12px;
	outline: none;
	min-width: 200px
}

.select {
	min-width: 160px
}

.btn {
	height: 36px;
	border: 1px solid var(--border);
	border-radius: 8px;
	background: #fff;
	color: var(--ink);
	padding: 0 14px;
	font-weight: 600;
	cursor: pointer
}

.btn-primary {
	background: var(--primary);
	border-color: var(--primary);
	color: var(--primary-ink)
}

.btn-outline {
	background: #fff;
	color: #111;
	border-color: var(--border)
}

.btn-outline.active {
	border-color: var(--primary);
	color: var(--primary)
}

.btn:disabled {
	opacity: .5;
	cursor: not-allowed
}

.card {
	margin-top: 14px;
	background: var(--card);
	border: 1px solid var(--border);
	border-radius: 12px;
	overflow: hidden
}

table {
	width: 100%;
	border-collapse: separate;
	border-spacing: 0
}

thead th {
	background: #F9FAFB;
	border-bottom: 1px solid var(--border);
	text-align: left;
	padding: 10px 12px;
	font-size: 12px;
	color: var(--muted);
	font-weight: 600
}

tbody td {
	padding: 12px;
	border-bottom: 1px solid var(--border);
	vertical-align: top
}

tbody tr:hover {
	background: #FBFCFE
}

.mono {
	font-variant-numeric: tabular-nums;
	font-feature-settings: "tnum"
}

.badge {
	display: inline-block;
	padding: 3px 8px;
	border-radius: 999px;
	font-size: 12px;
	font-weight: 700;
	line-height: 1
}

.b-pass {
	background: #ECFDF5;
	color: var(--pass)
}

.b-fail {
	background: #FEF2F2;
	color: var(--fail)
}

.b-review {
	background: #FFFBEB;
	color: var(--review)
}

.muted {
	color: var(--muted)
}

.footer-note {
	margin-top: 10px;
	font-size: 12px;
	color: var(--muted)
}

/* Pagination */
.pagination {
	display: flex;
	gap: 6px;
	align-items: center;
	justify-content: flex-end;
	margin-top: 12px;
	flex-wrap: wrap
}

a.btn {
	display: inline-flex; /* 높이/패딩 적용 */
	align-items: center;
	justify-content: center;
	text-decoration: none; /* 밑줄 제거 */
	color: inherit; /* 기본 글자색 상속 */
}

a.btn:visited {
	color: inherit;
} /* 방문 색상 고정 */
a.btn.btn-primary { /* 파란 기본 버튼 */
	color: var(--primary-ink);
}

a.btn.btn-outline { /* 외곽선 버튼 */
	color: #111;
}

a.btn.btn-outline.active { /* 통과만 보기 ON 상태 */
	color: var(--primary);
	border-color: var(--primary);
	background: #fff;
}

.page-btn {
	min-width: 34px;
	height: 34px;
	border: 1px solid var(--border);
	border-radius: 8px;
	background: #fff;
	color: #111;
	padding: 0 10px;
	font-weight: 600;
	cursor: pointer;
	text-decoration: none;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	text-decoration: none;
}

.page-btn.current {
	background: #EEF2FF;
	border-color: #C7D2FE;
	color: #1E3A8A
}

.page-btn:disabled, .page-btn.disabled {
	opacity: .5;
	pointer-events: none
}
</style>

<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
	<jsp:include page="../../fragments/header.jsp"></jsp:include>
	<div class="wrap">
		<div class="title">인증 로그 기록</div>

		<!-- 상단 필터/검색 폼 -->
		<form method="get" class="toolbar" action="">
			<div class="group">
				<label for="q" class="label">검색</label> <input id="q" name="q"
					type="text" class="input" placeholder="사용자번호/사유 검색"
					value="${fn:escapeXml(param.q)}">
			</div>

			<div class="group">
				<label for="status" class="label">상태</label> <select id="status"
					name="status" class="select">
					<option value="" ${empty param.status ? 'selected' : ''}>전체</option>
					<option value="PASS" ${param.status == 'PASS' ? 'selected' : ''}>통과(PASS)</option>
					<option value="FAIL" ${param.status == 'FAIL' ? 'selected' : ''}>실패(FAIL)</option>
					<option value="REVIEW"
						${param.status == 'REVIEW' ? 'selected' : ''}>검토(REVIEW)</option>
				</select>
			</div>

			<div class="group">
				<label for="from" class="label">시작일</label> <input id="from"
					name="from" type="date" class="input"
					value="${fn:escapeXml(param.from)}" style="min-width: 160px">
			</div>
			<div class="group">
				<label for="to" class="label">종료일</label> <input id="to" name="to"
					type="date" class="input" value="${fn:escapeXml(param.to)}"
					style="min-width: 160px">
			</div>

			<div class="group" style="justify-content: flex-end;">
				<button type="submit" class="btn btn-primary">검색</button>
				<a class="btn btn-outline" href="">초기화</a>
				<c:set var="passOnlyOn" value="${param.status == 'PASS'}" />
				<a class="btn btn-outline ${passOnlyOn ? 'active' : ''}"
					href="?status=${passOnlyOn ? '' : 'PASS'}&q=${fn:escapeXml(param.q)}&from=${fn:escapeXml(param.from)}&to=${fn:escapeXml(param.to)}&size=${fn:escapeXml(param.size)}">
					통과만 보기 </a>
			</div>
		</form>

		<!-- 날짜 파싱 (to는 23:59:59 포함) -->
		<c:if test="${not empty param.from}">
			<fmt:parseDate value="${param.from}" pattern="yyyy-MM-dd"
				var="fromDate" />
		</c:if>
		<c:if test="${not empty param.to}">
			<fmt:parseDate value="${param.to} 23:59:59"
				pattern="yyyy-MM-dd HH:mm:ss" var="toDate" />
		</c:if>

		<!-- 페이지네이션 파라미터 (컨트롤러 수정 없이 JSP에서 처리) -->
		<fmt:parseNumber var="pageRaw" type="number"
			value="${empty param.page ? 1 : param.page}" />
		<fmt:parseNumber var="sizeRaw" type="number"
			value="${empty param.size ? 10 : param.size}" />
		<c:set var="pageSize"
			value="${sizeRaw <= 0 ? 10 : (sizeRaw > 200 ? 200 : sizeRaw)}" />
		<c:set var="currentPage" value="${pageRaw < 1 ? 1 : pageRaw}" />

		<!-- 1차 패스: 필터 통과 건수 total 계산 -->
		<c:set var="total" value="0" />
		<c:forEach var="log" items="${logs}">
			<c:set var="kw"
				value="${fn:toLowerCase(empty param.q ? '' : param.q)}" />
			<c:set var="userStr" value="${log.userNo}" />
			<c:set var="reasonStr" value="${empty log.reason ? '' : log.reason}" />
			<c:set var="logNoStr" value="${log.logNo}" />
			<c:set var="statusOk"
				value="${empty param.status or log.status == param.status}" />
			<c:set var="kwOk"
				value="${
              empty kw
              or fn:contains(fn:toLowerCase(userStr), kw)
              or fn:contains(fn:toLowerCase(reasonStr), kw)
              or fn:contains(fn:toLowerCase(logNoStr), kw)
           }" />
			<c:set var="fromOk"
				value="${empty fromDate or log.createdAt >= fromDate}" />
			<c:set var="toOk"
				value="${empty toDate   or log.createdAt <= toDate}" />
			<c:if test="${statusOk and kwOk and fromOk and toOk}">
				<c:set var="total" value="${total + 1}" />
			</c:if>
		</c:forEach>

		<!-- 페이지 계산 -->
		<fmt:parseNumber var="maxPage" type="number" integerOnly="true"
			value="${(total + pageSize - 1) / pageSize}" />
		<c:set var="maxPage" value="${maxPage < 1 ? 1 : maxPage}" />
		<c:set var="page"
			value="${currentPage > maxPage ? maxPage : currentPage}" />
		<c:set var="startIndex" value="${(page - 1) * pageSize + 1}" />
		<c:set var="endIndex" value="${page * pageSize}" />

		<!-- 본문 테이블 -->
		<div class="card">
			<table>
				<thead>
					<tr>
						<th style="width: 80px;">번호</th>
						<th style="width: 140px;">사용자</th>
						<th style="width: 120px;">상태</th>
						<th>사유</th>
						<th style="width: 200px;">시간</th>
					</tr>
				</thead>
				<tbody>
					<c:if test="${total == 0}">
						<tr>
							<td colspan="5" class="muted" style="padding: 20px;">조건에 맞는
								로그가 없습니다.</td>
						</tr>
					</c:if>

					<!-- 2차 패스: 필터 + 페이지 범위 내 행만 렌더 -->
					<c:set var="matchIdx" value="0" />
					<c:forEach var="log" items="${logs}">
						<c:set var="kw"
							value="${fn:toLowerCase(empty param.q ? '' : param.q)}" />
						<c:set var="userStr" value="${log.userNo}" />
						<c:set var="reasonStr"
							value="${empty log.reason ? '' : log.reason}" />
						<c:set var="logNoStr" value="${log.logNo}" />

						<c:set var="statusOk"
							value="${empty param.status or log.status == param.status}" />
						<c:set var="kwOk"
							value="${
                  empty kw
                  or fn:contains(fn:toLowerCase(userStr), kw)
                  or fn:contains(fn:toLowerCase(reasonStr), kw)
                  or fn:contains(fn:toLowerCase(logNoStr), kw)
               }" />
						<c:set var="fromOk"
							value="${empty fromDate or log.createdAt >= fromDate}" />
						<c:set var="toOk"
							value="${empty toDate   or log.createdAt <= toDate}" />

						<c:if test="${statusOk and kwOk and fromOk and toOk}">
							<c:set var="matchIdx" value="${matchIdx + 1}" />
							<c:if test="${matchIdx >= startIndex and matchIdx <= endIndex}">
								<tr>
									<td class="mono">${log.logNo}</td>
									<td class="mono"><span class="muted">#</span> <c:out
											value="${log.userNo}" /></td>
									<td><c:choose>
											<c:when test="${log.status == 'PASS'}">
												<span class="badge b-pass">PASS</span>
											</c:when>
											<c:when test="${log.status == 'FAIL'}">
												<span class="badge b-fail">FAIL</span>
											</c:when>
											<c:otherwise>
												<span class="badge b-review">REVIEW</span>
											</c:otherwise>
										</c:choose></td>
									<td><c:out value="${empty log.reason ? '—' : log.reason}" /></td>
									<td class="mono"><c:catch var="dateErr">
											<fmt:formatDate value="${log.createdAt}"
												pattern="yyyy-MM-dd HH:mm:ss" var="createdAtFmt" />
										</c:catch> <c:choose>
											<c:when test="${empty dateErr and not empty createdAtFmt}">${createdAtFmt}</c:when>
											<c:otherwise>
												<c:out value="${log.createdAt}" />
											</c:otherwise>
										</c:choose></td>
								</tr>
							</c:if>
						</c:if>
					</c:forEach>
				</tbody>
			</table>
		</div>

		<!-- 페이지네이션 -->
		<c:if test="${total > 0}">
			<div class="pagination">
				<c:set var="prev" value="${page-1}" />
				<c:set var="next" value="${page+1}" />

				<!-- begin/end window (최대 5개) -->
				<c:set var="beginPage" value="${page-2 < 1 ? 1 : page-2}" />
				<c:set var="endPage"
					value="${beginPage+4 > maxPage ? maxPage : beginPage+4}" />
				<c:set var="beginPage" value="${endPage-4 < 1 ? 1 : endPage-4}" />

				<a class="page-btn ${page == 1 ? 'disabled' : ''}"
					href="?page=1&size=${pageSize}&q=${fn:escapeXml(param.q)}&status=${fn:escapeXml(param.status)}&from=${fn:escapeXml(param.from)}&to=${fn:escapeXml(param.to)}">«</a>
				<a class="page-btn ${page == 1 ? 'disabled' : ''}"
					href="?page=${prev}&size=${pageSize}&q=${fn:escapeXml(param.q)}&status=${fn:escapeXml(param.status)}&from=${fn:escapeXml(param.from)}&to=${fn:escapeXml(param.to)}">‹</a>

				<c:forEach var="p" begin="${beginPage}" end="${endPage}">
					<a class="page-btn ${p == page ? 'current' : ''}"
						href="?page=${p}&size=${pageSize}&q=${fn:escapeXml(param.q)}&status=${fn:escapeXml(param.status)}&from=${fn:escapeXml(param.from)}&to=${fn:escapeXml(param.to)}">${p}</a>
				</c:forEach>

				<a class="page-btn ${page == maxPage ? 'disabled' : ''}"
					href="?page=${next}&size=${pageSize}&q=${fn:escapeXml(param.q)}&status=${fn:escapeXml(param.status)}&from=${fn:escapeXml(param.from)}&to=${fn:escapeXml(param.to)}">›</a>
				<a class="page-btn ${page == maxPage ? 'disabled' : ''}"
					href="?page=${maxPage}&size=${pageSize}&q=${fn:escapeXml(param.q)}&status=${fn:escapeXml(param.status)}&from=${fn:escapeXml(param.from)}&to=${fn:escapeXml(param.to)}">»</a>
			</div>
		</c:if>

		<div class="footer-note">
			• 검색어는 사용자번호/사유/번호(logNo)에서 찾습니다. 날짜는 당일 23:59:59까지 포함됩니다. • “통과만
			보기”는 버튼을 한 번 더 누르면 해제됩니다. • 페이지 크기는
			<code>size</code>
			파라미터로 제어(기본 10, 최대 200).
		</div>
	</div>
	<script src="/js/adminHeader.js"></script>
</body>
</html>
