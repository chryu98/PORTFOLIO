<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<html>
<head>
    <title>Step 2 - 약관 동의</title>
</head>
<body>
    <h2>📝 Step 2: 약관 동의</h2>

    <form method="post" action="/application/termsSubmit">
        <!-- Step 1에서 넘겨받은 신청번호 -->
        <input type="hidden" name="applicationNo" value="${applicationNo}" />

        <c:forEach var="term" items="${terms}">
            <div style="margin-bottom: 12px; padding: 8px; border: 1px solid #ccc;">
                <label>
                    <input type="checkbox" name="termNos" value="${term.pdfNo}"
                           <c:if test="${term.isRequired eq 'Y'}">required</c:if> />
                    <b>${term.pdfName}</b> (${term.termScope})
                    <c:if test="${term.isRequired eq 'Y'}">
                        <span style="color:red;">[필수]</span>
                    </c:if>
                    <c:if test="${term.isRequired eq 'N'}">
                        <span style="color:gray;">[선택]</span>
                    </c:if>
                </label>
            </div>
        </c:forEach>

        <button type="submit">다음 단계로 이동 → (전자서명)</button>
    </form>

</body>
</html>
