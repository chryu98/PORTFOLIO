<%@ page contentType="text/html;charset=UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>부산은행 1:1 상담</title>
<link rel="stylesheet" href="/css/style.css">
<!-- 프로젝트 공통 스타일 존재 시 유지 -->

<style>
/* =============================
   브랜드 변수 (필요 시 수정)
   ============================= */
:root {
	--bnk-red: #d6001c; /* BNK 계열 레드 */
	--bnk-red-light: #ffe5e8; /* 레드 라이트 버블 */
	--bnk-blue: #004c97; /* 신뢰감 블루 */
	--bnk-blue-light: #e6f0ff; /* 블루 라이트 버블 */
	--bnk-gray-bg: #f5f6f8;
	--bnk-gray-border: #d5d7db;
	--bnk-gray-text: #555;
	--bnk-radius: 8px;
	--bnk-gap: 12px;
	--bnk-font-main: 'Noto Sans KR', '맑은 고딕', sans-serif;
	--bnk-font-size: 15px;
	--bnk-font-size-small: 12px;
}

/* 전체 페이지 베이스 */
body {
	margin: 0;
	background: var(--bnk-gray-bg);
	font-family: var(--bnk-font-main);
	font-size: var(--bnk-font-size);
	color: #000;
}

/* 페이지 중앙 정렬 */
.userchat-wrapper {
	display: flex;
	justify-content: center;
	padding: 80px 16px 120px;
	box-sizing: border-box;
}

/* 카드 컨테이너 */
.userchat-card {
	width: 100%;
	max-width: 480px;
	background: #fff;
	height: 680px; /* ← 고정 높이 */ max-height : 680px; /* 모바일에서도 동일 높이 유지 */
	border: 1px solid var(--bnk-gray-border);
	border-radius: var(--bnk-radius);
	box-shadow: 0 4px 12px rgba(0, 0, 0, .08);
	display: flex;
	flex-direction: column;
	overflow: hidden;
	max-height: 680px;
}

/* 헤더 */
.uc-header {
	background: var(--bnk-red);
	color: #fff;
	padding: 16px 20px;
	display: flex;
	align-items: center;
	gap: 8px;
	font-weight: 700;
	font-size: 18px;
	line-height: 1;
}

.uc-header-status {
	width: 10px;
	height: 10px;
	border-radius: 50%;
	background: #00e676; /* 연결됨 */
	flex-shrink: 0;
}

.uc-header-status.offline {
	background: #ff6b6b;
}

/* 채팅 영역 */
.uc-chat-scroll {
	flex:1 1 auto;  
	padding: 20px;
	background: #fff;
	border-bottom: 1px solid var(--bnk-gray-border);
	display: flex;
	flex-direction: column;
	gap: var(--bnk-gap);
	overflow-y: auto;
	max-height: 400px; /* 필요 시 조정 */
}

/* 메시지 행 */
.message-row {
	max-width: 80%;
	display: flex;
	flex-direction: column;
	word-break: break-word;
	line-height: 1.35;
}

.message-row.user {
	align-self: flex-end;
	text-align: right;
}

.message-row.admin {
	align-self: flex-start;
	text-align: left;
}

/* 말풍선 */
.message-bubble {
	display: inline-block;
	padding: 8px 12px;
	border-radius: 16px;
	font-size: var(--bnk-font-size);
	box-sizing: border-box;
	white-space: pre-wrap;
}

.message-row.user .message-bubble {
	background: var(--bnk-blue-light);
	border: 1px solid rgba(0, 0, 0, .05);
	color: #000;
}

.message-row.admin .message-bubble {
	background: var(--bnk-red-light);
	border: 1px solid rgba(0, 0, 0, .05);
	color: #000;
}

/* 이름 태그 (선택적으로 표시) */
.message-name {
	font-size: var(--bnk-font-size-small);
	color: var(--bnk-gray-text);
	margin-bottom: 2px;
}

