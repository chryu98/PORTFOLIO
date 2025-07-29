<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%
    Object adminNoObj = session.getAttribute("loginAdminNo");
    Long adminNoLong = null;
    if (adminNoObj instanceof Number) {
        adminNoLong = ((Number) adminNoObj).longValue();
    } else if (adminNoObj instanceof String) {
        try { adminNoLong = Long.valueOf((String) adminNoObj); } catch(Exception ignore){}
    }
    if (adminNoLong == null) adminNoLong = 999L;   // fallback
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>관리자 고객관리</title>

<!-- 공통 관리자 스타일(헤더 포함) -->
<link rel="stylesheet" href="/css/adminstyle.css">

<!-- 채팅 전용 스타일 -->
<style>
/* ── Reset / Base ───────────────────────────────────── */
* {
	box-sizing: border-box
}

body {
	margin: 0;
	font-family: 'Noto Sans KR', sans-serif;
	background: #f4f4f4;
	color: #333
}

/* ── 메인 패널 ───────────────────────────────────────── */
.container {
	width: 100%;
	max-width: 1020px;
	height: 800px;
	margin: 90px auto 40px; /* ↑ 헤더 높이만큼 top 여백 */
	display: flex;
	overflow: hidden;
	background: #fff;
	border: 1px solid #dcdcdc;
	border-radius: 10px;
	box-shadow: 0 4px 18px rgba(0, 0, 0, .15)
}

/* === 헤더를 화면 상단에 고정 === */
header.sidebar{
  position:fixed;     /* 문서 흐름에서 분리 */
  top:0; left:0; right:0;
 
  /* 
  background:#fff;
  border-bottom:1px solid #ddd;
  */
  border-bottom:1px solid #ddd;
  z-index:1000;       /* 내용보다 위에 올라오도록 */
}

.chat-sidebar {
	width: 220px;
	background: #fafafa;
	border-right: 1px solid #ddd;
	padding: 14px 12px 12px;
	display: flex;
	flex-direction: column;
	overflow-y: auto
}

.chat-area {
	flex-grow: 1;
	display: flex;
	flex-direction: column;
	padding: 20px
}

.chat-header {
	font-weight: 700;
	font-size: 17px;
	margin-bottom: 10px
}

/* ── 방 목록 ─────────────────────────────────────────── */
h3 {
	margin: 0 0 12px 0;
	font-size: 17px;
	font-weight: 700
}

.badge {
	display: inline-block;
	padding: 2px 7px;
	margin-left: 6px;
	background: #ff5252;
	color: #fff;
	font-size: 12px;
	border-radius: 12px;
	vertical-align: middle
}

#roomSearch {
	width: 100%;
	padding: 7px 9px;
	margin-bottom: 10px;
	font-size: 13px;
	border: 1px solid #bbb;
	border-radius: 6px
}

#roomSearch:focus {
	box-shadow: 0 0 0 2px rgba(0, 123, 255, .25)
}

.room-item {
	display: flex;
	justify-content: space-between;
	align-items: center;
	padding: 7px 10px;
	margin-bottom: 9px;
	border: 1px solid #ddd;
	border-radius: 6px;
	font-size: 12px;
	cursor: pointer;
	transition: background .15s, border .15s
}

.room-item:hover {
	background: #f1f5ff
}

.room-item.selected-room {
	background: #e2e3ff;
	border-color: #9fa8ff
}

.room-info {
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis
}

.room-unread {
	min-width: 20px;
	padding: 2px 6px;
	text-align: center;
	background: #ff5252;
	color: #fff;
	border-radius: 12px;
	font-size: 11px;
	font-weight: 700
}

.room-meta {
	display: block;
	font-size: 10px;
	color: #666;
	margin-top: 2px
}

/* ── 채팅 박스 & 입력 ───────────────────────────────── */
#chatBox {
	flex-grow: 1;
	border: 1px solid #ddd;
	border-radius: 6px;
	background: #fff;
	overflow-y: auto;
	padding: 10px;
	display: flex;
	flex-direction: column;
	gap: 8px;
	font-size: 13px
}

.message {
	max-width: 78%;
	padding: 7px 10px;
	border-radius: 10px;
	word-break: break-word
}

.user {
	background: #d1e7dd;
	align-self: flex-end;
	margin-left: auto
}

.admin {
	background: #f8d7da;
	align-self: flex-start;
	margin-right: auto
}

.input-area {
	display: flex;
	gap: 8px;
	margin-top: 8px
}

.input-area input {
	flex-grow: 1;
	padding: 9px;
	font-size: 13px;
	border: 1px solid #ccc;
	border-radius: 5px
}

.input-area button {
	padding: 9px 14px;
	background: #007bff;
	color: #fff;
	border: none;
	border-radius: 5px;
	font-size: 13px;
	cursor: pointer
}

.input-area button:hover {
	background: #0056b3
}
</style>

<!-- 헤더용 JS (메뉴 강조 등) -->
<script src="/js/adminHeader.js" defer></script>
</head>

<body>
	<!-- 공통 헤더 -->
	<jsp:include page="../fragments/header.jsp"></jsp:include>

	<!-- 채팅 패널 -->
	<div class="container">
		<div class="chat-sidebar">
			<h3>
				방 목록 <span id="totalUnread" class="badge">0</span>
			</h3>
			<input type="text" id="roomSearch" placeholder="검색">
			<div id="roomList"></div>
		</div>

		<div class="chat-area" style="display: none;">
			<div class="chat-header" id="roomTitle">채팅방</div>
			<div id="chatBox"></div>
			<div class="input-area">
				<input type="text" id="adminMessageInput" placeholder="메시지를 입력하세요">
				<button id="sendAdminBtn">보내기</button>
			</div>
		</div>
	</div>

	<!-- 라이브러리 -->
	<script
		src="https://cdn.jsdelivr.net/npm/sockjs-client@1/dist/sockjs.min.js"></script>
	<script
		src="https://cdn.jsdelivr.net/npm/stompjs@2.3.3/lib/stomp.min.js"></script>

	<!-- 채팅 패널 JS -->
	<script>
