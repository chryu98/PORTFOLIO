<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>

<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="/css/style.css">
<style>
.main-content {
  padding-top: 70px;
  margin: 0 30px;
}
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/fragments/mainheader2.jsp" />
<div class="main-content">
	<h1>은행소개</h1>
	<hr>
</div>
<jsp:include page="/WEB-INF/views/fragments/footer.jsp" />
<script src="/js/header2.js"></script>
<script>
	let remainingSeconds = ${remainingSeconds};
</script>
<script src="/js/sessionTime.js"></script>
</body>
</html>