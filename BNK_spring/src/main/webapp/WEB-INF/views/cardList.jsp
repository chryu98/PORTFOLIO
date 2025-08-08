<%@ page contentType="text/html; charset=UTF-8" isELIgnored="true"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>카드상품</title>
<link rel="stylesheet" href="/css/style.css">
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>

<!-- ✅ Slick Slider CSS + JS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/slick-carousel@1.8.1/slick/slick.css"/>
<script src="https://cdn.jsdelivr.net/npm/slick-carousel@1.8.1/slick/slick.min.js"></script>

<style>

.white-text,
.white-text .popular-title,
.white-text .popular-sub {
  color: white !important;
}

/* 슬라이더 예외 글 색깔처리 */
.white-text {
  color: #fff;
}

.chatbot-tooltip {
  background: #fff;
  color: #333;
  padding: 10px 14px;
  border-radius: 20px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.15);
  font-size: 14px;
  position: absolute;
  right: 75px; /* 버튼보다 왼쪽으로 이동 */
  bottom: 10px;
  white-space: nowrap;
  animation: fadeIn 0.5s ease-in-out;
  transition: opacity 0.5s ease-in-out;
}

/* 말풍선 꼬리 */
.chatbot-tooltip::after {
  content: '';
  position: absolute;
  top: 50%;
  left: 100%;
  transform: translateY(-50%);
  border: 6px solid transparent;
  border-left-color: #fff;
}

/* 나타나는 애니메이션 */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(5px); }
  to   { opacity: 1; transform: translateY(0); }
}


#chatbot-float {
  position: fixed;
  bottom: 40px;
  right: 30px;
  z-index: 5000;
}

.chatbot-open-btn {
	background: none;
	border: none;
	cursor: pointer;
	transition: 0.2s;
}

.chatbot-open-btn:hover{
	transform: scale(1.2);
}

.chatbot-icon {
  height: 60px;         /* 🔺 아이콘 크기 키우기 */
  width: auto;          /* 비율 유지 */
  display: inline-block;
}

.popular-slider.slick-slider {
  background-color: #fff;;
  padding: 50px 0 50px;
}

.slick-prev {
  position: absolute;
  bottom: 0px;
   left: 46%;
  transform: translateX(-40%);
  z-index: 100;
  background: white;
  border: 1px solid #ccc;
  border-radius: 50%;
  font-size: 20px;
  width: 36px;
  height: 36px;
  cursor: pointer;
  opacity: 0.85;
}
.slick-next {
  position: absolute;
  bottom: 0px;
  right: 46%;
  transform: translateX(-40%);
  z-index: 100;
  background: white;
  border: 1px solid #ccc;
  border-radius: 50%;
  font-size: 20px;
  width: 36px;
  height: 36px;
  cursor: pointer;
  opacity: 0.85;
}
.slick-prev:hover, .slick-next:hover {
  background: #000;
  color: #fff;
}

.slider-container {
  max-width: 1500px;
  margin: 0px auto 50px;
  overflow: hidden;
  position: relative;
}

.slider-container .slick-list {
  overflow: visible !important;
    padding: 0 220px 30px !important; /* 위/좌우/아래 여백 설정 */
}

.popular-slider .slick-slide {
  padding: 10px;
  box-sizing: border-box;
   transition: filter 0.4s ease;
}

.popular-card {
  position: relative;
  background-size: cover;
  background-position: center;
  border-radius: 16px;
  overflow: hidden;
  height: 200px; /* 필요시 조정 */
  padding: 25px;
  display: flex;
  align-items: flex-end;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transition: all 0.3s ease;
  color: #fff;
  cursor: pointer;
}

.popular-card img {
  max-width: 100%;
  height: auto;
  border-radius: 12px;
  margin-bottom: 10px;
}
.popular-title {
  font-weight: 580;
  font-size: 16px;
  margin: 5px 0;
  margin-bottom: 10px;
  text-align: left;
}
.popular-sub {
  font-size: 14px;
  color: white;
  margin-bottom: -15px;
  font-weight: 450;
}

.popular-slider .slick-slide {
  opacity: 1;
  transition: filter 0.1s ease;
  filter: none;
  transition:0.2s;
}

/* 가운데(active) 슬라이드 확대 */
.popular-slider .slick-center {
  transform: scale(1.2);
  opacity: 1;
  z-index: 10;
}

.popular-slider .slick-center .popular-card {
  transform: translateY(-10px); /* 살짝 위로 */
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
}

.popular-slider .slick-slide > div {
  margin: 0 15px; /* ← 좌우 간격. 줄이면 좁아지고 늘리면 넓어짐 */
}

.dark-text {
  color: #000;
}

.dark-text .popular-title,
.dark-text .popular-sub,
.dark-text .best-badge {
  color: #000 !important;
}

/* ---------- 카드 그리드 ---------- */
#cardGrid {
   display: grid;
   grid-template-columns: repeat(3, 1fr);
   gap: 130px 20px;
   justify-items: center;
   max-width: 1060px;
   margin: 125px auto;
}

