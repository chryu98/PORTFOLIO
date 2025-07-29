<%@ page contentType="text/html; charset=UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>부산은행 챗봇</title>

<style>
:root {
	--bnk-red: #D6001C;
	--bnk-gray: #F5F6F8;
	--text-dark: #333;
}

body {
	font-family: 'Noto Sans KR', sans-serif;
	background: var(--bnk-gray);
	display: flex;
	justify-content: center;
	padding: 24px;
}

.chat-container {
	width: 100%;
	max-width: 520px;
	height: 660px;
	background: #fff;
	border-radius: 16px;
	box-shadow: 0 4px 18px rgba(0, 0, 0, .12);
	display: flex;
	flex-direction: column;
	padding: 24px;
}

.chat-container h2 {
	margin: 0 0 16px;
	font-size: 22px;
	font-weight: 500;
	text-align: center;
	color: var(--bnk-red);
}

.chat-box {
	flex: 1;
	overflow-y: auto;
	background: #FAFAFA;
	border: 1px solid #E0E0E0;
	border-radius: 12px;
	padding: 16px;
	display: flex;
	flex-direction: column;
	gap: 12px;
}

.chat-entry {
	max-width: 78%;
	padding: 12px 16px;
	border-radius: 20px;
	line-height: 1.55;
	word-break: break-word;
	position: relative;
	box-shadow: 0 2px 5px rgba(0, 0, 0, .08);
}
.chat-entry.user {
	align-self: flex-end;
	background: var(--bnk-red);
	color: #fff;
	border-bottom-right-radius: 6px;
}
.chat-entry.user::after {
	content: '';
	position: absolute;
	top: 12px;
	right: -10px;
	border: 6px solid transparent;
	border-left-color: var(--bnk-red);
}
.chat-entry.bot {
	align-self: flex-start;
	background: #E9E9E9;
	color: var(--text-dark);
	border-bottom-left-radius: 6px;
}
.chat-entry.bot::after {
	content: '';
	position: absolute;
	top: 12px;
	left: -10px;
	border: 6px solid transparent;
	border-right-color: #E9E9E9;
}

#inputArea {
	margin-top: 18px;
	display: flex;
	gap: 10px;
}

#userInput {
	flex: 1;
	padding: 12px;
	font-size: 14px;
	border: 1px solid #ccc;
	border-radius: 8px;
}

button {
	padding: 0 20px;
	background: var(--bnk-red);
	color: #333;
	border: none;
	border-radius: 8px;
	cursor: pointer;
}

a.card-link {
	color: var(--bnk-red);
	text-decoration: underline;
}

/* 👇 말풍선 내부 버튼 스타일 */
.inline-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 12px;
}

.inline-buttons button {
  padding: 6px 10px;
  font-size: 13px;
  background: #fff;
  border: 1px solid #ccc;
  border-radius: 20px;
  cursor: pointer;
  transition: background 0.2s;
}

.inline-buttons button:hover {
  background: #f5f5f5;
}

.send-btn {
  color: #fff !important;
}
</style>
</head>
<body>

<div class="chat-container">
	<h2>부산은행 챗봇 부뱅이</h2>

	<div class="chat-box" id="chatBox"></div>

	<div id="inputArea">
		<input type="text" id="userInput" placeholder="질문을 입력하세요"
			onkeydown="if(event.key==='Enter') sendMessage()">
		<button class="send-btn" onclick="sendMessage()">보내기</button>
	</div>
</div>

<script>
document.addEventListener("DOMContentLoaded", function () {
  const welcomeHTML = `
    <p>안녕하세요! 부산은행 챗봇 <strong>부뱅이</strong>에요 😊<br>
    카드 관련 궁금한 점이 있다면 아래 버튼을 눌러보세요!<br>
    혹은 궁금하신 부분에 대해서 물어봐주세요</p>
    <div class="inline-buttons">
      <button onclick="handleQuickAction('배달앱 할인되는 카드 알려줘')">배달앱 할인</button>
      <button onclick="handleQuickAction('연회비 저렴한 카드 추천해줘')">연회비 저렴</button>
      <button onclick="handleQuickAction('커피 할인되는 카드 알려줘')">커피 할인</button>
      <button onclick="handleQuickAction('MZ세대 인기카드 뭐야?')">인기 카드</button>
    </div>
  `;
  appendMessage(welcomeHTML, "bot");
});

function makeLinksClickable(txt){
    return txt.replace(/<a[^>]*>(.*?)<\/a>/gi,"$1")
              .replace(/(https?:\/\/[^\s<]+)/g,
                       '<a href="$1" target="_blank" rel="noopener noreferrer" class="card-link">카드 상세보기</a>')
              .replace(/\n/g,"<br>");
}

function appendMessage(msg,type,isTemp=false){
    const box=document.getElementById("chatBox");
    const div=document.createElement("div");
    div.className = 'chat-entry ' + type; 
    div.innerHTML=makeLinksClickable(msg);
    box.appendChild(div); box.scrollTop=box.scrollHeight;
    return isTemp?div:null;
}

function createTypingBubble(){
    let dots=1;
    const bubble=appendMessage("작성중.","bot",true);
    const timer=setInterval(()=>{
        dots=dots%3+1;
        bubble.textContent="작성중"+'.'.repeat(dots);
    },400);
    return {bubble,timer};
}

function sendMessage(){
    const input=document.getElementById("userInput");
    const q=input.value.trim(); if(!q) return;
    appendMessage(q,"user"); input.value="";

    const {bubble,timer}=createTypingBubble();

    fetch("/user/card/chatbot",{
        method:"POST",
        headers:{ "Content-Type":"application/json" },
        body:JSON.stringify({question:q})
    })
    .then(res=>res.text())
    .then(ans=>{
        clearInterval(timer); bubble.remove();
        appendMessage(ans,"bot");
    })
    .catch(()=>{
        clearInterval(timer); bubble.remove();
        appendMessage("서버 오류가 발생했습니다.","bot");
    });
}

function handleQuickAction(message) {
    appendMessage(message, "user");
    
    const {bubble, timer} = createTypingBubble();

    fetch("/user/card/chatbot", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({question: message})
    })
    .then(res => res.text())
    .then(ans => {
        clearInterval(timer); bubble.remove();
        appendMessage(ans, "bot");
    })
    .catch(() => {
        clearInterval(timer); bubble.remove();
        appendMessage("서버 오류가 발생했습니다.", "bot");
    });
}
</script>

</body>
</html>
