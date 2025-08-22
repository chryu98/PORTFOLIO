<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>BNK 부산은행</title>
<link rel="stylesheet" href="/css/style.css">
<link rel="stylesheet" href="/css/carousel.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" integrity="sha512-Evv84Mr4kqVGRNSgIGL/F/aIDqQb7xQ2vcrdIwxfjThSH8CSR7PBEakCr51Ck+w+/U6swU2Im1vVX0SVk9ABhg==" crossorigin="anonymous" referrerpolicy="no-referrer" />
<link rel="stylesheet" type="text/css" href="//cdn.jsdelivr.net/npm/slick-carousel@1.8.1/slick/slick.css"/>
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.13.0/dist/Draggable.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.13.0/dist/MotionPathPlugin.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.13.0/dist/InertiaPlugin.min.js"></script>
<script type="module" src="https://unpkg.com/@splinetool/viewer@latest/build/spline-viewer.js"></script>
<script  src="https://code.jquery.com/jquery-3.7.1.min.js"  ></script>

</head>
<body class="main-body">
<jsp:include page="/WEB-INF/views/fragments/mainheader.jsp" />
<!-- <div class="video-wrapper">
	<div class="video-container">
	    흐릿한 배경용 영상
	    <video autoplay muted loop playsinline class="back-video">
	        <source src="/video/bannerVideo.mp4" type="video/mp4">
	    </video>
	
	    선명한 전경 영상
	    <video autoplay muted loop playsinline class="banner-video">
	        <source src="/video/bannerVideo.mp4" type="video/mp4">
	    </video>
		
	    텍스트나 버튼 등 추가 가능
	    <div class="overlay-text">
	        <h1 class="red">플러스, &nbsp</h1>
	        <h1> 그 이상의 혜택</h1>
	    </div>	
	</div>
</div> -->
<div class="slider-wrapper">
	<div class="main-slider">
	  <div>
	  	<div class="cover"></div>
	  	<div class="img img1">
	  		<span class="bold">정성</span><span>으로 보답합니다.</span>
	  	</div>
	  </div>
	  <div>
	  	<div class="cover"></div>
	  	<div class="img img2">
	  		<span>세계와 &nbsp</span><span class="bold">함께</span><span>성장합니다.</span>
	  	</div>
	  </div>
	  <div>
	  	<div class="cover"></div>
	  	<div class="img img3">
		  		<span>금융을 &nbsp</span><span class="bold">따뜻</span><span>하게</span>
	  	</div>
	  </div>
	  <div>
	  	<div class="cover"></div>
	  	<div class="img img4">
	  		<span>금융을 &nbsp</span><span class="bold">안전</span><span>하게</span>
	  	</div>
	  </div>
	  <div>
	  	<div class="cover"></div>
	  	<div class="img img5">
	  		<span>늘 &nbsp</span><span class="bold">새로운</span><span>&nbsp 마음으로</span>
	  	</div>
	  </div>
	  
	  
	</div>