.item {
  position: relative;
  width: 220px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  cursor: pointer;
}

.item img {
  width: 300px;
  rotate: 90deg;
  margin-bottom: 50px;
  transition: opacity 0.3s ease;
}

.card-img-wrapper {
  position: relative;
  display: inline-block;
}

/*  이미지에 hover 시 흐리게 */
.card-img-wrapper:hover img {
  opacity: 0.2;
  background-color: #ddd;
  border-radius: 10px;
  transition: opacity 0.3s ease;
}

/*  상세보기 텍스트 */
.overlay-text {
  position: absolute;
  top: 38%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-weight: 400;
  font-size: 15px;
  border-bottom: 1px solid #333333;
  color: #333333;
  padding: 6px 10px;
  display: none;
  pointer-events: none;
  z-index: 10;
}

/*  hover 시 텍스트 보이게 */
.card-img-wrapper:hover .overlay-text {
  display: block;
}


/* ---------- 카드 이름 ---------- */
.item p:nth-of-type(1) {
   font-size: 20px;
   font-weight: 500;
   margin-top: 40px;
}

/* ---------- 카드 설명 ---------- */
.item p:nth-of-type(2) {
   margin-top: 10px;
   margin-bottom: 20px;
   word-break: keep-all;
}

/* ---------- 비교함 ---------- */
#compareBox {

   text-align: center;
   position: fixed;
   right: 12px;
   top: 200px;
   width: 140px;
   padding: 10px;
   border: 1px solid #ccc;
   border-radius: 20px;
   background: #fff;
   z-index: 1010;
}

/* ---------- 비교함리스트 ---------- */
#compareList {
  display: flex;
  flex-direction: column;
  align-items: center;  
  gap: 12px;            
  padding: 0 0 8px 0;     
  margin: 0;
  list-style: none;
}


/* ---------- 비교 모달 ---------- */
#compareModal {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 80%;
  max-width: 900px;
  height: 85vh;                  
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 0 20px rgba(0,0,0,0.3);
  overflow: hidden;               /* 전체 영역 잘림 방지 */
  z-index: 3000;
  display: flex;
  flex-direction: column;
}

#compareModalContent {
  flex: 1;
  overflow-y: auto;               
  padding: 30px;
}

.compare-label {
  display: inline-block;
  font-weight: 500;
  font-size: 14px;
  cursor: pointer;
  border-bottom: 1px solid #333333;
  padding-bottom: 2px;
  margin-top: 6px;
}

.compare-label input {
  display: none;
}

#modalOverlay {
   display: none;
   position: fixed;
   inset: 0;
   background: rgba(0, 0, 0, .6);
   z-index: 1999;
}

#modalContent {
   position: relative;
   display: flex;
   flex-wrap: wrap;
   gap: 20px;
   justify-content: space-around;
}

#modalContent::after {
   content:"";
   position:absolute;
   width: 1px;
   margin-top: 20px;
   height: 480px;
   background-color: #ededed;
}


#modalContent div .card-name {
   margin-top: 50px;
   font-size: 20px;
   text-align: left;
}

#modalContent div .card-image-group img{
   width: 100%;
}

/* 더보기 */
#loadMoreWrap {
   text-align: center;
   margin: 40px 0
}

/* ---------- 검색바 + 타입버튼 ---------- */
.typeBtn {
   display: inline-block;
   padding: 7px 20px;
   margin: 0 3px;
   font-weight: 550;
   border: 1px solid #aaa;
   border-radius: 9999px;
   background: #fff;
   cursor: pointer;
   transition: 0.2s;
}

.typeBtn:hover {
	transform: scale(1.05);
}

.typeBtn.active {
   background: #b91111;
   color: #fff
}

.icon_img {
   display: flex;
   justify-content: center;
   width: 100%;
}

.icon_img > div {
   position: relative;
}

.icon_img input::placeholder {
   color: #828282;
}

.icon_img > div > img {
   position: absolute;
   top: 50%;
   left: 12px;
   transform: translateY(-50%);
    width: 18px;
    height: 18px;
}


#searchInput {
   cursor: pointer;
   width: 400px;
   padding: 10px 35px;
   font-size: 15px;
   border: none;
   background-color: #ededed;
   border-radius: 40px;
   outline: none;
   
}


#filterBtn {
   cursor: pointer;
   width: 40px;
   height: 40px;
   margin-left: 8px;
   border: none;
   border-radius: 50%;
   background: #eee;
   font-size: 18px;
   cursor: pointer;
   display: inline-flex;
   align-items: center;
   justify-content: center;
}

/* ---------- 상세 검색 모달 ---------- */
#advOverlay {
   display: none;
   position: fixed;
   inset: 0;
   background: rgba(0, 0, 0, .6);
   z-index: 3000;
}

#advModal {
   display: none;
   position: fixed;
   top: 50%;
   left: 50%;
   transform: translate(-50%, -50%);
   width: 90%;
   max-width: 600px;
   max-height: 85vh;
   background: #fff;
   border-radius: 12px;
   padding: 25px;
   z-index: 3001;
   box-shadow: 0 0 20px rgba(0, 0, 0, .35);
   flex-direction: column;
}

