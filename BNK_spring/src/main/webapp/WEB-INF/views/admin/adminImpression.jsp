<%@ page contentType="text/html;charset=UTF-8" language="java"%>
<html>
<head>
<title>상품 인가 목록</title>
<style>

body {
	background-color: #f9f9f9;
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

/* 테이블 헤더 */
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

/* 마지막 헤더 셀은 오른쪽 테두리 제거 */
.card-table thead th:last-child {
  border-right: none;
}

/* 테이블 바디 */
.card-table tbody td {
  padding: 14px;
  text-align: center;
  background-color: #ffffff;
  border-top: 1px solid #dee2e6;
  border-right: 1px solid #dee2e6;
  word-wrap: break-word;
}

/* 마지막 바디 셀 오른쪽 선 제거 */
.card-table tbody td:last-child {
  border-right: none;
}

/* 마지막 행 둥근 테두리 처리 */
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

/* 호버 효과 (선택)
.card-table tbody tr:hover td {
  background-color: #f1f3f5;
} */

#noDataMessage {
	text-align: center;
	color: #999;
	font-size: 1.1em;
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
	padding: 0 200px; /* ← 사이드바 여백과 같은 좌우 여백 */
	box-sizing: border-box;
}
/*
#permissionTable,
#permissionTable thead {
	display: none;
}*/

</style>

<link rel="stylesheet" href="/css/adminstyle.css">
</head>
<body>
	<jsp:include page="../fragments/header.jsp"></jsp:include>

	<div class="admin-content-wrapper">
		<div class="inner">
			<h2>상품 인가 목록</h2>

			<table id="permissionTable" class="card-table">
				<thead>
					<tr>
						<th>번호</th>
						<th>카드 번호</th>
						<th>상태</th>
						<th>반려 이유 </th>
						<th>요청한 담당관리자</th>
						<th>결정한 상위 관리자</th>
						<th>요청 날짜</th>
						<th>인가 날짜</th>
						<th>인가 내용</th>
					</tr>
				</thead>
				<tbody>
					<!-- 데이터는 fetch로 채워짐 -->
				</tbody>
			</table>

			<div id="noDataMessage" style="display: none; margin-top: 10px;">상품
				인가 목록이 없습니다.</div>

			<div id="pagination" style="margin-top: 10px; display: none;">
				<button id="prevPage">이전</button>
				<span id="pageInfo"></span>
				<button id="nextPage">다음</button>
			</div>
		</div>
	</div>
	<script src="/js/adminHeader.js"></script>
	<script>
	document.addEventListener('DOMContentLoaded', function() {
    	const tbody = document.querySelector('#permissionTable tbody');
        const thead = document.querySelector('#permissionTable thead');
        const noDataMessage = document.getElementById('noDataMessage');
        const pagination = document.getElementById('pagination');
        const searchInput = document.getElementById('searchInput');
            
        fetch('/admin/permissions')
        	.then(response => response.json())
        	.then(data => {
            	console.log('전체 응답 데이터', data);
                allData = data;
                renderTable(allData);
            })
            .catch(error => {
            	console.error('데이터 로딩 실패:', error);
            });
            
        // 날짜 포맷팅 함수
        function formatDate(dateString) {
        	if (!dateString) return '';
            const date = new Date(dateString);
            const year = date.getFullYear();
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const day = String(date.getDate()).padStart(2, '0');
            const hour = String(date.getHours()).padStart(2, '0');
            const minute = String(date.getMinutes()).padStart(2, '0');
            const second = String(date.getSeconds()).padStart(2, '0');
            return `\${year}-\${month}-\${day} \${hour}:\${minute}:\${second}`;
        }

        function renderTable(data){
        	tbody.innerHTML = '';
            	 
            // 데이터가 없으면 메시지 보여주고 테이블 숨김
            if (data.length === 0) {
            	thead.style.display = 'none';
                document.getElementById('permissionTable').style.display = 'none';
                noDataMessage.style.display = 'block';
                pagination.style.display = 'none';
                return;
            }
             	
            // 데이터가 있으면 테이블과 thead 보이게, 메시지 숨기기
            thead.style.display = '';
            document.getElementById('permissionTable').style.display = '';
            noDataMessage.style.display = 'none';

            // 테이블 행 모두 생성
            data.forEach(p => {
            	const tr = document.createElement('tr');
            	const regDate = formatDate(p.regDate);
                const perDate = formatDate(p.perDate);
            	
                tr.innerHTML = `
                	<td>\${p.perNo}</td>
                    <td>\${p.cardNo}</td>
                    <td>\${p.status}</td>
                    <td>\${p.reason}</td>
                    <td>\${p.admin}</td>
                    <td>\${p.sadmin}</td>
                    <td>\${regDate}</td>
                    <td>\${perDate}</td>
                    <td>\${p.perContent}</td>
                `;
                tbody.appendChild(tr);
        });
                
        setupPagination();
	}
            
    // 페이징 기능 구현
    const itemsPerPage = 10;
    let currentPage = 1;
            
    function setupPagination(){
            	
		const rows = tbody.querySelectorAll('tr');
	    const pageInfo = document.getElementById('pageInfo');
	    const prevBtn = document.getElementById('prevPage');
	    const nextBtn = document.getElementById('nextPage');
	
	    const totalPages = Math.ceil(rows.length / itemsPerPage);

	    if (rows.length <= itemsPerPage) {
	        pagination.style.display = 'none';
	        return;
	    }
	    
	 	pagination.style.display = 'block';
	 	
	 	// 페이지 번호 버튼 영역 초기화
	    pageInfo.innerHTML = '';
	 	
	 	// 현재 페이지 전역 변수
	    currentPage = 1;
	    
	    function renderPage(page) {
	    	const start = (page - 1) * itemsPerPage;
	        const end = start + itemsPerPage;
	                
	        rows.forEach((row, idx) => {
	        	row.style.display = (idx >= start && idx < end) ? '' : 'none';
	        });
	           
	        currentPage = page;

	        // 페이지 번호 버튼들 다시 생성
	        pageInfo.innerHTML = '';
	        
	        for (let i = 1; i <= totalPages; i++) {
	            const btn = document.createElement('button');
	            btn.textContent = i;
	            btn.style.margin = '0 3px';
	            if (i === currentPage) {
	                btn.disabled = true; // 현재 페이지는 비활성화
	                btn.style.fontWeight = 'bold';
	            }
	            btn.onclick = () => {
	                renderPage(i);
	            };
	            pageInfo.appendChild(btn);
	        }
	        
	     	// 이전/다음 버튼은 숨기거나 비활성화 처리 (필요시)
	        prevBtn.style.display = 'none';
	        nextBtn.style.display = 'none';
	    }
	    
	    renderPage(currentPage);
	}
});

</script>
</body>
</html>