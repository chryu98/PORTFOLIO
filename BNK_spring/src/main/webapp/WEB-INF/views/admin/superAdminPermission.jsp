<%@ page contentType="text/html;charset=UTF-8" language="java"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>카드 승인 검토</title>
<style>
/* ===== 글로벌 ===== */
body {
	margin: 0;
	font-family: 'Noto Sans KR', 'Apple SD Gothic Neo', sans-serif;
	background-color: #f9f9f9;
	color: #2c3e50;
	line-height: 1.6;
}

h1 {
	font-size: 22px;
	text-align: center;
	font-weight: 600;
	color: #34495e;
	padding: 40px;
}

/* ===== 테이블 스타일 ===== */
table {
	width: 50%;
	margin: 0 auto;
	border-collapse: collapse;
	background-color: #fff;
	border-radius: 8px;
	overflow: hidden;
	box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
}

thead {
	background-color: #f1f3f5;
}

thead th {
	padding: 14px 12px;
	font-size: 14px;
	color: #495057;
	border-bottom: 1px solid #dee2e6;
}

tbody td {
	padding: 14px 12px;
	font-size: 14px;
	text-align: center;
	border-bottom: 1px solid #f1f3f5;
}

tbody tr:hover {
	background-color: #f8f9fa;
}

/* ===== 버튼 ===== */
button {
	color: black;
	border: none;
	padding: 8px 14px;
	font-size: 14px;
	border-radius: 4px;
	cursor: pointer;
	transition: background-color 0.2s ease, transform 0.1s ease;
}

#closeBtn {
	padding: 8px 14px; /* 다른 버튼과 동일하게 */
	font-size: 14px; /* 다른 버튼과 동일하게 */
	line-height: 1; /* 높이 균일하게 맞추기 */
	height: 34px; /* 버튼 높이 고정 (다른 버튼 높이와 맞춰서 조정) */
	display: inline-flex;
	/* 버튼 안 텍스트 중앙 정렬 */
	align-items: center;
	justify-content: center;
	border-radius: 4px;
	border: none;
	background-color: #007bff;
	/* 필요시 배경색 조정 */
	color: white;
	cursor: pointer;
	transition: background-color 0.2s ease;
	line-height: 1; /* 높이 균일하게 맞추기 */
	height: 34px; /* 버튼 높이 고정 (다른 버튼 높이와 맞춰서 조정) */
	display: inline-flex; /* 버튼 안 텍스트 중앙 정렬 */
	align-items: center;
	justify-content: center;
	border-radius: 4px;
	border: none;
	background-color: #007bff; /* 필요시 배경색 조정 */
	color: white;
}

#closeBtn:hover {
	background-color: #0056b3;
}

button:hover {
	background-color: #2980b9;
}

button:active {
	transform: scale(0.97);
}

button:disabled {
	background-color: #ced4da;
	cursor: not-allowed;
}

/* ===== 페이지네이션 ===== */
#pagination button {
	background-color: #fff;
	color: #495057;
	border: 1px solid #ced4da;
	padding: 6px 10px;
	margin: 0 2px;
	border-radius: 4px;
	font-size: 14px;
	transition: background-color 0.2s;
}

#pagination button:hover {
	background-color: #e9ecef;
}

#pagination button:disabled {
	color: #adb5bd;
	background-color: #f1f3f5;
}

/* 모달 배경 오버레이 */
#modalOverlay {
	display: none;
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	background: rgba(0, 0, 0, 0.4);
	z-index: 999;
}

/* 모달 전체 wrapper */
#modalContainer {
	display: none;
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	justify-content: center;
	align-items: center;
	flex-direction: column; /* 수직 정렬 추가 */
	gap: 20px;
	z-index: 1000;
}

#modalTemp, #modalOriginal {
	display: none;
	background: #fff;
	padding: 30px 40px;
	box-shadow: 0 0 15px rgba(0, 0, 0, 0.3);
	width: 520px;
	max-height: 80vh;
	overflow-y: auto;
	font-size: 14px;
	color: #333;
	box-sizing: border-box;
	position: relative;
}

/* 제목 스타일 */
#modalTemp h2, #modalOriginal h2 {
	font-size: 18px;
	font-weight: 600;
	margin-bottom: 20px;
	color: #2c3e50;
}