#advModal.show {
   display: flex
}

#advModal h3 {
   text-align: center;
   margin-top: 0
}

#advKeyword {
   width: 100%;
   padding: 8px 12px;
   margin-top: 20px;
   margin-bottom: 5px;
   box-sizing: border-box;
   border: 1px solid #ccc;
   border-radius: 8px;
}

.hot {
   display: inline-block;
   padding: 4px 12px;
   margin: 3px;
   border-radius: 15px;
   background: #eee;
   font-size: 13px;
   cursor: pointer;
}

.hot.sel {
   background: #000;
   color: #fff
}

#modalResultGrid {
   display: grid;
   grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
   gap: 20px;
   justify-items: center;
   margin-top: 15px;
   flex: 1;
   overflow-y: auto;
}

.adv-close {
   position: absolute;
   top: 15px;
   right: 20px;
   font-size: 22px;
   font-weight: 700;
   cursor: pointer;
}

.compare-card {
  width: 220px;
  background: #fff;
  border-radius: 12px;
  padding: 15px;
  text-align: center;
  font-size: 13px;
  line-height: 1.5;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
}

.card-image-group img {
  rotate: 90deg;
  width: 60px;
  height: auto;
  margin: 2px;
}

.card-name {
  font-size: 15px;
  font-weight: 500;
  margin: 6px 0 3px;
  min-height: 40px; /* 카드명 길이에 따라 위치 밀림 방지 */
}

/* 해시태그 */
.card-tags {
  text-align: left;
  color: #777;
  font-size: 15px;
  margin: 4px 0;
  min-height: 40px; /* 해시태그가 1~2줄이더라도 고정 */
}

.card-fee {
  margin-top: 10px;
  text-align: left;
  color: #333;
  font-size: 13px;
  margin-bottom: 5px;
  min-height: 20px;
}

#modalContent .card-icons img {
  width: 30px;
  height: 30px;
  margin: 2px;
}

.card-summary {
  text-align: left;
  font-size: 12px;
  margin-top: 10px;
  min-height: 120px; /* 카드별 요약 길이 다르더라도 균형 유지 */
  overflow: hidden;
}

.card-summary b {
  
}

.card-icons {
  display: flex;
  gap: 10px 30px;
  margin-top: 8px;
  max-width: 200px;
  flex-direction: row;
  align-items: center;
  align-content: center;
  flex-wrap: wrap;
  justify-content: center;
  min-height: 60px; /* 아이콘 수에 따라 줄어드는 문제 방지 */
}

.scrap-compare-btn {
  font-size: 12px;
  padding: 4px 8px;
  border-radius: 6px;
  background: #fafafa;
  color: #b91111;
  border: 1px solid #b91111;
  cursor: pointer;
}

.scrap-compare-btn:hover {
	/* transform: scale(1.05); */
	background-color: #b91111;
	color: #fff;
}


.scrap-card:hover {
	 box-shadow: 0 14px 28px rgba(0,0,0,0.25), 0 10px 10px rgba(0,0,0,0.10);
}

.scrap-card-img {
  width: 100%;
  height: auto;
  border-radius: 8px;
  margin-bottom: 8px;
  transition: transform 0.3s ease;
  rotate: 90deg;
  margin-top: 35px;
}


.scrap-card-name {
	margin-top: 25px;
}

/* 비교함 썸네일 이미지 */
.compare-thumb {
  width: 120px;
  padding-top: 5px;
  display: block;
  margin: 0 auto 5px;
  border-radius: 6px;
}

/* 비교함 카드명 */
.compare-card-name {
  font-size: 13px;
  text-align: center;
  margin-bottom: 4px;
  color: #333;
}

/* 비교함 제거 버튼 */
.compare-remove-btn {
    background: #ffffff;
    color: #b91111;
    border: 1px solid #b91111;
    padding: 4px 8px;
    border-radius: 6px;
    font-size: 12px;
    cursor: pointer;
    display: block;
    margin: 10px auto 0;
}

/* 비교 버튼 */
#compareBox > button,
#compareBox > div > button {
  width: 110px;	
  font-size: 13px;
  padding: 6px 10px;
  background: #eee;
  border: 1px solid #ccc;
  border-radius: 6px;
  cursor: pointer;
  display: block;
  margin: 15px auto 0;
}

/* 플레이스홀더 */
.compare-placeholder {
  margin-top: 10px;
  width: 100px;           
  height: 135px;         
  background: #f5f5f5;
  border: 1px solid #aaa;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
}

.compare-slot {
  width: auto;
}


.compare-placeholder .plus-sign {
  font-size: 40px;
  color: #999;
  margin-bottom: 6px;
}

.compare-placeholder .placeholder-text {
  font-size: 13px;
  color: #555;
  text-align: center;
  line-height: 1.4;
}




/* 인기 슬라이드 검정 글 */
.sk-margin {
  margin-left: 15px;
}


