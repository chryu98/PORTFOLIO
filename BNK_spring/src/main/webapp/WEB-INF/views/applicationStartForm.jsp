<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Step 0 - 카드 신청 시작</title>
</head>
<body>
    <h2>🚀 Step 0: 카드 발급 신청 시작</h2>

    <form method="post" action="/application/start">
        <!-- 카드 번호는 이전 페이지에서 전달받음 -->
        <input type="hidden" name="cardNo" value="${cardNo}" />

        <!-- 임시로 회원번호를 하드코딩 (로그인 기능과 연동 시 세션에서 받아올 수 있음) -->
        <label>회원번호 (테스트용):</label><br/>
        <input type="text" name="memberNo" value="1" /><br/><br/>

        <label>카드 유형:</label><br/>
        <select name="isCreditCard">
            <option value="Y">신용카드</option>
            <option value="N">체크카드</option>
        </select><br/><br/>

        <input type="hidden" name="status" value="신청중" />

        <button type="submit">다음 → 개인정보 입력</button>
    </form>
</body>
</html>