<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>고객 정보 관리</title>
<style>
h1 {
  width: min(1100px, 92vw);
  margin: 0px auto 12px;
  font-size: 22px;
  font-weight: 700;
  text-align: center;
  padding-top:40px;
}
/* ===== 공통 ===== */
* { box-sizing: border-box; }
body {
  margin: 0;
  background: #fff;
  color: #111827;
  font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
}
/* ===== 가운데 정렬 페이지 블록 ===== */
.page-block {
  width: min(1100px, 92vw);
  margin: 0 auto;
}
/* ===== 제목 ===== */
h1.page-block {
  margin: 20px auto 12px;
  font-size: 22px;
  font-weight: 700;
  text-align: center;
}
/* ===== 검색창 ===== */
label[for="searchInput"] {
  display: block;
  margin: 10px auto 8px;
  color: #6b7280;
  font-weight: 600;
  width: min(1100px, 92vw);
  text-align: center;
}
#searchInput {
  display: block;
  width: min(520px, 92vw);
  margin: 0 auto;
  padding: 10px 12px 10px 38px;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  background: #fff;
}
/* ===== 테이블 (공통) ===== */
table {
  width: min(1100px, 92vw);
  margin: 16px auto 0;
  border-collapse: collapse;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0,0,0,.06);
}
thead th {
  text-align: left;
  font-size: 13px;
  color: #6b7280;
  background: #fff;
  border-bottom: 1px solid #e5e7eb;
  padding: 12px 14px;
}
tbody td {
  padding: 12px 14px;
  border-bottom: 1px solid #f1f5f9;
  text-align: left;
}
tbody tr {
  cursor: pointer;
  transition: background-color .15s ease;
}
tbody tr:hover {
  background: #f9fafb;
}
/* ===== 빈 상태 ===== */
tbody:empty::after {
  content: "불러올 데이터가 없습니다.";
  display: block;
  padding: 28px;
  text-align: center;
  color: #9ca3af;
}
/* ===== 상세 정보 박스 ===== */
#userDetailBox {
  width: min(1100px, 92vw);
  margin: 16px auto 0;
  padding: 16px 18px;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,.06);
  display: none;
}
#userDetailBox h3 {
  margin: 0 0 10px;
  font-size: 18px;
}
#userDetailBox p {
  display: grid;
  grid-template-columns: 120px 1fr;
  gap: 8px 14px;
  margin: 8px 0;
}
#userDetailBox strong {
  color: #6b7280;
  font-weight: 600;
}
/* ===== 가입/신청 내역 보조 메시지 ===== */
#appEmpty, #appLoading {
  width: min(1100px, 92vw);
  margin: 8px auto 0;
  text-align: center;
  color: #9ca3af;
}
#appLoading { color: #6b7280; }

#pagination button, 
#pagination span {
  border: 1px solid #d1d5db;   /* 옅은 회색 라인 */
  background: #ffffff;
  padding: 6px 12px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  color: #374151;               /* 기본 글자색: 진한 회색 */
  transition: all 0.2s ease;
}

#pagination button:hover {
  background: #f3f4f6;          /* 연한 회색 배경 */
  border-color: #9ca3af;
}

#pagination button[disabled] {
  opacity: 0.4;
  cursor: not-allowed;
  background: #f9fafb;
  color: #9ca3af;
  border-color: #e5e7eb;
}

#pagination .active {
  background: #2563eb;          /* 메인 블루 */
  color: #ffffff;
  border-color: #2563eb;
  font-weight: 600;
}

#pagination span {
  background: transparent;
  border: none;
  color: #9ca3af;               /* "…" 점 세 개는 연한 회색 */
  cursor: default;
}

</style>

<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
  <jsp:include page="../fragments/header.jsp"></jsp:include>
  <h1>고객 정보 관리</h1>

  <!-- 검색창 -->
  <label for="searchInput">고객 이름 검색:</label>
  <input type="text" id="searchInput" placeholder="이름을 입력하세요" />

