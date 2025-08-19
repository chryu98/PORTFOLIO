<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드 발급 - 카드 옵션 선택</title>
</head>
<body>

<div class="option-block">
    <label><input type="radio" name="cardBrand" value="VISA" checked> 비자(VISA)</label><br>
    <label><input type="radio" name="cardBrand" value="MasterCard"> 마스터(MasterCard)</label>
</div>

<div class="option-block">
    <label>후불 교통카드</label><br>
    <label class="toggle-switch">
        <input type="checkbox" id="postpaidCard">
        <span class="slider"></span>
    </label>
    <span id="postpaidLabel">OFF</span>
</div>

<button id="nextBtn">다음</button>

<script>
//URL에서 applicationNo 가져오기
const params = new URLSearchParams(window.location.search);
const applicationNo = params.get('applicationNo');

document.getElementById('postpaidCard').addEventListener('change', function() {
    document.getElementById('postpaidLabel').textContent = this.checked ? 'ON' : 'OFF';
});

document.getElementById('nextBtn').addEventListener('click', () => {
    //const applicationNo = document.getElementById('applicationNo').value;
    const cardBrand = document.querySelector('input[name="cardBrand"]:checked').value;
    const postpaid = document.getElementById('postpaidCard').checked ? 'Y' : 'N';
    const jwtToken = localStorage.getItem("jwtToken");

    if(!jwtToken) {
        alert('로그인이 필요합니다.');
        window.location.href = '/user/login';
        return;
    }

    const payload = { applicationNo, cardBrand, postpaid };

    fetch('/api/card/apply/card-options', {
        method: 'POST',
        headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer " + jwtToken
        },
        body: JSON.stringify(payload)
    })
    .then(res => {
        if(res.ok) {
            // 다음 단계 페이지 이동
            window.location.href = '/card/apply/addressInfo?applicationNo=' + applicationNo;
        } else {
            alert("카드 옵션 저장 실패");
        }
    })
    .catch(err => console.error(err));
});
</script>
</body>
</html>