/* 시간 */
.message-time {
	margin-top: 2px;
	font-size: 11px;
	color: var(--bnk-gray-text);
}

/* 입력 영역 */
.uc-input-area {
	display: flex;
	align-items: flex-end;
	gap: 8px;
	padding: 16px;
	background: #fff;
	box-sizing: border-box;
}

.uc-input-area textarea {
	flex-grow: 1;
	min-height: 40px;
	max-height: 120px;
	padding: 8px 10px;
	border: 1px solid var(--bnk-gray-border);
	border-radius: var(--bnk-radius);
	resize: vertical;
	font-family: var(--bnk-font-main);
	font-size: var(--bnk-font-size);
	line-height: 1.35;
	box-sizing: border-box;
}

.uc-input-area button {
	padding: 10px 18px;
	font-size: var(--bnk-font-size);
	font-weight: 600;
	color: #fff;
	background: var(--bnk-blue);
	border: none;
	border-radius: var(--bnk-radius);
	cursor: pointer;
	white-space: nowrap;
}

.uc-input-area button:hover:not(:disabled) {
	background: #003e7b;
}

.uc-input-area button:disabled {
	opacity: .6;
	cursor: not-allowed;
}

/* 숨겨진 기존 요소들 보존용 (필수 ID만 남기고 display none) */
#chatBox {
	display: none !important;
}

/* 반응형 */
@media ( max-width :480px) {
	.userchat-card {
		max-width: 100%;
	}
	.uc-header {
		font-size: 16px;
		padding: 14px 16px;
	}
	.uc-chat-scroll {
		padding: 16px;
		max-height: 60vh;
	}
	.uc-input-area {
		padding: 12px;
	}
}

/* 업무시간 배너 */
.uc-banner {
	display: none; /* 기본은 숨김 → JS에서 조건부 노출 */
	background: #fff5f5;
	color: #c00;
	font-size: var(--bnk-font-size-small);
	text-align: center;
	padding: 8px 12px;
	border-bottom: 1px solid var(--bnk-gray-border);
}

/* 고지 문구 (반투명) */
.uc-notice {
	font-size: var(--bnk-font-size-small);
	color: var(--bnk-gray-text);
	opacity: .6; /* 60 % 투명도 */
	text-align: center;
	padding: 8px 20px 4px;
}
</style>
</head>
<body>
	<jsp:include page="/WEB-INF/views/fragments/mainheader2.jsp" />

	<div class="userchat-wrapper">
		<div class="userchat-card">

			<!-- 헤더 -->
			<div class="uc-header">
				<span class="uc-header-status offline" id="ucStatusDot"></span> BNK
				부산은행 1:1 상담
			</div>

			<!-- 헤더 바로 아래 : 업무시간 안내 배너 -->
			<div class="uc-banner" id="ucBusinessBanner">9시부터 16시 업무시간 외에는
				상담이 어려울 수도 있습니다.</div>

			<!-- 채팅 스크롤 영역 (실제 메시지는 여기 렌더링) -->
			<div class="uc-chat-scroll" id="ucChatScroll"></div>


			<!-- …(중략) … -->

			<!-- 채팅 스크롤 영역 아래, 입력창 위쪽에 고지 문구 -->
			<div class="uc-notice">
				상담원은 누군가의 가족일 수 있습니다.<br> 대화 내역은 모두 기록됩니다.
			</div>


			<!-- 입력 영역 -->
			<div class="uc-input-area">
				<!-- 기존 input 대신 textarea. ID는 기존 send 로직 변경 위해 새 id지만 아래 JS에서 매핑 -->
				<textarea id="messageInput"
					placeholder="메시지를 입력하세요 (Enter 전송, Shift+Enter 줄바꿈)"></textarea>
				<button id="sendBtn">보내기</button>
			</div>
		</div>
	</div>

	<script src="/js/header2.js"></script>
	<script
		src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
	<script
		src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>

	<script>