/*추천어*/

/* 스크롤 전체 영역 */
#recommendedKeywords {
  overflow: hidden;
  white-space: nowrap;
  width: 100%;
  position: relative;
  box-sizing: border-box;
}

.scroll-track {
  margin-bottom: 25px;
  display: inline-block;
  white-space: nowrap;
  animation: scrollLeft 60s linear infinite; /* ← 속도 조절 가능 */
}

@keyframes scrollLeft {
  0% {
    transform: translateX(0);
  }
  100% {
    transform: translateX(-50%);
  }
}

.recommend {
  display: inline-block;
  margin-right: 50px;
  font-weight: bold;
  cursor: pointer;
  color: #0f0f0f;
  font-size: 12px;
}
.effect{
	position:absolute;
	height:100%;
	width:150px;
	z-index:2;
}
.effect-left{
	left:0;
	background:	linear-gradient(to right, rgba(255, 255, 255, 1) 0%, rgba(255, 255, 255, 0.4) 50%, rgba(0, 0, 0, 0) 100%);
	
}
.effect-right{
	right:0;
	background:	linear-gradient(to left, rgba(255, 255, 255, 1) 0%, rgba(255, 255, 255, 0.4) 50%, rgba(0, 0, 0, 0) 100%);
	
}

</style>
</head>
<body>
<jsp:include page="/WEB-INF/views/fragments/mainheader2.jsp" />


   
   <!-- 🔥 인기 카드 슬라이더 -->
<div class="slider-container">
	<div class="effect-left effect"></div>
	<div class="effect-right effect"></div>
  <div class="popular-slider autoplay">
    <!-- 인기 카드가 JS로 자동 채워짐 -->
  </div>
</div>
   

   <!-- 카드 타입 필터 -->
   <div style="text-align: center; margin-bottom: 15px;">
      <button class="typeBtn active" data-type="">전체</button>
      <button class="typeBtn" data-type="신용">신용카드</button>
      <button class="typeBtn" data-type="체크">체크카드</button>
   </div>

   <!-- 검색바 + 세부 조정 아이콘 -->
      <div class="icon_img">
	     <div>
	     	 <input id="searchInput" type="text" placeholder="원하는 카드를 찾아보세요" autocomplete="off" readonly>
	         <img src="/image/benifits/search.png" alt="icon">
	     </div>
      </div>
      

   <!-- 카드 그리드 -->
   <div id="cardGrid"></div>
   <div id="loadMoreWrap">
     <button onclick="loadMore()" style="background:none; border:none; cursor:pointer;">
       <img src="/image/benifits/more_arrow.png" alt="더보기" style="width:24px; height:auto; border: 1px solid black; border-radius: 50%; padding:10px;">
     </button>
   </div>
   
   

   <!-- 비교함 -->
   <div id="compareBox">
      <h4 style="font-weight: 550;">비교함</h4>
      <ul id="compareList" style="list-style: none; padding: 0; margin: 0"></ul>
      <button onclick="openCompare()">비교하기</button>
      <div style="text-align:center; margin-top:10px;">
        <button onclick="openScrapModal()" style="font-size:13px; padding:6px 10px; background:#eee; border:1px solid #ccc; border-radius:6px; cursor:pointer;">타행카드와 비교</button>
      </div>
   </div>

   <!-- 비교 모달 -->
   <div id="compareModal">
  <h2 style="text-align: center;margin-top: 20px;margin-bottom: 50px;">카드 비교</h2>
  <div id="modalContent"></div>
  <div style="text-align: center; margin-top: 20px;">
    <button onclick="closeCompareModal()" style="
	    background-color: #eeee;
	    border: 1px solid #ddd;
	    width: 80px;
	    height: 32px;
	    border-radius: 5px;
	">닫기</button>
  </div>
</div>
<div id="modalOverlay" onclick="closeCompareModal()"></div>

<div id="scrapCompareModal" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); width:180%; max-width:700px; background:#fff; border-radius:12px; padding:30px; box-shadow:0 0 20px rgba(0,0,0,.4); z-index:3000;">
  <h2 style="text-align:center;">타행카드 비교하기</h2>
  <div id="scrapModalList" style="max-height:400px; overflow-y:auto; margin-top:20px; display:flex; flex-wrap:wrap; gap:20px; justify-content:center;"></div>
  <div style="text-align:center; margin-top:20px;">
    <button onclick="closeScrapModal()" style="
    width: 70px;
    height: 30px;
    border-radius: 6px;
    border: 1px solid #ddd;
    background-color: #eee;
">닫기</button>
  </div>
