<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드 발급 - 약관 동의</title>
</head>
<body>
<h2>카드를 만드려면 약관 동의가 필요해요</h2>
<label><input type="checkbox" id="checkAll"> 모두 동의</label>
<hr>

<form id="termsForm">
<c:forEach var="term" items="${pdfList}">
    <div>
        <input type="checkbox" name="termCheck" value="${term.fileId}">
        <a href="#" class="viewPdf" data-id="${term.fileId}">${term.displayName}</a>
    </div>
</c:forEach>
<button type="submit">다음</button>
</form>

<!-- PDF 모달 -->
<div id="pdfModal" class="modal">
    <div class="modal-content">
        <span class="close">&times;</span>
        <iframe id="pdfViewer"></iframe>
        <div>
            <button id="agreeBtn">동의</button>
            <button id="downloadBtn">다운로드</button>
        </div>
    </div>
</div>

<script>
const modal = document.getElementById('pdfModal');
const iframe = document.getElementById('pdfViewer');
let currentFileId = null;

// 모두 동의 체크
document.getElementById('checkAll').addEventListener('change', function() {
    document.querySelectorAll('[name="termCheck"]').forEach(chk => chk.checked = this.checked);
});

// 약관 클릭 시 PDF 열기
document.querySelectorAll('.viewPdf').forEach(link => {
    link.addEventListener('click', function(e) {
        e.preventDefault();
        currentFileId = this.dataset.id;
        iframe.src = '/card/apply/terms/pdf/' + currentFileId;
        modal.style.display = 'block';
    });
});

// 모달 닫기
document.querySelector('.close').onclick = () => modal.style.display = 'none';

// 동의 버튼 클릭 시 해당 체크박스 선택
document.getElementById('agreeBtn').addEventListener('click', () => {
    document.querySelector('[name="termCheck"][value="' + currentFileId + '"]').checked = true;
    modal.style.display = 'none';
});

// 다운로드 버튼
document.getElementById('downloadBtn').addEventListener('click', () => {
    window.location.href = '/card/apply/terms/pdf/' + currentFileId;
});
</script>
</body>
</html>