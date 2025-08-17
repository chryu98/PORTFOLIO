<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>상품 약관 관리</title>
<link rel="stylesheet" href="/css/adminstyle.css">
<style>
/* ===== 기본 ===== */
* { box-sizing: border-box; }
html, body { height: 100%; }
body {
  margin: 0;
  background: #fff;               /* 전체 화이트 */
  color: #111827;
  font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
}

/* 가운데 정렬 + 페이지 폭 (별도 래퍼 없어도 적용) */
:where(h2, form, table, #editFormWrapper) {
  width: min(1100px, 92vw);
  margin-inline: auto;
}

/* 제목 */
h2 {
  margin: 0px auto 14px;
  font-size: 22px;
  font-weight: 700;
  text-align: center;
}

/* h3 제목 스타일 */
h3 {
  width: min(1100px, 92vw);   /* 테이블과 동일한 폭 */
  margin: 20px auto 10px;     /* 가운데 정렬 */
  text-align: center;         /* 텍스트도 가운데 정렬 */
  font-size: 18px;
  font-weight: 600;
  color: #111827;
}


/* ===== 폼 공통 ===== */
form {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  padding: 16px;
  margin: 12px auto 20px;
  box-shadow: 0 4px 12px rgba(0,0,0,.05);
}

label {
  display: inline-block;
  font-size: 13px;
  color: #6b7280;
  margin: 8px 0 6px;
}

input[type="text"],
input[type="file"],
select,
button {
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 10px;
  font-size: 14px;
  background: #fff;
  color: #111827;
  outline: none;
  transition: border-color .18s, box-shadow .18s, transform .05s, filter .12s;
}

input[type="text"],
input[type="file"],
select {
  width: min(520px, 92vw);
  max-width: 100%;
}

input:focus,
select:focus {
  border-color: #2563eb;
  box-shadow: 0 0 0 3px rgba(37,99,235,.15);
}

/* 라디오 그룹 (약관 범위) */
input[type="radio"] { margin-right: 6px; }
input[type="radio"] + label { margin-right: 16px; }

/* 버튼 */
button {
  cursor: pointer;
  background: #2563eb;
  border-color: #2563eb;
  color: #fff;
}
button:hover { filter: brightness(0.98); }
button:active { transform: translateY(1px); }

/* 보조 버튼 (취소 등) */
button[type="button"] {
  background: #fff;
  color: #111827;
  border-color: #d1d5db;
}

/* ===== 수정 폼(모달 느낌 카드) ===== */
#editFormWrapper {
  border: 1px solid #e5e7eb !important;
  border-radius: 14px;
  padding: 16px !important;
  margin-top: 20px !important;
  background: #fff;
  box-shadow: 0 6px 18px rgba(0,0,0,.08);
}
#editFormWrapper h3 {
  margin: 0 0 10px;
  font-size: 18px;
  font-weight: 700;
  color: #111827;
}

/* ===== 테이블 ===== */
/* HTML에 border="1"이 있어도 아래가 우선 적용됨 */
table {
  width: min(1100px, 92vw);
  border-collapse: collapse;
  background: #fff;
  border: 1px solid #e5e7eb !important;
  border-radius: 12px;
  overflow: hidden;
  margin: 10px auto 24px;
  box-shadow: 0 4px 12px rgba(0,0,0,.05);
}
thead th {
  background: #f9fafb;
  color: #374151;
  font-weight: 600;
  font-size: 14px;
  text-align: left;
  padding: 12px 14px;
  border-bottom: 1px solid #e5e7eb;
}
tbody td {
  padding: 11px 14px;
  border-bottom: 1px solid #f1f5f9;
  font-size: 14px;
  vertical-align: middle;
}
tbody tr:hover { background: #fafafa; }

/* 링크 */
a { color: #2563eb; text-decoration: none; }
a:hover { text-decoration: underline; }

/* 버튼 in 테이블 */
td button {
  padding: 6px 10px;
  font-size: 13px;
  border-radius: 8px;
}

/* ===== 접근성 ===== */
:focus-visible {
  outline: 3px solid rgba(37,99,235,.35);
  outline-offset: 2px;
}

/* ===== 반응형 ===== */
@media (max-width: 720px) {
  h2 { font-size: 20px; }
  thead th, tbody td { padding: 10px 12px; font-size: 13px; }
  form { padding: 14px; }
  input[type="text"], input[type="file"], select { width: 100%; }
}

/* ===== 프린트 ===== */
@media print {
  form, #editFormWrapper { box-shadow: none; border-color: #ddd; }
  button { display: none !important; }
}

</style>
</head>
<body>
<jsp:include page="../fragments/header.jsp"></jsp:include>
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

<script src="/js/adminHeader.js"></script>
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