</div>
<div id="scrapOverlay" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,.6); z-index:2999;" onclick="closeScrapModal()"></div>



   <!-- 상세 검색 모달 -->
   <div id="advOverlay"></div>
   <div id="advModal">
      <span class="adv-close" onclick="closeAdv()">✕</span>
      <h3>상세 검색</h3>
      <input id="advKeyword" type="text" placeholder="카드 이름 또는 키워드 입력">
      
     <div id="recommendedKeywords">
  		<div class="scroll-track" id="scrollContent"></div>
	</div>
      
      <p style="margin: 0 0 6px; font-weight: 600">주요혜택 (최대 5개)</p>
      
      <div id="hotArea">
        <span class="hot" data-keyword="커피">#커피</span>
        <span class="hot" data-keyword="편의점">#편의점</span>
        <span class="hot" data-keyword="베이커리">#베이커리</span>
        <span class="hot" data-keyword="영화">#영화</span>
        <span class="hot" data-keyword="쇼핑">#쇼핑</span>
        <span class="hot" data-keyword="외식">#외식</span>
        <span class="hot" data-keyword="교통">#교통</span>
        <span class="hot" data-keyword="통신">#통신</span>
        <span class="hot" data-keyword="교육">#교육</span>
        <span class="hot" data-keyword="레저">#레저</span>
        <span class="hot" data-keyword="스포츠">#스포츠</span>
        <span class="hot" data-keyword="구독">#구독</span>
        <span class="hot" data-keyword="병원">#병원</span>
        <span class="hot" data-keyword="약국">#약국</span>
        <span class="hot" data-keyword="공공요금">#공공요금</span>
        <span class="hot" data-keyword="주유">#주유</span>
        <span class="hot" data-keyword="하이패스">#하이패스</span>
        <span class="hot" data-keyword="배달앱">#배달앱</span>
        <span class="hot" data-keyword="환경">#환경</span>
        <span class="hot" data-keyword="공유모빌리티">#공유모빌리티</span>
        <span class="hot" data-keyword="세무지원">#세무지원</span>
        <span class="hot" data-keyword="포인트">#포인트</span>
        <span class="hot" data-keyword="캐시백">#캐시백</span>
        <span class="hot" data-keyword="놀이공원">#놀이공원</span>
        <span class="hot" data-keyword="라운지">#라운지</span>
        <span class="hot" data-keyword="발렛">#발렛</span>
      </div>
      

      <div id="modalResultGrid"></div>
      <div style="text-align: center; margin-top: 15px;">
         <button id="advSearchBtn"
            style="width: 100%; padding: 10px 0; background: #b91111; color: #fff; border: none; border-radius: 8px; font-size: 16px; cursor: pointer">검색</button>
      </div>
   </div>
<jsp:include page="/WEB-INF/views/fragments/footer.jsp" />

<script src="/js/header2.js"></script>
<script>
//추천 검색어 불러오기
fetch('/api/recommend/keywords')
  .then(res => res.json())
  .then(keywords => {
    const container = document.getElementById('scrollContent');

    // 키워드를 두 번 반복해서 무한루프 효과
    const tags = keywords.map(k =>
      `<span class="recommend" data-keyword="${k}">${k}</span>`
    ).join('');
    
    container.innerHTML = tags + tags;

    // 클릭 이벤트
    container.querySelectorAll('.recommend').forEach(tag => {
      tag.addEventListener('click', () => {
        const keyword = tag.dataset.keyword;
        document.getElementById('advKeyword').value = keyword;
        performSearch(keyword);
        closeAdv();
      });
    });
  });




//  인기 카드 슬라이더 데이터 불러오기
fetch('/api/cards/popular')
  .then(r => r.json())
  .then(cards => {
    const sorted = [...cards]
      .sort((a, b) => b.viewCount - a.viewCount)
      .slice(0, 6);

    const slider = document.querySelector('.popular-slider');

    // 슬라이더 초기화 해제
    if ($(slider).hasClass('slick-initialized')) {
      $(slider).slick('unslick');
    }

    // 카드 DOM 삽입
    slider.innerHTML = sorted.map(c => {
      const bgUrl = c.popularImgUrl?.trim() || c.cardUrl?.trim();
      const isWhiteText = c.cardName.trim().includes("부산체육사랑카드");

      return `
        <div>
          <div class="popular-card" style="background-image: linear-gradient(to top, rgba(0, 0, 0, 0.8) 0%, rgba(0, 0, 0, 0.4) 20%, rgba(0, 0, 0, 0) 40%),url('${bgUrl}')" onclick="goDetail(${c.cardNo})">
            <div class="card-text-wrap ${isWhiteText ? 'white-text' : ''}">
              <div class="popular-title">${c.cardName}</div>
              <div class="popular-sub">${c.cardSlogan || ''}</div>
            </div>
          </div>
        </div>
      `;
	}).join('');



    // 슬릭 슬라이더 재초기화
    $(slider).slick({
      centerMode: true,
      centerPadding: '170px',
      slidesToShow: 3,
      slidesToScroll: 1,
      autoplay: true,
      autoplaySpeed: 3000,
      arrows: true,
      dots: false,
      infinite: true,
      prevArrow: '<button class="slick-prev">&#10094;</button>',
      nextArrow: '<button class="slick-next">&#10095;</button>',
    });

    

    // 강제 초기화 이벤트 트리거
    $(slider).slick('setPosition'); // layout 계산
  });



