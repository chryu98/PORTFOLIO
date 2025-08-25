<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<%@ taglib uri="http://www.springframework.org/tags/form" prefix="form" %>

<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>영업점 관리</title>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <style>
:root{
  /* 피드백 대시보드 팔레트 */
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
  /* 효과 */
  --shadow:0 6px 18px rgba(17,24,39,.06);
  --ring:0 0 0 3px rgba(59,130,246,.18);
}

*{ box-sizing:border-box }

body{
  font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, "Apple SD Gothic Neo", "Malgun Gothic", sans-serif;
   color:var(--txt); background:var(--bg);
}

h1{ font-size:28px; margin:0 0 12px; font-weight:700 }

.container{ max-width:1080px; margin:0 auto; display:flex; flex-direction:column }

/* 공통 카드 느낌 */
form, table, .pagination, .search{
  width:100%; max-width:1100px;
  background:var(--card);
  border:1px solid var(--line);
  border-radius:12px;
  box-shadow:var(--shadow);
}

/* 검색 바 = 피드백 페이지의 filters 톤 */
.search{
  display:flex; gap:10px; align-items:center;
  padding:10px; margin:0 0 16px;
  background:var(--card);
}
.search input[type="text"]{
  flex:1; min-width:120px; height:38px; padding:0 12px;
  border:1px solid var(--line); border-radius:8px; outline:none; background:#fff;
}
.search input[type="text"]:focus{ box-shadow:var(--ring); border-color:var(--accent) }

