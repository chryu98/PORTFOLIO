<%@ page contentType="text/html;charset=UTF-8" language="java"%>
<html>
<head>
<meta charset="UTF-8">
<title>카드 승인/반려 목록</title>

<style>
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

.card-table {
	width: 100%;
	border-collapse: separate;
	border-spacing: 0;
	border: 1px solid #dee2e6;
	border-radius: 6px;
	overflow: hidden;
	font-size: 14px;
	background-color: #f8f9fa;
	color: #212529;
	table-layout: auto;
}

.card-table thead {
	background-color: #f1f3f5;
}

.card-table thead th {
	padding: 14px;
	text-align: center;
	font-weight: 700;
	color: #212529;
	border-right: 1px solid #dee2e6;
}

.card-table thead th:last-child {
	border-right: none;
}

.card-table tbody td {
	padding: 14px;
	text-align: center;
	background-color: #ffffff;
	border-top: 1px solid #dee2e6;
	border-right: 1px solid #dee2e6;
	word-wrap: break-word;
}

.card-table tbody td:last-child {
	border-right: none;
}

.card-table thead tr:first-child th:first-child {
	border-top-left-radius: 6px;
}
.card-table thead tr:first-child th:last-child {
	border-top-right-radius: 6px;
}
.card-table tbody tr:last-child td:first-child {
	border-bottom-left-radius: 6px;
}
.card-table tbody tr:last-child td:last-child {
	border-bottom-right-radius: 6px;
}

#noDataMessage {
	text-align: center;
	color: #999;
	font-size: 1.1em;
	margin-top: 20px;
}

#pagination {
	margin-top: 20px;
	text-align: center;
}

#pagination button {
	background-color: #ffffff;
	border: 1px solid #ccc;
	color: #333;
	padding: 6px 12px;
	margin: 0 3px;
	border-radius: 4px;
	cursor: pointer;
	transition: background-color 0.2s, color 0.2s;
}

#pagination button:hover:not(:disabled) {
	background-color: #007bff;
	color: white;
	border-color: #007bff;
}

#pagination button:disabled {
	background-color: #e9ecef;
	color: #999;
	cursor: default;
}

.admin-content-wrapper {
	display: flex;
	justify-content: center;
	padding: 0 200px;
	box-sizing: border-box;
}

/* 모달 */
.modal {
	display: none;
	position: fixed;
	z-index: 1000;
	left: 0; top: 0;
	width: 100%; height: 100%;
	background-color: rgba(0,0,0,0.4);
	justify-content: center;
	align-items: center;
}

.modal-content {
	background-color: #fff;
	margin: auto;
	padding: 20px;
	border-radius: 6px;
	width: 80%;
	max-width: 500px;
	box-shadow: 0 2px 8px rgba(0,0,0,0.2);
}

.close {
	float: right;
	font-size: 28px;
	font-weight: bold;
	cursor: pointer;
}

.modal-actions {
	margin-top: 20px;
	text-align: right;
}

.modal-actions button {
	padding: 8px 16px;
	margin-left: 10px;
	border: none;
	border-radius: 4px;
	cursor: pointer;
	font-size: 14px;
}

#approveBtn {
	background-color: #4CAF50;
	color: white;
}

#rejectBtn {
	background-color: #f44336;
	color: white;
}
</style>

<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
<jsp:include page="../fragments/header.jsp"></jsp:include>

<div class="admin-content-wrapper">
	<div class="inner">
		<h2>카드 승인/반려 목록</h2>
		<table id="approvalTable" class="card-table">
			<thead>
				<tr>
					<th>번호</th>
					<th>신청자명</th>
					<th>카드명</th>
					<th>상태</th>
					<th>추천</th>
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

