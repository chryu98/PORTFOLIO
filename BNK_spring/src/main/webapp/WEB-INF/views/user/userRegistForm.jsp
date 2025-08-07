<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>회원가입 - 정보입력</title>
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

.id-check-wrapper,
.zipcode-wrapper {
    display: flex;
    gap: 8px;
    align-items: center;
}

.id-check-wrapper input,
.zipcode-wrapper input[type="text"] {
    flex: 1;
}

.id-check-wrapper button,
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

#idErrorMsg,
#pwErrorMsg {
    color: red;
    font-size: 13px;
    margin-top: 4px;
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

</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/fragments/mainheader2.jsp" />

<div class="content-wrapper">
	<h2 class="page-title">회원가입</h2>
	<p class="sub-title">정보를 입력해 주세요.</p>

	<div class="divider-section">
		<table>
			<tr>
				<th>성명(실명)</th>
				<td><input type="text" name="name" id="name"></td>
			</tr>
			<tr>
				<th>아이디</th>
				<td>
					<div class="id-check-wrapper">
						<input type="text" name="username" id="username" onchange="resetUsernameCheck()" oninput="resetUsernameCheck()">
						<button type="button" id="checkBtn" onclick="checkUsername()">중복확인</button>
					</div>
				</td>
			</tr>
			<tr>
				<th></th>
				<td><div id="idErrorMsg"></div></td>
			</tr>
			<tr>
				<th>비밀번호</th>
				<td>
					<input type="password" name="password" id="password" oninput="validatePassword()">
					<span> ※ 영문자, 숫자, 특수문자 포함 8~12자 이내 (영문, 숫자, 특수문자 조합)</span>
				</td>
			</tr>
			<tr>
				<th>비밀번호 확인</th>
				<td><input type="password" name="passwordCheck" id="passwordCheck" oninput="checkPasswordMatch()" onfocus="blockIfInvalidPassword()"><span> ※ 비밀번호 재입력</span></td>
			</tr>
			<tr>
				<th></th>
				<td><div id="pwErrorMsg"></div></td>
			</tr>
			<tr>
				<th>주민등록번호</th>
				<td><input type="text" name="rrnFront" id="rrnFront" maxlength="6">
				 - <input type="password" name="rrnBack" id="rrnBack" maxlength="7"></td>
			</tr>
			<tr>
				<th>주소</th>
				<td>
					<div class="zipcode-wrapper">
						<input type="text" name="zipCode" id="zipCode" readonly>
						<input type="button" onclick="sample6_execDaumPostcode()" value="우편번호 찾기"><br>
					</div>
					<input type="text" name="address1" id="address1" readonly><br>
					<input type="text" name="extraAddress" id="extraAddress" readonly><br>
					<input type="text" name="address2" id="address2" placeholder="상세주소">
				</td>
			</tr>
		</table>

		<div class="button-group">
			<button type="button" onclick="validateAndSubmit()">등록</button>
			<button type="button" onclick="cancelRegist()">취소</button>
		</div>
	</div>
</div>
<c:if test="${not empty msg}">
    <script>
        alert("${msg}");
    </script>
</c:if>

<script src="/js/header2.js"></script>