</div>
<div class="main-wrap flex">
	<div class="section">
		<h1 class="mainTit1">동백PLUS 체크카드</h1>
		<h2 class="mainTit2">'가성비'와 '가심비'를 모두 만족하는 프리미엄 경험</h2>
		<p class="mainTit3">매일 쓰는 소비에, 매달 받는 보상</p>
		<div class="spline-wrapper">
			<div class="spline-cover"></div>
			<div class="confetti-wrapper c1">
			  <ul class="particles "></ul>
			</div>
			<div class="confetti-wrapper c2">
			  <ul class="particles "></ul>
			</div>
			<div class="confetti-wrapper c3">
			  <ul class="particles2 "></ul>
			</div>
			<div class="confetti-wrapper c4">
			  <ul class="particles2 "></ul>
			</div>
			<spline-viewer orbit class="spline"  allow="scroll" url="https://prod.spline.design/uHGgQogk8z9Qb0Xz/scene.splinecode"></spline-viewer>
		</div>
	</div>
	<div class="section">
	
		<div class="carousel">
			  <div class="spacer">
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:skyblue">SKY BLUE</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:orange">ORANGE</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:green">GREEN</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:purple">PURPLE</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:yellow">YELLOW</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:red">RED</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:skyblue">SKY BLUE</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:orange">ORANGE</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:green">GREEN</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:purple">PURPLE</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:yellow">YELLOW</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  	<div class="txt-box">
			  		<p class="color-txt" style="color:red">RED</p>
			  		<p class="desc"> 내가 고르는 선택의 즐거움</p>
			  	</div>
			  </div>
	
	    <div class="wrapper">
	           
            <div class="content">
	              <div class="track"></div>
	                  <div class="item"><img class="child" src="/image/CARD 1.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 2.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 3.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 4.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 5.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 6.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 1.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 2.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 3.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 4.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 5.png"></div>
	                  <div class="item"><img class="child" src="/image/CARD 6.png"></div>
	            </div>    
	           
	      </div>
		<button class="carousel-btn previous"><i class="fas fa-chevron-left"></i></button>
		<button class="carousel-btn next"><i class="fas fa-chevron-right"></i></button>

	
		</div>
    </div>
    
    <div class="section section3">
    	<div class="inner">
			<h2 class="bubble-title t1">혜택은 명확하게</h2>
			<h2 class="bubble-title t2">어디서나 간편하게</h2>
			<div class="bubble-wrap flex">
				<div class="hover-target-wrapper">
					<div class="hover-target b1">
						<img src="/image/웃는얼굴.png">
						<p>연회비 무료</p>
					</div>
					
				</div>
				<div class="hover-target-wrapper">
					<div class="hover-target b2">
						<img src="/image/버스.png">
						<p>후불 교통카드</p>
					</div>
					
				</div>
				<div class="hover-target-wrapper">
					<div class="hover-target b3">
						<img src="/image/atm.png">
						<p>수수료 무료</p>
					</div>
					
				</div>
				<div class="hover-target-wrapper">
					<div class="hover-target b4">
						<img src="/image/번개.png">
						<p>즉시 캐쉬백</p>
					</div>
					
				</div>
			</div>
		</div>
	</div>
	<div class="section infinite-carousel">
	  <h1 class="t1">부산은행이라면</h1>
	  <h1 class="t2">그만큼 특별하죠	</h1>
	  <p class="t3">당신의 생활에 꼭 맞는 혜택, 지금 경험해보세요</p>
	  
	  <div class="carousel-track">
	    <div class="carousel-item c1">
	    	<img src="/image/brands/커피.png">
	    	<p >스타벅스/이디야/카페베네</p>
	    </div>
	    <div class="carousel-item c2">
	    	<img src="/image/brands/다이소.jpg">
	    	<p>다이소</p>
	    </div>
	    <div class="carousel-item c3">
	    	<img src="/image/brands/마켓컬리.png">
	    	<p>마켓컬리</p>
	    </div>
	    <div class="carousel-item c4">
	    	<img src="/image/brands/쿠팡.png">
	    	<p>쿠팡</p>
	    </div>
	    <div class="carousel-item c5">
	    	<img src="/image/brands/맥도날드.png">
	    	<p>맥도날드</p>
	    </div>
	    <div class="carousel-item c6">
	    	<img src="/image/brands/대중교통.png">
	    	<p>대중교통</p>
	    </div>
	    <div class="carousel-item c7">
	    	<img src="/image/brands/세븐일레븐.png">
	    	<p>세븐일레븐</p>
	    </div>
	    <div class="carousel-item c8">
	    	<img src="/image/brands/던킨.jpg">
	    	<p>던킨도너츠</p>
	    </div>
	    <div class="carousel-item c9">
	    	<img src="/image/brands/씨유.jpg">
	    	<p>CU</p>
	    </div>
	    <div class="carousel-item c10">
	    	<img src="/image/brands/파리바게트.jpg">
	    	<p>파리바게트</p>
	    </div>
	    <div class="carousel-item c11">
	    	<img src="/image/brands/지에스.png">
	    	<p>GS</p>
	    </div>
	    <div class="carousel-item c12">
	    	<img src="/image/brands/휴대전화.png">
	    	<p>휴대전화</p>
	    </div>
	    
	    <!-- 복사본 -->
	    
	    <div class="carousel-item c1">
	    	<img src="/image/brands/커피.png">
	    	<p>스타벅스/이디야/카페베네</p>
	    </div>
	    <div class="carousel-item c2">
	    	<img src="/image/brands/다이소.jpg">
	    	<p>다이소</p>
	    </div>
	    <div class="carousel-item c3">
	    	<img src="/image/brands/마켓컬리.png">
	    	<p>마켓컬리</p>
	    </div>
	    <div class="carousel-item c4">
	    	<img src="/image/brands/쿠팡.png">
	    	<p>쿠팡</p>
	    </div>
	    <div class="carousel-item c5">
	    	<img src="/image/brands/맥도날드.png">
	    	<p>맥도날드</p>
	    </div>
	    <div class="carousel-item c6">
	    	<img src="/image/brands/대중교통.png">
	    	<p>대중교통</p>
	    </div>
	    <div class="carousel-item c7">
	    	<img src="/image/brands/세븐일레븐.png">
	    	<p>세븐일레븐</p>
	    </div>
	    <div class="carousel-item c8">
	    	<img src="/image/brands/던킨.jpg">
	    	<p>던킨도너츠</p>
	    </div>
	    <div class="carousel-item c9">
	    	<img src="/image/brands/씨유.jpg">
	    	<p>CU</p>
	    </div>
	    <div class="carousel-item c10">
	    	<img src="/image/brands/파리바게트.jpg">
	    	<p>파리바게트</p>
	    </div>
	    <div class="carousel-item c11">
	    	<img src="/image/brands/지에스.png">
	    	<p>GS</p>
	    </div>
	    <div class="carousel-item c12">
	    	<img src="/image/brands/휴대전화.png">
	    	<p>휴대전화</p>
	    </div>
	  </div>
	</div>
	
	<button id="scrollTopBtn" title="맨 위로 이동"><i class="fas fa-chevron-up"></i></button>
