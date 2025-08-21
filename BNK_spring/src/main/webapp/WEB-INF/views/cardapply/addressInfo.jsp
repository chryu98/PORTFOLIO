<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드 발급 - 배송지 입력</title>
<style>
    .address-block { display: none; margin-top: 10px; }
</style>
</head>
<body>
<h2>카드를 받을 배송지를 선택해 주세요.</h2>

<!-- 집/직장 선택 드롭다운 -->
<select id="addressType">
    <option value="home" selected>집</option>
    <option value="work">직장</option>
</select>

<div class="address-wrapper">
    <!-- 집 주소 블록 -->
    <div id="homeAddress" class="address-block">
        <div class="zipcode-wrapper">
            <input type="text" name="zipCodeHome" id="zipCodeHome" readonly>
            <input type="button" onclick="execDaumPostcode('home')" value="우편번호 찾기"><br>
        </div>
        <input type="text" name="address1Home" id="address1Home" readonly><br>
        <input type="text" name="extraAddressHome" id="extraAddressHome" readonly><br>
        <input type="text" name="address2Home" id="address2Home" placeholder="상세주소">
    </div>

    <!-- 직장 주소 블록 -->
    <div id="workAddress" class="address-block" style="display:none;">
        <div class="zipcode-wrapper">
            <input type="text" name="zipCodeWork" id="zipCodeWork" readonly>
            <input type="button" onclick="execDaumPostcode('work')" value="우편번호 찾기"><br>
        </div>
        <input type="text" name="address1Work" id="address1Work" readonly><br>
        <input type="text" name="extraAddressWork" id="extraAddressWork" readonly><br>
        <input type="text" name="address2Work" id="address2Work" placeholder="상세주소">
    </div>
</div>

<button id="nextBtn">다음</button>

<script src="//t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
//URL에서 applicationNo 가져오기
const params = new URLSearchParams(window.location.search);
const applicationNo = params.get('applicationNo');

document.addEventListener('DOMContentLoaded', () => {
	const jwtToken = localStorage.getItem("jwtToken");
	const memberNo = localStorage.getItem("memberNo");
	
	if (!jwtToken) {
        alert('로그인이 필요합니다.');
        window.location.href = '/user/login';
        return;
    }
	
	// 서버에서 집 주소 가져오기
	fetch('/api/card/apply/address-home?memberNo=' + memberNo, {
	    method: 'GET',
	    headers: {
	        "Content-Type": "application/json",
	        "Authorization": "Bearer " + jwtToken
	    }
	})
	.then(res => res.json())
	.then(data => {
		let fullAddress = data.address1 || ''; 

	    let baseAddr = fullAddress;
	    let extraAddr = '';

	    // 괄호 안 내용만 따로 추출
	    const match = fullAddress.match(/^(.*)(\(.+\))$/);
	    if (match) {
	        baseAddr = match[1].trim();   // 괄호 앞
	        extraAddr = match[2].trim();  // 괄호 안
	    }

	    // 값 세팅
	    document.getElementById('zipCodeHome').value = data.zipCode || '';
	    document.getElementById('address1Home').value = baseAddr;      // 기본주소
	    document.getElementById('extraAddressHome').value = extraAddr; // 괄호 안
	    document.getElementById('address2Home').value = data.address2 || '';
	})
	.catch(err => console.error(err));

	document.getElementById('homeAddress').style.display = 'block';
    document.getElementById('workAddress').style.display = 'none';
    
	// 드롭다운 선택 시 토글
    document.getElementById('addressType').addEventListener('change', function() {
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
function execDaumPostcode(type) {
    new daum.Postcode({
        oncomplete: function(data) {
            let fullAddr = data.address;
            let extraAddr = data.buildingName ? ', ' + data.buildingName : '';

            if (type === 'home') {
                document.getElementById('zipCodeHome').value = data.zonecode;
                document.getElementById('address1Home').value = fullAddr;
                document.getElementById('extraAddressHome').value = extraAddr;
                document.getElementById('address2Home').focus();
            } else {
                document.getElementById('zipCodeWork').value = data.zonecode;
                document.getElementById('address1Work').value = fullAddr;
                document.getElementById('extraAddressWork').value = extraAddr;
                document.getElementById('address2Work').focus();
            }
        }
    }).open();
}

//const applicationNo = document.getElementById('applicationNo').value;

document.getElementById('nextBtn').addEventListener('click', () => {
    const type = document.getElementById('addressType').value;
    saveAddress(type)
        .then(() => {
            window.location.href = '/card/apply/nextPage?applicationNo=' + applicationNo;
        })
        .catch(err => console.error(err));
});

function saveAddress(type) {
    let zipCode = document.getElementById(type === 'home' ? 'zipCodeHome' : 'zipCodeWork').value;
    let address1 = document.getElementById(type === 'home' ? 'address1Home' : 'address1Work').value;
    let extraAddress = document.getElementById(type === 'home' ? 'extraAddressHome' : 'extraAddressWork').value;
    let address2 = document.getElementById(type === 'home' ? 'address2Home' : 'address2Work').value;

    if (!zipCode || !address1 || !address2) {
        alert("주소를 모두 입력해 주세요.");
        return Promise.reject("주소 미입력");
    }

    const jwtToken = localStorage.getItem("jwtToken");

    const payload = {
        applicationNo: applicationNo,
        zipCode,
        address1,
        extraAddress,
        address2,
        addressType: type === 'home' ? 'H' : 'W'
    };

    return fetch('/api/card/apply/address-save', {
        method: 'POST',
        headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer " + jwtToken
        },
        body: JSON.stringify(payload)
    })
    .then(res => {
        if(!res.ok) throw new Error("주소 저장 실패");
        alert(type === 'home' ? "집 주소가 저장되었습니다." : "직장 주소가 저장되었습니다.");
    });
}


</script>
</body>
</html>
