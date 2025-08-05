<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>상품 약관 관리</title>
</head>
<body>
<h2>상품 약관 관리</h2>

<!-- 업로드 폼 -->
<form id="uploadForm">
    <label>파일명:</label><br>
    <input type="text" id="pdfName" name="pdfName" required /><br><br>

    <label>사용 여부:</label><br>
    <select id="isActive" name="isActive" required>
        <option value="Y">사용</option>
        <option value="N">미사용</option>
    </select><br><br>

    <label>약관 범위:</label><br>
    <input type="radio" id="scopeCommon" name="termScope" value="common" required>
    <label for="scopeCommon">공통약관</label><br>
    <input type="radio" id="scopeSpecific" name="termScope" value="specific">
    <label for="scopeSpecific">개별약관</label><br>
    <input type="radio" id="scopeSelect" name="termScope" value="select">
    <label for="scopeSelect">선택약관</label><br><br>

    <label>약관 PDF 파일 업로드:</label><br>
    <input type="file" id="file" name="file" accept="application/pdf" required /><br><br>

    <button type="submit">업로드</button>
</form>

<!-- 수정 모달 -->
<div id="editFormWrapper" style="display:none; border:1px solid #ccc; padding:15px; margin-top:20px;">
    <h3>PDF 수정</h3>
    <form id="editForm">
        <input type="hidden" id="editPdfNo" />

        <label>파일명:</label><br>
        <input type="text" id="editPdfName" required /><br><br>

        <label>사용 여부:</label><br>
        <select id="editIsActive" required>
            <option value="Y">사용</option>
            <option value="N">미사용</option>
        </select><br><br>

        <label>약관 범위:</label><br>
        <input type="radio" id="editScopeCommon" name="editTermScope" value="common" required>
        <label for="editScopeCommon">공통약관</label><br>
        <input type="radio" id="editScopeSpecific" name="editTermScope" value="specific">
        <label for="editScopeSpecific">개별약관</label><br>
        <input type="radio" id="editScopeSelect" name="editTermScope" value="select">
        <label for="editScopeSelect">선택약관</label><br><br>

        <label>새 PDF 파일 (선택):</label><br>
        <input type="file" id="editFile" accept="application/pdf" /><br><br>

        <button type="submit">수정 완료</button>
        <button type="button" onclick="cancelEdit()">취소</button>
    </form>
</div>

<h3>사용 중 약관</h3>
<table border="1" cellpadding="8">
    <thead>
        <tr>
            <th>번호</th>
            <th>파일명</th>
            <th>약관 범위</th>
            <th>업로드 날짜</th>
            <th>관리자 이름</th>
            <th>다운로드</th>
            <th>수정</th>
            <th>삭제</th>
        </tr>
    </thead>
    <tbody id="activeTableBody"></tbody>
</table>

<h3>미사용 약관</h3>
<table border="1" cellpadding="8">
    <thead>
        <tr>
            <th>번호</th>
            <th>파일명</th>
            <th>약관 종류</th>
            <th>업로드 날짜</th>
            <th>관리자 이름</th>
            <th>다운로드</th>
            <th>수정</th>
            <th>삭제</th>
        </tr>
    </thead>
    <tbody id="inactiveTableBody"></tbody>
</table>