<!-- 모달 -->
<div id="detailModal" class="modal">
	<div class="modal-content">
		<span class="close">&times;</span>
		<h3>카드 신청 상세</h3>
		<div id="modalBody"></div>
		<div class="modal-actions">
			<button id="approveBtn">승인</button>
			<button id="rejectBtn">반려</button>
		</div>
	</div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
	const tbody = document.querySelector('#approvalTable tbody');
	const thead = document.querySelector('#approvalTable thead');
	const noDataMessage = document.getElementById('noDataMessage');
	const pagination = document.getElementById('pagination');

	let allCards = [];
	let personMap = {};

	// 서버에서 데이터 가져오기
	fetch('/admin/card-approval/get-list')
		.then(res => res.json())
		.then(data => {
			allCards = data.cards;
			personMap = data.persons;
			renderTable(allCards, personMap);
		})
		.catch(err => console.error(err));

	function formatDate(dateString) {
	    if (!dateString) return '';
	    return dateString.substring(0, 10); // 2025-07-31 형태로 바로 추출
	}

	function renderTable(cards, persons) {
		tbody.innerHTML = '';
		if(!cards.length){
			thead.style.display='none';
			document.getElementById('approvalTable').style.display='none';
			noDataMessage.style.display='block';
			pagination.style.display='none';
			return;
		}

		thead.style.display='';
		document.getElementById('approvalTable').style.display='';
		noDataMessage.style.display='none';

		cards.forEach((card, idx)=>{
			const person = persons[card.applicationNo];
			const tr = document.createElement('tr');
			tr.innerHTML = '<td>'+ (idx+1) +'</td>'+
						   '<td>'+ (person?.name||'-') +'</td>'+
						   '<td>'+ (card.cardName||'-') +'</td>'+
						   '<td>'+ card.status +'</td>'+
						   '<td>'+ (card.recommendation||'-') +'</td>'+
						   '<td>'+ formatDate(card.createdAt) +'</td>'+
						   '<td><button class="viewBtn" data-id="'+card.applicationNo+'">보기</button></td>';
			tbody.appendChild(tr);
		});

		setupPagination();

		document.querySelectorAll('.viewBtn').forEach(btn=>{
			btn.addEventListener('click', function(){
				const appNo = this.dataset.id;
				const card = allCards.find(c=>c.applicationNo==appNo);
				const person = personMap[appNo];
				openModal(card, person);
			});
		});
	}

	function openModal(card, person){
		const modal = document.getElementById('detailModal');
		const modalBody = document.getElementById('modalBody');
		const approveBtn = document.getElementById('approveBtn');
		const rejectBtn = document.getElementById('rejectBtn');

		modalBody.innerHTML =
			'<p><strong>신청자:</strong> '+ (person?.name||'-') +'</p>'+
			'<p><strong>연락처:</strong> '+ (person?.phone||'-') +'</p>'+
			'<p><strong>이메일:</strong> '+ (person?.email||'-') +'</p>'+
			'<p><strong>주소:</strong> '+ (person?.address1||'-') +' '+ (person?.address2||'') +'</p>'+
			'<p><strong>신청 카드:</strong> '+ (card.cardName||'-') +'</p>'+
			'<p><strong>상태:</strong> '+ card.status +'</p>'+
			'<p><strong>추천:</strong> '+ (card.recommendation||'-') +'</p>';

		approveBtn.dataset.id = card.applicationNo;
		rejectBtn.dataset.id = card.applicationNo;
		modal.style.display = 'flex';
	}

	const modal = document.getElementById('detailModal');
	modal.querySelector('.close').onclick = ()=> modal.style.display='none';
	window.addEventListener('click', e=>{ if(e.target==modal) modal.style.display='none'; });

	document.getElementById('approveBtn').onclick = ()=>{
		const appNo = document.getElementById('approveBtn').dataset.id;
		if(appNo) updateStatus(appNo, 'APPROVED', modal);
	};
	document.getElementById('rejectBtn').onclick = ()=>{
		const appNo = document.getElementById('rejectBtn').dataset.id;
		if(appNo) updateStatus(appNo, 'REJECTED', modal);
	};

	function updateStatus(appNo, status, modal){
		fetch(`/admin/card-approval/update-status/${appNo}`, {
			method:'POST',
			headers:{'Content-Type':'application/json'},
			body: JSON.stringify({status})
		})
		.then(res=>res.json())
		.then(res=>{
			if(res.success){
				alert('상태가 변경되었습니다.');
				modal.style.display='none';
				location.reload();
			}else{
				alert('변경 실패: '+res.message);
			}
		})
		.catch(err=>console.error(err));
	}

	const itemsPerPage = 10;
	let currentPage = 1;

	function setupPagination(){
		const rows = tbody.querySelectorAll('tr');
		const pageInfo = document.getElementById('pageInfo');
		const prevBtn = document.getElementById('prevPage');
		const nextBtn = document.getElementById('nextPage');
		const totalPages = Math.ceil(rows.length / itemsPerPage);

		if(rows.length <= itemsPerPage){ pagination.style.display='none'; return;}
		pagination.style.display='block';

		function renderPage(page){
			const start = (page-1)*itemsPerPage;
			const end = start+itemsPerPage;
			rows.forEach((row, idx)=> row.style.display=(idx>=start && idx<end)?'':'none');
			currentPage = page;

			pageInfo.innerHTML='';
			for(let i=1;i<=totalPages;i++){
				const btn = document.createElement('button');
				btn.textContent = i;
				if(i===currentPage){ btn.disabled=true; btn.style.fontWeight='bold'; }
				btn.onclick=()=>renderPage(i);
				pageInfo.appendChild(btn);
			}
			prevBtn.disabled=currentPage===1;
			nextBtn.disabled=currentPage===totalPages;
		}

		prevBtn.onclick=()=>{ if(currentPage>1) renderPage(currentPage-1); };
		nextBtn.onclick=()=>{ if(currentPage<totalPages) renderPage(currentPage+1); };
		renderPage(currentPage);
	}
});
</script>

</body>
</html>
