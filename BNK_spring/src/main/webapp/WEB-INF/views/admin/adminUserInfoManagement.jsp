<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>고객 정보 관리</title>
<style>
    #userDetailBox {
        margin-top: 20px;
        border: 1px solid #999;
        padding: 10px;
        display: none;
        width: fit-content;
    }

    tr:hover {
        background-color: #f0f0f0;
        cursor: pointer;
    }

    table {
        border-collapse: collapse;
    }

    th, td {
        padding: 8px 12px;
    }
</style>
</head>
<body>
    <h1>고객 정보 관리</h1>

    <!-- 검색창 -->
    <label for="searchInput">고객 이름 검색:</label>
    <input type="text" id="searchInput" placeholder="이름을 입력하세요" />

    <!-- 고객 리스트 테이블 -->
    <table border="1" style="margin-top: 10px;">
        <thead>
            <tr>
                <th>고객명</th>
                <th>고객ID</th>
            </tr>
        </thead>
        <tbody id="userTableBody">
            <!-- fetch로 동적 데이터 삽입 -->
        </tbody>
    </table>

    <!-- 상세 정보 박스 -->
    <div id="userDetailBox">
        <h3>고객 상세 정보</h3>
        <p><strong>회원번호:</strong> <span id="detailMemberNo"></span></p>
        <p><strong>아이디:</strong> <span id="detailUsername"></span></p>
        <p><strong>이름:</strong> <span id="detailName"></span></p>
        <p><strong>성별:</strong> <span id="detailGender"></span></p>
        <p><strong>나이:</strong> <span id="detailAge"></span></p>
        <p><strong>주소:</strong> <span id="detailAddress"></span></p>
    </div>

<script>
document.addEventListener("DOMContentLoaded", function() {
    let allUsers = [];

    // 사용자 전체 목록 불러오기
    fetch("/admin/user/list")
        .then(response => {
            if (!response.ok) throw new Error("서버 응답 오류");
            return response.json();
        })
        .then(data => {
            allUsers = data;
            renderTable(allUsers);
        })
        .catch(error => {
            console.error("에러 발생:", error);
        });

    // 테이블 렌더링
    function renderTable(users) {
        const tbody = document.getElementById("userTableBody");
        tbody.innerHTML = "";

        users.forEach(user => {
            const row = document.createElement("tr");

            const nameTd = document.createElement("td");
            nameTd.textContent = user.name;

            const idTd = document.createElement("td");
            idTd.textContent = user.username;

            row.appendChild(nameTd);
            row.appendChild(idTd);
            tbody.appendChild(row);

            // 클릭 시 상세 정보 표시
            row.addEventListener("click", function() {
                showUserDetails(user);
            });
        });
    }

    // 상세 정보 출력
    function showUserDetails(user) {
        document.getElementById("detailMemberNo").textContent = user.memberNo;
        document.getElementById("detailUsername").textContent = user.username;
        document.getElementById("detailName").textContent = user.name;

        

        // 성별 표시
        document.getElementById("detailGender").textContent = getGender(user.rrnGender);

        // 나이 계산
        const age = calculateAge(user.rrnFront, user.rrnGender);
        document.getElementById("detailAge").textContent = age + "세";

     

        // 주소 표시
        const address = `\${user.zipCode || ''} \${user.address1 || ''} \${user.address2 || ''}`;
        document.getElementById("detailAddress").textContent = address.trim();

        document.getElementById("userDetailBox").style.display = "block";
    }

    // 이름 검색 필터링
    document.getElementById("searchInput").addEventListener("input", function(e) {
        const keyword = e.target.value.trim().toLowerCase();
        const filtered = allUsers.filter(user =>
            user.name.toLowerCase().includes(keyword)
        );
        renderTable(filtered);
    });

    // 성별 판별
    function getGender(code) {
        if (code === "1" || code === "3") return "남자";
        if (code === "2" || code === "4") return "여자";
        return "알 수 없음";
    }

    // 나이 계산
    function calculateAge(rrnFront, genderCode) {
        if (!rrnFront || rrnFront.length !== 6) return "-";

        const yearPart = parseInt(rrnFront.substring(0, 2));
        const monthPart = parseInt(rrnFront.substring(2, 4));
        const dayPart = parseInt(rrnFront.substring(4, 6));

        let fullYear;
        if (genderCode === "1" || genderCode === "2") {
            fullYear = 1900 + yearPart;
        } else if (genderCode === "3" || genderCode === "4") {
            fullYear = 2000 + yearPart;
        } else {
            return "-";
        }

        const today = new Date();
        const birthDate = new Date(fullYear, monthPart - 1, dayPart);

        let age = today.getFullYear() - fullYear;
        const isBirthdayPassed =
            today.getMonth() > birthDate.getMonth() ||
            (today.getMonth() === birthDate.getMonth() && today.getDate() >= birthDate.getDate());

        if (!isBirthdayPassed) age--;

        return age;
    }

    // 회원유형 코드 → 텍스트 변환
    function getRoleName(code) {
        switch(code) {
            case "PERSON": return "일반회원(개인)";
            case "OWNER": return "개인사업자";
            case "CORP": return "법인";
            default: return code || "-";
        }
    }
});
</script>
</body>
</html>
