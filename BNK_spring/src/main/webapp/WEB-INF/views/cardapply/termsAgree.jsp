<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="jakarta.tags.core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드 발급 - 약관 동의</title>
<style>
body {
	font-family: Arial, sans-serif;
	padding: 20px;
}

h1 {
	font-size: 20px;
	margin-bottom: 20px;
}

.term {
	margin-bottom: 10px;
}

.term label {
	cursor: pointer;
}

#nextBtn {
	margin-top: 20px;
	padding: 10px 20px;
	background: #c10c0c;
	color: white;
	border: none;
	cursor: pointer;
	border-radius: 5px;
}
#pdfModal {
    display: none;           /* 기본은 숨김 */
    position: fixed;         /* 화면 고정 */
    top: 50%;                /* 세로 중앙 */
    left: 50%;               /* 가로 중앙 */
    transform: translate(-50%, -50%); /* 정확히 중앙 */
    width: 80%;              /* 모달 너비 */
    max-width: 800px;
    background: white;
    border: 1px solid #ccc;
    box-shadow: 0 5px 15px rgba(0,0,0,0.3);
    z-index: 1000;
    padding: 20px;
}

#pdfModal iframe {
    width: 100%;
    height: 400px;
    border: none;
}

#pdfModal button {
    margin-top: 10px;
    margin-right: 10px;
    padding: 8px 16px;
    border: none;
    border-radius: 5px;
    background: #c10c0c;
    color: white;
    cursor: pointer;
}

/* 모달 바깥 클릭 시 닫기용 백그라운드 */
#modalBackdrop {
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0,0,0,0.5);
    z-index: 900;
}

</style>
</head>
<body>
<h1>
	카드를 만들려면<br>약관 동의가 필요해요
</h1>

<div>
	<div class="term">
		<input type="checkbox" id="allAgree"> <label for="allAgree">모두
		동의</label>
	</div>
	<div id="termsContainer"></div>

	<!-- PDF 모달 -->
	<div id="modalBackdrop"></div>
	<div id="pdfModal">
		<iframe id="pdfFrame"></iframe>
		<button id="agreeBtn">동의</button>
		<button id="downloadBtn">다운로드</button>
		<button id="closeModal">닫기</button>
	</div>
</div>

<button id="nextBtn">다음</button>

<script>

document.addEventListener('DOMContentLoaded', () => {
    const jwtToken = localStorage.getItem('jwtToken');
    const cardNo = '${cardNo}';
    console.log('cardNo = ' + cardNo);

    const container = document.getElementById('termsContainer');
    
    if (!jwtToken) {
        alert('로그인이 필요합니다.');
        window.location.href = '/user/login';
    } else {
        fetch('/card/apply/api/card-terms?cardNo=' + cardNo, {
            method: 'GET',
            headers: {
                'Authorization': 'Bearer ' + jwtToken,
                'Content-Type': 'application/json'
            },
            credentials: 'same-origin'
        })
        .then(res => {
            if (res.status === 401) {
                alert('인증에 실패했습니다. 다시 로그인해주세요.');
                window.location.href = '/user/login';
                throw new Error('인증 실패: 401 Unauthorized');
            }
            if (!res.ok) {
                throw new Error('HTTP error ' + res.status);
            }
            return res.json();
        })
        .then(terms => {
        	console.log('terms', terms);
        	container.innerHTML = ''; // 기존 내용 초기화
        	
        	terms.forEach(term => {
                const div = document.createElement('div');

                const checkbox = document.createElement('input');
                checkbox.type = 'checkbox';
                checkbox.id = 'term_' + term.pdfNo;
                checkbox.disabled = true;
                checkbox.className = 'termCheckbox';
                checkbox.dataset.pdfno = term.pdfNo;
                checkbox.dataset.required = term.isRequired;

                const label = document.createElement('label');
                label.htmlFor = checkbox.id;
                label.className = 'termLabel';
                label.textContent = term.pdfName + ' (' + (term.isRequired === 'Y' ? '필수' : '선택') + ')';

             	// 라벨 클릭 시 PDF 모달 열기
                label.addEventListener('click', () => openPdfModal(term.pdfNo));
             
                div.appendChild(checkbox);
                div.appendChild(label);
                container.appendChild(div);
            });
        })
        .catch(err => {
            console.error('약관 조회 실패:', err);
        });
    }
});

const modal = document.getElementById('pdfModal');
const backdrop = document.getElementById('modalBackdrop');

function openPdfModal(pdfNo) {
	const pdfFrame = document.getElementById('pdfFrame');
    // iframe에 PDF 표시
    pdfFrame.src = `/card/apply/api/view-pdf?pdfNo=${pdfNo}`;

 	// 모달과 백드롭 표시
    modal.style.display = 'block';
    backdrop.style.display = 'block';
    
 	// 동의 버튼 클릭
    document.getElementById('agreeBtn').onclick = () => {
        document.getElementById('term_' + pdfNo).checked = true;
        modal.style.display = 'none';
        backdrop.style.display = 'none';
    };
}

//닫기 버튼 클릭
document.getElementById('closeModal').onclick = () => {
    modal.style.display = 'none';
    backdrop.style.display = 'none';
};

// 백드롭 클릭 시 모달 닫기
backdrop.onclick = () => {
    modal.style.display = 'none';
    backdrop.style.display = 'none';
};




    // "모두 동의" 체크박스 동작
    const allAgree = document.getElementById('allAgree');
    allAgree.addEventListener('change', () => {
      const checkboxes = container.querySelectorAll('input[type="checkbox"]');
      checkboxes.forEach(cb => cb.checked = allAgree.checked);
    });


// 다음 버튼 클릭 시 필수 약관 체크 확인
document.getElementById('nextBtn').addEventListener('click', () => {
  const checkboxes = document.querySelectorAll('#termsContainer input[type="checkbox"]');
  const allRequiredChecked = Array.from(checkboxes)
    .filter(cb => cb.dataset.required === 'Y')
    .every(cb => cb.checked);

  if (!allRequiredChecked) {
    alert('필수 약관에 모두 동의해 주세요.');
    return;
  }

  // 다음 단계 이동 (예: 페이지 이동 또는 API 호출)
  alert('약관 동의 완료! 다음 단계로 이동합니다.');
});
</script>
</body>
</html>
