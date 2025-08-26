<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>고객 정보 관리</title>
<style>
:root{
  /* 공통 팔레트 (영업점 관리와 동일) */
  --bg:#fff;
  --txt:#111;
  --muted:#808089;
  --line:#ececec;
  --card:#f8f9fb;
  --pill:#eef1f7;
  --good:#28a745;
  --bad:#dc3545;
  --neutral:#6c757d;
  --accent:#3b82f6;
  /* 효과 */
  --shadow:0 6px 18px rgba(17,24,39,.06);
  --ring:0 0 0 3px rgba(59,130,246,.18);
}

*{ box-sizing:border-box }
body{
  margin:0;
  background:var(--bg);
  color:var(--txt);
  font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, "Apple SD Gothic Neo", "Malgun Gothic", sans-serif;
}

.container{ max-width:1080px; margin:0 auto; padding:0 12px }

/* 제목 */
h1{
  font-size:28px; font-weight:700; margin:0px 0 12px; text-align:center; padding-top :40px;
}

/* 카드 느낌 공통 */
.card{
  background:#fff; border:1px solid var(--line); border-radius:12px; box-shadow:var(--shadow);
}

/* 검색 바 (영업점 관리 .search 톤) */
.search{
  display:flex; gap:10px; align-items:center;
  padding:10px; margin:0 auto 16px; width:100%; max-width:1100px;
  background:var(--card); border:1px solid var(--line); border-radius:12px; box-shadow:var(--shadow);
}
.search label{
  font-size:12px; color:var(--muted); margin:0 4px 0 2px; white-space:nowrap;
}
.search input[type="text"]{
  flex:1; min-width:160px; height:38px; padding:0 12px 0 38px;
  border:1px solid var(--line); border-radius:8px; outline:none; background:#fff;
}
.search input[type="text"]:focus{ box-shadow:var(--ring); border-color:var(--accent) }
.search .field{
  position:relative; flex:1; display:flex; align-items:center;
}
.search .field::before{
  content:"🔎"; position:absolute; left:10px; top:50%; transform:translateY(-50%); font-size:14px; opacity:.6;
}
.search .select{
  display:flex; align-items:center; gap:8px;
}
.search select{
  height:38px; padding:0 10px; border:1px solid var(--line); border-radius:8px; background:#fff; outline:none;
}
.search select:focus{ box-shadow:var(--ring); border-color:var(--accent) }
.search .status{
  margin-left:auto; font-size:14px; color:var(--muted);
}

/* 버튼 */
.btn{
  display:inline-flex; align-items:center; justify-content:center;
  height:38px; padding:0 12px; gap:6px;
  border:1px solid var(--line); border-radius:8px;
  background:#fff; color:var(--txt); cursor:pointer; text-decoration:none; transition:.15s ease;
}
.btn:hover{ transform:translateY(-1px); box-shadow:var(--shadow) }
.btn:focus-visible{ outline:none; box-shadow:var(--ring) }
.btn.primary{
  background:var(--accent); color:#fff; border-color:var(--accent); min-width:80px;
}
.btn.primary:hover{ filter:brightness(.95) }
.btn.disabled{ pointer-events:none; opacity:.5 }

/* 테이블 */
.table-wrap{ width:100%; max-width:1100px; margin:10px auto 0 }
table{
  width:100%; border-collapse:separate; border-spacing:0;
  background:#fff; border:1px solid var(--line); border-radius:12px; overflow:hidden; box-shadow:var(--shadow);
}
thead th{
  text-align:left; font-size:14px; color:var(--txt);
  background:#fafbfc; border-bottom:1px solid var(--line); padding:12px 14px; font-weight:700;
}
tbody td{
  padding:12px 14px; border-bottom:1px solid var(--line); text-align:left; vertical-align:top;
}
tbody tr:last-child td{ border-bottom:none }
tbody tr{ cursor:pointer; transition:background-color .15s ease }
tbody tr:hover{ background:#fdfefe }

/* 빈 상태 */
tbody:empty::after{
  content:"불러올 데이터가 없습니다.";
  display:block; padding:28px; text-align:center; color:#9ca3af;
}

/* 상세 카드 */
#userDetailBox{
  width:100%; max-width:1100px; margin:16px auto 0; padding:16px 18px; display:none;
}
#userDetailBox h3{ margin:0 0 10px; font-size:18px; }
#userDetailBox p{
  display:grid; grid-template-columns:120px 1fr; gap:8px 14px; margin:8px 0;
}
#userDetailBox strong{ color:var(--muted); font-weight:600 }

/* 가입/신청 테이블 */
#appTable{ width:100%; max-width:1100px; margin:16px auto 0; }
#appEmpty, #appLoading{ width:100%; max-width:1100px; margin:8px auto 0; text-align:center; color:#9ca3af }
#appLoading{ color:#6b7280 }