/* 인풋, 텍스트에어리어, 셀렉트 */
#modalTemp input, #modalTemp textarea, #modalTemp select, #modalOriginal input,
	#modalOriginal textarea, #modalOriginal select {
	width: 100%;
	padding: 8px 12px;
	margin-bottom: 15px;
	border: 1px solid #ccc;
	border-radius: 4px;
	font-size: 14px;
	box-sizing: border-box;
	font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

/* textarea 크기 */
#modalTemp textarea, #modalOriginal textarea {
	min-height: 80px;
	resize: vertical;
}

/* 읽기 전용 필드 */
#modalTemp input[readonly], #modalOriginal input[readonly], #modalTemp textarea[readonly],
	#modalOriginal textarea[readonly] {
	color: #555;
	background-color: #f9f9f9;
	border: 1px solid #ddd;
	cursor: default;
}

/* 버튼 */
#modalTemp button, #modalOriginal button {
	background-color: #007bff;
	border: none;
	color: white;
	padding: 8px 16px;
	border-radius: 5px;
	font-size: 14px;
	margin-right: 8px;
	cursor: pointer;
	transition: background-color 0.2s ease;
}

#modalTemp p {
	display: flex;
	align-items: center;
	gap: 6px; /* input과 span 사이 간격 */
}

#modalTemp p label {
	min-width: 72px;
	margin-right: 8px;
}

.input-with-label {
	display: flex;
	align-items: center;
	gap: 6px;
	flex-wrap: nowrap; /* 👉 줄바꿈 방지 */
}

.input-with-label input, .input-with-label textarea {
	flex: none;
	margin-right: 4px;
	min-width: 0; /* 👉 넘침 방지 */
}

.edit-label {
	color: red;
	font-weight: bold;
	font-size: 13px;
	white-space: nowrap;
	margin-left: 6px; /* 👉 input과 간격 */
}

/* 각각 모달 박스는 고정 크기, position: relative 또는 static */
.modalBox {
	position: relative;
	background: #fff;
	padding: 30px 40px;
	box-shadow: 0 0 15px rgba(0, 0, 0, 0.3);
	width: 520px;
	max-height: 80vh;
	overflow-y: auto;
	box-sizing: border-box;
	color: #333;
	font-size: 14px;
}

.modalBox h2 {
	font-size: 18px;
	color: #2c3e50;
	margin-bottom: 16px;
}

/* ===== 모달 내용 ===== */
.modalBox p {
	margin-bottom: 12px;
	font-size: 14px;
	color: #212529;
}

.modalBox input, .modalBox textarea, .modalBox select {
	width: 100%;
	padding: 8px 10px;
	font-size: 14px;
	border: 1px solid #ced4da;
	border-radius: 4px;
	box-sizing: border-box;
}

.modalBox textarea {
	resize: vertical;
	min-height: 80px;
}

.modal-button-group {
	display: flex;
	justify-content: flex-start;
	gap: 8px;
	margin-top: 16px;
	flex-wrap: wrap;
}

#allButtons {
	display: flex;
	gap: 8px;
	margin-top: 20px;
	flex-wrap: nowrap; /* 줄 바꿈 없이 한 줄로 */
	justify-content: flex-start; /* 왼쪽 정렬 */
	align-items: center; /* 세로 중앙 정렬 */
}

/* 내부 approveButtons 등도 flex */
#approveButtons, #updateButtons, #deleteButtons {
	display: flex;
	gap: 8px;
	margin: 0;
	padding: 0;
}

#rejectSection h3 {
	font-size: 16px;
	color: #2c3e50;
	margin-bottom: 10px;
}

#rejectSection textarea {
	margin-top: 8px;
}

/* ===== 반응형 개선 (선택 사항) ===== */
@media ( max-width : 600px) {
	.modalBox {
		width: 95%;
		padding: 12px;
	}
	table thead {
		display: none;
	}
	table, table tbody, table tr, table td {
		display: block;
		width: 100%;
	}
	table tr {
		margin-bottom: 15px;
		border-bottom: 1px solid #ddd;
		background: #fff;
		padding: 10px;
	}
	table td {
		text-align: right;
		padding-left: 50%;
		position: relative;
	}
	table td::before {
		content: attr(data-label);
		position: absolute;
		left: 10px;
		top: 10px;
		font-weight: bold;
		color: #495057;
		text-align: left;
	}
}

