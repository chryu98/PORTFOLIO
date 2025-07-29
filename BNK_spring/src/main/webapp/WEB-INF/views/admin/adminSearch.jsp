<%@ page contentType="text/html;charset=UTF-8" language="java"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>검색어 관리 대시보드</title>
<link rel="stylesheet" href="/css/adminstyle.css">
<style>
body {
	background-color: #f9f9f9;
}

/* ===== 전체 구조 ===== */
.container {
	max-width: 1000px;
	margin: 0 auto;
	padding: 0 20px;
}

/* ===== 제목 ===== */
h2 {
	text-align: center;
	margin: 0 auto;
	padding-top: 40px;
	width: fit-content;
}

h3 {
	font-size: 1.4rem;
	margin: 30px 0 20px 0;
	color: #2c3e50;
	border-left: 4px solid #3498db;
	padding-left: 8px;
	font-weight: 600;
}

/* 제목과 버튼/날짜를 같은 줄에 정렬 */
.section-header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-top: 48px;
	margin-bottom: 12px;
}

/* 제목 자체 스타일은 기존 유지 */
.section-header h3 {
	margin: 0;
	color: #2c3e50;
	font-size: 20px;
	font-weight: 600;
}

/* 날짜 + 버튼 그룹: 한 줄로 붙이고 오른쪽 끝 정렬 */
.date-button-group {
	display: flex;
	align-items: center;
	gap: 8px; /* 요소 간 간격 */
	margin-left: auto; /* 좌측 공간을 밀어서 오른쪽 끝으로 이동 */
}

/* ===== 링크 ===== */
a {
	display: inline-block;
	margin-bottom: 20px;
	color: #3498db;
	text-decoration: none;
	font-weight: 500;
}

/* ===== 버튼 ===== */
.button-group {
	margin-bottom: 12px;
	display: flex;
	gap: 10px;
	flex-wrap: wrap;
}

/* ===== 날짜 필터 ===== */
.date-filter {
	display: flex;
	align-items: center;
	gap: 10px;
	margin: 20px 0;
}

input[type="date"] {
	padding: 6px 10px;
	font-size: 14px;
	border: 1px solid #ccc;
	border-radius: 4px;
}

/* ===== 테이블 ===== */
table {
	width: 100%;
	border-collapse: collapse;
	background-color: #fff;
	margin-bottom: 30px;
	box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
	border-radius: 6px;
	overflow: hidden;
}

th, td {
	padding: 12px;
	border: 1px solid #dee2e6;
	text-align: center;
	font-size: 14px;
}

thead {
	background-color: #f1f3f5;
}

tbody tr:hover {
	background-color: #f8f9fa;
}

/* ===== 페이지네이션 ===== */
#log-pagination {
	margin-top: 24px;
	display: flex;
	gap: 6px;
	flex-wrap: wrap;
}

#log-pagination button {
	background-color: #fff;
	border: 1px solid #ccc;
	color: #495057;
	padding: 6px 10px;
	border-radius: 4px;
	font-size: 13px;
	cursor: pointer;
}

#log-pagination button:hover {
	background-color: #e9ecef;
}

#log-pagination button[style*="bold"] {
	background-color: #3498db;
	color: white;
	border-color: #3498db;
}

/*
#recommended-table,
#recommended-table thead,
#prohibited-table,
#prohibited-table thead,
#top-table,
#top-table thead {
	display: none;
}*/

