<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>회원가입 - 약관동의</title>
<link rel="stylesheet" href="/css/style.css">
<style>
body {
    font-family: "맑은 고딕", sans-serif;
    background-color: #fff;
    color: #333;
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
}
.sub-title {
    font-size: 14px;
    color: #777;
    margin-bottom: 30px;
}
.terms-section {
    margin-bottom: 30px;
    border-top: 1px solid #ddd;
    padding-top: 20px;
    margin-top: 20px;
}
.terms-section+.terms-section {
    border-top: none;
    margin-top: 0;
    padding-top: 0;
}
.terms-section h3 {
    font-size: 16px;
    margin-bottom: 16px;
}
.scroll-box {
    width: 100%;
    max-height: 200px;
    padding: 4px 15px 15px;
    border: 1px solid #ccc;
    border-radius: 0;
    background-color: #f8f8f8;
    font-size: 14px;
    white-space: pre-wrap;
    overflow-y: auto;
    line-height: 1.6;
}
.scroll-box>p:first-child {
    text-align: center;
    margin-top: 0;
    margin-bottom: 12px;
}
.radio-group {
    margin-top: 12px;
    text-align: right;
    font-size: 14px;
}
.radio-group label {
    margin-right: 20px;
}
.radio-group input {
    margin-left: 8px;
    margin-right: 2px;
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
    margin: 0 8px;
}
.button-group button:first-child {
    background-color: #c10c0c;
    color: white;
}
.button-group button:last-child {
    background-color: #f2f2f2;
    color: #333;
}
body, html {
    height: 100%;
    overflow-y: auto; /* 또는 scroll */
}
</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/fragments/mainheader2.jsp" />

<div class="content-wrapper">
    <h2 class="page-title">회원가입</h2>
    <p class="sub-title">약관에 동의해 주세요</p>

    <form id="termsForm" onsubmit="event.preventDefault(); submitTerms();">
        <c:forEach var="term" items="${terms}">
            <div class="terms-section">
                <h3>
                    ${term.termType}
                    <c:if test="${term.isRequired == 'Y'}">(필수)</c:if>
                    <c:if test="${term.isRequired != 'Y'}">(선택)</c:if>
                </h3>
                <div class="scroll-box">
                    <p><strong>${term.termType}</strong></p>
                    <p>${term.content}</p>
                </div>
                <div class="radio-group">
                    <span>위의 내용에 동의하십니까?</span>
                    <label>
                        <input type="radio"
                            name="terms${term.termNo}"
                            value="Y"
                            <c:if test="${term.agreeYn eq 'Y'}">checked</c:if>
                            <c:if test="${term.isRequired eq 'Y'}">data-required="Y"</c:if>>동의함
                    </label>
                    <label>
                        <input type="radio"
                            name="terms${term.termNo}"
                            value="N"
                            <c:if test="${term.agreeYn eq 'N' or term.agreeYn == null}">checked</c:if>
                            <c:if test="${term.isRequired eq 'Y'}">data-required="Y"</c:if>>동의하지 않음
                    </label>
                </div>
            </div>
        </c:forEach>

        <div class="button-group">
            <button type="button" onclick="submitTerms()">다음</button>
            <button type="button" onclick="cancelRegist()">취소</button>
        </div>
        
        <!-- <input type="hidden" name="role" value="${role}"> -->
    </form>
</div>
<script src="/js/header2.js"></script>
<script>
<c:if test="${not empty message}">
    alert('<c:out value="${message}" escapeXml="true"/>');
</c:if>

async function submitTerms(){

	const termsData = {};

    const checkedInputs = document.querySelectorAll("input[type='radio']:checked");
    checkedInputs.forEach(input => {
        termsData[input.name] = input.value;
    });

    try {
        const response = await fetch("/user/api/regist/terms", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(termsData)
        });

        const result = await response.json();

        if (response.ok) {
            location.href = result.redirectUrl;
        } else {
            alert(result.message);
        }

    } catch (error) {
        console.error("통신 오류:", error);
        alert("서버와 통신 중 오류가 발생했습니다.");
    }
	
}

function cancelRegist(){
    if (confirm("회원가입 신청을 취소하시겠습니까?")) {
        location.href = "/user/regist/selectMemberType";
    }
}
</script>
</body>
</html>