@media ( max-width : 768px) {
	h1 {
		font-size: 18px;
		text-align: center;
	}
	table {
		width: 100%;
		box-shadow: none;
	}
	thead {
		display: none;
	}
	table, tbody, tr, td {
		display: block;
		width: 100%;
	}
	tbody tr {
		margin-bottom: 16px;
		border-radius: 6px;
		border: 1px solid #dee2e6;
		background: #fff;
		padding: 12px;
	}
	tbody td {
		text-align: left;
		padding: 8px 12px;
		position: relative;
	}
	tbody td::before {
		content: attr(data-label);
		font-weight: bold;
		color: #495057;
		display: block;
		margin-bottom: 4px;
	}
	#modalContainer {
		flex-direction: column;
		max-width: 95%;
		width: 95%;
	}

	/* 모달 반응형 */
	.modalBox {
		width: 100%;
		margin-bottom: 16px;
	}
	.modalBox h2 {
		font-size: 16px;
		margin-bottom: 12px;
	}
	.modalBox p {
		margin-bottom: 10px;
	}
	.modalBox input, .modalBox textarea, .modalBox select {
		font-size: 13px;
		padding: 6px 8px;
	}
	#rejectSection h3 {
		font-size: 14px;
	}
	#pagination button {
		font-size: 13px;
		padding: 4px 8px;
	}
}
</style>
<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
	<jsp:include page="../fragments/header.jsp"></jsp:include>
	<h1>카드 승인 검토</h1>

	<table cellpadding="6" width="100%">
		<thead>
			<tr>
				<th>승인 번호</th>
				<th>카드 번호</th>
				<th>상태</th>
				<th>반려 이유</th>
				<th>요청 관리자</th>
				<th>처리 관리자</th>
				<th>요청일</th>
				<th>처리일</th>
				<th>요청 내용</th>
				<th>작업</th>
			</tr>
		</thead>
		<tbody id="permissionTable"></tbody>
	</table>
	<div id="pagination" style="margin-top: 10px; text-align: center;"></div>

	<div id="modalOverlay"></div>

	<div id="modalContainer">
		<div id="modalBoxesWrapper" style="display: flex; gap: 20px;">
			<!-- 기존 카드 모달 -->
			<div id="modalOriginal" class="modalBox">
				<h2>기존 카드 정보</h2>
				<img id="modalCardImgOriginal" src="" alt="카드 이미지"
					style="max-width: 100%; height: auto; margin-bottom: 15px;">
				<p>
					카드명 <input id="originalCardName" readonly>
				</p>
				<p>
					카드 종류 <input id="originalCardType" readonly>
				</p>
				<p>
					브랜드 <input id="originalCardBrand" readonly>
				</p>
				<p>
					연회비 <input id="originalAnnualFee" readonly>
				</p>
				<p>
					발급 대상 <input id="originalIssuedTo" readonly>
				</p>
				<p>
					서비스
					<textarea id="originalService" readonly></textarea>
				</p>
				<p>
					부가 서비스
					<textarea id="originalSService" readonly></textarea>
				</p>
				<span> 상태 <input id="originalCardStatus" readonly>
				</span>
				<p>
					카드 URL <input id="originalCardUrl" readonly>
				</p>
				<p>
					슬로건 <input id="originalCardSlogan" readonly>
				</p>
				<p>
					주의사항
					<textarea id="originalCardNotice" readonly></textarea>
				</p>
			</div>

			<!-- TEMP 카드 모달 -->
			<div id="modalTemp" class="modalBox">
				<h2>요청 카드 정보</h2>
				<img id="modalCardImgTemp" src="" alt="카드 이미지"
					style="max-width: 100%; height: auto; margin-bottom: 15px;">
				<input type="hidden" id="modalCardNo">

				<div class="field-row">
					<label>카드명</label> <span class="edit-label" style="display: none;">(변경됨)</span>
					<div class="input-with-label">
						<input id="modalCardName" readonly>
					</div>
				</div>
				<div class="field-row">
					<label>카드 종류</label> <span class="edit-label"
						style="display: none;">(변경됨)</span>
					<div class="input-with-label">
						<input id="modalCardType" readonly>
					</div>
				</div>
				<div class="field-row">
					<label>브랜드</label> <span class="edit-label" style="display: none;">(변경됨)</span>
					<div class="input-with-label">
						<input id="modalCardBrand" readonly>
					</div>
				</div>
				<div class="field-row">
					<label>연회비</label> <span class="edit-label" style="display: none;">(변경됨)</span>
					<div class="input-with-label">
						<input id="modalAnnualFee" readonly>
					</div>
				</div>
				<div class="field-row">
					<label>발급 대상</label> <span class="edit-label"
						style="display: none;">(변경됨)</span>
					<div class="input-with-label">

						<input id="modalIssuedTo" readonly>
					</div>
				</div>
				<div class="field-row">
					<label>서비스</label> <span class="edit-label" style="display: none;">(변경됨)</span>
					<div class="input-with-label">

						<textarea id="modalService" readonly></textarea>

					</div>
				</div>
				<div class="field-row">
					<label>부가 서비스</label> <span class="edit-label"
						style="display: none;">(변경됨)</span>
					<div class="input-with-label">
						<textarea id="modalSService" readonly></textarea>

					</div>
				</div>
				<div class="field-row">
					<label>상태</label> <span class="edit-label" style="display: none;">(변경됨)</span>
					<div class="input-with-label">
						<input id="modalCardStatus" readonly>

					</div>
				</div>
				<div class="field-row">
					<label>카드 URL</label> <span class="edit-label"
						style="display: none;">(변경됨)</span>
					<div class="input-with-label">
						<input id="modalCardUrl" readonly>
					</div>
				</div>
				<div class="field-row">
					<label>슬로건</label><span class="edit-label" style="display: none;">(변경됨)</span>
					<div class="input-with-label">
						<input id="modalCardSlogan" readonly>
					</div>
				</div>
				<div class="field-row">
					<label>주의사항</label> <span class="edit-label" style="display: none">(변경됨)</span>
					<div class="input-with-label">
						<textarea id="modalCardNotice" readonly></textarea>

					</div>
				</div>
			</div>

			<!-- 검토 모달 위에 뜨는 보류/불허 모달 -->
			<div id="rejectOverlay"
				style="display: none; position: fixed; z-index: 1100; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); justify-content: center; align-items: center;">
				<div id="rejectModal"
					style="background: white; padding: 20px; border-radius: 8px; width: 400px; box-shadow: 0 0 15px rgba(0, 0, 0, 0.3);">
					<h3>보류/불허 처리</h3>
					<select id="rejectStatus" style="width: 100%; margin-bottom: 10px;">
						<option value="보류">보류</option>
						<option value="불허">불허</option>
					</select>
					<textarea id="rejectReason" placeholder="사유를 입력하세요"
						style="width: 100%; height: 80px; margin-bottom: 10px;"></textarea>
					<div style="display: flex; justify-content: flex-end; gap: 8px;">
						<button onclick="submitReject()">처리</button>
						<button onclick="closeReject()">취소</button>
					</div>
				</div>
			</div>
		</div>

		<div id="buttonsContainer"
			style="display: flex; justify-content: center; gap: 10px; margin-top: 20px;">
			<div id="allButtons"
				style="display: flex; gap: 8px; margin-top: 10px; flex-wrap: wrap;">
				<div id="approveButtons"
					style="display: none; display: flex; gap: 8px;">
					<button onclick="approve()">등록</button>
					<button onclick="openRejectModal()">보류/불허</button>
				</div>
				<div id="updateButtons"
					style="display: none; display: flex; gap: 8px;">
					<button onclick="update()">수정</button>
					<button onclick="openRejectModal()">보류/불허</button>
				</div>
				<div id="deleteButtons"
					style="display: none; display: flex; gap: 8px;">
					<button onclick="remove()">삭제</button>
					<button onclick="openRejectModal()">보류/불허</button>
				</div>
				<button id="closeBtn" onclick="closeModal()">닫기</button>
			</div>
		</div>
	</div>





	<script src="/js/adminHeader.js"></script>
	<script>
