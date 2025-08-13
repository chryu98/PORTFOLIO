<%@ page contentType="text/html; charset=UTF-8" isELIgnored="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>상품 상세</title>
  <link rel="stylesheet" href="/css/style.css">
  <style>
    html, body {
      background: #fff;
      margin: 0;
      padding: 0;
      font-family: 'Noto Sans KR', sans-serif;
      color: #333;
      box-sizing: border-box;
    }
    *, *::before, *::after {
      box-sizing: inherit;
    }
    .wrap {
      width: 100%;
      max-width: 1000px;
      margin: 0px auto;
    }
    .top {
      display: flex;
      flex-wrap: wrap;
      gap: 40px;
      padding: 70px 20px 20px;
      align-items: flex-start;
    }
    .card-img {
      margin-left: 50px;
      rotate: 90deg;
      margin-bottom: 50px;
      margin-top: 50px;
      width: 260px;
      min-width: 350px;
      max-width: 270px;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
      transition: transform 0.2s;
    }
    .card-img:hover {
  transform: scale(1.04) rotate(2deg);
}
    .info {
      flex: 1 1 0;
      min-width: 0;
    }
    .info h2 {
      font-size: 40px;
      font-weight: 500;
      color: #111;
      margin: 0;
    }
    .info p {
      font-size: 18px;
      color: #555;
      margin: 14px 0;
    }
    .fee-box {
      margin-top: 50px;
      display: flex;
      gap: 20px;
    }
    .fee-line {
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .fee-line img {
      width: 40px;
    }
    .fee-line span {
      font-size: 16px;
      font-weight: 500;
    }
    .summary-benefit {
      display: flex;
      gap: 12px;
      margin-top: 20px;
      flex-wrap: wrap;
    }
    
    .benefit-card {
	  display: inline-block;
	  padding: 6px 12px;
	  border: 1px solid #d44;
	  border-radius: 20px;
	  color: #d44;
	  font-weight: 500;
	  margin-bottom: 10px;
	  font-size: 16px;
	}
    
    .accordion {
        background: #f9f9f9;
	    border: 1px solid #ddd;
	    border-radius: 12px;
	    padding: 18px 22px;
	    margin-bottom: 14px;
	    cursor: pointer;
    }
    .accordion:hover {
      background: #e7e7e7;
    }
    .accordion h4 {
      margin: 0;
      font-size: 14px;
      font-weight: 600;
      color: #444;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .accordion p {
	  display: none;
	  margin-top: 12px;
	  font-size: 15px;
	  color: #444;
	  line-height: 2.5;
	}
	.accordion.active p {
	  display: block;
	}
    .section {
      margin-top: 70px;
      margin-left: 20px;
      background-color: white;
      width: 100%;
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      margin-bottom: 30px;

    }
    .section h3 {
      margin-bottom: 16px;
      font-size: 18px;
      font-weight: 600;
      color: #444;
      border-left: 4px solid #444;
      padding-left: 10px;
    }
    .section pre {
      white-space: pre-wrap;
      font-family: 'Noto Sans KR', sans-serif;
      font-size: 15px;
      color: #555;
      line-height: 2.5;
    }
    
    #sService {
  		line-height: 2.0; /* 원하는 값으로 */
	}
	
	.highlight {
	  color: #333;
	  font-weight: bold;
	}
	
	.benefit-container {
	  display: flex;
	  flex-wrap: wrap;
	  gap: 20px;
	  margin-top: 10px;
	}
	
	.benefit-block {
	  flex: 1 1 calc(50% - 10px);
	  background: #f9f9f9;
	  border: 1px solid #ddd;
	  border-radius: 12px;
	  padding: 20px;
	  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
	}
	
	.benefit-block .benefit-card {
	  color: #d44;
	  border: none;
	  background: transparent;
	  border-radius: 0;
	  font-weight: 600;
	  padding: 0;
	  font-size: 16px;
	  margin-bottom: 8px;
	}
	
	
	.benefit-block li {
	  font-size: 15px;
	  color: #444;
	  margin-bottom: 6px;
	  line-height: 1.6;
	}

  </style>