/* 폼 레이아웃 */
#dto{ padding:20px; margin-bottom:24px }
.row{ display:flex; gap:12px; flex-wrap:wrap; padding:14px }
.row > *{ flex:1; min-width:240px }
label{ display:block; font-size:12px; color:var(--muted); margin:2px 0 6px }
input[type="text"], input[type="number"]{
  width:100%; height:38px; padding:0 12px;
  border:1px solid var(--line); border-radius:8px; outline:none; background:#fff;
}
input[type="text"]:focus, input[type="number"]:focus{ box-shadow:var(--ring); border-color:var(--accent) }
.error{ color:#b91c1c; font-size:12px; margin-top:6px }

/* 버튼 (대시보드 톤) */
.btn{
  display:inline-flex; align-items:center; justify-content:center;
  height:38px; padding:0 12px; gap:6px;
  border:1px solid var(--line); border-radius:8px;
  background:#fff; color:var(--txt); cursor:pointer; text-decoration:none; transition:.15s ease;
}
.btn:hover{ transform:translateY(-1px); box-shadow:var(--shadow) }
.btn:focus-visible{ outline:none; box-shadow:var(--ring) }
.btn.primary{
  background:var(--accent); color:#fff; border-color:var(--accent); min-width:96px;
}
.btn.primary:hover{ filter:brightness(.95) }
.btn.disabled{ pointer-events:none; opacity:.5 }
.insert-btn{ display:flex; justify-content:center }

/* 삭제 버튼을 연한 경고톤으로 */
.actions .btn{
  background:#fff5f5; color:#7f1d1d; border-color:#f5c2c7; width:100%;
}
.actions .btn:hover{ background:#fee2e2 }

/* 테이블 (대시보드 톤) */
table{
  border-collapse:separate; border-spacing:0; overflow:hidden;
  background:#fff; border:1px solid var(--line); border-radius:12px;
}
thead th{
  background:#fafbfc; text-align:left; font-weight:700;
  border-bottom:1px solid var(--line);
  padding:12px 10px; font-size:14px; color:var(--txt);
}
tbody td{
  padding:12px 10px; border-bottom:1px solid var(--line);
  vertical-align:top; font-size:14px; color:var(--txt);
}
tbody tr:last-child td{ border-bottom:none }
tbody tr:hover{ background:#fdfefe }

/* 페이지네이션 (대시보드 톤) */
.pagination{
  padding:10px 12px; display:flex; gap:8px; align-items:center; margin-top:12px;
  background:var(--card); border:1px solid var(--line); border-radius:12px;
}
.pagination span{ font-size:14px; color:var(--muted) }
.pages{ display:inline-flex; gap:6px; margin-left:8px }

/* 반응형 */
@media (max-width: 768px){
  .row{ padding:10px }
  thead th:nth-child(4), tbody td:nth-child(4){ white-space:nowrap } /* 전화 컬럼 좁힘 */
}
</style>

<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
<jsp:include page="../fragments/header.jsp"></jsp:include>
<div class="container">
  <h1>영업점 관리</h1>

  <!-- 검색 -->
  <form action="${pageContext.request.contextPath}/admin/branches" method="get" class="search">
    <input type="text" name="q" placeholder="지점명/주소 검색" value="${q}">
    <input type="hidden" name="page" value="1">
    <button class="btn">검색</button>
  </form>

  <!-- 등록 폼 (Spring Form 바인딩) -->
  <form:form action="${pageContext.request.contextPath}/admin/branches" method="post" modelAttribute="dto">
    <c:if test="${not empty _csrf}">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
    </c:if>

    <div class="row">
      <div>
        <label>지점명</label>
        <form:input path="branchName" maxlength="100" required="required"/>
        <div class="error"><form:errors path="branchName"/></div>
      </div>
      <div>
        <label>전화번호</label>
        <form:input path="branchTel" maxlength="20" placeholder="051-xxx-xxxx"/>
        <div class="error"><form:errors path="branchTel"/></div>
      </div>
    </div>

    <div class="row">
      <div>
        <label>주소</label>
        <form:input path="branchAddress" maxlength="200" required="required" placeholder="부산광역시 ..." />
        <div class="error"><form:errors path="branchAddress"/></div>
      </div>
    </div>

    <div class="row">
      <div>
        <label>위도(LATITUDE)</label>
        <!-- 필요 시 step 조정 -->
        <form:input path="latitude" type="number" step="0.0000001" placeholder="미입력 시 주소로 자동 보정"/>
      </div>
      <div>
        <label>경도(LONGITUDE)</label>
        <form:input path="longitude" type="number" step="0.0000001" placeholder="미입력 시 주소로 자동 보정"/>
      </div>
    </div>

    <div class="insert-btn" style="margin-top:10px;">
      <button class="btn primary" type="submit">등록</button>
    </div>
  </form:form>

  <!-- 목록 -->
  <table>
    <thead>
      <tr>
        <th style="width:90px;">번호</th>
        <th>지점명</th>
        <th>주소</th>
        <th style="width:140px;">전화</th>
        <th style="width:170px;">좌표</th>
        <th style="width:120px;">관리</th>
      </tr>
    </thead>
    <tbody>
      <c:choose>
        <c:when test="${not empty paged.items}">
          <c:forEach var="b" items="${paged.items}">
            <tr>
              <td><c:out value="${b.branchNo}"/></td>
              <td><c:out value="${b.branchName}"/></td>
              <td><c:out value="${b.branchAddress}"/></td>
              <td><c:out value="${b.branchTel}"/></td>
              <td>
                <c:out value="${b.latitude}"/>, <c:out value="${b.longitude}"/>
              </td>
              <td class="actions">
                <form action="${pageContext.request.contextPath}/admin/branches/${b.branchNo}/delete" method="post"
                      onsubmit="return confirm('삭제하시겠습니까?')">
                  <c:if test="${not empty _csrf}">
                    <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
                  </c:if>
                  <input type="hidden" name="q" value="${q}">
                  <input type="hidden" name="page" value="${paged.page}">
                  <input type="hidden" name="size" value="${paged.size}">
                  <button class="btn" type="submit">삭제</button>
                </form>
              </td>
            </tr>
          </c:forEach>
        </c:when>
        <c:otherwise>
          <tr>
            <td colspan="6" style="text-align:center;color:#6b7280;">데이터가 없습니다.</td>
          </tr>
        </c:otherwise>
      </c:choose>
    </tbody>
  </table>

  <!-- 페이지네이션 -->
  <c:if test="${paged.total > 0}">
  <div class="pagination">
    <span>총 ${paged.total}건 / ${paged.totalPages}페이지</span>

    <div style="margin-left:auto; display:flex; gap:6px; align-items:center;">

      <!-- 이전 링크 -->
      <c:set var="prevPage" value="${paged.page - 1}" />
      <c:url var="prevUrl" value="/admin/branches">
        <c:param name="q" value="${q}" />
        <c:param name="page" value="${prevPage}" />
        <c:param name="size" value="${paged.size}" />
      </c:url>
      <a class="btn ${paged.page <= 1 ? 'disabled' : ''}"
         href="${paged.page <= 1 ? '#' : prevUrl}"
         aria-disabled="${paged.page <= 1}">이전</a>

      <!-- 숫자 페이지 -->
      <div class="pages">
        <c:forEach var="p" begin="1" end="${paged.totalPages}">
          <c:url var="pageUrl" value="/admin/branches">
            <c:param name="q" value="${q}" />
            <c:param name="page" value="${p}" />
            <c:param name="size" value="${paged.size}" />
          </c:url>
          <a class="btn ${p == paged.page ? 'primary' : ''}" href="${pageUrl}">${p}</a>
        </c:forEach>
      </div>

      <!-- 다음 링크 -->
      <c:set var="nextPage" value="${paged.page + 1}" />
      <c:url var="nextUrl" value="/admin/branches">
        <c:param name="q" value="${q}" />
        <c:param name="page" value="${nextPage}" />
        <c:param name="size" value="${paged.size}" />
      </c:url>
      <a class="btn ${paged.page >= paged.totalPages ? 'disabled' : ''}"
         href="${paged.page >= paged.totalPages ? '#' : nextUrl}"
         aria-disabled="${paged.page >= paged.totalPages}">다음</a>

    </div>
  </div>
</c:if>
</div>
<script src="/js/adminHeader.js"></script>
</body>
</html>