/* =========================================================
   기존 변수 / 플로우 유지
   ========================================================= */
let stompClient = null;
let roomId = null;
let memberNo = null;

/* 연결 상태 UI */
function setStatus(online) {
  const dot = document.getElementById('ucStatusDot');
  if (!dot) return;
  if (online) {
    dot.classList.remove('offline');
  } else {
    dot.classList.add('offline');
  }
}

window.onload = function () {
	  showBusinessHourBanner();     // ① 업무시간 체크
	  initChatFlow();               // ② 기존 로직
	  /* ③ 엔터/버튼 이벤트 바인딩 */
	  const msgEl=document.getElementById('messageInput');
	  msgEl.addEventListener('keydown',function(e){
	    if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();sendMessage();}
	  });
	  document.getElementById('sendBtn').addEventListener('click',sendMessage);
	};
	
	/* 09~16시 여부 판단 후 배너 노출 */
	function showBusinessHourBanner(){
	  const now=new Date();
	  const hour=now.getHours();        // 사용자의 브라우저 시간을 그대로 사용
	  const banner=document.getElementById('ucBusinessBanner');
	  if(hour<9||hour>=16){             // 9 ≤ hour < 16 이외이면 노출
	    banner.style.display='block';
	  }
	}
function initChatFlow() {
    console.log("▶ initChatFlow()");
    // --- 1. 로그인 사용자 정보 ---
    fetch('/user/chat/info', { credentials: 'same-origin' })
        .then(r => {
            console.log("INFO status:", r.status);
            if (!r.ok) throw new Error("로그인 정보 없음");
            return r.json();
        })
        .then(data => {
            console.log("INFO data:", data);
            memberNo = data.memberNo;
            if (!memberNo) throw new Error("세션 memberNo 없음");
            // --- 2. 기존 방 조회 ---
            return fetch('/user/chat/my-room', { credentials: 'same-origin' });
        })
        .then(r => {
            console.log("MY-ROOM status:", r.status);
            if (r.status === 404) {
                console.log("기존 방 없음 → 새 방 생성 진행.");
                return createRoomForMember(memberNo);
            }
            if (!r.ok) throw new Error("my-room 조회 실패");
            return r.text();   // body = roomId (text)
        })
        .then(idText => {
            if (!idText) {
                throw new Error("my-room 응답이 비어 있음 → 새 방 생성 시도");
            }
            let parsed = Number(idText);
            if (isNaN(parsed) || parsed <= 0) {
                console.warn("my-room 응답이 숫자가 아님. 새 방 생성 시도:", idText);
                return createRoomForMember(memberNo);
            }
            return parsed;
        })
        .then(id => {
            if (!id || isNaN(id)) {
                console.error("roomId가 유효하지 않습니다. 받은 값:", id);
                throw new Error("roomId 불러오기 실패");
            }
            roomId = id;
            console.log("최종 roomId 확정:", roomId);
            connect(roomId);
            loadPreviousMessages(roomId);
        })
        .catch(err => {
            console.error("initChatFlow 실패:", err);
            alert("로그인이 필요합니다.");
            window.location.href = "/user/login";
        });
}

/* 새 방 생성 */
function createRoomForMember(memberNo) {
    console.log("▶ createRoomForMember(", memberNo, ")");
    return fetch('/user/chat/room', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'memberNo=' + encodeURIComponent(memberNo),
        credentials: 'same-origin'
    })
    .then(r => {
        console.log("CREATE-ROOM status:", r.status);
        if (!r.ok) throw new Error("방 생성 실패");
        return r.text();
    })
    .then(idText => {
        console.log("CREATE-ROOM raw id:", idText);
        const id = Number(idText);
        if (!id || isNaN(id)) throw new Error("방 생성 응답이 숫자가 아님: " + idText);
        return id;
    });
}

