<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>마이페이지</title>
<link rel="stylesheet" href="/css/style.css">
<style>

body {
  margin: 0;
  padding: 0;
  font-family: 'Segoe UI', sans-serif;
  background-color: #ffffff;
  color: #333;
  height: 100%;
}

html {
  height: 100%;
}

.wrapper {
  display: flex;
  flex-direction: column;
  min-height: 100vh;   /* 화면 높이 채우기 */
}

.main-content {
  flex: 1;             /* 남은 공간을 차지해서 푸터 밀어내기 */
  padding-top: 130px;
  margin: 0 auto;
  max-width: 1000px;
  padding-left: 20px;
  padding-right: 20px;
}

.page-section {
  margin-bottom: 30px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  border-bottom: 1px solid #ddd;
  padding-bottom: 10px;
}

.section-header .title {
  font-size: 1.4em;
  font-weight: bold;
  color: #222;
}

.section-header .title a {
  color: black;             /* 까만색으로 설정 */
  text-decoration: none;    /* 밑줄 제거 (원하는 경우) */
  font-weight: 500;
}

.section-header a {
  font-size: 0.95em;
  color: #0066cc;
  text-decoration: none;
}

.section-header a:hover {
  text-decoration: underline;
}

.section-header .title a:hover {
  text-decoration: underline;  /* 호버 시 밑줄 추가 (선택 사항) */
}

.card-box {
  padding: 30px;
  text-align: center;
  margin-bottom: 30px;
  background-color: #fff;
  border-radius: 10px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}

.card-container {
  display: flex;
  flex-wrap: wrap;
  gap: 24px;
  justify-content: center;
}

.card-list {
  display: flex;
  flex-direction: column;
  align-items: center;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.card-list:hover {
  transform: translateY(-4px);
}

.card-image {
  width: 160px;
  height: 100px;
  object-fit: cover;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  margin-bottom: 10px;
}

.card-name {
  font-size: 16px;
  font-weight: 600;
  color: #444;
  margin: 0;
  text-align: center;
}

</style>
</head>
<body>
	<div class="wrapper">
		<jsp:include page="/WEB-INF/views/fragments/mainheader2.jsp" />
		<div class="main-content">
			<div>
				<div class="section-header">
					<div class="title">내 카드</div>
					<a href="/user/editProfile">개인 정보 수정</a>
				</div>
				<div class="card-box highlight">
					<div class="card-container">
						<c:forEach var="card" items="${cards}">
							<div class="card-list">
								<img class="card-image" src="${card.cardUrl}">
								<p class="card-name">${card.cardName}</p>
							</div>
						</c:forEach>
					</div>
				</div>
			</div>
			<div>
				<div class="section-header">
					<div class="title">
						<a href="#">문의 내역</a>
					</div>
				</div>
			</div>
		</div>
		<jsp:include page="/WEB-INF/views/fragments/footer.jsp" />
	</div>
<script src="/js/header2.js"></script>
<script>
	let remainingSeconds = ${remainingSeconds};
</script>
<script src="/js/sessionTime.js"></script>
</body>
</html>