let fullCardList=[],currentIndex=0,currentType='',currentKeyword='',selectedTags=[];
const advModal=document.getElementById('advModal');

/* ---------- 상세 페이지 이동 ---------- */
function goDetail(no){
  location.href='/cards/detail?no='+no;
}

/* 타입 필터 */
document.querySelectorAll('.typeBtn').forEach(btn=>{
  btn.addEventListener('click',()=>{
    document.querySelectorAll('.typeBtn').forEach(b=>b.classList.remove('active'));
    btn.classList.add('active');
    currentType=btn.dataset.type;
    performSearch(currentKeyword);
  });
});

/* 상세 검색 모달 open / close */
const openAdv=()=>{
  document.getElementById('advOverlay').style.display='block';
  advModal.classList.add('show');
  document.getElementById('advKeyword').value=currentKeyword;
  document.getElementById('advKeyword').focus();
};
function closeAdv(){
  document.getElementById('advOverlay').style.display='none';
  advModal.classList.remove('show');
}

/* 검색창 진입 */
document.getElementById('searchInput').addEventListener('mousedown',openAdv);
document.getElementById('searchInput').addEventListener('keydown',e=>{
  if(e.key==='Enter' && !e.isComposing){e.preventDefault();openAdv();}
});

/* 태그 선택 */
document.querySelectorAll('#hotArea .hot').forEach(h => {
  h.addEventListener('click', () => {
    if (h.classList.contains('sel')) {
      h.classList.remove('sel');
      selectedTags = selectedTags.filter(t => t !== h.dataset.keyword);
    } else {
      if (selectedTags.length >= 5) {
        alert('최대 5개 선택');
        return;
      }
      h.classList.add('sel');
      selectedTags.push(h.dataset.keyword);
    }

    //  항상 performSearch 호출 (모달 안이든 밖이든)
    performSearch(currentKeyword);
  });
});


/* 상세 검색 실행 */
document.getElementById('advSearchBtn').addEventListener('click',()=>{
  currentKeyword=document.getElementById('advKeyword').value.trim();
  performSearch(currentKeyword);closeAdv();
});
document.getElementById('advKeyword').addEventListener('keydown',e=>{
  if(e.key==='Enter' && !e.isComposing){e.preventDefault();document.getElementById('advSearchBtn').click();}
});

/* 검색 */
function performSearch(keyword=''){
   
   //  1) 로그 먼저 저장
     fetch('/admin/Search/searchlog', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    keyword: keyword
  })
}).catch(err => console.error('검색 로그 저장 실패', err));
   
   
  const params=new URLSearchParams();
  if(keyword)params.append('q',keyword);
  if(currentType)params.append('type',currentType);
  if(selectedTags.length)params.append('tags',selectedTags.join(','));

  fetch('/api/cards/search?'+params.toString())
   .then(r => {
    if (!r.ok) {
      return r.json().then(e => { throw new Error(e.message); });
    }
    return r.json();
  })
    .then(data=>{
      if(data.length===0){
        fullCardList=[];currentIndex=0;
        document.getElementById('cardGrid').innerHTML='<p style="text-align:center;">검색 결과가 없습니다.</p>';
        document.getElementById('loadMoreWrap').style.display='none';
        return;
      }
      fullCardList=data;currentIndex=0;
      document.getElementById('cardGrid').innerHTML='';
      drawCards();
      document.getElementById('loadMoreWrap').style.display=(data.length>9)?'block':'none';
    })
    .catch(err => {
        alert(err.message);
      });
}

/* 초기 로딩 */
window.addEventListener('DOMContentLoaded',()=>{
  closeAdv();closeCompareModal();
  fetch('/api/cards')
    .then(r=>r.json())
    .then(d=>{
      fullCardList=d;drawCards();
      if(fullCardList.length<=9)document.getElementById('loadMoreWrap').style.display='none';
    })
    .catch(err=>console.error('카드 목록 로딩 실패',err));
});

/* 카드 출력 */
function drawCards() {
  const grid = document.getElementById('cardGrid');
  const end = Math.min(currentIndex + 9, fullCardList.length);

  for (let i = currentIndex; i < end; i++) {
    const c = fullCardList[i];
    const div = document.createElement('div');
    div.className = 'item';

    div.innerHTML = `
      <div class="card-img-wrapper" onclick="goDetail(${c.cardNo})">
        <img src="${c.cardUrl}" alt="${c.cardName}" class="card-img" style="width:300px;">
        <div class="overlay-text">상세보기</div>
      </div>

      <p style="cursor:pointer" onclick="goDetail(${c.cardNo})">${c.cardName}</p>

      <p style="font-size:12px;">${c.cardSlogan || ''}</p>

      <label class="compare-label" onclick="event.stopPropagation();">
        <input type="checkbox"
               value="${c.cardNo}"
               onclick="event.stopPropagation(); toggleCompare(this)">
        비교함 담기
      </label>
    `;
    grid.appendChild(div);
  }

  currentIndex = end;
  if (currentIndex >= fullCardList.length)
    document.getElementById('loadMoreWrap').style.display = 'none';
}

