<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>

<html>
<head>
    <title>인증 로그</title>
</head>
<body>
<h2>인증 로그 기록</h2>

<table border="1" cellpadding="5" cellspacing="0">
  <tr>
    <th>번호</th>
    <th>사용자</th>
    <th>상태</th>
    <th>사유</th>
    <th>시간</th>
  </tr>
  <c:forEach var="log" items="${logs}">
    <tr>
      <td>${log.logNo}</td>
      <td>${log.userNo}</td>
      <td>${log.status}</td>
      <td>${log.reason}</td>
      <td><fmt:formatDate value="${log.createdAt}" pattern="yyyy-MM-dd HH:mm:ss"/></td>
    </tr>
  </c:forEach>
</table>

</body>
</html>