<script>
    // 업로드
    document.getElementById("uploadForm").addEventListener("submit", async function (event) {
        event.preventDefault();

        const formData = new FormData();
        formData.append("file", document.getElementById("file").files[0]);
        formData.append("pdfName", document.getElementById("pdfName").value);
        formData.append("isActive", document.getElementById("isActive").value);
        formData.append("termScope", document.querySelector('input[name="termScope"]:checked').value);

        try {
            const res = await fetch("/admin/pdf/upload", {
                method: "POST",
                body: formData,
                credentials: "include"
            });

            const text = await res.text();
            alert(text);
            loadPdfList();
        } catch (e) {
            console.error(e);
            alert("업로드 중 오류 발생");
        }
    });

    // 리스트 불러오기
    async function loadPdfList() {
        try {
            const res = await fetch("/admin/pdf/list");
            const list = await res.json();

            const activeBody = document.getElementById("activeTableBody");
            const inactiveBody = document.getElementById("inactiveTableBody");
            activeBody.innerHTML = "";
            inactiveBody.innerHTML = "";

            list.forEach(pdf => {
                const date = new Date(pdf.uploadDate);
                const formattedDate = date.toLocaleString("ko-KR", {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                    hour: "2-digit",
                    minute: "2-digit",
                    hour12: false,
                    timeZone: "Asia/Seoul"
                });

                const row = `
                    <tr>
                        <td>\${pdf.pdfNo}</td>
                        <td><a href="/admin/pdf/view/\${pdf.pdfNo}" target="_blank">\${pdf.pdfName}</a></td>
                        <td>\${pdf.termScope}</td>
                        <td>\${formattedDate}</td>
                        <td>\${pdf.adminName}</td>
                        <td><a href="/admin/pdf/download/\${pdf.pdfNo}">다운로드</a></td>
                        <td><button onclick="editPdf(\${pdf.pdfNo})">수정</button></td>
                        <td><button onclick="deletePdf(\${pdf.pdfNo})">삭제</button></td>
                    </tr>
                `;

                if (pdf.isActive === 'Y') {
                    activeBody.innerHTML += row;
                } else {
                    inactiveBody.innerHTML += row;
                }
            });

        } catch (err) {
            console.error("목록 불러오기 실패", err);
        }
    }

    // 수정 폼 열기
    function editPdf(pdfNo) {
        const pdf = getPdfByNo(pdfNo);
        if (!pdf) return;

        document.getElementById("editPdfNo").value = pdf.pdfNo;
        document.getElementById("editPdfName").value = pdf.pdfName;
        document.getElementById("editIsActive").value = pdf.isActive;
        document.querySelector(`input[name="editTermScope"][value="\${pdf.termScope}"]`).checked = true;

        document.getElementById("editFormWrapper").style.display = "block";
    }

    function getPdfByNo(pdfNo) {
        const rows = document.querySelectorAll("tbody tr");
        for (const row of rows) {
            const cells = row.querySelectorAll("td");
            if (cells.length && parseInt(cells[0].textContent) === pdfNo) {
                return {
                    pdfNo: parseInt(cells[0].textContent),
                    pdfName: cells[1].textContent,
                    termScope: cells[2].textContent,
                    isActive: row.closest("tbody").id === "activeTableBody" ? "Y" : "N"
                };
            }
        }
        return null;
    }

    // 수정 폼 제출
    document.getElementById("editForm").addEventListener("submit", function (event) {
        event.preventDefault();

        const formData = new FormData();
        formData.append("pdfNo", document.getElementById("editPdfNo").value);
        formData.append("pdfName", document.getElementById("editPdfName").value);
        formData.append("isActive", document.getElementById("editIsActive").value);
        formData.append("termScope", document.querySelector('input[name="editTermScope"]:checked').value);

        const file = document.getElementById("editFile").files[0];
        if (file) {
            formData.append("file", file);
        }

        fetch("/admin/pdf/edit", {
            method: "POST",
            body: formData,
            credentials: "include"
        })
        .then(res => res.text())
        .then(msg => {
            alert(msg);
            loadPdfList();
            cancelEdit();
        })
        .catch(err => {
            console.error(err);
            alert("수정 중 오류 발생");
        });
    });

    function cancelEdit() {
        document.getElementById("editFormWrapper").style.display = "none";
        document.getElementById("editForm").reset();
    }

    function deletePdf(pdfNo) {
        if (!confirm("정말 삭제하시겠습니까?")) return;

        const formData = new FormData();
        formData.append("pdfNo", pdfNo);

        fetch("/admin/pdf/delete", {
            method: "POST",
            body: formData,
            credentials: "include"
        })
        .then(res => res.text())
        .then(msg => {
            alert(msg);
            loadPdfList();
        })
        .catch(err => {
            console.error(err);
            alert("삭제 중 오류 발생");
        });
    }

    // 최초 로딩
    window.addEventListener("DOMContentLoaded", loadPdfList);
</script>
</body>
</html>