let currentPage = 1;


function highlightDifferences(temp, orig) {
	  const fields = [
	    'cardName', 'cardType', 'cardBrand', 'annualFee', 'issuedTo',
	    'service', 'sService', 'cardStatus', 'cardUrl', 'cardSlogan', 'cardNotice'
	  ];

	  fields.forEach(field => {
	    const tempId = 'modal' + capitalize(field);
	    const origId = 'original' + capitalize(field);

	    const tempEl = document.getElementById(tempId);
	    const origEl = document.getElementById(origId);

	    if (!tempEl || !origEl) return;

	 // TEMP 모달에 실제 값을 세팅
	    const tempVal = normalizeValue(temp[field]);
	    const origVal = normalizeValue(orig[field]);

	    console.log(`[${field}] TEMP:`, tempVal, 'ORIG:', origVal);
	    
	    // TEMP 모달 요소에 값 반영 (input/textarea 모두 대응)
	    if (tempEl.tagName === 'INPUT' || tempEl.tagName === 'TEXTAREA') {
	      tempEl.value = tempVal;
	    }

	    // '변경됨' 라벨 span을 찾아서 비교 결과에 따라 표시 제어
	const label = tempEl.closest('.field-row')?.querySelector('.edit-label');

	    
	    if (tempVal !== origVal) {
	    	  if (label && label.classList.contains('edit-label')) {
	    	    label.style.display = 'inline';
	    	  }
	    	} else {
	    	  if (label && label.classList.contains('edit-label')) {
	    	    label.style.display = 'none';
	    	  }
	    	}
	  });
	}