</style>
</head>
<body>
	<jsp:include page="../fragments/header.jsp"></jsp:include>
	<div class="container">
		<h2>검색어 관리 대시보드</h2>

		<a href="/admin/Statistics">통계</a>
		<!-- 추천어 관리 -->
		<div class="section-header">
			<h3>추천어</h3>
			<button onclick="addRecommended()">[+] 추천어 등록</button>
		</div>
		<table id="recommended-table">
			<thead>
				<tr>
					<th>No</th>
					<th>키워드</th>
					<th>등록일</th>
					<th>관리</th>
				</tr>
			</thead>
			<tbody></tbody>
		</table>
		<div id="recommended-no-data"
			style="display: none; text-align: center; color: #999; margin-bottom: 20px;">등록된
			추천어가 없습니다.</div>

		<!-- 금칙어 관리 -->
		<div class="section-header">
			<h3>금칙어</h3>
			<button onclick="addProhibited()">[+] 금칙어 등록</button>
		</div>
		<table id="prohibited-table">
			<thead>
				<tr>
					<th>No</th>
					<th>키워드</th>
					<th>등록일</th>
					<th>관리</th>
				</tr>
			</thead>
			<tbody></tbody>
		</table>
		<div id="prohibited-no-data"
			style="display: none; text-align: center; color: #999; margin-bottom: 20px;">등록된
			금칙어가 없습니다.</div>

		<!-- 인기 검색어 -->
		<div class="section-header">
			<h3>인기 검색어 TOP10</h3>
		</div>
		<table id="top-table">
			<thead>
				<tr>
					<th>키워드</th>
					<th>검색횟수</th>
				</tr>
			</thead>
			<tbody></tbody>
		</table>
		<div id="top-no-data"
			style="display: none; text-align: center; color: #999; margin-bottom: 20px;">인기
			검색어 정보가 없습니다.</div>

		<!-- 기간별 로그 조회 -->
		<div class="section-header">
			<h3>검색어 로그 조회</h3>
			<div class="date-button-group">
				<input type="date" id="fromDate"> ~ <input type="date"
					id="toDate">
				<button onclick="loadLogs()">조회</button>
			</div>
		</div>

		<table id="logs-table" style="display: none;">
			<thead>
				<tr>
					<th>No</th>
					<th>회원번호</th>
					<th>키워드</th>
					<th>추천어</th>
					<th>금칙어</th>
					<th>검색일자</th>
				</tr>
			</thead>
			<tbody></tbody>
		</table>
		<div id="logs-no-data" style="display: none; color: #999; text-align: center; margin-top: 20px;">검색 로그가 없습니다.</div>

		<div id="log-pagination" style="margin-top: 10px;"></div>
	</div>
