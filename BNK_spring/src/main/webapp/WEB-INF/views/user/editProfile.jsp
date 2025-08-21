<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>내 정보 수정</title>
<link rel="stylesheet" href="/css/style.css">
<style>
body {
    font-family: "맑은 고딕", sans-serif;
    background-color: #fff;
    color: #333;
    margin: 0;
    padding: 0;
}

.content-wrapper {
    max-width: 800px;
    margin: 0 auto;
    padding: 90px 30px 60px;
}

.page-title {
    font-size: 20px;
    font-weight: 600;
    color: #333;
    margin-bottom: 6px;
    text-align: left;
}

.sub-title {
    font-size: 14px;
    color: #777;
    margin-bottom: 30px;
    text-align: left;
}

.divider-section {
    border-top: 1px solid #ddd;
    padding-top: 20px;
    margin-top: 20px;
    margin-bottom: 30px;
}

form {
    width: 100%;
    max-width: 800px;
    margin: 0 auto;
}

table {
    width: 100%;
    border-collapse: collapse;
    font-size: 14px;
}

th {
    text-align: left;
    vertical-align: top;
    padding: 12px 10px 8px;
    width: 140px;
    font-weight: 600;
    color: #222;
    white-space: nowrap;
}

td {
    padding: 8px 10px;
}

td span {
    white-space: nowrap;
}

input[type="text"],
input[type="password"] {
    width: 100%;
    max-width: 300px;
    padding: 8px;
    border: 1px solid #ccc;
    border-radius: 0;
    font-size: 14px;
    box-sizing: border-box;
}

input[readonly] {
    background-color: #f9f9f9;
    color: #666;
}

span {
    font-size: 12px;
    color: #777;
    margin-left: 6px;
}

.zipcode-wrapper {
    display: flex;
    gap: 8px;
    align-items: center;
}

.zipcode-wrapper input[type="text"] {
    flex: 1;
}

.zipcode-wrapper input[type="button"] {
    padding: 8px 12px;
    font-size: 13px;
    background-color: #c10c0c;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    white-space: nowrap;
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
    margin: 0 10px;
}

.button-group button:first-child {
    background-color: #c10c0c;
    color: white;
}

.button-group button:last-child {
    background-color: #f2f2f2;
    color: #333;
}

input::placeholder {
    font-size: 13px;
    color: #aaa;
}

.input-with-guide {
    display: flex;
    align-items: center;
    gap: 10px; /* 입력창과 문장 사이 여백 */
}

.input-with-guide span {
    white-space: nowrap;
    font-size: 12px;
    color: #777;
}

</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/fragments/mainheader2.jsp" />

<div class="content-wrapper">
	<h2 class="page-title">회원정보 수정</h2>
    <p class="sub-title">수정할 정보를 입력해 주세요</p>
    
    <div class="divider-section">
		<form id="updateForm" action="/user/update" method="post">
			<table>
				<tr>
					<th>성명(실명)</th>
					<td><input type="text" name="name" id="name" value="${loginUser.name}" readonly></td>
				</tr>
				<tr>
					<th>아이디</th>
					<td><input type="text" name="username" id="username" value="${loginUser.username}" readonly></td>
				</tr>
				<tr>
					<th>새 비밀번호</th>
					<td>
						<input type="password" name="password" id="password" onblur="validatePassword()">
						<span> ※ 영문자, 숫자, 특수문자 포함 8~12자 이내 (영문, 숫자, 특수문자 조합)</span>
					</td>
				</tr>
				<tr>
					<th>새 비밀번호 확인</th>
					<td>
						<input type="password" name="passwordCheck" id="passwordCheck" onblur="checkPasswordMatch()">
						<span> ※ 비밀번호 재입력</span>
						<div id="pwErrorMsg"></div>
					</td>
				</tr>
				<tr>
					<th>주소</th>
					<td>
						<div class="zipcode-wrapper">
							<input type="text" name="zipCode" id="zipCode" value="${loginUser.zipCode}" readonly>
							<input type="button" onclick="sample6_execDaumPostcode()" value="우편번호 찾기"><br>
						</div>
						<input type="text" name="address1" id="address1" value="${loginUser.address1}" readonly><br>
						<input type="text" name="extraAddress" id="extraAddress" readonly><br>
						<input type="text" name="address2" id="address2" placeholder="상세주소" value="${loginUser.address2}">
					</td>
				</tr>
			</table>
			<input type="hidden" name="role" value="${role}">
			<div class="button-group">
				<button type="button" onclick="editProfile()">수정</button>
				<button type="button" onclick="cancelEdit()">취소</button>
			</div>
		</form>
	</div>
	
	<c:if test="${not empty msg}">
	    <script>
	        alert("${msg}");
	    </script>
	</c:if>
