<%@ page contentType="text/html; charset=UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<html>
<head>
<title>FAQ 목록</title>
<link rel="stylesheet" href="/css/adminstyle.css">
<style>
body {
	background-color: #f9f9f9;
}

h2 {
	text-align: center;
	margin: 40px auto 30px auto;
	width: fit-content;
}

.admin-content-wrapper {
	display: flex;
	justify-content: center;
	padding: 0 200px;
	box-sizing: border-box;
	margin-bottom: 40px;
}

.faq-table {
	width: 100%;
	border-collapse: separate;
	border-spacing: 0;
	border: 1px solid #dee2e6;
	border-radius: 6px;
	overflow: hidden;
	font-size: 14px;
	background-color: #f8f9fa;
	color: #212529;
	table-layout: auto;
}

.faq-table thead {
	background-color: #f1f3f5;
}

.faq-table thead th {
	padding: 14px;
	text-align: center;
	font-weight: 700;
	color: #212529;
	border-right: 1px solid #dee2e6;
}

.faq-table thead th:last-child {
	border-right: none;
}

.faq-table tbody td {
	padding: 14px;
	text-align: center;
	background-color: #ffffff;
	border-top: 1px solid #dee2e6;
	border-right: 1px solid #dee2e6;
	word-wrap: break-word;
}

.faq-table tbody td:last-child {
	border-right: none;
}

.faq-table tbody td:nth-child(2), .faq-table tbody td:nth-child(3) {
	text-align: left;
	white-space: normal; /* 줄바꿈 허용 */
	word-break: break-word; /* 단어 중간도 줄바꿈 */
}

/* 번호 열(th, td)에 고정 너비 + 줄바꿈 방지 */
.faq-table thead th:nth-child(1), .faq-table tbody td:nth-child(1) {
	width: 60px;
	white-space: nowrap;
}

.faq-table thead th:nth-child(4), .faq-table tbody td:nth-child(4) {
	min-width: 80px;
	text-align: center;
}

.faq-table thead tr:first-child th:first-child {
	border-top-left-radius: 6px;
}

.faq-table thead tr:first-child th:last-child {
	border-top-right-radius: 6px;
}

.faq-table tbody tr:last-child td:first-child {
	border-bottom-left-radius: 6px;
}

.faq-table tbody tr:last-child td:last-child {
	border-bottom-right-radius: 6px;
}

/* 검색 폼 */
form {
	display: flex;
	justify-content: center;
	align-items: center;
	gap: 10px; /* 입력창과 버튼 사이 간격 */
	margin-bottom: 24px;
}

form input[type="text"] {
	padding: 10px 12px;
	border: 1px solid #ccc;
	border-radius: 6px;
	width: 260px;
	font-size: 14px;
}

form button {
	padding: 10px 18px;
	background-color: #c22800;
	color: white;
	border: none;
	border-radius: 6px;
	font-size: 14px;
	cursor: pointer;
	transition: background-color 0.2s ease;
}

form button:hover {
	background-color: #a31d00;
}

/* 등록 버튼 */
.faq-insert-btn {
  padding: 10px 18px;
  background-color: #f0f0f0;
  color: #000000;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  text-decoration: none;
  display: inline-block;
}

.faq-insert-btn:hover {
  background-color: #333;
  color: #fff;
}

/* 관리 링크 */
td a {
	margin: 0 6px;
	color: #c22800;
	text-decoration: none;
}

td a:hover {
	text-decoration: underline;
}

/* 페이징 */
.pagination {
	text-align: center;
	margin-top: 40px;
	font-size: 1rem;
}

.pagination a, .pagination strong {
	display: inline-block;
	margin: 0 5px;
	color: #555;
	text-decoration: none;
}

.pagination a:hover {
	font-weight: bold;
	color: #000;
}

.pagination strong {
	color: #e74c3c;
}

#noDataMessage {
	text-align: center;
	color: #999;
	font-size: 1.1em;
	margin-top: 10px;
}

.inner {
	text-align: left; /* 필요하다면 */
}

.btn-wrapper {
	display: flex;
	justify-content: flex-end; /* 오른쪽 정렬 */
	margin-bottom: 16px; /* 버튼과 위아래 간격 */
	width: 100%;
}
</style>
</head>
<body>
	<jsp:include page="../../fragments/header.jsp"></jsp:include>

	<div class="admin-content-wrapper">
		<div class="inner">
			<h2>FAQ 목록</h2>

			<form method="get"
				action="${pageContext.request.contextPath}/admin/faq/list">
				<input type="text" name="keyword" placeholder="검색어 입력"
					value="${keyword}">
				<button type="submit">검색</button>
			</form>

			<div class="btn-wrapper">
				<a href="${pageContext.request.contextPath}/admin/faq/insertForm"
					class="faq-insert-btn">FAQ 등록</a>
			</div>

			<c:choose>
				<c:when test="${empty faqList}">
					<div id="noDataMessage">등록된 FAQ가 없습니다.</div>
				</c:when>
				<c:otherwise>
					<table class="faq-table">
						<thead>
							<tr>
								<th>번호</th>
								<th>질문</th>
								<th>답변</th>
								<th>관리</th>
							</tr>
						</thead>
						<tbody>
							<c:forEach var="faq" items="${faqList}">
								<tr>
									<td>${faq.faqNo}</td>
									<td>${faq.faqQuestion}</td>
									<td>${faq.faqAnswer}</td>
									<td><a
										href="${pageContext.request.contextPath}/admin/faq/editForm?faqNo=${faq.faqNo}">수정</a>
										<a
										href="${pageContext.request.contextPath}/admin/faq/delete?faqNo=${faq.faqNo}">삭제</a>
									</td>
								</tr>
							</c:forEach>
						</tbody>
					</table>
				</c:otherwise>
			</c:choose>

			<div class="pagination">
				<c:forEach var="i" begin="1" end="${totalPage}">
					<c:choose>
						<c:when test="${i == currentPage}">
							<strong>[${i}]</strong>
						</c:when>
						<c:otherwise>
							<a
								href="${pageContext.request.contextPath}/admin/faq/list?keyword=${keyword}&page=${i}">
								[${i}] </a>
						</c:otherwise>
					</c:choose>
				</c:forEach>
			</div>
		</div>
	</div>

	<script src="/js/adminHeader.js"></script>
</body>
</html>