function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

function normalizeValue(value) {
    if (typeof value === 'string') return value.trim();
    if (value === null || value === undefined) return '';
    return String(value).trim();
}

function loadPermissions(page) {
	 if (!page) page = 1;
	    console.log('loadPermissions() 호출됨, page=', page);
	    currentPage = page;

	    const size = 10;

    fetch(`/superadmin/permission/list?page=\${page}&size=\${size}`)
        .then(res => res.json())
        .then(result => {
        	 console.log('API 응답 도착, page=', page, 'result:', result);
        	
            const data = result.content || [];
            const totalPages = result.totalPages;

            const tbody = document.getElementById('permissionTable');
            tbody.innerHTML = '';

            data.forEach(row => {
                const regDate = row.regDate ? row.regDate.substring(0,10) : '';
                const perDate = row.perDate ? row.perDate.substring(0,10) : '';
                const perContent = row.perContent || '';

                let actionHtml = '';
                if (row.status === '대기중') {
                    actionHtml = `<button onclick="openModal(\${row.cardNo}, '\${perContent}')">검토하기</button>`;
                } else {
                    actionHtml = `<span style="color:gray;">처리 완료</span>`;
                }

                const statusColor = row.status === '허가' ? 'green'
                        : row.status === '불허' ? 'red'
                        : row.status === '보류' ? 'orange'
                        : 'black';
                
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td>\${row.perNo}</td>
                    <td>\${row.cardNo}</td>
                    <td style="color: \${statusColor};">\${row.status}</td>
                    <td>\${row.reason}</td>
                    <td>\${row.admin}</td>
                    <td>\${row.sadmin}</td>
                    <td>\${regDate}</td>
                    <td>\${perDate}</td>
                    <td>\${perContent}</td>
                    <td>\${actionHtml}</td>
                `;
                tbody.appendChild(tr);
            });

            renderPagination(totalPages, page);
        });
}


function renderPagination(totalPages, page) {
    const container = document.getElementById('pagination');
    container.innerHTML = '';

    if (totalPages <= 1) return;

    for (let i = 1; i <= totalPages; i++) {
        const btn = document.createElement('button');
        btn.textContent = i;
        btn.style.margin = '0 3px';
        if (i === page) {
            btn.style.fontWeight = 'bold';
        }
        // IIFE로 캡처
        (function(pageNumber) {
            btn.addEventListener('click', function() {
                console.log('버튼 클릭: 페이지', pageNumber);
                loadPermissions(pageNumber);
            });
        })(i);
        container.appendChild(btn);
    }
}


function openModal(cardNo, perContent) {
    // 버튼 초기화
    document.getElementById('approveButtons').style.display = 'none';
    document.getElementById('updateButtons').style.display = 'none';
    document.getElementById('deleteButtons').style.display = 'none';

 	// 모달 오버레이 보이기
    document.getElementById('modalOverlay').style.display = 'block';
    document.getElementById('modalContainer').style.display = 'flex';

    const modalOriginal = document.getElementById('modalOriginal');
    const modalTemp = document.getElementById('modalTemp');

    modalOriginal.style.display = 'none';
    modalTemp.style.display = 'none';

    if (perContent === '등록') {
        document.getElementById('approveButtons').style.display = 'block';
    } else if (perContent === '수정') {
        document.getElementById('updateButtons').style.display = 'block';
    } else if (perContent === '삭제') {
        document.getElementById('deleteButtons').style.display = 'block';
    }
    
    modalTemp.style.display = 'block';

    // 데이터 로드
    fetch('/superadmin/permission/temp/' + cardNo)
    .then(res => res.json())
    .then(data => {
        const temp = data.temp || {};

        document.getElementById('modalCardImgTemp').src = temp.cardUrl || '';
        
        // TEMP 카드 정보
        document.getElementById('modalCardNo').value = temp.cardNo;
        document.getElementById('modalCardName').value = temp.cardName || '';
        document.getElementById('modalCardType').value = temp.cardType || '';
        document.getElementById('modalCardBrand').value = temp.cardBrand || '';
        document.getElementById('modalAnnualFee').value = temp.annualFee || '';
        document.getElementById('modalIssuedTo').value = temp.issuedTo || '';
        document.getElementById('modalService').value = temp.service || '';
        document.getElementById('modalSService').value = temp.sService || '';
        document.getElementById('modalCardStatus').value = temp.cardStatus || '';
        document.getElementById('modalCardUrl').value = temp.cardUrl || '';
        document.getElementById('modalCardSlogan').value = temp.cardSlogan || '';
        document.getElementById('modalCardNotice').value = temp.cardNotice || '';

        if (perContent === '수정') {
            const orig = data.original || {};
            document.getElementById('modalCardImgOriginal').src = orig.cardUrl || '';
            document.getElementById('originalCardName').value = orig.cardName || '(없음)';
            document.getElementById('originalCardType').value = orig.cardType || '(없음)';
            document.getElementById('originalCardBrand').value = orig.cardBrand || '(없음)';
            document.getElementById('originalAnnualFee').value = orig.annualFee || '';
            document.getElementById('originalIssuedTo').value = orig.issuedTo || '';
            document.getElementById('originalService').value = orig.service || '';
            document.getElementById('originalSService').value = orig.sService || '';
            document.getElementById('originalCardStatus').value = orig.cardStatus || '';
            document.getElementById('originalCardUrl').value = orig.cardUrl || '';
            document.getElementById('originalCardSlogan').value = orig.cardSlogan || '';
            document.getElementById('originalCardNotice').value = orig.cardNotice || '';
            document.getElementById('modalOriginal').style.display = 'block';
            
            highlightDifferences(temp, orig);
        }

        document.getElementById('modalOverlay').style.display = 'block';
        document.getElementById('modalTemp').style.display = 'block';
    });

}

function closeModal() {
	document.getElementById('modalOverlay').style.display = 'none';
    document.getElementById('modalContainer').style.display = 'none';
}

// 승인 처리
function approve() { sendApprove(); }
function update() { sendApprove(); }
function sendApprove() {
    const payload = {
        cardNo: document.getElementById('modalCardNo').value,
        cardName: document.getElementById('modalCardName').value,
        cardType: document.getElementById('modalCardType').value,
        cardBrand: document.getElementById('modalCardBrand').value,
        annualFee: document.getElementById('modalAnnualFee').value,
        cardStatus: document.getElementById('modalCardStatus').value
    };
    fetch('/superadmin/permission/approve', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload)
    })
    .then(res => res.json())
    .then(data => {
        alert(data.message);
        closeModal();
        loadPermissions(currentPage); // 현재 페이지 다시 로드
    });
}

// 삭제 처리
function remove() {
    const cardNo = document.getElementById('modalCardNo').value;
    fetch('/superadmin/permission/delete?cardNo=' + cardNo, {
        method: 'POST'
    })
    .then(res => res.json())
    .then(data => {
        alert(data.message);
        closeModal();
        loadPermissions(currentPage); // 현재 페이지 다시 로드
    });
}

// 보류/불허 처리
function openRejectModal() {
    document.getElementById('rejectOverlay').style.display = 'flex';
}

// 🔹 보류/불허 모달 닫기
function closeReject() {
    document.getElementById('rejectOverlay').style.display = 'none';
}

function submitReject() {
    const cardNo = document.getElementById('modalCardNo').value;
    const status = document.getElementById('rejectStatus').value;
    const reason = document.getElementById('rejectReason').value;
    if (!reason.trim()) {
        alert('사유를 입력하세요.');
        return;
    }
    fetch('/superadmin/permission/reject?cardNo='+cardNo+'&status='+status+'&reason='+encodeURIComponent(reason),{
        method:'POST'
    })
    .then(res=>res.json())
    .then(data=>{
        alert(data.message);
        closeReject(); // 위 모달 닫기
        closeModal();  // 전체 검토 모달 닫기
        loadPermissions(currentPage); // 테이블 다시 로드
    });
}



// 초기 로드
if (currentPage === 1) {
    loadPermissions(1);
}
</script>
</body>
</html>