function loadMore(){drawCards();}

/* 비교함 */
function toggleCompare(cb){
  const item = cb.closest('.item');
  const cardNo = cb.value;

  const cardName = item.querySelector('p')?.innerText || '알 수 없음';
  const cardUrl  = item.querySelector('img')?.src || '';

  let box = JSON.parse(sessionStorage.getItem('compareCards') || '[]');

  if(cb.checked){
    if(box.length >= 2){
      alert('최대 2개까지만 비교');
      cb.checked = false;
      return;
    }
    box.push({cardNo, cardName, cardUrl});
  } else {
    box = box.filter(c => c.cardNo !== cardNo);
  }

  sessionStorage.setItem('compareCards', JSON.stringify(box));
  renderCompareList();
}

function renderCompareList() {
	  const list = document.getElementById('compareList');
	  list.innerHTML = '';

	  const cards = JSON.parse(sessionStorage.getItem('compareCards') || '[]');
	  const maxSlots = 2;

	  for (let i = 0; i < maxSlots; i++) {
	    const li = document.createElement('li');
	    li.className = 'compare-slot';

	    if (cards[i]) {
	      const c = cards[i];
	      li.innerHTML = `
	        <img src="${c.cardUrl}" class="compare-thumb">
	        <div class="compare-card-name">${c.cardName}</div>
	        <button class="compare-remove-btn" onclick="removeFromCompare('${c.cardNo}')">제거</button>
	      `;
	    } else {
	      li.innerHTML = `
	        <div class="compare-placeholder">
	          <div class="plus-sign">+</div>
	          <div class="placeholder-text">비교할 카드를<br>추가하세요</div>
	        </div>
	      `;
	    }

	    list.appendChild(li);
	  }
	}


renderCompareList();

function removeFromCompare(cardNo) {
     let box = JSON.parse(sessionStorage.getItem('compareCards') || '[]');
     box = box.filter(c => c.cardNo !== cardNo);
     sessionStorage.setItem('compareCards', JSON.stringify(box));
     renderCompareList();

     // 체크박스 상태도 해제
     const checkbox = document.querySelector(
       `input[type="checkbox"][value="${cardNo}"]`
     );
     if (checkbox) checkbox.checked = false;
   }


const categoryToIcon = {
        "커피": "coffee",
        "편의점": "convenience-store",
        "베이커리": "bakery",
        "영화": "movie",
        "쇼핑": "shopping",
        "외식": "meal",
        "교통": "metro",
        "통신": "telecommunication",
        "교육": "education",
        "레저&스포츠": "leisure",
        "구독": "subscribe",
        "병원": "hospital",
        "공공요금": "charges",
        "주유": "gas-station",
        "하이패스": "hipass",
        "배달앱": "delivery",
        "환경": "environment",
        "공유모빌리티": "socar",
        "세무지원": "tax",
        "포인트&캐시백": "point",
        "놀이공원": "amusementpark",
        "라운지": "lounge",
        "발렛": "valetparking"
};

/* 비교 모달 */
function openCompare() {
  const box = JSON.parse(sessionStorage.getItem('compareCards') || '[]');
  if (box.length < 2) {
    alert('최소 2개 이상 선택');
    return;
  }

  document.getElementById('compareModal').style.display = 'block';
  document.getElementById('modalOverlay').style.display = 'block';

  const wrap = document.getElementById('modalContent');
  wrap.innerHTML = '';

  box.forEach(c => {
    fetch(`/api/cards/${c.cardNo}`)
      .then(r => r.json())
      .then(d => {
        const div = document.createElement('div');
        div.className = 'compare-card';

        // 해시태그 추출
        const tagStr = (d.cardType || '') + ',' + (d.service || '') + ',' + (d.sService || '') + ',' + (d.issuedTo || '');
        const tags = Object.keys(categoryToIcon).filter(t => tagStr.includes(t));

        // 아이콘
        const iconHtml = tags.map(name => {
          const icon = categoryToIcon[name];
          return `<img src="/image/benifits/${icon}.png" alt="${name}">`;
        }).join('');
        const tagHtml = tags.map(t => `#${t}`).join(' ');

        // 카드 이미지 (최대 3장)
        const images = (d.cardUrl || d.scCardUrl || '').split(',');
      const imageHtml = images.slice(0, 3).map(url =>
        `<img src="${url.trim()}" alt="">`
      ).join('');

        // 요약 혜택: benefits 또는 scbenefits 우선 사용
        let summary = '';
      if (d.benefits || d.scBenefits) {
        summary = (d.benefits || d.scBenefits)
          .replace(/<br\s*\/?>/gi, '<br>');
      } else if (d.service) {
        summary = d.service
          .replace(/◆/g, '•')
          .split(/\n|<br>/)
          .filter(line => line.trim())
          .slice(0, 5)
          .join('<br>');
      }

        // 연회비: 일반 or 스크랩 카드용
        const fee = d.annualFee ?? d.scAnnualFee ?? 0;

        // 카드명: 일반 or 스크랩 카드용
        const name = d.cardName || d.scCardName;

        div.innerHTML = `
          <div class="card-image-group">${imageHtml}</div>
          <div class="card-name">${name}</div>
          <div class="card-tags">${tagHtml}</div>
          <div class="card-icons">${iconHtml}</div>
          <div class="card-fee"><b>연회비:</b> ${fee.toLocaleString()}원</div>
          <div class="card-summary"><b>요약 혜택</b><br>${summary}</div>
        `;
        wrap.appendChild(div);
      });
  });
}


