<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드 발급 - 고객 정보 입력</title>
</head>
<body>
    <h2>정보를 입력해 주세요.</h2>
    <form id="infoForm">
    	<!-- <input type="hidden" name="cardNo" value="${cardNo}"> -->
    	<input type="text" name="name" id="name">
		
		<div>
			<p>여권 이름과 동일해야 합니다.</p>
			<p>※ 여권 이름과 다르면 해외에서 카드를 사용할 수 없습니다.</p>
			
	    	<input type="text" name="engFirstName" placeholder="영문 성">
	    	<input type="text" name="engLastName" placeholder="영문 이름">		
		</div>
		
    	<input type="text" name="rrnFront" id="rrnFront">
		<input type="password" name="rrnBack" id="rrnBack">
        
        <button type="submit">다음</button>
    </form>
    
<script>
//페이지 로딩 시 고객 정보 가져오기
document.addEventListener('DOMContentLoaded', function() {
    const params = new URLSearchParams(window.location.search);
    const cardNo = params.get('cardNo');
    console.log('cardNo: ' + cardNo);
    
    fetch('/api/card/apply/get-customer-info?cardNo=' + cardNo)
        .then(res => res.json())
        .then(data => {
            const user = data.loginUser;
            const rrnBack = data.rrnBack;

            document.getElementById('name').value = user.name;
            document.getElementById('rrnFront').value = user.rrnFront;
            document.getElementById('rrnBack').value = rrnBack;
        });
});

document.getElementById('infoForm').addEventListener('submit', async function (e) {
	e.preventDefault();

	const params = new URLSearchParams(window.location.search);
    const cardNo = params.get('cardNo');
	
	const data = {
		cardNo: cardNo,
	    name: document.querySelector('[name="name"]').value.trim(),
	    engFirstName: document.querySelector('[name="engFirstName"]').value.trim(),
	    engLastName: document.querySelector('[name="engLastName"]').value.trim(),
	    rrnFront: document.querySelector('[name="rrnFront"]').value.trim(),
	    rrnBack: document.querySelector('[name="rrnBack"]').value.trim(),
	};
	
	try {
		const jwtToken = localStorage.getItem("jwtToken"); // 로그인 시 저장한 토큰
	    	
	    const response = await fetch('/card/apply/api/validateInfo', {
		    method: 'POST',
		    headers: {
		    	'Content-Type': 'application/json',
		        'Authorization': 'Bearer ' + jwtToken  // JWT 헤더 추가
		    },
		    body: JSON.stringify(data),
		});
	
		const result = await response.json();
	
	    if (result.success) {
	    	location.href = '/card/apply/contactInfo?applicationNo=' + encodeURIComponent(result.applicationNo);
	    }
	    else {
	    	alert(result.message);
	    }
	}
    catch (err) {
    	alert('서버와 통신 중 오류가 발생했습니다.');
    }
});
</script>
</body>
</html>