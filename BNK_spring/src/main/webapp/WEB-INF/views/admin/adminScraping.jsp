<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>관리자 스크래핑</title>
<link rel="stylesheet" href="/css/adminstyle.css">
<style>
body {
    font-family: 'Noto Sans KR', sans-serif;
    background-color: #f9f9f9;
    margin: 0;
    padding: 0;
}

.inner {
    max-width: 1000px;
    margin: 0 auto;
    padding: 30px;
    background: white;
    border-radius: 12px;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

h1 {
    font-size: 1.4rem;
	margin: 30px 0 20px 0;
	color: #2c3e50;
	border-left: 4px solid #3498db;
	padding-left: 8px;
}

button {
    background-color: #007bff;
    color: white;
    border: none;
    padding: 10px 20px;
    margin-right: 10px;
    font-size: 16px;
    border-radius: 8px;
    cursor: pointer;
    transition: background-color 0.2s ease;
    margin-bottom:20px;
}

#crawlBtn{
	background-color: #a2a2a2;
}

#deleteBtn{
    background-color: #eb2626;
}

button:hover {
    background-color: #0056b3;
}

#card-list {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 24px;
    margin-top: 20px;
    padding: 0;
    list-style: none;
}

.card {
    background-color: #fafafa;
    border: 1px solid #ddd;
    border-radius: 12px;
    padding: 16px;
    text-align: center;
    box-shadow: 0 2px 6px rgba(0,0,0,0.05);
    transition: transform 0.2s ease;
}

.card:hover {
    transform: translateY(-5px);
}

.card img {
    width: 100%;
    height: auto;
    border-radius: 8px;
    margin-bottom: 10px;
}

.card h3 {
    font-size: 17px;
    color: #333;
    margin-bottom: 8px;
    font-weight: 600;
}

.card p {
    font-size: 14px;
    color: #555;
    margin: 5px 0;
}

</style>
</head>
<body>
<jsp:include page="../fragments/header.jsp"></jsp:include>
	<div class="inner">
		<h1>스크래핑 관리</h1>
		<button id="crawlBtn">신한카드 크롤링 실행</button>
		<button id="deleteBtn">신한카드 상품 전체삭제</button>
		<h1>타행 카드 상품목록</h1>
		<ul id="card-list"></ul>
	</div>
	
	
<script src="/js/adminHeader.js"></script>
<script>
//버튼눌러서 크롤링 시작
document.getElementById("crawlBtn").addEventListener("click", function() {
    fetch("/admin/card/scrap", {
        method: "POST"
    })
    .then(res => res.text())
    .then(msg => {
        alert(msg);
    })
    .catch(err => {
        alert("오류 발생: " + err);
    });
});
// 버튼눌러서 전체삭제
document.getElementById("deleteBtn").addEventListener("click", function() {
    if (!confirm("정말로 전체 삭제하시겠습니까?")) return;

    fetch("/admin/card/deleteAll", {
        method: "DELETE"
    })
    .then(res => res.text())
    .then(msg => {
        alert(msg);
        location.reload(); // 새로고침하여 리스트 반영
    })
    .catch(err => {
        alert("삭제 중 오류 발생: " + err);
    });
});


//초기화면 크롤링 카드리스트 출력
	fetch('/admin/card/getScrapList') // ← 실제 REST API 경로
        .then(res => res.json())
        .then(cards => {
            const list = document.getElementById('card-list');
            cards.forEach(card => {
                console.log(card);
                const li = document.createElement('li');
                li.className = 'card';
                li.innerHTML = `
                	<img src=\${card.scCardUrl}>
                    <h3 class="hi">\${card.scCardName}</h3>
                    <p>연회비: \${card.scAnnualFee}원</p>
                    <p>크롤링 날짜: \${card.scDate}</p>
                `;
                list.appendChild(li);
            });
        })
        .catch(err => {
            document.getElementById('card-list').innerText = '카드 정보를 불러오지 못했습니다.';
            console.error('에러:', err);
        });

</script>
</body>
</html>