</div>
<jsp:include page="/WEB-INF/views/fragments/footer.jsp" />
<c:if test="${not empty msg}">
	    <script>alert("${msg}");</script>
	</c:if>
<script src="/js/carousel.js"></script>
<script type="text/javascript" src="//cdn.jsdelivr.net/npm/slick-carousel@1.8.1/slick/slick.min.js"></script>

<script>

	


	//헤더
	window.addEventListener('scroll', function() {
	    const header = document.querySelector('header');
	    if (window.scrollY > 50) {
	        header.classList.add('scrolled');
	    } else {
	        header.classList.remove('scrolled');
	    }
	});
	
	// 콘페티 애니메이션
function launchConfettiAll() {
  const containers = document.querySelectorAll('.particles');
  containers.forEach(ul => {
    ul.innerHTML = '';

    const count = 20;

    const imageParticleCount = Math.floor(Math.random() * 3) + 3; // 3~5개
    const imageIndexes = new Set();
    while (imageIndexes.size < imageParticleCount) {
      imageIndexes.add(Math.floor(Math.random() * count));
    }

    const imageUrl = '/image/동전.png';

    for (let i = 0; i < count; i++) {
      const li = document.createElement('li');
      li.style.setProperty('--i', i);

      const angle = Math.random() * 2 * Math.PI;
      const distance = Math.random() * 180 + 50;
      const x = Math.cos(angle) * distance;
      const y = Math.sin(angle) * distance;

      li.style.setProperty('--x', `\${x}px`);
      li.style.setProperty('--y', `\${y}px`);
      const rotation = Math.random() * 720 - 360;
      li.style.setProperty('--r', `\${rotation}deg`);

      if (imageIndexes.has(i)) {
        const size = Math.random() * 30 + 30;
        li.style.width = `\${size}px`;
        li.style.height = `\${size}px`;
        li.style.backgroundImage = `url(\${imageUrl})`;
        li.style.backgroundSize = 'contain';
        li.style.backgroundRepeat = 'no-repeat';
        li.style.backgroundPosition = 'center';
        li.style.backgroundColor = 'transparent';
        li.style.borderRadius = '0';
      } else {
        const size = Math.random() * 6 + 12;
        li.style.width = `\${size}px`;
        li.style.height = `\${size}px`;
      }

      ul.appendChild(li);
    }
  });
}
	

