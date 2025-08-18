<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드 발급 - 배송지 입력</title>
</head>
<body>
<h2>카드를 받을 배송지를 선택해 주세요.</h2>
<!-- 집/직장 선택 -->
<label>
    <input type="radio" name="addressType" value="home" checked> 집
</label>
<label>
    <input type="radio" name="addressType" value="work"> 직장
</label>

<div class="address-wrapper">
    <!-- 집 주소 블록 -->
    <div id="homeAddress" class="address-block">
        <span id="savedHomeAddress">
            <%-- 예시: 회원가입 시 저장된 집 주소를 서버에서 불러오기 --%>
            ${member.homeAddress}
        </span>
    </div>

    <!-- 직장 주소 입력 블록 -->
    <div id="workAddress" class="address-block">
        <div class="zipcode-wrapper">
            <input type="text" name="zipCode" id="zipCode" readonly> 
            <input type="button" onclick="sample6_execDaumPostcode()" value="우편번호 찾기"><br>
        </div>
        <input type="text" name="address1" id="address1" readonly placeholder="기본주소"><br>
        <input type="text" name="extraAddress" id="extraAddress" readonly placeholder="참고항목"><br>
        <input type="text" name="address2" id="address2" placeholder="상세주소">
    </div>
</div>

<script src="//t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
document.addEventListener('DOMContentLoaded', () => {
	const jwtToken = localStorage.getItem("jwtToken");
	const memberNo = localStorage.getItem("memberNo");
	
	if (!jwtToken) {
        alert('로그인이 필요합니다.');
        window.location.href = '/user/login';
        return;
    }
	
	fetch('/api/card/apply/address-home?memberNo=' + memberNo, {
	    method: 'GET',
	    headers: {
	        "Content-Type": "application/json",
	        "Authorization": "Bearer " + jwtToken
	    }
	})
	.then(res => res.json())
	.then(data => {
	    document.getElementById('savedHomeAddress').textContent = 
	        data.address1 + (data.extraAddress || '') + (data.address2 ? ', ' + data.address2 : '');
	})
	.catch(err => console.error(err));
}

//페이지 로드 시 집 주소 표시
document.getElementById('homeAddress').style.display = 'block';

// 라디오 선택 시 주소 블록 토글
const radios = document.querySelectorAll('input[name="addressType"]');
radios.forEach(radio => {
    radio.addEventListener('change', function() {
        if(this.value === 'home') {
            document.getElementById('homeAddress').style.display = 'block';
            document.getElementById('workAddress').style.display = 'none';
        } else {
            document.getElementById('homeAddress').style.display = 'none';
            document.getElementById('workAddress').style.display = 'block';
        }
    });
});

//다음 우편번호 API
function sample6_execDaumPostcode() {
    new daum.Postcode({
        oncomplete: function(data) {
            let fullAddr = data.address; 
            let extraAddr = data.buildingName ? ', ' + data.buildingName : '';
            document.getElementById('zipCode').value = data.zonecode;
            document.getElementById('address1').value = fullAddr;
            document.getElementById('extraAddress').value = extraAddr;
        }
    }).open();
}
</script>
</body>
</html>