/* 페이지 상단 우측 카운트 라벨 */
#userCountText{ color:var(--muted) }

/* 페이지네이션 (영업점 관리 톤) */
.pagination{
  width:100%; max-width:1100px; margin:12px auto 0; padding:10px 12px;
  display:flex; gap:6px; align-items:center; justify-content:center;
  background:var(--card); border:1px solid var(--line); border-radius:12px; box-shadow:var(--shadow);
}
.pagination .pages{ display:inline-flex; gap:6px; }
.pagination .ellipsis{
  display:inline-flex; align-items:center; padding:0 6px; color:#9ca3af;
}

/* 반응형 */
@media (max-width:768px){
  thead th:nth-child(2), tbody td:nth-child(2){ white-space:nowrap }
}
</style>

<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
  <jsp:include page="../fragments/header.jsp"></jsp:include>

  <div class="container">
    <h1>고객 정보 관리</h1>

    <!-- 검색/상단 바 -->
    <div class="search">
      <div class="field">
        <label for="searchInput" class="sr-only">고객 이름 검색</label>
        <input type="text" id="searchInput" placeholder="고객 이름을 입력하세요" />
      </div>

      <div class="select">
        <label for="pageSize" style="font-size:12px; color:var(--muted);">표시 개수</label>
        <select id="pageSize">
          <option value="10" selected>10</option>
          <option value="20">20</option>
          <option value="50">50</option>
        </select>
      </div>

      <div id="userCountText" class="status"></div>
    </div>

    <!-- 고객 리스트 테이블 -->
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>고객명</th>
            <th>고객ID</th>
          </tr>
        </thead>
        <tbody id="userTableBody"></tbody>
      </table>
    </div>

    <!-- 페이지네이션 -->
    <div id="pagination" class="pagination"></div>

    <!-- 상세 정보 카드 -->
    <div id="userDetailBox" class="card">
      <h3>고객 상세 정보</h3>
      <p><strong>회원번호:</strong> <span id="detailMemberNo"></span></p>
      <p><strong>아이디:</strong> <span id="detailUsername"></span></p>
      <p><strong>이름:</strong> <span id="detailName"></span></p>
      <p><strong>성별:</strong> <span id="detailGender"></span></p>
      <p><strong>나이:</strong> <span id="detailAge"></span></p>
      <p><strong>주소:</strong> <span id="detailAddress"></span></p>
    </div>

    <!-- 가입/신청 내역 테이블 + 상태 -->
    <div class="table-wrap">
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
    </div>
  </div>

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

    // 렌더 루트
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

    // 테이블 렌더링
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

    // 상단 우측 카운트 텍스트
    function renderCountText(total, startIdx, endIdx) {
      var el = document.getElementById("userCountText");
      if (!el) return;
      if (total === 0) {
        el.textContent = "0명";
        return;
      }
      el.textContent = total + "명 중 " + (startIdx + 1) + "–" + endIdx + " 표시";
    }

    // 페이지네이션 (영업점 관리 스타일의 .btn/.primary 재사용)
    function renderPagination(totalPages) {
      var container = document.getElementById("pagination");
      if (!container) return;
      container.innerHTML = "";

      function mkBtn(label, disabled, onClick, extraClass) {
        var b = document.createElement("button");
        b.textContent = label;
        b.className = "btn" + (extraClass ? (" " + extraClass) : "");
        if (disabled) b.setAttribute("disabled", "disabled");
        b.addEventListener("click", function(){ if (!disabled) onClick(); });
        return b;
      }
      function mkEllipsis() {
        var s = document.createElement("span");
        s.className = "ellipsis";
        s.textContent = "…";
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
      if (end - start + 1 < windowSize) start = Math.max(1, end - windowSize + 1);

      if (start > 1) {
        container.appendChild(mkBtn("1", false, function(){ currentPage = 1; render(); }));
        if (start > 2) container.appendChild(mkEllipsis());
      }

      for (var p = start; p <= end; p++) {
        if (p === currentPage) {
          container.appendChild(mkBtn(String(p), true, function(){}, "primary"));
        } else {
          (function(pp){
            container.appendChild(mkBtn(String(pp), false, function(){ currentPage = pp; render(); }));
          })(p);
        }
      }

      if (end < totalPages) {
        if (end < totalPages - 1) container.appendChild(mkEllipsis());
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

      setText("detailGender", getGender(user.rrnGender));
      var age = calculateAge(user.rrnFront, user.rrnGender);
      setText("detailAge", age === "-" ? "-" : (age + "세"));

      var address = [user.zipCode || "", user.address1 || "", user.address2 || ""]
        .filter(function(x){ return !!x; })
        .join(" ");
      setText("detailAddress", address || "-");

      document.getElementById("userDetailBox").style.display = "block";

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
      if (!s) return "-";
      return s;
    }
  })();
  </script>
</body>
</html>
