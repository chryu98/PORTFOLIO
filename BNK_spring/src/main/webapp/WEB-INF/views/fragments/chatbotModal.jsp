<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />

<!-- BNK Chatbot (공통) -->
<link rel="stylesheet" href="${ctx}/css/bnk-chatbot.css" />

<!-- 챗봇 루트 (JS가 여기에 FAB+모달 생성) -->
<div id="bnkChatbotRoot"
     data-placement="right"            <%-- left | right --%>
     data-backend-local="http://localhost:8000"
     data-backend-remote="http://192.168.0.5:8000"
     data-human-url="${ctx}/user/chat/page">
  <!-- JS 미동작시 graceful fallback: 단순 링크 표시 -->
  <noscript>
    <a href="${ctx}/chatbot" style="
      position:fixed;right:24px;bottom:24px;z-index:9999;
      background:#d6001c;color:#fff;padding:8px 12px;border-radius:4px;
      text-decoration:none;">챗봇</a>
  </noscript>
</div>

<script src="${ctx}/js/bnk-chatbot.js"></script>
