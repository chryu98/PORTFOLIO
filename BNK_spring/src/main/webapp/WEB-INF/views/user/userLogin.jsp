<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>로그인</title>
<link rel="stylesheet" href="/css/style.css">
<style>
.login-content {
  padding-top: 130px;
  max-width: 360px;
  margin: 0 auto;
  font-family: 'Noto Sans KR', 'Malgun Gothic', Arial, sans-serif;
}

.login-content h1 {
  font-size: 1.6rem;
  margin-bottom: 8px;
  text-align: center;
  color: #333;
  font-weight: 700;
}

.login-content hr {
  border: none;
  border-top: 3px solid #c10c0c;
  margin-bottom: 30px;
}

.login-content form {
  display: flex;
  flex-direction: column;
  gap: 6px; /* 입력창 사이 간격 적당히 좁게 */
}

.login-content input[type="text"],
.login-content input[type="password"] {
  padding: 14px 12px;
  font-size: 1.1rem;
  font-weight: 500;
  border: 1px solid #ccc;  /* 얇은 테두리 */
  border-radius: 0;
  box-sizing: border-box;
  transition: border-color 0.25s ease, box-shadow 0.25s ease;
}

.login-content input[type="text"]:focus,
.login-content input[type="password"]:focus {
  border-color: #c10c0c;
  outline: none;
  box-shadow: 0 0 6px rgba(193, 12, 12, 0.3); /* 은은한 그림자 */
}

.login-content button {
  padding: 16px 14px;
  margin-top: 8px;
  background-color: #c10c0c;
  color: white;
  font-weight: 700;
  font-size: 1.15rem;
  border: none;
  border-radius: 0;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.login-content button:hover {
  background-color: #9a0808;
}

.login-content div {
  margin-top: 22px;
  text-align: center;
  font-size: 0.95rem;
  color: #555;
  font-weight: 400;
}

.login-content a {
  color: #c10c0c;
  font-weight: 600;
  margin-left: 6px;
  text-decoration: none;
}

.login-content a:hover {
  text-decoration: underline;
}

.login-content input::placeholder {
  font-size: 0.9rem;
  color: #b2b2b2;
  font-weight: 400;
}

</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/fragments/mainheader2.jsp" />
<div class="login-content">
	<h1 class="login-title">로그인</h1>
	<hr>
	<form onsubmit="event.preventDefault(); login();">
		<input type="text" id="username" name="username" placeholder="아이디를 입력하세요.">
		<input type="password" id="password" name="password" placeholder="비밀번호를 입력하세요.">
		<button type="submit">로그인</button>
	</form>
	
	<div class="signup-link">
		<span>아직 회원이 아니신가요?</span>
		<a href="/user/regist/selectMemberType">회원가입</a>
	</div>
</div>
<c:if test="${not empty msg}">
	    <script>alert("${msg}");</script>
</c:if>
<script>
	async function login() {
		const username = document.getElementById("username").value;
		const password = document.getElementById("password").value;

		if (!username || !password) {
			alert("아이디와 비밀번호를 모두 입력해주세요.");
			return;
		}
		
		try {
			const response = await fetch("/user/api/login", {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({ username, password }),
			});
	
			const result = await response.json();
			
			if (response.ok) {
				// 핵심: 로그인 성공 시 토큰을 localStorage에 저장
	            if (result.token) {
	            	
	                localStorage.setItem('jwtToken', result.token);
	                localStorage.setItem('memberNo', result.memberNo);
	                // 토큰 저장 후 원하는 페이지로 이동
	                location.href = "/"; 
	            } else {
	                alert("로그인에 성공했지만, 토큰을 받지 못했습니다. 다시 시도해주세요.");
	            }
			} else {
				// 로그인 실패 시 서버에서 보낸 메시지를 알림
				alert(result.message);
				document.getElementById("username").value = "";
				document.getElementById("password").value = "";
			}
		} catch (error) {
			console.error("로그인 중 오류 발생:", error);
			alert("서버와 통신 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.");
		}
	}

</script>
<script src="/js/header2.js"></script>
</body>
</html>