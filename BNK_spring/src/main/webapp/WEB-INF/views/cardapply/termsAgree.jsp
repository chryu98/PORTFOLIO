<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드 발급 - 약관 동의</title>
<style>
#pdfViewer {
	width: 100%;
	height: 500px;
	border: 1px solid #ccc;
	display: none;
	margin-top: 20px;
}
.terms-list div { margin-bottom: 10px; }
.terms-list input[type="checkbox"] { cursor: pointer; }
.btn {
	padding: 8px 16px;
	margin-top: 10px;
	background-color: #c10c0c;
	color: white;
	border: none;
	cursor: pointer;
}
</style>
</head>
<body>

<h2>카드를 만드려면<br>약관 동의가 필요해요</h2>

<div class="terms-list" id="termsContainer">
	<div>
		<input type="checkbox" id="allAgree" />
		<label for="allAgree"><strong>모두 동의</strong></label>
	</div>
</div>

<button class="btn" id="nextBtn">다음</button>

<!-- PDF 뷰어 영역 -->
<div id="pdfViewer">
	<iframe id="pdfFrame" width="100%" height="100%"></iframe>
	<div style="margin-top: 10px;">
		<button class="btn" id="agreeBtn">동의</button>
		<button class="btn" id="downloadBtn">다운로드</button>
		<button class="btn" id="closeBtn" style="background-color: #888;">닫기</button>
	</div>
</div>

<script>
let currentPdfCheckbox = null;

// 약관 목록 불러오기
const cardNo = ${cardNo};
console.log('cardNo =', cardNo);

// JWT 토큰을 localStorage에서 가져오기
const jwtToken = localStorage.getItem('jwtToken');

if (jwtToken) {
    fetch('/card/apply/api/card-terms?cardNo=' + cardNo, {
        method: 'GET',
        headers: {
            'Authorization': 'Bearer ' + jwtToken, // 'Bearer ' 접두사 필수
            'Content-Type': 'application/json'
        },
        credentials: 'same-origin'
    })
    .then(res => {
        if (res.status === 401) {
            alert('인증에 실패했습니다. 다시 로그인해주세요.');
            window.location.href = '/user/login';
            throw new Error('인증 실패');
        }
        if (!res.ok) {
            throw new Error('HTTP error ' + res.status);
        }
        return res.json();
    })
    .then(terms => {
        const container = document.getElementById('termsContainer');
        terms.forEach(term => {
            const isRequired = term.isRequired === 'Y' ? '필수' : '선택';
            const div = document.createElement('div');
            div.innerHTML = `
                <input type="checkbox" class="termCheckbox" id="term_${term.pdfNo}" 
                    data-pdfno="${term.pdfNo}" disabled />
                <label class="termLabel" data-pdfno="${term.pdfNo}">
                    ${term.pdfName} (${isRequired})
                </label>
            `;
            container.appendChild(div);
        });
    })
    .catch(err => {
        console.error('fetch 요청 실패:', err);
    });
} else {
    alert('로그인이 필요한 서비스입니다.');
    window.location.href = '/user/login';
}

// 이벤트 위임 - 약관 클릭 시 PDF 뷰어
document.getElementById('termsContainer').addEventListener('click', function(e) {
	if (e.target.classList.contains('termLabel')) {
		const pdfNo = e.target.dataset.pdfno;
		currentPdfCheckbox = document.getElementById('term_' + pdfNo);
		
		const jwtToken = localStorage.getItem('jwtToken');
		if (jwtToken) {
			document.getElementById('pdfFrame').src = '/pdf/view?pdfNo=' + pdfNo + '&token=' + jwtToken;
			document.getElementById('pdfViewer').style.display = 'block';
		} else {
			alert('로그인이 필요합니다.');
			window.location.href = '/user/login';
		}
	}
});

// 전체 동의
document.getElementById('allAgree').addEventListener('change', function() {
	const allChecked = this.checked;
	document.querySelectorAll('.termCheckbox').forEach(cb => {
		if (!cb.disabled) cb.checked = allChecked;
	});
});

// 동의 버튼
document.getElementById('agreeBtn').addEventListener('click', function() {
	if (currentPdfCheckbox) {
		currentPdfCheckbox.checked = true;
		currentPdfCheckbox.disabled = false;
	}
	document.getElementById('pdfViewer').style.display = 'none';
	currentPdfCheckbox = null;
});

// PDF 닫기
document.getElementById('closeBtn').addEventListener('click', function() {
	document.getElementById('pdfViewer').style.display = 'none';
	currentPdfCheckbox = null;
});

// 다운로드 버튼
document.getElementById('downloadBtn').addEventListener('click', function() {
	if (currentPdfCheckbox) {
		const pdfNo = currentPdfCheckbox.dataset.pdfno;
		const jwtToken = localStorage.getItem('jwtToken');
		window.open('/pdf/download?pdfNo=' + pdfNo + '&token=' + jwtToken, '_blank');
	}
});

// 다음 버튼
document.getElementById('nextBtn').addEventListener('click', function() {
	const requiredTerms = Array.from(document.querySelectorAll('.termCheckbox'))
		.filter(cb => cb.parentElement.textContent.includes('(필수)'));

	const allChecked = requiredTerms.every(cb => cb.checked);
	if (!allChecked) {
		alert('필수 약관에 모두 동의해야 합니다.');
		return;
	}
    
    // 다음 페이지로 이동할 때도 cardNo를 함께 전달
	location.href = '/card/apply/info?cardNo=' + cardNo;
});
</script>
</body>
</html>
