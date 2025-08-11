<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>주소 및 이메일 입력</title>
</head>
<body>
<h2>배송 받을 주소를 입력해 주세요.</h2>

<form id="addressForm">
    <!-- 주소 유형 선택 -->
    <div class="form-group">
        <label for="addressType">주소 유형</label>
        <select name="addressType" id="addressType">
            <option value="home" selected>집</option>
            <option value="work">직장</option>
        </select>
    </div>

    <!-- 집 주소 영역 -->
    <div id="homeAddress">
        <p><strong>집 주소</strong></p>
        <input type="text" name="homePostcode" value="${loginUser.homePostcode}" readonly>
        <input type="text" name="homeAddress" value="${loginUser.homeAddress}" readonly>
        <input type="text" name="homeAddressDetail" value="${loginUser.homeAddressDetail}" readonly>
    </div>

    <!-- 직장 주소 입력 영역 -->
    <div id="workAddress" class="hidden">
        <p><strong>직장 주소</strong></p>
        <input type="text" name="workPostcode" placeholder="우편번호">
        <input type="text" name="workAddress" placeholder="주소">
        <input type="text" name="workAddressDetail" placeholder="상세주소">
    </div>

    <button type="submit">다음</button>
</form>

<script>
document.getElementById('addressType').addEventListener('change', function() {
    const homeDiv = document.getElementById('homeAddress');
    const workDiv = document.getElementById('workAddress');

    if (this.value === 'home') {
        homeDiv.classList.remove('hidden');
        workDiv.classList.add('hidden');
    } else {
        homeDiv.classList.add('hidden');
        workDiv.classList.remove('hidden');
    }
});
</script>
</body>
</html>