</head>
<body>

<jsp:include page="/WEB-INF/views/fragments/mainheader2.jsp" />

<div class="wrap">
  <div class="top">
    <div>
      <img id="cardImg" src="" alt="카드이미지" class="card-img" data-track="card-image">
      
    </div>
    <div class="info">
      <h2 id="cardName"></h2>
      <p id="cardSlogan"></p>
      <div class="summary-benefit" id="summaryBenefit"></div>
      	<div class="fee-box">

        <div class="fee-line"><img src="/image/overseas_pay_domestic.png" alt="국내"><span id="feeDomestic">-</span></div>
        <div class="fee-line"><img src="/image/overseas_pay_visa.png" alt="VISA"><span id="feeVisa">-</span></div>
        <div class="fee-line"><img src="/image/overseas_pay_master.png" alt="MASTER"><span id="feeMaster">-</span></div>
      	</div>
      	
      	<div style="margin-top: 30px;">
  <%
    String cardNo = request.getParameter("no"); // URL에서 no 파라미터 받아옴
%>
<a href="/card/apply/termsAgree?cardNo=<%=cardNo%>"
 id="applyLink"
   style="display:inline-block; padding:12px 24px; background:#d44; color:white; font-weight:bold; border-radius:8px; text-decoration:none;">
   카드 발급하기
</a>
</div>
    </div>
  </div>

  <div class="accordion-container" id="accordionContainer"></div>

  <div class="section">
    <h3>혜택 부문</h3>
    <pre id="sService"></pre>
  </div>

  <div class="section">
	  <h3>유의사항</h3>
	  <div class="accordion" data-track="notice-all" onclick="toggleNoticeAccordion(this)">
	    <h4>전체 보기 <span>▼</span></h4>
	    <p id="noticeFull"></p>
	  </div>
	</div>
</div>
<jsp:include page="/WEB-INF/views/fragments/footer.jsp" />