const ADMIN_NO_SERVER = Number('<%= adminNoLong %>');
let stompClient=null,currentRoomId=null,allRooms=[];

/* 초기화 */
window.onload=()=>{loadRooms();setInterval(loadRooms,5000);
  document.getElementById('sendAdminBtn').onclick=sendAdminMessage;
  document.getElementById('roomSearch').onkeyup=filterRooms;
};

/* ── REST: 방 목록 ───────────────────────────── */
function loadRooms(){
  fetch('/api/admin/chat/rooms')
    .then(r=>r.json())
    .then(d=>{ allRooms=Array.isArray(d)?d:[]; updateTotalUnread(allRooms); renderRoomList(allRooms); })
    .catch(console.error);
}
function updateTotalUnread(rooms){
  document.getElementById('totalUnread').textContent =
      rooms.reduce((a,r)=>a+(r.unreadCount||0),0);
}

/* ── 검색 필터 ────────────────────────────────── */
function filterRooms(e){
  const q=e.target.value.trim();
  renderRoomList(q?allRooms.filter(r=>String(r.memberNo??'').includes(q)||String(r.roomId).includes(q)):allRooms);
}

/* ── 방 리스트 출력 ───────────────────────────── */
function renderRoomList(rooms){
  const list=document.getElementById('roomList'); list.innerHTML='';
  rooms.sort((a,b)=>(b.unreadCount??0)-(a.unreadCount??0)||
        new Date(b.lastMessageAt||b.createdAt)-new Date(a.lastMessageAt||a.createdAt));

  if(!rooms.length){
     list.innerHTML="<p style='font-size:12px;color:#777'>방이 없습니다</p>";return;
  }
  rooms.forEach(r=>{
    if(r.roomId==null) return;
    const div=document.createElement('div'); div.className='room-item';
    if(Number(currentRoomId)===Number(r.roomId))div.classList.add('selected-room');

    const info=document.createElement('div'); info.className='room-info';
    info.innerHTML="방&nbsp;"+r.roomId+" / 회원&nbsp;"+(r.memberNo!=null?r.memberNo:'-');
    const meta=document.createElement('span'); meta.className='room-meta';
    meta.textContent="최근: "+(formatTime(r.lastMessageAt||r.createdAt)||"-"); info.appendChild(meta);

    const unread=document.createElement('span'); unread.className='room-unread';
    unread.textContent=r.unreadCount??0;

    div.appendChild(info); div.appendChild(unread);
    div.dataset.roomId=r.roomId; div.onclick=()=>enterRoom(Number(r.roomId));
    list.appendChild(div);
  });
}

/* ── 방 입장 ───────────────────────────────────── */
function enterRoom(roomId){
  if(!roomId||isNaN(roomId)){alert('방 번호 오류');return;}
  if(!ADMIN_NO_SERVER){alert('관리자 번호 오류');return;}
  currentRoomId=roomId;

  fetch('/api/admin/chat/room/'+roomId+'/enter?adminNo='+ADMIN_NO_SERVER,{method:'POST'})
    .then(res=>{if(!res.ok)throw res})
    .then(()=>fetch('/api/admin/chat/room/'+roomId+'/messages'))
    .then(r=>r.json())
    .then(d=>{
       document.querySelector('.chat-area').style.display='flex';
       document.getElementById('roomTitle').textContent='채팅방 #'+roomId;
       const box=document.getElementById('chatBox'); box.innerHTML='';
       (Array.isArray(d)?d:[]).forEach(showMessage);
       connect(roomId); loadRooms();
    })
    .catch(e=>{console.error(e);alert('방 입장 실패');});
}

/* ── WebSocket 연결 ───────────────────────────── */
function connect(roomId){
  if(stompClient?.connected)stompClient.disconnect();
  stompClient=Stomp.over(new SockJS('/ws/chat'));
  stompClient.connect({},()=>
     stompClient.subscribe('/topic/room/'+roomId,m=>{
        try{showMessage(JSON.parse(m.body));loadRooms();}catch(e){console.error(e);}
     }),console.error);
}

/* ── 메시지 전송 ──────────────────────────────── */
function sendAdminMessage(){
  const inp=document.getElementById('adminMessageInput'),msg=inp.value.trim();
  if(!msg){alert('메시지를 입력하세요');return;}
  if(!currentRoomId){alert('방을 선택하세요');return;}
  stompClient.send('/app/chat.sendMessage',{},JSON.stringify({
     roomId:currentRoomId,senderType:'ADMIN',senderId:ADMIN_NO_SERVER,message:msg
  })); inp.value='';
}

/* ── 메시지 출력 ──────────────────────────────── */
function showMessage(m){
  const div=document.createElement('div');
  div.className='message '+(m.senderType==='USER'?'user':'admin');
  div.textContent=(m.senderType||'')+': '+(m.message||'')+(m.sentAt?' ('+formatTime(m.sentAt)+')':'');
  const box=document.getElementById('chatBox'); box.appendChild(div); box.scrollTop=box.scrollHeight;
}
function formatTime(t){if(!t)return'';const d=new Date(t);return isNaN(d)?'':d.toLocaleString();}
    </script>
</body>
</html>
