<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>회원가입 - 회원유형 선택</title>
<link rel="stylesheet" href="/css/style.css">
<link
	href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR&display=swap"
	rel="stylesheet">
<style>
body {
	font-family: "맑은 고딕", sans-serif;
	/*background-color: #f5f7fa;*/
	margin: 0;
	padding: 0;
}

/* 전체 wrapper */
.container {
	max-width: 800px;
	margin: 0 auto;
	padding: 90px 30px 60px; /* header 공간 포함 */
}

/* 제목 및 부제목 */
.page-title {
	font-size: 20px;
	font-weight: 600;
	color: #333;
	margin-bottom: 6px;
}

.page-subtitle {
	font-size: 14px;
	color: #777;
	margin-bottom: 30px;
}

.divider-section {
    border-top: 1px solid #ddd;
    padding-top: 20px;
    margin-top: 20px;
    margin-bottom: 30px;
}

/* 유형 선택 카드들 */
.member-type-container {
	display: flex;
	justify-content: flex-start;
	gap: 20px;
	flex-wrap: wrap;
	align-items: stretch; /* 높이 통일 핵심 */
}

/* 각 카드 스타일 */
.member-type {
	flex: 1;
	min-width: 200px;
	max-width: 300px;
	height: 100%; /* form 내부에서 꽉 채우기 */
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: center;
	background-color: #fff;
	border: 1px solid #ddd;
	border-radius: 16px;
	padding: 24px;
	text-align: center;
	text-decoration: none;
	color: #000;
	transition: all 0.3s ease;
	box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
	cursor: pointer;
}

.member-type:hover {
	border-color: #005bac;
	box-shadow: 0 4px 12px rgba(0, 91, 172, 0.15);
	transform: translateY(-4px);
}

.member-type .title {
  font-size: 18px;
  font-weight: 600;
  color: #005bac;
  margin-bottom: 16px;
  position: relative;
  padding-bottom: 10px;
  border-bottom: 1px solid #e0e0e0;
}

.member-type .desc {
  font-size: 14px;
  color: #555;
  line-height: 1.5;
  margin-top: 12px;
}

</style>
</head>
<body>
	<jsp:include page="/WEB-INF/views/fragments/mainheader2.jsp" />

	<div class="container">
		<h2 class="page-title">회원가입</h2>
		<p class="page-subtitle">회원유형을 선택해 주세요</p>
		<div class="divider-section">
			<div class="member-type-container">
				<button type="button" class="member-type" onclick="selectMemberType('ROLE_PERSON')">
					<div class="title">일반회원(개인)</div>
					<div class="desc">
						영업점 방문 없이 홈페이지에서<br>간편하게 신청 가능합니다
					</div>
				</button>
				
				<button type="button" class="member-type" onclick="selectMemberType('ROLE_OWNER')">
					<div class="title">개인사업자</div>
					<div class="desc">
						사업체를 운영하는 개인 고객을<br>위한 전용 서비스입니다
					</div>
				</button>
				
				<button type="button" class="member-type" onclick="selectMemberType('ROLE_CORP')">
					<div class="title">법인</div>
					<div class="desc">
						법인 사업체를 위한<br>신뢰도 높은 금융 솔루션 제공
					</div>
				</button>
			</div>
		</div>
	</div>
<script src="/js/header2.js"></script>
<script>
	async function selectMemberType(role) {
	    const response = await fetch("/user/api/regist/selectMemberType", {
	        method: "POST",
	        headers: {
	            "Content-Type": "application/json"
	        },
	        body: JSON.stringify({ role })
	    });
	
	    const result = await response.json();

	    if (result.message) {
	        alert(result.message);
	    }

	    if (result.redirectUrl) {
	        location.href = result.redirectUrl;
	    }
	    else if (!result.message) {
	        alert("알 수 없는 오류가 발생했습니다.");
	    }
	}
</script>
</body>
</html>