<script src="/js/adminHeader.js"></script>
<script>
	/* 오늘 날짜 기본값 */
	window.addEventListener('DOMContentLoaded', () => {
		const today = new Date().toISOString().substring(0, 10);
		document.getElementById('fromDate').value = today;
		document.getElementById('toDate').value = today;
	});

	/* 공통 fetch 함수 */
	function fetchAndRender(url, tableSelector, rowTemplateFn, noDataSelector) {
	fetch(url)
    	.then(r => r.json())
    	.then(data => {
        	const table = document.querySelector(tableSelector);
  		    const thead = table.querySelector('thead');
  		    const tbody = table.querySelector('tbody');
     		const noDataDiv = document.querySelector(noDataSelector);

      		if (!data || data.length === 0) {
		    	table.style.display = 'none';
		        noDataDiv.style.display = 'block';
		        return;
		    }

	        table.style.display = '';
		    thead.style.display = '';
		    noDataDiv.style.display = 'none';
		      
		    tbody.innerHTML = '';
		    data.forEach(item => tbody.appendChild(rowTemplateFn(item)));
		});
	}

	/* 추천어 */
	fetchAndRender('/admin/Search/recommended', '#recommended-table', item => {
		const tr = document.createElement('tr');
	    tr.innerHTML = `
			<td>\${item.RECOMMENDED_NO}</td>
		    <td>\${item.KEYWORD}</td>
		    <td>\${item.REG_DATE ? item.REG_DATE.substring(0,10) : ''}</td>
		    <td>
		    	<button onclick="editRecommended(\${item.RECOMMENDED_NO}, '\${item.KEYWORD}')">수정</button>
		        <button onclick="deleteRecommended(\${item.RECOMMENDED_NO})">삭제</button>
		    </td>
		`;
	    return tr;
	}, '#recommended-no-data');

	/* 금칙어 */
	fetchAndRender('/admin/Search/prohibited', '#prohibited-table', item => {
		const tr = document.createElement('tr');
	    tr.innerHTML = `
			<td>\${item.PROHIBITED_NO}</td>
		    <td>\${item.KEYWORD}</td>
		    <td>\${item.REG_DATE ? item.REG_DATE.substring(0,10) : ''}</td>
		    <td>
		    	<button onclick="editProhibited(\${item.PROHIBITED_NO}, '\${item.KEYWORD}')">수정</button>
		    	<button onclick="deleteProhibited(\${item.PROHIBITED_NO})">삭제</button>
		    </td>
		`;
		return tr;
	}, '#prohibited-no-data');

	/* 인기 검색어 */
	fetchAndRender('/admin/Search/top', '#top-table', item => {
		const tr = document.createElement('tr');
		tr.innerHTML = `
	    	<td>\${item.KEYWORD}</td>
	    	<td>\${item.CNT}</td>
	    `;
	    return tr;
	}, '#top-no-data');

	/* 로그 조회 */
	function loadLogs(page = 1) {
		
		const from = document.getElementById('fromDate').value;
		const to = document.getElementById('toDate').value;
		
		let url = '/admin/Search/logs';
		const params = [];
		if(from) params.push('from=' + from);
		if(to) params.push('to=' + to);
		params.push('page=' + page);
		params.push('size=20'); // 페이지당 20건
		if(params.length) url += '?' + params.join('&');
		
		fetch(url)
			.then(res => res.json())
		    .then(result => {
		    	console.log("🚀 서버 응답 확인", result);
		    	
		    	const table = document.getElementById('logs-table');
		    	const noDataDiv = document.getElementById('logs-no-data');
		    	const tbody = table.querySelector('tbody');
		    	const pagination = document.getElementById('log-pagination');

		    	tbody.innerHTML = '';
		    	pagination.innerHTML = '';

		    	if (!result.data || result.data.length === 0) {
		    		table.style.display = 'none';
		    		noDataDiv.style.display = 'block';
		    		return;
		    	}

		    	// 데이터 있을 경우
		    	table.style.display = 'table';
		    	noDataDiv.style.display = 'none';
		        
		        
		        result.data.forEach(item => {
			        const tr = document.createElement('tr');
			        tr.innerHTML = `
				        <td>\${item.SEARCH_LOG_NO}</td>
				        <td>\${item.MEMBER_NO || '-'}</td>
				        <td>\${item.KEYWORD}</td>
				        <td>\${item.IS_RECOMMENDED}</td>
				        <td>\${item.IS_PROHIBITED}</td>
				        <td>\${item.SEARCH_DATE ? item.SEARCH_DATE.substring(0,10) : ''}</td>
		        	`;
		        	tbody.appendChild(tr);
		      	});
		
		        // 페이지네이션 UI
				for(let i=1; i<=result.totalPages; i++) {
		  			const btn = document.createElement('button');
		  			btn.textContent = i;
				    btn.onclick = () => loadLogs(i);
				    if(i === result.page) {
				    	btn.style.fontWeight = 'bold';
				  	}
		 			pagination.appendChild(btn);
				}
		    });
	}

	/* 추천어/금칙어 CRUD */
	function addRecommended() {
		const k = prompt("추천어 입력:"); if(!k) return;
		fetch('/admin/Search/recommended', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({keyword:k})}).then(()=>location.reload());
	}
	function editRecommended(id, oldK) {
		const k = prompt("수정할 추천어:", oldK); if(!k) return;
		fetch('/admin/Search/recommended/'+id, {method:'PUT', headers:{'Content-Type':'application/json'}, body:JSON.stringify({keyword:k})}).then(()=>location.reload());
	}
	function deleteRecommended(id) {
		if(confirm("삭제하시겠습니까?"))
	    fetch('/admin/Search/recommended/'+id, {method:'DELETE'}).then(()=>location.reload());
	}
	function addProhibited() {
		const k = prompt("금칙어 입력:"); if(!k) return;
		fetch('/admin/Search/prohibited', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({keyword:k})}).then(()=>location.reload());
	}
	function editProhibited(id, oldK) {
		const k = prompt("수정할 금칙어:", oldK); if(!k) return;
		fetch('/admin/Search/prohibited/'+id, {method:'PUT', headers:{'Content-Type':'application/json'}, body:JSON.stringify({keyword:k})}).then(()=>location.reload());
	}
	function deleteProhibited(id) {
		if(confirm("삭제하시겠습니까?"))
	    fetch('/admin/Search/prohibited/'+id, {method:'DELETE'}).then(()=>location.reload());
	}
</script>
</body>
</html>