function closeCompareModal(){
  document.getElementById('compareModal').style.display='none';
  document.getElementById('modalOverlay').style.display='none';
}

function openScrapModal() {
	  console.log("타행카드 모달 실행");

	  const comparedScrapNos = JSON.parse(sessionStorage.getItem('compareCards') || '[]')
	    .filter(c => c.cardNo.startsWith('scrap_'))
	    .map(c => c.cardNo.replace('scrap_', ''));

	  fetch('/api/public/cards/scrap')
	    .then(res => res.json())
	    .then(data => {
	      const listDiv = document.getElementById('scrapModalList');
	      listDiv.innerHTML = '';

	      data.forEach(card => {
	    	 
	    	  const div = document.createElement('div');
	    	  div.className = 'scrap-card'; 
	    	  div.style.cssText = 'width:160px; text-align:center; border:1px solid #ddd; padding:10px; border-radius:10px;';


	        // 이미지 추출 (첫 번째 URL만 사용)
	        const imageUrl = (card.scCardUrl || '').split(',')[0]?.trim();

	        // 비교함에 이미 담겼는지 확인
	        const isAlreadyAdded = comparedScrapNos.includes(String(card.scCardNo));

	        // innerHTML 구성
	        div.innerHTML = `
	          <img src="${imageUrl}" alt="${card.scCardName}" class="scrap-card-img">
	          <div class="scrap-card-name"><b>${card.scCardName}</b></div>
	          <div style="font-size:12px; color:#666; margin:5px 0 10px;">${card.scCardSlogan || ''}</div>
	          ${
	        	  isAlreadyAdded
	        	    ? `<div style="font-size:12px; color:green;">✔ 비교함에 추가됨</div>`
	        	    : `<button class="scrap-compare-btn" onclick='addScrapToCompare("${card.scCardNo}", "${imageUrl}", "${card.scCardName}")'>
	        	        비교함 담기
	        	    	  </button>`
	        	}

	        `;
	        listDiv.appendChild(div);
	      });

	      document.getElementById('scrapCompareModal').style.display = 'block';
	      document.getElementById('scrapOverlay').style.display = 'block';
	    });
	}


   function closeScrapModal() {
     document.getElementById('scrapCompareModal').style.display = 'none';
     document.getElementById('scrapOverlay').style.display = 'none';
   }

   function addScrapToCompare(cardNo, url, name) {
     const slot = document.getElementById('compareList');
     const box = JSON.parse(sessionStorage.getItem('compareCards') || '[]');
     if (box.length >= 2) {
       alert('최대 2개까지만 비교 가능합니다.');
       return;
     }
     console.log("addScrapToCompare실행")
     console.log(cardNo);
     box.push({cardNo: 'scrap_' + cardNo, cardName: name, cardUrl: url});
     sessionStorage.setItem('compareCards', JSON.stringify(box));
     renderCompareList();
     closeScrapModal();
   }

   function openChatbot() {
	   window.open(
	     '/card/chatbot',            // 챗봇 페이지 URL
	     'cardChatbotPopup',              // 창 이름 (중복 방지용)
	     'width=520,height=780,resizable=yes,scrollbars=yes'
	   );
	 }
   
   
</script>

<script>
   let remainingSeconds = <%= request.getAttribute("remainingSeconds") %>;
</script>


<div id="chatbot-float">
 
 <div class="chatbot-tooltip" id="tooltipText">마음에 쏙 드는 카드를 찾아드릴게요!</div>

  <!-- 챗봇 버튼 -->
  <button class="chatbot-open-btn" onclick="openChatbot()">
    <img src="/image/bnkchatbotchar.png" alt="카드 챗봇" class="chatbot-icon">
  </button>
</div>

<script>
const phrases = [
  "마음에 쏙 드는 카드를 찾아드릴게요!",
  "혜택이나 카드명을 입력해보세요 😊",
  "원하시는 카드 유형을 알려주세요!",
  "생활에 딱 맞는 카드 추천 도와드릴게요!"
];

let index = 0;

setInterval(() => {
  const tooltip = document.getElementById("tooltipText");

  // Fade-out
  tooltip.style.opacity = 0;

  setTimeout(() => {
    index = (index + 1) % phrases.length;
    tooltip.textContent = phrases[index];

    // Fade-in
    tooltip.style.opacity = 1;
  }, 400); // fade out 시간과 맞추기

}, 5000); // 5초마다 교체
</script>





<script src="/js/sessionTime.js"></script>
</body>
</html>