/* WebSocket 연결 */
function connect(roomId) {
    if (!roomId) {
        console.error("connect() 호출 실패 - roomId 없음");
        return;
    }
    const socket = new SockJS('/ws/chat');
    stompClient = Stomp.over(socket);
    stompClient.connect({}, function(frame) {
        console.log("WebSocket 연결됨:", frame);
        setStatus(true);
        stompClient.subscribe('/topic/room/' + roomId, function(message) {
            try {
                const data = JSON.parse(message.body);
                showMessage(data);
            } catch (e) {
                console.error("WebSocket 메시지 JSON 파싱 오류:", e, message.body);
            }
        });
    }, function(error) {
        console.error("WebSocket 연결 실패:", error);
        setStatus(false);
    });
}

/* 이전 메시지 로딩 */
function loadPreviousMessages(id) {
    if (!id || isNaN(id)) {
        console.error("loadPreviousMessages() 실패 - roomId가 유효하지 않음:", id);
        return;
    }
    const url = "/user/chat/room/" + encodeURIComponent(id) + "/messages";
    console.log("▶ loadPreviousMessages() 요청 URL:", url);
    fetch(url, { credentials: 'same-origin' })
        .then(res => {
            console.log("LOAD-MSG status:", res.status);
            if (!res.ok) throw new Error("메시지 조회 실패");
            return res.json();
        })
        .then(data => {
            console.log("LOAD-MSG data:", data);
            const scrollEl = document.getElementById("ucChatScroll");
            scrollEl.innerHTML = "";
            if (Array.isArray(data)) {
                data.forEach(showMessage);
            }
            scrollToBottom();
        })
        .catch(err => console.error("이전 메시지 로딩 오류:", err));
}

/* 메시지 전송 */
function sendMessage() {
    const msgEl = document.getElementById('messageInput');
    const msg = msgEl.value.trim();
    if (!msg) {
        msgEl.focus();
        return;
    }
    if (!roomId || !memberNo) {
        alert("채팅이 초기화되지 않았습니다. 다시 시도해주세요.");
        return;
    }
    const payload = {
        roomId: roomId,
        senderType: "USER",
        senderId: memberNo,
        message: msg
    };
    console.log("SEND payload:", payload);
    stompClient.send("/app/chat.sendMessage", {}, JSON.stringify(payload));
    msgEl.value = "";
    msgEl.focus();
}

/* 메시지 렌더링 */
function showMessage(message) {
    console.log("MSG:", message);
    const sender = message.senderType || "알 수 없음";
    const text   = message.message || "(빈 메시지)";
    const sentAt = message.sentAt ? formatTime(message.sentAt) : "";

    // container
    const row = document.createElement("div");
    row.classList.add("message-row", sender === "USER" ? "user" : "admin");

    // 발신자 이름 (금융권 UI에서는 생략 가능, 옵션)
    const nameEl = document.createElement("div");
    nameEl.className = "message-name";
    nameEl.textContent = sender === "USER" ? "나" : "상담사";

    // 말풍선
    const bubbleEl = document.createElement("div");
    bubbleEl.className = "message-bubble";
    bubbleEl.textContent = text;

    // 시간
    const timeEl = document.createElement("div");
    timeEl.className = "message-time";
    timeEl.textContent = sentAt;

    // 조립
    row.appendChild(nameEl);
    row.appendChild(bubbleEl);
    if (sentAt) row.appendChild(timeEl);

    const scrollEl = document.getElementById("ucChatScroll");
    scrollEl.appendChild(row);
    scrollToBottom();
}

/* 스크롤 최하단 이동 */
function scrollToBottom() {
    const el = document.getElementById("ucChatScroll");
    el.scrollTop = el.scrollHeight;
}

/* 시간 포맷 */
function formatTime(t) {
    try {
        const d = new Date(t);
        if (isNaN(d.getTime())) return "";
        return d.toLocaleString('ko-KR', {
            month:'2-digit', day:'2-digit',
            hour:'2-digit', minute:'2-digit'
        });
    } catch(e) {
        return "";
    }
}


</script>
</body>
</html>
