<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드 발급 - 연락처 입력</title>
</head>
<body>
	<h2>정보를 입력해 주세요.</h2>

	<form id="contactForm">
		
		<div class="form-group">
			<label for="email">이메일</label>
			<input type="email" id="email"
				name="email" placeholder="이메일" required>
		</div>

		<div class="form-group">
			<label for="phone">연락처</label> <input type="tel" id="phone"
				name="phone" placeholder="연락처"
				pattern="010-[0-9]{4}-[0-9]{4}" required>
		</div>

		<button type="submit" class="btn-submit">다음</button>
	</form>

	<script>
		// URL에서 applicationNo 가져오기
		const params = new URLSearchParams(window.location.search);
		const applicationNo = params.get('applicationNo');
		
		document.getElementById("contactForm").addEventListener("submit", async function(e) {
	    e.preventDefault();

	    const formData = {
	        applicationNo: applicationNo,
	        email: document.getElementById("email").value,
	        phone: document.getElementById("phone").value
	    };

	    try {
	    	const jwtToken = localStorage.getItem("jwtToken");
	    	
	        const response = await fetch("/card/apply/api/validateContact", {
	            method: "POST",
	            headers: {
	                "Content-Type": "application/json",
	                "Authorization": "Bearer " + jwtToken  // JWT 헤더 추가
	            },
	            body: JSON.stringify(formData)
	        });
	        const data = await response.json();
	        
	        if (data.success) {
	            // 다음 절차 페이지로 이동
	        	location.href = "/card/apply/jobInfo?applicationNo=" + encodeURIComponent(data.applicationNo);
	        } else {	        	
		        alert(data.message);
	        }
	    } catch (err) {
	        console.error(err);
	        alert("오류가 발생했습니다.");
	    }
	});
	</script>
</body>
</html>