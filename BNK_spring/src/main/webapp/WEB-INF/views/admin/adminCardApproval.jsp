<%@ page contentType="text/html;charset=UTF-8" language="java"%>
<html>
<head>
<meta charset="UTF-8">
<title>카드 승인/반려 목록</title>

<style>
/* CSS 부분은 변경하지 않고 그대로 유지했습니다. */
body {
  background-color: #f9f9f9;
  font-family: 'Noto Sans KR', sans-serif;
  margin: 0;
  padding: 0;
  color: #212529;
}
h2 {
  text-align: center;
  margin: 40px auto 30px auto;
  width: fit-content;
}

/* table */
.card-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  border: 1px solid #dee2e6;
  border-radius: 8px;
  overflow: hidden;
  font-size: 14px;
  background-color: #f8f9fa;
  color: #212529;
}
.card-table thead { background-color: #f1f3f5; }
.card-table thead th {
  padding: 14px;
  text-align: center;
  font-weight: 700;
  color: #212529;
  border-right: 1px solid #dee2e6;
}
.card-table thead th:last-child { border-right: none; }
.card-table tbody td {
  padding: 14px;
  text-align: center;
  background-color: #ffffff;
  border-top: 1px solid #dee2e6;
  border-right: 1px solid #dee2e6;
  word-wrap: break-word;
}
.card-table tbody td:last-child { border-right: none; }
.card-table thead tr:first-child th:first-child { border-top-left-radius: 8px; }
.card-table thead tr:first-child th:last-child { border-top-right-radius: 8px; }
.card-table tbody tr:last-child td:first-child { border-bottom-left-radius: 8px; }
.card-table tbody tr:last-child td:last-child { border-bottom-right-radius: 8px; }

.status-badge {
  display:inline-block; padding:4px 10px; border-radius: 999px;
  font-weight:700; font-size:12px; line-height: 1;
}
.status-badge.pending { background:#fff4e6; color:#d9480f; border:1px solid #ffd8a8; }
.status-badge.approved { background:#e6fcf5; color:#087f5b; border:1px solid #c3fae8; }
.status-badge.rejected { background:#ffe3e3; color:#c92a2a; border:1px solid #ffc9c9; }
.status-badge.signed { background:#edf2ff; color:#364fc7; border:1px solid #dbe4ff; }

/* empty/pagination */
#noDataMessage { text-align:center; color:#999; font-size:1.1em; margin-top:20px; }
#pagination { margin-top:20px; text-align:center; }
#pagination button {
  background-color:#ffffff; border:1px solid #ccc; color:#333;
  padding:6px 12px; margin:0 3px; border-radius:4px; cursor:pointer;
  transition: background-color .2s, color .2s;
}
#pagination button:hover:not(:disabled){ background-color:#007bff; color:#fff; border-color:#007bff; }
#pagination button:disabled{ background-color:#e9ecef; color:#999; cursor:default; }

/* layout */
.admin-content-wrapper { display:flex; justify-content:center; padding:0 200px; box-sizing:border-box; }
.inner { width:100%; max-width:1200px; }

/* modal */
.modal {
  display:none; position:fixed; z-index:1000; left:0; top:0; width:100%; height:100%;
  background-color: rgba(0,0,0,0.4); justify-content:center; align-items:center;
}
.modal-content {
  background-color:#fff; margin:auto; padding:24px; border-radius:10px;
  width: 90%; max-width: 720px; box-shadow: 0 12px 40px rgba(0,0,0,.18);
}
.modal-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:8px; }
.modal-title { font-size:18px; font-weight:800; }
.close { font-size:28px; font-weight:bold; cursor:pointer; line-height:1; }

.section { margin-top:14px; padding:14px; border:1px solid #edf2f7; border-radius:8px; background:#fbfbfd; }
.section-title { margin:0 0 10px 0; font-size:15px; font-weight:800; color:#334155; }
.kv { list-style:none; padding:0; margin:0; }
.kv li { display:flex; gap:10px; padding:7px 0; border-bottom:1px dashed #eef2f7; }
.kv li:last-child { border-bottom:none; }
.kv li span:first-child { min-width:130px; color:#6b7280; }
.auto-result { margin-top:8px; font-weight:800; }

.decision-row { display:flex; align-items:center; gap:14px; flex-wrap:wrap; }
.decision-row label { display:flex; align-items:center; gap:6px; }
#rejectReason {
  flex:1 1 300px; min-width:260px; padding:8px 10px; border:1px solid #d1d5db; border-radius:6px;
}

.modal-actions {
  margin-top:16px; display:flex; justify-content:flex-end; gap:10px;
}
.modal-actions button {
  padding:8px 16px; border:none; border-radius:6px; cursor:pointer; font-size:14px; font-weight:700;
}
#cancelBtn { background:#e9ecef; color:#334155; }
#approveBtn { background-color: #4CAF50; color: white; }
#rejectBtn { background-color: #f44336; color: white; }

/* view button */
.viewBtn {
  background:#ffffff; border:1px solid #ced4da; color:#334155; padding:6px 10px; border-radius:6px; cursor:pointer;
}
.viewBtn:hover { background:#f1f3f5; }
.filterBtn {
  background:#ffffff; border:1px solid #ced4da; color:#334155; padding:6px 14px; margin:0 4px; border-radius:6px;
  cursor:pointer; font-weight:600;
  transition: background .2s, color .2s;
}
.filterBtn:hover { background:#f1f3f5; }
.filterBtn.active { background:#2563eb; color:#fff; border-color:#2563eb; }
</style>

<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
<jsp:include page="../fragments/header.jsp"></jsp:include>

<div class="admin-content-wrapper">
  <div class="inner">
    <h2>카드 승인/반려 목록</h2>

	<!-- 상태 필터 버튼 -->
	<div id="statusFilter" style="text-align:center; margin-bottom:20px;">
	  <button class="filterBtn" data-status="ALL">전체</button>
	  <button class="filterBtn" data-status="SIGNED">대기</button>
	  <button class="filterBtn" data-status="APPROVED">승인</button>
	  <button class="filterBtn" data-status="REJECTED">반려</button>
	</div>

    <table id="approvalTable" class="card-table">
      <thead>
        <tr>
          <th>신청번호</th>
          <th>신청자명</th>
          <th>카드명</th>
          <th>상태</th>
          <th>신청일</th>
          <th>보기</th>
        </tr>
      </thead>
      <tbody></tbody>
    </table>

    <div id="noDataMessage" style="display:none;">승인 대기 카드 신청이 없습니다.</div>
    <div id="pagination" style="display:none;">
      <button id="prevPage">이전</button>
      <span id="pageInfo"></span>
      <button id="nextPage">다음</button>
    </div>
  </div>
</div>

<div id="detailModal" class="modal" aria-hidden="true">
  <div class="modal-content" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
    <div class="modal-header">
      <h3 id="modalTitle" class="modal-title">카드 신청 상세 심사</h3>
      <span class="close" aria-label="닫기">&times;</span>
    </div>
    <div id="modalBody"></div>
    <div class="modal-actions">
      <button id="cancelBtn">취소</button>
      <button id="approveBtn">승인하기</button>
      <button id="rejectBtn">반려하기</button>
    </div>
  </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function () {
	// 상태 필터 버튼 이벤트
    const filterBtns = document.querySelectorAll('.filterBtn');
    let currentFilter = 'ALL';

    filterBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        filterBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentFilter = btn.dataset.status;
        const filtered = (currentFilter === 'ALL') 
                          ? allCards 
                          : allCards.filter(c => (c.status || '').toUpperCase() === currentFilter);
        renderTable(filtered);
      });
    });

    // 기본적으로 전체 버튼 활성화
    document.querySelector('.filterBtn[data-status="ALL"]').classList.add('active');

  const tbody = document.querySelector('#approvalTable tbody');
  const thead = document.querySelector('#approvalTable thead');
  const noDataMessage = document.getElementById('noDataMessage');
  const pagination = document.getElementById('pagination');
  
  // ✅ 모달 변수를 전역으로 하나만 선언합니다.
  const modal = document.getElementById('detailModal');
  const modalBody = document.getElementById('modalBody');

  let allCards = [];
  let personMap = {};

  // 서버에서 데이터 가져오기
  fetch('/admin/card-approval/get-list')
    .then(res => res.json())
    .then(data => {
      allCards = Array.isArray(data.cards) ? data.cards : [];
      personMap = data.persons || {};
      allCards.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      renderTable(allCards);
    })
    .catch(err => console.error(err));

  // 유틸
  function formatDate(dateString) {
    if (!dateString) return '';
    return ('' + dateString).substring(0, 10); // yyyy-MM-dd
  }
  function maskResidentId(id) {
    if (!id) return '-';
    const s = ('' + id).replace(/[^0-9-]/g, '');
    const m = s.match(/^(\d{6})-?(\d)/);
    if (m) return m[1] + '-' + m[2] + '******';
    return id;
  }
  function renderStatusBadge(status) {
    const s = (status || '').toUpperCase();
    if (s === 'APPROVED') return '<span class="status-badge approved">승인</span>';
    if (s === 'REJECTED') return '<span class="status-badge rejected">반려</span>';
    if (s === 'SIGNED' || s === 'PENDING' || s === '대기') return '<span class="status-badge signed">대기</span>';
    return '<span class="status-badge pending">' + (status || 'PENDING') + '</span>';
  }
  
  function renderStatusText(status) {
	    const s = (status || '').toUpperCase();
	    if (s === 'APPROVED') return '승인';
	    if (s === 'REJECTED') return '반려';
	    if (s === 'SIGNED' || s === 'PENDING' || s === '대기') return '대기';
	    return status || '대기';
	}

  // 테이블 렌더
  function renderTable(cards) {
    tbody.innerHTML = '';
    if (!cards.length) {
      thead.style.display = 'none';
      document.getElementById('approvalTable').style.display = 'none';
      noDataMessage.style.display = 'block';
      pagination.style.display = 'none';
      return;
    }

    thead.style.display = '';
    document.getElementById('approvalTable').style.display = '';
    noDataMessage.style.display = 'none';

    cards.forEach((card) => {
      const person = personMap[card.applicationNo];
      const tr = document.createElement('tr');
      
      const applicationNo = card.applicationNo ?? '-';
      const personName = (person && person.name) || '-';
      const cardName = card.cardName || '-';
      const statusBadge = renderStatusBadge(card.status);
      const createdAt = formatDate(card.createdAt);

      tr.innerHTML = 
        '<td>' + applicationNo + '</td>' +
        '<td>' + personName + '</td>' +
        '<td>' + cardName + '</td>' +
        '<td>' + statusBadge + '</td>' +
        '<td>' + createdAt + '</td>' +
        '<td><button class="viewBtn" data-id="' + card.applicationNo + '">보기</button></td>';
      tbody.appendChild(tr);
    });

    setupPagination();

    document.querySelectorAll('.viewBtn').forEach(btn => {
      btn.addEventListener('click', function () {
        const applicationNo = this.dataset.id;
        const card = allCards.find(c => String(c.applicationNo) === String(applicationNo));
        const person = personMap[applicationNo];
        openModal(card, person);
      });
    });
  }
  
  function getAutoDecision(person) {
	    const job = person.job || '';
	    const purpose = person.purpose || '';
	    const fundSource = person.fundSource || '';
	    
	    let decision = 'HOLD';
	    let reason = '';

	    if(job === "무직") {
	        if(purpose === "투자" || purpose === "고액결제") {
	            decision = "REJECT";
	            reason = "무직인데 투자/고액결제 목적이어서 승인 불가";
	        } else {
	            decision = "APPROVE";
	            reason = "무직이지만 소액/일상 목적이므로 승인 가능";
	        }
	    }
	    else if(job === "학생") {
	        if(["급여이체","투자","고액결제"].includes(purpose)) {
	            decision = "REJECT";
	            reason = "학생이 급여이체/투자/고액결제 목적이어서 승인 불가";
	        } else {
	            decision = "APPROVE";
	            reason = "학생이지만 일상결제/저축 목적이므로 승인 가능";
	        }
	    }
	    else if(job === "주부") {
	        if(["투자","고액결제"].includes(purpose)) {
	            decision = "HOLD";
	            reason = "주부인데 투자/고액결제 목적이라 자금 출처 확인 필요";
	        } else {
	            decision = "APPROVE";
	            reason = "주부이며 일상결제/저축 목적이므로 승인 가능";
	        }
	    }
	    else if(["직장인","자영업자","프리랜서"].includes(job)) {
	        if(["투자","고액결제"].includes(purpose) && !["근로소득","사업소득","금융소득"].includes(fundSource)) {
	            decision = "HOLD";
	            reason = "투자/고액결제 목적인데 자금 출처가 근로/사업/금융소득이 아니므로 검토 필요";
	        } else {
	            decision = "APPROVE";
	            reason = "목적과 직업/자금 출처가 적합하므로 승인 가능";
	        }
	    }

	    if(fundSource === "기타소득" && (!purpose || purpose.trim() === '')) {
	        decision = "REJECT";
	        reason = "기타소득 선택 시 거래 목적 미입력으로 반려";
	    }

	    if(decision === "HOLD" && reason === '') {
	        reason = "자동 판정 기준에 따라 추가 검토 필요";
	    }

	    return { decision, reason };
	}


  // 모달 열기 함수 (하나로 통합)
  function openModal(card, person) {
    const approveBtn = document.getElementById('approveBtn');
    const rejectBtn = document.getElementById('rejectBtn');

    const cardData = card || {};
    const personData = person || {};
    
    // 백엔드 데이터 구조에 맞게 수정된 부분
    const jobText = personData.job || '확인 불가 -';
    const purposeText = personData.purpose || '확인 불가 -';
    const sourceText = personData.fundSource || '확인 불가 -';
    
    // 중복 가입 여부 데이터가 없으므로 임시로 '확인 불가 -' 처리
    const dupCheck = '확인 불가 -'; 

 	// 자동 판정
    const autoResult = getAutoDecision(personData);
    const recText = (autoResult.decision === 'REJECT') ? '반려 권장'
                    : (autoResult.decision === 'APPROVE') ? '승인 권장'
                    : '보류 / 참고';
    const recReason = autoResult.reason;
    
    const recType = (cardData.recommendation || '').toUpperCase();
    
    const rrn = personData.rrn || personData.residentId || personData.juminNo;
    const address2 = personData.address2 ? ' ' + personData.address2 : '';
    const rejectionReason = cardData.rejectionReason || '';
    
    // HTML 문자열 생성
    const modalHtml = 
      '<div class="section">' +
        '<h4 class="section-title">신청 정보</h4>' +
        '<ul class="kv">' +
          '<li><span>신청자</span><span>' + (personData.name || '-') + ' ' + (rrn ? '(' + maskResidentId(rrn) + ')' : '') + '</span></li>' +
          '<li><span>연락처</span><span>' + (personData.phone || '-') + '</span></li>' +
          '<li><span>이메일</span><span>' + (personData.email || '-') + '</span></li>' +
          '<li><span>주소</span><span>' + (personData.address1 || '-') + address2 + '</span></li>' +
          '<li><span>신청 카드</span><span>' + (cardData.cardName || '-') + '</span></li>' +
          '<li><span>신청일</span><span>' + formatDate(cardData.createdAt) + '</span></li>' +
          '<li><span>상태</span><span>' + renderStatusText(cardData.status) + '</span></li>' +
        '</ul>' +
      '</div>' +

      '<div class="section">' +
        '<h4 class="section-title">심사 자동 판정</h4>' +
        '<ul class="kv">' +
          '<li><span>중복 가입 여부</span><span>' + dupCheck + '</span></li>' +
          '<li><span>직업</span><span>' + jobText + '</span></li>' +
          '<li><span>거래 목적</span><span>' + purposeText + '</span></li>' +
          '<li><span>자금 출처</span><span>' + sourceText + '</span></li>' +
        '</ul>' +
        '<div class="auto-result">' +
        '→ 판정 결과: <strong>' + recText + '</strong><br>' +
        '→ 판정 사유: <span style="color:#555;">' + (recReason || '-') + '</span>' +
      '</div>' +
      '</div>' +

      '<div class="section">' +
        '<h4 class="section-title">관리자 최종 판정</h4>' +
        '<div class="decision-row">' +
          '<label><input type="radio" name="finalDecision" value="APPROVED"> 승인</label>' +
          '<label><input type="radio" name="finalDecision" value="REJECTED"> 반려</label>' +
          '<input id="rejectReason" type="text" placeholder="사유를 입력하세요" value="' + rejectionReason + '">' +
        '</div>' +
      '</div>';
    
    // 생성된 HTML을 모달 바디에 삽입
    modalBody.innerHTML = modalHtml;

    // 현재 상태에 따른 라디오 버튼 초기화
	const currentStatus = (cardData.status || '').toUpperCase();
	const reasonBox = document.getElementById('rejectReason');
	if (currentStatus === 'APPROVED') {
	    const approveRadio = document.querySelector('input[name="finalDecision"][value="APPROVED"]');
	    if (approveRadio) approveRadio.checked = true;
	    reasonBox.style.display = 'block';
	} else if (currentStatus === 'REJECTED') {
	    const rejectRadio = document.querySelector('input[name="finalDecision"][value="REJECTED"]');
	    if (rejectRadio) rejectRadio.checked = true;
	    reasonBox.style.display = 'block';
	} else {
	    reasonBox.style.display = 'none';
	}


    // 라디오 버튼 이벤트: 반려 선택 시 사유 입력창 활성화
    document.querySelectorAll('input[name="finalDecision"]').forEach(radio => {
    	radio.addEventListener('change', (e) => {
            const reasonBox = document.getElementById('rejectReason');
            if (e.target.value === 'REJECTED' || e.target.value === 'APPROVED') {
                reasonBox.style.display = 'block';
                reasonBox.focus();
            } else {
                reasonBox.style.display = 'none';
            }
        });
    });

    // 버튼 dataset
    approveBtn.dataset.id = cardData.applicationNo;
    rejectBtn.dataset.id = cardData.applicationNo;

    // 버튼 동작
    approveBtn.onclick = () => {
	    const selected = document.querySelector('input[name="finalDecision"]:checked');
	    const reason = document.getElementById('rejectReason').value.trim(); // 승인 사유도 동일 input 사용
	    if (!selected || selected.value !== 'APPROVED') {
	        alert('승인을 선택하거나 다시 "승인하기" 버튼을 눌러주세요.');
	        return;
	    }
	    submitDecision(cardData.applicationNo, 'APPROVED', reason);
	};
	rejectBtn.onclick = () => {
	    const selected = document.querySelector('input[name="finalDecision"]:checked');
	    const reason = document.getElementById('rejectReason').value.trim();
	    if (!selected || selected.value !== 'REJECTED') {
	        alert('반려를 선택하거나 다시 "반려하기" 버튼을 눌러주세요.');
	        return;
	    }
	    if (!reason) {
	        alert('사유를 입력해 주세요.');
	        return;
	    }
	    submitDecision(cardData.applicationNo, 'REJECTED', reason);
	};

    // 모달을 보이게 하는 코드
    modal.style.display = 'flex';
    modal.setAttribute('aria-hidden', 'false');
  }

  // 모달 닫기
  // ✅ 모달 변수를 전역에서 가져와 사용합니다.
  modal.querySelector('.close').onclick = () => closeModal();
  document.getElementById('cancelBtn').onclick = () => closeModal();
  window.addEventListener('click', e => { if (e.target === modal) closeModal(); });
  function closeModal() {
    modal.style.display = 'none';
    modal.setAttribute('aria-hidden', 'true');
  }

  // 상태 업데이트
  function submitDecision(applicationNo, status, reason) {
    fetch('/admin/card-approval/update-status/' + applicationNo, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status, reason })
    })
    .then(res => res.json())
    .then(res => {
        if (res.success) {
            alert('상태가 변경되었습니다.');
            closeModal();
            location.reload();
        } else {
            alert('변경 실패: ' + (res.message || '알 수 없는 오류'));
        }
    })
    .catch(err => {
        console.error(err);
        alert('요청 중 오류가 발생했습니다.');
    });
}

  // 페이지네이션
  const itemsPerPage = 10;
  let currentPage = 1;
  function setupPagination() {
    const rows = tbody.querySelectorAll('tr');
    const pageInfo = document.getElementById('pageInfo');
    const prevBtn = document.getElementById('prevPage');
    const nextBtn = document.getElementById('nextPage');
    const totalPages = Math.ceil(rows.length / itemsPerPage);

    if (rows.length <= itemsPerPage) { pagination.style.display = 'none'; return; }
    pagination.style.display = 'block';

    function renderPage(page) {
      const start = (page - 1) * itemsPerPage;
      const end = start + itemsPerPage;
      rows.forEach((row, idx) => row.style.display = (idx >= start && idx < end) ? '' : 'none');
      currentPage = page;

      pageInfo.innerHTML = '';
      for (let i = 1; i <= totalPages; i++) {
        const btn = document.createElement('button');
        btn.textContent = i;
        if (i === currentPage) { btn.disabled = true; btn.style.fontWeight = 'bold'; }
        btn.onclick = () => renderPage(i);
        pageInfo.appendChild(btn);
      }
      prevBtn.disabled = currentPage === 1;
      nextBtn.disabled = currentPage === totalPages;
    }

    prevBtn.onclick = () => { if (currentPage > 1) renderPage(currentPage - 1); };
    nextBtn.onclick = () => { if (currentPage < totalPages) renderPage(currentPage + 1); };
    renderPage(currentPage);
  }
	
  const sidebar = document.querySelector('.sidebar');
  const closeBtn = document.querySelector('.header-close-btn');
  const openBtn = document.querySelector('.header-open-btn');

  if (closeBtn && openBtn && sidebar) {
      // 닫기 버튼 클릭 시
      closeBtn.addEventListener('click', function() {
          sidebar.classList.add('closed');
          closeBtn.classList.add('off'); // 닫기 버튼을 숨김
      });

      // 열기 버튼 클릭 시
      openBtn.addEventListener('click', function() {
          sidebar.classList.remove('closed');
          closeBtn.classList.remove('off'); // 닫기 버튼을 다시 보이게 함
      });
  }

});

</script>

</body>
</html>