<script src="/js/header2.js"></script>
<script>
  const CATEGORY_KEYWORDS = {
    '커피': ['커피', '스타벅스', '이디야', '카페베네'],
    '편의점': ['편의점', 'GS25', 'CU', '세븐일레븐'],
    '베이커리': ['베이커리', '파리바게뜨', '뚜레쥬르', '던킨'],
    '영화': ['영화관', '영화', '롯데시네마', 'CGV'],
    '쇼핑': ['쇼핑몰', '쿠팡', '마켓컬리', 'G마켓', '다이소', '백화점', '홈쇼핑'],
    '외식': ['음식점', '레스토랑', '맥도날드', '롯데리아'],
    '교통': ['버스', '지하철', '택시', '대중교통', '후불교통'],
    '통신': ['통신요금', '휴대폰', 'SKT', 'KT', 'LGU+'],
    '교육': ['학원', '학습지'],
    '레저&스포츠': ['체육', '골프', '스포츠', '레저'],
    '구독': ['넷플릭스', '멜론', '유튜브프리미엄', '정기결제', '디지털 구독'],
    '병원': ['병원', '약국', '동물병원'],
    '공공요금': ['전기요금', '도시가스', '아파트관리비'],
    '주유': ['주유', '주유소', 'SK주유소', 'LPG'],
    '하이패스': ['하이패스'],
    '배달앱' : ['쿠팡', '배달앱'],
    '환경': ['전기차', '수소차', '친환경'],
    '공유모빌리티': ['공유모빌리티', '카카오T바이크', '따릉이', '쏘카', '투루카'],
    '세무지원': ['세무', '전자세금계산서', '부가세'],
    '포인트&캐시백': ['포인트', '캐시백', '가맹점', '청구할인'],
    '놀이공원': ['놀이공원', '자유이용권'],
    '라운지': ['공항라운지'],
    '발렛': ['발렛파킹']
  };

  function extractCategories(text, max = 5) {
    const found = new Set();
    const lowerText = text.toLowerCase();
    for (const [category, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
      if (found.size >= max) break;
      for (const keyword of keywords) {
        if (lowerText.includes(keyword.toLowerCase())) {
          found.add(category);
          break;
        }
      }
    }
    return Array.from(found);
  }

  const urlParams = new URLSearchParams(location.search);
  const cardNo = urlParams.get("no");

  if (!cardNo) {
    alert("카드 번호가 없습니다.");
    throw new Error("카드 번호 누락");
  }

  fetch(`/api/cards/${cardNo}`)
    .then(r => {
      if (!r.ok) throw new Error('존재하지 않는 카드');
      return r.json();
    })
    .then(c => {
      renderCard(c);
      fetch(`/api/cards/${cardNo}/view`, { method: 'PUT' });
    })
    .catch(err => {
      alert('카드 정보를 불러올 수 없습니다.');
      console.error(err);
    });

  function renderCard(c) {
    document.title = `${c.cardName} 상세`;
    document.getElementById('cardImg').src = c.cardUrl;
    document.getElementById('cardImg').alt = c.cardName;
    document.getElementById('cardName').innerText = c.cardName;
    document.getElementById('cardSlogan').innerText = c.cardSlogan ?? '-';
    document.getElementById('sService').innerText = c.sService ?? '';

    // 유의사항 줄이기
    const notice = c.cardNotice ?? '';
    document.getElementById('noticeFull').innerHTML = notice.replace(/\n/g, "<br>");

    const brand = (c.cardBrand || '').toUpperCase();
    const fee = (c.annualFee ?? 0).toLocaleString() + '원';
    document.getElementById('feeDomestic').innerText = brand.includes('BC') || brand.includes('LOCAL') ? fee : '없음';
    document.getElementById('feeVisa').innerText     = brand.includes('VISA') ? fee : '없음';
    document.getElementById('feeMaster').innerText   = brand.includes('MASTER') ? fee : '없음';

    renderCategories(c.service + '\n' + (c.sService ?? ''));
    renderBenefits(c.service);
  }

  function renderCategories(text) {
    const categories = extractCategories(text, 5);
    const html = categories.map(c => `<div class="benefit-card">#${c}</div>`).join('');
    document.getElementById("summaryBenefit").innerHTML = html;
  }

  
  function renderBenefits(rawService) {
	  const accordionDiv = document.getElementById('accordionContainer');

	  // ◆로 구분된 블록을 분리
	  const parts = rawService
	    .split('◆')
	    .map(s => s.trim())
	    .filter(s => s !== '');

	  const categoryMap = new Map(); // { '교통': [문장1, 문장2], ... }

	  for (let part of parts) {
	    // - 또는 숫자. 로 항목 분리
	    const subLines = part
	      .split(/\n|(?<!\d)-|(?=\d+\.\s)/g)  // ← 핵심: 숫자 리스트도 분리
	      .map(s => s.trim())
	      .filter(s => s !== '');

	    for (let p of subLines) {
	      let matchedCategory = null;

	      for (const [category, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
	        for (const keyword of keywords) {
	          const reg = new RegExp(`(${keyword})`, 'gi');
	          if (reg.test(p)) {
	            matchedCategory = category;
	            p = p.replace(reg, `<span class="highlight">$1</span>`);
	            break;
	          }
	        }
	        if (matchedCategory) break;
	      }

	      if (!matchedCategory) {
	        matchedCategory = '기타';
	      }

	      if (!categoryMap.has(matchedCategory)) {
	        categoryMap.set(matchedCategory, []);
	      }

	      categoryMap.get(matchedCategory).push(p);
	    }
	  }

	  // HTML 생성
	  let groupedHtml = '<div class="benefit-container">';
	  for (const [category, lines] of categoryMap.entries()) {
	    // 숫자 리스트 여부 감지
	    const isNumberedList = lines.every(line => /^\d+\.\s/.test(line));

	    const listHtml = isNumberedList
	      ? `<ol>${lines.map(line => `<li>${line.replace(/^\d+\.\s*/, '')}</li>`).join('')}</ol>`
	      : `<ul>${lines.map(line => `<li>${line}</li>`).join('')}</ul>`;

	    groupedHtml += `
	      <div class="benefit-block">
	        <div class="benefit-card">#${category}</div>
	        ${listHtml}
	      </div>
	    `;
	  }
	  groupedHtml += '</div>';

	  accordionDiv.innerHTML = `
	    <div class="section">
	      <h3>혜택 요약</h3>
	      ${groupedHtml}
	    </div>
	  `;
	}




  function toggleAccordion(el) {
    el.classList.toggle("active");
  }

  function toggleNoticeAccordion(el) {
    el.classList.toggle("active");
  }
</script>


<%
    com.busanbank.card.user.dto.UserDto loginUser =
        (com.busanbank.card.user.dto.UserDto) session.getAttribute("loginUser");
    Long memberNo = (loginUser != null) ? Long.valueOf(loginUser.getMemberNo()) : null;
%>
<script>
  const memberNo = <%= memberNo != null ? "'" + memberNo + "'" : "null" %>;
  console.log("🧪 memberNo (from session):", memberNo);

  // VIEW
  if (memberNo !== 'null' && memberNo !== '0') {
    fetch("/api/log/card-behavior", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        memberNo: Number(memberNo),
        cardNo: Number(cardNo), // 위쪽에서 URLSearchParams로 만든 JS 변수 그대로 사용
        behaviorType: "VIEW",
        deviceType: /Mobi|Android/i.test(navigator.userAgent) ? "MOBILE" : "PC",
        userAgent: navigator.userAgent
      })
    }).then(res => console.log("✅ 로그 저장 응답:", res.status))
      .catch(err => console.error("❌ 로그 저장 에러:", err));
  } else {
    console.warn("⛔ memberNo나 cardNo가 비어 있어서 로그 저장 안 됨");
  }

  function deviceTypeOf(ua) {
    return /Mobi|Android/i.test(ua) ? "MOBILE" : "PC";
  }

  // 공통 로깅: VIEW / CLICK / APPLY_START / APPLY_COMPLETE
  function logBehavior(type) {
    if (memberNo === 'null' || memberNo === '0') return; // 비로그인 시 스킵
    const payload = {
      memberNo: Number(memberNo),
      cardNo: Number(cardNo),
      behaviorType: type,
      deviceType: deviceTypeOf(navigator.userAgent),
      userAgent: navigator.userAgent
    };
    const url = "/api/log/card-behavior";
    const body = JSON.stringify(payload);

    if (navigator.sendBeacon) {
      const blob = new Blob([body], { type: "application/json;charset=UTF-8" });
      if (navigator.sendBeacon(url, blob)) return;
    }
    fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body })
      .catch(() => {});
  }

  // CLICK 수집 (필요 시 applyLink 제외)
  document.addEventListener("click", (e) => {
    const el = e.target.closest("[data-track]");
    if (!el) return;
    if (el.id === "applyLink") return; // ← 이 줄은 선택(빼고 싶을 때만)
    logBehavior("CLICK");
  });

  // APPLY_START: 인터셉트 후 이동
  document.addEventListener("DOMContentLoaded", () => {
    const applyLink = document.getElementById("applyLink");
    if (!applyLink) return;
    applyLink.setAttribute("data-track", "apply-button");
    applyLink.addEventListener("click", (e) => {
      e.preventDefault();
      const href = applyLink.getAttribute("href");
      if (applyLink._applied) return;
      applyLink._applied = true;
      logBehavior("APPLY_START");
      setTimeout(() => { window.location.href = href; }, 50);
    });
  });
</script>



<script>
   let remainingSeconds = <%= request.getAttribute("remainingSeconds") %>;
</script>
<script src="/js/sessionTime.js"></script>

</body>
</html>
