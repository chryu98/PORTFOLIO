<%@ page language="java" contentType="text/html; charset=UTF-8"
pageEncoding="UTF-8"%> <%@ taglib prefix="c"
uri="http://java.sun.com/jsp/jstl/core" %>
<header class="sidebar">
	<div class="flex admin-header">
		<a href="/admin/CardList">상품목록</a>
		<a href="/admin/Impression">상품인가</a>
		<a href="/admin/Search">검색어관리</a>
		<a href="/admin/Scraping">스크래핑</a>
		<a href="/admin/faq/list">FAQ관리</a>
		<a href="/admin/chat">고객관리</a>
		<a href="/admin/userinfomanagement">고객 정보 관리</a>
		<a href="/admin/reviewreport">상품 판매 현황 리포트</a>
		<a href="/admin/recommenproducts">추천 상품 관리</a>
		<a href="/admin/productTerms">상품 약관 관리</a>
		<a href="/admin/card-approval">카드 승인</a>
		<a href="/admin/verify/logs">사용자 인증관리</a>
		<a href="/admin/custom-cards">커스텀 AI 로그</a>
		<a href="/admin/feedback">피드백 분석</a>
		<a href="/admin/push">알림 관리</a>
		<a href="/admin/branches">영업점 관리</a>
		<a href="/admin/bouncerate">이탈률</a>
		<a href="/admin/Mainpage">사용자 메인페이지로</a>
		<a href="/admin/Mainpage"> </a>
		<div class="logout-container">
            <button id="logoutBtn">로그아웃</button>
        </div>
	</div>
		<div class="header-close-btn">
			<img src="/image/닫기.png">
		</div>
		<div class="header-open-btn">
			<img src="/image/삼단메뉴.png">
		</div>
</header>

<script>
document.addEventListener('DOMContentLoaded', function() {
  const currentPath = window.location.pathname;
  document.querySelectorAll('.admin-header a').forEach(link => {
    if (link.getAttribute('href') === currentPath) {
      link.style.color = 'red';
    }
  });
});
</script>


