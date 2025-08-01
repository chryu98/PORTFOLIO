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

<form id="uploadForm">
    <label>파일명:</label><br>
    <input type="text" id="pdfName" name="pdfName" required /><br><br>

    <label>사용 여부:</label><br>
    <select id="isActive" name="isActive" required>
        <option value="Y">사용</option>
        <option value="N">미사용</option>
    </select><br><br>

    <label>약관 PDF 파일 업로드:</label><br>
    <input type="file" id="file" name="file" accept="application/pdf" required /><br><br>

    <button type="submit">업로드</button>
</form>

<h3>사용 중 약관</h3>
<table border="1" cellpadding="8">
    <thead>
        <tr>
            <th>번호</th>
            <th>파일명</th>
            <th>업로드 날짜</th>
            <th>관리자 이름</th>
            <th>다운로드</th>
            <th>수정</th>
            <th>삭제</th>
        </tr>
    </thead>
    <tbody id="activeTableBody">
        <!-- JS에서 삽입 -->
    </tbody>
</table>

<h3>미사용 약관</h3>
<table border="1" cellpadding="8">
    <thead>
        <tr>
            <th>번호</th>
            <th>파일명</th>
            <th>업로드 날짜</th>
            <th>관리자 이름</th>
            <th>다운로드</th>
            <th>수정</th>
            <th>삭제</th>
        </tr>
    </thead>
    <tbody id="inactiveTableBody">
        <!-- JS에서 삽입 -->
    </tbody>
</table>

<script>
    document.getElementById("uploadForm").addEventListener("submit", async function (event) {
        event.preventDefault();

        const formData = new FormData();
        formData.append("file", document.getElementById("file").files[0]);
        formData.append("pdfName", document.getElementById("pdfName").value);
        formData.append("isActive", document.getElementById("isActive").value);

        try {
            const res = await fetch("/admin/pdf/upload", {
                method: "POST",
                body: formData,
                credentials: "include"  // ✅ 이게 꼭 있어야 세션 쿠키 전달됨!
            });

            const text = await res.text();
            alert(text);
            loadPdfList();  // ✅ 업로드 성공 후 테이블 새로고침
        } catch (e) {
            console.error(e);
            alert("업로드 중 오류 발생");
        }
    });

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
                    timeZone: "Asia/Seoul"  // 타임존 보정까지
                });
                const row = `
                    <tr>
                        <td>\${pdf.pdfNo}</td>
                        <td>\${pdf.pdfName}</td>
                        <td>\${formattedDate}</td>
                        <td>\${pdf.adminName}</td>
                        <td><a href="/admin/pdf/download/${pdf.pdfNo}">다운로드</a></td>
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
    
    // 수정
    function editPdf(pdfNo) {
        const newName = prompt("새 파일명을 입력하세요:");
        if (!newName) return;

        const newStatus = confirm("사용 상태로 설정할까요?") ? 'Y' : 'N';

        fetch("/admin/pdf/update", {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ pdfNo, pdfName: newName, isActive: newStatus }),
            credentials: "include"
        })
        .then(res => res.text())
        .then(msg => {
            alert(msg);
            loadPdfList();
        })
        .catch(err => {
            console.error(err);
            alert("수정 중 오류 발생");
        });
    }

    //삭제
    function deletePdf(pdfNo) {
    if (!confirm("정말 삭제하시겠습니까?")) return;

    fetch(`/admin/pdf/delete/${pdfNo}`, {
        method: "DELETE",
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


    // 초기 로딩 시 목록 불러오기
    window.addEventListener("DOMContentLoaded", loadPdfList);
</script>



</body>
</html>
