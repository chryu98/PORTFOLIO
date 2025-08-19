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
    display: none;
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 80%;
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
		<input type="checkbox" id="allAgree"> <label for="allAgree">모두 동의</label>
	</div>
	<div id="termsContainer"></div>

	<!-- PDF 모달 -->
	<div id="modalBackdrop"></div>
	<div id="pdfModal">
		<div id="pdfTabs" style="margin-bottom:10px;"></div>
		<iframe id="pdfFrame"></iframe>
		<button id="agreeBtn">동의</button>
		<button id="downloadBtn">다운로드</button>
		<button id="closeModal">닫기</button>
	</div>
</div>

<button id="nextBtn">다음</button>

<script>
const modal = document.getElementById('pdfModal');
const backdrop = document.getElementById('modalBackdrop');

// URLSearchParams로 cardNo 가져오기
const params = new URLSearchParams(window.location.search);
const cardNo = params.get('cardNo');
console.log('cardNo: ' + cardNo);

document.addEventListener('DOMContentLoaded', () => {
	window.termsData = [];
	
    const jwtToken = localStorage.getItem('jwtToken');
    //const cardNo = '${cardNo}';
    const container = document.getElementById('termsContainer');

    if (!jwtToken) {
        alert('로그인이 필요합니다.');
        window.location.href = '/user/login';
        return;
    }

    // 약관 조회
    fetch('/api/card/apply/card-terms?cardNo=' + cardNo, {
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
        if (!res.ok) throw new Error('HTTP error ' + res.status);
        return res.json();
    })
    .then(terms => {
    	window.termsData = terms;
    	
        container.innerHTML = '';
        terms.forEach(term => {
            const div = document.createElement('div');

            const checkbox = document.createElement('input');
            checkbox.type = 'checkbox';
            checkbox.id = 'term_' + term.pdfNo;
            checkbox.dataset.required = term.isRequired;
            checkbox.readOnly = true;       // 체크박스 직접 클릭 방지
            checkbox.onclick = (e) => e.preventDefault(); // 혹시 모달 안뜨게 확실히

            const label = document.createElement('label');
            label.htmlFor = checkbox.id;
            label.textContent = term.pdfName + ' (' + (term.isRequired === 'Y' ? '필수' : '선택') + ')';

            // 라벨 클릭 시 PDF 모달 열기
            label.addEventListener('click', () => openPdfModal(term));

            div.appendChild(checkbox);
            div.appendChild(label);
            container.appendChild(div);
        });
    })
    .catch(err => console.error('약관 조회 실패:', err));

    // 모두 동의 체크
    document.getElementById("allAgree").addEventListener("change", function () {
    	if (!this.checked) return;

        const pdfTabs = document.getElementById("pdfTabs");
        pdfTabs.innerHTML = "";

        // termsData 그대로 사용
        window.termsData.forEach(term => {
            const btn = document.createElement("button");
            btn.textContent = term.pdfName;
            btn.style.marginRight = "5px";
            btn.onclick = () => openPdfModal(term); // 클릭 시 PDF 표시
            pdfTabs.appendChild(btn);
        });

        // 첫 번째 PDF 자동 표시
        if (window.termsData.length > 0) {
            openPdfModal(window.termsData[0]);
        }

        // 모달 표시
        modal.style.display = 'block';
        backdrop.style.display = 'block';
    });
});

// PDF 모달 열기
function openPdfModal(term) {
    const pdfBase64 = term.pdfDataBase64;
    const byteArray = new Uint8Array(atob(pdfBase64).split("").map(c => c.charCodeAt(0)));
    const blob = new Blob([byteArray], { type: 'application/pdf' });
    const url = URL.createObjectURL(blob);
    document.getElementById('pdfFrame').src = url;

    const pdfFrame = document.getElementById('pdfFrame');
    pdfFrame.src = url;

    modal.style.display = 'block';
    backdrop.style.display = 'block';

    document.getElementById('downloadBtn').onclick = () => {
        const a = document.createElement('a');
        a.href = url;
        a.download = term.pdfName + '.pdf';
        a.click();
    };

    document.getElementById('agreeBtn').onclick = () => {
    	const checkbox = document.getElementById('term_' + term.pdfNo);
        checkbox.checked = true;
        
        closeModal();
    };
}

// 모달 닫기
function closeModal() {
    modal.style.display = 'none';
    backdrop.style.display = 'none';
    document.getElementById('pdfFrame').src = '';
}

document.getElementById('closeModal').onclick = closeModal;
backdrop.onclick = closeModal;

//다음 버튼 클릭 시 필수 약관 체크 + DB 저장
document.getElementById('nextBtn').addEventListener('click', () => {
    const checkboxes = document.querySelectorAll('#termsContainer input[type="checkbox"]');
    const agreedPdfNos = [];

    const allRequiredChecked = Array.from(checkboxes)
        .filter(cb => cb.dataset.required === 'Y')
        .every(cb => {
            if (cb.checked) {
                agreedPdfNos.push(Number(cb.id.replace("term_", "")));
                return true;
            }
            return false;
        });

    // 선택 약관도 추가
    Array.from(checkboxes)
        .filter(cb => cb.dataset.required !== 'Y' && cb.checked)
        .forEach(cb => agreedPdfNos.push(Number(cb.id.replace("term_", ""))));

    if (!allRequiredChecked) {
        alert('필수 약관에 모두 동의해 주세요.');
        return;
    }

    const jwtToken = localStorage.getItem('jwtToken');
    const memberNo = localStorage.getItem('memberNo');
    //const cardNo = '${cardNo}';

    //console.log('memberNo:', memberNo);
    //console.log('cardNo:', cardNo);
    //console.log('pdfNos:', agreedPdfNos);
    
    fetch('/api/card/apply/terms-agree', {
        method: 'POST',
        headers: {
            'Authorization': 'Bearer ' + jwtToken,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            memberNo: memberNo,
            cardNo: cardNo,
            pdfNos: agreedPdfNos
        })
    })
    .then(res => res.text())
    .then(msg => {
        alert(msg);
        window.location.href = '/card/apply/customer-info?cardNo=' + cardNo;
    })
    .catch(err => {
        console.error(err);
        alert('약관 저장 중 오류가 발생했습니다.');
    });
});


</script>
</body>
</html>