function launchConfettiAll2() {
	  const containers = document.querySelectorAll('.particles2');
	  containers.forEach(ul => {
	    ul.innerHTML = '';

	    const count = 20;

	    const imageParticleCount = Math.floor(Math.random() * 3) + 3; // 3~5개
	    const imageIndexes = new Set();
	    while (imageIndexes.size < imageParticleCount) {
	      imageIndexes.add(Math.floor(Math.random() * count));
	    }

	    const imageUrl = '/image/동전.png';

	    for (let i = 0; i < count; i++) {
	      const li = document.createElement('li');
	      li.style.setProperty('--i', i);

	      const angle = Math.random() * 2 * Math.PI;
	      const distance = Math.random() * 180 + 50;
	      const x = Math.cos(angle) * distance;
	      const y = Math.sin(angle) * distance;

	      li.style.setProperty('--x', `\${x}px`);
	      li.style.setProperty('--y', `\${y}px`);
	      const rotation = Math.random() * 720 - 360;
	      li.style.setProperty('--r', `\${rotation}deg`);

	      if (imageIndexes.has(i)) {
	        const size = Math.random() * 30 + 30;
	        li.style.width = `\${size}px`;
	        li.style.height = `\${size}px`;
	        li.style.backgroundImage = `url(\${imageUrl})`;
	        li.style.backgroundSize = 'contain';
	        li.style.backgroundRepeat = 'no-repeat';
	        li.style.backgroundPosition = 'center';
	        li.style.backgroundColor = 'transparent';
	        li.style.borderRadius = '0';
	      } else {
	        const size = Math.random() * 6 + 12;
	        li.style.width = `\${size}px`;
	        li.style.height = `\${size}px`;
	      }

	      ul.appendChild(li);
	    }
	  });
	}
		




setInterval(() => {
		launchConfettiAll();
	}, 6000); // 3초마다 터짐
	
setTimeout(() => {
	  setInterval(() => {
	    launchConfettiAll2();
	  }, 6000);
	}, 3000); // 첫 실행을 3초 뒤에 시작
	
	
		
	
	
	
	//슬라이더
	$('.main-slider').slick({
	  centerMode: true,
	  centerPadding: '0px',
	  slidesToShow: 3,
	  autoplay:true,
	  autoplaySpeed:5000,
	  arrows: true,
	  infinite: true,
	  variableWidth: true,
	  prevArrow: '<button class="slick-prev custom-prev custom-arrow"><i class="fas fa-chevron-left"></button>',
	  nextArrow: '<button class="slick-next custom-next custom-arrow"><i class="fas fa-chevron-right"></button>',
	});
	
	//가로 무한스크롤
		
	const track = document.querySelector('.carousel-track');
	const duplicatedItems = Array.from(track.children); // 이름 변경
	const trackWidth = track.scrollWidth;
	
	track.innerHTML += track.innerHTML; // 복사본 추가
	
	let currentX = 0;
	
	function animate() {
	  currentX -= 1; // 속도 조절
	  if (Math.abs(currentX) >= trackWidth) {
	    currentX = 0; // 원래 위치로 리셋
	  }
	  track.style.transform = `translateX(\${currentX}px)`;
	  requestAnimationFrame(animate);
	}
	
	animate();
	
	
	//스크롤 탑 버튼
	const scrollTopBtn = document.getElementById('scrollTopBtn');

	window.addEventListener('scroll', () => {
	  if (window.pageYOffset > 300) {  // 스크롤 300px 이상 내려가면 버튼 보임
	    scrollTopBtn.style.display = 'flex';
	  } else {
	    scrollTopBtn.style.display = 'none';
	  }
	});
	
	scrollTopBtn.addEventListener('click', () => {
		  smoothScrollToTop(600);  // 600ms 동안 부드럽게 스크롤
		});
	
	function smoothScrollToTop(duration = 500) {
		  const start = window.pageYOffset;
		  const startTime = performance.now();

		  function scroll() {
		    const now = performance.now();
		    const time = Math.min(1, (now - startTime) / duration);
		    const timeFunction = time * (2 - time); // easeOutQuad 효과
		    window.scrollTo(0, start * (1 - timeFunction));

		    if (time < 1) {
		      requestAnimationFrame(scroll);
		    }
		  }

		  requestAnimationFrame(scroll);
		}
	
	
	
	
	
	
	//로그인 남은시간	
	let remainingSeconds = "${remainingSeconds}";

	if (remainingSeconds === "null" || remainingSeconds === "" || isNaN(Number(remainingSeconds))) {
	  remainingSeconds = 0;
	} else {
	  remainingSeconds = Number(remainingSeconds);
	}
	
</script>
<script src="/js/sessionTime.js"></script>
</body>
</html>