</div>
<script src="/js/header2.js"></script>
<script>
	let remainingSeconds = ${remainingSeconds};

	//비밀번호 유효성 검사
	function isPasswordValid(password){
		const pwRegex = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()_+[\]{}|\\;:'",.<>?/`~\-]).{8,12}$/;
		return pwRegex.test(password);
	}
	
	function validatePassword(){
		const oldPw = "${loginUser.password}";
		const password = document.getElementById("password");
		const pwErrorMsg = document.getElementById("pwErrorMsg");
		
		if(!password.value.trim()){
			pwErrorMsg.textContent = "";
			return;
		}

		if(oldPw === password.value){
			pwErrorMsg.textContent = "현재 비밀번호와 일치합니다.";
		    pwErrorMsg.style.color = "red";
		    password.focus();
		    return;
		}
		
		if(!isPasswordValid(password.value)){
			pwErrorMsg.textContent = "비밀번호는 영문자, 숫자, 특수문자를 포함한 8~12자리여야 합니다.";
		    pwErrorMsg.style.color = "red";
		    password.focus();
		}
		else{
			pwErrorMsg.textContent = "사용가능한 비밀번호입니다.";	
			pwErrorMsg.style.color = "green";
		}
	}
	//비밀번호 확인
	function checkPasswordMatch(){
		const password = document.getElementById("password");
		const passwordCheck = document.getElementById("passwordCheck");
		const pwErrorMsg = document.getElementById("pwErrorMsg");
		
		if (!passwordCheck.value.trim()) {
			pwErrorMsg.textContent = "";
		    return;
		}
		if (password.value === passwordCheck.value) {
			pwErrorMsg.textContent = "비밀번호가 일치합니다.";
		    pwErrorMsg.style.color = "green";
		}
		else {
			pwErrorMsg.textContent = "비밀번호가 일치하지 않습니다.";
		    pwErrorMsg.style.color = "red";
		    passwordCheck.focus();
		}
	}
	
	//수정 버튼
	function editProfile(){
	    const form = document.getElementById("updateForm");
	    
	    const password = document.getElementById("password");
	    const passwordCheck = document.getElementById("passwordCheck");
	
	    if(password.value.trim()){
	        if(!passwordCheck.value.trim()){
	            alert("비밀번호를 확인하세요.");
	            passwordCheck.focus();
	            return;
	        }
	        if(!isPasswordValid(password.value)){
	            pwErrorMsg.textContent = "비밀번호는 영문자, 숫자, 특수문자를 포함한 8~12자리여야 합니다.";
	            pwErrorMsg.style.color = "red";
	            password.focus();
	            return;
	        }
	    }
	
	    if(!document.getElementById("zipCode").value.trim() || !document.getElementById("address1").value.trim()) {
	        alert("주소를 입력해주세요.");
	        document.getElementById("zipCode").focus();
	        return;
	    }
	    if(!document.getElementById("address2").value.trim()){            
	        alert("상세주소를 입력해주세요.");
	        document.getElementById("address2").focus();
	        return;
	    }
	
	    const formData = new FormData(form);
	    const jwtToken = localStorage.getItem("jwtToken");
	    
	    fetch('/user/api/update', {
	        method: 'POST',
	        headers: {
                "Authorization": "Bearer " + jwtToken  // JWT 헤더 추가
            },
            body: formData
	    })
	    .then(res => {
		    if (!res.ok) return res.text().then(text => { throw new Error(text); });
		    return res.json();
		})
	    .then(data => {
	        alert(data.msg);
	        if(data.success){
	            location.href = "/user/mypage";
	        }
	    })
	    .catch(err => console.error(err));
	}

	
	//취소버튼
	function cancelEdit(){
		if (confirm("정보 수정을 취소하겠습니까?")) {
	        location.href = "/user/mypage";
	    }
	}
</script>

<script src="/js/sessionTime.js"></script>
<script src="//t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script src="/js/postcode.js"></script>
</body>
</html>