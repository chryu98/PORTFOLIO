<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드 발급 - 직업 및 거래 정보 입력</title>
</head>
<body>
<h2>정보를 선택해 주세요.</h2>

    <form id="jobForm">
        <input type="hidden" name="applicationNo" value="${applicationNo}">

        <div>
            <label>직업</label>
            <select name="job" required>
                <option value="">직업</option>
                <option value="사무직">사무직</option>
                <option value="판매직">판매직</option>
                <option value="자영업">자영업</option>
                <option value="기타">기타</option>
            </select>
        </div>

        <div>
            <label>거래 목적</label>
            <select name="purpose" required>
                <option value="">거래 목적</option>
                <option value="생활비">생활비</option>
                <option value="사업자금">사업자금</option>
                <option value="투자">투자</option>
                <option value="기타">기타</option>
            </select>
        </div>

        <div>
            <label>자금 출처</label>
            <select name="fundSource" required>
                <option value="">자금 출처</option>
                <option value="근로소득">근로소득</option>
                <option value="사업소득">사업소득</option>
                <option value="부동산 임대소득">부동산 임대소득</option>
                <option value="금융소득">금융소득</option>
                <option value="기타">기타</option>
            </select>
        </div>

        <button type="submit">다음</button>
    </form>

<script>
//URL에서 applicationNo 가져오기
const params = new URLSearchParams(window.location.search);
const applicationNo = params.get('applicationNo');

document.getElementById('jobForm').addEventListener('submit', async function(e) {
    e.preventDefault();

    const data = {
        applicationNo: applicationNo,
        job: document.querySelector('[name="job"]').value,
        purpose: document.querySelector('[name="purpose"]').value,
        fundSource: document.querySelector('[name="fundSource"]').value
    };

    try {
    	const jwtToken = localStorage.getItem("jwtToken");
    	
        const response = await fetch('/card/apply/api/saveJobInfo', {
            method: 'POST',
            headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer " + jwtToken  // JWT 헤더 추가
            },
            body: JSON.stringify(data)
        });

        const result = await response.json();

        if (result.success) {
            location.href = '/card/apply/cardOption?applicationNo=' + encodeURIComponent(data.applicationNo);
        } else {
            alert(result.message);
        }
    } catch (err) {
        alert('서버 오류가 발생했습니다.');
    }
});
</script>
</body>
</html>