<script>
	let usernameChecked = false; // 중복확인 완료 여부
	
	//아이디 입력이 바뀌었을 때 중복확인 상태 초기화
	function resetUsernameCheck() {
		usernameChecked = false;
		const checkBtn = document.getElementById("checkBtn");
		checkBtn.disabled = false;
		
		const idErrorMsg = document.getElementById("idErrorMsg");
		idErrorMsg.textContent = "아이디 중복 확인을 해주세요.";
		idErrorMsg.style.color = "red";
	}
	
	//아이디 중복확인
	function checkUsername(){
		const username = document.getElementById("username").value.trim();
		const idErrorMsg = document.getElementById("idErrorMsg");
		const checkBtn = document.getElementById("checkBtn");
		
		if(!username){
			idErrorMsg.textContent = "아이디를 입력해주세요.";
			idErrorMsg.style.color = "red";
			return;
		}
		
		const xhr = new XMLHttpRequest();
		xhr.onload = function(){
			const res = JSON.parse(xhr.responseText);
			idErrorMsg.textContent = res.msg;
			if(res.valid){
				idErrorMsg.style.color = "green";
				usernameChecked = true;
                checkBtn.disabled = true; // 중복확인 완료 → 버튼 비활성화
			}
			else{
				idErrorMsg.style.color = "red";	
				usernameChecked = false;
			}
		}
		xhr.open("POST", "/user/api/regist/check-username");
		xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
		xhr.send("username=" + username);
	}
	
	function changeUsername(){
		idErrorMsg.textContent = "아이디 중복 확인을 해주세요.";
		idErrorMsg.style.color = "red";
	}

	//비밀번호 유효성 검사
	function isPasswordValid(password){
		const pwRegex = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()_+\[\]{}|\\;:'",.<>\/?`~\-]).{8,12}$/;
		return pwRegex.test(password);
	}
	
	function validatePassword(){
		const password = document.getElementById("password");
		const pwErrorMsg = document.getElementById("pwErrorMsg");
		
		if(!password.value.trim()){
			pwErrorMsg.textContent = "";
			return;
		}
		if(!isPasswordValid(password.value)){
			pwErrorMsg.textContent = "비밀번호는 영문자, 숫자, 특수문자를 포함한 8~12자리여야 합니다.";
		    pwErrorMsg.style.color = "red";
		    //password.focus();
		}
		else{
			pwErrorMsg.textContent = "사용가능한 비밀번호입니다.";	
			pwErrorMsg.style.color = "green";
		}
		
	}
	function blockIfInvalidPassword() {
		const password = document.getElementById("password");
		const passwordCheck = document.getElementById("passwordCheck");
		const pwErrorMsg = document.getElementById("pwErrorMsg");

		if (!isPasswordValid(password.value)) {
			pwErrorMsg.textContent = "비밀번호 양식이 올바르지 않습니다. 비밀번호를 먼저 정확히 입력해주세요.";
		    pwErrorMsg.style.color = "red";
			//alert("비밀번호 양식이 올바르지 않습니다. 비밀번호를 먼저 정확히 입력해주세요.");
			password.focus();
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
	
	//주민등록번호 유효성 검사
	function isValidRRNPartial(rrnFront, rrnBackFirstDigit){
		if (!/^\d{6}$/.test(rrnFront)) return false;
		
		//생년월일 유효성 검사
	    const year = parseInt(rrnFront.substring(0, 2), 10);
	    const month = parseInt(rrnFront.substring(2, 4), 10);
	    const day = parseInt(rrnFront.substring(4, 6), 10);
	    
	    if (month < 1 || month > 12) return false;
	    
	    const daysInMonth = new Date(2000, month, 0).getDate(); // 2000년은 윤년 처리 포함
	    if (day < 1 || day > daysInMonth) return false;
	    
	 	//성별코드 유효성 확인 (1~4)
	    if (!/^[1-4]$/.test(rrnBackFirstDigit)) return false;

	    return true;
	}
	
	function validateAndSubmit(){
		const name = document.getElementById("name").value.trim();
	    const username = document.getElementById("username").value.trim();
	    const password = document.getElementById("password").value.trim();
	    const passwordCheck = document.getElementById("passwordCheck").value.trim();
	    const rrnFront = document.getElementById("rrnFront").value.trim();
	    const rrnBack = document.getElementById("rrnBack").value.trim();
	    const zipCode = document.getElementById("zipCode").value.trim();
	    const address1 = document.getElementById("address1").value.trim();
	    const extraAddress = document.getElementById("extraAddress").value;
	    const address2 = document.getElementById("address2").value.trim();
		
		//성명 유효성 검사
		const nameRegex = /^[가-힣]{2,20}$/;

		if (!name) {
			alert("성명을 입력해주세요.");
			document.getElementById("name").focus();
			return;
		}
		if (!nameRegex.test(name)) {
			alert("성명은 한글 2~20자여야 합니다.");
			nameInput.focus();
			return;
		}
		//성명 검사
		if (!name) {
			alert("성명을 입력해주세요.");
			document.getElementById("name").focus();
			return;
		}

		//아이디 검사
		if (!username) {
			alert("아이디를 입력해주세요.");
			document.getElementById("username").focus();
			return;
		}
		if (!usernameChecked) {
			alert("아이디 중복 확인을 해주세요.");
			document.getElementById("checkBtn").focus();
			return;
		}
		
		//비밀번호 검사
		if(!password){
			alert("비밀번호를 입력해주세요.");
			document.getElementById("password").focus();
			return;
		}
		if(!passwordCheck){
			alert("비밀번호를 확인하세요.");
			document.getElementById("passwordCheck").focus();
			return;
		}
		if (password !== passwordCheck) {
			alert("비밀번호가 일치하지 않습니다.");
			document.getElementById("passwordCheck").focus();
			return;
		}
		
		// 주민등록번호 유효성 검사
		const rrnRegex6 = /^\d{6}$/;
		const rrnRegex7 = /^\d{7}$/;

		if (!rrnRegex6.test(rrnFront)) {
			alert("주민등록번호 앞자리는 6자리 숫자여야 합니다.");
			document.getElementById("rrnFront").focus();
			return;
		}

		if (!rrnRegex7.test(rrnBack)) {
			alert("주민등록번호 뒷자리는 7자리 숫자여야 합니다.");
			document.getElementById("rrnBack").focus();
			return;
		}
		
		if (!isValidRRNPartial(rrnFront, rrnBack[0])) {
		    alert("유효하지 않은 주민등록번호입니다.");
		    document.getElementById("rrnFront").focus();
		    return;
		}
		//주민등록번호 검사
		if(!document.getElementById("rrnFront").value.trim() || !document.getElementById("rrnBack").value.trim()) {
			alert("주민등록번호를 입력해주세요.");
			document.getElementById("rrnFront").focus();
			return;
		}
		
		//주소 검사
		if(!zipCode || !address1) {
			alert("주소를 입력해주세요.");
			document.getElementById("zipCode").focus();
			return;
		}
		if(!address2){			
			alert("상세주소를 입력해주세요.");
			document.getElementById("address2").focus();
			return;
		}
		
		const data = {
		        name: name,
		        username: username,
		        password: password,
		        passwordCheck: passwordCheck,
		        rrnFront: rrnFront,
		        rrnBack: rrnBack,
		        zipCode: zipCode,
		        address1: address1,
		        extraAddress: extraAddress,
		        address2: address2
		    };

		    fetch("/user/api/regist/submit", {
		        method: "POST",
		        headers: {"Content-Type": "application/json"},
		        body: JSON.stringify(data)
		    })
		    .then(response => response.json())
		    .then(result => {
		        if(result.success){
		            alert(result.msg);
		            window.location.href = "/user/login"; // 로그인 페이지 이동
		        }
		        else {
		            alert(result.msg);
		        }
		    })
		    .catch(error => {
		        console.error("Error:", error);
		        alert("회원가입 중 오류가 발생했습니다.");
		    });
	}
	
	function cancelRegist(){
		if (confirm("회원가입 신청을 취소하시겠습니까?")) {
	        location.href = "/user/regist/selectMemberType";
	    }
	}
	
</script>
<script src="//t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script src="/js/postcode.js"></script>
</body>
</html>