<%@ page contentType="text/html; charset=UTF-8"%>
<html>
<head>
<title>FAQ 수정</title>
<link rel="stylesheet" href="/css/adminstyle.css">
<style>
body {
	background-color: #f9f9f9;
}

h2 {
	text-align: center;
	margin: 0 auto;
	padding-top: 40px;
	width: fit-content;
}

form {
	max-width: 600px;
	margin: 30px auto;
	padding: 30px;
	background-color: #fff;
	border-radius: 8px;
	box-shadow: 0 0 10px rgba(0, 0, 0, 0.08);
	display: flex;
	flex-direction: column;
	gap: 24px; /* div 사이 간격 */
}

.form-group {
	display: flex;
	align-items: center;
	gap: 16px;
}

.form-group label {
	width: 100px;
	font-weight: bold;
	color: #2c3e50;
}

.form-group input[type="text"], .form-group textarea {
	flex: 1;
	padding: 10px 12px;
	border: 1px solid #ccc;
	border-radius: 4px;
	font-size: 1rem;
	box-sizing: border-box;
	background-color: #fff;
	transition: border-color 0.3s ease, box-shadow 0.3s ease;
}

.form-group input[type="text"]:focus, .form-group textarea:focus {
	outline: none;
	border-color: #3498db;
	box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.15);
}

.form-group textarea {
	resize: vertical;
	min-height: 150px; /* 답변 입력창 크게 */
	line-height: 1.5;
	white-space: pre-wrap; /* 줄바꿈 유지 */
	font-family: 'Noto Sans KR', sans-serif;
}

.button-group {
	text-align: center;
	margin-top: 40px;
}

.button-group button {
	padding: 10px 20px;
	border: none;
	border-radius: 4px;
	font-size: 14px;
	cursor: pointer;
	margin: 0 8px;
}

.button-group button:first-child {
	background-color: #c10c0c;
	color: white;
}

.button-group button:first-child:hover {
	background-color: #9b0a0a;
}

.button-group button:last-child {
	background-color: #f2f2f2;
	color: #333;
}

.button-group button:last-child:hover {
	background-color: #dcdcdc;
}
</style>
</head>
<body>
	<jsp:include page="../../fragments/header.jsp"></jsp:include>

	<h2>FAQ 수정</h2>

	<form action="edit" method="post">
		<input type="hidden" name="faqNo" value="${faq.faqNo}">

		<div class="form-group">
			<label for="faqQuestion">질문</label> <input type="text"
				id="faqQuestion" name="faqQuestion" value="${faq.faqQuestion}">
		</div>

		<div class="form-group">
			<label for="faqAnswer">답변</label>
			<textarea id="faqAnswer" name="faqAnswer" oninput="autoResize(this)">${faq.faqAnswer}</textarea>
		</div>

		<div class="form-group">
			<label for="writer">작성자</label> <input type="text" id="writer"
				name="writer" value="${faq.writer}">
		</div>

		<div class="form-group">
			<label for="admin">관리자</label> <input type="text" id="admin"
				name="admin" value="${faq.admin}">
		</div>

		<div class="form-group">
			<label for="cattegory">카테고리</label>
			<div style="display: flex; gap: 20px;">
				<label> <input type="radio" name="cattegory" value="카드"
					${faq.cattegory == '카드' ? 'checked' : ''}> 카드
				</label> <label> <input type="radio" name="cattegory" value="예적금"
					${faq.cattegory == '예적금' ? 'checked' : ''}> 예적금
				</label>
			</div>
		</div>

		<div class="button-group">
			<button type="submit">수정</button>
			<button type="button" onclick="history.back()">취소</button>
		</div>
	</form>

	<script src="/js/adminHeader.js"></script>
	<script>
	    function autoResize(textarea) {
	        textarea.style.height = "auto"; // 높이 초기화
	        textarea.style.height = textarea.scrollHeight + "px"; // 내용만큼 높이 조절
	    }
	    
		window.addEventListener("DOMContentLoaded", () => {
		    const textarea = document.getElementById("faqAnswer");
		    if (textarea) autoResize(textarea); // 초기값에도 적용
		});

</script>
</body>
</html>