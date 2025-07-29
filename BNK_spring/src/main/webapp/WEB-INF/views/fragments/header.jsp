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
		<a href="/admin/Mainpage">사용자 메인페이지로</a>
		<button id="logoutBtn">로그아웃</button>
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


