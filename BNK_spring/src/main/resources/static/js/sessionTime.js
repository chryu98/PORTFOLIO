document.addEventListener("DOMContentLoaded", () => {
	const timer = document.getElementById("session-timer");
	if (!timer) return; // 요소가 없으면 실행 중단

	function formatTime(sec){
		const min = Math.floor(sec / 60);
		const secVal = sec % 60;
		const minStr = min < 10 ? "0" + min : "" + min;
		const secStr = secVal < 10 ? "0" + secVal : "" + secVal;
		return minStr + ":" + secStr;
	}

	function updateTimer(){
		if (remainingSeconds <= 0) {
			timer.textContent = "00:00";
			clearInterval(timerInterval);
			location.href = "/logout?expired=true";
			return;
		}
		timer.textContent = formatTime(remainingSeconds);
		remainingSeconds--;
	}

	let remainingSeconds = 1200;
	let timerInterval = setInterval(updateTimer, 1000);
	updateTimer();

	window.extend = function(){
		fetch("/session/keep-session", {
			method: "POST"
		})
		.then(res => res.json())
		.then(data => {
			if (data.remainingSeconds) {
				remainingSeconds = data.remainingSeconds;
				updateTimer();
			}
		});
	};

	window.logout = function(){
		if(confirm("로그아웃 하시겠습니까?")){
			document.getElementById("logoutForm").submit();
		}
	};
});
