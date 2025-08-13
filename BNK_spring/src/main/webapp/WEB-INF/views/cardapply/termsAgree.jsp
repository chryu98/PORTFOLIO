<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드 발급 - 약관 동의</title>
<style>
    body { font-family: Arial, sans-serif; }
    .term-list { margin: 20px; }
    .term-item { margin-bottom: 10px; }
    .term-item label { cursor: pointer; color: #0073e6; text-decoration: underline; }
    .modal {
        display: none;
        position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(0, 0, 0, 0.5);
        justify-content: center; align-items: center;
    }
    .modal-content {
        background: #fff; padding: 20px; width: 80%; height: 80%;
        display: flex; flex-direction: column;
    }
    .pdf-viewer { flex: 1; border: none; margin-bottom: 10px; }
    .modal-buttons { text-align: right; }
    .modal-buttons button { padding: 8px 15px; }
</style>
</head>
<body>
<h2>카드를 만드려면<br>약관 동의가 필요해요</h2>
<div class="term-list">
    <div class="term-item">
        <input type="checkbox" id="term1" disabled>
        <label data-pdf-no="1">[필수] 체크카드 개인회원 표준 약관</label>
    </div>
    <div class="term-item">
        <input type="checkbox" id="term2" disabled>
        <label data-pdf-no="2">[필수] 개인(신용)정보 필수적 전체 동의서</label>
    </div>
    <div class="term-item">
        <input type="checkbox" id="term3" disabled>
        <label data-pdf-no="3">[필수] 포인트이용약관</label>
    </div>
    <button id="agreeAll">모두 동의</button>
</div>

<!-- PDF 모달 -->
<div class="modal" id="pdfModal">
    <div class="modal-content">
        <iframe id="pdfViewer" class="pdf-viewer"></iframe>
        <div class="modal-buttons">
            <button id="btnAgree">동의</button>
            <button id="btnClose">닫기</button>
        </div>
    </div>
</div>

<script>
    const modal = document.getElementById("pdfModal");
    const pdfViewer = document.getElementById("pdfViewer");
    const btnAgree = document.getElementById("btnAgree");
    const btnClose = document.getElementById("btnClose");

    let currentTermId = null;

    // 체크박스나 라벨 클릭 시 PDF 뷰어 띄움
    document.querySelectorAll(".term-item label, .term-item input[type=checkbox]").forEach(el => {
        el.addEventListener("click", function(e) {
            e.preventDefault(); // 체크박스 직접 클릭 방지
            const pdfNo = this.dataset.pdfNo || this.nextElementSibling?.dataset.pdfNo;
            currentTermId = this.getAttribute("for") || this.id || this.previousElementSibling?.id;
            openPdfViewer(pdfNo);
        });
    });

    // 모두 동의 버튼 클릭
    document.getElementById("agreeAll").addEventListener("click", async function() {
        const labels = document.querySelectorAll(".term-item label");
        for (let i = 0; i < labels.length; i++) {
            const pdfNo = labels[i].dataset.pdfNo;
            currentTermId = labels[i].previousElementSibling.id;
            await openPdfViewer(pdfNo, true); // 자동 동의 모드
        }
    });

    // PDF 뷰어 열기
    function openPdfViewer(pdfNo, autoAgree = false) {
        return new Promise(resolve => {
            fetch(`/terms/pdf/${pdfNo}`) // 서버에서 PDF URL 반환
                .then(res => res.json())
                .then(data => {
                    pdfViewer.src = data.pdfUrl; // PDF 경로
                    modal.style.display = "flex";

                    if (autoAgree) {
                        document.getElementById(currentTermId).checked = true;
                        resolve();
                    } else {
                        btnAgree.onclick = () => {
                            document.getElementById(currentTermId).checked = true;
                            modal.style.display = "none";
                            resolve();
                        };
                        btnClose.onclick = () => {
                            modal.style.display = "none";
                            resolve();
                        };
                    }
                });
        });
    }
</script>

</body>
</html>