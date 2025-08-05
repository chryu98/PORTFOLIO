<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<html>
<head>
    <title>Step 1 - 개인정보 입력</title>
</head>
<body>
    <h2>📋 Step 1: 개인정보 입력</h2>

    <form method="post" action="/application/userInfoSubmit">
        <!-- 신청번호는 이전 페이지에서 전달받음 -->
        <input type="hidden" name="applicationNo" value="${applicationNo}" />

        <label>이름:</label><br/>
        <input type="text" name="name" required /><br/><br/>

        <label>영문 이름:</label><br/>
        <input type="text" name="nameEng" required /><br/><br/>

        <label>주민등록번호 앞 6자리 (YYMMDD):</label><br/>
        <input type="text" name="rrnFront" maxlength="6" required /><br/><br/>

        <label>주민등록번호 뒷자리 (암호화된 값):</label><br/>
        <input type="text" name="rrnTailEnc" required />
        <small style="color:gray">(실제 프로젝트에서는 암호화 처리됨)</small><br/><br/>

        <label>기존 계좌 보유 여부:</label><br/>
        <select name="isExistingAccount" required>
            <option value="Y">있음 (기존 계좌 사용)</option>
            <option value="N">없음 (자동 계좌 생성)</option>
        </select><br/><br/>

        <button type="submit">다음 단계로 이동 → (약관 동의)</button>
    </form>

</body>
</html>
