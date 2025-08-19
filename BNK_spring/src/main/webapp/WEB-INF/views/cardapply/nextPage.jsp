<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

<script>
//URL에서 applicationNo 가져오기
const params = new URLSearchParams(window.location.search);
const applicationNo = params.get('applicationNo');
</script>
</body>
</html>