<!-- 페이지 설정/상태 -->
<div class="page-block" style="display:flex; align-items:center; gap:12px; justify-content:space-between; margin-top:10px;">
  <div>
    <label for="pageSize" style="color:#6b7280; font-weight:600; margin-right:8px;">표시 개수</label>
    <select id="pageSize">
      <option value="10" selected>10</option>
      <option value="20">20</option>
      <option value="50">50</option>
    </select>
  </div>
  <div id="userCountText" style="color:#6b7280;"></div>
</div>


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

<!-- 페이지네이션 -->
<div id="pagination" class="page-block" style="display:flex; gap:6px; justify-content:center; align-items:center; margin-top:10px;"></div>


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

  <!-- 가입/신청 내역 테이블 + 상태 메시지 -->
  <table id="appTable" style="display:none;">
    <thead>
      <tr>
        <th>신청번호</th>
        <th>카드번호</th>
        <th>카드명</th>
          <th>카드이미지</th>
        <th>상태</th>
        <th>신용카드</th>
        <th>KYC 계좌보유</th>
        <th>단기다중</th>
        <th>신청일</th>
        <th>수정일</th>
      </tr>
    </thead>
    <tbody id="appTableBody"></tbody>
  </table>
  <div id="appEmpty" style="display:none;">가입/신청 내역이 없습니다.</div>
  <div id="appLoading" style="display:none;">불러오는 중...</div>

  <script src="/js/adminHeader.js"></script>
  <script>
  (function() {
	  var allUsers = [];
	  var filteredUsers = [];
	  var currentPage = 1;
	  var pageSize = 10;

    document.addEventListener("DOMContentLoaded", function() {
      // 사용자 전체 목록 불러오기
      fetch("/admin/user/list")
        .then(function(response) {
          if (!response.ok) throw new Error("서버 응답 오류");
          return response.json();
        })
        .then(function(data) {
        	allUsers = Array.isArray(data) ? data : [];
        	 filteredUsers = allUsers.slice();
             render();
        })
        .catch(function(error) {
          console.error("에러 발생:", error);
        });

   // 검색 입력
      var searchInput = document.getElementById("searchInput");
      searchInput.addEventListener("input", function(e) {
        var keyword = (e.target.value || "").trim().toLowerCase();
        filteredUsers = allUsers.filter(function(user) {
          return ((user.name || "") + "").toLowerCase().includes(keyword);
        });
        currentPage = 1;
        render();
      });

      // 페이지 크기 변경
      var pageSizeSelect = document.getElementById("pageSize");
      pageSizeSelect.addEventListener("change", function(e) {
        var v = parseInt(e.target.value, 10);
        pageSize = isNaN(v) ? 10 : v;
        currentPage = 1;
        render();
      });
    });

    // 메인 렌더
    function render() {
      var total = filteredUsers.length;
      var totalPages = Math.max(1, Math.ceil(total / pageSize));
      if (currentPage > totalPages) currentPage = totalPages;

      var startIdx = (currentPage - 1) * pageSize;
      var endIdx = Math.min(startIdx + pageSize, total);
      var pageSlice = filteredUsers.slice(startIdx, endIdx);

      renderTable(pageSlice);
      renderCountText(total, startIdx, endIdx);
      renderPagination(totalPages);
    }

    // 테이블 렌더링 (페이지 조각만)
    function renderTable(usersPage) {
      var tbody = document.getElementById("userTableBody");
      tbody.innerHTML = "";

      usersPage.forEach(function(user) {
        var row = document.createElement("tr");

        var nameTd = document.createElement("td");
        nameTd.textContent = user.name != null ? user.name : "-";

        var idTd = document.createElement("td");
        idTd.textContent = user.username != null ? user.username : "-";

        row.appendChild(nameTd);
        row.appendChild(idTd);
        tbody.appendChild(row);

        // 클릭 시 상세 정보 표시
        row.addEventListener("click", function() {
          showUserDetails(user);
        });
      });
    }

    // 상단 우측 "n명 중 x–y 표시" 텍스트
    function renderCountText(total, startIdx, endIdx) {
      var el = document.getElementById("userCountText");
      if (!el) return;
      if (total === 0) {
        el.textContent = "0명";
        return;
      }
      el.textContent = total + "명 중 " + (startIdx + 1) + "–" + endIdx + " 표시";
    }

    // 페이지네이션 렌더
    function renderPagination(totalPages) {
      var container = document.getElementById("pagination");
      if (!container) return;
      container.innerHTML = "";

      // 유틸: 버튼 생성
      function mkBtn(label, disabled, onClick, extraClass) {
        var b = document.createElement("button");
        b.textContent = label;
        if (extraClass) b.className = extraClass;
        if (disabled) b.setAttribute("disabled", "disabled");
        b.addEventListener("click", function() { if (!disabled) onClick(); });
        return b;
      }
      // 유틸: 스팬(점3개)
      function mkSpan(txt) {
        var s = document.createElement("span");
        s.textContent = txt;
        s.style.border = "none";
        s.style.background = "transparent";
        return s;
      }

      var isFirst = currentPage === 1;
      var isLast = currentPage === totalPages;

      // 처음/이전
      container.appendChild(mkBtn("≪ 처음", isFirst, function(){ currentPage = 1; render(); }));
      container.appendChild(mkBtn("‹ 이전", isFirst, function(){ currentPage -= 1; render(); }));

      // 가운데 숫자 (윈도우 5)
      var windowSize = 5;
      var half = Math.floor(windowSize / 2);
      var start = Math.max(1, currentPage - half);
      var end = Math.min(totalPages, start + windowSize - 1);
      if (end - start + 1 < windowSize) {
        start = Math.max(1, end - windowSize + 1);
      }

      if (start > 1) {
        container.appendChild(mkBtn("1", false, function(){ currentPage = 1; render(); }));
        if (start > 2) container.appendChild(mkSpan("…"));
      }

      for (var p = start; p <= end; p++) {
        if (p === currentPage) {
          var active = mkBtn(String(p), true, function(){}, "active");
          container.appendChild(active);
        } else {
          container.appendChild(mkBtn(String(p), false, (function(pp){ 
            return function(){ currentPage = pp; render(); };
          })(p)));
        }
      }

      if (end < totalPages) {
        if (end < totalPages - 1) container.appendChild(mkSpan("…"));
        container.appendChild(mkBtn(String(totalPages), false, function(){ currentPage = totalPages; render(); }));
      }

      // 다음/마지막
      container.appendChild(mkBtn("다음 ›", isLast, function(){ currentPage += 1; render(); }));
      container.appendChild(mkBtn("마지막 ≫", isLast, function(){ currentPage = totalPages; render(); }));
    }

    // 상세 정보 출력
    function showUserDetails(user) {
      setText("detailMemberNo", user.memberNo != null ? user.memberNo : "-");
      setText("detailUsername", user.username != null ? user.username : "-");
      setText("detailName", user.name != null ? user.name : "-");

      // 성별/나이
      setText("detailGender", getGender(user.rrnGender));
      var age = calculateAge(user.rrnFront, user.rrnGender);
      setText("detailAge", age === "-" ? "-" : (age + "세"));

      // 주소: join 사용(EL 충돌 회피)
      var address = [user.zipCode || "", user.address1 || "", user.address2 || ""]
        .filter(function(x){ return !!x; })
        .join(" ");
      setText("detailAddress", address || "-");

      document.getElementById("userDetailBox").style.display = "block";

      // 신청내역 로딩
      if (user.memberNo != null) {
        loadApplications(user.memberNo);
      } else {
        resetAppsView();
      }
    }

    function setText(id, value) {
      var el = document.getElementById(id);
      if (el) el.textContent = value;
    }

    // --- 가입/신청 내역 렌더링 ---
    function resetAppsView() {
      document.getElementById("appTableBody").innerHTML = "";
      document.getElementById("appEmpty").style.display = "none";
      document.getElementById("appTable").style.display = "none";
      document.getElementById("appLoading").style.display = "none";
    }

    function loadApplications(memberNo) {
      var appTable   = document.getElementById("appTable");
      var appBody    = document.getElementById("appTableBody");
      var appEmpty   = document.getElementById("appEmpty");
      var appLoading = document.getElementById("appLoading");

      appBody.innerHTML = "";
      appEmpty.style.display = "none";
      appTable.style.display = "none";
      appLoading.style.display = "block";

      // 템플릿 리터럴 금지 → 문자열 더하기
      fetch("/admin/user/" + memberNo + "/applications")
        .then(function(r) {
          if (!r.ok) throw new Error("신청 내역 조회 실패");
          return r.json();
        })
        .then(function(list) {
          appLoading.style.display = "none";

          if (!list || list.length === 0) {
            appEmpty.textContent = "가입/신청 내역이 없습니다.";
            appEmpty.style.display = "block";
            return;
          }

          list.forEach(function(app) {
        	  var imgHtml = app.cardUrl
              ? '<img src="' + app.cardUrl + '" alt="카드" style="width:80px;height:auto;border-radius:8px;object-fit:contain;">'
              : '-';

            var tr = document.createElement("tr");
            tr.innerHTML =
              "<td>" + (app.applicationNo != null ? app.applicationNo : "-") + "</td>" +
              "<td>" + (app.cardNo != null ? app.cardNo : "-") + "</td>" +
              "<td>" + (app.cardName ? app.cardName : "-") + "</td>" +
              "<td>" + imgHtml + "</td>" + 
              "<td>" + statusToKorean(app.status) + "</td>" +
              "<td>" + ynToText(app.isCreditCard) + "</td>" +
              "<td>" + ynToText(app.hasAccountAtKyc) + "</td>" +
              "<td>" + ynToText(app.isShortTermMulti) + "</td>" +
              "<td>" + formatDate(app.createdAt) + "</td>" +
              "<td>" + formatDate(app.updatedAt) + "</td>";
            appBody.appendChild(tr);
          });

          appTable.style.display = "table";
        })
        .catch(function(err) {
          console.error(err);
          appLoading.style.display = "none";
          appEmpty.textContent = "내역을 불러오는 중 오류가 발생했습니다.";
          appEmpty.style.display = "block";
        });
    }

    // 공통 유틸
    function ynToText(v) {
      if (v === "Y") return "예";
      if (v === "N") return "아니오";
      return "-";
    }
    function statusToKorean(s) {
      switch (s) {
        case "DRAFT": return "작성중";
        case "KYC_PASSED": return "본인인증 완료";
        case "ACCOUNT_CONFIRMED": return "계좌확인";
        case "OPTIONS_SET": return "옵션설정";
        case "ISSUED": return "발급완료";
        case "CANCELLED": return "취소";
        default: return s || "-";
      }
    }
    function getGender(code) {
      if (code === "1" || code === "3") return "남자";
      if (code === "2" || code === "4") return "여자";
      return "알 수 없음";
    }
    function calculateAge(rrnFront, genderCode) {
      if (!rrnFront || rrnFront.length !== 6) return "-";
      var yearPart = parseInt(rrnFront.substring(0, 2), 10);
      var monthPart = parseInt(rrnFront.substring(2, 4), 10);
      var dayPart = parseInt(rrnFront.substring(4, 6), 10);
      var fullYear;
      if (genderCode === "1" || genderCode === "2") {
        fullYear = 1900 + yearPart;
      } else if (genderCode === "3" || genderCode === "4") {
        fullYear = 2000 + yearPart;
      } else {
        return "-";
      }
      var today = new Date();
      var birthDate = new Date(fullYear, monthPart - 1, dayPart);
      var age = today.getFullYear() - fullYear;
      var isBirthdayPassed =
        today.getMonth() > birthDate.getMonth() ||
        (today.getMonth() === birthDate.getMonth() && today.getDate() >= birthDate.getDate());
      if (!isBirthdayPassed) age--;
      return age;
    }
    function formatDate(s) {
      // 백엔드가 문자열로 내려준다고 가정
      if (!s) return "-";
      return s;
    }
  })();
  </script>
</body>
</html>
